create database sales_project;
use sales_project;

-- Total Sales by Country : Write a query to find the total sales for each country
select count(sales) as total_sales from sales_report
group by country;

-- Write a query to show the total sales for each month of the year 2019
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    SUM(sales) AS total_sales
FROM 
    sales_report
WHERE 
    order_date >= '2019-01-01' AND order_date < '2020-01-01'
GROUP BY 
    DATE_FORMAT(order_date, '%Y-%m')
ORDER BY 
    month;
    
    -- Write a query to calculate the average delivery time
    
    select 
      date_format(ship_date-order_date,'%Y-%m') as average_delivery_time
      from sales_report;
      
      -- Write a query to find the total sales for each segment in each region
      
      select count(sales) as total_sales from sales_report
      group by region,segment;

/* TOTAL SALES BY COUNTRY:
-Write a query to find the total sales for each country */
SELECT Country , Sum(sales) Total_Sales
FROM sales_report
GROUP BY Country
ORDER BY Total_Sales;

/* SALES BY SEGMENT AND REGION:
-Write a query to find the total sales for each segment in each region*/
SELECT Segment, Region, SUM(Sales) AS Total_Sales
FROM Sales_Report
GROUP BY Segment, Region
ORDER BY Segment, Region;

/* PRODUCTS WITH NO PROFIT:
Write a query to find all products where the profit is zero or negative */
SELECT Product_ID, Product_Name, Sales, 
	   Quantity, Discount, Profit
FROM sales_report
WHERE Profit <= 0;

/* TOP 10 CUSTOMERS BY SALES:
-Write a query to find the top 10 customers based on the total sales amount */
SELECT Customer_Name, SUM(Sales) AS Total_Sales
FROM Sales_Report
GROUP BY Customer_Name
ORDER BY Total_Sales DESC
LIMIT 10;

/* DISCOUNT IMPACT ON PROFIT: 
-Write a query to analyze the impact of different discount levels on the profit. 
Categorize the discounts into ranges (e.g., 0-10%, 10-20%, etc.) and show the total sales and profit for each range */
SELECT
    CASE 
        WHEN Discount BETWEEN 0 AND 0.1 THEN '0-10%'
        WHEN Discount BETWEEN 0.1 AND 0.2 THEN '10-20%'
        WHEN Discount BETWEEN 0.2 AND 0.3 THEN '20-30%'
        WHEN Discount BETWEEN 0.3 AND 0.4 THEN '30-40%'
        WHEN Discount BETWEEN 0.4 AND 0.5 THEN '40-50%'
		WHEN Discount BETWEEN 0.5 AND 0.6 THEN '50-60%'
        WHEN Discount BETWEEN 0.6 AND 0.7 THEN '60-70%'
        ELSE '70% and above'
    END AS Discount_Range,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Sales_Report
GROUP BY Discount_Range
ORDER BY Discount_Range;

/* ORDER FREQUENCY BY CUSTOMER SEGMENT:
-Write a query to calculate the average number of orders per customer for each segment */
SELECT Segment,
    AVG(Order_Count) AS Average_Orders_Per_Customer
FROM (
    SELECT Segment,Customer_ID, 
        COUNT(Order_ID) AS Order_Count
    FROM Sales_Report
    GROUP BY Segment, Customer_ID
) AS Customer_Order_Count
GROUP BY Segment
ORDER BY Segment;

/* CUSTOMER RETENTION ANALYSIS:
-Write a query to find customers who have placed more than one order and calculate the total sales for their first and last orders */
WITH CustomerOrders AS (
    SELECT 
        Customer_ID, Customer_Name, Order_ID, Order_Date, Sales,
        ROW_NUMBER() OVER (PARTITION BY Customer_ID ORDER BY Order_Date) AS OrderRankAsc,
        ROW_NUMBER() OVER (PARTITION BY Customer_ID ORDER BY Order_Date DESC) AS OrderRankDesc
    FROM Sales_Report
),
FirstAndLastOrders AS (
    SELECT Customer_ID, Customer_Name,
        MAX(CASE WHEN OrderRankAsc = 1 THEN Sales END) AS First_Order_Sales,
        MAX(CASE WHEN OrderRankDesc = 1 THEN Sales END) AS Last_Order_Sales
    FROM CustomerOrders
    GROUP BY Customer_ID, Customer_Name
),
MultiOrderCustomers AS (
    SELECT Customer_ID, Customer_Name
    FROM Sales_Report
    GROUP BY Customer_ID, Customer_Name
    HAVING COUNT(Order_ID) > 1
)
SELECT f.Customer_ID, f.Customer_Name, f.First_Order_Sales, f.Last_Order_Sales
FROM FirstAndLastOrders f
JOIN MultiOrderCustomers m ON f.Customer_ID = m.Customer_ID
ORDER BY f.Customer_Name;

