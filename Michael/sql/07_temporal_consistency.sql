WITH quarterly AS (
    SELECT *
    FROM raw_sp500
    WHERE fiscal_period_end IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY ticker, fiscal_period_end
        ORDER BY date DESC
    ) = 1
),

lagged AS (
    SELECT
        *,
        LAG(shares_out) OVER (
            PARTITION BY ticker ORDER BY fiscal_period_end
        ) AS prev_shares_out,

        LAG(eps_diluted) OVER (
            PARTITION BY ticker ORDER BY fiscal_period_end
        ) AS prev_eps_diluted,

        LAG(eps_diluted_ttm) OVER (
            PARTITION BY ticker ORDER BY fiscal_period_end
        ) AS prev_eps_diluted_ttm,

        LAG(revenue_ps_ttm) OVER (
            PARTITION BY ticker ORDER BY fiscal_period_end
        ) AS prev_revenue_ps_ttm,

        LAG(assets_ps) OVER (
            PARTITION BY ticker ORDER BY fiscal_period_end
        ) AS prev_assets_ps,

        LAG(liabilities_ps) OVER (
            PARTITION BY ticker ORDER BY fiscal_period_end
        ) AS prev_liabilities_ps
    FROM quarterly
)

SELECT
    'shares_out_100x_quarter_jump' AS test_name,
    COUNT(*) AS flagged_events
FROM lagged
WHERE shares_out IS NOT NULL
  AND prev_shares_out IS NOT NULL
  AND shares_out > 0
  AND prev_shares_out > 0
  AND (
      shares_out / prev_shares_out >= 100
      OR shares_out / prev_shares_out <= 0.01
  )

UNION ALL

SELECT
    'eps_diluted_1000x_quarter_jump',
    COUNT(*)
FROM lagged
WHERE eps_diluted IS NOT NULL
  AND prev_eps_diluted IS NOT NULL
  AND ABS(eps_diluted) >= 0.01
  AND ABS(prev_eps_diluted) >= 0.01
  AND (
      ABS(eps_diluted / prev_eps_diluted) >= 1000
      OR ABS(eps_diluted / prev_eps_diluted) <= 0.001
  )

UNION ALL

SELECT
    'eps_ttm_1000x_quarter_jump',
    COUNT(*)
FROM lagged
WHERE eps_diluted_ttm IS NOT NULL
  AND prev_eps_diluted_ttm IS NOT NULL
  AND ABS(eps_diluted_ttm) >= 0.01
  AND ABS(prev_eps_diluted_ttm) >= 0.01
  AND (
      ABS(eps_diluted_ttm / prev_eps_diluted_ttm) >= 1000
      OR ABS(eps_diluted_ttm / prev_eps_diluted_ttm) <= 0.001
  )

UNION ALL

SELECT
    'revenue_per_share_100x_quarter_jump',
    COUNT(*)
FROM lagged
WHERE revenue_ps_ttm IS NOT NULL
  AND prev_revenue_ps_ttm IS NOT NULL
  AND revenue_ps_ttm > 0
  AND prev_revenue_ps_ttm > 0
  AND (
      revenue_ps_ttm / prev_revenue_ps_ttm >= 100
      OR revenue_ps_ttm / prev_revenue_ps_ttm <= 0.01
  )

UNION ALL

SELECT
    'assets_per_share_100x_quarter_jump',
    COUNT(*)
FROM lagged
WHERE assets_ps IS NOT NULL
  AND prev_assets_ps IS NOT NULL
  AND assets_ps > 0
  AND prev_assets_ps > 0
  AND (
      assets_ps / prev_assets_ps >= 100
      OR assets_ps / prev_assets_ps <= 0.01
  )

UNION ALL

SELECT
    'liabilities_per_share_100x_quarter_jump',
    COUNT(*)
FROM lagged
WHERE liabilities_ps IS NOT NULL
  AND prev_liabilities_ps IS NOT NULL
  AND liabilities_ps > 0
  AND prev_liabilities_ps > 0
  AND (
      liabilities_ps / prev_liabilities_ps >= 100
      OR liabilities_ps / prev_liabilities_ps <= 0.01
  );
