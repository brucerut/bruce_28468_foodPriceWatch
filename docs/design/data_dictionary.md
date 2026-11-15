# Phase II – Data dictionary (logical)

**Project:** Rwanda Food Price Watch · Bruce RUTAGENGWA (28468) · INSY 8311

This is the logical design. Oracle data types and sizes are added in Phase IV.

**Key:** PK = primary key · FK = foreign key · UK = unique (alternate) key. **Req** = a value is required (NOT NULL). **Unique** = no two rows may share the value.

---

## Location

### PROVINCE: the 5 provinces of Rwanda (raw `admin1`)

| Column | Meaning | Key | Req | Unique |
|---|---|---|---|---|
| province_id | Surrogate number for the province, assigned alphabetically | PK | Yes | Yes |
| province_name | Province name, e.g. "Eastern Province" | UK | Yes | Yes |

### DISTRICT: the 30 districts (raw `admin2`)

| Column | Meaning | Key | Req | Unique |
|---|---|---|---|---|
| district_id | Surrogate number for the district, assigned alphabetically | PK | Yes | Yes |
| district_name | District name, e.g. "Gatsibo" | UK | Yes | Yes |
| province_id | Province the district belongs to | FK → PROVINCE | Yes | No |

### MARKET: the 320 markets monitored by WFP (109 have prices)

| Column | Meaning | Key | Req | Unique |
|---|---|---|---|---|
| market_id | WFP's own market number, kept from the raw data | PK | Yes | Yes |
| market_name | Market name, e.g. "Mugera" (all 320 names are unique) | UK | Yes | Yes |
| district_id | District where the market is | FK → DISTRICT | Yes | No |
| latitude | Latitude in decimal degrees, rounded to 2 decimals by WFP | | Yes | No |
| longitude | Longitude in decimal degrees, rounded to 2 decimals by WFP | | Yes | No |

## Commodities

### CATEGORY: 8 commodity groups

| Column | Meaning | Key | Req | Unique |
|---|---|---|---|---|
| category_id | Surrogate number, assigned alphabetically | PK | Yes | Yes |
| category_name | Group name, e.g. "cereals and tubers" | UK | Yes | Yes |

### UNIT: 4 units of measure

| Column | Meaning | Key | Req | Unique |
|---|---|---|---|---|
| unit_id | Surrogate number, assigned alphabetically | PK | Yes | Yes |
| unit_name | KG, L, Sack or Unit | UK | Yes | Yes |

### COMMODITY: 65 products priced by WFP

| Column | Meaning | Key | Req | Unique |
|---|---|---|---|---|
| commodity_id | WFP's own commodity number, kept from the raw data | PK | Yes | Yes |
| commodity_name | Product name, e.g. "Maize", "Beans (dry)". Some names overlap (e.g. "Beans" and "Beans (dry)"), see dataset card issue 11 | UK | Yes | Yes |
| category_id | Group the product belongs to | FK → CATEGORY | Yes | No |
| unit_id | Unit every price of this product is quoted in | FK → UNIT | Yes | No |

## Prices

### PRICE_TYPE: Retail or Wholesale

| Column | Meaning | Key | Req | Unique |
|---|---|---|---|---|
| price_type_id | Surrogate number: 1 Retail, 2 Wholesale | PK | Yes | Yes |
| price_type_name | "Retail" or "Wholesale" | UK | Yes | Yes |

### PRICE_FLAG: how WFP obtained the price

| Column | Meaning | Key | Req | Unique |
|---|---|---|---|---|
| flag_id | Surrogate number: 1 actual, 2 aggregate | PK | Yes | Yes |
| flag_name | "actual" (price observed in the market) or "aggregate" (calculated from several observations) | UK | Yes | Yes |

### PRICE_OBSERVATION: one price for one commodity, price type, market and month (157,793 rows)

| Column | Meaning | Key | Req | Unique |
|---|---|---|---|---|
| observation_id | Surrogate number for the observation | PK | Yes | Yes |
| market_id | Market where the price was recorded | FK → MARKET, part of UK | Yes | No |
| commodity_id | Product that was priced | FK → COMMODITY, part of UK | Yes | No |
| price_type_id | Retail or wholesale | FK → PRICE_TYPE, part of UK | Yes | No |
| obs_month | Month of the price, stored as the first day of the month | part of UK | Yes | No |
| price_rwf | Price in Rwandan francs for one unit of the commodity; must be greater than 0 | | Yes | No |
| entered_by | Database user who entered the price (WFP load or data entry officer) | | Yes | No |
| entered_at | Date and time the row was entered | | Yes | No |

