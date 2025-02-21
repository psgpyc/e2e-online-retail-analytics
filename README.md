## End-to-End Online Retail Analytics using SQl, Python and Tableau.

## Overview

This project showcases the full data pipeline—from data ingestion and transformation to advanced analytics and interactive visualization—highlighting best practices in data engineering, SQL optimization, and ETL automation.

## Project Workflow

1. **Data Ingestion & Preparation:**
   - **Source:** Start with the UCI Online Retail dataset provided in XLSX format.
   - **Transformation:** Convert the XLSX file into CSV to facilitate data loading.
   - **Loading:** Import the CSV data into a PostgreSQL database using a staging table, ensuring the raw data is preserved.

2. **Data Cleaning & Imputation:**
   - Address missing values (e.g., replacing NULL CustomerIDs with a default value of `00000`).
   - Perform thorough data quality checks to ensure consistency and integrity.

3. **Data Transformation & Normalization:**
   - Transform the staging data into a normalized schema comprising:
     - **Dimension Tables:** Customers, Products.
     - **Fact Tables:** Invoices, InvoiceItems.
   - Utilize SQL techniques such as window functions, CTEs, and indexing to optimize query performance.

4. **Advanced Analytics:**
   - Execute complex analyses including RFM segmentation, sales forecasting, and pricing strategy optimization.
   - Leverage SQL queries to derive meaningful insights from the structured data.

5. **Visualization & Automation:**
   - Connect the normalized database to Tableau for interactive dashboards and visual storytelling.
   - Automate the ETL process using Python, ensuring seamless data refreshes and up-to-date analytics.

## Key Takeaways

- **Data Pipeline Mastery:** Demonstrates a robust, auditable ETL process from raw data ingestion to enriched, normalized datasets.
- **Advanced SQL & ETL Skills:** Showcases proficiency in SQL optimization, data transformation, and automated reporting.
- **Business Impact:** Provides actionable insights for retail operations, customer behavior, and revenue trends, making it an ideal project for data analyst and machine learning engineering portfolios.

This project exemplifies industry-standard data practices and is a comprehensive demonstration of end-to-end analytics.

Feel free to explore, contribute, or adapt this project for your own data analysis journey!

Happy Coding!
