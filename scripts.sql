-- Provide the list of markets in which customer  "Atliq  Exclusive"  operates its business in the  APAC  region. 

select distinct market from dim_customer where customer = 'Atliq Exclusive' and region = 'APAC';


-- monthly sales of Atliq Exclusive.
select year(date),monthname(date), sum(sales_amount) as sum_sales from sales_table
where customer = 'Atliq Exclusive'
group by year(date), monthname(date)
order by year(date),monthname(date) asc;

-- What is the percentage of unique product increase in 2021 vs. 2020?
create view unique_products_data as 
(select t1.*,t2.fiscal_year,t2.customer_code,t2.date from dim_product t1 inner join fact_sales_monthly t2 on
t1.product_code = t2.product_code);   

with temp_table as 
(select 
(select count(distinct product_code) from unique_products_data where fiscal_year = 2020 group by fiscal_year) as unique_products_2020,
(select count(distinct product_code) from unique_products_data where fiscal_year = 2021 group by fiscal_year) as unique_products_2021
)
select unique_products_2020, unique_products_2021,
round((((unique_products_2021 - unique_products_2020)/unique_products_2020) * 100),2) as percentage_chg
from temp_table;

-- Provide a report with all the unique product counts for each  segment  and sort them in descending order of product counts.
select segment, count(distinct product) as product_count from dim_product
group by segment
order by count(distinct product) desc;

-- Which segment had the most increase in unique products in 2021 vs 2020?
with t1 as 
(select segment,count(distinct product_code) as product_count_2020 
from unique_products_data where fiscal_year = 2020 
group by segment),
t2 as 
(select segment,count(distinct product_code) as product_count_2021
from unique_products_data where fiscal_year = 2021
group by segment)
select t1.*,t2.product_count_2021,
product_count_2021 - product_count_2020 as difference
from t1 inner join t2 on t1.segment = t2.segment
order by product_count_2021 - product_count_2020 desc;

-- Get the products that have the highest and lowest manufacturing costs.
with min_cost_product as 
(select t1.product_code as min_manufac_cost_pcode,t2.product as min_manufac_cost_prodc from fact_manufacturing_cost t1 inner join 
dim_product t2 on t1.product_code = t2.product_code
where manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost)
),
max_cost_product as 
(select t1.product_code as max_manufac_cost_pcode,t2.product as max_manufac_cost_prodc from fact_manufacturing_cost t1 inner join 
dim_product t2 on t1.product_code = t2.product_code
where manufacturing_cost = (select max(manufacturing_cost) from fact_manufacturing_cost)
)
select
(select min_manufac_cost_prodc from min_cost_product) as min_costing_product,
(select max_manufac_cost_prodc from max_cost_product) as max_costing_product;

-- Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct  for the fiscal year 2021 and in the Indian market.

select t1.customer_code, t1.customer,
concat(round(avg(t2.pre_invoice_discount_pct)*100,2),' % ') as avg_pre_invoice_discount_prec
from dim_customer t1 inner join fact_pre_invoice_deductions t2 
on t1.customer_code = t2.customer_code
where fiscal_year = 2021 and sub_zone = 'India'
group by t1.customer_code,t1.customer
order by avg(t2.pre_invoice_discount_pct) desc limit 5;

-- Get the complete report of the Gross sales amount for the customer  “Atliq Exclusive”  for each month  .  
-- This analysis helps to  get an idea of low and 
-- high-performing months and take strategic decisions. 

create view atliq_exclusive_rdata as 
(select t1.*,
t2.date,t2.product_code,t2.sold_quantity,t2.fiscal_year,
t3.gross_price,
year(t2.date) as `year`,
monthname(t2.date) as month_name,
month(t2.date) as month_number,
t2.sold_quantity * t3.gross_price as sales_amt
from dim_customer t1 inner join fact_sales_monthly t2 on 
t1.customer_code = t2.customer_code
inner join fact_gross_price t3 on t2.product_code = t3.product_code and t2.fiscal_year = t3.fiscal_year
where customer = 'Atliq Exclusive');

select year,month_name,round(sum(sales_amt),2) as gross_sales_amount from atliq_exclusive_rdata
group by year,month_name,month_number
order by year,month_number asc;

-- In which quarter of 2020, got the maximum total_sold_quantity?
with qty_sold as 
(select *,
case 
	when month(date) in (9,10,11) then 'Q1'
	when month(date) in (12,1,2) then '	Q2'
    when month(date) in (3,4,5) then 'Q3'
    when month(date) in (6,7,8) then 'Q4'
end 
as FY20_Quarter
from fact_sales_monthly where fiscal_year = 2020)
select FY20_Quarter,sum(sold_quantity) as qty_sold from qty_sold 
group by FY20_Quarter
order by sum(sold_quantity) desc;
order by sum(sold_quantity) desc;


-- Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
set @total_sales_amount = (select sum(sales_amount) from sales_amount);
select channel,(sum(sales_amount)/(@total_sales_amount)) * 100 as sales_dist_by_channel_2021 from sales_table where fiscal_year = 2021
group by channel order by sales_dist_by_channel_2021 desc;


-- region and channel wise analysis.

--  Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?

with temp_table as
(select 
t1.division,t1.product_code,t1.product,t1.variant,
sum(t2.sold_quantity) as qty_sold,
rank() over(partition by division order by sum(t2.sold_quantity) desc) as `rank`
from dim_product t1 inner join fact_sales_monthly t2 
on t1.product_code = t2.product_code
where fiscal_year = 2021
group by t1.division,t1.product_code,t1.product,t1.variant)
select division,product,qty_sold from temp_table where `rank` < 4;


-- BUSINESS QUESTIONS:
-- QUESTION.
-- Which region and markets contribute the most to the overall revenue and profitability.
-- sales amt vs region wise analysis.
create view sales_table as 
(select t1.*,
t2.date,t2.product_code,t2.sold_quantity,t2.fiscal_year,
t3.gross_price,
t4.division,t4.segment,t4.category,t4.product,t4.variant,
t2.sold_quantity * t3.gross_price as sales_amount
from dim_customer t1 inner join fact_sales_monthly t2 on t1.customer_code = t2.customer_code
inner join fact_gross_price t3 on t3.product_code = t2.product_code and t2.fiscal_year = t3.fiscal_year
inner join dim_product t4 on t2.product_code = t4.product_code);

-- apac region highest sales.
select region,sum(sales_amount) as sales from sales_table
group by region
order by sum(sales_amount) desc;

-- india, south korea, philiphines
select market,sum(sales_amount) as sales from sales_table
where region = 'APAC'
group by market
order by sum(sales_amount) desc;

select market, sum(sales_amount) as sales from sales_table 
group by market 
order by sum(sales_amount) desc limit 10;

-- seasonal sales pattern across markets. -- this can be created using a tableau graphic to show country wise trendline.

select year(date),monthname(date),market,	
sum(sales_amount) as total_sales_in_time_frame
from sales_table
group by year(date),monthname(date),market
order by year(date) asc, monthname(date) asc;

-- highest growth in market - DONE BELOW.
-- highest growth in region.

with regional_sales_2020 as 
(select region,sum(sales_amount) as 2020_sales from sales_table where fiscal_year = 2020
group by region
),
regional_sales_2021 as 
(
select region,sum(sales_amount) as 2021_sales from sales_table where fiscal_year = 2021
group by region
)
select t1.region,2020_sales,2021_sales,
2021_sales - 2020_sales as regional_sales_increase,
((2021_sales - 2020_sales)/(2020_sales)) * 100 as regional_sales_increase_perc
 from regional_sales_2020 t1 inner join regional_sales_2021 t2 on
t1.region = t2.region
order by ((2021_sales - 2020_sales)/(2020_sales)) * 100 desc;


-- monthwise sales trend.
select year(date),month(date),
sum(sales_amount) as total_sales_in_time_frame
from sales_table
group by year(date),month(date)
order by year(date) asc, month(date) asc;



-- Question
-- Which product divisions (PC, Peripherals & Accessories, Network & Storage) are driving the most revenue and profit margins?

-- P & A contribute highest to the revenue.
select division, sum(sales_amount) as sales_amt from sales_table
group by division
order by sum(sales_amount) desc;

-- Question
-- Who are our top 10 customers by gross sales, and what percentage of total sales do they contribute?

-- amazon - 14.65 percent, atliq e store contributes 9.23% and atliq exclusive 8.25% and Flipkart contributes to the 3.60%.
select customer, sum(sales_amount) as sales,
round((sum(sales_amount)/(select sum(sales_amount) from sales_table)) * 100,2) as perc_contribution
from sales_table
group by customer
order by sum(sales_amount) desc limit 10;

-- top 10 customers are contributing to the 50 percetage of the sales.
with temp_table as
(select customer, sum(sales_amount) as sales
from sales_table
group by customer
order by sum(sales_amount) desc limit 10)
select 
sum(sales)/(select sum(sales_amount) from sales_table) as perc_contribution_by_top_customers
from temp_table;

