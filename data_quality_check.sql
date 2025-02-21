--- Check for data inconsistencies

----------------------------------------------------------------- Let us check if duplicate rows exists

SELECT 
    invoice_no, 
    stock_code, 
    description, 
    quantity, 
    invoice_date, 
    unit_price, 
    customer_id, 
    country, 
    COUNT(*) AS duplicate_count
FROM staging_source_table
GROUP BY 
    invoice_no, 
    stock_code, 
    description, 
    quantity, 
    invoice_date, 
    unit_price, 
    customer_id, 
    country
HAVING COUNT(*) > 1;

--- We have around 4900 duplicated rows. Let us drop them

WITH duplicates AS (
	SELECT 
		id,
		ROW_NUMBER() OVER(PARTITION BY invoice_no, stock_code, description, quantity, invoice_date, unit_price, customer_id, country ORDER BY id) AS row_num
	FROM
		staging_source_table
)
DELETE FROM staging_source_table
WHERE id IN (
	SELECT 
		id
	FROM duplicates 
	WHERE row_num > 1
)


--- Lets check the final row counts

SELECT COUNT(*) FROM staging_source_table;

--- Duplicates are now dropped

----------------------------------------------------------------- Check of quantity table has values zero or negative
SELECT 
	COUNT(*)
FROM ( SELECT * 
FROM
	staging_source_table
WHERE 
	quantity <= 0
)

--- We have 10587 rows with quanity value -ve.
SELECT * 
FROM
	staging_source_table
WHERE 
	quantity = 0;

--- We dont have quantity == 0. I assume it is just due to data entry issues. 

SELECT 
	invoice_no,
	stock_code, 
	quantity
FROM
	staging_source_tablestaging_source_table;
WHERE 
	quantity < 0;

--- I was wrong, all the cancelled orders have quantity in negative! canceled orders have 'c' prefix in their invoice_no. Thats how I figured it out.

--- let us add a new bool column, is_cancelled, for quantity = -ve

ALTER TABLE staging_source_table
ADD COLUMN is_cancelled BOOLEAN DEFAULT FALSE;

UPDATE staging_source_table
SET is_cancelled = TRUE
WHERE quantity < 0;


SELECT * FROM staging_source_table;

-- We now have a new column

----------------------------------------------------------------- Checking for rows with negative or zero unit prices

SELECT 
	*
FROM
	staging_source_table
WHERE 
	unit_price <= 0;

--- There are thousands of rows with unit price = 0, and looks like these are for cancelled orders.

--- Lets, see if orders that were not cancelled have unit price set to 0


SELECT 
	*
FROM
	staging_source_table
WHERE 
	unit_price <= 0 AND is_cancelled = FALSE;

--- Shit! we do have 1180 rows with unit_price = 0, for is_cancelled = False

--- Let us look for distinct products with with unit_price = 0, for is_cancelled = False


SELECT 
	COUNT(DISTINCT stock_code)
FROM
	staging_source_table
WHERE 
	unit_price <= 0 AND is_cancelled = FALSE

--- 683 distinct products with unit_price = 0
--- Let see if we have prices for these stock codes

SELECT 
	DISTINCT ON(stock_code)
	stock_code,
	unit_price
FROM 
	staging_source_table
WHERE 
	stock_code IN (
	SELECT 
		DISTINCT(stock_code)
	FROM
		staging_source_table
	WHERE 
		unit_price <= 0 AND is_cancelled = FALSE	
)

SELECT COUNT(DISTINCT stock_code) FROM staging_source_table;
--- THERE ARE 4070 distinct stock_code 

SELECT COUNT(DISTINCT (stock_code, unit_price)) FROM staging_source_table;
--- THERE ARE 17303 unique combinations of stock_code and unit_price. 
--- I can conclude that product has different prices.



SELECT 
	*
FROM
	staging_source_table
WHERE 
	unit_price <= 0 AND is_cancelled = FALSE	

--- Looking at the data, most of unit_price == 0.00 are from customer_id which were NULL and we set to 00000. Also, escription suggests they were adjustments, bank charges, 
--- Lets drop all the unit_price == 0 for customer_id = 00000


DELETE FROM staging_source_table
WHERE 
	unit_price = 0.00 AND is_cancelled = FALSE AND customer_id = '00000';

--- We deleted 1134 rows

--- Now lets look at the remaining

SELECT 
	*
FROM
	staging_source_table
WHERE 
	unit_price <= 0 AND is_cancelled = FALSE	

-- NOW we have 46 rows
-- These rows contain stock_code = [M(for manual), B(Adjust bad dept), BANK CHARGES(Bank_charges)] : These do not relate to our analysis, and are of no value.
-- Even if we could use these rows, we do not have what amount was spent on bank charges or manual transactions.


DELETE FROM staging_source_table
WHERE 
	unit_price <= 0.00 AND is_cancelled = FALSE AND stock_code = ANY(ARRAY['M', 'B', 'BANK CHARGES']);


-- Let us check

SELECT 
	*
FROM
	staging_source_table
WHERE 
	unit_price <= 0 AND is_cancelled = FALSE	


--- NOW we have 37 rows
--- We can now possibly impute with mean.


