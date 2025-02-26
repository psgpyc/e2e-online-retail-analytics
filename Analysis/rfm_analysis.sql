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
), rfm_score AS (
SELECT

	customer_id, 
	recency_score, 
	frequency_score, 
	monetary_score,
	(recency_score+frequency_score+monetary_score) AS overall_rfm_score
FROM
	rfm_calculation),
segments AS (	
SELECT
	customer_id, 
	overall_rfm_score, 
	CASE
		WHEN recency_score = 5 AND frequency_score = 5 AND monetary_score = 5 THEN 'Champions'
		WHEN overall_rfm_score >= 12 THEN 'Returning and Loyal'
		WHEN overall_rfm_score >= 9 THEN 'Less Frequent but Loyal'
		WHEN overall_rfm_score >= 6 THEN 'At Risk'
		ELSE 'Dormant'
	END AS customer_segment
FROM rfm_score)
SELECT
	customer_segment,
	COUNT(*) AS customer_count,
	ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM segments), 2) AS segment_percentage
FROM
	segments
GROUP BY 
	customer_segment;
		
	
	

