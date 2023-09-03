-- SQL query for bicycle store. Query written to extract needed information from an SQL database via Excel to create Pivot tables and then Tableau visualizations --
SELECT
	ord.order_id,
	CONCAT(cus.first_name,' ', cus.last_name),
-- Concatenating first and last names into a single value --
	cus.city,
	cus.state,
	ord.order_date,
	SUM(ite.quantity) AS 'total_units',
-- Function for sales volume --
	SUM(ite.quantity * ite.list_price) AS 'revenue'
-- Function for revenue --
	pro.product_name,
	cat.category_name,
	sto.store_name,
	CONCAT(first_name,' ', last_name) AS 'Sales Rep'
-- Concatenating for full sales rep name --
FROM sales.orders AS ord
JOIN sales.customers AS cus
	ON ord.customer_id = cus.customer_id
-- Joining tables on the customer_id field --
JOIN sales.order_items AS ite
	ON ord.order_id = ite.order_id
-- Joining tables on the order_id field --
JOIN production.products AS pro
	ON ite.product_id = pro.product_id
-- Joining tables on the product_id field --
JOIN production.categories AS cat
	ON pro.category_id = cat.category_id
-- Joining tables on the category_id field --
JOIN sales.stores AS sto
	ON ord.store_id = sto.store_id
-- Joining tables on the store_id field --
JOIN sales.staffs sta
	ON ord.staff_id = sta.staff_id
-- Joining tables on the staff_id field --
GROUP BY
	ord.order_id,
	CONCAT(cus.first_name,' ', cus.last_name),
	cus.city,
	cus.state,
	ord.order_date,
	pro.product_name,
	cat.category_name,
	sto.store_name,
	CONCAT(first_name,' ', last_name) AS 'Sales Rep'
