{{ config(materialized='table') }}

select 
    DISTINCT
    ticker,
    company,
    sector,
    sub_industry
from {{ source('proj2sp500', 'public_proj2_sp500') }}