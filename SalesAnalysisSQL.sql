--Dataset: AdventureWorks sample databases
--Source: Microsoft https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver15&tabs=ssms
--Queried using: T-SQL

--Tables required for task: Customer, product, product category, internet sales, date, budget(external)
--(S) = Saved as CSV for use in Power BI

--TABLES:
--Cleaned DIMDate Table
SELECT
		 [DateKey]
--Alias names are label-friendly and ready for visualizations 
        ,[FullDateAlternateKey] AS Date
          --,[DayNumberOfWeek]
          --,[EnglishDayNameOfWeek]
          --,[SpanishDayNameOfWeek]
          --,[FrenchDayNameOfWeek]
          --,[DayNumberOfMonth]
          --,[DayNumberOfYear]
          --,[WeekNumberOfYear]
        ,[EnglishMonthName] AS Month
		,LEFT([EnglishMonthName], 3) AS MonthShort 
          --,[SpanishMonthName]
          --,[FrenchMonthName]
        ,[MonthNumberOfYear] AS MonthNo
        ,[CalendarQuarter] AS Quarter
        ,[CalendarYear] AS Year 
          --,[CalendarSemester]
          --,[FiscalQuarter]
          --,[FiscalYear]
          --,[FiscalSemester]
FROM 
	[AdventureWorksDW2022].[dbo].[DimDate]
WHERE
	CalendarYear >= 2019;

--(S)

--Cleaned DIMCustomer Table
SELECT 
	c.customerKey AS CKey,
		  --,[GeographyKey]
		  --,[CustomerAlternateKey]
		  --,[Title]
    c.firstname AS [First Name],
		  --,[MiddleName]
    c.lastname AS [Last Name],
	c.firstname + ' ' + lastname AS [Full Name],
--Combined first and last name
		  --,[NameStyle]
		  --,[BirthDate]
		  --,[MaritalStatus]
		  --,[Suffix]
    CASE c.gender WHEN 'M' THEN 'Male' WHEN 'F' THEN 'Female' END AS Gender,
--Original gender column used M or F only. CASE statement allows for full text
		  --,[EmailAddress]
		  --,[YearlyIncome]
		  --,[TotalChildren]
		  --,[NumberChildrenAtHome]
		  --,[EnglishEducation]
		  --,[SpanishEducation]
		  --,[FrenchEducation]
		  --,[EnglishOccupation]
		  --,[SpanishOccupation]
		  --,[FrenchOccupation]
		  --,[HouseOwnerFlag]
		  --,[NumberCarsOwned]
		  --,[AddressLine1]
		  --,[AddressLine2]
		  --,[Phone]
     c.datefirstpurchase AS [Date of First Purchase],
		  --,[CommuteDistance]
	 g.city AS [Customer City] 
  FROM [AdventureWorksDW2022].[dbo].[DimCustomer] AS c --Alias for ease
 
  LEFT JOIN AdventureWorksDW2022.dbo.DimGeography AS g 
	ON g.geographykey = c.geographykey
--Basic table join to primary key / Joined Customer City from Geography table (geographic visualizations)
ORDER BY
	CustomerKey ASC;
-- Order list by customer key ascending

-(S)

--Cleaned DIM_Products Table - columns selected specifically for request in relation to product(variables) sales
SELECT
	p.[ProductKey],
	p.[ProductAlternateKey] AS [Product Item Code],
		  --,[ProductSubcategoryKey]
		  --,[WeightUnitMeasureCode]
		  --,[SizeUnitMeasureCode]
	p.[EnglishProductName] AS [Product Name],
	ps.EnglishProductSubcategoryName AS [Sub Category], -- JOIN Sub Category table
	pc.EnglishProductCategoryName AS [Product Category], --JOIN from Category table
		  --,[SpanishProductName]
		  --,[FrenchProductName]
	      --,[StandardCost]
	      --,[FinishedGoodsFlag]
	p.[Color] AS [Product Color], 
--Product aliases added to allow detailed statistics in visualizations
		  --,[SafetyStockLevel]
		  --,[ReorderPoint]
		  --,[ListPrice]
	p.[Size] AS [Product Size],
		  --,[SizeRange]
		  --,[Weight]
		  --,[DaysToManufacture]
	p.[ProductLine] AS [Product Line],
		  --,[DealerPrice]
		  --,[Class]
		  --,[Style]
	p.[ModelName] AS [Product Model Name],
          --,[LargePhoto]
	p.[EnglishDescription] AS [Product Description],
		  --,[FrenchDescription]
		  --,[ChineseDescription]
		  --,[ArabicDescription]
		  --,[HebrewDescription]
		  --,[ThaiDescription]
		  --,[GermanDescription]
		  --,[JapaneseDescription]
		  --,[TurkishDescription]
		  --,[StartDate]
		  --,[EndDate]
--Previous 'status' option was only current or NULL. Understood that if status was NOT current then it must be 'Outdated'
	ISNULL (p.Status, 'Outdated') AS [Product Status]
FROM [AdventureWorksDW2022].[dbo].[DimProduct] AS p
	LEFT JOIN [AdventureWorksDW2022].[dbo].[DimProductSubcategory] AS ps ON ps.ProductSubcategoryKey = p.ProductSubcategoryKey
	LEFT JOIN [AdventureWorksDW2022].[dbo].[DimProductCategory] AS pc ON ps.ProductCategoryKey = pc.ProductCategoryKey
--JOIN subcategory and category tables and apply aliases
ORDER BY
	p.ProductKey ASC;

-(S)

--Cleaned FACT_InternetSales Table
SELECT
	   [ProductKey]
      ,[OrderDateKey]
      ,[DueDateKey]
      ,[ShipDateKey]
      ,[CustomerKey]
		  --,[PromotionKey]
		  --,[CurrencyKey]
		  --,[SalesTerritoryKey]
      ,[SalesOrderNumber]
		  --,[SalesOrderLineNumber]
		  --,[RevisionNumber]
		  --,[OrderQuantity]
		  --,[UnitPrice]
		  --,[ExtendedAmount]
		  --,[UnitPriceDiscountPct]
		  --,[DiscountAmount]
		  --,[ProductStandardCost]
		  --,[TotalProductCost]
      ,[SalesAmount]
      --,[TaxAmt]
      --,[Freight]
      --,[CarrierTrackingNumber]
      --,[CustomerPONumber]
      --,[OrderDate]
      --,[DueDate]
      --,[ShipDate]
  FROM [AdventureWorksDW2022].[dbo].[FactInternetSales]
  WHERE
	LEFT (OrderDateKey, 4) >= YEAR(GETDATE()) -2 
--Transform date into YEAR value to get the appropriate date for the task (2021 onwards) 
ORDER BY
	OrderDateKey ASC;

-(S)
