# Phase II – Normalization (UNF → 1NF → 2NF → 3NF)

**Project:** Rwanda Food Price Watch · Bruce RUTAGENGWA (28468) · INSY 8311

**Source:** `data/raw/wfp_food_prices_rwa.csv` (157,793 rows) and `data/raw/wfp_markets_rwa.csv` (320 rows). See the [dataset card](../../data/dataset_card.md).

Every row shown below is a **real row** from the raw file. The running example is **Mugera market (Gatsibo district) in January 2025** (raw lines 144460, 152726, 152732 and 156429), plus one row from the neighbouring market Ntungaruze (line 144472). Line numbers count the header as line 1.

---

## UNF – the raw file as it arrives

One wide row per price, with 16 columns. Market, district, province, category and unit text are repeated on every row, and `priceflag` sometimes holds **two values in one cell**.

| date | admin1 | admin2 | market | market_id | latitude | longitude | category | commodity | commodity_id | unit | priceflag | pricetype | currency | price | usdprice |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2025-01-15 | Eastern Province | Gatsibo | Mugera | 2374 | -1.6 | 30.28 | cereals and tubers | Cassava | 68 | KG | actual | Retail | RWF | 375 | 0.27 |
| 2025-01-15 | Eastern Province | Gatsibo | Mugera | 2374 | -1.6 | 30.28 | cereals and tubers | Maize | 51 | KG | **actual,aggregate** | Retail | RWF | 433.33 | 0.32 |
| 2025-01-15 | Eastern Province | Gatsibo | Mugera | 2374 | -1.6 | 30.28 | pulses and nuts | Beans (dry) | 262 | KG | **actual,aggregate** | Retail | RWF | 756.13 | 0.55 |
| 2025-01-15 | Eastern Province | Gatsibo | Mugera | 2374 | -1.6 | 30.28 | cereals and tubers | Rice (imported) | 64 | KG | aggregate | Retail | RWF | 1400 | 1.02 |
| 2025-01-15 | Eastern Province | Gatsibo | Ntungaruze | 2375 | -1.6 | 30.27 | cereals and tubers | Cassava | 68 | KG | actual | Retail | RWF | 400 | 0.29 |

**Problems:**
- `priceflag` is a **repeating group inside one cell**: 6,520 rows hold the list `actual,aggregate`.
- **Redundancy:** "Eastern Province, Gatsibo, Mugera, -1.6, 30.28" is stored on 2,026 Mugera rows, and "cereals and tubers" on every cereal row. Renaming a district would mean updating thousands of rows (an update anomaly).

---

## 1NF – one value per cell

**Dependency removed: the repeating group.** The multi-valued `priceflag` is split so each row holds one flag. A row flagged `actual,aggregate` becomes two rows.

**Key:** (`date`, `market_id`, `commodity_id`, `pricetype`, `priceflag`). The data check shows (`date`, `market_id`, `commodity_id`, `pricetype`) is unique on all 157,793 rows, and the flag is added because one price can now have two flag rows.

| date | market_id | market | admin2 | admin1 | lat | long | commodity_id | commodity | category | unit | pricetype | **priceflag** | currency | price | usdprice |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2025-01-15 | 2374 | Mugera | Gatsibo | Eastern Province | -1.6 | 30.28 | 68 | Cassava | cereals and tubers | KG | Retail | actual | RWF | 375 | 0.27 |
| 2025-01-15 | 2374 | Mugera | Gatsibo | Eastern Province | -1.6 | 30.28 | 51 | Maize | cereals and tubers | KG | Retail | **actual** | RWF | 433.33 | 0.32 |
| 2025-01-15 | 2374 | Mugera | Gatsibo | Eastern Province | -1.6 | 30.28 | 51 | Maize | cereals and tubers | KG | Retail | **aggregate** | RWF | 433.33 | 0.32 |
| 2025-01-15 | 2374 | Mugera | Gatsibo | Eastern Province | -1.6 | 30.28 | 64 | Rice (imported) | cereals and tubers | KG | Retail | aggregate | RWF | 1400 | 1.02 |
| 2025-01-15 | 2375 | Ntungaruze | Gatsibo | Eastern Province | -1.6 | 30.27 | 68 | Cassava | cereals and tubers | KG | Retail | actual | RWF | 400 | 0.29 |

Every cell is now atomic. The Maize price `433.33` is stored twice, which is the partial dependency that 2NF removes.

---

## 2NF – remove partial dependencies

Each non-key column must depend on the **whole** key. The data check proves which part of the key each column depends on. Every `market_id` has exactly one name, district and coordinate pair, and every `commodity_id` has exactly one name, category and unit (0 exceptions).

