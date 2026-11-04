# Data source

| Item | Value |
|---|---|
| Dataset | Rwanda – Food Prices (WFP) |
| Link | https://data.humdata.org/dataset/wfp-food-prices-for-rwanda |
| Files | `wfp_food_prices_rwa.csv` (20.6 MB, 157,793 rows), `wfp_markets_rwa.csv` (320 markets listed, 109 with prices) |
| Licence | CC BY-IGO (educational use allowed, attribution required) |
| Coverage | Jan 2000 – Aug 2026, monthly |
| Size | 157,793 price rows · 109 markets · 65 commodities · 5 provinces · 29 districts |
| Personal data | None (market-level prices only) |

Downloaded 2026-11-04 from the link above. Units: KG, L, Sack, Unit. Price types: Retail (157,124 rows), Wholesale (669).

## Columns (raw file)
`date, admin1, admin2, market, market_id, latitude, longitude, category, commodity, commodity_id,
unit, priceflag, pricetype, currency, price, usdprice`

## Sample records
| date | admin1 | admin2 | market | commodity | unit | pricetype | price (RWF) |
|---|---|---|---|---|---|---|---|
| 2000-01-15 | Kigali City | Nyarugenge | Kigali | Maize | KG | Wholesale | 206.11 |
| 2000-01-15 | Kigali City | Nyarugenge | Kigali | Beans | KG | Wholesale | 108.02 |
| 2026-08-15 | Western Province | Karongi | Kiziba (Camp) | Beans (dry) | KG | Retail | 1122.22 |

## Normalization notes (for Phase II)
- `admin1 → admin2 → market` repeats on every row → split into PROVINCE, DISTRICT, MARKET (removes transitive dependencies).
- `category` depends on `commodity`, not on the observation → CATEGORY and COMMODITY.
- `usdprice` is derived from `price` and the month's exchange rate → EXCHANGE_RATE table; do not store it on each row.
- `currency` is RWF on all 157,793 rows (checked) → a constant, so it is dropped.
- `priceflag` holds a combined value `actual,aggregate` on 6,520 rows → not atomic (violates 1NF); split it into a lookup table or flags in Phase II.
