-- =====================================================================================
-- One ticker: 20/50/100/200-day moving averages, daily returns, and the Sharpe ratio
-- between two dates (BigQuery).
--
-- Before running: replace `your_project.your_dataset.sp500_panel` (4 places) with your table,
-- then set the four values below. Run the whole file as one script.
-- Works whether the `date` column was loaded as DATE (with sp500_panel_schema.json) or as text.
--
-- Adds to the table: sma_20, sma_50, sma_100, sma_200, daily_return (filled for the chosen ticker).
-- =====================================================================================

DECLARE target_ticker STRING  DEFAULT 'NVDA';
DECLARE start_date    DATE    DEFAULT DATE '2024-01-02';   -- X: the period starts at this day's close
DECLARE end_date      DATE    DEFAULT DATE '2025-12-31';   -- Y: and ends at this day's close
DECLARE annual_rf     FLOAT64 DEFAULT 0.04;                -- annual risk-free rate, e.g. average 3-month T-bill yield


-- 1. New columns (safe to re-run).
ALTER TABLE `your_project.your_dataset.sp500_panel`
  ADD COLUMN IF NOT EXISTS sma_20       FLOAT64,
  ADD COLUMN IF NOT EXISTS sma_50       FLOAT64,
  ADD COLUMN IF NOT EXISTS sma_100      FLOAT64,
  ADD COLUMN IF NOT EXISTS sma_200      FLOAT64,
  ADD COLUMN IF NOT EXISTS daily_return FLOAT64;


-- 2. Fill them for the chosen ticker.
--    Moving averages use `close` (what a price chart shows) and stay NULL until the window is full.
--    daily_return uses `adj_close`, so it includes dividends.
--    To fill every ticker at once, delete the line `WHERE ticker = target_ticker`.
UPDATE `your_project.your_dataset.sp500_panel` AS t
SET
  sma_20       = s.sma_20,
  sma_50       = s.sma_50,
  sma_100      = s.sma_100,
  sma_200      = s.sma_200,
  daily_return = s.daily_return
FROM (
  SELECT
    ticker,
    `date`,
    IF(COUNT(close) OVER w20  = 20,  AVG(close) OVER w20,  NULL) AS sma_20,
    IF(COUNT(close) OVER w50  = 50,  AVG(close) OVER w50,  NULL) AS sma_50,
    IF(COUNT(close) OVER w100 = 100, AVG(close) OVER w100, NULL) AS sma_100,
    IF(COUNT(close) OVER w200 = 200, AVG(close) OVER w200, NULL) AS sma_200,
    adj_close / LAG(adj_close) OVER (PARTITION BY ticker ORDER BY SAFE_CAST(`date` AS DATE)) - 1 AS daily_return
  FROM `your_project.your_dataset.sp500_panel`
  WHERE ticker = target_ticker
  WINDOW
    w20  AS (PARTITION BY ticker ORDER BY SAFE_CAST(`date` AS DATE) ROWS BETWEEN 19  PRECEDING AND CURRENT ROW),
    w50  AS (PARTITION BY ticker ORDER BY SAFE_CAST(`date` AS DATE) ROWS BETWEEN 49  PRECEDING AND CURRENT ROW),
    w100 AS (PARTITION BY ticker ORDER BY SAFE_CAST(`date` AS DATE) ROWS BETWEEN 99  PRECEDING AND CURRENT ROW),
    w200 AS (PARTITION BY ticker ORDER BY SAFE_CAST(`date` AS DATE) ROWS BETWEEN 199 PRECEDING AND CURRENT ROW)
) AS s
WHERE t.ticker = s.ticker
  AND t.`date` = s.`date`;


-- 3. Sharpe ratio from the close on X to the close on Y.
--    Sharpe = mean(daily return - daily risk-free rate) / stdev(daily return) * SQRT(252).
WITH period AS (
  SELECT daily_return
  FROM `your_project.your_dataset.sp500_panel`
  WHERE ticker = target_ticker
    AND SAFE_CAST(`date` AS DATE) > start_date
    AND SAFE_CAST(`date` AS DATE) <= end_date
    AND daily_return IS NOT NULL
),
params AS (
  SELECT POW(1 + annual_rf, 1 / 252) - 1 AS rf_daily
)
SELECT
  target_ticker                                                         AS ticker,
  start_date,
  end_date,
  COUNT(*)                                                              AS trading_days,
  EXP(SUM(LN(1 + daily_return))) - 1                                    AS total_return,
  AVG(daily_return) * 252                                               AS annual_return,
  STDDEV_SAMP(daily_return) * SQRT(252)                                 AS annual_volatility,
  annual_rf                                                             AS risk_free_rate,
  SAFE_DIVIDE(AVG(daily_return) - ANY_VALUE(rf_daily), STDDEV_SAMP(daily_return)) * SQRT(252) AS sharpe_ratio
FROM period CROSS JOIN params;
