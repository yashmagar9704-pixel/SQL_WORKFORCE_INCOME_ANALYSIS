/*
=========================================================
WORKFORCE DATA ANALYSIS - SQL SERVER PROJECT
Dataset: salaries
Source case study: Workforce Data Analysis
=========================================================
*/
CREATE DATEBASE SQL_PROJECT_ANALYSIS;

USE SQL_PROJECT_ANALYSIS

select * from salary_project_Analysis

-- ======================================================
-- TASK 1
-- Number of employees by company size in 2021
-- ======================================================
SELECT
    company_size,
    COUNT(*) AS employee_count
FROM salary_project_Analysis
WHERE work_year = 2021
GROUP BY company_size
ORDER BY company_size;

-- ======================================================
-- TASK 2
-- Top 3 job titles with highest average salary for
-- part-time positions in 2023, requiring >50 employees
-- in the grouped result.
-- ======================================================
SELECT TOP (3)
    job_title,
    AVG(salary_in_usd) AS avg_salary_usd,
    COUNT(*) AS employee_count
FROM salary_project_Analysis
WHERE employment_type = 'PT'
  AND work_year = 2023
GROUP BY job_title
HAVING COUNT(*) > 50
ORDER BY AVG(salary_in_usd) DESC;

-- ======================================================
-- TASK 3
-- Countries where 2023 mid-level salary is above the
-- overall 2023 mid-level average
-- ======================================================
WITH OverallMI AS
(
    SELECT AVG(salary_in_usd) AS overall_avg_salary
    FROM salary_project_Analysis
    WHERE experience_level = 'MI'
      AND work_year = 2023
),
CountryMI AS
(
    SELECT
        employee_residence,
        AVG(salary_in_usd) AS country_avg_salary
    FROM salary_project_Analysis
    WHERE experience_level = 'MI'
      AND work_year = 2023
    GROUP BY employee_residence
)
SELECT
    c.employee_residence,
    c.country_avg_salary,
    o.overall_avg_salary
FROM CountryMI c
CROSS JOIN OverallMI o
WHERE c.country_avg_salary > o.overall_avg_salary
ORDER BY c.country_avg_salary DESC;

-- ======================================================
-- TASK 4
-- Highest and lowest average salary locations for
-- senior-level employees in 2023
-- ======================================================
WITH SeniorSalary AS
(
    SELECT
        company_location,
        AVG(salary_in_usd) AS avg_salary_usd
    FROM salary_project_Analysis
    WHERE experience_level = 'SE'
      AND work_year = 2023
    GROUP BY company_location
)
SELECT TOP (1)
    'Highest' AS salary_position,
    company_location,
    avg_salary_usd
FROM SeniorSalary
ORDER BY avg_salary_usd DESC

SELECT TOP (1)
    'Lowest' AS salary_position,
    company_location,
    avg_salary_usd
FROM SeniorSalary
ORDER BY avg_salary_usd ASC;
-- ======================================================
-- TASK 5
-- Salary growth percentage by job title from 2023 to 2024
-- ======================================================
WITH SeniorSalary AS
(
    SELECT
        company_location,
        AVG(salary_in_usd) AS avg_salary_usd
    FROM salary_project_analysis
    WHERE experience_level = 'SE'
      AND work_year = 2023
    GROUP BY company_location
),
HighestSalary AS
(
    SELECT TOP (1)
        'Highest' AS salary_position,
        company_location,
        avg_salary_usd
    FROM SeniorSalary
    ORDER BY avg_salary_usd DESC
),
LowestSalary AS
(
    SELECT TOP (1)
        'Lowest' AS salary_position,
        company_location,
        avg_salary_usd
    FROM SeniorSalary
    ORDER BY avg_salary_usd ASC
)
SELECT *
FROM HighestSalary

UNION ALL

SELECT *
FROM LowestSalary;
-- ======================================================
-- TASK 6
-- Top 3 countries with highest entry-level salary growth
-- from 2020 to 2023, with >50 employee records.
-- ======================================================
SELECT TOP (3)
    employee_residence,
    AVG(CASE WHEN work_year = 2020 THEN salary_in_usd END) AS avg_salary_2020,
    AVG(CASE WHEN work_year = 2023 THEN salary_in_usd END) AS avg_salary_2023,
    (
        (
            AVG(CASE WHEN work_year = 2023 THEN salary_in_usd END)
            -
            AVG(CASE WHEN work_year = 2020 THEN salary_in_usd END)
        )
        / NULLIF(AVG(CASE WHEN work_year = 2020 THEN salary_in_usd END), 0)
    ) * 100.0 AS growth_pct
