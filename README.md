# E-Commerce Customer Retention Analysis (SQL)

## Project Overview
This project analyzes customer retention and puchasing behavior for an e-commerce business using SQL only.

The goal is to build an analytics-ready data model and answer the key business questions related to revenue, retention, and customer lifecycle.

## Objectives
- Design a clean SQL data pipeline from raw data to analysis
- Build a star schema for analytics
- Analyze customer retention and chort behavior
- Identify repeat purchase patterns and business risks

## Dataset
This project uses the Brazilian E-Commerce public Dataset (Olist), which contains customer, order, payment, product, and seller data.

The dataset is publicly available and included in this repository for reproducibility.

## Tools
-MySQL
-SQL(window function, CTEs, views, aggregation)


## Data Pipeline
1. **Staging**
  - Raw CSV data loading into staging tables
  - Null handling, data type enforcement
  - Data quality checks (duplicates, orphan records, negative values)

2. **Modeling**
  - Star schema design
  - Fact tables: orders, order items, payments
  - Dimention tables/views: customers, products, sellers, dates
  - Derived metrics (order value, delivery time, approval time)

3. **Analysis**
  - One-time vs repeat customers
  - Repeat purchase rate
  - Customer lifetime orders
  - Cohort analysis based on first purchase month

## Key insights
  - 97% of customers purchased only once
  - Repeat purchase rate is approximately 3%
  - Average orders per customer:~1.03
  - A small group of customers shows high lifetime value(up to 15 orders)
  - Business growth is driven mainly by new customer acquisition, not retention

## Outcome
This project delivers a reusable SQL analytics layer that transform raw transactional data into actionable business insights.

The data model and queries are designed to be BI-ready for future dashboarding.
