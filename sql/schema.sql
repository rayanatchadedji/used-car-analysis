-- Schema for used_cars.db
-- Two tables: a fact table (listings) and a small lookup/dimension table (regions),
-- so brand/state-level questions can be written as real JOINs instead of one flat table.

CREATE TABLE listings (
    id            INTEGER PRIMARY KEY,
    price         INTEGER NOT NULL,
    brand         TEXT NOT NULL,
    model         TEXT,              -- unreliable field, see phase 1 notebook; kept but not used for analysis
    year          INTEGER NOT NULL,
    title_status  TEXT NOT NULL,     -- 'clean vehicle' or 'salvage insurance'
    mileage       INTEGER NOT NULL,
    color         TEXT,
    state         TEXT NOT NULL,
    country       TEXT NOT NULL
);

CREATE TABLE regions (
    state   TEXT PRIMARY KEY,        -- lowercase state/province name, matches listings.state
    region  TEXT NOT NULL            -- Northeast / Midwest / South / West / Canada
);

CREATE INDEX idx_listings_state ON listings(state);
CREATE INDEX idx_listings_brand ON listings(brand);