-- Which customer has shown most growth from 2020 to 2021.
with customer_sales_2020 as 
(select customer,sum(sales_amount) as 2020_sales from sales_table where fiscal_year = 2020
group by customer
),
customer_sales_2021 as 
(
select customer,sum(sales_amount) as 2021_sales from sales_table where fiscal_year = 2021
group by customer
)
select t1.customer,2020_sales,2021_sales,
2021_sales - 2020_sales as customer_sales_increase,
((2021_sales - 2020_sales)/(2020_sales)) * 100 as customer_sales_increase_perc
 from customer_sales_2020 t1 inner join customer_sales_2021 t2 on
t1.customer = t2.customer
order by ((2021_sales - 2020_sales)/(2020_sales)) * 100 desc limit 10;

-- Question: Which Category of products are bought by the top 10 customers by sales.
create table top_10_customer_sales_table as
(select * from sales_table where customer in 
('Amazon','Atliq e Store','Atliq Exclusive','Flipkart','Sage','Leader','Ebay','Neptune','Electricalsocity','Synthetic')
);

select * from fact_manufacturing_cost;

-- What are the year-over-year sales growth rates by segment.
with sales_2020 as
(select segment, round(sum(sales_amount),2) as sales_2020 from sales_table where fiscal_year = 2020
group by segment),
sales_2021 as
(select segment, round(sum(sales_amount),2) as sales_2021 from sales_table where fiscal_year = 2021
group by segment)

select t1.segment,t1.sales_2020,t2.sales_2021,
t2.sales_2021 - t1.sales_2020 as sales_inc_or_dec,
round(((t2.sales_2021 - t1.sales_2020)/(t1.sales_2020) * 100),2) as inc_or_dec_perc
from sales_2020 t1 inner join sales_2021 t2 on t1.segment = t2.segment;
-- desktop sales have surged the highest from FY 2020,FY 2021 -- probably due to the covid time.

-- What are the year-over-year sales growth rates by category.
-- repeating same for the category.
with sales_2020 as
(select category, round(sum(sales_amount),2) as sales_2020 from sales_table where fiscal_year = 2020
group by category),
sales_2021 as
(select category, round(sum(sales_amount),2) as sales_2021 from sales_table where fiscal_year = 2021
group by category)

select t1.category,t1.sales_2020,t2.sales_2021,
t2.sales_2021 - t1.sales_2020 as sales_inc_or_dec,
round(((t2.sales_2021 - t1.sales_2020)/(t1.sales_2020) * 100),2) as inc_or_dec_perc
from sales_2020 t1 inner join sales_2021 t2 on t1.category = t2.category;




-- What are the year-over-year sales growth rates by division.
with sales_2020 as
(select division, round(sum(sales_amount),2) as sales_2020 from sales_table where fiscal_year = 2020
group by division),
sales_2021 as
(select division, round(sum(sales_amount),2) as sales_2021 from sales_table where fiscal_year = 2021
group by division)

select t1.division,t1.sales_2020,t2.sales_2021,
t2.sales_2021 - t1.sales_2020 as sales_inc_or_dec,
round(((t2.sales_2021 - t1.sales_2020)/(t1.sales_2020) * 100),2) as inc_or_dec_perc
from sales_2020 t1 inner join sales_2021 t2 on t1.division = t2.division;





-- Which products have the highest manufacturing cost-to-price ratio (low margin products).
with temp_table_2 as
(with temp_table as
(select t1.product_code,t1.cost_year,t1.manufacturing_cost,t2.gross_price
from
fact_manufacturing_cost t1 inner join 
fact_gross_price t2 on t1.product_code = t2.product_code
and t1.cost_year = t2.fiscal_year)
select product_code, avg(manufacturing_cost)/avg(gross_price) as cost_to_price
from temp_table
group by product_code
order by avg(manufacturing_cost)/avg(gross_price) desc)
select t1.product_code,t1.cost_to_price,t2.product,t2.cleaned_variant
 from temp_table_2 t1 inner join dim_product t2 on t1.product_code = t2.product_code
 order by t1.cost_to_price desc limit 10;
 
-- 	Question.
-- What are the seasonal sales patterns across markets?
-- get a line graph of this.
select year(date) as `year`,monthname(date) as `month`, year(date), month(date),sum(sales_amount) as sales from sales_table
group by year(date),monthname(date),year(date), month(date) order by year(date) asc, month(date) asc;

-- find which product was sold most during a particular month.

with temp_table as 
(select *,
rank() over(partition by year(date),month(date) order by sales_amount desc rows between unbounded preceding and unbounded following) `rank`
from sales_table)
select * from temp_table where `rank` = 1;



-- Question.
-- Which sales channels (Retailers, Direct, Distributors) generate the most revenue and which bring in higher margins?
select channel, 
sum(sales_amount) as sales,
round((sum(sales_amount)/(select sum(sales_amount) from sales_table)) * 100,2) as perc_contribution
from sales_table
group by channel
order by sum(sales_amount) desc;

-- How much discounting are we doing by customer and region, and what is its impact on margins?
create view discount_info as 
(select t1.*,
t2.customer, t2.region,t2.market
from fact_pre_invoice_deductions t1 inner join dim_customer t2 on t1.customer_code = t2.customer_code);

select customer, avg(pre_invoice_discount_pct) as avg_pre_invoice_discount_pct from discount_info
group by customer
order by avg(pre_invoice_discount_pct) desc limit 10;

-- discount and region.
select region, avg(pre_invoice_discount_pct) as avg_pre_invoice_discount_pct from discount_info
group by region
order by avg(pre_invoice_discount_pct) desc;
-- discount and market 
select market, avg(pre_invoice_discount_pct) as avg_pre_invoice_discount_pct from discount_info
group by market
order by avg(pre_invoice_discount_pct) desc limit 10;



-- why are giving most of the discount to the LATAM customers but highest sales are in APAC.

-- What is the share of premium vs standard variants in total sales

select standardised_variant,sum(sales_amount) as sales,
sum(sales_amount)/(select sum(sales_amount) from sales_table) as perc_contribution
from sales_table
group by standardised_variant;

-- QUESTION
-- Which products are consistetly top-sellers vs underperformers across fiscal years?

-- most revenue generating product across years.
with top_sales_generating_product_years as
(select fiscal_year,product_code,product,
sum(sales_amount) as sales_amt,
rank() over(partition by fiscal_year order by sum(sales_amount) desc rows between unbounded preceding and unbounded following) as `rank`
from sales_table
group by fiscal_year,product_code,product)
select * from top_sales_generating_product_years 
where `rank` = 1;

-- most sold product across years.
with most_selling_product_years as
(select fiscal_year,product_code,product,
sum(sold_quantity) as sold_quantity,
rank() over(partition by fiscal_year order by sum(sold_quantity) desc rows between unbounded preceding and unbounded following) as `rank`
from sales_table
group by fiscal_year,product_code,product)
select * from most_selling_product_years 
where `rank` = 1;
 
 
-- Which markets/customers have shown the highest sales growth vs decline over the last 2 years?

with sales_2020 as 
(select market, sum(sales_amount) as sales_2020 from sales_table
where fiscal_year = 2020
group by market
),
sales_2021 as
(
select market, sum(sales_amount) as sales_2021 from sales_table
where fiscal_year = 2021
group by market
)
select t1.market,t1.sales_2020,t2.sales_2021,
t2.sales_2021 - t1.sales_2020 as sales_inc_or_dec,
round(((t2.sales_2021 - t1.sales_2020)/t1.sales_2020)*100,2) as sales_inc_or_dec_prec
from sales_2020 t1 inner join sales_2021 t2
on t1.market = t2.market
order by t2.sales_2021 - t1.sales_2020 desc;

-- markets with the highest growth(percentage) from 2020 to 2021.

with sales_2020 as 
(select market, sum(sales_amount) as sales_2020 from sales_table
where fiscal_year = 2020
group by market
),
sales_2021 as
(
select market, sum(sales_amount) as sales_2021 from sales_table
where fiscal_year = 2021
group by market
)
select t1.market,t1.sales_2020,t2.sales_2021,
t2.sales_2021 - t1.sales_2020 as sales_inc_or_dec,
round(((t2.sales_2021 - t1.sales_2020)/t1.sales_2020)*100,2) as sales_inc_or_dec_prec
from sales_2020 t1 inner join sales_2021 t2
on t1.market = t2.market
order by round(((t2.sales_2021 - t1.sales_2020)/t1.sales_2020)*100,2) desc limit 10;



--  Which divisions/segments are showing declining average selling prices (ASP) year-over-year?
with avg_segment_price_2020 as
(select segment,avg(gross_price) as avg_selling_price_2020 from sales_table
where fiscal_year = 2020
group by segment),
avg_segment_price_2021 as 
(
select segment,avg(gross_price) as avg_selling_price_2021 from sales_table
where fiscal_year = 2021
group by segment
)
select t1.segment,t1.avg_selling_price_2020,t2.avg_selling_price_2021,t2.avg_selling_price_2021 - t1.avg_selling_price_2020 as inc_or_decrease
 from avg_segment_price_2020 t1 inner join avg_segment_price_2021 t2 on
