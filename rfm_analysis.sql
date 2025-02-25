--- RFM Segmentation

WITH customers_orders AS (
	SELECT
		i.customer_id,
		MAX(i.invoice_date) AS last_purchase_date,
		COUNT(DISTINCT i.invoice_no) AS frequency, 
		SUM(ii.quantity * ii.unit_price) AS monetary
	FROM 
		invoices i
	JOIN
		invoice_items ii
	ON 
		i.invoice_no = ii.invoice_no
	WHERE
		i.is_cancelled = FALSE AND i.customer_id != '00000'
	GROUP BY
		i.customer_id),
rfm_calculation AS (
	SELECT 
		customer_id, 
		DATE_PART('day', DATE '2012-01-01' - last_purchase_date) AS days_since_last_purchase, 
		frequency,
		monetary,
		--- We want customers with lower dates to score higgher, therefore inverting the socre. // now, higher score is better // consistent with freq and mon score.
		(6 - NTILE(5) OVER (ORDER BY DATE_PART('day', DATE '2012-01-01' - last_purchase_date))) AS recency_score,

		--- Higer the frequency and monetary score, suggest frequent orders and high monetary value
		NTILE(5) OVER (ORDER BY frequency) AS frequency_score, 
		NTILE(5) OVER (ORDER BY monetary) AS monetary_score
	FROM
		customers_orders
)
SELECT
	*
FROM
	rfm_calculation;
	

