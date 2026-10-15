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
        ticker,
        company,
        fiscal_period_end,
        shares_out,
        eps_diluted,
        eps_diluted_ttm,
        revenue_ps_ttm,
        assets_ps,
        liabilities_ps,

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
),

exceptions AS (

    SELECT
        'shares_out_scale_jump' AS issue,
        ticker,
        company,
        fiscal_period_end,
        prev_shares_out AS previous_value,
        shares_out AS current_value,
        shares_out / prev_shares_out AS ratio
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
        'eps_diluted_scale_jump',
        ticker,
        company,
        fiscal_period_end,
        prev_eps_diluted,
        eps_diluted,
        ABS(eps_diluted / prev_eps_diluted)
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
        'eps_ttm_scale_jump',
        ticker,
        company,
        fiscal_period_end,
        prev_eps_diluted_ttm,
        eps_diluted_ttm,
        ABS(eps_diluted_ttm / prev_eps_diluted_ttm)
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
        'revenue_ps_scale_jump',
        ticker,
        company,
        fiscal_period_end,
        prev_revenue_ps_ttm,
        revenue_ps_ttm,
        revenue_ps_ttm / prev_revenue_ps_ttm
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
        'assets_ps_scale_jump',
        ticker,
        company,
        fiscal_period_end,
        prev_assets_ps,
        assets_ps,
        assets_ps / prev_assets_ps
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
        'liabilities_ps_scale_jump',
        ticker,
        company,
        fiscal_period_end,
        prev_liabilities_ps,
        liabilities_ps,
        liabilities_ps / prev_liabilities_ps
    FROM lagged
    WHERE liabilities_ps IS NOT NULL
      AND prev_liabilities_ps IS NOT NULL
      AND liabilities_ps > 0
      AND prev_liabilities_ps > 0
      AND (
          liabilities_ps / prev_liabilities_ps >= 100
          OR liabilities_ps / prev_liabilities_ps <= 0.01
      )
)

SELECT *
FROM exceptions
ORDER BY issue, ticker, fiscal_period_end;
