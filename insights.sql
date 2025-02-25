--- 1. CUSTOMERS INSIGHTS

SELECT
	DISTINCT COUNT(*)
FROM 
	customers;

-- we have a total of 4372 unique customers


SELECT 
	country,
	COUNT(id) AS total_customers_by_country, 
	ROUND(COUNT(id) * 1.0/ (SELECT COUNT(*) FROM customers)*100, 2)  AS percentage_distribution_by_country
FROM 
	customers
GROUP BY
	country
ORDER BY 
	COUNT(id) DESC;

-- 90% of our customers are from the uk.


-- Customer grouped based on order placed.

-- An unique order is defined by an unique invoice_no

-- I am excluding customer 00000,as it is a place holder for all the nulls.


SELECT 
	customer_id, 
	COUNT(invoice_no) AS total_order_placed
FROM
	invoices
WHERE 
	customer_id != '00000'
GROUP BY
	customer_id
ORDER BY
	COUNT(invoice_no) DESC

--- customer 14911 placed a total of 248 orders.

--- Calculate avg. order count, standard deviation and median of orders by customers.

WITH customer_order_volume AS (
SELECT 
	customer_id, 
	COUNT(invoice_no) AS total_order_placed
FROM
	invoices
WHERE 
	customer_id != '00000'
GROUP BY
	customer_id)
SELECT 
	CAST(AVG(total_order_placed) AS INT) AS avg_order_placed,
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_order_placed) AS median_order_placed,
	CAST(STDDEV(total_order_placed) AS INT) AS standard_dev
FROM
	customer_order_volume	

-- On average a customer places around 5 orders. Excluding orders from customer_id = '00000'
-- Median is 3, this suggest our data is right skewed.


---------------------------------------------------------------------------------------------------------------------------------------------  Invoices Table


WITH order_interval AS (
SELECT
	MIN(invoice_date) AS first_order_date,
	MAX(invoice_date) AS last_order_date,
	AGE(MAX(invoice_date), MIN(invoice_date)) AS total_interval
FROM
	invoices)
SELECT
	first_order_date AS from, 
	last_order_date AS to, 
	CONCAT(
		EXTRACT('year' FROM total_interval),
		' years ',
		EXTRACT('days' FROM total_interval),
		' days'
	) AS total_interval
FROM
	order_interval;

--- We have sales data of 1 years 8 days

--- Month-over-Month Order GROWTH metrics

WITH month_by_month_sales_volume AS (
SELECT
	DATE_TRUNC('months', invoice_date) AS order_months, 
	COUNT(invoice_no) as total_orders
FROM
	invoices
GROUP BY
	DATE_TRUNC('months', invoice_date)),
month_vs_prev_month AS (
SELECT 
	order_months, 
	total_orders AS current_month_total_orders,
	LAG(total_orders) OVER(ORDER BY order_months) AS prev_month_total_orders
FROM
	month_by_month_sales_volume)
SELECT
	TO_CHAR(order_months, 'YYYY-MM-DD'), 
	current_month_total_orders,
	COALESCE(prev_month_total_orders,0) AS prev_month_total_orders,
	ROUND(COALESCE((current_month_total_orders - prev_month_total_orders) * 1.0/(prev_month_total_orders),0),2) AS per_growth
FROM
	month_vs_prev_month;

---- WHAT % OF ORDERS ARE CANCELLED


SELECT
	ROUND(COUNT(invoice_no) * 1.0 / (SELECT COUNT(*) FROM invoices) * 100, 2) AS total_cancelled_orders
FROM
	invoices
WHERE
	is_cancelled = TRUE

-- 20.58% of the total orders are cancelled 


--- MONTH OVER MONTH CANCELLED METRICES COMPARED TO ORDER METRICS

WITH month_by_month_sales_volume AS (
SELECT
	DATE_TRUNC('months', invoice_date) AS order_months, 
	COUNT(invoice_no) as total_orders
FROM
	invoices
GROUP BY
	DATE_TRUNC('months', invoice_date)), 
-- cte to calculate mom cancelled
month_by_month_cancelled_volume AS (
SELECT
	DATE_TRUNC('months', invoice_date) AS order_months, 
	COUNT(invoice_no) as total_cancelled
FROM
	invoices i
WHERE 
	is_cancelled = TRUE
GROUP BY
	DATE_TRUNC('months', invoice_date))
SELECT 
	mmcv.order_months, 
	mmsv.total_orders AS total_order_received,
	mmcv.total_cancelled AS total_cancelled,
	ROUND(((mmcv.total_cancelled * 1.0) / (total_orders))*100, 2) AS per_cancelled
	
FROM 
	month_by_month_cancelled_volume mmcv
FULL OUTER JOIN
	month_by_month_sales_volume mmsv
