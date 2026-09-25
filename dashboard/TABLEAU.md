# Building the Tableau Public version

The interactive dashboard in this folder already implements the phase 2 spec. This
file is for rebuilding the same four visuals in Tableau Public, which is worth
doing only for one reason: "Tableau" is a keyword recruiters filter on, and an
HTML page doesn't satisfy a job description that asks for it.

**Power BI is not an option on macOS.** There is no Power BI Desktop build for
Mac, and Power BI Service (the web app) requires a work or school account, not a
personal one. Tableau Public is the free Mac-native equivalent.

Two things to know before starting: Tableau Public has no private save — every
workbook you save goes to your public profile — and it cannot read SQLite
directly, which is why there's a CSV.

## 1. Connect the data

Use `data/processed/tableau_listings.csv` (2,448 rows), already flattened with the
region join applied, so no relationship needs configuring in Tableau:

| field | type | notes |
|---|---|---|
| `id` | number | listing id |
| `price` | number | the measure everything aggregates |
| `brand` | text | 26 values, long tail — see step 3 |
| `year` | number | set to **Dimension**, Tableau reads it as a measure by default |
| `title_status` | text | `clean vehicle` / `salvage insurance` — the filter field |
| `mileage` | number | odometer |
| `color`, `state`, `country` | text | |
| `region` | text | Midwest / Northeast / South / West / Canada |

Regenerate it after any data change:

```bash
python -c "
import sqlite3, csv
c = sqlite3.connect('data/processed/used_cars.db')
rows = c.execute('''SELECT l.id,l.price,l.brand,l.year,l.title_status,l.mileage,
                           l.color,l.state,r.region,l.country
                    FROM listings l LEFT JOIN regions r ON l.state=r.state''').fetchall()
w = csv.writer(open('data/processed/tableau_listings.csv','w',newline=''))
w.writerow(['id','price','brand','year','title_status','mileage','color','state','region','country'])
w.writerows(rows)"
```

**Open Tableau Public → Connect → Text file → pick the CSV.** Then click
`Sheet 1`. In the data pane, right-click `Year` → **Convert to Dimension**.

## 2. KPI tiles (Sheet: "KPIs")

Three numbers, one sheet each, or one sheet with three measures on Text.

- Drag `Price` to **Text**, set aggregation to **Average**. Format to 0 decimals,
  prefix `$`.
- Duplicate, change aggregation to **Median**.
- Drag `Number of Records` (or `COUNT(id)`) for total listings.

Expected with no filter: **2,448 listings, $19,123 average, $17,100 median.**
If your numbers differ, the CSV didn't load fully — check for a trailing blank row.

## 3. Average price by brand (Sheet: "Brand")

- `Brand` → **Rows**, `Price` → **Columns**, aggregation **Average**.
- Sort descending by the measure.
- **Fold the tail.** 12 nameplates have fewer than 10 listings and their averages
  are noise. Either filter `Brand` to those with `COUNT(id) >= 10`, or create a
  calculated field:

  ```
  IF { FIXED [Brand] : COUNT([Id]) } >= 10 THEN [Brand] ELSE "other" END
  ```

  Name it `Brand (grouped)` and use it on Rows instead. This reproduces the 15
  groups the HTML dashboard shows.
- Add `COUNT(id)` to **Tooltip** so thin bars are visible as thin.

## 4. Average price by region (Sheet: "Region")

- `Region` → **Rows**, `AVG(Price)` → **Columns**, sorted descending.
- **Canada is 7 listings** and has the highest average, so by default it renders
  as the tallest, most prominent bar — the least trustworthy number reading as
  the headline. Either exclude it, or drag `COUNT(id)` to **Detail** and add a
  caption stating the count. The HTML version dims any bar under 20 listings.
- Add a caption with the correction from notebook section 5b: only the Midwest
  gap survives controls (+$4,054 over the South); the Northeast premium collapses
  to +$76 once Pennsylvania, 59% of that region's listings, is excluded.

Expected (no filter): Canada $30,357 · Midwest $22,190 · Northeast $20,334 ·
West $18,888 · South $16,696.

## 5. Price vs. odometer (Sheet: "Scatter")

- `Mileage` → **Columns**, `Price` → **Rows**, both set to **Dimension** (or
  disaggregate via Analysis → uncheck *Aggregate Measures*) so you get one mark
  per listing rather than one averaged dot.
- `Title Status` → **Color**.
- Mark type **Circle**, size down, opacity ~50%.
- Mileage runs to 507,985 with most listings under 100,000. Either set the x-axis
  to a fixed 0–250,000 range and note what that omits, or leave it full and
  accept a compressed cloud.

## 6. Assemble and filter

- **Dashboard → New Dashboard.** Drop KPIs across the top, Brand and Region side
  by side, Scatter full width beneath.
- On any sheet, drag `Title Status` to **Filters** → show all values.
- Right-click the filter card → **Apply to Worksheets → All Using This Data
  Source.** This is the step that makes it one dashboard instead of four charts;
  without it each sheet filters independently and the numbers disagree.
- Show it as a single-select list so it reads as "all / clean / salvage".

Sanity check: with `salvage insurance` selected you should see **117 listings,
$3,236 average, $1,900 median.**

## 7. Publish

**File → Save to Tableau Public.** You'll need a free account. The workbook
becomes publicly visible at `public.tableau.com/app/profile/<you>`. Put that link
in the README next to the interactive dashboard.
