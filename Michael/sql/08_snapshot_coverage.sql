WITH bounds AS (
    SELECT
        MIN(date) AS first_date,
        MAX(date) AS latest_date
    FROM raw_sp500
),

ticker_coverage AS (
    SELECT
        ticker,
        MIN(date) AS ticker_first_date,
        MAX(date) AS ticker_last_date
    FROM raw_sp500
    GROUP BY ticker
),

latest_snapshot AS (
    SELECT r.*
    FROM raw_sp500 r
    CROSS JOIN bounds b
    WHERE r.date = b.latest_date
)

SELECT
    'distinct_sectors_full_dataset' AS metric,
    COUNT(DISTINCT sector)::BIGINT AS metric_value
FROM raw_sp500

UNION ALL

SELECT
    'tickers_on_first_date',
    COUNT(DISTINCT r.ticker)
FROM raw_sp500 r
CROSS JOIN bounds b
WHERE r.date = b.first_date

UNION ALL

SELECT
    'tickers_on_latest_date',
    COUNT(DISTINCT r.ticker)
FROM raw_sp500 r
CROSS JOIN bounds b
WHERE r.date = b.latest_date

UNION ALL

SELECT
    'tickers_present_first_and_latest',
    COUNT(*)
FROM ticker_coverage t
CROSS JOIN bounds b
WHERE t.ticker_first_date = b.first_date
  AND t.ticker_last_date = b.latest_date

UNION ALL

SELECT
    'tickers_entered_after_first_date',
    COUNT(*)
FROM ticker_coverage t
CROSS JOIN bounds b
WHERE t.ticker_first_date > b.first_date

UNION ALL

SELECT
    'tickers_exited_before_latest_date',
    COUNT(*)
FROM ticker_coverage t
CROSS JOIN bounds b
WHERE t.ticker_last_date < b.latest_date

UNION ALL

SELECT
    'latest_snapshot_distinct_dates',
    COUNT(DISTINCT date)
FROM latest_snapshot

UNION ALL

SELECT
    'latest_snapshot_missing_market_cap',
    COUNT(*)
FROM latest_snapshot
WHERE mkt_cap IS NULL

UNION ALL

SELECT
    'latest_snapshot_missing_shares_out',
    COUNT(*)
FROM latest_snapshot
WHERE shares_out IS NULL;
