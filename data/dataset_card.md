# Dataset card – Rwanda Food Prices (WFP)

## Source

| Item | Value |
|---|---|
| Dataset | Rwanda – Food Prices, World Food Programme (WFP) |
| Publisher / host | WFP, via the Humanitarian Data Exchange (HDX) |
| Link | https://data.humdata.org/dataset/wfp-food-prices-for-rwanda |
| Licence | CC BY-IGO: educational use allowed, attribution required |
| Format | CSV, UTF-8, comma-separated, first row is the header; values that contain a comma are wrapped in double quotes |
| Date collected | Downloaded 2026-11-04 |
| Coverage | Monthly prices, January 2000 – August 2026 |
| Personal data | None. Rows describe market prices only (no names, phone numbers or ID numbers), so nothing had to be anonymised |

## Raw files (`data/raw/`, kept exactly as downloaded, never edited)

| File | Size | Rows (without header) | Columns | SHA-256 |
|---|---|---|---|---|
| `wfp_food_prices_rwa.csv` | 20.6 MB | 157,793 | 16 | `6c19988f0239b2a367401fdba165571e3de9b6d3aa3471287b48a0ce1e50f839` |
| `wfp_markets_rwa.csv` | 18 KB | 320 | 7 | `95ef480b6807a708cbc8f626bfc88c37aeb9c0bcc30243badd4bbd6116169a60` |

The checksums prove the raw files have not been changed. Run `sha256sum data/raw/*.csv` to check them.

### What one record represents

- **Price file:** the price of **one commodity** (e.g. Maize, in one unit such as KG) of **one price type** (Retail or Wholesale) in **one market** for **one month**. The month is always written as the 15th (e.g. `2025-01-15` = January 2025).
- **Markets file:** one market where WFP monitors prices, with its province, district and coordinates.

### Columns

| File | Columns |
|---|---|
| Price file | `date, admin1, admin2, market, market_id, latitude, longitude, category, commodity, commodity_id, unit, priceflag, pricetype, currency, price, usdprice` |
| Markets file | `market_id, market, countryiso3, admin1, admin2, latitude, longitude` |