/* PROFIT MARGIN BY SUB-CATEGORY:
-Write a query to calculate the profit margin (profit as a percentage of sales) for each sub-category */
SELECT Sub_Category,
    SUM(Profit) AS Total_Profit,
    SUM(Sales) AS Total_Sales,
	(SUM(Profit) / SUM(Sales)) * 100 AS Profit_Margin_Percentage
FROM Sales_Report
GROUP BY Sub_Category
ORDER BY Profit_Margin_Percentage DESC;

/* CUSTOMER SEGMENTATION USING RFM ANALYSIS:
-Write a query to perform RFM (Recency, Frequency, Monetary) analysis. 
-Categorize customers into different segments based on their purchase recency, frequency and monetary value */
WITH RFM_Calculation AS (
    SELECT Customer_ID, Customer_Name, 
           MAX(Order_Date) AS Last_Order_Date,
           DATEDIFF(CURDATE(), MAX(Order_Date)) AS Recency,
           COUNT(Order_ID) AS Frequency,
           SUM(Sales) AS Monetary
    FROM Sales_Report
    GROUP BY Customer_ID, Customer_Name
)
SELECT Customer_ID, Customer_Name, Recency, Frequency, Monetary,
       CASE 
           WHEN Recency <= 30 THEN 5
           WHEN Recency <= 60 THEN 4
           WHEN Recency <= 90 THEN 3
           WHEN Recency <= 180 THEN 2
           ELSE 1
       END AS Recency_Score,
       CASE 
           WHEN Frequency >= 10 THEN 5
           WHEN Frequency >= 7 THEN 4
           WHEN Frequency >= 5 THEN 3
           WHEN Frequency >= 3 THEN 2
           ELSE 1
       END AS Frequency_Score,
       CASE 
           WHEN Monetary >= 1000 THEN 5
           WHEN Monetary >= 750 THEN 4
           WHEN Monetary >= 500 THEN 3
           WHEN Monetary >= 250 THEN 2
           ELSE 1
       END AS Monetary_Score
FROM RFM_Calculation;

/* BASKET ANALYSIS FOR PRODUCT BUNDLING:
-Write a query to find pairs of products that are frequently bought together.
-List the top 10 product pairs with the highest cooccurrence in orders */
WITH ProductPairs AS (
    SELECT 
        a.Order_ID,
        a.Product_ID AS Product_A,
        b.Product_ID AS Product_B
    FROM Sales_Report a
    JOIN Sales_Report b ON a.Order_ID = b.Order_ID AND a.Product_ID < b.Product_ID
)
SELECT 
    Product_A, Product_B,
    COUNT(*) AS Cooccurrence_Count
FROM ProductPairs
GROUP BY Product_A, Product_B
ORDER BY Cooccurrence_Count DESC
LIMIT 10;

/* REVENUE IMPACT OF SHIPPING DELAYS:
-Write a query to analyze the impact of shipping delays on revenue. 
-Compare the average sales amount for orders shipped on Time vs Orders delayed by Product Performance by Discount Levels 
-Write a query to analyze product performance at different discount levels and visualize sales, profit, and quantity sold more than 3 days */
WITH Sales_Performance AS (
    SELECT 
        CASE 
            WHEN DATEDIFF(Ship_Date, Order_Date) <= 3 THEN 'On-Time'
            ELSE 'Delayed'
        END AS Shipping_Status,
        CASE 
            WHEN Discount BETWEEN 0 AND 0.1 THEN '0-10%'
            WHEN Discount BETWEEN 0.1 AND 0.2 THEN '10-20%'
            WHEN Discount BETWEEN 0.2 AND 0.3 THEN '20-30%'
            WHEN Discount BETWEEN 0.3 AND 0.4 THEN '30-40%'
            WHEN Discount BETWEEN 0.4 AND 0.5 THEN '40-50%'
            WHEN Discount BETWEEN 0.5 AND 0.6 THEN '50-60%'
            WHEN Discount BETWEEN 0.6 AND 0.7 THEN '60-70%'
            ELSE '70% and above'
        END AS Discount_Range,
        Sales, Profit, Quantity 
    FROM Sales_Report
)
SELECT 
    Shipping_Status, Discount_Range,
    AVG(Sales) AS Average_Sales,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    SUM(Quantity) AS Total_Quantity
FROM Sales_Performance
GROUP BY Shipping_Status, Discount_Range
ORDER BY Shipping_Status, Discount_Range;

/* TOP 10 PRODUCTS BY SALES AND PROFIT:
-Write a query to identify the top 10 products by sales and profit and visualize their performance */
WITH ProductPerformance AS (
    SELECT 
        Product_Name,
        SUM(Sales) AS Total_Sales,
        SUM(Profit) AS Total_Profit
    FROM Sales_Report
    GROUP BY Product_Name
)
SELECT 
    Product_Name, Total_Sales, Total_Profit