ON mmcv.order_months = mmsv.order_months
ORDER BY mmcv.order_months 

-- On April we received a total of 1672 orders and 426 were cancelled, a cancellation rate of 25.48%. This is the highest cancellation rate in the observed period.




----------------------------------------------------------------------- Invoices Table Product Analysis

SELECT
	invoice_no, 
	COUNT(stock_code) AS total_products_in_an_order
FROM
	invoice_items
GROUP BY
	invoice_no
ORDER BY 
	COUNT(stock_code) DESC

--- WOW, invoice_no 573585 has a total of 1114 products in it. 

--- I find it unusual. Lets dive deeper.

SELECT 
	i.invoice_no, 
	ii.stock_code,
	i.customer_id, 
	i.invoice_date
FROM
	invoice_items ii
JOIN
	invoices i
ON
	ii.invoice_no = i.invoice_no
WHERE
	ii.invoice_no = '573585';

-- The order was placed by customer_id 00000, on 2011-10-31 14:41:00. There is nothing wrong with this.


---- Order value invoices

SELECT
	invoice_no,
	SUM(quantity) AS total_qunatity_ordered,
	SUM(quantity * unit_price) AS order_value
FROM
	invoice_items
GROUP BY
	invoice_no
HAVING 
	SUM(quantity * unit_price) > 0
ORDER BY
	SUM(quantity * unit_price) DESC;

-- Our largest order on a single invoice is of 168469.


--- Total revenue
WITH invoice_order_value AS (
SELECT
	invoice_no,
	SUM(quantity * unit_price) AS order_value
FROM
	invoice_items
GROUP BY
	invoice_no
HAVING 
	SUM(quantity * unit_price) > 0 )
SELECT 
	SUM(order_value) AS total_revenue
FROM 
	invoice_order_value
WHERE	
	order_value > 0;
-- Our total revenue is 10,643,627.27

-- Lost Revenue

WITH invoice_order_value AS (
SELECT
	invoice_no,
	SUM(quantity * unit_price) AS order_value
FROM
	invoice_items
GROUP BY
	invoice_no
HAVING 
	SUM(quantity * unit_price) < 0 )
SELECT 
	ABS(SUM(order_value)) AS lost_revenue
FROM 
	invoice_order_value
WHERE	
	order_value < 0;

-- We lost 893,979.73 

	

--------------------------------------------------------------- REVENUE MONTH OVER MONTH

WITH month_by_month_rev AS (
SELECT
	TO_CHAR(DATE_TRUNC('months', i.invoice_date), 'YYYY-MM-DD') AS curr_month,
	SUM(ii.quantity * ii.unit_price) AS curr_month_rev 
FROM
	invoice_items ii
JOIN
	invoices i
ON
	i.invoice_no = ii.invoice_no
WHERE
	i.is_cancelled = FALSE
GROUP BY
	DATE_TRUNC('months', i.invoice_date)
ORDER BY
	DATE_TRUNC('months', i.invoice_date)),
month_vs_prev_month AS (
SELECT 
	curr_month, 
	curr_month_rev,
	LAG(curr_month_rev) OVER(ORDER BY curr_month) AS prev_month_rev
FROM 
	month_by_month_rev)
SELECT
	curr_month, 
	curr_month_rev, 
	COALESCE(prev_month_rev, 0) AS prev_month_rev,
	COALESCE(ROUND(((curr_month_rev - prev_month_rev)/(prev_month_rev))*100,2), 0) AS rev_growth
FROM
	month_vs_prev_month;


--------------------------------------------------------------- REVENUE LOST MONTH OVER MONTH

WITH month_by_month_rev_lost AS (
SELECT
	TO_CHAR(DATE_TRUNC('months', i.invoice_date), 'YYYY-MM-DD') AS curr_month,
	SUM(ii.quantity * ii.unit_price) AS curr_month_rev_lost 
FROM
	invoice_items ii
JOIN
	invoices i
ON
	i.invoice_no = ii.invoice_no
WHERE
	i.is_cancelled = TRUE
GROUP BY
	DATE_TRUNC('months', i.invoice_date)
ORDER BY
	DATE_TRUNC('months', i.invoice_date)),
month_vs_prev_month AS (
SELECT 
	curr_month, 
	curr_month_rev_lost,
	LAG(curr_month_rev_lost) OVER(ORDER BY curr_month) AS prev_month_rev_lost
FROM 
	month_by_month_rev_lost)
SELECT
	curr_month, 
	ABS(curr_month_rev_lost), 
	COALESCE(ABS(prev_month_rev_lost), 0) AS prev_month_rev_lost,
	COALESCE(ROUND(((ABS(curr_month_rev_lost) - ABS(prev_month_rev_lost))/(ABS(prev_month_rev_lost)))*100,2), 0) AS rev_lost_change
FROM
	month_vs_prev_month;










