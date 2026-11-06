/*
Customer Analytics & RFM Segmentation
SQL Server data preparation

Workflow:
1. Check the imported year-wise tables.
2. Combine both years and convert InvoiceDate and Price.
3. Validate the combined table.
4. Check data quality and exact duplicates.
5. Create the final deduplicated table.

Note:
- This script follows the tutorial-guided workflow used in the project.
- The SELECT INTO statements create new tables. Run this script in a database
  where dbo.RetailCombined and dbo.RetailCleaned do not already exist.
- The final CSV export is performed separately through SQL Server/SSMS.
*/

-- 1. Check row counts after import
SELECT COUNT(*) AS Rows_2009_2010
FROM dbo.[Year 2009-2010];

SELECT COUNT(*) AS Rows_2010_2011
FROM dbo.[Year 2010-2011];


-- 2. Combine both years and convert data types safely
SELECT
    Invoice,
    StockCode,
    Description,
    Quantity,
    COALESCE(
        TRY_CONVERT(datetime2, InvoiceDate, 120),
        TRY_CONVERT(datetime2, InvoiceDate, 105)
    ) AS InvoiceDate,
    TRY_CONVERT(decimal(10,2), Price) AS Price,
    Customer_ID,
    Country,
    '2009-2010' AS SourceSheet
INTO dbo.RetailCombined
FROM dbo.[Year 2009-2010]

UNION ALL

SELECT
    Invoice,
    StockCode,
    Description,
    Quantity,
    COALESCE(
        TRY_CONVERT(datetime2, InvoiceDate, 120),
        TRY_CONVERT(datetime2, InvoiceDate, 105)
    ) AS InvoiceDate,
    TRY_CONVERT(decimal(10,2), Price) AS Price,
    Customer_ID,
    Country,
    '2010-2011' AS SourceSheet
FROM dbo.[Year 2010-2011];


-- 3. Confirm the conversion worked
SELECT COUNT(*) AS Total_Rows
FROM dbo.RetailCombined;

SELECT COUNT(*) AS Failed_Dates
FROM dbo.RetailCombined
WHERE InvoiceDate IS NULL;

SELECT COUNT(*) AS Failed_Prices
FROM dbo.RetailCombined
WHERE Price IS NULL;


-- 4. Data quality checks

-- Check 1: Missing Customer ID
SELECT COUNT(*) AS Missing_CustomerID
FROM dbo.RetailCombined
WHERE Customer_ID IS NULL;

-- Check 2: Negative or zero Quantity
SELECT COUNT(*) AS Negative_Qty
FROM dbo.RetailCombined
WHERE Quantity <= 0;

-- Check 3: Missing Description
SELECT COUNT(*) AS Missing_Description
FROM dbo.RetailCombined
WHERE Description IS NULL;

-- Check 4: Exact duplicate rows
SELECT
    Invoice,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    Price,
    Customer_ID,
    Country,
    COUNT(*) AS ExactDupCount
FROM dbo.RetailCombined
GROUP BY
    Invoice,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    Price,
    Customer_ID,
    Country
HAVING COUNT(*) > 1;


-- 5. Deduplicate and create the final cleaned table
;WITH Deduped AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                Invoice,
                StockCode,
                Description,
                Quantity,
                InvoiceDate,
                Price,
                Customer_ID,
                Country
            ORDER BY (SELECT NULL)
        ) AS RowNum
    FROM dbo.RetailCombined
)
SELECT
    Invoice,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    Price,
    Customer_ID,
    Country,
    SourceSheet
INTO dbo.RetailCleaned
FROM Deduped
WHERE RowNum = 1;


-- 6. Preview the cleaned table
SELECT *
FROM dbo.RetailCleaned;

-- Export dbo.RetailCleaned to CSV separately using the SSMS export workflow.
