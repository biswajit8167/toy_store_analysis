create database toystore_sales;
use toy_store_sales;


---Monthly wise sales trend over the stores, location for both year(2022 & 2023)--


SELECT 
    YEAR(s.Date) AS Year,
    MONTH(s.Date) AS Month,
    st.Store_Name,
    st.Store_City,
    st.Store_Location,
    SUM(s.Units) AS Total_Units_Sold,
    SUM(s.Units * p.Product_Price) AS Total_Revenue
FROM 
    Sales s
JOIN 
    Stores st ON s.Store_ID = st.Store_ID
JOIN 
    Products p ON s.Product_ID = p.Product_ID
WHERE 
    YEAR(s.Date) IN (2022, 2023)  
GROUP BY 
    YEAR(s.Date),
    MONTH(s.Date),
    st.Store_Name,
    st.Store_City,
    st.Store_Location
ORDER BY 
    Year,
    Month,
    st.Store_Name;



---2.Create a comparison of Monthly sales, Quarterly sales between 2022 and 2023 sales


	---Monthly Sales Comparison (Grouped and Ordered by Month and Store Name)
	SELECT 
    MONTH(s.Date) AS Month,  -- SQL Server supports MONTH()
    st.Store_Name,
    st.Store_City,
    st.Store_Location,
    -- Sales for 2022
    SUM(CASE WHEN YEAR(s.Date) = 2022 THEN s.Units * p.Product_Price ELSE 0 END) AS Sales_2022,
    -- Sales for 2023
    SUM(CASE WHEN YEAR(s.Date) = 2023 THEN s.Units * p.Product_Price ELSE 0 END) AS Sales_2023
FROM 
    Sales s
JOIN 
    Stores st ON s.Store_ID = st.Store_ID
JOIN 
    Products p ON s.Product_ID = p.Product_ID
WHERE 
    YEAR(s.Date) IN (2022, 2023)  -- Filter for 2022 and 2023
GROUP BY 
    MONTH(s.Date),
    st.Store_Name,
    st.Store_City,
    st.Store_Location
ORDER BY 
    MONTH(s.Date),               -- Order by month
    st.Store_Name;               -- Order by store name



	-----Quarterly Sales Comparison (Grouped and Ordered by Quarter and Store Name)
	SELECT 
    DATEPART(QUARTER, s.Date) AS Quarter,  -- Using DATEPART to extract the quarter
    st.Store_Name,
    st.Store_City,
    st.Store_Location,
    -- Sales for 2022
    SUM(CASE WHEN YEAR(s.Date) = 2022 THEN s.Units * p.Product_Price ELSE 0 END) AS Sales_2022,
    -- Sales for 2023
    SUM(CASE WHEN YEAR(s.Date) = 2023 THEN s.Units * p.Product_Price ELSE 0 END) AS Sales_2023
FROM 
    Sales s
JOIN 
    Stores st ON s.Store_ID = st.Store_ID
JOIN 
    Products p ON s.Product_ID = p.Product_ID
WHERE 
    YEAR(s.Date) IN (2022, 2023)  -- Filter for 2022 and 2023
GROUP BY 
    DATEPART(QUARTER, s.Date),  -- Group by quarter using DATEPART
    st.Store_Name,
    st.Store_City,
    st.Store_Location
ORDER BY 
    DATEPART(QUARTER, s.Date),   -- Order by quarter
    st.Store_Name;               -- Order by store name



----a.	Find the sales trend over the different Stores and find the best and least five stores as per the performance in one query.--

	WITH StoreSales AS (
    SELECT 
        st.Store_ID,
        st.Store_Name,
        st.Store_City,
        st.Store_Location,
        SUM(s.Units * p.Product_Price) AS Total_Sales  -- Calculate total sales for each store
    FROM 
        Sales s
    JOIN 
        Stores st ON s.Store_ID = st.Store_ID
    JOIN 
        Products p ON s.Product_ID = p.Product_ID
    GROUP BY 
        st.Store_ID, 
        st.Store_Name,
        st.Store_City,
        st.Store_Location
),
RankedStores AS (
    SELECT 
        Store_ID,
        Store_Name,
        Store_City,
        Store_Location,
        Total_Sales,
        RANK() OVER (ORDER BY Total_Sales DESC) AS Sales_Rank, -- Rank stores based on sales
        RANK() OVER (ORDER BY Total_Sales ASC) AS Sales_Rank_Asc -- Rank stores for least sales
    FROM 
        StoreSales
)
SELECT 
    Store_ID,
    Store_Name,
    Store_City,
    Store_Location,
    Total_Sales,
    CASE 
        WHEN Sales_Rank <= 5 THEN 'Top 5' 
        WHEN Sales_Rank_Asc <= 5 THEN 'Bottom 5' 
        ELSE 'Other' 
    END AS Store_Performance
