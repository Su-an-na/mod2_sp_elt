SELECT 'market_cap_above_10_trillion' AS test_name, COUNT(*) AS flagged_rows
FROM raw_sp500
WHERE mkt_cap > 10000000000000

UNION ALL

SELECT 'market_cap_below_1_billion', COUNT(*)
FROM raw_sp500
WHERE mkt_cap IS NOT NULL
  AND mkt_cap > 0
  AND mkt_cap < 1000000000

UNION ALL

SELECT 'shares_above_50_billion', COUNT(*)
FROM raw_sp500
WHERE shares_out > 50000000000

UNION ALL

SELECT 'shares_below_1_million', COUNT(*)
FROM raw_sp500
WHERE shares_out IS NOT NULL
  AND shares_out > 0
  AND shares_out < 1000000

UNION ALL

SELECT 'eps_diluted_abs_above_10000', COUNT(*)
FROM raw_sp500
WHERE ABS(eps_diluted) > 10000

UNION ALL

SELECT 'eps_ttm_abs_above_10000', COUNT(*)
FROM raw_sp500
WHERE ABS(eps_diluted_ttm) > 10000

UNION ALL

SELECT 'pe_abs_above_1000', COUNT(*)
FROM raw_sp500
WHERE ABS(pe) > 1000

UNION ALL

SELECT 'p_cfo_abs_above_1000', COUNT(*)
FROM raw_sp500
WHERE ABS(p_cfo) > 1000

UNION ALL

SELECT 'p_fcf_abs_above_1000', COUNT(*)
FROM raw_sp500
WHERE ABS(p_fcf) > 1000

UNION ALL

SELECT 'p_book_abs_above_1000', COUNT(*)
FROM raw_sp500
WHERE ABS(p_book) > 1000

UNION ALL

SELECT 'dividend_yield_negative', COUNT(*)
FROM raw_sp500
WHERE div_yield_pct < 0

UNION ALL

SELECT 'dividend_yield_above_50pct', COUNT(*)
FROM raw_sp500
WHERE div_yield_pct > 50

UNION ALL

SELECT 'eps_growth_abs_above_100000pct', COUNT(*)
FROM raw_sp500
WHERE ABS(eps_ttm_yoy_pct) > 100000

UNION ALL

SELECT 'revenue_growth_abs_above_10000pct', COUNT(*)
FROM raw_sp500
WHERE ABS(revenue_ttm_yoy_pct) > 10000;
