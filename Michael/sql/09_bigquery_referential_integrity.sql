WITH dim AS (
  SELECT
    COUNT(*) AS dim_rows,
    COUNT(DISTINCT ticker) AS dim_tickers,
    COUNTIF(ticker IS NULL OR TRIM(ticker) = '') AS dim_blank_ticker
  FROM `dsaimodule2-509312.proj2sp500.dim_ticker`
),

fact AS (
  SELECT
    COUNT(*) AS fact_rows,
    COUNT(DISTINCT ticker) AS fact_tickers,
    COUNTIF(ticker IS NULL OR TRIM(ticker) = '') AS fact_blank_ticker,
    COUNT(DISTINCT CONCAT(ticker, '|', CAST(date AS STRING))) AS fact_ticker_date_pairs
  FROM `dsaimodule2-509312.proj2sp500.fact_dailyprice`
),

orphans AS (
  SELECT
    COUNT(*) AS orphan_fact_rows,
    COUNT(DISTINCT f.ticker) AS orphan_tickers
  FROM `dsaimodule2-509312.proj2sp500.fact_dailyprice` f
  LEFT JOIN `dsaimodule2-509312.proj2sp500.dim_ticker` d
    ON f.ticker = d.ticker
  WHERE d.ticker IS NULL
)

SELECT *
FROM dim
CROSS JOIN fact
CROSS JOIN orphans;
