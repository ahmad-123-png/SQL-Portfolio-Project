create schema Portfolio_project;

use Portfolio_project;

select * from customers;
select * from products;
select * from sales;
select * from inventory;

alter table customers
add primary key (customer_id);

alter table products
add primary key (product_id);

alter table sales
add primary key (sale_id);

alter table inventory
add primary key (movement_id);

alter table sales
add constraint fk1_sales
foreign key(customer_id) references customers (customer_id);

alter table sales
add constraint fk2_sales
foreign key(product_id) references products (product_id);

alter table inventory
add constraint fk_inventory
foreign key(product_id) references products (product_id);

create table customers_backup as (

select * from customers

);

create table inventory_backup as (

select * from inventory);

create table products_backup as (

select * from products

);

create table sales_backup as (

select * from sales

);

-- Module 1 Question 1 (Total Sales per Month)

select date_format(sale_date,"%Y" "-" "%m") as months, round(sum(total_amount),2) as sales, round(sum(total_amount*(1-discount_applied/100)),2) as revenue,  sum(quantity_sold) as number_of_units_sold
from sales
group by months
order by months;

-- Module 1 Question 2 (average discount per month)

-- Wrong Attempt 1:
/*
select date_format(sale_date,"%Y" "-" "%m") as months, avg(discount_applied) as average_discount_percentage
from sales d
join (select date_format(sale_date,"%Y" "-" "%m") as months, round(sum(total_amount),2) as sales, round(sum(total_amount*(1-discount_applied/100)),2) as revenue,  sum(quantity_sold) as number_of_units_sold
		from sales
		group by months
		order by months) total_sales on total_sales.months=d.months;

*/
-- Wrong Attempt 2

/*
with total_sales as(
select date_format(sale_date,"%Y" "-" "%m") as months, round(sum(total_amount),2) as sales, round(sum(total_amount*(1-discount_applied/100)),2) as revenue,  sum(quantity_sold) as number_of_units_sold
from sales
group by months
order by months)

select date_format(d.sale_date,"%Y" "-" "%m") as months, round(avg(d.discount_applied),2) as average_discount_percentage
from sales d
join total_sales s on date_format(d.sale_date,"%Y" "-" "%m")= s.months
group by date_format(d.sale_date,"%Y" "-" "%m");
-- order by months;
*/

-- Wrong Attempt 3

/*
WITH total_sales AS (
    SELECT 
        DATE_FORMAT(sale_date, "%Y-%m") AS months, 
        ROUND(SUM(total_amount), 2) AS sales, 
        ROUND(SUM(total_amount * (1 - discount_applied / 100)), 2) AS revenue, 
        SUM(quantity_sold) AS number_of_units_sold
    FROM 
        sales
    GROUP BY 
        DATE_FORMAT(sale_date, "%Y-%m")
    ORDER BY 
        months
)

SELECT 
    s.months, 
    ROUND(AVG(d.discount_applied), 2) AS average_discount_percentage, 
    s.sales, 
    s.revenue, 
    s.number_of_units_sold
FROM 
    sales d
JOIN 
    total_sales s 
ON 
    DATE_FORMAT(d.sale_date, "%Y-%m") = s.months
GROUP BY 
    s.months, 
    s.sales, 
    s.revenue, 
    s.number_of_units_sold
ORDER BY 
    s.months;
*/

-- correct code (the harder approach)

    WITH total_sales AS (
    SELECT 
        DATE_FORMAT(sale_date, "%Y-%m") AS months, 
        ROUND(SUM(total_amount), 2) AS sales, 
        ROUND(SUM(total_amount * (1 - discount_applied / 100)), 2) AS revenue, 
        SUM(quantity_sold) AS number_of_units_sold
    FROM 
        sales
    GROUP BY 
        DATE_FORMAT(sale_date, "%Y-%m")
    ORDER BY 
        months
)
SELECT 
    s.months, 
    ROUND(AVG(d.discount_applied), 2) AS average_discount_percentage, 
    s.sales, 
    s.revenue, 
    s.number_of_units_sold
FROM 
    sales d
JOIN 
    total_sales s 
ON 
    DATE_FORMAT(d.sale_date, "%Y-%m") = s.months
GROUP BY 
    s.months
ORDER BY 
    s.months;
    
-- Simpler way
    
SELECT 
	date_format(sale_date,"%Y" '-' "%m") as months,
    round(avg(discount_applied),1) as Average_Discount,
    round(sum(total_amount),2) as sales,
    ROUND(SUM(total_amount * (1 - discount_applied / 100)), 2) AS revenue, 
        SUM(quantity_sold) AS number_of_units_sold
FROM sales
GROUP BY months
order by months;

-- Module 2 Question 1 (Identify high-value customers)

-- High value customers

select customer_id, round(sum(total_amount),2) as money_spent
from sales
group by customer_id
order by money_spent desc;

select c.*, s.money_spent
from customers c
join ( select customer_id, round(sum(total_amount),2) as money_spent
		from sales
		group by customer_id
		order by money_spent desc) s on c.customer_id=s.customer_id
order by s.money_spent desc;

-- Module 2 Question 2 (Oldest customers)
-- try using window functions and partition, over

-- Wrong attempt 1