| Split | Partial dependency removed (one sentence) |
|---|---|
| **MARKET** | `market`, `admin2`, `admin1`, `latitude` and `longitude` depend only on `market_id`, not on the whole key, so they move to MARKET. |
| **COMMODITY** | `commodity`, `category` and `unit` depend only on `commodity_id`, so they move to COMMODITY. |
| **EXCHANGE_RATE** | The RWF→USD rate behind `usdprice` and the `currency` depend only on the month (`date`), so the rate moves to EXCHANGE_RATE. |
| **PRICE_OBSERVATION** | `price` depends on (`date`, `market_id`, `commodity_id`, `pricetype`) but not on `priceflag`, so the price moves to its own table without the flag. |
| **OBSERVATION_FLAG** | What remains of the 1NF key (price key + `priceflag`) becomes a junction table linking one observation to one or more flags. |

**MARKET (2NF)**

| market_id | market | admin2 | admin1 | latitude | longitude |
|---|---|---|---|---|---|
| 2374 | Mugera | Gatsibo | Eastern Province | -1.6 | 30.28 |
| 2375 | Ntungaruze | Gatsibo | Eastern Province | -1.6 | 30.27 |
| 1079 | Kiramuruzi | Gatsibo | Eastern Province | -1.8 | 30.4 |

**COMMODITY (2NF)**

| commodity_id | commodity | category | unit |
|---|---|---|---|
| 51 | Maize | cereals and tubers | KG |
| 68 | Cassava | cereals and tubers | KG |
| 64 | Rice (imported) | cereals and tubers | KG |
| 262 | Beans (dry) | pulses and nuts | KG |

**EXCHANGE_RATE (2NF)** (the rate is the monthly median of `price ÷ usdprice` in the raw file)

| month | rwf_per_usd |
|---|---|
| 2024-12 | 1,370.97 |
| 2025-01 | 1,373.63 |

**PRICE_OBSERVATION (2NF)**

| date | market_id | commodity_id | pricetype | price |
|---|---|---|---|---|
| 2025-01-15 | 2374 | 68 | Retail | 375 |
| 2025-01-15 | 2374 | 51 | Retail | 433.33 |
| 2025-01-15 | 2374 | 64 | Retail | 1400 |
| 2025-01-15 | 2375 | 68 | Retail | 400 |

**OBSERVATION_FLAG (2NF)**

| date | market_id | commodity_id | pricetype | priceflag |
|---|---|---|---|---|
| 2025-01-15 | 2374 | 68 | Retail | actual |
| 2025-01-15 | 2374 | 51 | Retail | actual |
| 2025-01-15 | 2374 | 51 | Retail | aggregate |
| 2025-01-15 | 2374 | 64 | Retail | aggregate |

The Maize price `433.33` is now stored once, and its two flags are two junction rows.

---

## 3NF – remove transitive dependencies

No non-key column may depend on another non-key column.

| Split | Transitive dependency removed (one sentence) |
|---|---|
| **DISTRICT** | In MARKET, `admin1` (province) depends on `admin2` (district), not directly on the market (`market_id → admin2 → admin1`), so the district moves to DISTRICT with a link to its province. |
| **PROVINCE** | The province name then lives once in PROVINCE (5 rows) instead of on every district and market. |
| **`usdprice` dropped** | `usdprice` depends on `price` and the month's exchange rate (`price ÷ rwf_per_usd`), both non-key facts, so it is not stored; `fn_price_usd` calculates it. |
| **`currency` dropped** | `currency` is `RWF` on all 157,793 rows, so it carries no information; every price is in RWF. |

After these splits every table is in 3NF. COMMODITY (`commodity_id`, `commodity`, `category`, `unit`) and PRICE_OBSERVATION with a `pricetype` text column would already satisfy 3NF, because each of those columns depends directly on the key.

### Lookup tables (a design choice beyond 3NF)

Four more tables are **lookups**. They do not fix a normal-form violation. They remove repeated text and the update anomaly that comes with it:

| Lookup | Why |
|---|---|
| **CATEGORY** | The text "cereals and tubers" would repeat on 18 commodities, and renaming it would mean 18 updates. COMMODITY keeps only `category_id`. |
| **UNIT** | Unit names (`KG`, `L`, `Sack`, `Unit`) would repeat on 65 commodities. COMMODITY keeps `unit_id`. |
| **PRICE_TYPE** | "Retail" / "Wholesale" would repeat on all 157,793 observations, and a typo such as "retail" could slip in. The lookup allows only valid values. |
| **PRICE_FLAG** | "actual" / "aggregate" would repeat on every flag row. OBSERVATION_FLAG keeps only `flag_id`. |

Surrogate ids for the new lookups are assigned in **alphabetical order** in Phase IV. The ids below are what that rule gives (e.g. Gatsibo is the 5th of the 30 districts).

**PROVINCE**

| province_id | province_name |
|---|---|
| 1 | Eastern Province |
| 2 | Kigali City |
| 5 | Western Province |

**DISTRICT**

| district_id | district_name | province_id |
|---|---|---|
| 5 | Gatsibo | 1 |
| 25 | Rubavu | 5 |

**MARKET**