t1.segment = t2.segment;

select * from sales_table;

-- Which products are showing declining average selling prices(ASP) year over years.
-- prices mostly declined for the premium and plus variant products indicating -- some effect of the covid 19.
create view price_decline_analysis as
(with avg_price_2020 as 
(select product_code,product,standardised_variant, avg(gross_price) as avg_price_2020 from sales_table
where fiscal_year = 2020
group by product_code,product,standardised_variant),
avg_price_2021 as 
(
select product_code,product,standardised_variant, avg(gross_price) as avg_price_2021 from sales_table
where fiscal_year = 2021
group by product_code,product,standardised_variant
)
select t1.*,t2.avg_price_2021,
t2.avg_price_2021 - t1.avg_price_2020 as price_inc_or_dec,
round(((t2.avg_price_2021 - t1.avg_price_2020)/(t1.avg_price_2020)) * 100,2) as price_inc_or_dec_perc
from avg_price_2020 t1 inner join avg_price_2021 t2 
on t1.product_code = t2.product_code and 
t1.product = t2.product);
select * from price_decline_analysis where price_inc_or_dec < 0 order by price_inc_or_dec_perc asc limit 10;

-- Which product variant are showing the declining average selling price (ASP) year over years.
select standardised_variant, count(*) from price_decline_analysis where price_inc_or_dec < 0 group by standardised_variant
order by count(*) desc;

-- Which Product category shows the most decrease in the selling price over year.
with product_category_price_decline_2020 as
(select category, standardised_variant ,avg(gross_price) as avg_gross_price_2020 from sales_table
where fiscal_year = 2020
group by category, standardised_variant),
product_category_price_decline_2021 as 
(select category, standardised_variant ,avg(gross_price) as avg_gross_price_2021 from sales_table
where fiscal_year = 2021
group by category, standardised_variant)
select *,
avg_gross_price_2021 - avg_gross_price_2020 as price_inc_or_dec,
round(((avg_gross_price_2021 - avg_gross_price_2020)/(avg_gross_price_2020)) * 100,2) as price_inc_or_dec_perc
from product_category_price_decline_2020 t1 
inner join product_category_price_decline_2021 t2 on t1.category = t2.category and t1.standardised_variant = t2.standardised_variant
order by round(((avg_gross_price_2021 - avg_gross_price_2020)/(avg_gross_price_2020)) * 100,2) desc;


-- Which Product Division shows the most decrease in the selling price over year.
with product_division_price_decline_2020 as
(select division, standardised_variant ,avg(gross_price) as avg_gross_price_2020 from sales_table
where fiscal_year = 2020
group by division, standardised_variant),
product_division_price_decline_2021 as 
(select division, standardised_variant ,avg(gross_price) as avg_gross_price_2021 from sales_table
where fiscal_year = 2021
group by division, standardised_variant)
select *,
avg_gross_price_2021 - avg_gross_price_2020 as price_inc_or_dec,
round(((avg_gross_price_2021 - avg_gross_price_2020)/(avg_gross_price_2020)) * 100,2) as price_inc_or_dec_perc
from product_division_price_decline_2020 t1 
inner join product_division_price_decline_2021 t2 on t1.division = t2.division and t1.standardised_variant = t2.standardised_variant
order by round(((avg_gross_price_2021 - avg_gross_price_2020)/(avg_gross_price_2020)) * 100,2) desc;

select distinct segment from sales_table where division = 'PC';

-- Sales by Amount increase by division from 2020 to 2021.
-- done

-- Sales by Quantity Increase by division from 2020 to 2021.
with sales_amt_by_division_2020 as 
(select division,sum(sold_quantity) as amt_sold_2020 from sales_table where fiscal_year = 2020
group by division
),
sales_amt_by_division_2021 as 
(select division,sum(sold_quantity) as amt_sold_2021 from sales_table where fiscal_year = 2021
group by division
)
select *,
(amt_sold_2021 - amt_sold_2020) as increase_in_amount_sold,
round(((amt_sold_2021 - amt_sold_2020)/(amt_sold_2020)) * 100,2) as perc_increase
from sales_amt_by_division_2020 t1 inner join sales_amt_by_division_2021 t2
on t1.division = t2.division;

-- Question.
-- Get top 5 and bottom 5 in each division

alter table dim_product add
cleaned_variant varchar(255);
-- added the values already

create view marginal_analysis as
(select t1.product_code,t1.fiscal_year,t2.division,t2.segment,t2.category,t2.product,t2.cleaned_variant,
t3.manufacturing_cost,t4.gross_price
from fact_sales_monthly t1 
inner join dim_product t2 on t1.product_code = t2.product_code
inner join fact_manufacturing_cost t3 on t3.product_code = t1.product_code and t3.cost_year = t1.fiscal_year
inner join fact_gross_price t4 on t4.product_code = t1.product_code and t4.fiscal_year = t1.fiscal_year);

with temp_table as 
(select division, product_code,product, avg(gross_price) - avg(manufacturing_cost) as margin,
rank() over(partition by division order by avg(gross_price) - avg(manufacturing_cost) desc rows between unbounded preceding and unbounded following) as top_5,
rank() over(partition by division order by avg(gross_price) - avg(manufacturing_cost) asc rows between unbounded preceding and unbounded following) as bottom_5
from marginal_analysis
group by division, product_code, product)
select division,product_code,product,
margin,
case
	when top_5 <= 5 then 'High Margin Product'
    when bottom_5 <= 5 then 'Low Margin Product'
end 
as category
from temp_table
where top_5 <=5 or bottom_5 <= 5;

-- Customer Profitability Analysis
-- Question: Which customers generate the highest net profit (gross sales – discounts – manufacturing cost) and which ones are unprofitable?

-- some table modifications.
alter table fact_pre_invoice_deductions add
discount_category varchar(255);

set sql_safe_updates = 0;
-- adding a new column to the view.
UPDATE fact_pre_invoice_deductions f
JOIN (
    SELECT customer_code,fiscal_year,
           NTILE(3) OVER (ORDER BY pre_invoice_discount_pct DESC) AS ranked
    FROM fact_pre_invoice_deductions
) temp_table ON f.customer_code = temp_table.customer_code and f.fiscal_year = temp_table.fiscal_year
SET f.discount_category = CASE
    WHEN temp_table.ranked = 1 THEN 'High'
    WHEN temp_table.ranked = 2 THEN 'Medium'
    WHEN temp_table.ranked = 3 THEN 'Low'
END;

create table customer_analysis_table as
(select 
t1.customer_code, t1.customer,t1.gross_price,t3.manufacturing_cost,
t1.sold_quantity,t1.sales_amount,t4.pre_invoice_discount_pct,t4.discount_category,
(t1.sales_amount * coalesce(t4.pre_invoice_discount_pct,0)) as discount_value,
(t1.sales_amount * (1-coalesce(t4.pre_invoice_discount_pct,0))) as sales_after_discount,
(t3.manufacturing_cost * t1.sold_quantity) as net_manufacturing_cost,
((t1.sales_amount * (1- coalesce(t4.pre_invoice_discount_pct,0))) - (t3.manufacturing_cost * t1.sold_quantity)) as net_profit,
round((((t1.sales_amount * (1- coalesce(t4.pre_invoice_discount_pct,0))) - (t3.manufacturing_cost * t1.sold_quantity))/(t1.sales_amount)) * 100,2) as profit_percentage
from sales_table t1
inner join fact_manufacturing_cost t3 on t1.product_code = t3.product_code and t3.cost_year = t1.fiscal_year
inner join fact_pre_invoice_deductions t4 on t1.customer_code = t4.customer_code and t1.fiscal_year = t4.fiscal_year);

select customer_code,customer,discount_category,
avg(net_profit) as average_net_profit,
avg(profit_percentage) as avg_profit_percentage
from customer_analysis_table
group by customer_code, customer,discount_category
order by discount_category asc , avg(profit_percentage) desc,avg(net_profit) desc;

-- after discounts also we are not making loss,
-- run it rem.
select *,
ntile(3) over(order by t2.cost_to_sales desc rows between unbounded preceding and unbounded following) as cost_to_sales_ratio_category
from sales_table t1 inner join cost_to_sales_table t2 on 
t1.product_code = t2.product_code;




-- Question: For each product (Standard / Plus / Premium), what is the share of sales volume and how has it shifted over the last 2 years?
-- dont use product code as -- the variants of product are marked with diff pcode use product name.

create table product_sold_variant_wise
(with standard_qty_sold as 
(select product,
sum(sold_quantity) as standard_sold_qty,
sum(sales_amount) as standard_sales_amt from sales_table
where standardised_variant = 'STANDARD'
group by product),
plus_qty_sold as 
(select product,
sum(sold_quantity) as plus_sold_qty,
sum(sales_amount) as plus_sales_amt from sales_table
where standardised_variant = 'PLUS'
group by product),
premium_qty_sold as 
(select product,
sum(sold_quantity) as premium_sold_qty,
sum(sales_amount) as premium_sales_amt from sales_table
where standardised_variant = 'PREMIUM'
group by product)
select t1.product,t1.standard_sold_qty,t2.plus_sold_qty,
t3.premium_sold_qty,t1.standard_sales_amt,
t2.plus_sales_amt, t3.premium_sales_amt
from standard_qty_sold t1 inner join plus_qty_sold t2 on t1.product = t2.product 
inner join premium_qty_sold t3 on t2.product = t3.product);


