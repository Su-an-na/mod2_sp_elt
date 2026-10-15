WITH raw AS (
  SELECT *
  FROM `dsaimodule2-509312.proj2sp500.public_proj2_sp500`
),

fact AS (
  SELECT *
  FROM `dsaimodule2-509312.proj2sp500.fact_dailyprice`
),

raw_stats AS (
  SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT ticker) AS ticker_count,
    MIN(SAFE_CAST(date AS DATE)) AS min_date,
    MAX(SAFE_CAST(date AS DATE)) AS max_date,
    COUNTIF(
      date IS NOT NULL
      AND SAFE_CAST(date AS DATE) IS NULL
    ) AS invalid_date_count
  FROM raw
),

fact_stats AS (
  SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT ticker) AS ticker_count,
    MIN(date) AS min_date,
    MAX(date) AS max_date
  FROM fact
),

raw_duplicates AS (
  SELECT
    COALESCE(SUM(record_count - 1), 0) AS extra_duplicate_rows
  FROM (
    SELECT
      ticker,
      SAFE_CAST(date AS DATE) AS trade_date,
      COUNT(*) AS record_count
    FROM raw
    GROUP BY ticker, trade_date
    HAVING COUNT(*) > 1
  )
),

raw_not_fact AS (
  SELECT COUNT(*) AS mismatch_count
  FROM (
    SELECT
      ticker,
      SAFE_CAST(date AS DATE) AS trade_date
    FROM raw

    EXCEPT DISTINCT

    SELECT
      ticker,
      date AS trade_date
    FROM fact
  )
),

fact_not_raw AS (
  SELECT COUNT(*) AS mismatch_count
  FROM (
    SELECT
      ticker,
      date AS trade_date
    FROM fact

    EXCEPT DISTINCT

    SELECT
      ticker,
      SAFE_CAST(date AS DATE) AS trade_date
    FROM raw
  )
),

calculated AS (
  SELECT
    *,

    LAG(close) OVER (
      PARTITION BY ticker
      ORDER BY date
    ) AS previous_close,

    AVG(close) OVER (
      PARTITION BY ticker
      ORDER BY date
      ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
    ) AS calculated_sma_20,

    COUNT(close) OVER (
      PARTITION BY ticker
      ORDER BY date
      ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
    ) AS count_20,

    AVG(close) OVER (
      PARTITION BY ticker
      ORDER BY date
      ROWS BETWEEN 49 PRECEDING AND CURRENT ROW
    ) AS calculated_sma_50,

    COUNT(close) OVER (
      PARTITION BY ticker
      ORDER BY date
      ROWS BETWEEN 49 PRECEDING AND CURRENT ROW
    ) AS count_50,

    AVG(close) OVER (
      PARTITION BY ticker
      ORDER BY date
      ROWS BETWEEN 99 PRECEDING AND CURRENT ROW
    ) AS calculated_sma_100,

    COUNT(close) OVER (
      PARTITION BY ticker
      ORDER BY date
      ROWS BETWEEN 99 PRECEDING AND CURRENT ROW
    ) AS count_100,

    AVG(close) OVER (
      PARTITION BY ticker
      ORDER BY date
      ROWS BETWEEN 199 PRECEDING AND CURRENT ROW
    ) AS calculated_sma_200,

    COUNT(close) OVER (
      PARTITION BY ticker
      ORDER BY date
      ROWS BETWEEN 199 PRECEDING AND CURRENT ROW
    ) AS count_200

  FROM fact
),