FROM ProductPerformance
ORDER BY Total_Sales DESC, Total_Profit DESC
LIMIT 10;

/* CUSTOMER PURCHASE FREQUENCY ANALYSIS:
-Write a query to categorize customers based on their purchase frequency (e.g., frequent, occasional, rare buyers) 
and analyze their contribution to total sales */
WITH CustomerPurchaseCounts AS (
    SELECT Customer_ID,
        COUNT(Order_ID) AS PurchaseCount,
        SUM(Sales) AS TotalSales
    FROM sales_report
    GROUP BY Customer_ID
),
CustomerCategories AS (
    SELECT Customer_ID, PurchaseCount, TotalSales,
        CASE
            WHEN PurchaseCount >= 10 THEN 'Frequent'
            WHEN PurchaseCount BETWEEN 5 AND 9 THEN 'Occasional'
            ELSE 'Rare'
        END AS PurchaseFrequency
    FROM
        CustomerPurchaseCounts
)
SELECT PurchaseFrequency,
    COUNT(Customer_ID) AS NumberOfCustomers,
    SUM(TotalSales) AS TotalSales
FROM CustomerCategories
GROUP BY PurchaseFrequency
ORDER BY TotalSales DESC;

/* PRODUCT RETURN RATE ANALYSIS:
-Write a query to analyze the return rate of products. 
-Identify products with high return rates and their impact on overall profit */
SELECT Product_ID, Product_Name, 
       COUNT(CASE WHEN Profit < 0 THEN 1 END) AS Return_Count, 
       COUNT(Order_ID) AS Total_Orders, 
       (COUNT(CASE WHEN Profit < 0 THEN 1 END) / COUNT(Order_ID)) * 100 AS Return_Rate
FROM Sales_Report
GROUP BY Product_ID, Product_Name
ORDER BY Return_Rate DESC;

/* PRODUCT LIFECYCLE ANALYSIS:
-Write a query to analyze the lifecycle of products from their introduction to their decline. 
-Identify products in each lifecycle stage */
WITH Product_Lifecycle AS (
    SELECT Product_ID, Product_Name,
           MIN(Order_Date) AS Introduction_Date,
           MAX(Order_Date) AS Last_Sale_Date,
           COUNT(Order_ID) AS Total_Orders,
           SUM(Sales) AS Total_Sales
    FROM Sales_Report
    GROUP BY Product_ID, Product_Name
)
SELECT Product_ID, Product_Name, Introduction_Date, Last_Sale_Date, Total_Orders, Total_Sales,
       CASE 
           WHEN Total_Orders <= 10 THEN 'Introduction'
           WHEN Total_Orders <= 50 THEN 'Growth'
           WHEN Total_Orders <= 100 THEN 'Maturity'
           ELSE 'Decline'
       END AS Lifecycle_Stage
FROM Product_Lifecycle;

/* CUSTOMER CHURN ANALYSIS BY SEGMENT AND REGION:
-Write a query to analyze customer churn rates by segment and region
-Identify segments and regions with the highest churn rates */
WITH Last_Order AS (
    SELECT Customer_ID, Customer_Name, Segment, Region, 
           MAX(Order_Date) AS Last_Order_Date
    FROM Sales_Report
    GROUP BY Customer_ID, Customer_Name, Segment, Region
)
SELECT Segment, Region, 
       COUNT(CASE WHEN Last_Order_Date < DATE_SUB(CURDATE(), INTERVAL 6 MONTH) THEN 1 END) AS Churned_Customers,
       COUNT(Customer_ID) AS Total_Customers,
       (COUNT(CASE WHEN Last_Order_Date < DATE_SUB(CURDATE(), INTERVAL 6 MONTH) THEN 1 END) / COUNT(Customer_ID)) * 100 AS Churn_Rate
FROM Last_Order
GROUP BY Segment, Region
ORDER BY Segment, Region;

/* TOP N% PRODUCTS BY SALES:
-Write a query to find the top N% of products that contribute to 80% of the total sales. 
Use the Pareto principle (80/20 rule) */

-- Step 1: Calculate the total sales
SELECT @total_sales := SUM(Sales) FROM Sales_Report;
 -- Step 2: Calculate cumulative sales percentage and find top products contributing to 80% of total sales
SELECT Product_ID, Product_Name, Sales
FROM (
    SELECT Product_ID, Product_Name, Sales,
        @running_total := @running_total + Sales AS Running_Total,
        (@running_total / @total_sales) * 100 AS Cumulative_Sales_Percentage
    FROM 
        (SELECT Product_ID, Product_Name, Sales 
         FROM Sales_Report 
         ORDER BY Sales DESC) AS sorted_products,
        (SELECT @running_total := 0) AS init
) AS cumulative_sales
WHERE Cumulative_Sales_Percentage <= 80;