UK = (market_id, commodity_id, price_type_id, obs_month): one price per market, product, price type and month.

### OBSERVATION_FLAG: junction between PRICE_OBSERVATION and PRICE_FLAG

| Column | Meaning | Key | Req | Unique |
|---|---|---|---|---|
| observation_id | The observation that carries the flag | PK (part), FK → PRICE_OBSERVATION | Yes | No |
| flag_id | The flag | PK (part), FK → PRICE_FLAG | Yes | No |

The pair (observation_id, flag_id) is unique. An observation flagged `actual,aggregate` in the raw file has two rows.

### EXCHANGE_RATE: one RWF/USD rate per month

| Column | Meaning | Key | Req | Unique |
|---|---|---|---|---|
| rate_month | Month, stored as the first day of the month | PK | Yes | Yes |
| rwf_per_usd | Rwandan francs per US dollar for that month (median of `price ÷ usdprice` in the raw file) | | Yes | No |

## Alert rules and audit (from the Phase I process)

### PRICE_THRESHOLD: allowed increase per commodity

| Column | Meaning | Key | Req | Unique |
|---|---|---|---|---|
| commodity_id | Commodity the threshold applies to | PK, FK → COMMODITY | Yes | Yes |
| max_increase_pct | Largest month-on-month increase, in percent, before an alert is raised (e.g. 25) | | Yes | No |
| updated_at | When the threshold was last changed | | Yes | No |

### PRICE_ALERT: price spikes found by `generate_alerts`

| Column | Meaning | Key | Req | Unique |
|---|---|---|---|---|
| alert_id | Surrogate number for the alert | PK | Yes | Yes |
| observation_id | The new price that triggered the alert | FK → PRICE_OBSERVATION | Yes | No |
| previous_price_rwf | The previous month's price it was compared with | | Yes | No |
| pct_change | Increase in percent | | Yes | No |
| threshold_pct | Threshold in force when the alert was created | | Yes | No |
| status | OPEN, CONFIRMED, FALSE_ALARM or CLOSED | | Yes | No |
| created_at | When the alert was created | | Yes | No |
| reviewed_by | Analyst who confirmed it or marked it a false alarm | | No | No |
| notified_at | When the district was notified (CONFIRMED alerts only) | | No | No |
| action_taken | What the district did (filled when closing) | | No | No |
| closed_at | When the alert was closed | | No | No |

Closed alerts older than 12 months are archived by deleting them, and the audit trigger keeps a copy of the old values in AUDIT_LOG.

### AUDIT_LOG: every change and denied attempt on price data

| Column | Meaning | Key | Req | Unique |
|---|---|---|---|---|
| audit_id | Surrogate number for the log entry | PK | Yes | Yes |
| table_name | Table that was changed, e.g. PRICE_OBSERVATION | | Yes | No |
| record_id | Primary key of the changed row | | Yes | No |
| action | INSERT, UPDATE, DELETE or DENIED | | Yes | No |
| old_values | Values before the change (UPDATE and DELETE) | | No | No |
| new_values | Values after the change (INSERT and UPDATE) | | No | No |
| db_user | Database user who did it | | Yes | No |
| action_time | Date and time of the action | | Yes | No |
| reason | Why a DENIED attempt was blocked (restriction rule) | | No | No |

AUDIT_LOG has no foreign key on purpose: it must keep entries for rows that have been deleted.

---

## Relationships (crow's-foot, see [erd.png](erd.png))

