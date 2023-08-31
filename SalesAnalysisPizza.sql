
/* Creating tables in from previously existing Excel data. Declaring table name, data type, primary keys, and NULL/NOT NULL */

CREATE TABLE `orders` (
    `row_id` int  NOT NULL ,
    `order_id` varchar(10)  NOT NULL ,
    `created_date` datetime  NOT NULL ,
    `quantity` int  NOT NULL ,
    `cust_id` int  NOT NULL ,
    `delivery` boolean  NOT NULL ,
    `add_id` int  NOT NULL ,
    `item_id` varchar(10)  NOT NULL ,
    PRIMARY KEY (
        `row_id`
    )
);

/* Basic orders table (normalized to reduce redundancy) */
CREATE TABLE `customers` (
    `cust_id` int  NOT NULL ,
    `cust_firstname` varchar(50)  NOT NULL ,
    `cust_lastname` varchar(50)  NOT NULL ,
    PRIMARY KEY (
        `cust_id`
    )
);

CREATE TABLE `address` (
    `add_id` int  NOT NULL ,
    `delivery_address1` varchar(200)  NOT NULL ,
    `delivery_address2` varchar(200)  NULL ,
    -- NULL added as delivery address 2 isn't always needed
    `delivery_city` varchar(50)  NOT NULL ,
    `delivery_zipcode` varchar(20)  NOT NULL ,
    PRIMARY KEY (
        `add_id`
    )
);

CREATE TABLE `item` (
    `item_id` varchar(10)  NOT NULL ,
    `sku` varchar(20)  NOT NULL ,
    `item_name` varchar(50)  NOT NULL ,
    `item_cat` varchar(50)  NOT NULL ,
    `item_size` varchar(20)  NOT NULL ,
    `item_price` decimal(5,2)  NOT NULL ,
    PRIMARY KEY (
        `item_id`
    )
);

/* Above tables are all for ORDERS  */
CREATE TABLE `ingredient` (
    `ing_id` varchar(10)  NOT NULL ,
    `ing_name` varchar(200)  NOT NULL ,
    `ing_weight` int  NOT NULL ,
    `ing_meas` varchar(20)  NOT NULL ,
    `ing_price` decimale(5,2)  NOT NULL ,
    PRIMARY KEY (
        `ing_id`
    )
);

CREATE TABLE `recipe` (
    `row_id` int  NOT NULL ,
    `recipe_id` varchar(20)  NOT NULL ,
    `ing_id` varchar(10)  NOT NULL ,
    `quantity` int  NOT NULL ,
    PRIMARY KEY (
        `row_id`
    )
);

CREATE TABLE `inventory` (
    `inv_id` int  NOT NULL ,
    `item_id` varchar(10)  NOT NULL ,
    `quantity` int  NOT NULL ,
    PRIMARY KEY (
        `inv_id`
    )
);

/* Inventory prices ABOVE */
CREATE TABLE `shift` (
    `shift_id` varchar(20)  NOT NULL ,
    `day_of_week` varchar(10)  NOT NULL ,
    `start_time` time  NOT NULL ,
    `end_time` time  NOT NULL ,
    PRIMARY KEY (
        `shift_id`
    )
);

CREATE TABLE `rota` (
    `row_id` int  NOT NULL ,
    `rota_id` varchar(20)  NOT NULL ,
    `date` datetime  NOT NULL ,
    `shift_id` varchar(20)  NOT NULL ,
    `staff_id` varchar(20)  NOT NULL ,
    PRIMARY KEY (
        `row_id`
    )
);

CREATE TABLE `staff` (
    `staff_id` varchar(20)  NOT NULL ,
    `first_name` varchar(50)  NOT NULL ,
    `last_name` varchar(50)  NOT NULL ,
    `position` varchar(100)  NOT NULL ,
    `hourly_rate` decimal(5,2)  NOT NULL ,
    PRIMARY KEY (
        `staff_id`
    )
);

/* Joins queried after CSV import */

ALTER TABLE `orders` ADD CONSTRAINT `fk_orders_cust_id` FOREIGN KEY(`cust_id`)
REFERENCES `customers` (`cust_id`);

ALTER TABLE `address` ADD CONSTRAINT `fk_address_add_id` FOREIGN KEY(`add_id`)
REFERENCES `orders` (`add_id`);

ALTER TABLE `item` ADD CONSTRAINT `fk_item_item_id` FOREIGN KEY(`item_id`)
REFERENCES `orders` (`item_id`);

ALTER TABLE `ingredient` ADD CONSTRAINT `fk_ingredient_ing_id` FOREIGN KEY(`ing_id`)
REFERENCES `recipe` (`ing_id`);

ALTER TABLE `recipe` ADD CONSTRAINT `fk_recipe_recipe_id` FOREIGN KEY(`recipe_id`)
REFERENCES `item` (`sku`);

ALTER TABLE `inventory` ADD CONSTRAINT `fk_inventory_item_id` FOREIGN KEY(`item_id`)
REFERENCES `recipe` (`ing_id`);

ALTER TABLE `shift` ADD CONSTRAINT `fk_shift_shift_id` FOREIGN KEY(`shift_id`)
REFERENCES `rota` (`shift_id`);

ALTER TABLE `rota` ADD CONSTRAINT `fk_rota_date` FOREIGN KEY(`date`)
REFERENCES `orders` (`created_date`);

ALTER TABLE `rota` ADD CONSTRAINT `fk_rota_staff_id` FOREIGN KEY(`staff_id`)
REFERENCES `staff` (`staff_id`);