derived_checks AS (
  SELECT

    COUNTIF(
      previous_close IS NULL
      AND daily_return IS NOT NULL
    ) AS return_first_row_nonnull,

    COUNTIF(
      previous_close IS NOT NULL
      AND daily_return IS NULL
    ) AS return_missing_after_first,

    COUNTIF(
      previous_close IS NOT NULL
      AND daily_return IS NOT NULL
      AND ABS(
        daily_return -
        SAFE_DIVIDE(close - previous_close, previous_close)
      ) > 0.000001
    ) AS return_decimal_mismatch,

    COUNTIF(
      previous_close IS NOT NULL
      AND daily_return IS NOT NULL
      AND ABS(
        daily_return -
        SAFE_DIVIDE(close - previous_close, previous_close) * 100
      ) > 0.000001
    ) AS return_percent_mismatch,

    COUNTIF(count_20 < 20 AND sma_20 IS NOT NULL)
      AS sma20_early_nonnull,

    COUNTIF(
      count_20 = 20
      AND (
        sma_20 IS NULL
        OR ABS(sma_20 - calculated_sma_20) > 0.000001
      )
    ) AS sma20_mismatch,

    COUNTIF(count_50 < 50 AND sma_50 IS NOT NULL)
      AS sma50_early_nonnull,

    COUNTIF(
      count_50 = 50
      AND (
        sma_50 IS NULL
        OR ABS(sma_50 - calculated_sma_50) > 0.000001
      )
    ) AS sma50_mismatch,

    COUNTIF(count_100 < 100 AND sma_100 IS NOT NULL)
      AS sma100_early_nonnull,

    COUNTIF(
      count_100 = 100
      AND (
        sma_100 IS NULL
        OR ABS(sma_100 - calculated_sma_100) > 0.000001
      )
    ) AS sma100_mismatch,

    COUNTIF(count_200 < 200 AND sma_200 IS NOT NULL)
      AS sma200_early_nonnull,

    COUNTIF(
      count_200 = 200
      AND (
        sma_200 IS NULL
        OR ABS(sma_200 - calculated_sma_200) > 0.000001
      )
    ) AS sma200_mismatch

  FROM calculated
)

SELECT
  'Source reconciliation' AS category,
  'Raw invalid date values' AS test_name,
  r.invalid_date_count AS failed_count,
  IF(r.invalid_date_count = 0, 'PASS', 'FAIL') AS status,
  'Raw STRING dates must convert successfully to DATE' AS detail
FROM raw_stats r

UNION ALL

SELECT
  'Source reconciliation',
  'Raw vs fact row count',
  ABS(r.row_count - f.row_count),
  IF(r.row_count = f.row_count, 'PASS', 'FAIL'),
  CONCAT(
    'raw=', CAST(r.row_count AS STRING),
    ', fact=', CAST(f.row_count AS STRING)
  )
FROM raw_stats r
CROSS JOIN fact_stats f

UNION ALL

SELECT
  'Source reconciliation',
  'Raw vs fact ticker count',
  ABS(r.ticker_count - f.ticker_count),
  IF(r.ticker_count = f.ticker_count, 'PASS', 'FAIL'),
  CONCAT(
    'raw=', CAST(r.ticker_count AS STRING),
    ', fact=', CAST(f.ticker_count AS STRING)
  )
FROM raw_stats r
CROSS JOIN fact_stats f

UNION ALL

SELECT
  'Source reconciliation',
  'Raw vs fact date range',
  IF(
    r.min_date = f.min_date
    AND r.max_date = f.max_date,
    0, 1
  ),
  IF(
    r.min_date = f.min_date
    AND r.max_date = f.max_date,
    'PASS', 'FAIL'
  ),
  CONCAT(
    'raw=', CAST(r.min_date AS STRING), ' to ',
    CAST(r.max_date AS STRING),
    ', fact=', CAST(f.min_date AS STRING), ' to ',
    CAST(f.max_date AS STRING)
  )
FROM raw_stats r
CROSS JOIN fact_stats f

UNION ALL

SELECT
  'Source reconciliation',
  'Raw duplicate ticker-date rows',
  extra_duplicate_rows,
  IF(extra_duplicate_rows = 0, 'PASS', 'FAIL'),
  'Extra rows beyond one record per ticker-date'
FROM raw_duplicates

UNION ALL

