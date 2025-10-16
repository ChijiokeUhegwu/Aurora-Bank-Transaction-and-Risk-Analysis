-- Transaction & Risk Analysis
-- Explore customer behavior, fraud detection, and financial risk.

-- 1. Spending Patterns by Merchant Category
SELECT 
    m.Description AS Merchant_Category,
    COUNT(t.id) AS Total_Transactions,
    SUM(t.amount) AS Total_Spent
FROM transactions_data t
JOIN mcc_codes m ON t.mcc = m.mcc_id
GROUP BY m.Description
ORDER BY Total_Spent DESC;

-- 2. Geographical Trends
-- Total Spending by State (or City)
SELECT 
    merchant_state,
    merchant_city,
    SUM(amount) AS total_spent,
    COUNT(id) AS total_transactions,
    ROUND(AVG(amount), 2) AS avg_transaction_value
FROM transactions_data
WHERE errors IS NULL -- exclude failed transactions
GROUP BY merchant_state, merchant_city
ORDER BY total_spent DESC;

-- 2b. Combination of MCC and Location for Deeper Insig
SELECT 
    m.Description AS merchant_category,
    t.merchant_state,
    COUNT(t.id) AS total_transactions,
    ROUND(SUM(t.amount), 2) AS total_spent
FROM transactions_data t
JOIN mcc_codes m ON t.mcc = m.mcc_id
WHERE t.amount > 0
GROUP BY m.Description, t.merchant_state
ORDER BY total_spent DESC;



-- 3. Error Trends
SELECT 
    errors,
    COUNT(*) AS error_count
FROM transactions_data
WHERE errors IS NOT NULL
GROUP BY errors
ORDER BY error_count DESC;

