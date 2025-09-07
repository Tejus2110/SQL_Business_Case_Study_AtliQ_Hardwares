# SQL_Business_Case_Study_AtliQ_Hardwares

## Project Overview
This project presents an in-depth SQL-driven analysis of AtliQ Hardwares, a fictional global computer hardware company. The objective was to extract actionable business insights from transactional and cost data using SQL, validate outputs through Excel, and present findings in a structured management presentation.
The analysis uncovers key regional, customer, product, channel, and discount trends and translates them into strategic recommendations for business decision-making.

## Dataset Description

The dataset mimics a real-world ERP/transactional environment with multiple fact and dimension tables.
Sales Data: Customer, product, market, region, channel, sold quantity, sales amount, fiscal year (Sept–Aug), and gross unit price.
Manufacturing Cost Data: Per-unit product costs tied to fiscal years.
Gross Price Data: Pre-discount gross prices per product.
Discount Data: Pre-invoice discounts at customer and fiscal year level, including discount bands.
Product Hierarchies: Division (PC, Peripherals & Accessories, Network & Storage), segment, and standardized variant (Standard, Plus, Premium).
Geographic Dimensions: Region (APAC, EU, NA, LATAM) and markets (countries or country groups).

## Key definitions:

Gross Sales = Quantity × Gross Price.
Net Sales = Gross Sales – Discounts.
Net Profit = Net Sales – Manufacturing Costs.
Fiscal Year = September through August.

## Analysis Performed

1. Regional and Market Insights

APAC is the largest revenue region, with India, South Korea, and the Philippines as top markets.
EU posted the strongest year-over-year growth (~256%), while LATAM lagged (~42%) despite heavy discounting.
North America is anchored by the USA as the largest single-country market.
Retail dominates sales across all regions, contributing ~73% of revenue.
Implication: Growth should be prioritized in APAC and EU, while LATAM requires a re-evaluated strategy as discounts have not stimulated demand.

2. Customer Insights

Top 10 customers (e.g., Amazon, AtliQ eStore, Flipkart) contribute ~50% of total revenue.
Bulk of unit volumes are in low-margin products, but profitability is concentrated in high- and medium-margin items.
Notebooks deliver the highest per-unit profitability, despite lower sales volumes.
Implication: AtliQ should deepen relationships with key accounts by pushing high-margin products, while also diversifying beyond the top 10 customers to mitigate concentration risk.

3. Product, Division, and Segment Insights

Peripherals & Accessories (P&A) drive the most revenue; however, PCs grew the fastest year-over-year, especially Desktop PCs.
Notebook and Business PCs generate the highest unit profitability.
A large share of sales comes from Plus/Premium variants with high manufacturing-cost-to-price ratios, creating margin risk.
Accessories expanded significantly, adding ~34 products between 2020–21.
Implication: Portfolio balance is required: grow high-profit PCs and notebooks, manage reliance on premium SKUs, and continue expanding accessories to broaden the base.

4. Channel Insights

Retail accounts for ~73% of total sales and showed the strongest growth (~221% YoY).
Distributor channel also expanded strongly (~211% YoY), while Direct (online) grew modestly (~167% YoY).
Discounting levels differ slightly across channels, with Direct showing lower average discounts.
Implication: Retail and Distributor channels remain strategic priorities, though Direct can be selectively grown to capture long-term e-commerce potential.

5. Discount Insights
Discounts are nearly uniform across divisions, segments, and product variants (~23%).
LATAM customers receive the highest discounts yet show the weakest growth.
Discounts are most aggressive on low-margin products, where returns are limited.
Implication: Discounting strategy should be rebalanced—reduce unnecessary discounts in low-margin categories and LATAM, while targeting incentives toward medium/high-margin products where profitability is stronger.

6. Seasonal Insights
All quarters in FY2021 grew versus FY2020, but demand peaked in Q1 and declined steadily by Q4.
Growth slowed quarter-over-quarter, suggesting a need for demand-smoothing initiatives in later quarters.
Implication: Inventory and marketing should be aligned with peak Q1 demand, while targeted campaigns or product launches should support weaker Q3–Q4 sales.

## Strategic Recommendations

Invest in High-Growth Regions: Prioritize EU and APAC for further resource allocation and market expansion.
Optimize Customer Portfolio: Push high-margin products to top accounts while diversifying customer base.
Refine Product Mix: Emphasize PCs and laptops for profitability, expand accessories, and manage premium SKU reliance.
Strengthen Retail & Distributor Channels: Continue supporting these dominant channels with co-promotions and partner incentives.
Re-evaluate LATAM Strategy: Tailor product fit and reduce ineffective discounts.
Seasonal Planning: Build supply ahead of Q1 peaks and strengthen late-year campaigns.
Profitability Monitoring: Establish dashboards tracking net profit by region, customer, and product to guide future decisions.

## Tools and Workflow

SQL: Data extraction, joins, aggregations, CTEs, window functions, profitability calculations.
Excel: Validation, pivot tables, and exploratory visualization.
PresentationAI: Structured presentation of insights and recommendations for management.
Workflow followed: SQL → Excel validation → Charting → Business presentation.

## Deliverables

SQL scripts for all queries.
Output tables and charts documenting results.
Insights and recommendation reports.
Final management presentation in PowerPoint.
