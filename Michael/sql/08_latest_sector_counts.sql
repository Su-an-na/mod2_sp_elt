WITH latest_date AS (
    SELECT MAX(date) AS max_date
    FROM raw_sp500
)

SELECT
    r.sector,
    COUNT(DISTINCT r.ticker) AS stock_count,
    COUNT(*) AS row_count,
    COUNT(r.mkt_cap) AS stocks_with_market_cap,
    COUNT(*) - COUNT(r.mkt_cap) AS stocks_missing_market_cap
FROM raw_sp500 r
CROSS JOIN latest_date d
WHERE r.date = d.max_date
GROUP BY r.sector
ORDER BY stock_count DESC, r.sector;
