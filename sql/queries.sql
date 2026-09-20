-- Phase 2 queries against used_cars.db
-- Same questions as the phase 1 notebook, written as SQL, plus a couple only SQL makes easy.

-- 1. The basics
SELECT COUNT(*) AS total_listings,
       MIN(price) AS min_price,
       MAX(price) AS max_price,
       ROUND(AVG(price), 0) AS avg_price
FROM listings;

-- 2. Most common brands, and what they go for (aggregation + HAVING)
-- HAVING filters on the aggregate itself (n >= 15), which WHERE can't do.
SELECT brand,
       COUNT(*) AS n,
       ROUND(AVG(price), 0) AS avg_price
FROM listings
GROUP BY brand
HAVING n >= 15
ORDER BY avg_price DESC;

-- 3. Clean title vs. salvage insurance
SELECT title_status,
       COUNT(*) AS n,
       ROUND(AVG(price), 0) AS avg_price,
       ROUND(MIN(price), 0) AS min_price,
       ROUND(MAX(price), 0) AS max_price
FROM listings
GROUP BY title_status;

-- 4. Does region of the country matter? (JOIN to the regions lookup table)
SELECT r.region,
       COUNT(*) AS n,
       ROUND(AVG(l.price), 0) AS avg_price
FROM listings l
JOIN regions r ON l.state = r.state
GROUP BY r.region
ORDER BY avg_price DESC;

-- 5. Rank brands by price within each title_status (window function)
-- A plain GROUP BY can't rank rows within a group at the same time as aggregating them; a window function can.
SELECT brand,
       title_status,
       ROUND(AVG(price), 0) AS avg_price,
       RANK() OVER (PARTITION BY title_status ORDER BY AVG(price) DESC) AS price_rank
FROM listings
GROUP BY brand, title_status
HAVING COUNT(*) >= 10
ORDER BY title_status, price_rank;

-- 6. Which brands sell above the overall average price? (subquery)
SELECT brand,
       ROUND(AVG(price), 0) AS avg_price
FROM listings
GROUP BY brand
HAVING avg_price > (SELECT AVG(price) FROM listings)
ORDER BY avg_price DESC;
