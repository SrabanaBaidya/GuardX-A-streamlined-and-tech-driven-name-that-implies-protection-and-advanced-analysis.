Create Database market_abuse ;

-- Easy

-- 1.Find the Total Transaction Value for Each Stock in the surveillance Data.

SELECT Stock_ID , ROUND(sum(Transaction_Price*Volume),2) AS total_transaction_value 
FROM surveillance_optimization 
GROUP BY Stock_ID 
LIMIT 5 ; 

-- 2.Identify the top three manipulated Stocks with the Highest Average Order Price.

  SELECT Stock_Name , ROUND(Avg(Order_Price),2) As Highest_avg_order_price
  FROM market_manipulation
  GROUP BY Stock_Name
  ORDER BY Highest_avg_order_price DESC
  LIMIT 3 ;


-- 3.Find the Top five Enquiry_Type and the users who requested it.

WITH cte as (
     SELECT User_ID ,Enquiry_Type , COUNT(*) As  Enquiry_count
     FROM regulatory_enquiries
     GROUP BY  User_ID ,Enquiry_Type )
     
SELECT User_ID, Enquiry_Type, Enquiry_count
FROM cte 
ORDER BY Enquiry_count DESC
LIMIT 5 ;

-- Using Subquery 

SELECT User_ID, Enquiry_Type, Enquiry_count
FROM  (SELECT User_ID ,Enquiry_Type , COUNT(*) As  Enquiry_count
     FROM regulatory_enquiries
     GROUP BY  User_ID ,Enquiry_Type ) AS subquery 
ORDER BY Enquiry_count DESC
LIMIT 5 ;


-- 4.Find Users Who Made More Than one Regulatory Enquiries in a single month.

SELECT User_ID, YEAR(Enquiry_Date) AS Year, 
       MONTHNAME(Enquiry_Date) AS Month , COUNT(*) AS Enquiry_count
FROM regulatory_enquiries
GROUP BY  User_ID,YEAR(Enquiry_Date), 
          MONTHNAME(Enquiry_Date)     
HAVING COUNT(*) > 1 ;         

/*5.Determine the top 3 Most Common market manipulation Type and Its Average Price for Each Stock.*/

WITH CommonOrderType AS (SELECT Order_Price,Stock_Name, Manipulation_Type, COUNT(*) AS manipulation_Type_Count,
ROW_NUMBER() OVER (PARTITION BY Stock_Name ORDER BY COUNT(*) DESC) AS RowNum
FROM market_manipulation
GROUP BY Stock_Name, Manipulation_Type,Order_Price)

SELECT Manipulation_Type, ROUND(AVG(Order_Price),2)AS Avg_Price
FROM CommonOrderType
WHERE RowNum = 1
GROUP BY Manipulation_Type
ORDER BY Avg_Price DESC
LIMIT 3;
 
-- 6. Find the total volume of orders for each stock with a corresponding regulatory enquiry*/

SELECT m.Stock_Name, SUM(m.Order_Volume) AS total_order
FROM market_manipulation AS m
INNER JOIN regulatory_enquiries AS r USING(Stock_ID)
GROUP BY m.Stock_Name
ORDER BY total_order DESC ;


-- Intermediate

-- 7. Give a count of the different Price Ranges for Each Stock

SELECT Stock_Name,
CASE WHEN Order_Price < 50 THEN '0-50'
WHEN Order_Price BETWEEN 50 AND 100 THEN '50-100'
ELSE '100+' END AS Price_Range,
COUNT(*) AS Range_Count
FROM market_manipulation
GROUP BY Stock_Name, Price_Range
ORDER BY Stock_Name, Range_Count DESC;


/*8.Detect users who have experienced more than three significant fluctuations in enquiry prices. A significant
 fluctuation is defined as a change in price that exceeds 10 units compared to the previous enquiry price.*/
 
SELECT User_ID, COUNT(*) AS Fluctuation_Count
FROM (SELECT User_ID, Enquiry_Price, 
LAG(Enquiry_Price) OVER (PARTITION BY User_ID ORDER BY Enquiry_Date) AS Prev_Enquiry_Price
FROM regulatory_enquiries
) AS PriceDiffs
WHERE ABS(Enquiry_Price - Prev_Enquiry_Price) > 10
GROUP BY User_ID
HAVING COUNT(*) > 3;
 
 /*9.Write a query to find the top 5 entities with the highest average order volume, excluding any extreme values.
 Calculate the average order volume for each entity, rounding the result to two decimal places.*/
 
 WITH Stats AS (SELECT Stock_Name, 
AVG(Order_Volume) AS Avg_Volume, 
STDDEV(Order_Volume) AS StdDev_Volume
FROM market_manipulation
GROUP BY Stock_Name)
 
SELECT mm.Stock_Name, ROUND(AVG(mm.Order_Volume),2) AS Avg_Order_Volume_Excluding_Outliers
FROM market_manipulation AS mm
JOIN Stats AS s ON mm.Stock_Name = s.Stock_Name
WHERE mm.Order_Volume BETWEEN s.Avg_Volume - 2 * s.StdDev_Volume 
AND s.Avg_Volume + 2 * s.StdDev_Volume
GROUP BY mm.Stock_Name
ORDER BY Avg_Order_Volume_Excluding_Outliers DESC
LIMIT 5;

 -- 10.Find Stocks with a Price Drop of More Than 90% Compared to the Previous Transaction.
 
 SELECT Transaction_ID, Stock_Name, Transaction_Price, Prev_Price
FROM (SELECT Transaction_ID, Stock_Name, Transaction_Price,
LAG(Transaction_Price) OVER (PARTITION BY Stock_Name ORDER BY Transaction_Date) AS Prev_Price
FROM surveillance_optimization) AS Subquery

WHERE Prev_Price IS NOT NULL 
AND (Transaction_Price / Prev_Price) < 0.1;
 
 
 
 -- 11.Retrieve Orders with Manipulated Prices Higher Than the Average Manipulated Price for Each Stock.
 
 SELECT Stock_Name, Order_Price
FROM market_manipulation AS mm
WHERE Order_Price >
(SELECT AVG(Order_Price)FROM market_manipulation WHERE Stock_Name = mm.Stock_Name);
 
 
 

-- 12.Determine the top 3 Most Common market manipulation Type and Its Average Price for Each Stock*/

WITH CommonOrderType AS (SELECT Order_Price,Stock_Name, Manipulation_Type, COUNT(*) AS manipulation_Type_Count,
ROW_NUMBER() OVER (PARTITION BY Stock_Name ORDER BY COUNT(*) DESC) AS RowNum
FROM market_manipulation
GROUP BY Stock_Name, Manipulation_Type,Order_Price)

SELECT Manipulation_Type, ROUND(AVG(Order_Price),2)AS Avg_Price
FROM CommonOrderType
WHERE RowNum = 1
GROUP BY Manipulation_Type
ORDER BY Avg_Price DESC
LIMIT 3;