FROM 
    RankedStores
WHERE 
    Sales_Rank <= 5 OR Sales_Rank_Asc <= 5  -- Filter for top 5 and bottom 5
ORDER BY 
    Total_Sales DESC;  -- Sort by total sales for better readability



---b.	Which stores performs well than the last year ----

	WITH YearlySales AS (
    SELECT 
        st.Store_ID,
        st.Store_Name,
        st.Store_City,
        st.Store_Location,
        YEAR(s.Date) AS Year,
        SUM(s.Units * p.Product_Price) AS Total_Sales  -- Calculate total sales per year per store
    FROM 
        Sales s
    JOIN 
        Stores st ON s.Store_ID = st.Store_ID
    JOIN 
        Products p ON s.Product_ID = p.Product_ID
    WHERE 
        YEAR(s.Date) IN (2022, 2023)  -- Focus on 2022 and 2023
    GROUP BY 
        st.Store_ID,
        st.Store_Name,
        st.Store_City,
        st.Store_Location,
        YEAR(s.Date)
),
SalesComparison AS (
    SELECT 
        ys2023.Store_ID,
        ys2023.Store_Name,
        ys2023.Store_City,
        ys2023.Store_Location,
        ys2023.Total_Sales AS Sales_2023,
        COALESCE(ys2022.Total_Sales, 0) AS Sales_2022, -- Handle cases where a store didn't exist in 2022
        ys2023.Total_Sales - COALESCE(ys2022.Total_Sales, 0) AS Sales_Change -- Calculate sales difference
    FROM 
        YearlySales ys2023
    LEFT JOIN 
        YearlySales ys2022
        ON ys2023.Store_ID = ys2022.Store_ID AND ys2022.Year = 2022
    WHERE 
        ys2023.Year = 2023
)
SELECT 
    Store_ID,
    Store_Name,
    Store_City,
    Store_Location,
    Sales_2022,
    Sales_2023,
    Sales_Change
FROM 
    SalesComparison
WHERE 
    Sales_Change > 0  -- Filter stores with positive sales growth
ORDER BY 
    Sales_Change DESC; -- Order by greatest improvement



---a.	Find out the report of Product that which product performs well and contributing most part of sales--

	WITH ProductSales AS (
    SELECT 
        p.Product_ID,
        p.Product_Name,
        p.Product_Category,
        SUM(s.Units * p.Product_Price) AS Total_Sales  -- Total sales for each product
    FROM 
        Sales s
    JOIN 
        Products p ON s.Product_ID = p.Product_ID
    GROUP BY 
        p.Product_ID, 
        p.Product_Name, 
        p.Product_Category
),
TotalSales AS (
    SELECT 
        SUM(Total_Sales) AS Overall_Sales  -- Calculate overall sales across all products
    FROM 
        ProductSales
),
ProductContribution AS (
    SELECT 
        ps.Product_ID,
        ps.Product_Name,
        ps.Product_Category,
        ps.Total_Sales,
        (ps.Total_Sales / ts.Overall_Sales) * 100 AS Contribution_Percentage -- Calculate contribution
    FROM 
        ProductSales ps
    CROSS JOIN 
        TotalSales ts
)
SELECT 
    Product_ID,
    Product_Name,
    Product_Category,
    Total_Sales,
    Contribution_Percentage
FROM 
    ProductContribution
ORDER BY 
    Total_Sales DESC;  -- Order by sales to see top-performing products first


---b.	Is there any seasonality between the last three half yearly sales counted with the max(date) of sales.---
	WITH MaxDate AS (
    SELECT 
        MAX(Date) AS Max_Sales_Date -- Find the latest sales date
    FROM 
        Sales
),
HalfYearPeriods AS (
    SELECT 
        s.Sale_ID,
        s.Store_ID,
        s.Product_ID,
        s.Units,
        
        s.Date,
        -- Calculate the half-year period relative to the Max_Sales_Date
        CASE 
            WHEN MONTH(s.Date) BETWEEN 1 AND 6 THEN CONCAT(YEAR(s.Date), '-H1') -- Jan-Jun
            WHEN MONTH(s.Date) BETWEEN 7 AND 12 THEN CONCAT(YEAR(s.Date), '-H2') -- Jul-Dec
        END AS Half_Year
    FROM 
        Sales s
    CROSS JOIN 
        MaxDate md
    WHERE 
        s.Date >= DATEADD(YEAR, -2, md.Max_Sales_Date)  -- Consider last three half-years
),
HalfYearlySales AS (
    SELECT 
        Half_Year,
        SUM(s.Units * p.Product_Price) AS Total_Sales -- Aggregate sales for each half-year
    FROM 
        HalfYearPeriods s
    JOIN 
        Products p ON s.Product_ID = p.Product_ID
    GROUP BY 
        Half_Year
),
RankedSales AS (
    SELECT 
        Half_Year,
        Total_Sales,
        RANK() OVER (ORDER BY Total_Sales desc) AS Sales_Rank -- Rank the sales for comparison
    FROM 
        HalfYearlySales
)
SELECT 
    Half_Year,
    Total_Sales,
    Sales_Rank
