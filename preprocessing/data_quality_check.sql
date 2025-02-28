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

SELECT 
	invoice_no,
	stock_code, 
	quantity
FROM
	staging_source_table
WHERE 
	quantity < 0;

--- The cancelled orders have quantity in negative! canceled orders have 'c' prefix in their invoice_no. Thats how I figured it out.

--- let us add a new bool column, is_cancelled, for quantity = -ve

ALTER TABLE staging_source_table
ADD COLUMN is_cancelled BOOLEAN DEFAULT FALSE;

UPDATE staging_source_table
SET is_cancelled = TRUE
WHERE quantity < 0;


SELECT * FROM staging_source_table
WHERE is_cancelled = FALSE AND quantity < 0;
--- zero coulumns where quantiy is zero for non cancelled orders.

-- We also now have a new column

----------------------------------------------------------------- Checking for rows with negative or zero unit prices------------------------------------

SELECT 
	*
FROM
	staging_source_table
WHERE 
	unit_price <= 0;

--- There are 2516 of rows with unit price = 0, and looks like these are for cancelled orders.
--- Lets, see if orders that were not cancelled have unit price set to 0


SELECT 
	*
FROM
	staging_source_table
WHERE 
	unit_price <= 0 AND is_cancelled = FALSE;

--- We do have 1180 rows with unit_price = 0, for is_cancelled = False
--- Let us look for distinct products with unit_price = 0, for is_cancelled = False

--------------------- SKIP BEGAN

-- SELECT 
-- 	COUNT(DISTINCT stock_code)
-- FROM
-- 	staging_source_table
-- WHERE 
-- 	unit_price <= 0 AND is_cancelled = FALSE

--- 683 distinct products with unit_price = 0
--- Let see if we have prices for these stock codes


-- SELECT 
-- 	DISTINCT ON(stock_code)
-- 	stock_code,
-- 	unit_price
-- FROM 
-- 	staging_source_table
-- WHERE 
-- 	stock_code IN (
-- 	SELECT 
-- 		DISTINCT(stock_code)
-- 	FROM
-- 		staging_source_table
-- 	WHERE 
-- 		unit_price <= 0 AND is_cancelled = FALSE	
-- )

-- SELECT COUNT(DISTINCT stock_code) FROM staging_source_table;
--- THERE ARE 4070 distinct stock_code 

-- SELECT COUNT(DISTINCT (stock_code, unit_price)) FROM staging_source_table;
--- THERE ARE 17303 unique combinations of stock_code and unit_price. 
--- I can conclude that product has different prices.

------------------------------ SKIP	END

SELECT 
	*
FROM
	staging_source_table
WHERE 
	unit_price <= 0 AND is_cancelled = FALSE	

--- Looking at the data, most of unit_price == 0.00 are from customer_id which were NULL and we set to 00000. Also, description suggests they were adjustments, bank charges, 
-- These rows contain stock_code = [M(for manual), B(Adjust bad dept), BANK CHARGES(Bank_charges)] : These do not relate to our analysis, and are of no value.
-- Even if we could use these rows, we do not have what amount was spent on bank charges or manual transactions.

--- First lets look into stock_code column TO SEE IF THERE EXISTS ANY RELATION

SELECT
	*
FROM
	staging_source_table
WHERE
	stock_code !~'[0-9]';

-- From these stock_code lets see how many of them have unit_price set to 0.00

SELECT
	*
FROM
	staging_source_table
WHERE
	stock_code !~'[0-9]' AND unit_price=0.00;

--- dropped 18 rows with inconsistent stock code and unit price set to 0. Looks like data entry issue.

DELETE FROM 
	staging_source_table
WHERE
	stock_code !~'[0-9]' AND unit_price=0.00;	

SELECT 
	description, 
	COUNT(*)
FROM
	staging_source_table
WHERE 
	unit_price <= 0 AND is_cancelled = FALSE	
GROUP BY
	description;

-------- DROPPPING ROWS WITH description like amazon, found, ?, check, dotcom
SELECT 
	*
FROM
	staging_source_table
