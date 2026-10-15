# S&P 500 Sharpe ratio kit

Calculates Sharpe ratios for S&P 500 stocks over the last 1, 2, 3 and 5 years from `sp500_panel.csv`,
in Python (a Jupyter notebook) and in BigQuery. Both give the same numbers.

## What is in the kit

| File | What it is for |
|---|---|
| `sp500_sharpe_explorer.ipynb` | Asks for a ticker, calculates its Sharpe ratios, compares them with its sector and the index, and writes a report with charts. Also calculates every ticker. |
| `bigquery_all_tickers_sharpe.sql` | BigQuery: Sharpe ratios for every ticker over 1, 2, 3 and 5 years. |
| `bigquery_one_ticker_sma_sharpe.sql` | BigQuery: adds 20/50/100/200-day moving averages and daily returns for one ticker, and its Sharpe ratio between two dates. |
| `sp500_panel_schema.json` | Column types for loading `sp500_panel.csv` into BigQuery, so dates load as dates. |
| `README.md` | These instructions. |

You also need `sp500_panel.csv`. It is not in the kit.

## 1. The CSV this kit expects

`sp500_panel.csv` as exported by `sp500_panel.ipynb`: one row per ticker per trading day, comma-separated, with a header row.
The notebook needs only these five columns; the BigQuery moving averages also use `close`.

| Column | Format | Example |
|---|---|---|
| `date` | `YYYY-MM-DD` | `2026-10-06` |
| `ticker` | text; share classes use a dot | `NVDA`, `BRK.B` |
| `company` | text | `Nvidia` |
| `sector` | text (GICS sector) | `Information Technology` |
| `close` | number: closing price, adjusted for splits | `239.24` |
| `adj_close` | number: closing price, adjusted for splits and dividends | `239.24` |

The full file has 38 columns in this order: `date, ticker, company, sector, sub_industry, date_added, open, high, low,
close, adj_close, volume, chg_pct, rel_vol, dividends, stock_splits, mkt_cap, pe, p_cfo, p_fcf, p_book, div_yield_pct,
fiscal_period_end, fund_filed, eps_diluted, eps_diluted_ttm, eps_ttm_yoy_pct, revenue_ps_ttm, revenue_ttm_yoy_pct,
cfo_ps_ttm, fcf_ps_ttm, dps_ttm, book_value_ps, cash_ps, lt_debt_ps, assets_ps, liabilities_ps, shares_out`.
Extra columns are ignored. If your file is in this format, everything runs without changes.

## 2. One-time setup (Python)

In Terminal:

```bash
conda create -n ndx python=3.11 -y
conda activate ndx
pip install pandas numpy matplotlib jupyter
python -m ipykernel install --user --name ndx --display-name "Python (ndx)"
```

If you already created the `ndx` environment for `sp500_panel.ipynb`, just run `pip install matplotlib` inside it.

## 3. Run the notebook

1. Put `sp500_sharpe_explorer.ipynb` and `sp500_panel.csv` in the same folder.
2. Open the notebook in VS Code (or Jupyter) and select the kernel **Python (ndx)**.
3. Click **Run All**.
4. When asked, type a ticker (for example `AAPL`, `BRK.B`) and press Enter.
   A wrong ticker shows an error in red with suggestions; you get three tries. An empty entry cancels.
5. The results appear in the notebook and are saved in a new `sharpe_output` folder next to it:

| Output | Contents |
|---|---|
| `sharpe_report_<TICKER>.md` | Summary table and three charts, embedded, so the file can be shared on its own |
| `<TICKER>_sharpe_by_window.png` | The ticker's Sharpe ratio for each window, against its sector median and the S&P 500 median |
| `<TICKER>_rolling_sharpe.png` | Rolling one-year Sharpe ratio over time |
| `<TICKER>_sharpe_distribution.png` | Where the ticker sits among all S&P 500 stocks, one panel per window |
| `sharpe_all_tickers.csv` | Every ticker x every window: returns, volatility, Sharpe, rank in index and sector |
| `sharpe_all_tickers_bigquery.sql` | The BigQuery version of that table, using your current settings |

To analyse another ticker, run step 2 of the notebook again and the cells after it. You do not need to reload the CSV.

### Settings (first code cell)

