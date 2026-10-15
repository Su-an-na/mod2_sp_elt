CREATE OR REPLACE VIEW raw_sp500 AS
SELECT *
FROM read_csv_auto(
    'data/raw/sp500_panel.csv',
    header = true
);