select t1.product,t1.standard_sold_qty,t1.plus_sold_qty,t1.premium_sold_qty,t1.standard_sales_amt,t1.plus_sales_amt,t1.premium_sales_amt,
t2.total_sales_by_product,
(t1.standard_sales_amt/t2.total_sales_by_product) * 100 as standard_sales_perc,
(t1.plus_sales_amt/t2.total_sales_by_product) * 100 as plus_sales_perc,
(t1.premium_sales_amt/t2.total_sales_by_product) * 100 as premium_sales_perc
from product_sold_variant_wise t1 
inner join 
(select product,sum(sales_amount) as total_sales_by_product from sales_table
group by product) t2 on t1.product = t2.product
order by t2.total_sales_by_product desc;

-- Question: What % of sales in each region is tied to a single channel (e.g., Retailers or Distributors)?
with temp_table as 
(select region, channel,
sum(sales_amount) as region_channel_sales
from sales_table
group by region,channel)
select *,
sum(region_channel_sales) over(partition by region) as region_total_sales,
round((region_channel_sales/sum(region_channel_sales) over(partition by region)) * 100,2) as per_c_to_overall_regional_sales
from temp_table
order by region,channel asc ;
-- across all the regions retailer channel brings the most revenue.

-- channel growth from 2020 to 2021

select * from sales_table;

with channel_sales_2020 as 
(select channel,sum(sales_amount) as total_sales_2020 from sales_table 
where fiscal_year = 2020
group by channel),
channel_sales_2021 as 
(select channel,sum(sales_amount) as total_sales_2021 from sales_table 
where fiscal_year = 2021
group by channel)
select t1.channel,t1.total_sales_2020,t2.total_sales_2021,
((t2.total_sales_2021 - t1.total_sales_2020)/(t1.total_sales_2020)) * 100 as sales_inc_by_channel_perc
from channel_sales_2020 t1 inner join
channel_sales_2021 t2 on t1.channel = t2.channel
order by sales_inc_by_channel_perc desc;

-- channel and region.
select region,channel,sum(sales_amount) as sales_amt from sales_table
group by region,channel
order by region asc, channel desc;

-- channel and region 2020,2021
with channel_region_sales_2020 as
(select region,channel,sum(sales_amount) as sales_amt_2020 from sales_table
where fiscal_year = 2020
group by region,channel
),
channel_region_sales_2021 as 
(select region,channel,sum(sales_amount) as sales_amt_2021 from sales_table
where fiscal_year = 2021
group by region,channel
)
select t1.region,t1.channel,t1.sales_amt_2020,
t2.sales_amt_2021, t2.sales_amt_2021 - t1.sales_amt_2020 as sales_inc_or_dec,
((t2.sales_amt_2021 - t1.sales_amt_2020)/(t1.sales_amt_2020)) * 100 as perc_inc_or_dec
from channel_region_sales_2020 t1 inner join channel_region_sales_2021 t2 
on t1.region = t2.region and t1.channel = t2.channel
order by t1.region asc, t1.channel desc;





-- Which product segments (e.g., Notebooks, Storage, Peripherals) generate the highest profit per unit sold?
-- selling any kind of desktop / laptop gets me the highest profit per unit.
-- but they contribute only 2.79 % of the total qty sold.
-- but contribue to the 36.66% of the overall sales.

-- using session variable to avoid error code 2013.
set @total_sales_amount = (select sum(sales_amount) from sales_table);
set @total_sold_quantity = (select sum(sold_quantity) from sales_table);

select t1.segment,t1.category, round(avg(t1.gross_price) - avg(t2.manufacturing_cost),2) as profit_per_unit_sold_without_disc,
(sum(t1.sold_quantity)/(@total_sold_quantity)) * 100 as perc_contribution_to_total_qty_sold,
(sum(t1.sales_amount)/(@total_sales_amount)) * 100 as per_contribution_to_overall_sales
from sales_table t1 inner join fact_manufacturing_cost t2 
on t1.product_code = t2.product_code and t1.fiscal_year = t2.cost_year
group by segment,category
order by avg(t1.gross_price) - avg(t2.manufacturing_cost) desc;


-- Question: What share of revenue is driven by products with above-median manufacturing cost-to-sales ratios?

create table cost_to_sales_table as 
(select t1.product_code,t1.product,t1.variant,
t1.gross_price,t2.manufacturing_cost,t1.sold_quantity,
t1.sales_amount,t2.manufacturing_cost * t1.sold_quantity as net_manfacturing_cost,
((t2.manufacturing_cost * t1.sold_quantity)/t1.sales_amount) as cost_to_sales,
row_number() over(order by (((t2.manufacturing_cost * t1.sold_quantity)/t1.sales_amount)) asc rows between unbounded preceding and current row) as indexer
 from sales_table t1 inner join fact_manufacturing_cost t2 on
t1.product_code = t2.product_code and t1.fiscal_year = t2.cost_year);

select * from cost_to_sales_table;

set @median_cost_to_sales_ratio = 
(WITH total AS (
  SELECT COUNT(*) AS total_rows FROM cost_to_sales_table
)
SELECT 
  ROUND(AVG(cost_to_sales), 6) AS median_cost_to_sales_ratio
FROM 
  cost_to_sales_table, total
WHERE 
  indexer IN (
    FLOOR((total.total_rows + 1) / 2),
    CEIL((total.total_rows + 1) / 2)
  )
);


-- most of the product with the higher cost to sales ratio are mostly --
-- plus or premium products.
-- these higher cost to sales ratio product contribute 48.58 % of total_sales and 52.74 % of total quantity sold.
-- might need to reduce the dependence on the higher cost to sales products.
set @total_sales_amount = (select sum(sales_amount) from sales_table);
set @total_qty_sold = (select sum(sold_quantity) from sales_table);

select product_code,product,variant,
avg(cost_to_sales) as avg_cost_to_sales_ratio,
(sum(sales_amount)/@total_sales_amount) * 100 as per_contribution_to_total_sales,
(sum(sold_quantity)/@total_qty_sold) * 100 as per_contribution_to_qty_sold
from cost_to_sales_table group by product_code,product,variant
having avg(cost_to_sales) > @median_cost_to_sales_ratio
order by avg(cost_to_sales) desc;

with temp_table as
(select product_code,product,variant,
avg(cost_to_sales) as avg_cost_to_sales_ratio,
(sum(sales_amount)/@total_sales_amount) * 100 as per_contribution_to_total_sales,
(sum(sold_quantity)/@total_qty_sold) * 100 as per_contribution_to_qty_sold
from cost_to_sales_table group by product_code,product,variant
having avg(cost_to_sales) > @median_cost_to_sales_ratio
order by avg(cost_to_sales) desc)
select sum(per_contribution_to_total_sales),
sum(per_contribution_to_qty_sold) from 
temp_table;

-- channel and product variant analysis.
select channel,standardised_variant, sum(sold_quantity) as quantity_sold from sales_table
group by channel,standardised_variant
order by channel desc, standardised_variant asc, quantity_sold desc;

-- region,channel,product_variant - sum(sales)

select region,channel,standardised_variant,sum(sold_quantity) as quantity_sold from sales_table 
group by region, channeL, standardised_variant
order by region asc,channel desc, standardised_variant asc,sum(sold_quantity) desc;

-- region,channel ,product variant -- yoy analysis for qty sold

with t1 as 
(select region,channel,standardised_variant,sum(sold_quantity) as quantity_sold_2020 from sales_table 
where fiscal_year = '2020'
group by region, channeL, standardised_variant
order by region asc,channel desc, standardised_variant asc,sum(sold_quantity) desc),
t2 as
(select region,channel,standardised_variant,sum(sold_quantity) as quantity_sold_2021 from sales_table 
where fiscal_year = '2021'
group by region, channeL, standardised_variant
order by region asc,channel desc, standardised_variant asc,sum(sold_quantity) desc)
select t1.region,t1.channel,t1.standardised_variant,t1.quantity_sold_2020, t2.quantity_sold_2021 ,
((t2.quantity_sold_2021 - t1.quantity_sold_2020)/(t1.quantity_sold_2020)) * 100 as perc_inc_dec_in_sold_qty
from t1 inner join t2 on t1.region = t2.region
and t1.channel = t2.channel and t1.standardised_variant = t2.standardised_variant;

-- region,channel ,product variant -- yoy analysis for sales amount.

