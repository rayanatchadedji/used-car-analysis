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
-- A plain GROUP BY can't rank rows within a group at the same time as aggregating
-- them, but a window function can.
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

-- 4b. Sanity checks on the region result from query 4.
-- A raw AVG(price) per region credits the region column for anything that
-- happens to differ between regions. These two queries show why query 4 alone
-- is not a finding. The regression that controls for all of it at once is in
-- section 5b of notebooks/02_sql_analysis.ipynb (SQL can't fit a model).

-- 4b-i. Is a region's average really the region, or just its biggest state?
-- Pennsylvania is 59% of the Northeast, so "Northeast" and "Pennsylvania" are
-- nearly the same claim. The Midwest is far less concentrated.
SELECT r.region,
       COUNT(DISTINCT l.state)                               AS states,
       COUNT(*)                                              AS n,
       MAX(state_n.n)                                        AS biggest_state_n,
       ROUND(100.0 * MAX(state_n.n) / COUNT(*), 0)           AS biggest_state_pct
FROM listings l
JOIN regions r ON l.state = r.state
JOIN (SELECT state, COUNT(*) AS n FROM listings GROUP BY state) state_n
     ON state_n.state = l.state
GROUP BY r.region
ORDER BY biggest_state_pct DESC;

-- 4b-ii. Mileage was the real confounder, not salvage title: the South carries
-- ~14,000 more miles per listing than the Midwest, while the salvage share
-- differs by only a few points.
SELECT r.region,
       COUNT(*)                                                          AS n,
       ROUND(AVG(l.mileage), 0)                                          AS avg_mileage,
       ROUND(AVG(l.year), 1)                                             AS avg_year,
       ROUND(100.0 * SUM(CASE WHEN l.title_status = 'salvage insurance'
                              THEN 1 ELSE 0 END) / COUNT(*), 1)          AS salvage_pct,
       ROUND(AVG(l.price), 0)                                            AS avg_price
FROM listings l
JOIN regions r ON l.state = r.state
GROUP BY r.region
ORDER BY avg_price DESC;

-- 4b-iii. Spread WITHIN a region exceeds the gap between regions: Oklahoma
-- (South) outprices most of the Midwest, and Illinois outprices Missouri by
-- more than the Midwest-South gap itself.
SELECT r.region, l.state, COUNT(*) AS n, ROUND(AVG(l.price), 0) AS avg_price
FROM listings l
JOIN regions r ON l.state = r.state
WHERE l.title_status = 'clean vehicle'
GROUP BY r.region, l.state
HAVING COUNT(*) >= 20
ORDER BY r.region, avg_price DESC;