FROM 
    RankedSales
ORDER BY 
    Half_Year; -- Sort chronologically for trend analysis


---c.	High demanded product among all locations as per the sales.---
	WITH ProductDemand AS (
    SELECT 
        p.Product_ID,
        p.Product_Name,
        p.Product_Category,
        SUM(s.Units) AS Total_Units_Sold, -- Total units sold for each product
        SUM(s.Units * p.Product_Price) AS Total_Sales -- Total sales for reference
    FROM 
        Sales s
    JOIN 
        Products p ON s.Product_ID = p.Product_ID
    GROUP BY 
        p.Product_ID, 
        p.Product_Name, 
        p.Product_Category
),
RankedProducts AS (
    SELECT 
        Product_ID,
        Product_Name,
        Product_Category,
        Total_Units_Sold,
        Total_Sales,
        RANK() OVER (ORDER BY Total_Units_Sold DESC) AS Demand_Rank -- Rank products by units sold
    FROM 
        ProductDemand
)
SELECT 
    Product_ID,
    Product_Name,
    Product_Category,
    Total_Units_Sold,
    Total_Sales
FROM 
    RankedProducts
WHERE 
    Demand_Rank = 1; -- Select the top-ranked product



---a.	Find out the avg_inventory as per the store and product.--

SELECT 
    i.Store_ID,
    s.Store_Name,
    s.Store_City,
    i.Product_ID,
    p.Product_Name,
    p.Product_Category,
    AVG(i.Stock_On_Hand) AS Avg_Inventory  -- Calculate average inventory
FROM 
    Inventory i
JOIN 
    Stores s ON i.Store_ID = s.Store_ID
JOIN 
    Products p ON i.Product_ID = p.Product_ID
GROUP BY 
    i.Store_ID, 
    s.Store_Name, 
    s.Store_City, 
    i.Product_ID, 
    p.Product_Name, 
    p.Product_Category
ORDER BY 
    i.Store_ID, 
    i.Product_ID;  -- Sort by Store and Product for clarity




----b.	Analyze the Inventory turnover ratio as per the store wise along with avg_inventory in a comparative report ---
	WITH AvgInventory AS (
    SELECT 
        i.Store_ID,
        s.Store_Name,
        s.Store_City,
        AVG(i.Stock_On_Hand) AS Avg_Inventory  -- Calculate average inventory
    FROM 
        Inventory i
    JOIN 
        Stores s ON i.Store_ID = s.Store_ID
    GROUP BY 
        i.Store_ID, 
        s.Store_Name, 
        s.Store_City
),
StoreCOGS AS (
    SELECT 
        s.Store_ID,
        s.Store_Name,
        s.Store_City,
        SUM(p.Product_Cost * sa.Units) AS Total_COGS  -- Calculate COGS (Units Sold * Product Cost)
    FROM 
        Sales sa
    JOIN 
        Products p ON sa.Product_ID = p.Product_ID
    JOIN 
        Stores s ON sa.Store_ID = s.Store_ID
    GROUP BY 
        s.Store_ID, 
        s.Store_Name, 
        s.Store_City
)
SELECT 
    a.Store_ID,
    a.Store_Name,
    a.Store_City,
    a.Avg_Inventory,
    c.Total_COGS,
    ROUND(CASE 
        WHEN a.Avg_Inventory > 0 THEN c.Total_COGS / a.Avg_Inventory -- Calculate ITR
        ELSE 0
    END, 2) AS Inventory_Turnover_Ratio
FROM 
    AvgInventory a
JOIN 
    StoreCOGS c ON a.Store_ID = c.Store_ID
ORDER BY 
    Inventory_Turnover_Ratio DESC;  -- Order by ITR for a comparative report