with t1 as 
(select region,channel,standardised_variant,sum(sales_amount) as sales_amount_2020 from sales_table 
where fiscal_year = '2020'
group by region, channeL, standardised_variant
order by region asc,channel desc, standardised_variant asc,sum(sales_amount) desc),
t2 as
(select region,channel,standardised_variant,sum(sales_amount) as sales_amount_2021 from sales_table 
where fiscal_year = '2021'
group by region, channeL, standardised_variant
order by region asc,channel desc, standardised_variant asc,sum(sales_amount) desc)
select t1.region,t1.channel,t1.standardised_variant,t1.sales_amount_2020, t2.sales_amount_2021,
((t2.sales_amount_2021 - t1.sales_amount_2020)/(t1.sales_amount_2020)) * 100 as perc_inc_dec_in_sales
from t1 inner join t2 on t1.region = t2.region
and t1.channel = t2.channel and t1.standardised_variant = t2.standardised_variant;

-- Qty Sold Analysis For Region.
select region,sum(sold_quantity) as sold_qty from sales_table group by region
order by sold_qty desc;

-- Qty Sold Analysis for region increase/dec from 2020 to 2021.
with region_wise_sold_qty_2020 as
(select region,sum(sold_quantity) as sold_qty_2020 from sales_table
where fiscal_year = '2020'
group by region),
region_wise_sold_qty_2021 as
(select region,sum(sold_quantity) as sold_qty_2021 from sales_table
where fiscal_year = '2021'
group by region)
select t1.region,t1.sold_qty_2020, t2.sold_qty_2021,
sold_qty_2021 - sold_qty_2020 as inc_or_dec_in_sold_qty,
((t2.sold_qty_2021 - t1.sold_qty_2020)/(t1.sold_qty_2020)) * 100 as inc_or_dec_percentage
from region_wise_sold_qty_2020 t1 inner join 
region_wise_sold_qty_2021 t2 on 
t1.region = t2.region;


-- channel and high margin product.
-- using product_code to avoid involving the cost of the plus and premium products.

create table pcode_margin_cat as
(with temp_table as
(select t1.product_code,t1.fiscal_year,
t1.gross_price - t2.manufacturing_cost as margin_for_product
from sales_table t1
inner join fact_manufacturing_cost t2
on t1.product_code = t2.product_code and t1.fiscal_year = t2.cost_year)
select product_code,fiscal_year,avg(margin_for_product) as avg_margin_for_product,
ntile(3) over(order by avg(margin_for_product) desc rows between unbounded preceding and unbounded following) as margin_cat_num
from temp_table
group by product_code,fiscal_year
);

alter table pcode_margin_cat
add margin_category varchar(255) not null;


update pcode_margin_cat
set margin_category = 
(case
	when margin_cat_num = 1 then 'high_margin_product'
    when margin_cat_num = 2 then 'medium_margin_product'
    when margin_cat_num = 3 then 'low_maring_product'
end);

-- channel and what kind of product are sold.
set @total_sales = (select sum(sales_amount) from sales_table);
set @total_qty_sold = (select sum(sold_quantity) from sales_table);
select t1.channel,t2.margin_category,sum(t1.sold_quantity) as sold_qty,
round((sum(t1.sales_amount)/(@total_sales)) * 100,2) as perc_contribution_to_sales,
round((sum(t1.sold_quantity)/(@total_qty_sold)) * 100,2) as perc_contribution_to_qty_sold
from sales_table t1 inner join
pcode_margin_cat t2 on t1.product_code = t2.product_code and t1.fiscal_year = t2.fiscal_year
group by t1.channel,t2.margin_category
order by channel asc,sold_qty desc;

-- region and margin category sold most.
select t1.region, t2.margin_category, sum(sold_quantity) as qty_sold from sales_table
t1 inner join pcode_margin_cat t2 
on t1.product_code = t2.product_code 
and t1.fiscal_year = t2.fiscal_year
group by t1.region,t2.margin_category
order by t1.region, t2.margin_category,qty_sold desc;

-- which product margin category saw the most increase in sales from 2020 to 2021.

-- regionwise increase in sales of by product margin category from 2020 to 2021.

with sold_qty_2020 as
(select t1.region,t2.margin_category, sum(t1.sold_quantity) as sold_qty_2020 from 
sales_table t1 inner join pcode_margin_cat t2 on 
t1.product_code = t2.product_code and 
t1.fiscal_year = t2.fiscal_year
where t1.fiscal_year = 2020
group by t1.region,t2.margin_category),
sold_qty_2021 as
(
select t1.region,t2.margin_category, sum(t1.sold_quantity) as sold_qty_2021 from 
sales_table t1 inner join pcode_margin_cat t2 on 
t1.product_code = t2.product_code and 
t1.fiscal_year = t2.fiscal_year
where t1.fiscal_year = 2021
group by t1.region,t2.margin_category
)
select t1.region,t1.margin_category,
t1.sold_qty_2020,t2.sold_qty_2021,
((t2.sold_qty_2021 - t1.sold_qty_2020)/(t1.sold_qty_2020)) * 100 as perc_increase
from sold_qty_2020 t1 inner join sold_qty_2021 t2 on
t1.region = t2.region and 
t1.margin_category = t2.margin_category
order by t1.region asc,t2.margin_category asc,perc_increase desc;

-- top 10 customer and product category margin analysis -- by sales amount.

with temp_table as (
select distinct customer from top_10_customer_sales_table group by customer
order by sum(sales_amount) desc limit 10
)
select t1.customer,t2.margin_category,sum(sales_amount) as sum_sales from sales_table t1 
inner join pcode_margin_cat t2 on
t1.product_code = t2.product_code 
and t1.fiscal_year = t2.fiscal_year
where t1.customer in (select temp_table.customer from temp_table)
group by t1.customer,t2.margin_category;

-- top 10 customer and product category margin analysis -- by sold qty.

with temp_table as (
select distinct customer from top_10_customer_sales_table group by customer
order by sum(sold_quantity) desc limit 10
)
select t1.customer,t2.margin_category,sum(sold_quantity) as sold_quantity from sales_table t1 
inner join pcode_margin_cat t2 on
t1.product_code = t2.product_code 
and t1.fiscal_year = t2.fiscal_year
where t1.customer in (select temp_table.customer from temp_table)
group by t1.customer,t2.margin_category;


-- customer and product category margin analysis -- by sales amount yoy.
with sales_amt_2020 as
(with temp_table as (
select distinct customer from top_10_customer_sales_table group by customer
order by sum(sales_amount) desc limit 10
)
select t1.customer,t2.margin_category,sum(sales_amount) as sum_sales_2020 from sales_table t1 
inner join pcode_margin_cat t2 on
t1.product_code = t2.product_code 
and t1.fiscal_year = t2.fiscal_year
where t1.customer in (select temp_table.customer from temp_table) and t1.fiscal_year = 2020
group by t1.customer,t2.margin_category
),
sales_amt_2021 as
(with temp_table as (
select distinct customer from top_10_customer_sales_table group by customer
order by sum(sales_amount) desc limit 10
)
select t1.customer,t2.margin_category,sum(sales_amount) as sum_sales_2021 from sales_table t1 
inner join pcode_margin_cat t2 on
t1.product_code = t2.product_code 
and t1.fiscal_year = t2.fiscal_year
where t1.customer in (select temp_table.customer from temp_table) and t1.fiscal_year = 2021
group by t1.customer,t2.margin_category
)
select t1.customer,t1.margin_category,t1.sum_sales_2020,t2.sum_sales_2021 from sales_amt_2020 t1 
inner join sales_amt_2021 t2 
on t1.customer = t2.customer and 
t1.margin_category = t2.margin_category;


-- customer and product category margin analysis -- first by sold qty yoy.
with sold_quantity_2020 as
(with temp_table as (
select distinct customer from top_10_customer_sales_table group by customer
order by sum(sales_amount) desc limit 10
)
select t1.customer,t2.margin_category,sum(sold_quantity) as sold_quantity_2020 from sales_table t1 
inner join pcode_margin_cat t2 on
t1.product_code = t2.product_code 
and t1.fiscal_year = t2.fiscal_year
where t1.customer in (select temp_table.customer from temp_table) and t1.fiscal_year = 2020
group by t1.customer,t2.margin_category
),
sold_quantity_2021 as
(with temp_table as (
select distinct customer from top_10_customer_sales_table group by customer
order by sum(sales_amount) desc limit 10
)
select t1.customer,t2.margin_category,sum(sold_quantity) as sold_quantity_2021 from sales_table t1 
inner join pcode_margin_cat t2 on
t1.product_code = t2.product_code 
and t1.fiscal_year = t2.fiscal_year
where t1.customer in (select temp_table.customer from temp_table) and t1.fiscal_year = 2021
group by t1.customer,t2.margin_category
)
select t1.customer,t1.margin_category,t1.sold_quantity_2020,t2.sold_quantity_2021 from sold_quantity_2020 t1 
inner join sold_quantity_2021 t2 
on t1.customer = t2.customer and 
t1.margin_category = t2.margin_category;




-- Discount related analysis.-------------------------------------------------------------------------------------------------------------------------------------

