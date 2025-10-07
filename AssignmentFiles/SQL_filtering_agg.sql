-- ==================================
-- FILTERS & AGGREGATION
-- ==================================

USE coffeeshop_db;

-- Q1) Compute total items per order.
--     Return (order_id, total_items) from order_items.
SELECT order_id, COUNT(product_id) AS total_items
FROM order_items
GROUP BY order_id;
-- ====================================================================================================================
-- Q2) Compute total items per order for PAID orders only.
--     Return (order_id, total_items). Hint: order_id IN (SELECT ... FROM orders WHERE status='paid').

SELECT order_id, COUNT(product_id) AS total_items
FROM order_items where order_id in (SELECT order_id FROM orders WHERE status= 'paid')
GROUP BY order_id;
-- ====================================================================================================================

-- Q3) How many orders were placed per day (all statuses)?
--     Return (order_date, orders_count) from orders.

SELECT date(order_datetime) AS order_date, count(order_id) AS orders_count
FROM orders
GROUP BY date(order_datetime);
-- ====================================================================================================================

-- Q4) What is the average number of items per PAID order?
--     Use a subquery or CTE over order_items filtered by order_id IN (...).
SELECT order_id FROM orders WHERE status = 'PAID'; -- Paid orders from orders
SELECT * FROM order_items 
WHERE order_id IN (SELECT order_id FROM orders WHERE status = 'PAID');  -- filter Paid order items from order_items

SELECT order_id, COUNT(*) AS item_count FROM order_items 
WHERE order_id IN (SELECT order_id FROM orders WHERE status = 'PAID') GROUP BY order_id; -- get item counts
-- Final query
SELECT ROUND(AVG(item_count)) FROM (SELECT order_id, COUNT(*) AS item_count FROM order_items 
WHERE order_id IN (SELECT order_id FROM orders WHERE status = 'PAID') GROUP BY order_id)AS per_order_count; -- get avg of paid filtered items
SHOW ERRORS;
--- 2
-- ====================================================================================================================

-- Q5) Which products (by product_id) have sold the most units overall across all stores?
--     Return (product_id, total_units), sorted desc.

SELECT product_id, SUM(quantity) AS total_units 
FROM order_items 
GROUP BY product_id
ORDER BY total_units DESC;
SHOW ERRORS;
-- ====================================================================================================================

-- Q6) Among PAID orders only, which product_ids have the most units sold?
--     Return (product_id, total_units_paid), sorted desc.
--     Hint: order_id IN (SELECT order_id FROM orders WHERE status='paid').

SELECT product_id, sum(quantity) AS total_units_paid FROM order_items 
WHERE order_id IN (SELECT order_id FROM orders WHERE status = 'PAID') GROUP BY product_id
order by total_units_paid desc ;
-- product_id7, 6 units sold; product_id2 5 units, product_id1 and product_id4 3 units sold
-- ====================================================================================================================

-- Q7) For each store, how many UNIQUE customers have placed a PAID order?
--     Return (store_id, unique_customers) using only the orders table.
SELECT * FROM orders order by store_id;

SELECT store_id, COUNT(DISTINCT customer_id) AS unique_customers
FROM orders 
GROUP BY store_id
ORDER BY store_id;
-- ====================================================================================================================

-- Q8) Which day of week has the highest number of PAID orders?
--     Return (day_name, orders_count). Hint: DAYNAME(order_datetime). Return ties if any.

SELECT DAYNAME(order_datetime) AS day_name, COUNT(order_id) AS orders_count
FROM orders
WHERE order_id IN (SELECT order_id FROM orders WHERE status = 'PAID')
GROUP BY day_name
order by COUNT(order_id) desc ; -- DAYNAME(order_datetime);
-- Tuesday
-- ====================================================================================================================

-- Q9) Show the calendar days whose total orders (any status) exceed 3.
--     Use HAVING. Return (order_date, orders_count).

-- order_date, orders_count by Date
SELECT DATE(order_datetime) AS order_date , COUNT(order_id) AS orders_count
FROM orders GROUP BY DATE(order_datetime) HAVING orders_count > 3;

-- order_date, orders_count by Dayname
SELECT DAYNAME(order_datetime) AS order_date , COUNT(order_id) AS orders_count
FROM orders GROUP BY DAYNAME(order_datetime) HAVING orders_count >3;
-- ====================================================================================================================

-- Q10) Per store, list payment_method and the number of PAID orders.
--      Return (store_id, payment_method, paid_orders_count).
-- app 3/13
SELECT store_id, payment_method, COUNT(order_id) AS paid_orders_count
FROM orders WHERE order_id IN (SELECT order_id FROM orders WHERE status = 'PAID')
GROUP BY store_id, payment_method
ORDER BY store_id;
SHOW ERRORS;
-- ====================================================================================================================

-- Q11) Among PAID orders, what percent used 'app' as the payment_method?
--      Return a single row with pct_app_paid_orders (0–100).
-- 3/13
SELECT CONCAT(ROUND(COUNT(order_id)*100/(SELECT COUNT(*) FROM orders WHERE status = 'PAID'),1), '%') AS pct_app_paid_orders
FROM orders 
WHERE order_id IN (SELECT order_id FROM orders WHERE status = 'PAID' AND payment_method LIKE '%app%')
GROUP BY payment_method;
-- 23.1% app ad payment method

SELECT order_id FROM orders WHERE status = 'PAID' AND payment_method LIKE '%app%';
SELECT payment_method, count(*) FROM orders where  status = 'PAID'
group by payment_method ;
SHOW ERRORS;
-- ====================================================================================================================

-- Q12) Busiest hour: for PAID orders, show (hour_of_day, orders_count) sorted desc.

SELECT HOUR(order_datetime) AS hour_of_day, COUNT(order_id) AS orders_count
FROM orders
WHERE order_id IN (SELECT order_id FROM orders WHERE status = 'PAID')
GROUP BY hour_of_day
ORDER BY orders_count DESC;
-- 7 am
-- ====================================================================================================================