FROM salary_project_Analysis
WHERE experience_level = 'EN'
  AND work_year IN (2020, 2023)
GROUP BY employee_residence
HAVING COUNT(*) > 50
   AND COUNT(CASE WHEN work_year = 2020 THEN 1 END) > 0
   AND COUNT(CASE WHEN work_year = 2023 THEN 1 END) > 0
ORDER BY growth_pct DESC;
-- ======================================================
-- TASK 7
-- Set remote_ratio = 100 for employees earning >$90,000
-- whose residence is US or AU.
-- ======================================================
UPDATE salary_project_Analysis
SET remote_ratio = 100
WHERE salary_in_usd > 90000
  AND employee_residence IN ('US', 'AU');

-- ======================================================
-- TASK 8
-- Increase 2024 salaries according to experience level.
-- The case study explicitly states:
--     SE = 22%
--     MI = 30%
-- It does NOT specify EN and EX percentages.
--
-- Replace NULL below with the assignment's EN/EX values
-- once they are supplied.
-- ======================================================
UPDATE salary_project_Analysis
SET salary =
    salary *
    (
        1 +
        CASE
            WHEN experience_level = 'SE' THEN 0.22
            WHEN experience_level = 'MI' THEN 0.30
            -- WHEN experience_level = 'EN' THEN 0.xx
            -- WHEN experience_level = 'EX' THEN 0.xx
            ELSE 0
        END
    )
WHERE work_year = 2024;

-- ======================================================
-- TASK 9
-- Year with the highest average salary for each job title
-- ======================================================
WITH JobYearSalary AS
(
    SELECT
        job_title,
        work_year,
        AVG(salary_in_usd) AS avg_salary_usd
    FROM salary_project_Analysis
    GROUP BY job_title, work_year
),
Ranked AS
(
    SELECT *,
           RANK() OVER
           (
               PARTITION BY job_title
               ORDER BY avg_salary_usd DESC
           ) AS salary_rank
    FROM JobYearSalary
)
SELECT
    job_title,
    work_year,
    avg_salary_usd
FROM Ranked
WHERE salary_rank = 1
ORDER BY job_title;

-- ======================================================
-- TASK 10
-- Percentage of FT and PT employees for each job title
-- ======================================================
SELECT
    job_title,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN employment_type = 'FT' THEN 1 ELSE 0 END) AS ft_count,
    SUM(CASE WHEN employment_type = 'PT' THEN 1 ELSE 0 END) AS pt_count,
    100.0 * SUM(CASE WHEN employment_type = 'FT' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0) AS ft_percentage,
    100.0 * SUM(CASE WHEN employment_type = 'PT' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0) AS pt_percentage
FROM salary_project_Analysis
GROUP BY job_title
ORDER BY job_title;
-- ======================================================
-- TASK 11
-- Countries offering fully remote manager jobs >$90,000
-- ======================================================
SELECT
    employee_residence,
    COUNT(*) AS qualifying_manager_jobs
FROM salary_project_Analysis
WHERE job_title LIKE '%Manager%'
  AND salary_in_usd > 90000
  AND remote_ratio = 100
GROUP BY employee_residence
ORDER BY qualifying_manager_jobs DESC;
-- ======================================================
-- TASK 12
-- Top 5 countries with the most large companies
-- ======================================================
SELECT TOP (5)
    company_location,
    COUNT(*) AS large_company_employee_records
FROM salary_project_Analysis
WHERE company_size = 'L'
GROUP BY company_location
ORDER BY COUNT(*) DESC;

-- ======================================================
-- TASK 13
-- Percentage of employees who are fully remote and earn >$100,000
-- ======================================================
SELECT
    COUNT(CASE
              WHEN remote_ratio = 100
               AND salary_in_usd > 100000
              THEN 1
         END) AS qualifying_employees,
    COUNT(*) AS total_employees,
    100.0 * COUNT(CASE
                      WHEN remote_ratio = 100
                       AND salary_in_usd > 100000
                      THEN 1
                  END)
        / NULLIF(COUNT(*), 0) AS qualifying_percentage
FROM salary_project_Analysis;

