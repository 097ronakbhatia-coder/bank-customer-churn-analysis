-- POSTGRE SQL FILE


-- OBJECTIVE 2.	Identify the top 5 customers with the highest Estimated Salary in the last quarter of the year. (SQL)

-- ANS
SELECT 
    c.customerid,
    c.surname,
    c.estimatedsalary,
    c."Bank DOJ",
    g.gendercategory,
    h.geographylocation
FROM customerinfo c
JOIN gender g 
    ON c.genderid = g.genderid
JOIN geography h 
    ON c.geographyid = h.geographyid
WHERE EXTRACT(MONTH FROM c."Bank DOJ") IN (10, 11, 12)
order by c.estimatedsalary desc
limit 5;


-- OBJECTIVE 3.	Calculate the average number of products used by customers who have a credit card. (SQL)

-- ANS
select hascrcard,
round(avg(cast(numofproducts as numeric)),3) as average_products from bank_churn 
group by hascrcard;


-- OBJECTIVE 5.	Compare the average credit score of customers who have exited and those who remain. (SQL)

-- ANS 
select exited,
round(avg(cast(creditscore as numeric)),2) as avgcreditscore from bank_churn
group by exited;


-- OBJECTIVE 6.	Which gender has a higher average estimated salary, and how does it relate to the number of active accounts? (SQL)

-- ANS
select g.gendercategory,
avg(c.estimatedsalary) as avg_salary,
sum(b.isactivemember) as active_accounts from customerinfo c 
join gender g 
on c.genderid = g.genderid
join bank_churn b 
on c.customerid = b.customeridD
group by g.gendercategory;

-- OBJECTIVE 7.	Segment the customers based on their credit score and identify the segment with the highest exit rate. (SQL)

-- ANS
with cte as(SELECT
  CASE
    WHEN creditscore BETWEEN 300 AND 450 THEN '300-450'
    WHEN creditscore BETWEEN 451 AND 550 THEN '451-550'
    WHEN creditscore BETWEEN 551 AND 650 THEN '551-650'
    WHEN creditscore BETWEEN 651 AND 750 THEN '651-750'
    WHEN creditscore BETWEEN 751 AND 850 THEN '751-850'
  END AS creditsegment,
  customerid,
  exited
FROM bank_churn)
select creditsegment,
COUNT(*) AS Total,
  SUM(exited) AS exited,
  ROUND(100.0*SUM(exited)/COUNT(*), 2) AS exitrate
  from cte 
 group by creditsegment
 order by exitrate desc;


-- OBJECTIVE 8.	Find out which geographic region has the highest number of active customers with a tenure greater than 5 years. (SQL)

-- ANS
SELECT geo.geographylocation, COUNT(*) AS active_long_tenure
FROM bank_churn bc
JOIN customerinfo ci ON bc.customerid = ci.customerid
JOIN geography geo ON ci.geographyid = geo.geographyid
WHERE bc.isactivemember = 1 AND bc.tenure > 5
GROUP BY geo.geographylocation
ORDER BY active_long_tenure DESC;

-- OBJECTIVE 11.	Examine the trend of customers joining over time and identify any seasonal patterns (yearly or monthly). 
-- Prepare the data through SQL and then visualize it.

-- ANS
with cte as(select year, customerjoined, lag(customerjoined) over(order by year asc) as previous_year from
(select extract (year from "Bank DOJ") as year,
count(*) as customerjoined from customerinfo
group by extract (year from "Bank DOJ")) j)
select year,
customerjoined,
previous_year,
round(((customerjoined-previous_year):: numeric /previous_year) * 100,2) as yeargrowth from cte;


-- OBJECTIVE 15. Using SQL, write a query to find out the gender-wise average income of males and females in each geography id. 
-- Also, rank the gender according to the average value. (SQL)

-- ANS
SELECT geo.geographylocation, g.gendercategory,
       AVG(ci.estimatedsalary) AS avgincome,
       RANK() OVER (PARTITION BY geo.geographylocation
                   ORDER BY AVG(ci.estimatedsalary) DESC) AS incomerank
FROM customerinfo ci
JOIN gender g ON ci.genderid = g.genderid
JOIN geography geo ON ci.geographyid = geo.geographyid
GROUP BY geo.geographylocation, g.gendercategory;


-- OBJECTIVE 16. Using SQL, write a query to find out the average tenure of the people 
-- who have exited in each age bracket (18-30, 30-50, 50+).

-- ANS
SELECT
  CASE
    WHEN age BETWEEN 18 AND 30 THEN '18-30'
    WHEN age BETWEEN 31 AND 50 THEN '31-50'
    ELSE '50+'
  END AS agebracket,
  AVG(CAST(bc.tenure AS INT)) AS avgtenure
