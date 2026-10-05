-- 4.1 MONTHLY REVENUE VIEW

DROP VIEW IF EXISTS v_monthly_sales;

CREATE VIEW v_monthly_sales AS
SELECT
    STRFTIME('%Y-%m', i.InvoiceDate) AS year_month,
    CAST(STRFTIME('%Y', i.InvoiceDate) AS INTEGER) AS year,
    CAST(STRFTIME('%m', i.InvoiceDate) AS INTEGER) AS month,
    COUNT(DISTINCT i.InvoiceId) AS n_invoices,
    SUM(il.Quantity) AS units_sold,
    ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS revenue
FROM Invoice i
JOIN InvoiceLine il ON il.InvoiceId = i.InvoiceId
GROUP BY year_month, year, month;

SELECT
    year_month,
    n_invoices,
    units_sold,
    revenue
FROM v_monthly_sales
ORDER BY year_month;

-- -----------------------------------------------------------------------------
-- 4.2 MONTH-OVER-MONTH GROWTH (LAG)

SELECT
    year_month,
    revenue,
    LAG(revenue) OVER (ORDER BY year_month) AS previous_month_revenue,
    ROUND(revenue - LAG(revenue) OVER (ORDER BY year_month), 2) AS change_amount,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY year_month))
        / NULLIF(LAG(revenue) OVER (ORDER BY year_month), 0),
        2
    ) AS mom_growth_percent
FROM v_monthly_sales
ORDER BY year_month;

-- -----------------------------------------------------------------------------
-- 4.3 YEARLY REVENUE AND YEAR-OVER-YEAR GROWTH

WITH yearly AS (
    SELECT
        year,
        SUM(revenue) AS revenue,
        SUM(n_invoices) AS n_invoices
    FROM v_monthly_sales
    GROUP BY year
)

SELECT
    year,
    ROUND(revenue, 2) AS revenue,
    n_invoices,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY year))
        / NULLIF(LAG(revenue) OVER (ORDER BY year), 0),
        2
    ) AS yoy_growth_percent
FROM yearly
ORDER BY year;

-- -----------------------------------------------------------------------------
-- 4.4 RUNNING (CUMULATIVE) REVENUE

SELECT
    year_month,
    revenue,
    ROUND(
        SUM(revenue) OVER (
            ORDER BY year_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS cumulative_revenue
FROM v_monthly_sales
ORDER BY year_month;

-- -----------------------------------------------------------------------------
-- 4.5 3-MONTH MOVING AVERAGE

SELECT
    year_month,
    revenue,
    ROUND(
        AVG(revenue) OVER (
            ORDER BY year_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_avg_3m
FROM v_monthly_sales
ORDER BY year_month;

-- -----------------------------------------------------------------------------
-- 4.6 SEASONALITY

SELECT
    month,
    CASE month
        WHEN 1  THEN 'January'
        WHEN 2  THEN 'February'
        WHEN 3  THEN 'March'
        WHEN 4  THEN 'April'
        WHEN 5  THEN 'May'
        WHEN 6  THEN 'June'
        WHEN 7  THEN 'July'
        WHEN 8  THEN 'August'
        WHEN 9  THEN 'September'
        WHEN 10 THEN 'October'
        WHEN 11 THEN 'November'
        WHEN 12 THEN 'December'
    END AS month_name,
    COUNT(*) AS months_observed,
    ROUND(AVG(revenue), 2) AS avg_monthly_revenue
FROM v_monthly_sales
GROUP BY month
ORDER BY month;

-- -----------------------------------------------------------------------------
-- 4.7 BEST AND WORST MONTH OF EACH YEAR

WITH ranked_months AS (
    SELECT
        year,
        year_month,
        revenue,
        ROW_NUMBER() OVER (PARTITION BY year ORDER BY revenue DESC, year_month) AS best_rank,
        ROW_NUMBER() OVER (PARTITION BY year ORDER BY revenue ASC,  year_month) AS worst_rank
    FROM v_monthly_sales
)

SELECT
    year,
    year_month,
    revenue,
    'best month' AS label
FROM ranked_months
WHERE best_rank = 1

UNION ALL

SELECT
    year,
    year_month,
    revenue,
    'worst month' AS label
FROM ranked_months
WHERE worst_rank = 1

ORDER BY year, revenue DESC;