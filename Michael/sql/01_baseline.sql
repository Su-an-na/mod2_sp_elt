SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT ticker) AS distinct_tickers,
    MIN(date) AS earliest_date,
    MAX(date) AS latest_date
FROM raw_sp500;