/* The following data is required for the first dashboard (sales):

1. Total Orders (order_id)
2. Total Sales (item_id)
3. Total Items (quantity)
4. Average Order Value (Can be calculated in Power BI)
5. Sales by Category (item_cat and item_name)
6. Top Selling Items (created_at)
7. Orders by Hour (delivery addresses)
8. Sales by Hour
9. Orders by Address
10. Orders by Delivery/Pick-up

The following query is made in relation (numerically) to this list (with comments above). Aliasing and basic LEFT JOINS */

SELECT 
o.order_id,
i.item_price,
o.quantity,
i.item_cat,
i.item_name,
o.created_at,
a.delivery_address1,
a.delivery_address2,
a.delivery_city,
a.delivery_zipcode,
o.delivery
FROM orders AS o 
LEFT JOIN item AS i
	ON o.item_id = i.item_id
LEFT JOIN address AS a
	ON o.add_id = a.add_id

/* The following data is required for the second dashboard (inventory management):

1. Total quantity by ingredient = (No. of orders * ingredient quantity in recipe)
2. Total cost of ingredients
3. Calculated cost of pizza
4. Percentage stock remaining by ingredient */

SELECT
o.item_id,
i.sku,
i.item_name,
r.ing_id,
ing.ing_name,
r.quantity AS recipe_quantity,
sum(o.quantity) AS order_quantity,
ing.ing_weight,
ing.ing_price
FROM orders AS o
LEFT JOIN item AS i
	ON o.item_id = i.item_id
LEFT JOIN recipe AS r
	ON i.sku = r.recipe_id
LEFT JOIN ingredient AS ing 
	ON ing.ing_id = r.ing_id
GROUP BY o.item_id, i.sku, i.item_name, r.ing_id, r.quantity, ing.ing_name, ing.ing_weight, ing.ing_price

/* This part of the query gives us the number of orders per pizza, then it is joined to the recipe table to give us the quantity of ingredients needed per recipe. 
This is then joined to the ingredient table to show ingredient names, further data in the ingredient table (price and weight) allows for a full calculation of price.
To get the total one would usually multiply 'recipe_quantity' by 'order_quantity', but order_quantity is already aggregated so it can't be used within the same SELECT statement. 
So we need a subquery, see update below */

SELECT 
s1.item_name,
s1.ing_id,
s1.ing_name,
s1.ing_weight,
s1.ing_price,
s1.order_quantity,
s1.recipe_quantity,
s1.order_quantity*s1.recipe_quantity AS ordered_weight,
s1.ing_price/s1.ing_weight AS unit_cost,
(s1.order_quantity*s1.recipe_quantity)*(s1.ing_price/s1.ing_weight) AS ingredient_cost
FROM (SELECT
o.item_id,
i.sku,
i.item_name,
r.ing_id,
ing.ing_name,
r.quantity AS recipe_quantity,
sum(o.quantity) AS order_quantity,
ing.ing_weight,
ing.ing_price
FROM orders AS o
LEFT JOIN item AS i
	ON o.item_id = i.item_id
LEFT JOIN recipe AS r
	ON i.sku = r.recipe_id
LEFT JOIN ingredient AS ing 
	ON ing.ing_id = r.ing_id
GROUP BY o.item_id, i.sku, i.item_name, r.ing_id, r.quantity, ing.ing_name, ing.ing_weight, ing.ing_price) AS s1

/* Original query is bracketed into a subquery as to refine data selection. The three new aliases from multiplications allow for new total columns.
This allows everything need for both quantity by ingredient, total cost of ingredient, and cost per pizza. This query is turned into a view (CREATE VIEW view1
AS[query])*/

SELECT 
	s2.ing_name,
    s2.ordered_weight,
    ing.ing_weight*inv.quantity AS total_inv_weight,
    (ing.ing_weight * inv.quantity)-s2.ordered_weight AS remaining_weight
    
FROM (SELECT 
ing_id,
ing_name,
	sum(ordered_weight) AS ordered_weight
FROM view1
GROUP BY ing_name, ing_id) AS s2

LEFT JOIN inventory AS inv
	ON inv.item_id = s2.ing_id
LEFT JOIN ingredient AS ing
	ON ing.ing_id = s2.ing_id

/* Selecting from 'view1', joining to the relevant tables (inventory and ingredient) to then subquery that statement as to work out
total inventory weight and the remaining weight. */

/* From here we can move to staff and rotas. The below basic query joins the relevant tables of staff, rota, and shift times */

SELECT
r.date,
s.first_name,
s.last_name,
s.hourly_rate,
sh.start_time,
sh.end_time
FROM rota AS r
LEFT JOIN staff AS s
	ON r.staff_id = s.staff_id
LEFT JOIN shift AS sh
	ON r.shift_id = sh.shift_id

/* Now the difference between the start_time and end_time needs to be calculated and then multiplied by the hourly rate to work out staff costs */

SELECT
r.date,
s.first_name,
s.last_name,
s.hourly_rate,
sh.start_time,
sh.end_time,
((hour(timediff(sh.end_time, sh.start_time))*60)+(minute(timediff(sh.end_time, sh.start_time))))/60 AS hours_in_shift,
((hour(timediff(sh.end_time, sh.start_time))*60)+(minute(timediff(sh.end_time, sh.start_time))))/60 *s.hourly_rate AS staff_cost

/*The above 2 lines calculate the difference between end time and start time in hours, multiply that by 60 to work out  no of minutes
this is added to the difference between start and end minutes, this is total minutes and divided by 60 to get the difference in hours. This is 
then copied and multiplied by hourly rate */

FROM rota AS r
LEFT JOIN staff AS s
	ON r.staff_id = s.staff_id
LEFT JOIN shift AS sh
	ON r.shift_id = sh.shift_id