| Parent | Child | Cardinality | Optionality (read as "each parent has …") |
|---|---|---|---|
| PROVINCE | DISTRICT | 1 : N | one or more districts; each district has exactly one province |
| DISTRICT | MARKET | 1 : N | zero or more markets; each market is in exactly one district |
| MARKET | PRICE_OBSERVATION | 1 : N | zero or more prices (211 markets have none); each price is in exactly one market |
| CATEGORY | COMMODITY | 1 : N | one or more commodities; each commodity is in exactly one category |
| UNIT | COMMODITY | 1 : N | one or more commodities; each commodity has exactly one unit |
| COMMODITY | PRICE_OBSERVATION | 1 : N | zero or more prices; each price is for exactly one commodity |
| PRICE_TYPE | PRICE_OBSERVATION | 1 : N | zero or more prices; each price has exactly one type |
| PRICE_OBSERVATION | OBSERVATION_FLAG | 1 : N | one or more flags (every raw row has at least one) |
| PRICE_FLAG | OBSERVATION_FLAG | 1 : N | zero or more observations |
| PRICE_OBSERVATION ⟷ PRICE_FLAG | (through OBSERVATION_FLAG) | M : N | resolved by the junction table |
| COMMODITY | PRICE_THRESHOLD | 1 : 0..1 | at most one threshold per commodity |
| PRICE_OBSERVATION | PRICE_ALERT | 1 : N | zero or more alerts (a corrected price can be re-checked) |

EXCHANGE_RATE is linked to PRICE_OBSERVATION by month (`obs_month = rate_month`) inside `fn_price_usd`, not by a foreign key: a month can have prices before its rate is loaded.

---

## Source-to-target mapping

This is the cleaning checklist for Phase IV.

### Price file `wfp_food_prices_rwa.csv`

| Raw field | Target table.column | Conversion / rule | Notes |
|---|---|---|---|
| date | PRICE_OBSERVATION.obs_month | text `YYYY-MM-15` → DATE, truncated to the first day of the month | Always the 15th (157,793 rows) |
| admin1 | PROVINCE.province_name | look up or insert → province_id | 5 values |
| admin2 | DISTRICT.district_name | look up → district_id; replace `Administrative unit not available` (2,246 rows, Gisenyi) with Rubavu | Placeholder is a missing value |
| market | MARKET.market_name | text, via market_id | 1 name per id (checked) |
| market_id | MARKET.market_id, PRICE_OBSERVATION.market_id | text → NUMBER | WFP id kept |
| latitude | MARKET.latitude | text → NUMBER | 1 value per market (checked) |
| longitude | MARKET.longitude | text → NUMBER | 1 value per market (checked) |
| category | CATEGORY.category_name | look up → category_id; quote-aware parsing (`"meat, fish and eggs"`) | 8 values |
| commodity | COMMODITY.commodity_name | text, via commodity_id; quote-aware parsing (4 names contain commas) | 65 values |
| commodity_id | COMMODITY.commodity_id, PRICE_OBSERVATION.commodity_id | text → NUMBER | WFP id kept |
| unit | UNIT.unit_name → COMMODITY.unit_id | look up → unit_id | 1 unit per commodity (checked) |
| priceflag | PRICE_FLAG.flag_name → OBSERVATION_FLAG | split `"actual,aggregate"` on the comma into 2 rows | 6,520 rows give 2 flags |
| pricetype | PRICE_TYPE.price_type_name → PRICE_OBSERVATION.price_type_id | look up → price_type_id | Retail / Wholesale |
| currency | **dropped** | – | Constant `RWF` on all rows |
| price | PRICE_OBSERVATION.price_rwf | text → NUMBER; reject ≤ 0 | 0 invalid now; 101 possible outliers flagged |
| usdprice | **dropped** (used once to build EXCHANGE_RATE.rwf_per_usd) | monthly median of `price ÷ usdprice` | Derived value; rounded to 2 decimals in the raw file |

### Markets file `wfp_markets_rwa.csv`

| Raw field | Target table.column | Conversion / rule | Notes |
|---|---|---|---|
| market_id | MARKET.market_id | text → NUMBER | 320 ids, no duplicates |
| market | MARKET.market_name | text | Unique |
| countryiso3 | **dropped** | – | Constant `RWA` |
| admin1 | PROVINCE.province_name | look up → province_id | Same 5 as the price file |
| admin2 | DISTRICT.district_name | look up → district_id; replace the placeholder for Gisenyi (Rubavu) and Hepfu (no prices; confirm its district from its coordinates) | 30 named districts |
| latitude | MARKET.latitude | text → NUMBER | |
| longitude | MARKET.longitude | text → NUMBER | |

### Columns not from the raw files

`observation_id`, `province_id`, `district_id`, `category_id`, `unit_id`, `price_type_id` and `flag_id` are surrogate keys. `entered_by` and `entered_at` are filled by the loader or by `record_price`. The tables PRICE_THRESHOLD, PRICE_ALERT and AUDIT_LOG are filled by the PL/SQL rules.
