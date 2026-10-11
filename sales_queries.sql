-- =====================================================================
-- SQL Practice: Sales Dataset (200 orders)  |  Works in SQLite / MySQL / PostgreSQL
-- Tables (in sales.db):
--   sales(order_id, customer_name, order_date, category, sub_category,
--         product_name, quantity, unit_price, total_price, region)   <- flat, as in the Excel file
--   customers(customer_id, customer_name, region)
--   products(product_id, product_name, category, sub_category, unit_price)
--   orders(order_id, customer_id, product_id, order_date, quantity, total_price)
-- NOTE: every customer in this dataset has exactly ONE order, so "top customers"
--       means "customers with the largest single order".
-- =====================================================================

-- ---------- 1. BASIC QUERIES: SELECT / WHERE / ORDER BY ----------
SELECT order_id, customer_name, category, total_price
FROM sales
WHERE region = 'East' AND total_price > 20000
ORDER BY total_price DESC;

-- ---------- 2. AGGREGATIONS: SUM / AVG / COUNT / MIN / MAX ----------
SELECT COUNT(*)                    AS total_orders,
       SUM(total_price)            AS total_revenue,
       ROUND(AVG(total_price), 2)  AS avg_order_value,
       MIN(total_price)            AS smallest_order,
       MAX(total_price)            AS largest_order
FROM sales;

-- ---------- 3. GROUP BY (+ HAVING) ----------
-- Revenue and average order value by category
SELECT category,
       COUNT(*)                   AS orders,
       SUM(total_price)           AS revenue,
       ROUND(AVG(total_price), 2) AS avg_order_value
FROM sales
GROUP BY category
ORDER BY revenue DESC;

-- Regions whose average order value is above 12,000
SELECT region, ROUND(AVG(total_price), 2) AS avg_order_value
FROM sales
GROUP BY region
HAVING AVG(total_price) > 12000
ORDER BY avg_order_value DESC;

-- Monthly revenue trend
SELECT strftime('%Y-%m', order_date) AS month,      -- MySQL: DATE_FORMAT(order_date,'%Y-%m')
       COUNT(*) AS orders, SUM(total_price) AS revenue
FROM sales
GROUP BY month
ORDER BY month;

-- ---------- 4. ASSIGNMENT: TOP CUSTOMERS ----------
-- Top 10 customers by order value
SELECT customer_name, region, category, total_price
FROM sales
ORDER BY total_price DESC
LIMIT 10;

-- Same idea using the normalized tables (JOIN)
SELECT c.customer_name, c.region, p.product_name, o.total_price
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN products  p ON p.product_id  = o.product_id
ORDER BY o.total_price DESC
LIMIT 10;

-- ---------- 5. ASSIGNMENT: AVERAGE ORDER VALUES ----------
-- Average order value per region and category
SELECT region, category,
       ROUND(AVG(total_price), 2) AS avg_order_value,
       COUNT(*)                   AS orders
FROM sales
GROUP BY region, category
ORDER BY region, avg_order_value DESC;

-- ---------- 6. JOINS ----------
-- Revenue by customer region and product sub-category
SELECT c.region, p.sub_category, SUM(o.total_price) AS revenue
FROM orders o
INNER JOIN customers c ON c.customer_id = o.customer_id
INNER JOIN products  p ON p.product_id  = o.product_id
GROUP BY c.region, p.sub_category
ORDER BY revenue DESC
LIMIT 10;

-- LEFT JOIN: products that have never been ordered (none here, but the pattern matters)
SELECT p.product_name
FROM products p
LEFT JOIN orders o ON o.product_id = p.product_id
WHERE o.order_id IS NULL;

-- ---------- 7. SUBQUERIES ----------
-- Orders above the overall average order value
SELECT order_id, customer_name, total_price
FROM sales
WHERE total_price > (SELECT AVG(total_price) FROM sales)
ORDER BY total_price DESC;

-- Orders above the average for their own category (correlated subquery)
SELECT s.order_id, s.customer_name, s.category, s.total_price
FROM sales s
WHERE s.total_price > (SELECT AVG(total_price) FROM sales WHERE category = s.category)
ORDER BY s.category, s.total_price DESC;

-- Categories whose total revenue beats the average category revenue (subquery in FROM)
SELECT category, revenue
FROM (SELECT category, SUM(total_price) AS revenue FROM sales GROUP BY category) t
WHERE revenue > (SELECT AVG(revenue)
                 FROM (SELECT SUM(total_price) AS revenue FROM sales GROUP BY category));

-- ---------- 8. CASE STATEMENTS ----------
-- Segment orders into Small / Medium / Large and summarise each tier
SELECT CASE WHEN total_price >= 20000 THEN 'Large'
            WHEN total_price >= 5000  THEN 'Medium'
            ELSE 'Small' END AS order_tier,
       COUNT(*)                   AS orders,
       SUM(total_price)           AS revenue,
       ROUND(AVG(total_price), 2) AS avg_order_value
FROM sales
GROUP BY order_tier
ORDER BY revenue DESC;

-- Conditional aggregation (pivot-style): revenue per category as columns, by region
SELECT region,
       SUM(CASE WHEN category = 'Electronics' THEN total_price ELSE 0 END) AS electronics,
       SUM(CASE WHEN category = 'Furniture'   THEN total_price ELSE 0 END) AS furniture,
       SUM(CASE WHEN category = 'Clothing'    THEN total_price ELSE 0 END) AS clothing,
       SUM(CASE WHEN category = 'Grocery'     THEN total_price ELSE 0 END) AS grocery
FROM sales
GROUP BY region;
