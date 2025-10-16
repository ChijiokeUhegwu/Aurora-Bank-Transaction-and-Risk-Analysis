-- Customer Profiling & Segmentation
-- These queries help to understand who the customers are and how they behave.

-- 1. Customer Demographics 
-- Age Distribution (Each customer’s age and group them into buckets)
SELECT 
    CASE 
        WHEN DATEDIFF(YEAR, birth_year, GETDATE()) < 25 THEN '<25'
        WHEN DATEDIFF(YEAR, birth_year, GETDATE()) BETWEEN 25 AND 34 THEN '25–34'
        WHEN DATEDIFF(YEAR, birth_year, GETDATE()) BETWEEN 35 AND 44 THEN '35–44'
        WHEN DATEDIFF(YEAR, birth_year, GETDATE()) BETWEEN 45 AND 54 THEN '45–54'
        ELSE '55+'
    END AS age_group,
    COUNT(*) AS total_customers
FROM users_data
WHERE birth_year IS NOT NULL
GROUP BY 
    CASE 
        WHEN DATEDIFF(YEAR, birth_year, GETDATE()) < 25 THEN '<25'
        WHEN DATEDIFF(YEAR,birth_year, GETDATE()) BETWEEN 25 AND 34 THEN '25–34'
        WHEN DATEDIFF(YEAR, birth_year, GETDATE()) BETWEEN 35 AND 44 THEN '35–44'
        WHEN DATEDIFF(YEAR, birth_year, GETDATE()) BETWEEN 45 AND 54 THEN '45–54'
        ELSE '55+'
    END
ORDER BY total_customers DESC;

-- 2. Gender distribution
SELECT 
    gender,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM users_data
GROUP BY gender
ORDER BY total_customers DESC;

-- Age distribution (without bracketing)
SELECT birth_year, COUNT(*) AS total_customers
FROM users_data
GROUP BY birth_year
ORDER BY birth_year;

-- c. Combine: Gender + Age + Location Breakdown
SELECT 
    gender,
    CASE 
        WHEN DATEDIFF(YEAR, birth_year, GETDATE()) < 25 THEN '<25'
        WHEN DATEDIFF(YEAR, birth_year, GETDATE()) BETWEEN 25 AND 34 THEN '25–34'
        WHEN DATEDIFF(YEAR, birth_year, GETDATE()) BETWEEN 35 AND 44 THEN '35–44'
        WHEN DATEDIFF(YEAR, birth_year, GETDATE()) BETWEEN 45 AND 54 THEN '45–54'
        ELSE '55+'
    END AS age_group,
    address,
    COUNT(*) AS total_customers
FROM users_data
WHERE birth_year IS NOT NULL
GROUP BY gender,
    CASE 
        WHEN DATEDIFF(YEAR, birth_year, GETDATE()) < 25 THEN '<25'
        WHEN DATEDIFF(YEAR, birth_year, GETDATE()) BETWEEN 25 AND 34 THEN '25–34'
        WHEN DATEDIFF(YEAR, birth_year, GETDATE()) BETWEEN 35 AND 44 THEN '35–44'
        WHEN DATEDIFF(YEAR, birth_year, GETDATE()) BETWEEN 45 AND 54 THEN '45–54'
        ELSE '55+'
    END,
    address
ORDER BY total_customers DESC;


-- 2. Credit Score Analysis (See how income and debt vary by credit score)
-- 2a. Credit Score Distribution
SELECT 
    CASE 
        WHEN credit_score < 580 THEN 'Poor (<580)'
        WHEN credit_score BETWEEN 580 AND 669 THEN 'Fair (580–669)'
        WHEN credit_score BETWEEN 670 AND 739 THEN 'Good (670–739)'
        WHEN credit_score BETWEEN 740 AND 799 THEN 'Very Good (740–799)'
        ELSE 'Excellent (800–850)'
    END AS credit_category,
    COUNT(*) AS total_customers,
    ROUND(AVG(yearly_income), 2) AS avg_income,
    ROUND(AVG(total_debt), 2) AS avg_debt
FROM users_data
WHERE credit_score IS NOT NULL
GROUP BY 
    CASE 
        WHEN credit_score < 580 THEN 'Poor (<580)'
        WHEN credit_score BETWEEN 580 AND 669 THEN 'Fair (580–669)'
        WHEN credit_score BETWEEN 670 AND 739 THEN 'Good (670–739)'
        WHEN credit_score BETWEEN 740 AND 799 THEN 'Very Good (740–799)'
        ELSE 'Excellent (800–850)'
    END
ORDER BY total_customers DESC;

