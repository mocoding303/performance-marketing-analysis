-- ============================================
-- Meta Ads Performance Analysis
-- Dataset: 90-day e-commerce Meta Ads data
-- Tool: PostgreSQL 17 / pgAdmin 4
-- Author: Mouhssine
-- Date: Q1 2025
-- ============================================


-- ============================================
-- Table Setup
-- ============================================

CREATE TABLE meta_ads (
    date DATE,
    campaign_name VARCHAR(100),
    placement VARCHAR(50),
    amount_spent NUMERIC(10,2),
    impressions INTEGER,
    reach INTEGER,
    clicks INTEGER,
    ctr NUMERIC(6,2),
    cpc NUMERIC(6,2),
    purchases INTEGER,
    cost_per_purchase NUMERIC(10,2),
    purchase_value NUMERIC(10,2),
    roas NUMERIC(6,2)
);

ALTER DATABASE marketing_analytics SET datestyle = 'ISO, DMY';


-- ============================================
-- Question 1 (Descriptive): Which campaign generated the highest ROAS?
-- ============================================

SELECT campaign_name,
       ROUND(AVG(roas), 2) AS avg_roas
FROM meta_ads
GROUP BY 1
ORDER BY 2 DESC;

/*
FINDING: Prospecting consumes 39% of total budget but delivers the lowest ROAS at 1.41x,
while Retargeting receives only 19% of budget yet delivers 6.19x —
a 4.4x performance gap on less than half the spend.
*/


-- ============================================
-- Question 2 (Diagnostic): Why does retargeting outperform prospecting?
-- Is it CTR, CPC, or conversion rate?
-- ============================================

SELECT campaign_name,
       ROUND(SUM(purchases)::NUMERIC / SUM(clicks)::NUMERIC * 100, 2) AS conversion_rate,
       ROUND(AVG(ctr), 2) AS avg_ctr,
       ROUND(AVG(cpc), 2) AS avg_cpc
FROM meta_ads
GROUP BY 1
ORDER BY 2 DESC;

/*
FINDING: Across all four campaigns, KPIs degrade consistently as audience warmth decreases —
from Retargeting (CVR 5.19%, CTR 3.05%, CPC 0.53) to Prospecting (CVR 2.04%, CTR 1.48%, CPC 0.85) —
confirming that audience temperature is the primary driver of ROAS performance,
not creative or placement.
*/


-- ============================================
-- Question 3 (Descriptive): Which day of the week drives the most purchases?
-- ============================================

SELECT TO_CHAR(date, 'Day') AS day_of_week,
       SUM(purchases) AS total_purchases,
       ROUND(AVG(roas), 2) AS avg_roas
FROM meta_ads
GROUP BY 1
ORDER BY 2 DESC;

/*
FINDING: Weekends generate higher purchase volume (Sat: 85, Sun: 84) and slightly superior ROAS
(3.51x and 3.43x) compared to weekdays — suggesting a modest budget shift toward weekend days,
validated by an A/B test on weekday audience targeting before committing to a full reallocation.
*/


-- ============================================
-- Question 4 (Descriptive): Which placement delivers the lowest CPA?
-- ============================================

SELECT placement,
       ROUND(SUM(amount_spent) / SUM(purchases), 2) AS cpa,
       ROUND(AVG(roas), 2) AS avg_roas
FROM meta_ads
GROUP BY 1
ORDER BY 2 ASC, 3 DESC;

/*
FINDING: Instagram Stories delivers the lowest CPA at 10.06 and highest ROAS at 6.41x,
driven by its native browsing format that matches user decision-making behaviour.
Budget should be shifted toward Stories, while Reels creative should be A/B tested
to address its high CPA of 26.97 and weak ROAS of 2.35x.
*/


-- ============================================
-- Question 5 (Prescriptive): If we move 1,000 from Prospecting to Retargeting,
-- how much extra revenue do we generate?
-- ============================================

WITH meta_analysis AS (
    SELECT
        campaign_name,
        SUM(amount_spent) AS current_spend,
        SUM(purchase_value) AS current_revenue,
        ROUND(AVG(roas), 2) AS avg_roas,
        CASE
            WHEN campaign_name = 'Retargeting — Website Visitors'
                THEN SUM(amount_spent) + 1000
            WHEN campaign_name = 'Prospecting — Broad Audiences'
                THEN SUM(amount_spent) - 1000
            ELSE SUM(amount_spent)
        END AS projected_spend,
        ROUND(
            CASE
                WHEN campaign_name = 'Retargeting — Website Visitors'
                    THEN SUM(amount_spent) + 1000
                WHEN campaign_name = 'Prospecting — Broad Audiences'
                    THEN SUM(amount_spent) - 1000
                ELSE SUM(amount_spent)
            END * AVG(roas), 2
        ) AS projected_revenue
    FROM meta_ads
    GROUP BY 1
)
SELECT
    campaign_name,
    current_spend,
    current_revenue,
    avg_roas,
    projected_spend,
    projected_revenue,
    ROUND(projected_revenue - current_revenue, 2) AS revenue_difference
FROM meta_analysis
ORDER BY revenue_difference DESC;

/*
FINDING: Reallocating 1,000 from Prospecting to Retargeting generates a net revenue gain
of 4,738 — a 44% return on the reallocation decision itself.
Prospecting loses 1,434 in revenue but Retargeting gains 6,214,
resulting in a positive net impact without increasing total budget.
*/
