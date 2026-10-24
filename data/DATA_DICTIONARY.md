# Data dictionary

Expected file: `data/panel_data.csv`  (one row per country-month, long format)

Sample: 4 countries (India, Poland, Thailand, Turkey) x 42 months (Jan 2023 - Jun 2026) = 168 observations.
Leave the values for months that are not yet published as empty (`NA`); the script fills them with country-specific ARIMA forecasts.

| Column | Type | Description | Source (per report) |
|---|---|---|---|
| `country` | text | India, Poland, Thailand, Turkey | n/a |
| `year` | integer | Calendar year | n/a |
| `month` | integer | Calendar month (1-12) | n/a |
| `cpi` | numeric | Consumer Price Index (level) | IMF International Financial Statistics |
| `ipi` | numeric | Industrial Production Index (level) | IMF International Financial Statistics |
| `brent` | numeric | Brent crude spot price, USD per barrel (same value for all countries in a month) | U.S. EIA |
| `neer` | numeric | Nominal Effective Exchange Rate index | BIS |
| `interest_rate` | numeric | Nominal central bank policy rate, % | n/a |
| `vix` | numeric | CBOE VIX, global financial stress index (same value for all countries in a month) | n/a |

## Variables built by the script

| Variable | Definition |
|---|---|
| `date` | `as.Date(paste(year, month, "01", sep = "-"))` |
| `ln_cpi`, `ln_ipi`, `ln_neer` | Natural logs of `cpi`, `ipi`, `neer` |
| `oil_shock` | Monthly percentage change in Brent |
| `post_crisis` | 1 for months after 27 Feb 2026 (March 2026 onward), else 0 |
| `oil_x_crisis` | `oil_shock * post_crisis` (interaction model) |

Raw data files are not included in this repository unless their licences allow redistribution. Download them from the sources above.