-- 2b. Relationship Between Credit Score and Income
SELECT 
    ROUND(yearly_income / 10000, 0) * 10000 AS income_bracket,
    ROUND(AVG(credit_score), 2) AS avg_credit_score,
    COUNT(*) AS num_customers
FROM users_data
WHERE yearly_income IS NOT NULL AND credit_score IS NOT NULL
GROUP BY ROUND(yearly_income / 10000, 0) * 10000
ORDER BY income_bracket;

-- 2c. Relationship Between Credit Score and Debt-to-Income Ratio (DTI)
SELECT 
    ROUND((total_debt / NULLIF(yearly_income, 0)) * 100, 2) AS debt_to_income_ratio,
    ROUND(AVG(credit_score), 2) AS avg_credit_score,
    COUNT(*) AS num_customers
FROM users_data
WHERE total_debt IS NOT NULL AND yearly_income IS NOT NULL AND credit_score IS NOT NULL
GROUP BY ROUND((total_debt / NULLIF(yearly_income, 0)) * 100, 2)
ORDER BY debt_to_income_ratio;

-- 2d. Relationship Between Credit Score and Age
SELECT 
    CASE 
        WHEN DATEDIFF(YEAR, birth_year, GETDATE()) < 25 THEN '<25'
        WHEN DATEDIFF(YEAR, birth_year, GETDATE()) BETWEEN 25 AND 34 THEN '25–34'
        WHEN DATEDIFF(YEAR, birth_year, GETDATE()) BETWEEN 35 AND 44 THEN '35–44'
        WHEN DATEDIFF(YEAR, birth_year, GETDATE()) BETWEEN 45 AND 54 THEN '45–54'
        ELSE '55+'
    END AS age_group,
    ROUND(AVG(credit_score), 2) AS avg_credit_score,
    COUNT(*) AS total_customers
FROM users_data
WHERE credit_score IS NOT NULL AND birth_year IS NOT NULL
GROUP BY 
    CASE 
        WHEN DATEDIFF(YEAR, birth_year, GETDATE()) < 25 THEN '<25'
        WHEN DATEDIFF(YEAR, birth_year, GETDATE()) BETWEEN 25 AND 34 THEN '25–34'
        WHEN DATEDIFF(YEAR, birth_year, GETDATE()) BETWEEN 35 AND 44 THEN '35–44'
        WHEN DATEDIFF(YEAR, birth_year, GETDATE()) BETWEEN 45 AND 54 THEN '45–54'
        ELSE '55+'
    END
ORDER BY avg_credit_score DESC;

-- 3. Financial Health Analysis
-- 3a. Calculate Debt-to-Income (DTI) and Flag High-Risk Customers
SELECT 
    id AS customer_id,
    yearly_income,
    total_debt,
    ROUND((total_debt / NULLIF(yearly_income, 0)) * 100, 2) AS debt_to_income_ratio,
    CASE 
        WHEN (total_debt / NULLIF(yearly_income, 0)) * 100 < 20 THEN 'Low Risk (<20%)'
        WHEN (total_debt / NULLIF(yearly_income, 0)) * 100 BETWEEN 20 AND 35 THEN 'Moderate Risk (20–35%)'
        WHEN (total_debt / NULLIF(yearly_income, 0)) * 100 BETWEEN 36 AND 49 THEN 'High Risk (36–49%)'
        WHEN (total_debt / NULLIF(yearly_income, 0)) * 100 >= 50 THEN 'Critical Risk (≥50%)'
        ELSE 'Unknown'
    END AS financial_health_category
FROM users_data
WHERE yearly_income IS NOT NULL AND total_debt IS NOT NULL
ORDER BY debt_to_income_ratio DESC;

-- 3b. Aggregate Summary by Risk Category
SELECT 
    CASE 
        WHEN (total_debt / NULLIF(yearly_income, 0)) * 100 < 20 THEN 'Low Risk (<20%)'
        WHEN (total_debt / NULLIF(yearly_income, 0)) * 100 BETWEEN 20 AND 35 THEN 'Moderate Risk (20–35%)'
        WHEN (total_debt / NULLIF(yearly_income, 0)) * 100 BETWEEN 36 AND 49 THEN 'High Risk (36–49%)'
        WHEN (total_debt / NULLIF(yearly_income, 0)) * 100 >= 50 THEN 'Critical Risk (≥50%)'
        ELSE 'Unknown'
    END AS financial_health_category,
    COUNT(*) AS num_customers,
    ROUND(AVG((total_debt / NULLIF(yearly_income, 0)) * 100), 2) AS avg_dti_ratio,
    ROUND(AVG(credit_score), 2) AS avg_credit_score