-- discount and the product margin category.
select t2.margin_category, avg(t3.pre_invoice_discount_pct) as avg_discount_perc from sales_table t1 inner join pcode_margin_cat t2 
on t1.product_code = t2.product_code and t1.fiscal_year = t2.fiscal_year inner join
fact_pre_invoice_deductions t3 on t1.customer_code = t3.customer_code and t1.fiscal_year = t3.fiscal_year
group by t2.margin_category order by avg_discount_perc desc;

-- discount and division.
select t1.division,avg(t2.pre_invoice_discount_pct) as avg_discount_perc from sales_table t1 
inner join fact_pre_invoice_deductions t2 on 
t1.customer_code = t2.customer_code and t1.fiscal_year = t2.fiscal_year
group by t1.division order by avg_discount_perc desc;

-- discount and product division and market.
select t1.market,t1.division,avg(t2.pre_invoice_discount_pct) as avg_discount_perc from sales_table t1 inner join fact_pre_invoice_deductions t2 on 
t1.customer_code = t2.customer_code and t1.fiscal_year = t2.fiscal_year
group by t1.division, t1.market order by t1.market asc;
-- insight -- nothing much the discount pct remain nearly same for across product divsion for market.

-- which product category gets the most discount in each market.
-- simply discount,category and market.
select t1.market,t1.category,avg(t2.pre_invoice_discount_pct) as avg_discount_perc from sales_table t1 
inner join fact_pre_invoice_deductions t2 on 
t1.customer_code = t2.customer_code and t1.fiscal_year = t2.fiscal_year
group by t1.category, t1.market order by t1.market asc;

-- discount and product segment
select t1.segment,avg(t2.pre_invoice_discount_pct) as avg_discount_perc 
from sales_table t1 inner join fact_pre_invoice_deductions t2 on 
t1.customer_code = t2.customer_code and t1.fiscal_year = t2.fiscal_year
group by t1.segment order by avg_discount_perc desc;

-- discount and product category
select t1.category,avg(t2.pre_invoice_discount_pct) as avg_discount_perc 
from sales_table t1 inner join fact_pre_invoice_deductions t2 on 
t1.customer_code = t2.customer_code and t1.fiscal_year = t2.fiscal_year
group by t1.category order by avg_discount_perc desc;

-- discount and standardised_variant.
select t1.standardised_variant,avg(t2.pre_invoice_discount_pct) as avg_discount_perc 
from sales_table t1 inner join fact_pre_invoice_deductions t2 on 
t1.customer_code = t2.customer_code and t1.fiscal_year = t2.fiscal_year
group by t1.standardised_variant order by avg_discount_perc desc;

-- does discount percentage varies for different variant of products across markets.
-- simply discount,market,standardised_variant.
-- No doesnt vary
select t1.market,t1.standardised_variant,avg(t2.pre_invoice_discount_pct) as avg_discount_perc 
from sales_table t1 inner join fact_pre_invoice_deductions t2 on 
t1.customer_code = t2.customer_code and t1.fiscal_year = t2.fiscal_year
group by t1.standardised_variant, t1.market order by t1.market;

-- discount and product segment, and product category.
select t1.segment,t1.category,avg(t2.pre_invoice_discount_pct) as avg_discount_perc 
from sales_table t1 inner join fact_pre_invoice_deductions t2 on 
t1.customer_code = t2.customer_code and t1.fiscal_year = t2.fiscal_year
group by t1.segment,t1.category order by t1.segment;

-- discount,customer,product margin category.

select t1.customer,t2.margin_category, avg(pre_invoice_discount_pct) as avg_percentage
from sales_table t1 inner join pcode_margin_cat t2 
on t1.product_code = t2.product_code and t1.fiscal_year = t2.fiscal_year 
inner join fact_pre_invoice_deductions t3 on
t1.customer_code = t3.customer_code and t1.fiscal_year = t3.fiscal_year
where t1.customer in (select distinct customer from top_10_customer_sales_table)
group by t1.customer,t2.margin_category
order by t1.customer;

select * from fact_pre_invoice_deductions;


-- discount , region, product margin category.

select t1.region,t2.margin_category, avg(pre_invoice_discount_pct) as avg_percentage
from sales_table t1 inner join pcode_margin_cat t2 
on t1.product_code = t2.product_code and t1.fiscal_year = t2.fiscal_year 
inner join fact_pre_invoice_deductions t3 on
t1.customer_code = t3.customer_code and t1.fiscal_year = t3.fiscal_year
group by t1.region,t2.margin_category
order by t1.region;

-- discount , market , product margin category,
with temp_table as 
(
select distinct market from sales_table group by market order by sum(sales_amount) desc limit 10
)
select t1.market,t2.margin_category, avg(pre_invoice_discount_pct) as avg_percentage
from sales_table t1 inner join pcode_margin_cat t2 
on t1.product_code = t2.product_code and t1.fiscal_year = t2.fiscal_year 
inner join fact_pre_invoice_deductions t3 on
t1.customer_code = t3.customer_code and t1.fiscal_year = t3.fiscal_year
where market in (select market from temp_table)
group by t1.market,t2.margin_category
order by t1.market;

-- customer,segment, discount analysis.
with temp_table as 
(
select distinct customer from sales_table group by customer order by sum(sales_amount) desc limit 10
)
select t1.customer,t1.segment,avg(pre_invoice_discount_pct) as discount_percentage from sales_table t1 
inner join fact_pre_invoice_deductions t2
on t1.customer_code = t2.customer_code and t1.fiscal_year = t2.fiscal_year
where t1.customer in (select customer from temp_table)
group by t1.customer,t1.segment;

-- customer,division,discount analysis.

with temp_table as 
(
select distinct customer from sales_table group by customer order by sum(sales_amount) desc limit 10
)
select t1.customer,t1.division,avg(pre_invoice_discount_pct) as discount_percentage from sales_table t1 
inner join fact_pre_invoice_deductions t2
on t1.customer_code = t2.customer_code and t1.fiscal_year = t2.fiscal_year
where t1.customer in (select customer from temp_table)
group by t1.customer,t1.division;

-- customer,category ,discount analysis

with temp_table as 
(
select distinct customer from sales_table group by customer order by sum(sales_amount) desc limit 10
)
select t1.customer,t1.category,avg(pre_invoice_discount_pct) as discount_percentage from sales_table t1 
inner join fact_pre_invoice_deductions t2
on t1.customer_code = t2.customer_code and t1.fiscal_year = t2.fiscal_year
where t1.customer in (select customer from temp_table)
group by t1.customer,t1.category;



-- channel,discount,analysis
select t1.channel,avg(t2.pre_invoice_discount_pct) as avg_discount_percentage 
from sales_table t1 inner join fact_pre_invoice_deductions t2 
on t1.customer_code = t2.customer_code and 
t1.fiscal_year = t2.fiscal_year
group by t1.channel
order by avg_discount_percentage desc;


-- channel and discount percentage increase/decrease in 2020 and 2021.
with discount_2020 as
(select t1.channel,avg(t2.pre_invoice_discount_pct) as avg_discount_percentage_2020
from sales_table t1 inner join fact_pre_invoice_deductions t2 
on t1.customer_code = t2.customer_code and 
t1.fiscal_year = t2.fiscal_year
where t1.fiscal_year = 2020
group by t1.channel),
discount_2021 as
(
select t1.channel,avg(t2.pre_invoice_discount_pct) as avg_discount_percentage_2021
from sales_table t1 inner join fact_pre_invoice_deductions t2 
on t1.customer_code = t2.customer_code and 
t1.fiscal_year = t2.fiscal_year
where t1.fiscal_year = 2021
group by t1.channel
)
select t1.channel,t1.avg_discount_percentage_2020, t2.avg_discount_percentage_2021,
 round(((t2.avg_discount_percentage_2021 - t1.avg_discount_percentage_2020)/(t1.avg_discount_percentage_2020)) * 100,2) as discount_pct_inc_dec_perc
from discount_2020 t1 inner join discount_2021 t2 on t1.channel = t2.channel
order by discount_pct_inc_dec_perc desc;



-- channel variant analysis sales amt analysis.
select channel,standardised_variant,sum(sales_amount) as sales_amoint 
from sales_table group by channel,standardised_variant
order by channel;

-- channel variant analysis sold qty analysis.
select channel,standardised_variant,sum(sold_quantity) as sold_quantity
from sales_table group by channel,standardised_variant
order by channel;

-- channel, product_ margin category
select t1.channel,t2.margin_category,sum(sold_quantity) as sold_qty from sales_table t1 inner join 
pcode_margin_cat t2 on t1.product_code = t2.product_code
and t1.fiscal_year = t2.fiscal_year
group by t1.channel,t2.margin_category
order by t1.channel;



