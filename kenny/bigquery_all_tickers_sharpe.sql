-- Sharpe ratio for every ticker over the last 1, 2, 3, 5 years (BigQuery)
-- Daily Sharpe = mean(daily return - daily risk-free rate) / stdev(daily return); annualised x SQRT(252).
-- Works whether `date` was loaded as DATE or as text.
WITH params AS (
  SELECT POW(1 + 0.04, 1 / 252) - 1 AS rf_daily
),
prices AS (
  SELECT ticker, SAFE_CAST(`date` AS DATE) AS d, adj_close
  FROM `your_project.your_dataset.sp500_panel`
  WHERE adj_close IS NOT NULL
),
returns AS (
  SELECT ticker, d, adj_close / LAG(adj_close) OVER (PARTITION BY ticker ORDER BY d) - 1 AS r
  FROM prices
),
first_day AS (
  SELECT ticker, MIN(d) AS first_d FROM prices GROUP BY ticker
),
windows AS (
  SELECT h AS horizon_years, DATE_SUB(MAX(d), INTERVAL h YEAR) AS start_date, MAX(d) AS end_date
  FROM prices, UNNEST([1, 2, 3, 5]) AS h
  GROUP BY h
)
SELECT
  r.ticker,
  w.horizon_years,
  w.start_date,
  w.end_date,
  COUNT(r.r)                                              AS trading_days,
  AVG(r.r)                                                AS daily_mean_return,
  STDDEV_SAMP(r.r)                                        AS daily_volatility,
  SAFE_DIVIDE(AVG(r.r) - ANY_VALUE(p.rf_daily), STDDEV_SAMP(r.r))                   AS sharpe_daily,
  SAFE_DIVIDE(AVG(r.r) - ANY_VALUE(p.rf_daily), STDDEV_SAMP(r.r)) * SQRT(252) AS sharpe_ratio,
  AVG(r.r) * 252                               AS annual_return,
  STDDEV_SAMP(r.r) * SQRT(252)                 AS annual_volatility,
  EXP(SUM(LN(1 + r.r))) - 1                               AS total_return
FROM returns AS r
JOIN first_day AS f USING (ticker)
CROSS JOIN windows AS w
CROSS JOIN params AS p
WHERE r.r IS NOT NULL
  AND r.d > w.start_date
  AND r.d <= w.end_date
  AND f.first_d <= w.start_date            -- only stocks listed for the whole window
GROUP BY r.ticker, w.horizon_years, w.start_date, w.end_date
ORDER BY w.horizon_years, sharpe_ratio DESC