FROM users_data
WHERE yearly_income IS NOT NULL AND total_debt IS NOT NULL
GROUP BY 
    CASE 
        WHEN (total_debt / NULLIF(yearly_income, 0)) * 100 < 20 THEN 'Low Risk (<20%)'
        WHEN (total_debt / NULLIF(yearly_income, 0)) * 100 BETWEEN 20 AND 35 THEN 'Moderate Risk (20–35%)'
        WHEN (total_debt / NULLIF(yearly_income, 0)) * 100 BETWEEN 36 AND 49 THEN 'High Risk (36–49%)'
        WHEN (total_debt / NULLIF(yearly_income, 0)) * 100 >= 50 THEN 'Critical Risk (≥50%)'
        ELSE 'Unknown'
    END
ORDER BY avg_dti_ratio DESC;

-- 4. Card Ownership Analysis
-- 4a. Number of Cards per Customer
SELECT 
    u.id AS customer_id,
    u.gender,
    u.current_age,
    COUNT(c.id) AS num_cards_owned
FROM users_data u
JOIN cards_data c ON u.id = c.client_id
GROUP BY u.id, u.gender, u.current_age
ORDER BY num_cards_owned DESC;

-- 4b. Average Cards Owned by Gender
SELECT 
    u.gender,
    ROUND(AVG(COUNT(c.id)) OVER (PARTITION BY u.gender), 2) AS avg_cards_owned
FROM users_data u
JOIN cards_data c ON u.id = c.client_id
GROUP BY u.id, u.gender;

-- 4c. Card Ownership by Age Group
SELECT 
    CASE 
        WHEN current_age < 25 THEN '<25'
        WHEN current_age BETWEEN 25 AND 34 THEN '25–34'
        WHEN current_age BETWEEN 35 AND 44 THEN '35–44'
        WHEN current_age BETWEEN 45 AND 54 THEN '45–54'
        ELSE '55+'
    END AS age_group,
    COUNT(c.id) AS total_cards,
    COUNT(DISTINCT u.id) AS total_customers,
    ROUND(COUNT(c.id) * 1.0 / COUNT(DISTINCT u.id), 2) AS avg_cards_per_customer
FROM users_data u
JOIN cards_data c ON u.id = c.client_id
GROUP BY 
    CASE 
        WHEN current_age < 25 THEN '<25'
        WHEN current_age BETWEEN 25 AND 34 THEN '25–34'
        WHEN current_age BETWEEN 35 AND 44 THEN '35–44'
        WHEN current_age BETWEEN 45 AND 54 THEN '45–54'
        ELSE '55+'
    END
ORDER BY total_cards DESC;

-- 4d. Card Ownership by Brand and Type
SELECT  
    c.card_brand,
    c.card_type,
    COUNT(*) AS total_cards_issued,
    ROUND(AVG(c.credit_limit), 2) AS avg_credit_limit,
    ROUND(AVG(DATEDIFF(YEAR, TRY_CONVERT(DATE, '01-' + c.acct_open_date, 106), GETDATE())), 2) AS avg_years_active
FROM cards_data c
WHERE TRY_CONVERT(DATE, '01-' + c.acct_open_date, 106) IS NOT NULL
GROUP BY c.card_brand, c.card_type
ORDER BY total_cards_issued DESC;

-- 5. Financial Health (Debt-to-Income Ratio)
-- Identify high-risk customers
SELECT 
    id,
    yearly_income,
    total_debt,
    ROUND(CAST(total_debt AS FLOAT) / NULLIF(yearly_income, 0), 2) AS debt_to_income_ratio
FROM users_data
ORDER BY debt_to_income_ratio DESC;

-- 6. Card Ownership
-- How card usage and limits vary by demographic
SELECT 
    u.gender,
    COUNT(c.id) AS total_cards,
    AVG(c.credit_limit) AS avg_credit_limit
FROM users_data u
JOIN cards_data c ON u.id = c.client_id
GROUP BY u.gender;

-- 7. Grouping customers into longitude and latitude
SELECT 
    CAST(TRY_CAST(latitude AS FLOAT) AS INT) AS LatBand,
    CAST(TRY_CAST(longitude AS FLOAT) AS INT) AS LonBand,
    COUNT(*) AS NumOfCustomers
FROM users_data
WHERE TRY_CAST(latitude AS FLOAT) IS NOT NULL
  AND TRY_CAST(longitude AS FLOAT) IS NOT NULL
GROUP BY CAST(TRY_CAST(latitude AS FLOAT) AS INT),
         CAST(TRY_CAST(longitude AS FLOAT) AS INT)
ORDER BY NumOfCustomers DESC;


