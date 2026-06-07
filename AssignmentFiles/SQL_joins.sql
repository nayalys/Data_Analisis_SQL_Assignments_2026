USE coffeeshop_db;

-- =========================================================
-- JOINS & RELATIONSHIPS PRACTICE
-- =========================================================

-- Q1) Join products to categories: list product_name, category_name, price.
select  p.name as product_name, c.name as category_name, p.price
from products p
inner join categories c 
on p.category_id = c.category_id;

-- Q2) For each order item, show: order_id, order_datetime, store_name,
--     product_name, quantity, line_total (= quantity * products.price).
--     Sort by order_datetime, then order_id.

SELECT
    oi.order_id,
    o.order_datetime,
    s.name as store_name,
    p.name as product_name,
    oi.quantity,
    (oi.quantity * p.price) AS line_total
FROM
    order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    INNER JOIN stores s ON o.store_id = s.store_id
    INNER JOIN products p ON oi.product_id = p.product_id
ORDER BY
    o.order_datetime,
    o.order_id;

-- Q3) Customer order history (PAID only):
--     For each order, show customer_name, store_name, order_datetime,
--     order_total (= SUM(quantity * products.price) per order).
select 
	concat(cu.first_name, ' ' , cu.last_name) as customer_name, 
	s.name as store_name, 
	o.order_datetime, 
	sum(oi.quantity * p.price) as order_total
from orders o 
left join customers cu on o.customer_id = cu.customer_id
left join stores s on o.store_id = s.store_id
left join order_items oi on o.order_id = oi.order_id
left join products p on oi.product_id = p.product_id
where o.status = 'paid'
group by 
	cu.first_name,
	cu.last_name,
    s.name,
    o.order_datetime, o.order_id
order by o.order_id;


-- Q4) Left join to find customers who have never placed an order.
--     Return first_name, last_name, city, state.

select cu.first_name, cu.last_name,cu.city,cu.state
from customers cu
left join orders o on cu.customer_id = o.customer_id
where o.customer_id is null;

-- Q5) For each store, list the top-selling product by units (PAID only).
--     Return store_name, product_name, total_units.
--     Hint: Use a window function (ROW_NUMBER PARTITION BY store) or a correlated subquery.


SELECT 
    s.name as store_name,
    p.name as product_name,
    SUM(oi.quantity) AS total_units
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN stores s ON o.store_id = s.store_id
WHERE o.status = 'PAID'
GROUP BY s.store_id, s.name, p.product_id, p.name
HAVING SUM(oi.quantity) = (
    SELECT MAX(total_units)
    FROM (
        SELECT 
            s2.store_id,
            p2.product_id,
            SUM(oi2.quantity) AS total_units
        FROM orders o2
        JOIN order_items oi2 ON o2.order_id = oi2.order_id
        JOIN products p2 ON oi2.product_id = p2.product_id
        JOIN stores s2 ON o2.store_id = s2.store_id
        WHERE o2.status = 'PAID'
        AND s2.store_id = s.store_id
        GROUP BY s2.store_id, p2.product_id
    ) store_sales
);

-- Q6) Inventory check: show rows where on_hand < 12 in any store.
--     Return store_name, product_name, on_hand.

select 
	s.name as store_name, 
    p.name as product_name, 
    i.on_hand as on_hand
from inventory i
join stores s on i.store_id = s.store_id
join products p on i.product_id = p.product_id
where i.on_hand < 12
order by s.name, p.name;


-- Q7) Manager roster: list each store's manager_name and hire_date.
--     (Assume title = 'Manager').
select distinct
	concat(emp.first_name,' ',emp.last_name) as manager_name,
    s.name as store_name,
    emp.hire_date
from employees emp
join stores s on emp.store_id = s.store_id
where emp.title = 'Manager'
order by store_name, manager_name;

-- Q8) Using a subquery/CTE: list products whose total PAID revenue is above
--     the average PAID product revenue. Return product_name, total_revenue.

select 
	p.name as product_name, 
    sum(oi.quantity * p.price) as total_revenue
from products p
join order_items oi on p.product_id = oi.product_id
join orders o  on oi.order_id = o.order_id
where o.status = 'paid'
group by p.product_id, p.name
HAVING SUM(oi.quantity * p.price) > (
    SELECT AVG(product_revenue)
    FROM (
        SELECT 
            SUM(oi2.quantity * p2.price) AS product_revenue
        FROM products p2
        JOIN order_items oi2 ON p2.product_id = oi2.product_id
        JOIN orders o2 ON oi2.order_id = o2.order_id
        WHERE o2.status = 'PAID'
        GROUP BY p2.product_id
    ) revenue_subquery
)
ORDER BY total_revenue DESC;

-- Q9) Churn-ish check: list customers with their last PAID order date.
--     If they have no PAID orders, show NULL.
--     Hint: Put the status filter in the LEFT JOIN's ON clause to preserve non-buyer rows.
select 
	cu.customer_id, 
    cu.first_name, 
    cu.last_name, 
    cu.city,
    cu.state,
   max(date(o.order_datetime)) as last_paid_order_date,
      max(o.order_datetime) as last_paid_order_datetime

from customers cu
left join orders o on cu.customer_id = o.customer_id and o.status = 'PAID'
group by 
    cu.customer_id, 
    cu.first_name, 
    cu.last_name, 
    cu.city, 
    cu.state
order by last_paid_order_datetime DESC ;

-- Q10) Product mix report (PAID only):
--     For each store and category, show total units and total revenue (= SUM(quantity * products.price)).


select 
    s.name as Store_Name,
    cat.name as Product_Category,
    SUM(oi.quantity) as Total_Units,
    ROUND(SUM(oi.quantity * p.price), 2) AS Total_Revenue
from orders o
join order_items oi on o.order_id = oi.order_id
join products p on oi.product_id = p.product_id
join categories cat on  p.category_id = cat.category_id
join stores s on o.store_id = s.store_id
where o.status = 'PAID'
--     For each store and category, show total units and total revenue (= SUM(quantity * products.price)).