-- 4. Error Frequency by Region
SELECT 
    merchant_state,
    merchant_city,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN errors IS NOT NULL THEN 1 ELSE 0 END) AS failed_transactions,
    ROUND(
        100.0 * SUM(CASE WHEN errors IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS failure_rate_percent
FROM transactions_data
GROUP BY merchant_state, merchant_city
HAVING COUNT(*) > 10 -- optional: exclude low-activity areas
ORDER BY failure_rate_percent DESC;

--5. Combine Spending and Failure Data
-- Spending vs. error rate in the same output (for correlation analysis)
SELECT 
    merchant_state,
    SUM(amount) AS total_spent,
    COUNT(id) AS total_transactions,
    SUM(CASE WHEN errors IS NOT NULL THEN 1 ELSE 0 END) AS failed_transactions,
    ROUND(
        100.0 * SUM(CASE WHEN errors IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS failure_rate_percent
FROM transactions_data
GROUP BY merchant_state
ORDER BY total_spent DESC, failure_rate_percent DESC;

-- 6a. Basic Error Frequency Analysis
-- Count and Rank Error Types
SELECT 
    errors AS error_type,
    COUNT(*) AS error_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM transactions_data), 2) AS error_percentage
FROM transactions_data
WHERE errors IS NOT NULL
GROUP BY errors
ORDER BY error_count DESC;

-- 6b. Error Trends by Time (Daily, Monthly, Yearly)
-- Monthly Error Trends
SELECT 
    YEAR(date) AS txn_year,
    MONTH(date) AS txn_month,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN errors IS NOT NULL THEN 1 ELSE 0 END) AS failed_transactions,
    ROUND(
        100.0 * SUM(CASE WHEN errors IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS failure_rate_percent
FROM transactions_data
GROUP BY YEAR(date), MONTH(date)
ORDER BY txn_year, txn_month;

-- 6c. Error Trends by Location
-- Identify Regions with Most Transaction Errors
SELECT 
    merchant_state,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN errors IS NOT NULL THEN 1 ELSE 0 END) AS failed_transactions,
    ROUND(
        100.0 * SUM(CASE WHEN errors IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS failure_rate_percent
FROM transactions_data
GROUP BY merchant_state
ORDER BY failure_rate_percent DESC;

-- 6d. Error Trends by Card Brand or Type
-- Which Card Brands Have More Errors
SELECT 
    c.card_brand,
    c.card_type,
    COUNT(t.id) AS total_transactions,
    SUM(CASE WHEN t.errors IS NOT NULL THEN 1 ELSE 0 END) AS failed_transactions,
    ROUND(
        100.0 * SUM(CASE WHEN t.errors IS NOT NULL THEN 1 ELSE 0 END) / COUNT(t.id),
        2
    ) AS failure_rate_percent
FROM transactions_data t
JOIN cards_data c ON t.card_id = c.id
GROUP BY c.card_brand, c.card_type
ORDER BY failure_rate_percent DESC;

-- 6e. Error Trends by Merchant Category (MCC)
-- Which Merchant Categories Have the Most Errors
SELECT 
    m.Description AS Merchant_Category,
    COUNT(t.id) AS total_transactions,
    SUM(CASE WHEN t.errors IS NOT NULL THEN 1 ELSE 0 END) AS failed_transactions,
    ROUND(
        100.0 * SUM(CASE WHEN t.errors IS NOT NULL THEN 1 ELSE 0 END) / COUNT(t.id),
        2
    ) AS failure_rate_percent
FROM transactions_data t
JOIN mcc_codes m ON t.mcc = m.mcc_id
GROUP BY m.Description
ORDER BY failure_rate_percent DESC;

-- 6f. Check whether chip vs non-chip transactions fail more often
SELECT 
    use_chip,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN errors IS NOT NULL THEN 1 ELSE 0 END) AS failed_transactions,
    ROUND(
        100.0 * SUM(CASE WHEN errors IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS failure_rate_percent
FROM transactions_data
GROUP BY use_chip;

-- 7a. Identify High-Value Transactions (Global Threshold)
-- Transactions Above 3× the Average Transaction Value
SELECT 
    t.id AS transaction_id,
    t.client_id,
    t.card_id,
    t.amount,
    t.merchant_city,
    t.merchant_state,
    m.Description AS merchant_category,
    c.card_brand,
    c.card_type,
    u.yearly_income,
    u.credit_score
FROM transactions_data t
JOIN mcc_codes m ON t.mcc = m.mcc_id
JOIN cards_data c ON t.card_id = c.id
JOIN users_data u ON t.client_id = u.id
WHERE t.amount > (SELECT AVG(amount) * 3 FROM transactions_data)
ORDER BY t.amount DESC;

-- 7b. Detect High-Value Transactions Relative to Customer Profile
-- Transaction > 50% of Customer’s Monthly Income
SELECT 
    t.id AS transaction_id,
    t.client_id,
    u.yearly_income,
    ROUND(u.yearly_income / 12.0, 2) AS monthly_income,
    t.amount,
    t.merchant_city,
    t.merchant_state,
    m.Description AS merchant_category,
    CASE 
        WHEN t.amount > (u.yearly_income / 12.0) * 0.5 THEN 'High Value (≥50% Monthly Income)'
        ELSE 'Normal'
    END AS transaction_flag
FROM transactions_data t
JOIN users_data u ON t.client_id = u.id
JOIN mcc_codes m ON t.mcc = m.mcc_id
WHERE t.amount > (u.yearly_income / 12.0) * 0.5
ORDER BY t.amount DESC;

-- 7c. Compare Against Credit Limit (For Credit Cards Only)
-- Transactions > 90% of Credit Limit (N/B: Use NULLIF() to avoid zero division)
SELECT 
    t.id AS transaction_id,
    t.client_id,
    c.id AS card_id,
    c.card_brand,
    c.card_type,
    c.credit_limit,
    t.amount,
    ROUND((t.amount / NULLIF(c.credit_limit, 0)) * 100, 2) AS pct_of_credit_limit,
    m.Description AS merchant_category
FROM transactions_data t
JOIN cards_data c ON t.card_id = c.id
JOIN mcc_codes m ON t.mcc = m.mcc_id
WHERE 
    c.credit_limit > 0
    AND t.amount > (c.credit_limit * 0.9)
ORDER BY pct_of_credit_limit DESC;

-- 8a. Credit Risk Segmentation
SELECT 
    u.id AS customer_id,
    u.gender,
    u.current_age,
    u.yearly_income,
    u.total_debt,
    u.credit_score,
    ROUND((u.total_debt / NULLIF(u.yearly_income, 0)), 2) AS debt_to_income_ratio,
    CASE
        WHEN (u.total_debt / NULLIF(u.yearly_income, 0)) > 0.5 AND u.credit_score < 600 THEN 'High Risk'
        WHEN (u.total_debt / NULLIF(u.yearly_income, 0)) BETWEEN 0.3 AND 0.5 OR (u.credit_score BETWEEN 600 AND 700) THEN 'Moderate Risk'
        WHEN (u.total_debt / NULLIF(u.yearly_income, 0)) < 0.3 AND u.credit_score > 700 THEN 'Low Risk'
        ELSE 'Unclassified'
    END AS risk_level
FROM users_data u
WHERE u.yearly_income IS NOT NULL 
  AND u.yearly_income > 0
ORDER BY risk_level DESC, debt_to_income_ratio DESC;

-- 8b. Debt Distribution and Risk Grouping
SELECT 
    u.id AS customer_id,
    u.gender,
    u.yearly_income,
    u.total_debt,
    u.credit_score,
    ROUND((u.total_debt / NULLIF(u.yearly_income, 0)), 2) AS debt_to_income_ratio,
    CASE 
        WHEN u.total_debt < 10000 THEN 'Low Debt (₦0–10K)'
        WHEN u.total_debt BETWEEN 10000 AND 50000 THEN 'Moderate Debt (₦10K–50K)'
        WHEN u.total_debt BETWEEN 50001 AND 100000 THEN 'High Debt (₦50K–100K)'
        WHEN u.total_debt > 100000 THEN 'Very High Debt (₦100K+)'
        ELSE 'Unclassified'
    END AS debt_category
FROM users_data u
WHERE u.total_debt IS NOT NULL
ORDER BY u.total_debt DESC;

-- Summary View (to get the distribution counts)
SELECT 
    CASE 
        WHEN total_debt < 10000 THEN 'Low Debt (₦0–10K)'
        WHEN total_debt BETWEEN 10000 AND 50000 THEN 'Moderate Debt (₦10K–50K)'
        WHEN total_debt BETWEEN 50001 AND 100000 THEN 'High Debt (₦50K–100K)'
        WHEN total_debt > 100000 THEN 'Very High Debt (₦100K+)'
        ELSE 'Unclassified'
    END AS debt_category,
    COUNT(*) AS num_customers,
    ROUND(AVG(total_debt), 2) AS avg_debt,
    ROUND(AVG(credit_score), 0) AS avg_credit_score
FROM users_data
GROUP BY 
    CASE 
        WHEN total_debt < 10000 THEN 'Low Debt (₦0–10K)'
        WHEN total_debt BETWEEN 10000 AND 50000 THEN 'Moderate Debt (₦10K–50K)'
        WHEN total_debt BETWEEN 50001 AND 100000 THEN 'High Debt (₦50K–100K)'
        WHEN total_debt > 100000 THEN 'Very High Debt (₦100K+)'
        ELSE 'Unclassified'
    END
ORDER BY num_customers DESC;









-- 6. High-Value Transactions (Potential Fraud)
SELECT 
    t.id, t.client_id, t.amount, t.merchant_city, m.Description
FROM transactions_data t
JOIN mcc_codes m ON t.mcc = m.mcc_id
WHERE t.amount > (SELECT AVG(amount) * 3 FROM transactions_data); -- threshold: 3x average

-- 5. Credit Risk Customers
SELECT 
    u.id,
    u.credit_score,
    u.yearly_income,
    u.total_debt,
    ROUND(CAST(u.total_debt AS FLOAT) / NULLIF(u.yearly_income, 0), 2) AS debt_to_income_ratio
FROM users_data u
WHERE u.credit_score < 600 OR (u.total_debt / NULLIF(u.yearly_income, 0)) > 0.6;



