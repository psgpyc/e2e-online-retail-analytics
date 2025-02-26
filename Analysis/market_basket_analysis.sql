--- Market Basket Analysis:
--- Identifying which products are purchased together

SELECT
    a.stock_code AS product_a,
    b.stock_code AS product_b,
    COUNT(DISTINCT a.invoice_no) AS co_occurrence_count
FROM invoice_items a
JOIN invoice_items b
  ON a.invoice_no = b.invoice_no
  AND a.stock_code < b.stock_code -- each pair is counted only once
GROUP BY a.stock_code, b.stock_code
HAVING COUNT(DISTINCT a.invoice_no) > 50 
ORDER BY co_occurrence_count DESC
LIMIT 10;