`admin1` = province, `admin2` = district. Every column of both files is mapped to a target table, or dropped with a reason, in [docs/design/data_dictionary.md](../docs/design/data_dictionary.md#source-to-target-mapping).

### Sample records (price file, raw lines 144460–144461 and one aggregate row)

```
2025-01-15,Eastern Province,Gatsibo,Mugera,2374,-1.6,30.28,cereals and tubers,Cassava,68,KG,actual,Retail,RWF,375,0.27
2025-01-15,Eastern Province,Gatsibo,Mugera,2374,-1.6,30.28,cereals and tubers,Cassava flour,74,KG,actual,Retail,RWF,800,0.58
2025-01-15,Eastern Province,Gatsibo,Mugera,2374,-1.6,30.28,cereals and tubers,Maize,51,KG,"actual,aggregate",Retail,RWF,433.33,0.32
```

## Size and content

| Measure | Price file | Markets file |
|---|---|---|
| Records | 157,793 | 320 |
| Distinct months | 295 | – |
| Markets | 109 (all present in the markets file) | 320 (211 have no prices) |
| Provinces (`admin1`) | 5 | 5 |
| Districts (`admin2`) | 28 named + 1 placeholder | 30 named + 1 placeholder |
| Categories | 8 | – |
| Commodities | 65 | – |
| Units | 4: KG 138,579 · Unit 10,485 · L 5,930 · Sack 2,799 | – |
| Price types | Retail 157,124 · Wholesale 669 | – |
| Price flags | actual 148,105 · aggregate 3,168 · `actual,aggregate` 6,520 | – |
| Price range (RWF) | 11 – 332,333.33 | – |

## Data quality report (checked 2026-11-15, nothing fixed yet)

Checked with a script over every row of both raw files. **Nothing has been cleaned.** The fixes are planned for Phase IV, as the right-hand column shows.

### Checks that passed

| Check | Result |
|---|---|
| Rows with the wrong number of columns | 0 of 157,793 (price) · 0 of 320 (markets) |
| Empty or missing values, any column | 0 cells in both files |
| Leading or trailing spaces in any value | 0 |
| Exact duplicate rows | 0 |
| Duplicate natural keys (`date` + `market_id` + `commodity_id` + `pricetype`) | 0 |
| Dates that are not a valid `YYYY-MM-DD` | 0 |
| Prices that are not numeric, zero or negative | 0 |
| Spelling variants of the same province, district, market or commodity (ignoring case and punctuation) | 0 |
| `market_id` with more than one name, district or coordinate pair | 0 of 109 |
| `commodity_id` with more than one name, category or unit | 0 of 65 |
| District assigned to more than one province | 0 |
| Markets in the price file that are missing from the markets file | 0 |
| Market name or district differs between the two files | 0 |

### Issues found (with counts)

| # | Issue | Count | Plan for Phase IV |
|---|---|---|---|
| 1 | `priceflag` is not atomic: it holds two values, `"actual,aggregate"` | 6,520 rows | Split into the PRICE_FLAG lookup and the OBSERVATION_FLAG junction table (two flag rows each) |
| 2 | District is a placeholder text, `Administrative unit not available`, instead of a real district | 2,246 price rows (all for market Gisenyi, id 1063) · 2 markets in the markets file (Gisenyi 1063, Hepfu 7285) | Assign the correct district (Gisenyi is in Rubavu district) before loading |
| 3 | Values contain commas, so they are wrapped in quotes (category `"meat, fish and eggs"`, the combined flag, and 4 commodity names such as `"Rice (imported, Tanzanian)"`) | 29,547 lines (15,837 for the category alone) | The loader must use a quote-aware CSV parser; splitting on commas breaks these rows |
| 4 | `currency` is the same value, `RWF`, on every row | 157,793 rows (1 distinct value) | Drop the column; all prices are RWF |
| 5 | `usdprice` is derived from `price` and the exchange rate, and is rounded to 2 decimals | 113,044 rows below 1 USD lose precision · 5,205 rows imply an exchange rate more than 2% away from that month's median | Drop the column; store one rate per month in EXCHANGE_RATE and compute USD with `fn_price_usd` |
| 6 | Dates and numbers are stored as text in the CSV | all 157,793 rows (`date`, `price`, `usdprice`, `latitude`, `longitude`, both ids) | Convert: text → DATE (first day of the month) and text → NUMBER |
| 7 | `date` is always the 15th: it stands for a month, not a day | 157,793 rows | Store as the month (`obs_month` = first day of the month) |
| 8 | Missing months between Jan 2000 and Aug 2026 | 25 of 320 months (2001-09 → 2002-10, 2004-07 → 2005-08 with gaps) | Keep; the spike check compares only consecutive months that both have a price |
| 9 | Uneven coverage over time | 2000–2007: 162 rows in total · 2016: 610 rows · 2015: 27,275 rows | Keep; mention as a limitation on the dashboard |
| 10 | Coordinates are rounded to 2 decimals, so different markets share the same point | 14 price-file markets share 6 coordinate pairs (e.g. Kigali, Kimisagara, Nyabugogo and Mulindi are all at -1.95, 30.06) · 12 shared pairs in the markets file | Keep as is; note that map positions are approximate |
| 11 | Overlapping commodity names that may describe the same product | 5 groups, 17 names (e.g. `Beans` 237 rows vs `Beans (dry)` 6,855 rows; `Potatoes` 1,695 vs `Potatoes (Irish)` 6,364; 6 rice names) | Keep separate (they have separate WFP ids); flag them in the data dictionary |
| 12 | Possible outliers: price more than 5× above or below the median for that commodity and price type | 101 rows (e.g. Passion fruit 100–140 RWF/KG in 2008 vs median 754.25) | Keep but flag; do not raise alerts on them without review |
| 13 | Wholesale prices are rare | 669 rows (0.42%) | Keep; the dashboard defaults to Retail |
| 14 | `countryiso3` is the same value, `RWA`, in the markets file | 320 rows | Drop the column |
| 15 | Markets with no price at all | 211 of 320 markets | Load them anyway (MARKET → PRICE_OBSERVATION is optional) |

**Correction to Phase 0:** the Phase 0 documents say 29 districts. A full check shows 28 named districts plus the placeholder in the price file, and 30 named districts in the markets file (all of Rwanda's districts).
