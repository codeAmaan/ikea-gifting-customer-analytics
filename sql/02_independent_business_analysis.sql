-- =========================================
-- INDEPENDENT SQL EXTENSION 1
-- Repeat vs One-Time Customer Analysis
-- =========================================
-- Question 1: Repeat Customer vs One-Time Customer Analysis

WITH CustomerNewData AS
(
    SELECT
        Customer_ID,
        COUNT(DISTINCT Invoice) AS Total_Orders,
        SUM(Quantity * Price) AS Total_Revenue,
        CASE
            WHEN COUNT(DISTINCT Invoice) > 1 THEN 'repeat_customer'
            WHEN COUNT(DISTINCT Invoice) = 1 THEN 'one_time_customer'
        END AS Customer_Classification
    FROM dbo.RetailCleaned
    WHERE Customer_ID IS NOT NULL
      AND Quantity > 0
    GROUP BY Customer_ID
),
CustomerSummary AS
(
    SELECT
        Customer_Classification,
        COUNT(Customer_ID) AS Total_Customers,
        SUM(Total_Orders) AS Total_Orders,
        SUM(Total_Revenue) AS Revenue,
        SUM(Total_Revenue) * 1.0 / SUM(Total_Orders) AS AOV,
        SUM(Total_Orders) * 1.0 / COUNT(Customer_ID) AS Avg_Orders_Per_Customer
    FROM CustomerNewData
    GROUP BY Customer_Classification
)
SELECT
    Customer_Classification,
    Total_Customers,
    Total_Orders,
    Revenue,
    ROUND(Revenue * 100.0 / SUM(Revenue) OVER(), 2) AS Revenue_Contribution_Pct,
    ROUND(AOV, 2) AS AOV,
    ROUND(Avg_Orders_Per_Customer, 2) AS Avg_Orders_Per_Customer
FROM CustomerSummary;


-- =========================================
-- INDEPENDENT SQL EXTENSION 2
-- Top 10 Product Revenue Concentration
-- =========================================
-- Question- 2  Top Products Revenue Concentration
WITH ProductRevenue AS
(
    SELECT
        StockCode,
        Description,
        SUM(Quantity * Price) AS Revenue
    FROM dbo.RetailCleaned
    WHERE Customer_ID IS NOT NULL
      AND Quantity > 0
      AND StockCode NOT IN ('M', 'POST')
    GROUP BY StockCode, Description
),
Top10Revenue AS
(
    SELECT TOP 10
        StockCode,
        Description,
        Revenue
    FROM ProductRevenue
    ORDER BY Revenue DESC
),
RevenueSummary AS
(
    SELECT 
        (SELECT SUM(Revenue) FROM Top10Revenue) AS Top10_Combined_Revenue,
        (SELECT SUM(Revenue) FROM ProductRevenue) AS Total_Product_Revenue
)
SELECT
    Top10_Combined_Revenue,
    Total_Product_Revenue,
    ROUND(
        Top10_Combined_Revenue * 100.0 / Total_Product_Revenue, 2
    ) AS Top_10_Revenue_Contribution
    FROM RevenueSummary;


-- Q2A: Top 10 Products List

WITH ProductRevenue AS
(
    SELECT
        StockCode,
        Description,
        SUM(Quantity * Price) AS Revenue
    FROM dbo.RetailCleaned
    WHERE Customer_ID IS NOT NULL
      AND Quantity > 0
      AND StockCode NOT IN ('M', 'POST')
    GROUP BY StockCode, Description
)
SELECT TOP 10
    StockCode,
    Description,
    Revenue
FROM ProductRevenue
ORDER BY Revenue DESC;