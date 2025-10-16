CREATE VIEW vw_TransactionRiskAnalysis AS
SELECT
    t.id AS transaction_id,
    t.client_id,
    t.card_id,
    t.date,
    t.amount,
    t.merchant_city,
    t.merchant_state,
    t.use_chip,
    t.errors,

    -- Merchant & Category Info
    m.Description AS merchant_category,

    -- Card Info
    c.card_brand,
    c.card_type,
    c.credit_limit,

    -- Customer Info
    u.gender,
    u.current_age,
    u.yearly_income,
    u.total_debt,
    u.credit_score,

    ------------------------------------------------------------------
    -- SPENDING METRICS
    ------------------------------------------------------------------
    ROUND(AVG(t.amount) OVER (), 2) AS avg_transaction_value_global,
    ROUND(AVG(t.amount) OVER (PARTITION BY t.merchant_state), 2) AS avg_transaction_value_state,
    COUNT(t.id) OVER (PARTITION BY m.Description) AS total_transactions_by_category,
    SUM(t.amount) OVER (PARTITION BY m.Description) AS total_spent_by_category,
    SUM(t.amount) OVER (PARTITION BY t.merchant_state) AS total_spent_by_state,

    ------------------------------------------------------------------
    -- ERROR / FAILURE METRICS
    ------------------------------------------------------------------
    COUNT(t.id) OVER (PARTITION BY t.merchant_state) AS total_txn_state,
    SUM(CASE WHEN t.errors IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY t.merchant_state) AS failed_txn_state,
    ROUND(
        100.0 * SUM(CASE WHEN t.errors IS NOT NULL THEN 1 ELSE 0 END) 
        OVER (PARTITION BY t.merchant_state) 
        / NULLIF(COUNT(t.id) OVER (PARTITION BY t.merchant_state), 0),
        2
    ) AS failure_rate_state_percent,

    COUNT(t.id) OVER (PARTITION BY m.Description) AS total_txn_mcc,
    SUM(CASE WHEN t.errors IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY m.Description) AS failed_txn_mcc,
    ROUND(
        100.0 * SUM(CASE WHEN t.errors IS NOT NULL THEN 1 ELSE 0 END)
        OVER (PARTITION BY m.Description)
        / NULLIF(COUNT(t.id) OVER (PARTITION BY m.Description), 0),
        2
    ) AS failure_rate_mcc_percent,

    ------------------------------------------------------------------
    -- HIGH-VALUE TRANSACTION FLAGS
    ------------------------------------------------------------------
    CASE 
        WHEN t.amount > (SELECT AVG(amount) * 3 FROM transactions_data)
        THEN 'High Value (Global Threshold)'
        WHEN t.amount > (u.yearly_income / 12.0) * 0.5
        THEN 'High Value (≥50% Monthly Income)'
        WHEN t.amount > (c.credit_limit * 0.9)
        THEN 'High Value (≥90% Credit Limit)'
        ELSE 'Normal Transaction'
    END AS transaction_flag,

    ROUND((t.amount / NULLIF(c.credit_limit, 0)) * 100, 2) AS pct_of_credit_limit,

    ------------------------------------------------------------------
    -- RISK SEGMENTATION
    ------------------------------------------------------------------
    ROUND((u.total_debt / NULLIF(u.yearly_income, 0)), 2) AS debt_to_income_ratio,
    CASE
        WHEN (u.total_debt / NULLIF(u.yearly_income, 0)) > 0.5 AND u.credit_score < 600 THEN 'High Risk'
        WHEN (u.total_debt / NULLIF(u.yearly_income, 0)) BETWEEN 0.3 AND 0.5 
             OR (u.credit_score BETWEEN 600 AND 700) THEN 'Moderate Risk'
        WHEN (u.total_debt / NULLIF(u.yearly_income, 0)) < 0.3 AND u.credit_score > 700 THEN 'Low Risk'
        ELSE 'Unclassified'
    END AS risk_level,

    ------------------------------------------------------------------
    -- DEBT CATEGORY GROUPING
    ------------------------------------------------------------------
    CASE 
        WHEN u.total_debt < 10000 THEN 'Low Debt (₦0–10K)'
        WHEN u.total_debt BETWEEN 10000 AND 50000 THEN 'Moderate Debt (₦10K–50K)'
        WHEN u.total_debt BETWEEN 50001 AND 100000 THEN 'High Debt (₦50K–100K)'
        WHEN u.total_debt > 100000 THEN 'Very High Debt (₦100K+)'
        ELSE 'Unclassified'
    END AS debt_category

FROM transactions_data t
LEFT JOIN mcc_codes m ON t.mcc = m.mcc_id
LEFT JOIN cards_data c ON t.card_id = c.id
LEFT JOIN users_data u ON t.client_id = u.id
WHERE t.amount > 0;