| market_id | market_name | district_id | latitude | longitude |
|---|---|---|---|---|
| 2374 | Mugera | 5 | -1.6 | 30.28 |
| 2375 | Ntungaruze | 5 | -1.6 | 30.27 |
| 1063 | Gisenyi | 25 *(placeholder district fixed in Phase IV)* | -1.7 | 29.26 |

**CATEGORY** · **UNIT** · **PRICE_TYPE** · **PRICE_FLAG**

| category_id | category_name | | unit_id | unit_name | | price_type_id | price_type_name | | flag_id | flag_name |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | cereals and tubers | | 1 | KG | | 1 | Retail | | 1 | actual |
| 7 | pulses and nuts | | 2 | L | | 2 | Wholesale | | 2 | aggregate |

**COMMODITY**

| commodity_id | commodity_name | category_id | unit_id |
|---|---|---|---|
| 51 | Maize | 1 | 1 |
| 68 | Cassava | 1 | 1 |
| 262 | Beans (dry) | 7 | 1 |

**PRICE_OBSERVATION** (surrogate `observation_id`; the natural key `market_id + commodity_id + price_type_id + obs_month` stays unique)

| observation_id | market_id | commodity_id | price_type_id | obs_month | price_rwf |
|---|---|---|---|---|---|
| 1 | 2374 | 68 | 1 | 2025-01 | 375 |
| 2 | 2374 | 51 | 1 | 2025-01 | 433.33 |
| 3 | 2375 | 68 | 1 | 2025-01 | 400 |

**OBSERVATION_FLAG** (junction: resolves the many-to-many between observations and flags)

| observation_id | flag_id |
|---|---|
| 1 | 1 |
| 2 | 1 |
| 2 | 2 |

**EXCHANGE_RATE**

| rate_month | rwf_per_usd |
|---|---|
| 2025-01 | 1,373.63 |

### Tables that support the PL/SQL rules (not in the raw file)

These come from the Phase I process, not from the CSV, and are already in 3NF:

| Table | Holds | Links |
|---|---|---|
| PRICE_THRESHOLD | Allowed % increase before an alert, one row per commodity | COMMODITY 1 → 0..1 |
| PRICE_ALERT | Alerts created by `generate_alerts` and their status (OPEN, CONFIRMED, FALSE_ALARM, CLOSED) | PRICE_OBSERVATION 1 → 0..N |
| AUDIT_LOG | Every insert, update, delete and denied attempt on price data | none (it must keep rows for deleted records too) |

**Result:** 14 tables in 3NF: 11 hold the data from the raw file, and 3 support the PL/SQL rules. The diagram is in [erd.png](erd.png), and every column is listed in the [data dictionary](data_dictionary.md).

---

## Tracing one raw record into the 3NF tables (the class demo)

Raw line 152726 (Maize at Mugera, January 2025):

```
2025-01-15,Eastern Province,Gatsibo,Mugera,2374,-1.6,30.28,cereals and tubers,Maize,51,KG,"actual,aggregate",Retail,RWF,433.33,0.32
```

| Raw value | Goes to |
|---|---|
| `2025-01-15` | PRICE_OBSERVATION.obs_month = 2025-01-01 (the month) |
| `Eastern Province` | PROVINCE.province_name (id 1) |
| `Gatsibo` | DISTRICT.district_name (id 5, province_id 1) |
| `Mugera`, `2374`, `-1.6`, `30.28` | MARKET (market_id 2374, district_id 5, latitude, longitude) |
| `cereals and tubers` | CATEGORY.category_name (id 1) |
| `Maize`, `51` | COMMODITY (commodity_id 51, category_id 1, unit_id 1) |
| `KG` | UNIT.unit_name (id 1), linked through COMMODITY |
| `actual,aggregate` | two OBSERVATION_FLAG rows → PRICE_FLAG ids 1 (actual) and 2 (aggregate) |
| `Retail` | PRICE_TYPE (id 1), PRICE_OBSERVATION.price_type_id |
| `RWF` | not stored: constant, all prices are RWF |
| `433.33` | PRICE_OBSERVATION.price_rwf |
| `0.32` | not stored: `fn_price_usd` = 433.33 ÷ EXCHANGE_RATE 1,373.63 = 0.32 |

The same market and commodity rose from **437.25 RWF in October 2024 to 586.46 RWF in November 2024 (+34%)**, a real spike that the alert rule from Phase I would catch.

---

## Changes from the Phase 0 plan

| Phase 0 plan | Phase II design | Reason |
|---|---|---|
| `unit` stored on PRICE_OBSERVATION | `unit_id` stored on COMMODITY | The data shows each of the 65 commodities has exactly one unit, so unit depends on the commodity alone (a partial dependency). |
| `priceflag` "split in Phase II" | PRICE_FLAG lookup + OBSERVATION_FLAG junction | One price can have two flags, which is a many-to-many relationship. |
| Price type as a text column | PRICE_TYPE lookup | Removes repeated text. |
| 11 tables | 14 tables | The three tables above are added. |
| 29 districts | 30 districts | The markets file names all 30; the price file has 28 plus one placeholder. |
