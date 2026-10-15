from pathlib import Path
import duckdb

DB_FILE = "module2.duckdb"

print("=== S&P 500 DATA QUALITY TESTING ===")
print()

con = duckdb.connect(DB_FILE)

# SETUP
con.execute(Path("sql/00_setup.sql").read_text())

# TEST 01
baseline = con.execute(
    Path("sql/01_baseline.sql").read_text()
).df()
baseline.to_csv("results/01_baseline.csv", index=False)

# TEST 02
completeness = con.execute(
    Path("sql/02_completeness.sql").read_text()
).df()
completeness.to_csv("results/02_completeness.csv", index=False)

# TEST 03
duplicate_summary = con.execute("""
SELECT
    COUNT(*) AS duplicate_groups,
    COALESCE(SUM(record_count - 1), 0) AS extra_duplicate_rows
FROM (
    SELECT ticker, date, COUNT(*) AS record_count
    FROM raw_sp500
    GROUP BY ticker, date
    HAVING COUNT(*) > 1
)
""").df()

duplicate_details = con.execute("""
SELECT ticker, date, COUNT(*) AS record_count
FROM raw_sp500
GROUP BY ticker, date
HAVING COUNT(*) > 1
ORDER BY record_count DESC, ticker, date
""").df()

duplicate_summary.to_csv(
    "results/03_duplicates_summary.csv",
    index=False
)

duplicate_details.to_csv(
    "results/03_duplicates_details.csv",
    index=False
)

# TEST 04
print("=== TEST 04: PRICE / BUSINESS RULES ===")

price_rules = con.execute(
    Path("sql/04_price_business_rules.sql").read_text()
).df()

price_rules["status"] = price_rules["failed_rows"].apply(
    lambda x: "PASS" if x == 0 else "FAIL"
)

print(price_rules.to_string(index=False))

price_rules.to_csv(
    "results/04_price_business_rules.csv",
    index=False
)

con.close()

print()
print("Data quality tests completed successfully.")
