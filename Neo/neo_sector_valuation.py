"""
Analysis 4 - Did prices follow profits? (sector valuation)
Author: Neo (Team 2)

Question: did each sector's share price rise because its profits grew,
or because investors simply paid more?

Data : team BigQuery tables fact_dailyprice + dim_ticker (read only)
Window: 7 Oct 2025 -> 7 Oct 2026 (8 Oct excluded: downloaded mid-session)
Output: images/neo_price_vs_earnings.png + two printed tables

Run from the repo root (where .env is):  python neo/neo_sector_valuation.py
.env needs GCP_PROJECT_ID and GCP_DATASET_ID
"""
import os
from dotenv import load_dotenv
import pandas as pd
from sqlalchemy import create_engine
import matplotlib.pyplot as plt

load_dotenv()
project_id = os.getenv("GCP_PROJECT_ID")
dataset_id = os.getenv("GCP_DATASET_ID")
engine = create_engine(f"bigquery://{project_id}/{dataset_id}")

START = "2025-10-07"
END = "2026-10-07"   # last complete trading day

# ---------- Query 1: how expensive is each sector? (medians on END date)
q1 = f"""
SELECT
  d.sector,
  COUNT(*) AS n_stocks,
  ROUND(APPROX_QUANTILES(IF(f.pe > 0, f.pe, NULL), 100)[OFFSET(50)], 1)         AS median_pe,
  ROUND(APPROX_QUANTILES(IF(f.p_book > 0, f.p_book, NULL), 100)[OFFSET(50)], 1) AS median_pb,
  ROUND(APPROX_QUANTILES(f.div_yield_pct, 100)[OFFSET(50)], 2)                  AS median_div_yield_pct
FROM `{project_id}.{dataset_id}.fact_dailyprice` f
JOIN `{project_id}.{dataset_id}.dim_ticker` d USING (ticker)
WHERE f.date = DATE '{END}'
GROUP BY d.sector
ORDER BY median_pe DESC
"""

# ---------- Query 2: price growth vs earnings growth over the year
q2 = f"""
WITH per_stock AS (
  SELECT
    ticker,
    MAX(IF(date = DATE '{START}', adj_close, NULL))       AS price_start,
    MAX(IF(date = DATE '{END}',   adj_close, NULL))       AS price_end,
    MAX(IF(date = DATE '{END}',   eps_ttm_yoy_pct, NULL)) AS eps_growth_pct
  FROM `{project_id}.{dataset_id}.fact_dailyprice`
  WHERE date IN (DATE '{START}', DATE '{END}')
    AND ticker != 'CTVA'                       -- spin-off distorts its price
  GROUP BY ticker
)
SELECT
  d.sector,
  COUNT(*) AS n_stocks,
  ROUND(APPROX_QUANTILES((p.price_end / p.price_start - 1) * 100, 100)[OFFSET(50)], 1) AS median_price_growth_pct,
  ROUND(APPROX_QUANTILES(p.eps_growth_pct, 100)[OFFSET(50)], 1)                       AS median_eps_growth_pct
FROM per_stock p
JOIN `{project_id}.{dataset_id}.dim_ticker` d USING (ticker)
WHERE p.price_start IS NOT NULL AND p.price_end IS NOT NULL
GROUP BY d.sector
ORDER BY median_price_growth_pct DESC
"""

df1 = pd.read_sql(q1, con=engine)
df2 = pd.read_sql(q2, con=engine)
print("Valuation by sector (", END, ")\n", df1.to_string(index=False), "\n")
print("Price vs earnings growth (", START, "->", END, ")\n", df2.to_string(index=False))

# ---------- Chart: one dot per sector; dashed line = price growth equals earnings growth
plot = df2[df2["sector"] != "Real Estate"]   # EPS distorted by asset sales/depreciation

fig, ax = plt.subplots(figsize=(11, 8))
ax.fill_between([-15, 40], [-15, 40], [-15, -15], color="#FFF7ED", zorder=0)
ax.plot([-15, 40], [-15, 40], "--", color="#64748B", label="Price growth = earnings growth")
for _, r in plot.iterrows():
    colour = "#EA580C" if r["sector"] == "Financials" else (
             "#16A34A" if r["sector"] == "Information Technology" else "#2563EB")
    ax.scatter(r["median_eps_growth_pct"], r["median_price_growth_pct"], s=120, color=colour, zorder=3)
    ax.annotate(r["sector"], (r["median_eps_growth_pct"], r["median_price_growth_pct"]),
                textcoords="offset points", xytext=(6, 5), fontsize=10)
ax.axhline(0, color="#334155", lw=0.7)
ax.axvline(0, color="#334155", lw=0.7)
ax.set_xlim(-15, 40)
ax.set_ylim(-15, 40)
ax.set_xlabel("Median earnings growth, % (EPS, trailing 12 months)")
ax.set_ylabel("Median price growth, %")
ax.set_title(f"Price vs Earnings Growth by Sector ({START} to {END})", fontweight="bold")
ax.legend(loc="lower right")
ax.grid(color="#E2E8F0")
plt.tight_layout()

os.makedirs("images", exist_ok=True)
fig.savefig("images/neo_price_vs_earnings.png", dpi=300, bbox_inches="tight")
print("\nSaved images/neo_price_vs_earnings.png")
