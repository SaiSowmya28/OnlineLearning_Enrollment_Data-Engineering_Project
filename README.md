# Online Learning Enrollment Data Engineering Project

## Project Overview
This project demonstrates an end-to-end data engineering pipeline built using **Databricks** and the **Medallion Architecture** to process online learning enrollment data.

The pipeline transforms raw enrollment records into clean, validated, and business-ready datasets for reporting and analytics.

## Business Problem
Online learning platforms need a reliable way to manage enrollment data and understand learner behavior, course popularity, and enrollment trends.

The objective is to build a structured data pipeline that converts raw enrollment data into meaningful business insights.

## Technologies Used
- Databricks
- Python
- SQL
- Unity Catalog
- Power BI / Databricks Dashboards

## Data Architecture

The project follows the Medallion Architecture:

1. **Bronze Layer:** Stores raw enrollment data ingested from CSV files.
2. **Silver Layer:** Performs data cleaning, validation, and transformation. Separates valid and rejected records.
3. **Gold Layer:** Creates business summary tables and analytical datasets.
4. **Dashboard:** Visualizes enrollment trends and business insights.

## Project Workflow

CSV File → Unity Catalog Volume → Bronze → Silver → Gold → Dashboard

## Key Activities
- Ingested CSV data into Databricks.
- Stored raw data in the Bronze layer.
- Cleaned and validated enrollment records in the Silver layer.
- Identified and separated rejected records.
- Created Gold summary tables for business analysis.
- Developed dashboards to visualize enrollment insights.

## Business Insights
The project supports analysis of:
- Total course enrollments.
- Course popularity.
- Learner enrollment status.
- Enrollment trends.
- Valid and rejected records.

## Project Outcome
Successfully developed a structured data pipeline using Databricks Medallion Architecture, transforming raw enrollment data into analytics-ready datasets and interactive business dashboards.

## Repository Structure
```text
Online-Learning-Enrollment/
│
├── data/
├── notebooks/
│   ├── Bronze_Layer
│   ├── Silver_Layer
│   └── Gold_Layer
│
├── dashboards/
├── screenshots/
└── README.md
```

## Conclusion
This project demonstrates practical data engineering concepts, including data ingestion, ETL processing, data quality validation, Delta Lake, and analytical reporting using Databricks.
