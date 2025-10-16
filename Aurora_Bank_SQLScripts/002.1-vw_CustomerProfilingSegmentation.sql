CREATE VIEW vw_CustomerProfilingSegmentation AS
SELECT
    u.id AS customer_id,
    u.gender,
    
    -- Compute Age Group
    CASE 
        WHEN u.current_age < 25 THEN '<25'
        WHEN u.current_age BETWEEN 25 AND 34 THEN '25–34'
        WHEN u.current_age BETWEEN 35 AND 44 THEN '35–44'
        WHEN u.current_age BETWEEN 45 AND 54 THEN '45–54'
        ELSE '55+'
    END AS age_group,

    -- Location and Geographical Buckets
    u.address,
    CAST(TRY_CAST(u.latitude AS FLOAT) AS INT) AS latitude_band,
    CAST(TRY_CAST(u.longitude AS FLOAT) AS INT) AS longitude_band,

    -- Financial Indicators
    u.yearly_income,
    u.total_debt,
    ROUND((u.total_debt / NULLIF(u.yearly_income, 0)) * 100, 2) AS debt_to_income_ratio,

    CASE 
        WHEN (u.total_debt / NULLIF(u.yearly_income, 0)) * 100 < 20 THEN 'Low Risk (<20%)'
        WHEN (u.total_debt / NULLIF(u.yearly_income, 0)) * 100 BETWEEN 20 AND 35 THEN 'Moderate Risk (20–35%)'
        WHEN (u.total_debt / NULLIF(u.yearly_income, 0)) * 100 BETWEEN 36 AND 49 THEN 'High Risk (36–49%)'
        WHEN (u.total_debt / NULLIF(u.yearly_income, 0)) * 100 >= 50 THEN 'Critical Risk (≥50%)'
        ELSE 'Unknown'
    END AS financial_health_category,

    -- Credit Score & Category
    u.credit_score,
    CASE 
        WHEN u.credit_score < 580 THEN 'Poor (<580)'
        WHEN u.credit_score BETWEEN 580 AND 669 THEN 'Fair (580–669)'
        WHEN u.credit_score BETWEEN 670 AND 739 THEN 'Good (670–739)'
        WHEN u.credit_score BETWEEN 740 AND 799 THEN 'Very Good (740–799)'
        ELSE 'Excellent (800–850)'
    END AS credit_category,

    -- Card Ownership
    COUNT(c.id) AS num_cards_owned,
    ROUND(AVG(c.credit_limit), 2) AS avg_credit_limit,
    COUNT(DISTINCT c.card_brand) AS distinct_card_brands,

    -- Average Account Age (in years)
    ROUND(AVG(
        DATEDIFF(
            YEAR,
            TRY_CONVERT(DATE, '01-' + c.acct_open_date, 106),
            GETDATE()
        )
    ), 2) AS avg_years_active

FROM users_data u
LEFT JOIN cards_data c 
    ON u.id = c.client_id

WHERE 
    (TRY_CONVERT(DATE, '01-' + c.acct_open_date, 106) IS NOT NULL 
     OR c.acct_open_date IS NULL)

GROUP BY 
    u.id, 
    u.gender, 
    u.current_age, 
    u.address, 
    u.latitude, 
    u.longitude, 
    u.yearly_income, 
    u.total_debt, 
    u.credit_score;