-- channel, product_ margin category, yoy sold_qty.
with channel_sold_qty_2020 as
(select t1.channel,t2.margin_category,sum(sold_quantity) as sold_qty_2020
from sales_table t1 inner join pcode_margin_cat t2 
on t1.product_code = t2.product_code and t1.fiscal_year = t2.fiscal_year
where t1.fiscal_year = 2020
group by t1.channel,t2.margin_category
order by t1.channel),
channel_sold_qty_2021 as 
(select t1.channel,t2.margin_category,sum(sold_quantity) as sold_qty_2021
from sales_table t1 inner join pcode_margin_cat t2 
on t1.product_code = t2.product_code and t1.fiscal_year = t2.fiscal_year
where t1.fiscal_year = 2021
group by t1.channel,t2.margin_category
order by t1.channel)
select t1.channel,t1.margin_category, t1.sold_qty_2020 , t2.sold_qty_2021, 
t2.sold_qty_2021 - t1.sold_qty_2020 as qty_inc_dec,
round(((t2.sold_qty_2021 - t1.sold_qty_2020)/(t1.sold_qty_2020)) * 100,2) as perc_inc_or_dec
from channel_sold_qty_2020 t1 inner join channel_sold_qty_2021 t2 
on t1.channel = t2.channel and t1.margin_category = t2.margin_category;

-- channel, product_ margin category sales analysis yoy.
with channel_sales_amt_2020 as
(select t1.channel,t2.margin_category,sum(sales_amount) as sales_amount_2020
from sales_table t1 inner join pcode_margin_cat t2 
on t1.product_code = t2.product_code and t1.fiscal_year = t2.fiscal_year
where t1.fiscal_year = 2020
group by t1.channel,t2.margin_category
order by t1.channel),
channel_sales_amt_2021 as 
(select t1.channel,t2.margin_category,sum(sales_amount) as sales_amount_2021
from sales_table t1 inner join pcode_margin_cat t2
on t1.product_code = t2.product_code and t1.fiscal_year = t2.fiscal_year
where t1.fiscal_year = 2021
group by t1.channel,t2.margin_category
order by t1.channel)
select t1.channel,t1.margin_category, t1.sales_amount_2020 , t2.sales_amount_2021, 
t2.sales_amount_2021 - t1.sales_amount_2020 as sales_inc_or_dec,
round(((t2.sales_amount_2021 - t1.sales_amount_2020)/(t1.sales_amount_2020)) * 100,2) as perc_inc_or_dec_sales
from channel_sales_amt_2020 t1 inner join channel_sales_amt_2021 t2 
on t1.channel = t2.channel and t1.margin_category = t2.margin_category;

-- channel, product_ margin category sales analysis.
select t1.channel,t2.margin_category,sum(sales_amount) as sales_amount from sales_table t1 inner join 
pcode_margin_cat t2 on t1.product_code = t2.product_code
and t1.fiscal_year = t2.fiscal_year
group by t1.channel,t2.margin_category
order by t1.channel;


-- channel variant analysis sales 

select channel,standardised_variant,sum(sales_amount) as sales_amt from sales_table
group by channel,standardised_variant
order by channel;

-- channel,variant analysis, sales YoY.
with sales_2020 as 
(select channel,standardised_variant,sum(sales_amount) as sales_amt_2020 from sales_table
where fiscal_year = 2020
group by channel,standardised_variant
order by channel
),
sales_2021 as
(
select channel,standardised_variant,sum(sales_amount) as sales_amt_2021 from sales_table
where fiscal_year = 2021
group by channel,standardised_variant
order by channel
)
select t1.channel,t1.standardised_variant,t1.sales_amt_2020,t2.sales_amt_2021,
t2.sales_amt_2021 - t1.sales_amt_2020 as inc_or_dec_in_sales_amt,
((t2.sales_amt_2021 - t1.sales_amt_2020)/(t1.sales_amt_2020)) * 100 as perc_inc_or_dec_in_sales
from sales_2020 t1 inner join sales_2021 t2 on
t1.channel = t2.channel and t1.standardised_variant = t2.standardised_variant;

-- market, segment, discount analysis.
-- cant use limit keyword inside subqueries so using with.
with temp_table as 
(
select distinct market from sales_table group by market order by sum(sales_amount) desc limit 10
)
select t1.market, t1.segment, avg(t2.pre_invoice_discount_pct) as avg_discount_perc 
from sales_table t1 inner join fact_pre_invoice_deductions t2
on t1.customer_code = t2.customer_code and t1.fiscal_year = t2.fiscal_year
where t1.market in (select market from sales_table)
group by t1.market,t1.segment
order by t1.market;

-- market, standardised variant, discount analysis.
with temp_table as 
(
select distinct market from sales_table group by market order by sum(sales_amount) desc limit 10
)
select t1.market, t1.standardised_variant, avg(t2.pre_invoice_discount_pct) as avg_discount_perc 
from sales_table t1 inner join fact_pre_invoice_deductions t2
on t1.customer_code = t2.customer_code and t1.fiscal_year = t2.fiscal_year
where t1.market in (select market from sales_table)
group by t1.market,t1.standardised_variant
order by t1.market;



-- region and markets revenue contribution.

select region,market,sum(sales_amount) as sum_sales from sales_table
group by region, market;

-- region and markets revenue contribution yoy.
with region_market_sales_2020 as
(select region,market,sum(sales_amount) as sum_sales_2020 from sales_table
where fiscal_year = '2020'
group by region, market),
region_market_sales_2021 as 
(
select region,market, sum(sales_amount) as sum_sales_2021 from sales_table 
where fiscal_year = '2021'
group by region,market
)
select * from region_market_sales_2020 t1 inner join 
region_market_sales_2021 t2 on t1.region = t2.region and 
t1.market = t2.market;


-- For each product (Standard / Plus / Premium), what is the share of sales
-- volume and how has it shifted over the last 2 years?
with standardised_variant_qty_sold_2020 as 
(select standardised_variant,sum(sold_quantity) as sold_quantity_2020 
from sales_table where fiscal_year = 2020
group by standardised_variant),
standardised_variant_qty_sold_2021 as 
(select standardised_variant,sum(sold_quantity) as sold_quantity_2021
from sales_table where fiscal_year = 2021
group by standardised_variant)
select t1.standardised_variant,t1.sold_quantity_2020,t2.sold_quantity_2021
from standardised_variant_qty_sold_2020 t1 
inner join standardised_variant_qty_sold_2021 t2 on
t1.standardised_variant = t2.standardised_variant;

-- Seasonal Analysis

-- monthly sales
select 
    fiscal_year,
    month(date) as month_num,
    date_format(date, '%b') as month_name,
    sum(sales_amount) as total_sales
from sales_table
group by fiscal_year, month_num, month_name
order by fiscal_year, month_num;

-- quarterly sales
select  fiscal_year, quarter(date) as quarter_num, sum(sales_amount) as total_sales
from sales_table
group by fiscal_year, quarter_num
order by fiscal_year, quarter_num;

-- seasonal sales by region monthly.
select region,
concat(fiscal_year,"-",monthname(`date`)) as `year_month`,
sum(sales_amount) as total_sales
from sales_table
group by region, `year_month`
order by region, `year_month`;

-- Seasonal Sales by Product Segment.
select 
    segment,
    concat(fiscal_year,"-",monthname(date)) AS `year_month`,
    SUM(sales_amount) AS total_sales
from sales_table
group by segment, `year_month`
order by segment, `year_month`;

-- season growth yoy by quarter by sales amount.
with quarterly_sales_2020 as
(select quarter(date) as quarter_2020 ,sum(sales_amount) as quarterly_sales_2020 from sales_table
where fiscal_year = 2020
group by quarter(date)
),
quarterly_sales_2021 as 
(select quarter(date) as quarter_2021 ,sum(sales_amount) as quarterly_sales_2021 from sales_table
where fiscal_year = 2021
group by quarter(date)
)
select t1.quarter_2020,t1.quarterly_sales_2020,t2.quarterly_sales_2021,
t2.quarterly_sales_2021 - t1.quarterly_sales_2020 as inc_or_dec,
((t2.quarterly_sales_2021 - t1.quarterly_sales_2020)/(t1.quarterly_sales_2020)) * 100 as inc_or_dec_percentage
from quarterly_sales_2020 t1 inner join quarterly_sales_2021 t2 
on t1.quarter_2020 = t2.quarter_2021
order by t1.quarter_2020;

-- quarter wise analysis the sales this year quarter than last year has increased.

-- season growth yoy by quarter by sold quantity
with quarterly_sold_qty_2020 as
(select quarter(date) as quarter_2020 ,sum(sold_quantity) as quarterly_sold_qty_2020 from sales_table
where fiscal_year = 2020
group by quarter(date)
),
quarterly_sold_qty_2021 as 
(select quarter(date) as quarter_2021 ,sum(sold_quantity) as quarterly_sold_qty_2021 from sales_table
where fiscal_year = 2021
group by quarter(date)
)
select t1.quarter_2020,t1.quarterly_sold_qty_2020,t2.quarterly_sold_qty_2021,
t2.quarterly_sold_qty_2021 - t1.quarterly_sold_qty_2020 as inc_or_dec,
((t2.quarterly_sold_qty_2021 - t1.quarterly_sold_qty_2020)/(t1.quarterly_sold_qty_2020)) * 100 as inc_or_dec_percentage
from quarterly_sold_qty_2020 t1 inner join quarterly_sold_qty_2021 t2 
on t1.quarter_2020 = t2.quarter_2021
order by t1.quarter_2020;
-- for quarterly the sold quantity has increased quarter over quarter.

