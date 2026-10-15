WITH bounds AS (
    SELECT
        MIN(date) AS first_date,
        MAX(date) AS latest_date
    FROM raw_sp500
),

ticker_coverage AS (
    SELECT
        ticker,
        ANY_VALUE(company) AS company,
        ANY_VALUE(sector) AS sector,
        MIN(date) AS ticker_first_date,
        MAX(date) AS ticker_last_date,
        COUNT(*) AS trading_rows
    FROM raw_sp500
    GROUP BY ticker
)

SELECT
    t.*,
    CASE
        WHEN t.ticker_first_date > b.first_date
             AND t.ticker_last_date = b.latest_date
            THEN 'ENTERED_LATER'
        WHEN t.ticker_first_date = b.first_date
             AND t.ticker_last_date < b.latest_date
            THEN 'EXITED_EARLY'
        WHEN t.ticker_first_date > b.first_date
             AND t.ticker_last_date < b.latest_date
            THEN 'PARTIAL_PERIOD'
        WHEN t.ticker_first_date = b.first_date
             AND t.ticker_last_date = b.latest_date
            THEN 'FULL_PERIOD'
        ELSE 'OTHER'
    END AS coverage_status
FROM ticker_coverage t
CROSS JOIN bounds b
ORDER BY coverage_status, ticker;