/*

select c.* , date_format(date_of_birth, "%Y") as birth_year,m.total_money_spent
from customers c
join( select customer_id, round(sum(total_amount)) as total_money_spent
		from sales s
        group by customer_id) m on m.customer_id= c.customer_id
where date_format(date_of_birth, "%Y")>= 1990 and date_format(date_of_birth, "%Y")<=1999
order by total_money_spent desc;
*/

-- Wrong attempt 2 

/*
select  round(sum(total_amount)) as total_money_spent
from sales s
join ( select * , date_format(date_of_birth, "%Y") as birth_year
		from customers
		where date_format(date_of_birth, "%Y")>= 1990 and date_format(date_of_birth, "%Y")<=1999
		order by birth_year) birth_year on birth_year.customer_id= s.customer_id;
*/

-- Wrong attempt 3

/*
WITH filtered_customers AS (
    SELECT 
        *, 
        DATE_FORMAT(date_of_birth, "%Y") AS birth_year
    FROM 
        customers
    WHERE 
        DATE_FORMAT(date_of_birth, "%Y") BETWEEN 1990 AND 1999
)
SELECT 
    fc.*, 
    p.* 
FROM 
    filtered_customers fc
JOIN 
    sales s 
    ON fc.customer_id = s.customer_id
JOIN 
    products p 
    ON s.product_id = p.product_id
ORDER BY 
    fc.birth_year;

*/
/*
select p.*
from products p
left join (select s.customer_id, round(sum(s.total_amount),2) as money_spent
			from sales s 
			group by customer_id
			order by money_spent desc) s on p.product_id=s.product_id;
*/

-- Correct answer

with total_money as (select customer_id, round(sum(total_amount)) as total_money_spent
from sales s
group by customer_id)

select c.*, date_format(date_of_birth, "%Y") as birth_year,s.sale_id,s.product_id,s.sale_date,s.discount_applied,s.total_amount,p.product_name,p.category,t.total_money_spent
from customers c
join sales s on s.customer_id= c.customer_id
join products p on p.product_id=s.product_id
join total_money t on t.customer_id=s.customer_id
where date_format(date_of_birth, "%Y")>= 1990 and date_format(date_of_birth, "%Y")<=1999
order by c.customer_id;

-- Module 2 question 3 (Customer segmentation)

with total_money_spent as(
select customer_id,round(sum(total_amount),2) as total_money
from sales
group by customer_id)

select c.*,t.total_money,
dense_rank() over (order by t.total_money desc) as ranks
from customers c
join total_money_spent t on c.customer_id= t.customer_id
order by ranks;

-- Module 3 Question 1 (Stock Management)

select * from products
order by stock_quantity;

with stock_update as (select product_id, product_name, category, stock_quantity,
case when stock_quantity<10 then "Low stock"
else " Stock Available"
end as stock_status
from products
order by stock_status desc)

-- Restocking recommendations based on sales performance

select s.product_id,sum(s.quantity_sold) as items_sold,round(sum(s.total_amount),2) as total_money_earned,u.product_name,u.category,u.stock_quantity,u.stock_status
from sales s
join stock_update u on s.product_id=u.product_id
where stock_quantity<10
group by s.product_id
order by items_sold desc;

select * from inventory;

-- Restocking based on inventory data

with stock_update as (select product_id, product_name, category, stock_quantity,
case when stock_quantity<10 then "Low stock"
else " Stock Available"
end as stock_status
from products
order by stock_status desc)

select i.product_id,i.movement_type,sum(i.quantity_moved) as quantity_moved,u.product_name,u.category,u.stock_quantity,u.stock_status
from inventory i
join stock_update u on i.product_id=u.product_id
group by i.product_id,i.movement_type,i.movement_date
order by u.stock_status desc, i.product_id;



-- Product16 has 34 items sold so it should be restocked on priority by around 35 items, Product 41 has 27 items sold so should be stocked by 25 items.
-- Product12 only sold 17 items and is among the bottom 5 products based on items sold, so only restock it slightly by 10-15 items.

-- Module 3 question 2 (Inventory Movements Overview)

SELECT product_id, movement_date,
sum(CASE 
    WHEN movement_type = 'IN' THEN quantity_moved
    ELSE 0
    END )AS Product_restocked,
sum(CASE
    WHEN movement_type = 'OUT' THEN quantity_moved
    ELSE 0
    END) AS Product_sold
FROM inventory
GROUP BY product_id, movement_date
ORDER BY product_id;

-- Module 3 question 3 (Rank Products)

select *,
dense_rank() over (partition by category order by price desc) as ranks
from products
order by category, price desc;

-- Module 4 question 1 (Average order size in terms of quantity sold)

with average_order as(
select product_id,round(avg(quantity_sold),2) as average_order_size
from sales
group by product_id)

select p.product_id,p.product_name,p.category,p.price,a.average_order_size
from products p
join average_order a on p.product_id=a.product_id
order by average_order_size desc;

-- Module 4 question 2 (Recent Restock Product)

select i.product_id, p.product_name,i.movement_date,sum(i.quantity_moved) as quantity_moved,p.stock_quantity
from inventory i
join products p on i.product_id=p.product_id
group by i.product_id,p.product_name,i.movement_type,i.movement_date,p.stock_quantity
having i.movement_type = "IN"
order by i.movement_date desc;






