WITH profiled AS (
    SELECT
        date,
        ticker,
        company,
        close,
        shares_out,
        mkt_cap,
        LAG(shares_out) OVER (
            PARTITION BY ticker
            ORDER BY date
        ) AS previous_shares_out
    FROM raw_sp500
)

SELECT
    date,
    ticker,
    company,
    previous_shares_out,
    shares_out,
    ROUND(
        shares_out / previous_shares_out,
        6
    ) AS share_count_ratio,
    close,
    mkt_cap
FROM profiled
WHERE shares_out IS NOT NULL
  AND previous_shares_out IS NOT NULL
  AND shares_out > 0
  AND previous_shares_out > 0
  AND (
        shares_out / previous_shares_out >= 100
        OR shares_out / previous_shares_out <= 0.01
      )
ORDER BY ticker, date;
