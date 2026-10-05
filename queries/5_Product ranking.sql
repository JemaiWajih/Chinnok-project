-- 5.1 PRODUCT SALES VIEW

DROP VIEW IF EXISTS v_product_sales;

CREATE VIEW v_product_sales AS
SELECT
    t.TrackId,
    t.Name AS track_name,
    ar.Name AS artist_name,
    g.Name AS genre,
    SUM(il.Quantity) AS units_sold,
    ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS revenue
FROM InvoiceLine il
JOIN Track t        ON t.TrackId   = il.TrackId
LEFT JOIN Album al  ON al.AlbumId  = t.AlbumId
LEFT JOIN Artist ar ON ar.ArtistId = al.ArtistId
LEFT JOIN Genre g   ON g.GenreId   = t.GenreId
GROUP BY t.TrackId, t.Name, ar.Name, g.Name;

-- -----------------------------------------------------------------------------
-- 5.2 ROW_NUMBER vs RANK vs DENSE_RANK

SELECT
    track_name,
    artist_name,
    revenue,
    ROW_NUMBER() OVER (ORDER BY revenue DESC, track_name) AS row_num,
    RANK()       OVER (ORDER BY revenue DESC)             AS rank_with_gaps,
    DENSE_RANK() OVER (ORDER BY revenue DESC)             AS dense_rank
FROM v_product_sales
ORDER BY revenue DESC, track_name
LIMIT 15;

-- -----------------------------------------------------------------------------
-- 5.3 TOP 3 TRACKS INSIDE EACH GENRE

WITH ranked_by_genre AS (
    SELECT
        genre,
        track_name,
        artist_name,
        units_sold,
        revenue,
        ROW_NUMBER() OVER (
            PARTITION BY genre
            ORDER BY revenue DESC, units_sold DESC, track_name
        ) AS genre_rank
    FROM v_product_sales
    WHERE genre IS NOT NULL
)

SELECT
    genre,
    genre_rank,
    track_name,
    artist_name,
    units_sold,
    revenue
FROM ranked_by_genre
WHERE genre_rank <= 3
ORDER BY genre, genre_rank;

-- -----------------------------------------------------------------------------
-- 5.4 BEST-SELLING TRACK IN EACH COUNTRY

WITH country_track_sales AS (
    SELECT
        c.Country AS country,
        t.Name AS track_name,
        SUM(il.Quantity) AS units_sold,
        ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS revenue
    FROM InvoiceLine il
    JOIN Invoice i  ON i.InvoiceId  = il.InvoiceId
    JOIN Customer c ON c.CustomerId = i.CustomerId
    JOIN Track t    ON t.TrackId    = il.TrackId
    GROUP BY c.Country, t.TrackId, t.Name
),

ranked AS (
    SELECT
        country,
        track_name,
        units_sold,
        revenue,
        ROW_NUMBER() OVER (
            PARTITION BY country
            ORDER BY revenue DESC, units_sold DESC, track_name
        ) AS rn
    FROM country_track_sales
)

SELECT
    country,
    track_name,
    units_sold,
    revenue
FROM ranked
WHERE rn = 1
ORDER BY revenue DESC, country;

-- -----------------------------------------------------------------------------
-- 5.5 ARTIST RANKING WITHIN EACH GENRE

WITH artist_genre_sales AS (
    SELECT
        genre,
        artist_name,
        SUM(revenue) AS revenue
    FROM v_product_sales
    WHERE genre IS NOT NULL
      AND artist_name IS NOT NULL
    GROUP BY genre, artist_name
),

ranked AS (
    SELECT
        genre,
        artist_name,
        ROUND(revenue, 2) AS revenue,
        RANK() OVER (
            PARTITION BY genre
            ORDER BY revenue DESC
        ) AS artist_rank
    FROM artist_genre_sales
)

SELECT
    genre,
    artist_name,
    revenue,
    artist_rank
FROM ranked
WHERE artist_rank <= 2
ORDER BY genre, artist_rank, artist_name;

-- -----------------------------------------------------------------------------
-- 5.6 ARTIST ABC CLASSIFICATION (cumulative revenue share)

WITH artist_sales AS (
    SELECT
        artist_name,
        SUM(revenue) AS revenue
    FROM v_product_sales
    WHERE artist_name IS NOT NULL
    GROUP BY artist_name
),

cumulative AS (
    SELECT
        artist_name,
        revenue,
        100.0 * SUM(revenue) OVER (
            ORDER BY revenue DESC, artist_name
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) / SUM(revenue) OVER () AS cumulative_share
    FROM artist_sales
),

classified AS (
    SELECT
        artist_name,
        revenue,
        cumulative_share,
        CASE
            WHEN cumulative_share <= 50 THEN 'A'
            WHEN cumulative_share <= 80 THEN 'B'
            ELSE 'C'
        END AS class
    FROM cumulative
)

SELECT
    class,
    COUNT(*) AS n_artists,
    ROUND(SUM(revenue), 2) AS class_revenue
FROM classified
GROUP BY class
ORDER BY class;

-- -----------------------------------------------------------------------------
-- 5.7 TOP ARTIST OF EACH YEAR

WITH artist_year AS (
    SELECT
        CAST(STRFTIME('%Y', i.InvoiceDate) AS INTEGER) AS year,
        ar.Name AS artist_name,
        ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS revenue
    FROM InvoiceLine il
    JOIN Invoice i ON i.InvoiceId = il.InvoiceId
    JOIN Track t   ON t.TrackId   = il.TrackId
    JOIN Album al  ON al.AlbumId  = t.AlbumId
    JOIN Artist ar ON ar.ArtistId = al.ArtistId
    GROUP BY year, ar.ArtistId, ar.Name
),

ranked AS (
    SELECT
        year,
        artist_name,
        revenue,
        ROW_NUMBER() OVER (
            PARTITION BY year
            ORDER BY revenue DESC, artist_name
        ) AS rn
    FROM artist_year
)

SELECT
    year,
    artist_name,
    revenue
FROM ranked
WHERE rn = 1
ORDER BY year;


-- -----------------------------------------------------------------------------
-- 5.8 RECONCILIATION CHECK (cross-validation)

SELECT
    (SELECT ROUND(SUM(Total), 2) FROM Invoice)                    AS invoice_total,
    (SELECT ROUND(SUM(revenue), 2) FROM v_sales_by_country)       AS by_country,
    (SELECT ROUND(SUM(revenue), 2) FROM v_monthly_sales)          AS by_month,
    (SELECT ROUND(SUM(revenue), 2) FROM v_product_sales)          AS by_product,
    (SELECT ROUND(SUM(il.UnitPrice * il.Quantity), 2)
       FROM InvoiceLine il
       JOIN Track t ON t.TrackId = il.TrackId
       JOIN Genre g ON g.GenreId = t.GenreId)                  AS by_genre;
