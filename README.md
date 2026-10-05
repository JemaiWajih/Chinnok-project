# SQL-Based Analysis of Product Sales (Chinook Database)

**Level 2, Task 5: Data Analytics**

This project uses SQL to analyze product sales in the **Chinook** database, a relational
database for a digital music store. It answers the three business questions of the task:

1. **Top-selling products:** which tracks, albums, artists and genres earn the most?
2. **Revenue per region:** which countries and regions generate the most revenue?
3. **Monthly performance:** how does revenue change month by month and year by year?

**Bonus:** window functions (`ROW_NUMBER`, `RANK`, `DENSE_RANK`, `LAG`) are used for rankings and growth.

**Tool:** SQL (SQLite) | **Sales period:** Jan 2009 to Dec 2013 | **Total revenue:** $2,328.60

---

## Project structure

```
Chinook_Project/
├── database/   Chinook_Sqlite.sqlite      # Chinook database
├── queries/    1 to 5 .sql scripts         # SQL queries, grouped by topic
├── results/    CSV output of the key queries
├── run_all.py                              # runs the scripts and exports the CSVs
└── README.md
```

## How to run

Requires Python 3 (no extra packages). From the project root:

```bash
python3 run_all.py database/Chinook_Sqlite.sqlite
```

The script runs every `.sql` file in order and writes the key results to `results/`
as CSV files. Old CSVs are replaced on each run.

You can also run a single script directly with the SQLite CLI:

```bash
sqlite3 -header -column database/Chinook_Sqlite.sqlite < "queries/3_Revenue by country.sql"
```

Run the scripts in order (1 to 5): scripts 3, 4 and 5 create the views
(`v_sales_by_country`, `v_monthly_sales`, `v_product_sales`) that later queries use.

## Queries and what they answer

| Business question | Query | Output (in `results/`) |
|---|---|---|
| Top-selling products | 2.1 Top 10 tracks | `2.1_top_10_tracks_by_revenue.csv` |
| | 2.2 Top 10 albums | `2.2_top_10_albums_by_revenue.csv` |
| | 2.3 Top 10 artists | `2.3_top_10_artists_by_revenue.csv` |
| | 2.4 Revenue by genre | `2.4_revenue_by_genre.csv` |
| Revenue per region | 3.1 Revenue by country | `3.1_revenue_by_customer_country.csv` |
| | 3.4 Region grouping | `3.4_region_grouping.csv` |
| Monthly performance | 4.1 Monthly revenue | `4.1_monthly_revenue_view.csv` |
| | 4.2 Month-over-month growth | `4.2_month_over_month_growth.csv` |
| | 4.3 Yearly revenue and growth | `4.3_yearly_revenue_and_year_over_year_growth.csv` |
| Bonus: window functions | 5.2 ROW_NUMBER vs RANK vs DENSE_RANK | `5.2_row_number_vs_rank_vs_dense_rank.csv` |
| | 5.3 Top 3 tracks in each genre | `5.3_top_3_tracks_inside_each_genre.csv` |

The `.sql` scripts also contain extra queries (data-quality checks, seasonality,
ABC classification, reconciliation). They run but are not exported as CSVs.
To export more, add their numbers to the `KEEP` list at the top of `run_all.py`.

## SQL techniques used

- **JOINs** across `InvoiceLine`, `Invoice`, `Customer`, `Track`, `Album`, `Artist`, `Genre`
- **Aggregations:** `SUM`, `COUNT`, `AVG` with `GROUP BY`
- **Business logic:** revenue = `UnitPrice * Quantity`; `CASE` to group countries into regions
- **Views and CTEs** for reusable, readable queries
- **Window functions:** `ROW_NUMBER`, `RANK`, `DENSE_RANK`, `LAG`, `PARTITION BY`

## Key findings

**Top-selling products**
- **Rock** is the biggest genre at **35.5%** of revenue ($826.65), followed by Latin (16.4%) and Metal (11.2%).
- **Iron Maiden** is the top artist ($138.60, 140 units), followed by U2 ($105.93).
- Individual tracks are all very close: the top tracks earned $3.98 each, so many tie for rank 1.
  This is where `RANK` and `DENSE_RANK` differ from `ROW_NUMBER` (see query 5.2).

**Revenue per region**
- **USA** leads with $523.06 (22.5% of revenue), then **Canada** ($303.96) and **France** ($195.10).
- By region: **Europe $1,114.36**, **North America $827.02**, South America $274.34, Asia-Pacific $112.88.

**Monthly performance**
- Yearly revenue is stable at roughly **$450 to $480**, with no strong growth:

  | Year | Revenue | YoY growth |
  |---|---|---|
  | 2009 | $449.46 | n/a |
  | 2010 | $481.45 | +7.12% |
  | 2011 | $469.58 | -2.47% |
  | 2012 | $477.53 | +1.69% |
  | 2013 | $450.58 | -5.64% |

## Notes

- Revenue is calculated from `InvoiceLine` as `UnitPrice * Quantity`.
- Track names are not unique, so queries group by `TrackId` instead of name.
- Rankings use explicit tie-breakers so results are repeatable.

## Dataset

[Chinook Database](https://www.kaggle.com/) (Kaggle), SQLite version.
