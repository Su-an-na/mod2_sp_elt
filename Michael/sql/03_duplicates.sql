-- Test 03A: Count duplicate ticker-date groups
SELECT
    COUNT(*) AS duplicate_groups,
    COALESCE(SUM(record_count - 1), 0) AS extra_duplicate_rows
FROM (
    SELECT
        ticker,
        date,
        COUNT(*) AS record_count
    FROM raw_sp500
    GROUP BY ticker, date
    HAVING COUNT(*) > 1
);

-- Test 03B: Show the actual duplicate records, if any
SELECT
    ticker,
    date,
    COUNT(*) AS record_count
FROM raw_sp500
GROUP BY ticker, date
HAVING COUNT(*) > 1
ORDER BY record_count DESC, ticker, date;