| Setting | Default | Meaning |
|---|---|---|
| `CSV_PATH` | `"sp500_panel.csv"` | Where the CSV is; use a full path if it is in another folder |
| `TICKER` | `None` | `None` asks for a ticker; set e.g. `"NVDA"` to skip the question |
| `HORIZONS_YEARS` | `[1, 2, 3, 5]` | Windows, in years, ending on the last date in the CSV |
| `RISK_FREE_RATE` | `0.04` | Annual risk-free rate, e.g. the average 3-month T-bill yield |
| `OUT_DIR` | `"sharpe_output"` | Output folder |
| `EMBED_IMAGES_IN_MARKDOWN` | `True` | `False` makes the report link to the PNG files instead |
| `BQ_TABLE` | `None` | Set to `"project.dataset.table"` to also run the all-ticker query in BigQuery from the notebook (needs `pip install google-cloud-bigquery db-dtypes` and `gcloud auth application-default login`) |

## 4. BigQuery (optional)

### Load the CSV

The BigQuery console accepts uploads up to 100 MB and the CSV is about 170 MB, so compress it first:

```bash
gzip -k sp500_panel.csv          # creates sp500_panel.csv.gz (about 30 MB) and keeps the original
```

**Console:** your dataset → **Create table** → Source: **Upload**, file `sp500_panel.csv.gz`, format **CSV** →
table name `sp500_panel` → Schema: turn on **Edit as text** and paste the contents of `sp500_panel_schema.json` →
Advanced options: **Header rows to skip = 1** → **Create table**.

**Or from Terminal** (replace `your_project` and `your_dataset`):

```bash
bq load --source_format=CSV --skip_leading_rows=1 \
  your_project:your_dataset.sp500_panel sp500_panel.csv.gz sp500_panel_schema.json
```

Using the schema file makes `date` a DATE column. Both queries also work if it was loaded as text.

### Run the queries

In each `.sql` file, replace `your_project.your_dataset.sp500_panel` with your table, then paste the whole file into a
BigQuery query tab and click **Run**.

- `bigquery_all_tickers_sharpe.sql`: returns one row per ticker per window. Stocks listed for less than a full window
  are left out of that window. To change the risk-free rate or windows, edit the numbers in the file, or change the
  notebook settings and use the copy it writes to `sharpe_output`.
- `bigquery_one_ticker_sma_sharpe.sql`: set the ticker, start date (X), end date (Y) and risk-free rate at the top.
  It adds five columns to your table and fills them for that ticker (delete the line `WHERE ticker = target_ticker`
  in step 2 to fill all tickers), then returns the Sharpe ratio from the close on X to the close on Y.

## 5. How the Sharpe ratio is calculated

- Daily return = today's `adj_close` / the previous trading day's `adj_close` - 1. This includes dividends.
- Daily risk-free rate = (1 + annual rate)^(1/252) - 1.
- Daily Sharpe = (mean daily return - daily risk-free rate) / standard deviation of daily returns (sample).
- Annualised Sharpe = daily Sharpe x sqrt(252). This is `sharpe_ratio` everywhere in the kit.
- An N-year window runs from the close N years before the last date to the last date.
- Sector medians and ranks compare today's S&P 500 members only, so companies that left the index are not included.

## 6. Troubleshooting

| Message | Fix |
|---|---|
| `Cannot find '.../sp500_panel.csv'` | Put the CSV next to the notebook, or set `CSV_PATH` to its full path. |
| `has no column(s) ...` | The file is not in the format in section 1. Check the column names in the first line. |
| `rows have a date that is not in YYYY-MM-DD format` | The file was re-saved by Excel, which changes date formats. Use the original export. |
| `rows repeat a ticker and date` | Two files were appended together. Use a single export. |
| `'XYZ' is not an S&P 500 ticker` | Use one of the suggested symbols. Share classes use a dot (`BRK.B`). |
| `has less than N year(s) of prices` | The stock joined the market recently; that window is left blank. |
| BigQuery: `No matching signature for operator > for argument types: STRING, DATE` | You are using an older copy of a query; use the files in this kit, or reload the table with `sp500_panel_schema.json`. |
| BigQuery: `Not found: Table ...` | The table name in the query does not match yours. |
| `ModuleNotFoundError: No module named 'matplotlib'` | Wrong kernel or missing package: select **Python (ndx)**, or run `pip install matplotlib` in that environment. |
