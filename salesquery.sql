select * from sales;
select distinct status from sales;
select distinct year_id from sales;
select distinct PRODUCTLINE from sales;
select distinct COUNTRY from sales;
select distinct CITY from sales;
select distinct DEALSIZE from sales;
select distinct TERRITORY from sales;
select distinct ORDERDATE from sales;
select distinct MONTH_ID  from sales where YEAR_ID=2005;

SET SQL_SAFE_UPDATES = 0;

UPDATE sales
SET ORDERDATE = STR_TO_DATE(ORDERDATE, '%m/%d/%Y %H:%i');


select PRODUCTLINE , sum(sales) Revenue 
from sales
group by PRODUCTLINE
order by 2 desc;

select YEAR_ID , sum(sales) Revenue 
from sales
group by YEAR_ID
order by 2 desc;

select DEALSIZE , sum(sales) Revenue 
from sales
group by DEALSIZE
order by 2 desc;

select MONTH_ID , sum(sales) Revenue  , count(ORDERNUMBER) Frequency
from sales where YEAR_ID=2004
group by MONTH_ID
order by 2 desc;

select MONTH_ID , PRODUCTLINE , sum(sales) Revenue  , count(ORDERNUMBER) Frequency
from sales where YEAR_ID=2004 and MONTH_ID=11
group by MONTH_ID , PRODUCTLINE
order by 3 desc;

DROP TEMPORARY TABLE IF EXISTS temp_rfm;

CREATE TEMPORARY TABLE temp_rfm AS
WITH rfm AS (
    SELECT 
        CUSTOMERNAME, 
        SUM(sales) AS MonetaryValue,
        AVG(sales) AS AvgMonetaryValue, 
        COUNT(ORDERNUMBER) AS Frequency,
        MAX(ORDERDATE) AS last_order_date,
        (SELECT MAX(ORDERDATE) FROM sales) AS max_order_date,
        DATEDIFF((SELECT MAX(ORDERDATE) FROM sales), MAX(ORDERDATE)) AS Recency
    FROM sales 
    GROUP BY CUSTOMERNAME
),
rfm_calc AS (
    SELECT 
        r.*,
        NTILE(4) OVER (ORDER BY Recency DESC) AS rfm_recency,
        NTILE(4) OVER (ORDER BY Frequency) AS rfm_frequency,
        NTILE(4) OVER (ORDER BY MonetaryValue) AS rfm_monetary
    FROM rfm r
)
SELECT 
    c.*, 
    rfm_recency + rfm_frequency + rfm_monetary AS rfm_cell,
    CONCAT(CAST(rfm_recency AS CHAR), CAST(rfm_frequency AS CHAR), CAST(rfm_monetary AS CHAR)) AS rfm_cell_string
FROM rfm_calc c;


SELECT 
    CUSTOMERNAME, 
    rfm_recency, 
    rfm_frequency, 
    rfm_monetary,
    CASE 
        WHEN rfm_cell_string IN ('111', '112', '121', '122', '123', '132', '211', '212', '114', '141') THEN 'lost_customers'  
        WHEN rfm_cell_string IN ('133', '134', '143', '244', '334', '343', '344', '144') THEN 'slipping away, cannot lose' 
        WHEN rfm_cell_string IN ('311', '411', '331') THEN 'new customers'
        WHEN rfm_cell_string IN ('222', '223', '233', '322') THEN 'potential churners'
        WHEN rfm_cell_string IN ('323', '333', '321', '422', '332', '432') THEN 'active'
        WHEN rfm_cell_string IN ('433', '434', '443', '444') THEN 'loyal'
    END AS rfm_segment
FROM temp_rfm;

SELECT DISTINCT 
    s.ORDERNUMBER, 
    SUBSTRING_INDEX(
        GROUP_CONCAT(p.PRODUCTCODE ORDER BY p.PRODUCTCODE SEPARATOR ','), ',', 3
    ) AS ProductCodes
FROM 
    sales s
JOIN 
    (
        SELECT 
            ORDERNUMBER, 
            COUNT(*) AS rn
        FROM 
            sales
        WHERE 
            STATUS = 'Shipped'
        GROUP BY 
            ORDERNUMBER
        HAVING 
            rn = 3
    ) m ON s.ORDERNUMBER = m.ORDERNUMBER
JOIN 
    sales p ON s.ORDERNUMBER = p.ORDERNUMBER
GROUP BY 
    s.ORDERNUMBER
ORDER BY 
    ProductCodes DESC;



SELECT city, SUM(sales) AS Revenue
FROM sales
WHERE country = 'UK'
GROUP BY city
ORDER BY Revenue DESC;


select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from sales
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc;