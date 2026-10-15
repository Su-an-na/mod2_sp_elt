WITH profiled AS (
    SELECT
        *,
        LAG(shares_out) OVER (
            PARTITION BY ticker
            ORDER BY date
        ) AS previous_shares_out
    FROM raw_sp500
)

SELECT
    'missing_market_cap' AS test_name,
    COUNT(*) AS failed_rows
FROM profiled
WHERE mkt_cap IS NULL

UNION ALL

SELECT
    'missing_shares_out',
    COUNT(*)
FROM profiled
WHERE shares_out IS NULL

UNION ALL

SELECT
    'non_positive_market_cap',
    COUNT(*)
FROM profiled
WHERE mkt_cap IS NOT NULL
  AND mkt_cap <= 0

UNION ALL

SELECT
    'non_positive_shares_out',
    COUNT(*)
FROM profiled
WHERE shares_out IS NOT NULL
  AND shares_out <= 0

UNION ALL

SELECT
    'market_cap_reconciliation_over_1pct',
    COUNT(*)
FROM profiled
WHERE mkt_cap IS NOT NULL
  AND shares_out IS NOT NULL
  AND close IS NOT NULL
  AND mkt_cap > 0
  AND ABS(
        mkt_cap - (close * shares_out)
      ) / mkt_cap > 0.01

UNION ALL

SELECT
    'share_count_scale_jump_100x',
    COUNT(*)
FROM profiled
WHERE shares_out IS NOT NULL
  AND previous_shares_out IS NOT NULL
  AND shares_out > 0
  AND previous_shares_out > 0
  AND (
        shares_out / previous_shares_out >= 100
        OR shares_out / previous_shares_out <= 0.01
      );
