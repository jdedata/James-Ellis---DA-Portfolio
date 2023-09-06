-- database files source: https://github.com/AllThingsDataWithAngelina/DataSource/blob/main/sales_data_sample.csv
-- retrieved 06/09/2023
-- Import database from cleaned (Excel) csv file

--Basic data inspect

	SELECT *
	FROM [dbo].[sales_data_sample]

--Checking (distinct) unique values and whether selection would work to plot in Tableau/Power BI

	SELECT DISTINCT STATUS FROM [dbo].[sales_data_sample] --Easy to plot (bar chart) in Tableau
	SELECT DISTINCT YEAR_ID FROM [dbo].[sales_data_sample]
	SELECT DISTINCT PRODUCTLINE FROM [dbo].[sales_data_sample] --Bar or tree plot
	SELECT DISTINCT COUNTRY FROM [dbo].[sales_data_sample] --Map plot
	SELECT DISTINCT DEALSIZE FROM [dbo].[sales_data_sample]
	SELECT DISTINCT TERRITORY FROM [dbo].[sales_data_sample] -- Further plot


--Data analysis

--Group sales by productline

	SELECT PRODUCTLINE, SUM(sales) AS Revenue
--Aliasing sum of sales as 'Revenue' for use later
	FROM SalesData.dbo.sales_data_sample
	GROUP BY PRODUCTLINE
    
--Aggregate needs a group by
    
	ORDER BY 2 DESC
    
--Ordering by (SELECT) position 2 descending

	SELECT YEAR_ID, SUM(sales) AS Revenue
	FROM SalesData.dbo.sales_data_sample
	GROUP BY YEAR_ID
	ORDER BY 2 DESC
    
--Checking most sales (revenue) per year
--Years 2005 appears out of normal range compared to 2003 and 2004, so checking if they operated during the full year of 2005

	SELECT DISTINCT MONTH_ID FROM dbo.sales_data_sample
	WHERE YEAR_ID = 2005

--Returns only 5 distinct months compared to the full 12 from 2003 and 2004, so lower revenue makes sense

	SELECT DEALSIZE, SUM(sales) AS Revenue
	FROM SalesData.dbo.sales_data_sample
	GROUP BY DEALSIZE
	ORDER BY 2 DESC

--Medium size generates the most revenue

--Checking best month for sales + how much was earned

	SELECT MONTH_ID, SUM(sales) AS Revenue, COUNT(ORDERNUMBER) AS Frequency --Counting orders per month
	FROM SalesData.dbo.sales_data_sample
	WHERE YEAR_ID = 2003 --year as variable to change here
	GROUP BY MONTH_ID
	ORDER BY 2 DESC
    
--November and October are top, but November is almost double October. The same repeats for 2004. Didn't check 2005 as lacking data.

--What is it about november?

	SELECT MONTH_ID, PRODUCTLINE, SUM(sales) AS Revenue, COUNT(ORDERNUMBER) AS Frequency --Adding productline to SELECT to see what product was popular
	FROM SalesData.dbo.sales_data_sample
	WHERE YEAR_ID = 2003 AND MONTH_ID = 11 --Checking only November
	GROUP BY MONTH_ID, PRODUCTLINE
	ORDER BY 3 DESC

--Classic cars and vintage are best sellers

--Who is the best customer? (RFM Analysis - Last order, count of orders, total spent (Sum or Average))
    
	DROP TABLE IF EXISTS #rfm --Eventual need for a temp table
	;with rfm as --CTE 
	(SELECT
	CUSTOMERNAME,
	SUM(sales) AS MonetaryValue,
	AVG(sales) AS AvgMonetaryValue,
	COUNT(ORDERNUMBER) AS Frequency,
	MAX(ORDERDATE) AS last_order_date,
	(SELECT MAX(ORDERDATE) FROM dbo.sales_data_sample) AS max_order_date, -- View the customers last order date and the maximum date in the dataset
	DATEDIFF(DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM dbo.sales_data_sample)) AS Recency --Column/alias 'Recency' gives difference in days (DD) between last order and max date (with common data set max date would likely be the current day)
	FROM SalesData.dbo.sales_data_sample
	GROUP BY CUSTOMERNAME),

	rfm_calc AS (

	SELECT r.*
	NTILE(4) OVER (ORDER BY Recency DESC) AS RFM_Recency,
	NTILE(4) OVER (ORDER BY Frequency) AS RFM_Frequency,
	NTILE(4) OVER (ORDER BY AvgMonetaryValue) AS RFM_Monetary
    
--NTILE to split into bins (4), in relation to each the greater the number (from 1-4), the greater in terms of recency, frequency, and or monetary value
    
	FROM rfm AS r) --Aliased as r

	SELECT c.*, RFM_Recency + RFM_Frequency + RFM_Monetary AS rfm_cell,
	cast(RFM_Recency as varchar) + cast(RFM_Frequency as varchar) + cast(RFM_Monetary as varchar) AS rfm_cell_string -- Concatenates the RFM values as strings instead of integers
	INTO #rfm
	FROM rfm_calc AS c

	SELECT *	
	FROM #rfm
    
--Quick run to check the temp table works okay

	SELECT CUSTOMERNAME, RFM_Recency, RFM_Frequency, RFM_Monetary
		case --Case statement relates rfm values to a notation, so the related concatenated value equals a category of customer
			when rfm_cell_string in (111, 112, 121, 122, 123, 132, 211, 212, 114, 141) then 'Lost Customers' 
			when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'Close to Losing'
			when rfm_cell_string in (311, 411, 331) then 'New customers'
			when rfm_cell_string in (222, 223, 233, 322) then 'Potential Churn'
			when rfm_cell_string in (323, 333, 321, 422, 332, 432) then 'Active'
			when rfm_cell_string in (433, 434, 443, 444) then 'Loyal'
		end rfm_segment
	FROM #rfm

--What products are being sold together?

	SELECT ORDERNUMBER, COUNT(*) AS rn
	FROM SalesData.dbo.sales_data_sample
	WHERE STATUS = 'Shipped'
	GROUP BY ORDERNUMBER
    
--Base query, count of shipped orders
	SELECT ORDERNUMBER, STUFF(
	SELECT ',' + PRODUCTCODE --If there were two product codes in a single order (rn), append them in columns instead of rows (comma as delimiter)
	FROM dbo.sales_data_sample
	WHERE DISTINCT ORDERNUMBER in (
		SELECT ORDERNUMBER
		FROM (
		SELECT ORDERNUMBER, COUNT(*) AS rn
		FROM SalesData.dbo.sales_data_sample
		WHERE STATUS = 'Shipped'
		GROUP BY ORDERNUMBER
		) AS m
		WHERE rn = 2)
		AND p.ORDERNUMBER = s.ORDERNUMBER
		for xml path ('') --Appended
		, 1, 1, '') AS ProductCodes --Stuff, no of characters, starting with, and replacing with. Converted from xml to string
	FROM dbo.sales_data_sample AS s
	ORDER BY 2 DESC
--Reduced selection to orders with > 2 productcodes, then ordered by descending to show orders with the same codes to view orders frequently purchased together
--rn can be changed to further integers to show orders with > 2 etc
