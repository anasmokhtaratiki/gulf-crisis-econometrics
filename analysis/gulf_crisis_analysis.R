# ==============================================================================
# The Geopolitics of Energy: Asymmetric Macroeconomic Impact of the 2026 Gulf Crisis
# Advanced Econometrics, Tunis Business School
#
# Pipeline: load -> build date -> ARIMA enrichment -> EDA -> panel models
#           (POLS / FE / RE) -> diagnostics (BP-LM, Hausman) -> interaction models
#
# Input : data/panel_data.csv   (see data/DATA_DICTIONARY.md)
# Output: figures/*.png and outputs/*.csv
#
# NOTE: reconstruction of the workflow described in the report. Run it on your
# data and compare the results with the report before publishing.
# ==============================================================================

pkgs <- c("dplyr", "tidyr", "ggplot2", "plm", "lmtest", "sandwich", "forecast")
new  <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(new)) install.packages(new)
invisible(lapply(pkgs, library, character.only = TRUE))

dir.create("figures", showWarnings = FALSE)
dir.create("outputs", showWarnings = FALSE)

# ---- 1. Load data and build the timeline ------------------------------------
raw <- read.csv("data/panel_data.csv", stringsAsFactors = FALSE)

# Rebuild dates from numeric year/month to avoid spreadsheet date-format issues
raw$date <- as.Date(paste(raw$year, raw$month, "01", sep = "-"))

# Complete country x month grid so missing months show up as NA
grid <- expand.grid(
  country = unique(raw$country),
  date    = seq(as.Date("2023-01-01"), as.Date("2026-06-01"), by = "month"),
  stringsAsFactors = FALSE
)
df <- grid |>
  left_join(raw |> select(-year, -month), by = c("country", "date")) |>
  arrange(country, date)

# ---- 2. ARIMA enrichment of missing months ----------------------------------
# Each series is modelled per country on Jan 2023 - Mar 2026 (auto.arima picks
# the specification by AIC) and forecasts the missing months.
train_end <- as.Date("2026-03-01")
vars      <- c("cpi", "ipi", "brent", "neer", "interest_rate", "vix")

fill_arima <- function(d, v) {
  miss <- which(is.na(d[[v]]))
  if (length(miss) == 0) return(d)
  hist <- d[d$date <= train_end & !is.na(d[[v]]), ]
  fit  <- auto.arima(ts(hist[[v]], start = c(2023, 1), frequency = 12), ic = "aic")
  fc   <- forecast(fit, h = length(miss))$mean
  d[[v]][miss] <- as.numeric(fc)
  d
}

df <- do.call(rbind, lapply(split(df, df$country), function(d) {
  for (v in vars) d <- fill_arima(d, v)
  d
}))
rownames(df) <- NULL

# ---- 3. Variable construction -----------------------------------------------
brent_m <- df |>
  distinct(date, brent) |>
  arrange(date) |>
  mutate(oil_shock = 100 * (brent / lag(brent) - 1))   # monthly % change

df <- df |>
  left_join(brent_m |> select(date, oil_shock), by = "date") |>
  mutate(
    ln_cpi       = log(cpi),
    ln_ipi       = log(ipi),
    ln_neer      = log(neer),
    post_crisis  = as.integer(date > as.Date("2026-02-27")),
    oil_x_crisis = oil_shock * post_crisis
  ) |>
  filter(!is.na(oil_shock))   # first month has no percentage change

write.csv(df, "outputs/panel_clean.csv", row.names = FALSE)

# ---- 4. Exploratory analysis ------------------------------------------------
sink("outputs/summary_statistics.txt")
print(summary(df[, c("cpi", "ipi", "brent", "interest_rate", "vix")]))
sink()

