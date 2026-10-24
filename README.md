# The Geopolitics of Energy: Asymmetric Macroeconomic Impact of the 2026 Gulf Crisis

Advanced Econometrics research project, Tunis Business School (May 2026).

**Authors:** Mohamed Aziz Ben Mustapha, Hiba Touati, Houwayda Amorri, Anas Mokhtar Atiki

## Overview

The 2026 Gulf Crisis caused a sudden oil supply shock, with Brent crude rising from roughly $65-85 to a peak of $117.29 per barrel after 27 February 2026. This project estimates how far that shock passed through to domestic consumer prices and industrial output in **emerging net-oil importers**: India, Poland, Thailand and Turkey.

A panel of **4 countries x 42 months (Jan 2023 - Jun 2026, N = 168)** is analysed with fixed-effects regressions and cluster-robust standard errors.

## Key findings (as reported)

| Result | Estimate |
|---|---|
| Oil shock to CPI (FE) | beta = 0.000326, p = 0.007 (about 0.033% per 1% oil price rise) |
| Exchange rate pass-through, ln(NEER) | -0.343, p < 0.001 (1% appreciation lowers CPI by about 0.34%) |
| Post-crisis baseline shift | +0.0216 (about 2.16%), p < 0.001 |
| Model fit (FE, within) | R-squared = 0.812 |
| Oil shock to industrial output (FE) | beta = -0.000895, p = 0.021 |
| Breusch-Pagan LM test | chi2 = 104.53, p < 2.2e-16 (country effects needed) |
| Hausman test | chi2 = 38.92, p = 2.46e-7 (Fixed Effects preferred over Random Effects) |

## Method

1. **Data cleaning:** rebuild dates from numeric year and month columns in R.
2. **Data enrichment:** country-specific ARIMA models (AIC-selected, trained on Jan 2023 - Mar 2026) forecast April-June 2026.
3. **Exploratory analysis:** summary statistics and ggplot2 visualisations.
4. **Estimation:** Pooled OLS, Random Effects and Fixed Effects (within), with Arellano cluster-robust standard errors.
5. **Specification tests:** Breusch-Pagan LM and Hausman.
6. **Extensions:** oil shock x post-crisis interaction, country-level regressions and subsample comparisons.

Model (inflation):

```
ln(CPI)_it = a_i + b1 oil_shock_it + b2 ln(NEER)_it + b3 interest_rate_it + b4 vix_it + b5 post_crisis_it + e_it
```

## Repository structure

```
.
├── analysis/
│   └── gulf_crisis_analysis.R   # full pipeline
├── data/
│   └── DATA_DICTIONARY.md       # expected columns of panel_data.csv
├── docs/                        # put the PDF report here
├── figures/                     # generated plots
├── outputs/                     # generated tables
└── README.md
```

## How to run

1. Install R (4.x) and RStudio.
2. Create `data/panel_data.csv` following [`data/DATA_DICTIONARY.md`](data/DATA_DICTIONARY.md).
3. From the project root, run:

```r
source("analysis/gulf_crisis_analysis.R")
```

The script installs the required packages (`dplyr`, `tidyr`, `ggplot2`, `plm`, `lmtest`, `sandwich`, `forecast`) if they are missing, then writes figures to `figures/` and tables to `outputs/`.

## Data sources

- Brent spot price: U.S. Energy Information Administration (EIA)
- Effective exchange rates: Bank for International Settlements (BIS)
- CPI, industrial production and other macro series: IMF International Financial Statistics

## Limitations

- April-June 2026 values come from ARIMA forecasts, which may smooth out real short-term movements.
- Only four countries (clusters) are used, so cluster-robust standard errors may be unreliable with so few groups.
- The static linear panel does not capture lags or asymmetric responses. Dynamic panels (Difference or System GMM) are suggested for future work.
- The crisis period covers only four of the 42 months.

## Report

The full report is in `docs/` (add the PDF before pushing).
