--Monday coffee--Data Analysis
select * from city;
SELECT * from products;
SELECT * FROM customers;
select * from sales;

-- Reports & Data Analysis
--Q.1
-- How many people in each city are estimated to consume coffee, given that 25% of population does?

select
	city_name,
	ROUND((population * 0.25)/1000000, 2) as coffee_consumers_in_millions,
	city_rank
from city
order by 2 desc

--Q.2
--Total Revenue from Coffee Sales
--What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

select 
	ci.city_name,
	sum(s.total) as total_revenue
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id
where
	extract(year from s.sale_date) = 2023
	and
	extract(quarter from s.sale_date) = 4
group by 1
order by 2 desc

--Q.3
--Sales Count for Each Product
--How many units of each coffee product have been sold?

select 
	p.product_name,
	count(s.sale_id) as total_orders
from products as p 
left join sales as s
on s.product_id = p.product_id
group by 1
order by 2 desc

--Q.4
--Average Sales Amount per City
--What is the average sales amount per customer in each city?

--city and total sales
--no. of cust in each city

select 
	ci.city_name,
	sum(s.total) as total_revenue,
	count(distinct s.customer_id) as total_cx,
	round(
		sum(s.total)::numeric/
			count(distinct s.customer_id)::numeric
		,2) as avg_sale_pr_cx
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id
group by 1
order by 2 desc

--Q.5
--City Population and Coffee Consumers
--Provide a list of cities along with their populations and estimated coffee consumers.
--return city_name, total_current_cx, estimated_coffeconsumers (25%)

with city_table as 
(
	select
		city_name,
		round((population * 0.25)/1000000, 2) as coffee_consumers
	from city
),
customers_table
as
(
	select
		ci.city_name,
		count(distinct c.customer_id) as unique_cx
	from sales as s
	join customers as c
	on c.customer_id = s.customer_id
	join city as ci
	on ci.city_id = c.city_id
	group by 1
)
select
	customers_table.city_name,
	city_table.coffee_consumers as coffee_consumers_in_millions,
	customers_table.unique_cx
from city_table 
join customers_table
on city_table.city_name = customers_table.city_name

--Q.6
--Top Selling Products by City
--What are the top 3 selling products in each city based on sales volume?

select * from --table
(
	select 
		ci.city_name,
		p.product_name,
		count(s.sale_id) as total_orders,
		dense_rank() over(partition by ci.city_name order by count(s.sale_id) desc) as rank
	from sales as s 
	join products as p
	on s.product_id = p.product_id
	join customers as c 
	on c.customer_id = s.customer_id
	join city as ci
	on ci.city_id = c.city_id
	group by 1, 2
	--order by 1,3 desc
) as t1
where rank <=3

--Q.7
--Customer Segmentation by City
--How many unique customers are there in each city who have purchased coffee products?

select 
	ci.city_name,
	count(distinct c.customer_id) as unique_cx
from city as ci
left join customers as c
on c.city_id = ci.city_id
join sales as s
on s.customer_id = c.customer_id
where s.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
group by 1

--Q.8
--Average Sale vs Rent
--Find each city and their average sale per customer and avg rent per customer

with city_table
as
(
select 
	ci.city_name,
	count(distinct s.customer_id) as total_cx,
	round(
		sum(s.total)::numeric/
			count(distinct s.customer_id)::numeric
		,2) as avg_sale_pr_cx
	
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id
group by 1
order by 2 desc
),
city_rent
as
(select city_name, estimated_rent from city
)
select 
	cr.city_name, 
	cr.estimated_rent, 
	ct.total_cx,
	ct.avg_sale_pr_cx,
	round(cr.estimated_rent::numeric/ct.total_cx::numeric,2) as avg_rent_per_cx
from city_rent as cr
join city_table as ct
on cr.city_name = ct.city_name
order by 4 desc

--Q.9
--Monthly Sales Growth
--Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
--by each city

with
monthly_sales
as
	(
select 
	ci.city_name,
	extract(month from sale_date) as month,
	extract(year from sale_date) as year,
	sum(s.total) as total_sales
from sales as s
join customers as c
on c.customer_id=s.customer_id
join city as ci
on ci.city_id=c.city_id
group by 1,2,3
order by 1,3,2
),
growth_ratio
as
(
select 
	city_name,
	month,
	year,
	total_sales as cr_month_sale,
	lag(total_sales,1) over(partition by city_name order by year,month) as last_month_sale
from monthly_sales
)

select 
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	round((cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric *100
	,2
	)as growth_ratio
from growth_ratio
where
	last_month_sale is not null

--Q.10
--Market Potential Analysis
--Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

with city_table
as
(
select 
	ci.city_name,
	sum(s.total) as total_revenue,
	count(distinct s.customer_id) as total_cx,
	round(
		sum(s.total)::numeric/
			count(distinct s.customer_id)::numeric
		,2) as avg_sale_pr_cx
	
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id
group by 1
order by 2 desc
),
city_rent
as
(
select 
	city_name, 
	estimated_rent, 
	round((population*0.25)/1000000,3) as estimated_coffee_consumer_in_millions
from city
)
select 
	cr.city_name, 
	total_revenue,
	cr.estimated_rent as total_rent, 
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	round(cr.estimated_rent::numeric/ct.total_cx::numeric,2) as avg_rent_per_cx
from city_rent as cr
join city_table as ct
on cr.city_name = ct.city_name
order by 2 desc

/*
--Recommendations
city1: pune
avg rent per cx is very less, highest total revenue, avg sale per cx is also high

--city2: delhi
highest estimated coffee consumer which 7.7m, highest total cx which is 68, avg rent of cx 330 (still under 500)

--city3: jaipur
highest no of cx is 69, avg rent per cx is very less 156, avg sale per cx is better which is at 11.6k