-- quarter wise growth sales amount.

alter table fact_sales_monthly add 
quarter_per_fiscal_year varchar(255);


set sql_safe_updates = 0;

update fact_sales_monthly set quarter_per_fiscal_year = 
case 
	when month(date) in (9,10,11) then 'Q1'
    when month(date) in (12,1,2) then 'Q2'
    when month(date) in (3,4,5) then 'Q3'
    when month(date) in (6,7,8) then 'Q4'
end;

-- quarter wise growth in qty sold.

select fiscal_year,quarter_per_fiscal_year,
sum(sales_amount) as sales_amount,
lead(sum(sales_amount),1) over(rows between unbounded preceding and unbounded following) as next_quarter_sales
from fact_sales_monthly
group by fiscal_year,quarter_per_fiscal_year;

with temp_table_2 as
(with temp_table as 
(select t1.date,t1.product_code,t1.customer_code,t1.sold_quantity,t1.fiscal_year,t1.quarter_per_fiscal_year,
t1.sold_quantity * t2.gross_price as sales_amount
from fact_sales_monthly t1 inner join fact_gross_price t2 
on t1.product_code = t2.product_code and t1.fiscal_year = t2.fiscal_year)
select fiscal_year,quarter_per_fiscal_year,
sum(sales_amount) as sales_amount,
lead(sum(sales_amount),1) over(rows between unbounded preceding and unbounded following) as next_quarter_sales
from temp_table group by fiscal_year,quarter_per_fiscal_year
order by fiscal_year asc,quarter_per_fiscal_year asc)
select *,
next_quarter_sales - sales_amount as inc_dec_in_sales,
((next_quarter_sales - sales_amount)/(sales_amount)) * 100 as inc_dec_in_sales_perc
from temp_table_2;

select * from fact_sales_monthly;


-- Additional Questions.
-- regional profitability: -- need to work on this 

create table regional_profitability as
(
with region_profit as (
    select 
        c.region,
        s.fiscal_year,
        SUM(s.sold_quantity * gp.gross_price) as gross_sales,
        SUM(s.sold_quantity * gp.gross_price * (1 - d.pre_invoice_discount_pct)) as net_sales,
        SUM(s.sold_quantity * mc.manufacturing_cost) as total_cost,
        SUM(s.sold_quantity * gp.gross_price * (1 - d.pre_invoice_discount_pct)) 
          - SUM(s.sold_quantity * mc.manufacturing_cost) as net_profit
    from fact_sales_monthly s
    join dim_customer c on s.customer_code = c.customer_code
    join fact_gross_price gp on s.product_code = gp.product_code and s.fiscal_year = gp.fiscal_year
    join fact_manufacturing_cost mc on s.product_code = mc.product_code and s.fiscal_year = mc.cost_year
    left join fact_pre_invoice_deductions d on s.customer_code = d.customer_code and s.fiscal_year = d.fiscal_year
    group by c.region, s.fiscal_year
)
select * from region_profit
);

-- gpm and npm
-- gpm and npm more or less same for all regions across year means for APAC region the margins are better.
select *, 
((gross_sales - total_cost)/(net_sales)) * 100 as gross_profit_margin,
((net_profit)/(net_sales) * 100) as net_profit_margin
from regional_profitability;

-- abosoulte growth in net_sales from the 2020 to 2021 regionwise.
with net_sales_t_2020 as
(select region, sum(net_sales) as net_sales_2020 from regional_profitability
where fiscal_year = 2020
group by region ),
net_sales_t_2021 as 
(
select region, sum(net_sales) as net_sales_2021 from regional_profitability
where fiscal_year = 2021
group by region)
select *,
net_sales_2021 - net_sales_2020 as sales_growth,
((net_sales_2021 - net_sales_2020)/(net_sales_2020)) * 100 as sales_growth_pct
from net_sales_t_2020 t1 inner join net_sales_t_2021 t2
on t1.region = t2.region;

-- abosoulte growth in net_profit from the 2020 to 2021 regionwise.
with net_sales_t_2020 as
(select region, sum(net_sales) as net_sales_2020, sum(net_profit) as net_profit_2020 from regional_profitability
where fiscal_year = 2020
group by region ),
net_sales_t_2021 as 
(
select region, sum(net_sales) as net_sales_2021, sum(net_profit) as net_profit_2021 from regional_profitability
where fiscal_year = 2021
group by region)
select t1.region,t1.net_sales_2020,t2.net_sales_2021,t1.net_profit_2020,t2.net_profit_2021,
net_sales_2021 - net_sales_2020 as sales_growth,
((net_sales_2021 - net_sales_2020)/(net_sales_2020)) * 100 as sales_growth_pct,
net_profit_2021 - net_profit_2020 as net_profit_growth,
((net_profit_2021 - net_profit_2020)/(net_profit_2020)) * 100 as net_profit_growth_pct
from net_sales_t_2020 t1 inner join net_sales_t_2021 t2
on t1.region = t2.region;



-- Channel Profitability
create table channel_profitability as 
(with channel_profit as (
    select 
        c.channel,
        s.fiscal_year,
        SUM(s.sold_quantity * gp.gross_price) as gross_sales,
        SUM(s.sold_quantity * gp.gross_price * (1 - d.pre_invoice_discount_pct)) as net_sales,
        SUM(s.sold_quantity * mc.manufacturing_cost) as total_cost,
        SUM(s.sold_quantity * gp.gross_price * (1 - d.pre_invoice_discount_pct)) 
          - SUM(s.sold_quantity * mc.manufacturing_cost) as net_profit
    from fact_sales_monthly s
    join dim_customer c on s.customer_code = c.customer_code
    join fact_gross_price gp on s.product_code = gp.product_code and s.fiscal_year = gp.fiscal_year
    join fact_manufacturing_cost mc on s.product_code = mc.product_code and s.fiscal_year = mc.cost_year
    left join fact_pre_invoice_deductions d on s.customer_code = d.customer_code and s.fiscal_year = d.fiscal_year
    group by c.channel, s.fiscal_year
)
SELECT * FROM channel_profit
);

-- channel profitability analysis by sales for 2020 and 2021
with g_s_2020 as 
(select channel,sum(gross_sales) as gross_sales_2020 from channel_profitability where fiscal_year = 2020
group by channel),
g_s_2021 as 
(select channel,sum(gross_sales) as gross_sales_2021 from channel_profitability where fiscal_year = 2021
group by channel)
select t1.channel, t1.gross_sales_2020, t2.gross_sales_2021,
t2.gross_sales_2021 - t1.gross_sales_2020 as increase_or_decrease,
((t2.gross_sales_2021 - t1.gross_sales_2020)/(t1.gross_sales_2020)) * 100 as gross_sales_pct
from g_s_2020 t1 inner join g_s_2021 t2 on
t1.channel = t2.channel;


-- channel profitability analysis by sales for 2020 and 2021 by np.
with g_s_2020 as 
(select channel,sum(gross_sales) as gross_sales_2020, sum(net_profit) as net_profit_2020 from channel_profitability where fiscal_year = 2020
group by channel),
g_s_2021 as 
(select channel,sum(gross_sales) as gross_sales_2021, sum(net_profit) as net_profit_2021 from channel_profitability where fiscal_year = 2021
group by channel)
select t1.channel, t1.gross_sales_2020, t2.gross_sales_2021,
t1.net_profit_2020, t2.net_profit_2021,
t2.gross_sales_2021 - t1.gross_sales_2020 as inc_dec_g_sales,
((t2.gross_sales_2021 - t1.gross_sales_2020)/(t1.gross_sales_2020)) * 100 as gross_sales_pct_inc_or_dec,
t2.net_profit_2021 - t1.net_profit_2020 as inc_dec_net_profit,
((t2.net_profit_2021 - t1.net_profit_2020)/(t1.net_profit_2020)) * 100 as np_inc_dec_perc
from g_s_2020 t1 inner join g_s_2021 t2 on
t1.channel = t2.channel;
select * from channel_profitability;

-- channel Region Mix
SELECT c.region,c.channel,s.fiscal_year,SUM(s.sold_quantity * gp.gross_price) AS gross_sales
FROM fact_sales_monthly s
JOIN dim_customer c ON s.customer_code = c.customer_code
JOIN fact_gross_price gp ON s.product_code = gp.product_code AND s.fiscal_year = gp.fiscal_year
GROUP BY c.region, c.channel, s.fiscal_year
ORDER BY c.region, c.channel, s.fiscal_year;

-- RANDOM
-- key markets in north america.
select market,sum(sales_amount) as sales_amt from sales_table
where region = 'NA'
group by market
order by sales_amt desc;

-- key market in EU 
select market,sum(sales_amount) as sales_amt from sales_table
where region = 'EU'
group by market
order by sales_amt desc;

-- key markets in LATAM
select market,sum(sales_amount) as sales_amt from sales_table
where region = 'LATAM'
group by market
order by sales_amt desc;

-- channel dominance

select region,channel,sum(sales_amount) as sales_amount from sales_table
group by region, channel;
