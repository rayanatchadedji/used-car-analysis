# Used Car Price Analysis

A multi-phase project analyzing real used-car listings: what drives price, then extending into SQL/a dashboard, then a price-prediction model.

## Phase 1 — Exploratory Data Analysis (done)

`notebooks/01_eda.ipynb` cleans and analyzes ~2,500 real U.S. used-vehicle auction listings to answer: what actually drives price — mileage, model year, title status, or brand?

**Headline finding:** title status matters more than anything else tested. A salvage-insurance title cuts the median price by about 90% (from $18,000 to $1,900) — a much bigger effect than mileage (correlation -0.44) or model year (correlation +0.38). Full breakdown, charts, and the data-cleaning steps are in the notebook.

The raw data was messier than it first looked: $0 placeholder prices, duplicate VINs, a `condition` column that actually held auction time-remaining (not vehicle condition), a handful of non-passenger vehicles mixed in, and an unreliable `model` field. Cleaning that is part of the notebook, not a separate step.

## Phase 2 — SQL + database (done)

`notebooks/02_sql_analysis.ipynb` rebuilds the phase 1 questions as SQL against a real SQLite database (`data/processed/used_cars.db`) instead of pandas on a CSV, and adds two questions pandas alone made awkward:

- **Does region matter?** (a JOIN against a `regions` lookup table) — partly. A raw average puts Midwest and Northeast above the South, but only the Midwest result survives testing: **+$4,054 over the South** after controlling for mileage, year, title status and brand, still significant with state-clustered standard errors, and unchanged when its largest state is dropped. The apparent **Northeast** premium collapses to **+$76 (p=0.92)** once Pennsylvania — 59% of that region's listings — is excluded, so it was one state's market, not a region's. Region explains only ~3.5% of price variation either way, and within-region spread is larger than the gap between regions. Section 5b of the notebook shows the checks.
- **Do brands hold their price rank the same way across title status?** (a window function) — no: Chevrolet is mid-pack among clean titles but the cheapest major brand once salvaged.

Standalone SQL lives in `sql/schema.sql` (the two-table design) and `sql/queries.sql` (every query, commented). The notebook runs the same queries with narrative and charts.

The dashboard half of phase 2 is built: `dashboard/index.html` is a self-contained
interactive page implementing the spec at the end of `02_sql_analysis.ipynb` — KPI
tiles, average price by brand and by region, price against odometer colored by title
status, and one title-status filter scoping all of it. Open it directly, or rebuild
its embedded data from the database with `python dashboard/build_dashboard.py`.

The original spec named Power BI, which has no macOS build (and Power BI Service
needs a work or school account). `dashboard/TABLEAU.md` is a step-by-step guide for
rebuilding the same four visuals in Tableau Public, the free Mac-native equivalent,
for when a named BI tool is specifically wanted.

## Phase 3 — price-prediction model (done)

`notebooks/03_price_model.ipynb` combines mileage, year, title status, and brand into one model instead of looking at each alone, using a linear regression baseline plus a random forest for comparison.

**Headline finding:** controlling for mileage, year, and brand at once, the salvage-title price effect drops from phase 1's raw ~$16,700 gap to about $7,000 — meaning roughly half of that original gap was confounded with salvage listings also skewing toward higher mileage and different brands, not purely the title status itself.

Both models land around R² ≈ 0.3 (explaining roughly a third of price variation) — reported honestly rather than tuned to look better, with the likely reasons (missing features like trim/condition detail, auction-price noise, dataset size) and concrete next steps written up in the notebook.

## Coming next

- **Optional:** rebuild the dashboard in Tableau Public following `dashboard/TABLEAU.md`, if a named BI tool is wanted alongside the interactive page
- **Improve phase 3:** add the `region` feature (Midwest only — see 5b; the Northeast and West effects didn't hold), try gradient boosting, cross-validate instead of a single train/test split

## What's here

```
used-car-analysis/
├── data/
│   ├── raw/us_cars.csv              # original source data
│   └── processed/
│       ├── us_cars_clean.csv        # cleaned data (output of phase 1)
│       ├── used_cars.db             # SQLite database built from the cleaned data
│       └── tableau_listings.csv     # flattened export for Tableau (region join applied)
├── sql/
│   ├── schema.sql                   # table definitions
│   └── queries.sql                  # every phase 2 query, standalone
├── dashboard/
│   ├── index.html                   # interactive phase 2 dashboard (data embedded)
│   ├── build_dashboard.py           # regenerates that embedded data from used_cars.db
│   └── TABLEAU.md                   # guide for rebuilding it in Tableau Public
├── notebooks/
│   ├── 01_eda.ipynb                 # phase 1: cleaning + exploratory analysis
│   ├── 02_sql_analysis.ipynb        # phase 2: same questions in SQL, plus JOINs/window functions
│   └── 03_price_model.ipynb         # phase 3: linear regression + random forest price model
├── requirements.txt
└── README.md
```

## Running it locally

```bash
pip install -r requirements.txt
jupyter notebook notebooks/01_eda.ipynb   # or notebooks/02_sql_analysis.ipynb
```

## Data source

USA Cars dataset (used-vehicle auction listings): https://raw.githubusercontent.com/stat-lu/dataviz/main/data/us_cars.csv
