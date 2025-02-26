# Project: End-to-End Data Pipeline & Analysis for UCI Online Retail Dataset

## Overview

This project involves transforming and analyzing the UCI Online Retail dataset. Our goal is to create a clean, reliable dataset that can drive actionable insights. We started with raw XLSX data, performed a series of data quality checks, and prepared the data for advanced analytics.

## Data Ingestion & Transformation

1. **XLSX to CSV Conversion**
   - Converted the original XLSX file to CSV using a Python script.

2. **Loading into Staging Table**
   - Imported the CSV data into a PostgreSQL staging table.

3. **Imputation of Missing Values**
   - Imputed missing `customer_id` values with a placeholder (e.g., `00000`).

## Data Quality Checks & Cleaning

1. **Duplicate Rows**
   - Identified and dropped duplicate rows from the staging table.

2. **Handling Cancelled Orders**
   - Negative quantity values were recognized as cancelled orders.
   - A new boolean column was added to flag whether an order is cancelled.

3. **Unit Price Issues**
   - Identified 1,180 rows where `unit_price` equals 0, spanning 683 distinct products.
   - Noted that the same products sometimes had different `stock_code` values and varied prices.

4. **Dropping Irrelevant Rows**
   - **Action Taken:**  
     Dropped all rows where `customer_id` is null and rows with stock codes such as:
     - `M` (Manual)
     - `B` (Adjust bad dept)
     - `BANK CHARGES` (Bank_charges)
   - **Rationale:**  
     These rows did not contain meaningful consumer transaction data or a valid measure of spending and were not relevant for our analysis.
   - **Outcome:**  
     After this cleanup, we dropped 1,134 rows, leaving 46 rows to be handled separately.

5. **Imputation with Mean Values**
   - After dropping the irrelevant rows, we imputed missing or anomalous values using the mean value.
   - As a result, the only remaining 0.00 values for `unit_price` are in cancelled orders, which is acceptable for our analysis.

6. **Handling Cancelled Order Descriptions**
   - For cancelled orders where the description was omitted, we imputed the description with "cancelled orders do not have description" to maintain consistency.
   - Since our analysis does not heavily rely on the description field, this standardization does not impact the insights.

7. **Date Validity**
   - Verified that all invoice dates are valid with no anomalies.

8. **Final Data Quality Outcome**
   - The cleaned dataset now contains 37 rows and 31 distinct invoice numbers.
   - The dataset is robust and ready for further advanced analytics.

## Summary of Data Quality Process

- **Data Ingestion:**  
  - Converted XLSX to CSV and loaded the data into a staging table.
- **Data Cleaning:**  
  - Imputed missing `customer_id` values.
  - Removed duplicate rows.
  - Flagged cancelled orders using negative quantity values.
  - Dropped irrelevant rows (those with null `customer_id` and stock codes like `M`, `B`, `BANK CHARGES`).
  - Imputed missing values with the mean, ensuring consistency.
  - Imputed missing descriptions for cancelled orders.
  - Confirmed date integrity.
- **Final Outcome:**  
  - A cleaned dataset with 37 rows and 31 distinct invoices.
  - Only cancelled orders have a `unit_price` of 0, which is expected.

This comprehensive data quality process sets a strong foundation for the next steps in our analysis, including advanced analytics such as RFM segmentation, cohort analysis, and market basket analysis.
