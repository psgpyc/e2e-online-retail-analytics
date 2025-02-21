
-- CREATING A TABLE TO LOAD raw, unmodified dataset from the CSV file

CREATE TABLE staging_source_table (
	id SERIAL PRIMARY KEY, 
	invoice_no VARCHAR(20) NOT NULL,
	stock_code VARCHAR(50) NOT NULL CHECK(LENGTH(stock_code) > 0),
	description TEXT, 
	quantity INT NOT NULL,
	invoice_date TIMESTAMP NOT NULL, 
	unit_price NUMERIC(10, 2) NOT NULL, 
	customer_id VARCHAR(20),
	country VARCHAR(50) NOT NULL

);


--- Loading the data to the db table

COPY staging_source_table(invoice_no, stock_code, description, quantity, invoice_date, unit_price, customer_id, country) 
FROM '/Users/psgpyc/Datasets/OnlineRetail.csv'
WITH (FORMAT csv, HEADER true);

--- Looking into the new staging table

SELECT * FROM staging_source_table;

--- Let us look into null counts in each rows

CREATE OR REPLACE FUNCTION get_null_counts()
RETURNS TABLE (
    total_rows BIGINT,
    null_count_invoice_number BIGINT,
    null_count_stock_code BIGINT,
    null_count_description BIGINT,
    null_count_quantity BIGINT,
    null_count_invoice_date BIGINT,
    null_count_invoice_price BIGINT,
    null_count_customer_id BIGINT,
    null_count_country BIGINT
)
AS $$
    SELECT 
        COUNT(*) AS total_rows,
        COUNT(*) - COUNT(invoice_no) AS null_count_invoice_number, 
        COUNT(*) - COUNT(stock_code) AS null_count_stock_code, 
        COUNT(*) - COUNT(description) AS null_count_description, 
        COUNT(*) - COUNT(quantity) AS null_count_quantity, 
        COUNT(*) - COUNT(invoice_date) AS null_count_invoice_date, 
        COUNT(*) - COUNT(unit_price) AS null_count_invoice_price, 
        COUNT(*) - COUNT(customer_id) AS null_count_customer_id, 
        COUNT(*) - COUNT(country) AS null_count_country
    FROM staging_source_table;
$$ LANGUAGE SQL;


SELECT 
	*
FROM 
	get_null_counts();

--- looks like we have a huge number of customer_id missing.

--- We will be doing customer-level analysis (RFM, CLV) which requires reliable customer identification. 
--- Aditionally, we will also be doing sales level analysis. Therefore, I will be imputing the misisng Customer IDs as 000000.


UPDATE staging_source_table
SET 
	customer_id = '00000'
WHERE
	customer_id IS NULL;


--- Let us call the function again to check for missing values.

SELECT 
	*
FROM 
	get_null_counts();

-- We only have description column with null values, which is fine.
