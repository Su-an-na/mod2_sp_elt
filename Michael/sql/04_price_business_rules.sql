SELECT 'high_below_low' AS test_name, COUNT(*) AS failed_rows
FROM raw_sp500
WHERE high < low

UNION ALL

SELECT 'high_below_open', COUNT(*)
FROM raw_sp500
WHERE high < open

UNION ALL

SELECT 'high_below_close', COUNT(*)
FROM raw_sp500
WHERE high < close

UNION ALL

SELECT 'low_above_open', COUNT(*)
FROM raw_sp500
WHERE low > open

UNION ALL

SELECT 'low_above_close', COUNT(*)
FROM raw_sp500
WHERE low > close

UNION ALL

SELECT 'non_positive_open', COUNT(*)
FROM raw_sp500
WHERE open <= 0

UNION ALL

SELECT 'non_positive_high', COUNT(*)
FROM raw_sp500
WHERE high <= 0

UNION ALL

SELECT 'non_positive_low', COUNT(*)
FROM raw_sp500
WHERE low <= 0

UNION ALL

SELECT 'non_positive_close', COUNT(*)
FROM raw_sp500
WHERE close <= 0

UNION ALL

SELECT 'non_positive_adj_close', COUNT(*)
FROM raw_sp500
WHERE adj_close <= 0

UNION ALL

SELECT 'negative_volume', COUNT(*)
FROM raw_sp500
WHERE volume < 0;
