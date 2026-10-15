WITH x AS (
  SELECT
    ticker,
    date,
    open,
    close,
    adj_close,
    chg_pct,
    daily_return,

    LAG(close) OVER (
      PARTITION BY ticker ORDER BY date
    ) AS prev_close,

    LAG(adj_close) OVER (
      PARTITION BY ticker ORDER BY date
    ) AS prev_adj_close

  FROM `dsaimodule2-509312.proj2sp500.fact_dailyprice`
)

SELECT
  COUNTIF(
    prev_close IS NOT NULL
    AND ABS(
      daily_return -
      SAFE_DIVIDE(close - prev_close, prev_close)
    ) <= 0.000001
  ) AS matches_close_return,

  COUNTIF(
    prev_adj_close IS NOT NULL
    AND ABS(
      daily_return -
      SAFE_DIVIDE(adj_close - prev_adj_close, prev_adj_close)
    ) <= 0.000001
  ) AS matches_adjusted_close_return,

  COUNTIF(
    daily_return IS NOT NULL
    AND ABS(daily_return - chg_pct) <= 0.000001
  ) AS matches_chg_pct,

  COUNTIF(
    daily_return IS NOT NULL
    AND ABS(daily_return - SAFE_DIVIDE(chg_pct,100)) <= 0.000001
  ) AS matches_chg_pct_div_100,

  COUNTIF(
    open IS NOT NULL
    AND open != 0
    AND ABS(
      daily_return -
      SAFE_DIVIDE(close - open, open)
    ) <= 0.000001
  ) AS matches_intraday_return

FROM x;
