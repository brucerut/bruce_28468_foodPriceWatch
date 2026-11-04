# Rwanda Food Price Watch

| | |
|---|---|
| **Student** | Bruce RUTAGENGWA |
| **Student ID** | 28468 |
| **Group** | Wednesday Grp C |
| **Course** | INSY 8311 – Database Development with PL/SQL |
| **Instructor** | Eric Maniraguha |
| **Repository** | [github.com/brucerut/bruce_28468_foodPriceWatch](https://github.com/brucerut/bruce_28468_foodPriceWatch) |

## Problem statement
Food prices in Rwandan markets change sharply between seasons and between districts. WFP publishes
monthly price data, but only as one flat file. Cooperatives, local authorities and households cannot
easily see when a staple such as beans or maize suddenly becomes expensive in their market. Price
spikes are noticed late, so there is no early warning.

## Objectives
**Main objective:** Build an Oracle database with PL/SQL that stores Rwandan market food prices in
normalized form and automatically detects and reports abnormal price increases.

**Specific objectives:**
1. Normalize the WFP price file to 3NF (province, district, market, commodity, price observation).
2. Load and validate more than 150,000 real price records using PL/SQL.
3. Detect month-over-month price spikes per market and commodity with functions, cursors and triggers.
4. Audit every change to price data and enforce a restriction rule on data entry.
5. Show prices and alerts on a live Power BI dashboard connected to Oracle.

## Data source
WFP – World Food Programme (2026). *Rwanda – Food Prices* [Data set]. Humanitarian Data Exchange.
https://data.humdata.org/dataset/wfp-food-prices-for-rwanda. Licence: CC BY-IGO. See [data/README.md](data/README.md).

## Innovation
**Option:** Analytics dashboard · **Tool:** Power BI (connected live to Oracle).
The dashboard shows a map of markets coloured by current price change, price trends by commodity and
district, and the open price alerts. A nightly `DBMS_SCHEDULER` job runs the spike-detection procedure,
so new alerts appear without anyone running SQL by hand.

## Planned tables
| Table | Purpose |
|---|---|
| `PROVINCE` | 5 provinces (admin1) |
| `DISTRICT` | 29 districts (admin2), FK → PROVINCE |
| `MARKET` | 109 markets with latitude/longitude, FK → DISTRICT |
| `CATEGORY` | Commodity categories (cereals and tubers, pulses and nuts, …) |
| `COMMODITY` | 54 commodities, FK → CATEGORY |
| `UNIT` | Units of measure (KG, L, …) |
| `PRICE_OBSERVATION` | One price per market, commodity, unit, price type and month |
| `EXCHANGE_RATE` | RWF per USD per month (removes the derived `usdprice` column) |
| `PRICE_THRESHOLD` | Allowed % increase per commodity before an alert |
| `PRICE_ALERT` | Generated spike alerts and their status |
| `AUDIT_LOG` | Who changed what and when, including denied attempts |

## Planned PL/SQL features
- **Procedure** `record_price`: inserts one observation and raises `e_invalid_price` if the price is ≤ 0 or the market is unknown.
- **Function** `fn_pct_change`: returns the % change from the previous month for a market and commodity.
- **Function** `fn_price_usd`: converts RWF to USD using `EXCHANGE_RATE`.
- **Cursor** in `generate_alerts`: loops over the latest month's observations and inserts a `PRICE_ALERT` when the change exceeds `PRICE_THRESHOLD`.
- **Package** `pkg_price_watch`: groups the procedures and functions above.
- **Trigger** `trg_price_audit`: writes every INSERT/UPDATE/DELETE on `PRICE_OBSERVATION` to `AUDIT_LOG`.
- **Trigger** for the restriction rule (defined in Phase VI): blocks data entry outside the allowed days and logs the denied attempt.
- **Analytic SQL** (`LAG`, `AVG OVER`): computes trends for the dashboard.

## Repository structure
```
data/                 dataset notes (raw CSV downloaded from HDX)
docs/research/        research_log.md
docs/proposal/        proposal (max 2 pages)
docs/presentation/    Phase 0 slides
```

## References
See [docs/research/research_log.md](docs/research/research_log.md).