-- ======================================================
-- TASK 14
-- Locations where entry-level average salary exceeds
-- the overall entry-level market average
-- ======================================================
WITH Market AS
(
    SELECT AVG(salary_in_usd) AS market_avg
    FROM salary_project_Analysis
    WHERE experience_level = 'EN'
),
LocationSalary AS
(
    SELECT
        employee_residence,
        AVG(salary_in_usd) AS location_avg
    FROM salary_project_Analysis
    WHERE experience_level = 'EN'
    GROUP BY employee_residence
)
SELECT
    l.employee_residence,
    l.location_avg,
    m.market_avg
FROM LocationSalary l
CROSS JOIN Market m
WHERE l.location_avg > m.market_avg
ORDER BY l.location_avg DESC;

-- ======================================================
-- TASK 15
-- Country with the maximum average salary for each job title
-- ======================================================
WITH JobCountry AS
(
    SELECT
        job_title,
        employee_residence,
        AVG(salary_in_usd) AS avg_salary_usd
    FROM salary_project_Analysis
    GROUP BY job_title, employee_residence
),
Ranked AS
(
    SELECT *,
           RANK() OVER
           (
               PARTITION BY job_title
               ORDER BY avg_salary_usd DESC
           ) AS salary_rank
    FROM JobCountry
)
SELECT
    job_title,
    employee_residence,
    avg_salary_usd
FROM Ranked
WHERE salary_rank = 1
ORDER BY job_title;
-- ======================================================
-- TASK 16
-- Countries with sustained salary growth in 2021, 2022, 2023
-- ======================================================
WITH CountrySalary AS
(
    SELECT
        employee_residence,
        AVG(CASE WHEN work_year = 2021 THEN salary_in_usd END) AS avg_2021,
        AVG(CASE WHEN work_year = 2022 THEN salary_in_usd END) AS avg_2022,
        AVG(CASE WHEN work_year = 2023 THEN salary_in_usd END) AS avg_2023
    FROM salary_project_Analysis
    WHERE work_year IN (2021, 2022, 2023)
    GROUP BY employee_residence
)
SELECT
    employee_residence,
    avg_2021,
    avg_2022,
    avg_2023
FROM CountrySalary
WHERE avg_2021 IS NOT NULL
  AND avg_2022 IS NOT NULL
  AND avg_2023 IS NOT NULL
  AND avg_2022 > avg_2021
  AND avg_2023 > avg_2022
ORDER BY avg_2023 DESC;

-- ======================================================
-- TASK 17
-- Percentage of fully remote work by experience level,
-- comparing 2021 vs 2024
-- ======================================================
SELECT
    experience_level,
    work_year,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN remote_ratio = 100 THEN 1 ELSE 0 END) AS fully_remote,
    100.0 * SUM(CASE WHEN remote_ratio = 100 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0) AS fully_remote_percentage
FROM salary_project_Analysis
WHERE work_year IN (2021, 2024)
GROUP BY experience_level, work_year
ORDER BY experience_level, work_year;
-- ======================================================
-- TASK 18
-- Average salary increase percentage by experience level
-- and job title from 2023 to 2024
-- ======================================================
WITH SalaryByYear AS
(
    SELECT
        experience_level,
        job_title,
        AVG(CASE WHEN work_year = 2023 THEN salary_in_usd END) AS avg_2023,
        AVG(CASE WHEN work_year = 2024 THEN salary_in_usd END) AS avg_2024
    FROM salary_project_Analysis
    WHERE work_year IN (2023, 2024)
    GROUP BY experience_level, job_title
)
SELECT
    experience_level,
    job_title,
    avg_2023,
    avg_2024,
    100.0 * (avg_2024 - avg_2023) / NULLIF(avg_2023, 0)
        AS salary_increase_percentage
FROM SalaryByYear
WHERE avg_2023 IS NOT NULL
  AND avg_2024 IS NOT NULL
ORDER BY salary_increase_percentage DESC;

-- ======================================================
-- TASK 19
-- Role-based access control by experience level
-- SQL Server Row-Level Security (RLS)
-- ======================================================
CREATE FUNCTION dbo.fn_ExperienceLevel
(
    @experience_level VARCHAR(10)
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    SELECT 1 AS fn_access
    WHERE @experience_level =
          CONVERT(VARCHAR(10),
                  SESSION_CONTEXT(N'ExperienceLevel'))
);

CREATE SECURITY POLICY dbo.ExperienceLevelSecurityPolicy
ADD FILTER PREDICATE
    dbo.fn_ExperienceLevelPredicate(experience_level)
ON dbo.salaries
WITH (STATE = ON);

