WITH first_purchase AS (
  SELECT 
    customer_id, 
    MIN(invoice_date) AS first_purchase_date
  FROM invoices
  WHERE is_cancelled = FALSE
  GROUP BY customer_id
),
customer_orders AS (
  SELECT 
    i.customer_id,
    i.invoice_date,
    fp.first_purchase_date,
    DATE_TRUNC('month', fp.first_purchase_date) AS cohort_month, 
    -- Months elapsed since the first purchase // muyltiplying by year by 12 to convert in months.
	
    ( (DATE_PART('year', i.invoice_date) * 12 + DATE_PART('month', i.invoice_date)) - 
      (DATE_PART('year', fp.first_purchase_date) * 12 + DATE_PART('month', fp.first_purchase_date)) ) AS months_since_first_purchase
  FROM invoices i
  JOIN first_purchase fp ON i.customer_id = fp.customer_id
  WHERE i.is_cancelled = FALSE
)
SELECT 
  TO_CHAR(cohort_month, 'YYYY-MM') AS cohort,
  months_since_first_purchase,
  COUNT(DISTINCT customer_id) AS active_customers
FROM customer_orders
GROUP BY cohort_month, months_since_first_purchase
ORDER BY cohort_month, months_since_first_purchase;


SELECT
	DATE_PART('month', DATE '2024-12-10') 