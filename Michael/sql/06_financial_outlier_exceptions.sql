SELECT
    'market_cap_above_10_trillion' AS issue,
    date,
    ticker,
    company,
    close,
    mkt_cap,
    shares_out,
    pe,
    eps_diluted,
    eps_diluted_ttm,
    div_yield_pct
FROM raw_sp500
WHERE mkt_cap > 10000000000000

UNION ALL

SELECT
    'market_cap_below_1_billion',
    date, ticker, company, close, mkt_cap, shares_out,
    pe, eps_diluted, eps_diluted_ttm, div_yield_pct
FROM raw_sp500
WHERE mkt_cap IS NOT NULL
  AND mkt_cap > 0
  AND mkt_cap < 1000000000

UNION ALL

SELECT
    'shares_above_50_billion',
    date, ticker, company, close, mkt_cap, shares_out,
    pe, eps_diluted, eps_diluted_ttm, div_yield_pct
FROM raw_sp500
WHERE shares_out > 50000000000

UNION ALL

SELECT
    'shares_below_1_million',
    date, ticker, company, close, mkt_cap, shares_out,
    pe, eps_diluted, eps_diluted_ttm, div_yield_pct
FROM raw_sp500
WHERE shares_out IS NOT NULL
  AND shares_out > 0
  AND shares_out < 1000000

UNION ALL

SELECT
    'extreme_eps',
    date, ticker, company, close, mkt_cap, shares_out,
    pe, eps_diluted, eps_diluted_ttm, div_yield_pct
FROM raw_sp500
WHERE ABS(eps_diluted) > 10000
   OR ABS(eps_diluted_ttm) > 10000

UNION ALL

SELECT
    'extreme_valuation_ratio',
    date, ticker, company, close, mkt_cap, shares_out,
    pe, eps_diluted, eps_diluted_ttm, div_yield_pct
FROM raw_sp500
WHERE ABS(pe) > 1000
   OR ABS(p_cfo) > 1000
   OR ABS(p_fcf) > 1000
   OR ABS(p_book) > 1000

UNION ALL

SELECT
    'extreme_dividend_yield',
    date, ticker, company, close, mkt_cap, shares_out,
    pe, eps_diluted, eps_diluted_ttm, div_yield_pct
FROM raw_sp500
WHERE div_yield_pct < 0
   OR div_yield_pct > 50

ORDER BY issue, ticker, date;