-- ======================================================
-- TASK 20
-- Domain switching recommendation
--
-- The dataset has job_title but no explicit "domain" field.
-- Therefore the following is an analytical classification
-- inferred from job-title keywords. It is an approach, not a
-- source-provided domain mapping.
-- ======================================================

WITH JobDomain AS
(
    SELECT
        experience_level,
        job_title,
        salary_in_usd,
        CASE
            WHEN job_title LIKE '%Machine Learning%'
              OR job_title LIKE '%ML %'
              OR job_title LIKE '%MLOps%'
              OR job_title LIKE '%Deep Learning%'
              OR job_title LIKE '%NLP%'
              OR job_title LIKE '%AI %'
              OR job_title LIKE 'AI%'
              OR job_title LIKE '%Computer Vision%'
              OR job_title LIKE '%Robotics%'
                THEN 'AI / Machine Learning'

            WHEN job_title LIKE '%Data Scientist%'
              OR job_title LIKE '%Data Science%'
              OR job_title LIKE '%Research Scientist%'
              OR job_title LIKE '%Research Engineer%'
              OR job_title LIKE '%Decision Scientist%'
              OR job_title LIKE '%Applied Scientist%'
                THEN 'Data Science'

            WHEN job_title LIKE '%Data Engineer%'
              OR job_title LIKE '%ETL%'
              OR job_title LIKE '%Data Pipeline%'
              OR job_title LIKE '%Data Infrastructure%'
              OR job_title LIKE '%Data Integration%'
              OR job_title LIKE '%Database%'
              OR job_title LIKE '%Cloud Data%'
                THEN 'Data Engineering'

            WHEN job_title LIKE '%Analyst%'
              OR job_title LIKE '%Analytics%'
              OR job_title LIKE '%Business Intelligence%'
              OR job_title LIKE '%BI %'
              OR job_title LIKE '%Power BI%'
              OR job_title LIKE '%Visualization%'
                THEN 'Analytics / BI'

            WHEN job_title LIKE '%Manager%'
              OR job_title LIKE '%Director%'
              OR job_title LIKE '%Head %'
              OR job_title LIKE '%Lead%'
                THEN 'Management / Leadership'

            ELSE 'Other'
        END AS domain
    FROM salary_project_Analysis
),
DomainSalary AS
(
    SELECT
        experience_level,
        domain,
        AVG(salary_in_usd) AS avg_salary_usd
    FROM JobDomain
    GROUP BY experience_level, domain
)
SELECT
    experience_level,
    domain,
    avg_salary_usd,
    RANK() OVER
    (
        PARTITION BY experience_level
        ORDER BY avg_salary_usd DESC
    ) AS salary_rank
FROM DomainSalary
ORDER BY experience_level, salary_rank;


DECLARE @ExperienceLevel VARCHAR(10) = 'MI';
DECLARE @CurrentJobTitle VARCHAR(255) = 'Data Analyst';

WITH CurrentSalary AS
(
    SELECT AVG(salary_in_usd) AS current_avg_salary
    FROM salary_project_Analysis
    WHERE experience_level = @ExperienceLevel
      AND job_title = @CurrentJobTitle
),
RoleSalary AS
(
    SELECT
        job_title,
        AVG(salary_in_usd) AS avg_salary_usd
    FROM salary_project_Analysis
    WHERE experience_level = @ExperienceLevel
    GROUP BY job_title
)
SELECT TOP (10)
    r.job_title AS possible_transition_role,
    r.avg_salary_usd,
    c.current_avg_salary,
    r.avg_salary_usd - c.current_avg_salary AS potential_salary_difference
FROM RoleSalary r
CROSS JOIN CurrentSalary c
WHERE r.avg_salary_usd > c.current_avg_salary
ORDER BY potential_salary_difference DESC;

-- ======================================================
-- OPTIONAL DATA QUALITY CHECKS
-- ======================================================
SELECT COUNT(*) AS total_rows
FROM salary_project_Analysis;

SELECT
    COUNT(*) AS exact_duplicate_rows
FROM
(
    SELECT
        work_year, experience_level, employment_type, job_title,
        salary, salary_currency, salary_in_usd, employee_residence,
        remote_ratio, company_location, company_size,
        COUNT(*) AS duplicate_count
    FROM salary_project_Analysis
    GROUP BY
        work_year, experience_level, employment_type, job_title,
        salary, salary_currency, salary_in_usd, employee_residence,
        remote_ratio, company_location, company_size
    HAVING COUNT(*) > 1
) d;