FROM bank_churn bc
JOIN customerinfo ci ON bc.customerid = ci.customerid
WHERE bc.exited = 1
GROUP BY CASE WHEN age BETWEEN 18 AND 30 THEN '18-30'
              WHEN age BETWEEN 31 AND 50 THEN '31-50'
              ELSE '50+' END;


-- OBJECTIVE 20. According to the age buckets find the number of customers who have a credit card. 
-- Also retrieve those buckets that have lesser than average number of credit cards per bucket

-- ANS
SELECT agebucket, COUNT(*) AS creditcardholders
FROM (SELECT customerid,
        CASE WHEN age BETWEEN 18 AND 30 THEN '18-30'
             WHEN age BETWEEN 31 AND 50 THEN '31-50'
             ELSE '50+' END AS agebucket
      FROM customerinfo) ci
JOIN bank_churn bc ON ci.CustomerId = bc.CustomerId
WHERE bc.hascrcard = 1
GROUP BY agebucket;


-- OBJECTIVE  22.	As we can see that the “CustomerInfo” table has the CustomerID and Surname, 
-- now if we have to join it with a table where the primary key is also a combination of CustomerID and Surname, 
-- come up with a column where the format is “CustomerID_Surname”.

-- ANS
SELECT customerid, surname,
       concat(customerid, ' ', surname) AS customerid_surname
FROM customerinfo;


-- OBJECTIVE 23. Without using “Join”, can we get the “ExitCategory” from ExitCustomers table to Bank_Churn table? 
-- If yes do this using SQL.

-- ANS 
-- Method 1: Subquery (Correlated):
SELECT bc.*,
  (SELECT ec.exitcategory
   FROM exitcustomer ec
   WHERE ec.exitid = bc.exited) AS exitcategory
FROM bank_churn bc;

-- Method 2: CASE Expression (No join needed):
SELECT bc.*,
  CASE WHEN bc.exited = 1 THEN 'exit'
       WHEN bc.exited = 0 THEN 'retain'
  END AS exitcategory
FROM bank_churn bc;


-- OBJECTIVE 25. Write the query to get the customer IDs, their last name, and whether they are active or not for the customers
-- whose surname ends with “on”.

-- ANS
SELECT bc.customerid, ci.surname,
  CASE WHEN bc.isactivemember = 1 THEN 'active'
       ELSE 'inactive' END AS activestatus
FROM bank_churn bc
JOIN customerinfo ci ON bc.customerid = ci.customerid
WHERE ci.surname LIKE '%on';


-- SUBJECTIVE 9. Utilize SQL queries to segment customers based on demographics and account details.


-- ANS
SELECT
    ci.customerid,ci.surname,g.gendercategory,geo.geographylocation,ci.age,bc.creditscore,bc.balance,bc.numofproducts,bc.tenure,
    bc.isactivemember,bc.hascrcard,bc.exited,ci.estimatedsalary,
    CASE
        WHEN ci.age BETWEEN 18 AND 30 THEN '18-30'
        WHEN ci.age BETWEEN 31 AND 50 THEN '31-50'
        ELSE '50+'
    END AS agebracket,
    CASE
        WHEN bc.creditscore < 450 AND bc.numofproducts = 1 THEN 'high risk'
        WHEN bc.CreditScore BETWEEN 450 AND 650 AND bc.isactivemember = 0 THEN 'medium risk'
        WHEN bc.creditscore > 650 AND bc.isactivemember = 1 THEN 'low risk'
        ELSE 'moderate'
    END AS risksegment,
    ROUND((1 - bc.creditscore/850.0) * 0.30 + (1 - bc.isactivemember) * 0.40 +
        CASE WHEN bc.numofproducts = 1 THEN 0.30 ELSE 0 END,
    4) AS churnriskscore,
    CASE
        WHEN ROUND((1-bc.creditscore/850.0)*0.3+(1-bc.isactivemember)*0.4+
             CASE WHEN bc.numofproducts=1 THEN 0.3 ELSE 0 END,4) > 0.65 THEN 'RED'
        WHEN ROUND((1-bc.creditscore/850.0)*0.3+(1-bc.isactivemember)*0.4+
             CASE WHEN bc.numofproducts=1 THEN 0.3 ELSE 0 END,4) > 0.35 THEN 'amber'
        ELSE 'green'
    END AS riskcolor
FROM bank_churn bc
JOIN customerinfo ci  ON bc.customerid   = ci.customerid
JOIN gender g         ON ci.genderid     = g.genderid
JOIN geography geo    ON ci.geographyid  = geo.geographyid
ORDER BY churnriskscore DESC;
  

-- SUBJECTIVE 14.	In the “bank_churn” table how can you modify the name of
--  the “hascrcard” column to “has_creditcard”? 

-- ANS 

ALTER TABLE Bank_Churn
RENAME COLUMN hascrcard TO has_creditcard;

select * from bank_churn;