SELECT
  'Source reconciliation',
  'Raw keys missing from fact',
  mismatch_count,
  IF(mismatch_count = 0, 'PASS', 'FAIL'),
  'Ticker-date keys present in raw but absent from transformed fact'
FROM raw_not_fact

UNION ALL

SELECT
  'Source reconciliation',
  'Unexpected fact keys',
  mismatch_count,
  IF(mismatch_count = 0, 'PASS', 'FAIL'),
  'Ticker-date keys created in fact but absent from raw'
FROM fact_not_raw

UNION ALL

SELECT
  'Daily return',
  'First observation should have no prior-day return',
  return_first_row_nonnull,
  IF(return_first_row_nonnull = 0, 'PASS', 'REVIEW'),
  'First observation for each ticker has no previous close'
FROM derived_checks

UNION ALL

SELECT
  'Daily return',
  'Missing daily return after first observation',
  return_missing_after_first,
  IF(return_missing_after_first = 0, 'PASS', 'REVIEW'),
  'Checks unexpected NULL daily returns'
FROM derived_checks

UNION ALL

SELECT
  'Daily return',
  'Decimal-return formula mismatch',
  return_decimal_mismatch,
  IF(return_decimal_mismatch = 0, 'MATCH', 'REVIEW'),
  'Candidate formula: (close - previous_close) / previous_close'
FROM derived_checks

UNION ALL

SELECT
  'Daily return',
  'Percentage-return formula mismatch',
  return_percent_mismatch,
  IF(return_percent_mismatch = 0, 'MATCH', 'REVIEW'),
  'Candidate formula: decimal return x 100'
FROM derived_checks

UNION ALL

SELECT
  'SMA',
  'SMA 20 populated before 20 observations',
  sma20_early_nonnull,
  IF(sma20_early_nonnull = 0, 'PASS', 'REVIEW'),
  'A full 20-day SMA normally requires 20 observations'
FROM derived_checks

UNION ALL

SELECT
  'SMA',
  'SMA 20 calculation mismatch',
  sma20_mismatch,
  IF(sma20_mismatch = 0, 'PASS', 'FAIL'),
  'Compared with AVG(close) over current and previous 19 observations'
FROM derived_checks

UNION ALL

SELECT
  'SMA',
  'SMA 50 populated before 50 observations',
  sma50_early_nonnull,
  IF(sma50_early_nonnull = 0, 'PASS', 'REVIEW'),
  'A full 50-day SMA normally requires 50 observations'
FROM derived_checks

UNION ALL

SELECT
  'SMA',
  'SMA 50 calculation mismatch',
  sma50_mismatch,
  IF(sma50_mismatch = 0, 'PASS', 'FAIL'),
  'Compared with AVG(close) over current and previous 49 observations'
FROM derived_checks

UNION ALL

SELECT
  'SMA',
  'SMA 100 populated before 100 observations',
  sma100_early_nonnull,
  IF(sma100_early_nonnull = 0, 'PASS', 'REVIEW'),
  'A full 100-day SMA normally requires 100 observations'
FROM derived_checks

UNION ALL

SELECT
  'SMA',
  'SMA 100 calculation mismatch',
  sma100_mismatch,
  IF(sma100_mismatch = 0, 'PASS', 'FAIL'),
  'Compared with AVG(close) over current and previous 99 observations'
FROM derived_checks

UNION ALL

SELECT
  'SMA',
  'SMA 200 populated before 200 observations',
  sma200_early_nonnull,
  IF(sma200_early_nonnull = 0, 'PASS', 'REVIEW'),
  'A full 200-day SMA normally requires 200 observations'
FROM derived_checks

UNION ALL

SELECT
  'SMA',
  'SMA 200 calculation mismatch',
  sma200_mismatch,
  IF(sma200_mismatch = 0, 'PASS', 'FAIL'),
  'Compared with AVG(close) over current and previous 199 observations'
FROM derived_checks

ORDER BY category, test_name;
