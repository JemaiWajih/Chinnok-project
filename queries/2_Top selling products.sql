-- =============================================================================
-- PART 2: TOP SELLING PRODUCTS
-- =============================================================================

-- 2.1 TOP 10 TRACKS BY REVENUE

SELECT
    DENSE_RANK() OVER (ORDER BY SUM(il.UnitPrice * il.Quantity) DESC) AS revenue_rank,
    t.TrackId,
    t.Name AS track_name,
    ar.Name AS artist_name,
    SUM(il.Quantity) AS units_sold,
    ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS revenue
FROM InvoiceLine il
JOIN Track t        ON t.TrackId   = il.TrackId
LEFT JOIN Album al  ON al.AlbumId  = t.AlbumId
LEFT JOIN Artist ar ON ar.ArtistId = al.ArtistId
GROUP BY t.TrackId, t.Name, ar.Name
ORDER BY revenue DESC, units_sold DESC, t.Name
LIMIT 10;

-- -----------------------------------------------------------------------------
-- 2.2 TOP 10 ALBUMS BY REVENUE

SELECT
    al.AlbumId,
    al.Title AS album_title,
    ar.Name AS artist_name,
    SUM(il.Quantity) AS units_sold,
    COUNT(DISTINCT il.TrackId) AS distinct_tracks_sold,
    ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS revenue
FROM InvoiceLine il
JOIN Track t   ON t.TrackId   = il.TrackId
JOIN Album al  ON al.AlbumId  = t.AlbumId
JOIN Artist ar ON ar.ArtistId = al.ArtistId
GROUP BY al.AlbumId, al.Title, ar.Name
ORDER BY revenue DESC
LIMIT 10;

-- -----------------------------------------------------------------------------
-- 2.3 TOP 10 ARTISTS BY REVENUE

SELECT
    ar.ArtistId,
    ar.Name AS artist_name,
    SUM(il.Quantity) AS units_sold,
    ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS revenue
FROM InvoiceLine il
JOIN Track t   ON t.TrackId   = il.TrackId
JOIN Album al  ON al.AlbumId  = t.AlbumId
JOIN Artist ar ON ar.ArtistId = al.ArtistId
GROUP BY ar.ArtistId, ar.Name
ORDER BY revenue DESC
LIMIT 10;

-- -----------------------------------------------------------------------------
-- 2.4 REVENUE BY GENRE (with share of total)

SELECT
    g.Name AS genre,
    SUM(il.Quantity) AS units_sold,
    ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS revenue,
    ROUND(
        100.0 * SUM(il.UnitPrice * il.Quantity)
        / (SELECT SUM(UnitPrice * Quantity) FROM InvoiceLine),
        2
    ) AS revenue_share_percent
FROM InvoiceLine il
JOIN Track t ON t.TrackId = il.TrackId
JOIN Genre g ON g.GenreId = t.GenreId
GROUP BY g.GenreId, g.Name
ORDER BY revenue DESC;

-- -----------------------------------------------------------------------------
-- 2.5 REVENUE BY MEDIA TYPE

SELECT
    m.Name AS media_type,
    SUM(il.Quantity) AS units_sold,
    ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS revenue
FROM InvoiceLine il
JOIN Track t      ON t.TrackId      = il.TrackId
JOIN MediaType m  ON m.MediaTypeId  = t.MediaTypeId
GROUP BY m.MediaTypeId, m.Name
ORDER BY revenue DESC;

-- -----------------------------------------------------------------------------
-- 2.6 TRACKS THAT NEVER SOLD (bottom of the catalog)

SELECT
    t.TrackId,
    t.Name AS track_name,
    g.Name AS genre
FROM Track t
LEFT JOIN InvoiceLine il ON il.TrackId = t.TrackId
LEFT JOIN Genre g        ON g.GenreId  = t.GenreId
WHERE il.InvoiceLineId IS NULL
ORDER BY g.Name, t.Name
LIMIT 20;