p1 <- ggplot(brent_m, aes(date, brent)) +
  geom_line(colour = "darkred", linewidth = 1.2) +
  geom_vline(xintercept = as.Date("2026-02-27"), linetype = "dashed", colour = "blue") +
  labs(title = "Global Brent Crude Oil Price Trend",
       subtitle = "Exogenous Geopolitical Shock Timeline",
       x = "Timeline (2023 - 2026)", y = "USD per Barrel") +
  theme_minimal()
ggsave("figures/fig1_brent_trend.png", p1, width = 8, height = 5, dpi = 300)

p2 <- ggplot(df, aes(date, ln_cpi, colour = country)) +
  geom_line(linewidth = 1.1) +
  geom_vline(xintercept = as.Date("2026-02-27"), linetype = "dashed") +
  labs(title = "Log CPI Trends Across Emerging Importers",
       subtitle = "Comparing Country Heterogeneity Post-March 2026",
       x = "Timeline (2023 - 2026)", y = "Natural Log of CPI (ln_cpi)", colour = "Country") +
  theme_minimal()
ggsave("figures/fig2_log_cpi_trends.png", p2, width = 8, height = 5, dpi = 300)

# ---- 5. Panel models ---------------------------------------------------------
pdata <- pdata.frame(df, index = c("country", "date"))

f_cpi <- ln_cpi ~ oil_shock + ln_neer + interest_rate + vix + post_crisis
f_ipi <- ln_ipi ~ oil_shock + ln_neer + interest_rate + vix + post_crisis

fit_models <- function(f) list(
  POLS = plm(f, data = pdata, model = "pooling"),
  FE   = plm(f, data = pdata, model = "within"),
  RE   = plm(f, data = pdata, model = "random")
)
m_cpi <- fit_models(f_cpi)
m_ipi <- fit_models(f_ipi)

# Arellano cluster-robust covariance (clustered by country)
robust <- function(m) coeftest(m, vcov = vcovHC(m, method = "arellano", type = "HC3", cluster = "group"))

tidy_tab <- function(models) {
  do.call(rbind, lapply(names(models), function(n) {
    ct <- robust(models[[n]])
    data.frame(model = n, term = rownames(ct), ct[, 1:4], row.names = NULL)
  }))
}
write.csv(tidy_tab(m_cpi), "outputs/table_inflation_models.csv", row.names = FALSE)
write.csv(tidy_tab(m_ipi), "outputs/table_growth_models.csv",    row.names = FALSE)

cat("\n=== Fixed Effects, inflation (robust SE) ===\n"); print(robust(m_cpi$FE))
cat("\n=== Fixed Effects, growth (robust SE) ===\n");    print(robust(m_ipi$FE))

# ---- 6. Specification tests --------------------------------------------------
cat("\n=== Breusch-Pagan LM (POLS vs panel) ===\n")
print(plmtest(m_cpi$POLS, type = "bp"))
cat("\n=== Hausman (FE vs RE) ===\n")
print(phtest(m_cpi$FE, m_cpi$RE))

# Country fixed effects (alpha_i)
write.csv(data.frame(country = names(fixef(m_cpi$FE)), alpha = as.numeric(fixef(m_cpi$FE))),
          "outputs/country_fixed_effects.csv", row.names = FALSE)

# ---- 7. Interaction model and country-level regressions ---------------------
f_int <- ln_cpi ~ oil_shock + ln_neer + post_crisis + oil_x_crisis
m_int <- plm(f_int, data = pdata, model = "within")
cat("\n=== Interaction model (FE, robust SE) ===\n"); print(robust(m_int))

by_country <- do.call(rbind, lapply(split(df, df$country), function(d) {
  m  <- lm(ln_cpi ~ oil_shock + ln_neer + post_crisis + oil_x_crisis, data = d)
  ct <- coeftest(m, vcov = vcovHC(m, type = "HC3"))
  data.frame(country = d$country[1], term = rownames(ct), ct[, 1:4], row.names = NULL)
}))
write.csv(by_country, "outputs/table_country_interaction.csv", row.names = FALSE)

cat("\nDone. Figures in figures/, tables in outputs/\n")
