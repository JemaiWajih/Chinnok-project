-- 1.1 TABLES AND ROW COUNTS

SELECT 'Artist' AS table_name, COUNT(*) AS row_count FROM Artist
UNION ALL
SELECT 'Album', COUNT(*) FROM Album
UNION ALL
SELECT 'Track', COUNT(*) FROM Track
UNION ALL
SELECT 'Genre', COUNT(*) FROM Genre
UNION ALL
SELECT 'MediaType', COUNT(*) FROM MediaType
UNION ALL
SELECT 'Customer', COUNT(*) FROM Customer
UNION ALL
SELECT 'Employee', COUNT(*) FROM Employee
UNION ALL
SELECT 'Invoice', COUNT(*) FROM Invoice
UNION ALL
SELECT 'InvoiceLine', COUNT(*) FROM InvoiceLine;

-- -----------------------------------------------------------------------------
-- 1.2 SALES DATE RANGE

SELECT
    COUNT(*) AS total_invoices,
    MIN(InvoiceDate) AS first_invoice,
    MAX(InvoiceDate) AS last_invoice
FROM Invoice;

-- -----------------------------------------------------------------------------
-- 1.3 HOW THE SALES TABLES CONNECT

SELECT
    i.InvoiceId,
    i.InvoiceDate,
    c.Country,
    t.Name AS track_name,
    al.Title AS album_title,
    ar.Name AS artist_name,
    g.Name AS genre,
    il.UnitPrice,
    il.Quantity
FROM InvoiceLine il
JOIN Invoice  i  ON i.InvoiceId  = il.InvoiceId
JOIN Customer c  ON c.CustomerId = i.CustomerId
JOIN Track    t  ON t.TrackId    = il.TrackId
LEFT JOIN Album  al ON al.AlbumId  = t.AlbumId
LEFT JOIN Artist ar ON ar.ArtistId = al.ArtistId
LEFT JOIN Genre  g  ON g.GenreId   = t.GenreId
LIMIT 10;

-- -----------------------------------------------------------------------------
-- 1.4 DATA QUALITY: DOES LINE REVENUE MATCH INVOICE TOTALS?

SELECT
    (SELECT ROUND(SUM(UnitPrice * Quantity), 2) FROM InvoiceLine) AS line_revenue,
    (SELECT ROUND(SUM(Total), 2) FROM Invoice)                    AS invoice_revenue;

-- -----------------------------------------------------------------------------
-- 1.5 DATA QUALITY: NULLS AND ORPHANS

SELECT
    (SELECT COUNT(*) FROM Track WHERE AlbumId IS NULL) AS tracks_without_album,
    (SELECT COUNT(*) FROM Track WHERE GenreId IS NULL) AS tracks_without_genre,
    (SELECT COUNT(*) FROM Customer WHERE Country IS NULL) AS customers_without_country,
    (SELECT COUNT(*)
       FROM InvoiceLine il
       LEFT JOIN Track t ON t.TrackId = il.TrackId
      WHERE t.TrackId IS NULL) AS orphan_invoice_lines;

-- -----------------------------------------------------------------------------
-- 1.6 CATALOG VS SOLD
-- How many tracks exist, and how many were actually bought at least once?

SELECT
    COUNT(*) AS tracks_in_catalog,
    COUNT(CASE WHEN sold.TrackId IS NOT NULL THEN 1 END) AS tracks_sold,
    COUNT(CASE WHEN sold.TrackId IS NULL THEN 1 END)     AS tracks_never_sold
FROM Track t
LEFT JOIN (
    SELECT DISTINCT TrackId
    FROM InvoiceLine
) sold
    ON sold.TrackId = t.TrackId;


-- -----------------------------------------------------------------------------
-- 1.7 PRICING AND QUANTITY PROFILE

SELECT
    UnitPrice,
    Quantity,
    COUNT(*) AS n_lines,
    ROUND(SUM(UnitPrice * Quantity), 2) AS revenue
FROM InvoiceLine
GROUP BY UnitPrice, Quantity
ORDER BY UnitPrice, Quantity;

-- -----------------------------------------------------------------------------
-- 1.8 DATA QUALITY: JOIN SAFETY AND DUPLICATE NAMES

SELECT
    (SELECT COUNT(*)
       FROM InvoiceLine il
       JOIN Track t ON t.TrackId = il.TrackId
      WHERE il.UnitPrice <> t.UnitPrice) AS invoice_lines_price_mismatch,

    (SELECT COUNT(*)
       FROM Invoice i
      WHERE NOT EXISTS (
            SELECT 1
            FROM InvoiceLine il
            WHERE il.InvoiceId = i.InvoiceId
      )) AS invoices_without_lines,

    (SELECT COUNT(*)
       FROM Customer c
      WHERE NOT EXISTS (
            SELECT 1
            FROM Invoice i
            WHERE i.CustomerId = c.CustomerId
      )) AS customers_without_invoices,

    (SELECT COUNT(*)
       FROM (
            SELECT Name
            FROM Track
            GROUP BY Name
            HAVING COUNT(*) > 1
       )) AS duplicate_track_names;

-- -----------------------------------------------------------------------------
-- 1.9 MONTH COVERAGE PER YEAR

SELECT
    STRFTIME('%Y', InvoiceDate) AS year,
    COUNT(DISTINCT STRFTIME('%Y-%m', InvoiceDate)) AS months_with_sales
FROM Invoice
GROUP BY year
ORDER BY year;

