
--- CREATING NORMALISED TABLE

------------------------------------------------------------------------- CUSTOMER TABLE
DROP TABLE customers CASCADE;
CREATE TABLE customers
(
	id VARCHAR(20) PRIMARY KEY, 
	country VARCHAR(50)
);

--- Insert into this table

INSERT INTO customers (id, country)
SELECT
	DISTINCT customer_ID, country
FROM
	staging_source_table
ON CONFLICT (id) DO NOTHING;


SELECT COUNT(*)
FROM customers;


-- 4372 unique customers

------------------------------------------------------------------------- PRODUCTS TABLE

CREATE TABLE products (
    stock_code VARCHAR(50) PRIMARY KEY,   
    unit_price NUMERIC(10,2)
);

CREATE TABLE product_details (
	id SERIAL PRIMARY KEY,
	description TEXT,
	unit_price NUMERIC(10,2),
	products_id VARCHAR(50),
	CONSTRAINT product_fk FOREIGN KEY(products_id) REFERENCES products(stock_code) ON DELETE SET NULL
)


SELECT
	COUNT(DISTINCT (stock_code, description, unit_price))
FROM
	staging_source_table;

--- THERE ARE TOTAL OF 17518
--- unique products


SELECT
	stock_code, description, unit_price,
	COUNT(DISTINCT (stock_code, description, unit_price))
FROM
	staging_source_table
GROUP BY
	stock_code, description, unit_price

--- Completely forgot that, each products have variable unit prices and seperate description. We need to accomodate that by adding a nother table for these products. 


ALTER TABLE products
DROP unit_price;


INSERT INTO products (stock_code)
SELECT DISTINCT stock_code
FROM staging_source_table;



---- INSERTED 4053 RECORDS
INSERT INTO product_details (description, unit_price, products_id)
SELECT
	DISTINCT description, unit_price, stock_code	
FROM
	staging_source_table

--- INSERTED 17518

SELECT * FROM 

SELECT COUNT(DISTINCT (description, unit_price, stock_code)) FROM
staging_source_table
WHERE
stock_code = '21429';

SELECT COUNT(*)
FROM products p
INNER JOIN
	product_details pd
ON p.stock_code = pd.products_id
WHERE p.stock_code = '21429'


--- MATCHES 7 == 7 !


SELECT 
	*
FROM
	staging_source_table
WHERE
	invoice_no = '546986';


------------------------------------------------------------------------- INVOICE TABLE

CREATE TABLE invoices (
	invoice_no VARCHAR(20) PRIMARY KEY,
	invoice_date TIMESTAMP NOT NULL, 
	customer_id VARCHAR(20),
	is_cancelled BOOLEAN DEFAULT FALSE,

	CONSTRAINT customer_fk FOREIGN KEY(customer_id) REFERENCES customers(id) ON DELETE SET NULL
)

INSERT INTO invoices 
SELECT	
	DISTINCT ON (invoice_no, customer_id, is_cancelled) invoice_no, invoice_date, customer_id, is_cancelled
FROM
	staging_source_table
	

DROP TABLE invoice_items;
CREATE TABLE invoice_items; (
	invoice_item_id SERIAL PRIMARY KEY, 
	invoice_no VARCHAR(20),
	stock_code VARCHAR(20),
	quantity INT NOT NULL, 
	unit_price NUMERIC(10,2) NOT NULL,

	CONSTRAINT invoice_no_fk FOREIGN KEY (invoice_no) REFERENCES invoices(invoice_no),
    CONSTRAINT products_fk FOREIGN KEY (stock_code) REFERENCES products(stock_code)
)

INSERT INTO invoice_items (invoice_no, stock_code, quantity, unit_price)
SELECT 
	invoice_no, stock_code, quantity, unit_price
FROM
	staging_source_table




