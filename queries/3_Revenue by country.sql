-- 3.1 REVENUE BY CUSTOMER COUNTRY

DROP VIEW IF EXISTS v_sales_by_country;

CREATE VIEW v_sales_by_country AS
SELECT
    c.Country AS country,
    COUNT(DISTINCT c.CustomerId) AS n_customers,
    COUNT(DISTINCT i.InvoiceId)  AS n_invoices,
    ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS revenue
FROM Customer c
JOIN Invoice i      ON i.CustomerId = c.CustomerId
JOIN InvoiceLine il ON il.InvoiceId = i.InvoiceId
GROUP BY c.Country;

SELECT
    country,
    n_customers,
    n_invoices,
    revenue
FROM v_sales_by_country
ORDER BY revenue DESC;

-- -----------------------------------------------------------------------------
-- 3.2 COUNTRY KPIs

SELECT
    country,
    n_customers,
    n_invoices,
    revenue,
    ROUND(revenue / n_customers, 2) AS revenue_per_customer,
    ROUND(revenue / n_invoices, 2)  AS avg_invoice_value
FROM v_sales_by_country
ORDER BY revenue_per_customer DESC;

-- -----------------------------------------------------------------------------
-- 3.3 SHARE OF TOTAL REVENUE + CUMULATIVE SHARE

WITH country_rev AS (
    SELECT country, revenue
    FROM v_sales_by_country
),
total AS (
    SELECT SUM(revenue) AS total_revenue
    FROM country_rev
)

SELECT
    cr.country,
    cr.revenue,
    ROUND(100.0 * cr.revenue / t.total_revenue, 2) AS share_percent,
    ROUND(
        100.0 * SUM(cr.revenue) OVER (
            ORDER BY cr.revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) / t.total_revenue,
        2
    ) AS cumulative_share_percent
FROM country_rev cr
CROSS JOIN total t
ORDER BY cr.revenue DESC;

-- -----------------------------------------------------------------------------
-- 3.4 REGION GROUPING

SELECT
    CASE
        WHEN country IN ('USA', 'Canada')
            THEN 'North America'
        WHEN country IN ('Brazil', 'Argentina', 'Chile')
            THEN 'South America'
        WHEN country IN ('Australia', 'India')
            THEN 'Asia-Pacific'
        WHEN country IN ('Austria', 'Belgium', 'Czech Republic', 'Denmark', 'Finland',
                         'France', 'Germany', 'Hungary', 'Ireland', 'Italy',
                         'Netherlands', 'Norway', 'Poland', 'Portugal', 'Spain',
                         'Sweden', 'United Kingdom')
            THEN 'Europe'
        ELSE 'Unmapped'
    END AS region,
    SUM(n_customers) AS n_customers,
    SUM(n_invoices)  AS n_invoices,
    ROUND(SUM(revenue), 2) AS revenue
FROM v_sales_by_country
GROUP BY region
ORDER BY revenue DESC;

-- -----------------------------------------------------------------------------
-- 3.5 TOP 3 GENRES IN EACH OF THE TOP 3 COUNTRIES

WITH top_countries AS (
    SELECT country
    FROM v_sales_by_country
    ORDER BY revenue DESC
    LIMIT 3
),

country_genre AS (
    SELECT
        c.Country AS country,
        g.Name AS genre,
        ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS revenue
    FROM InvoiceLine il
    JOIN Invoice i  ON i.InvoiceId  = il.InvoiceId
    JOIN Customer c ON c.CustomerId = i.CustomerId
    JOIN Track t    ON t.TrackId    = il.TrackId
    JOIN Genre g    ON g.GenreId    = t.GenreId
    WHERE c.Country IN (SELECT country FROM top_countries)
    GROUP BY c.Country, g.GenreId, g.Name
),

ranked AS (
    SELECT
        country,
        genre,
        revenue,
        ROW_NUMBER() OVER (
            PARTITION BY country
            ORDER BY revenue DESC, genre
        ) AS genre_rank
    FROM country_genre
)

SELECT
    country,
    genre_rank,
    genre,
    revenue
FROM ranked
WHERE genre_rank <= 3
ORDER BY country, genre_rank;