WHERE 
	unit_price <= 0 AND is_cancelled = FALSE	AND customer_id = '00000' AND description IS NOT NULL AND LENGTH(description) < 15;

DELETE FROM 
	staging_source_table
WHERE
	unit_price <= 0 AND is_cancelled = FALSE	AND customer_id = '00000' AND description IS NOT NULL AND LENGTH(description) < 15;
	
---- checking if the remaining products can be imputed with the mean value

WITH product_stock_code AS
(
SELECT 
	stock_code,
	COUNT(*)
FROM
	staging_source_table
WHERE 
	unit_price <= 0 AND is_cancelled = FALSE
GROUP BY
	stock_code
HAVING
	COUNT(*) >= 1
)
SELECT * FROM staging_source_table
WHERE
	stock_code IN (SELECT stock_code FROM product_stock_code)

--- YES, THERE ARE STOCK_CODES WITH PRICES FOR PRODUCTS WIHT UNIT_PRICE == 0.00



--- We can now possibly impute with mean.

WITH avg_unit_price_calculated AS (
SELECT 
	stock_code,
	ROUND(AVG(unit_price), 2) avg_unit_price
FROM 
	staging_source_table
WHERE
	stock_code IN (
		SELECT 
			stock_code
		FROM
			staging_source_table
		WHERE 
			unit_price <= 0 AND is_cancelled = FALSE)
	
GROUP BY stock_code 
) 
UPDATE staging_source_table AS sst
SET
	unit_price = aupc.avg_unit_price
FROM 
	(SELECT * FROM avg_unit_price_calculated) AS aupc
WHERE 
	sst.unit_price <= 0 AND sst.is_cancelled = FALSE AND sst.stock_code = aupc.stock_code

--- Lets check the remaining dataset

SELECT
	*
FROM 
staging_source_table
WHERE 
	unit_price <= 0 AND is_cancelled = FALSE AND stock_code = '85226A'

--- We still have 20 rows remaining, THESE ARE SINGLE PRODUCTS WITH UNIT PRICE SET TO ZERO, THERE FORE WE CANNOT FURTHER IMPUTE THESE.

	

---- DROP THE REMAINING UNIT_PRICE = 0

DELETE FROM staging_source_table
WHERE 
	unit_price <= 0 AND is_cancelled = FALSE 



SELECT 
	COUNT(*)
FROM
	staging_source_table
WHERE 
	unit_price <= 0 AND is_cancelled=FALSE;

--- OUTPUTS ZERO
--- ONLY remaining 0.00 for unit_price is for cancelled orders.


SELECT * FROM staging_source_table;


----------------------------------------------------------------- Invalid Invoice Date

SELECT 
	*
FROM 
	staging_source_table
WHERE invoice_date IS NULL;
-- NO NUlls

SELECT
	MIN(invoice_date),
	MAX(invoice_date)
FROM
	staging_source_table;

-- Dates within the range


----------------------------------------------------------------- Invalid Invoice Date

SELECT
	customer_id,
	COUNT(customer_id),
	
FROM
	staging_source_table
GROUP BY customer_id
HAVING COUNT(customer_id) = 0;

--- NO customers with 0 orders


---------------------------------------------------------------- DESCRIPTION

SELECT 
	*
FROM staging_source_table
WHERE
	description IS NULL;

--- For all canceled orders, the descriptions has been omitted.
--- Our analysis doesnot involve description, therefore I am imputing these description with 'orders do not have description'

UPDATE staging_source_table
SET
	description = 'orders do not have description'
WHERE
	description IS NULL;

--- check if worked
SELECT 
	*
FROM staging_source_table
WHERE
	description IS NULL;

--- NO more nulls in description



----------------------------------------------------------------- stock_code 
-- We hve previoulsy relaised that stock code column has inconsistencies in them. 
--- We were informed that stock_code was 5 digit numeric followed by an alphabet(some cases)


SELECT 
	*
FROM
	staging_source_table
WHERE 	
	stock_code !~'[0-9]' AND is_cancelled = FALSE













