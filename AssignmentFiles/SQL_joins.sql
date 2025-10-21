USE coffeeshop_db;

-- =========================================================
-- JOINS & RELATIONSHIPS PRACTICE
-- =========================================================

-- Q1) Join products to categories: list product_name, category_name, price.

SELECT p.name AS product_name, c.name AS category_name, p.price
FROM products p INNER JOIN categories c
ON p.category_id = c.category_id
ORDER BY product_name;
SHOW ERRORS;
-- ====================================================================================================================

-- Q2) For each order item, show: order_id, order_datetime, store_name,
--     product_name, quantity, line_total (= quantity * products.price).
--     Sort by order_datetime, then order_id.

SELECT oi.order_item_id, oi.order_id, o.order_datetime, s.name AS store_name, 
		p.name AS product_name, oi.quantity, (oi.quantity*p.price) AS line_total 
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN stores s ON o.store_id = s.store_id
JOIN products p ON oi.product_id = p.product_id
ORDER BY o.order_datetime,oi.order_id;
SELECT * FROM stores;
SHOW tables;
SHOW ERRORS;

-- ====================================================================================================================

-- Q3) Customer order history (PAID only):
--     For each order, show customer_name, store_name, order_datetime,
--     order_total (= SUM(quantity * products.price) per order).

SELECT o.order_id, CONCAT(c.first_name,' ', c.last_name) AS customer_name, s.name AS store_name,
		o.order_datetime, SUM(oi.quantity * p.price) AS order_total
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c ON o.customer_id = c.customer_id
JOIN stores s ON o.store_id = s.store_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'PAID'
GROUP BY o.order_id;   -- , o.order_datetime;
SHOW ERRORS;
-- ====================================================================================================================

-- Q4) Left join to find customers who have never placed an order.
--     Return first_name, last_name, city, state.

SELECT c.first_name, c.last_name, c.city, c.state
FROM customers c  LEFT JOIN orders o   ON o.customer_id = c.customer_id 
WHERE c.customer_id NOT IN (SELECT o.customer_id FROM orders);
-- ====================================================================================================================

-- Q5) For each store, list the top-selling product by units (PAID only).
--     Return store_name, product_name, total_units.
--     Hint: Use a window function (ROW_NUMBER PARTITION BY store) or a correlated subquery.
SELECT store_name, product_name, MAX(total_units1) AS total_units
FROM
(SELECT s.name AS store_name, p.name AS product_name, SUM(oi.quantity) AS total_units1
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN stores s ON o.store_id = s.store_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'PAID'
GROUP BY o.store_id,store_name,product_name) store_qty
GROUP BY store_name,product_name
ORDER BY store_name;
SHOW ERRORS;
-- ====================================================================================================================

-- Q6) Inventory check: show rows where on_hand < 12 in any store.
--     Return store_name, product_name, on_hand.
SELECT s.name AS store_name, p.name AS product_name, i.on_hand
FROM inventory i
JOIN products p ON i.product_id = p.product_id
JOIN stores s ON i.store_id = s.store_id
WHERE i.on_hand < 12;
SHOW ERRORS;
-- ====================================================================================================================

-- Q7) Manager roster: list each store's manager_name and hire_date.
--     (Assume title = 'Manager').
SELECT s.name AS store_name, CONCAT(e.first_name,' ',e.last_name) AS store_manager_name , e.hire_date
FROM employees e JOIN stores s ON e.store_id = s.store_id
WHERE title = 'Manager';
-- ====================================================================================================================

-- Q8) Using a subquery/CTE: list products whose total PAID revenue is above
--     the average PAID product revenue. Return product_name, total_revenue.

-- total PAID revenue for each product
SELECT p.name AS product_name, SUM(oi.quantity*p.price) AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'PAID'
GROUP BY product_name;

-- Product revenue
SELECT SUM(oi.quantity * p.price) AS product_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'PAID'
GROUP BY p.name;

-- avg revenue
SELECT AVG(product_revenue)
FROM (
	SELECT 
	SUM(oi.quantity * p.price) AS product_revenue
	FROM orders o
	JOIN order_items oi ON o.order_id = oi.order_id
	JOIN products p ON oi.product_id = p.product_id
	WHERE o.status = 'PAID'
	GROUP BY p.name
) avg;
    
-- final query
SELECT p.name AS product_name, SUM(oi.quantity * p.price) AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'PAID'
GROUP BY p.name
HAVING total_revenue > 
(
    SELECT AVG(product_revenue)
    FROM (
        SELECT 
            SUM(oi.quantity * p.price) AS product_revenue
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        JOIN products p ON oi.product_id = p.product_id
        WHERE o.status = 'PAID'
        GROUP BY p.name
    ) avg
 );
 
 -- or
WITH products_revenue AS(
 SELECT products.name AS product_name, SUM(order_items.quantity*products.price) AS revenue, orders.order_id
 FROM orders
 JOIN  order_items ON order_items.order_id = orders.order_id
 JOIN products ON order_items.product_id = products.product_id
 WHERE orders.status = 'paid'
 GROUP BY products.name,orders.order_id,products.product_id
 )
 SELECT avg(revenue) as avg_revenue FROM products_revenue
 ;
 
 WITH products_revenue AS(
 SELECT products.name AS product_name, SUM(order_items.quantity*products.price) AS total_revenue
 FROM orders
 JOIN  order_items ON order_items.order_id = orders.order_id
 JOIN products ON order_items.product_id = products.product_id
 WHERE orders.status = 'paid'
 GROUP BY products.name,products.product_id
 ),
 average_revenue AS (SELECT avg(total_revenue) AS avg_revenue FROM products_revenue)
 SELECT products_revenue.product_name, products_revenue.total_revenue
 FROM products_revenue
 JOIN average_revenue on products_revenue.total_revenue > average_revenue.avg_revenue
 ORDER BY products_revenue.total_revenue desc;
SHOW ERRORS;

-- ==============================================================================================

-- Q9) Churn-ish check: list customers with their last PAID order date.
--     If they have no PAID orders, show NULL.
--     Hint: Put the status filter in the LEFT JOIN's ON clause to preserve non-buyer rows.
SELECT o.customer_id, CONCAT(c.first_name,' ', c.last_name) AS customer_name, DATE(MAX(o.order_datetime)) AS last_paid_order_date
FROM orders o LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE o.status = 'PAID'
GROUP BY o.customer_id ;
SHOW ERRORS;
-- ====================================================================================================================

-- Q10) Product mix report (PAID only):
--     For each store and category, show total units and total revenue (= SUM(quantity * products.price)).
SELECT s.name AS store_name, c.name AS category_name, COUNT(oi.quantity) AS total_units, SUM(oi.quantity * p.price) AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN stores s ON o.store_id = s.store_id
JOIN products p ON p.product_id = oi.product_id
JOIN categories c ON c.category_id = p.category_id
WHERE o.status = 'PAID'
GROUP BY o.store_id,p.category_id
ORDER BY store_name;
SHOW ERRORS;
-- ====================================================================================================================
