{{ config(materialized='table') }}

with source_data as (

    select *
    from {{ source('proj2sp500', 'public_proj2_sp500') }}
),

type_casted as (

    select
        -- Date Transformations (STRING -> DATE)
        coalesce(
            safe_cast(date as date),
            date(safe_cast(date as timestamp))
        ) as date,
        -- Foreign Key & Identifiers
        ticker,
        
        coalesce(
            safe_cast(date_added as date),
            date(safe_cast(date_added as timestamp))
        ) as date_added,
        coalesce(
            safe_cast(fiscal_period_end as date),
            date(safe_cast(fiscal_period_end as timestamp))
        ) as fiscal_period_end,
        coalesce(
            safe_cast(fund_filed as date),
            date(safe_cast(fund_filed as timestamp))
        ) as fund_filed,

        -- Daily Trading Metrics (Float / Integer)
        safe_cast(open as float64)           as open,
        safe_cast(high as float64)           as high,
        safe_cast(low as float64)            as low,
        safe_cast(close as float64)          as close,
        safe_cast(adj_close as float64)      as adj_close,
        safe_cast(volume as int64)           as volume,
        safe_cast(chg_pct as float64)        as chg_pct,
        safe_cast(rel_vol as float64)        as rel_vol,

        -- Corporate Actions & Valuation Metrics (STRING -> FLOAT64 / INT64)
        safe_cast(dividends as float64)      as dividends,
        safe_cast(stock_splits as float64)   as stock_splits,
        safe_cast(mkt_cap as int64)          as mkt_cap,
        safe_cast(pe as float64)             as pe,
        safe_cast(p_cfo as float64)          as p_cfo,
        safe_cast(p_fcf as float64)          as p_fcf,
        safe_cast(p_book as float64)         as p_book,
        safe_cast(div_yield_pct as float64)  as div_yield_pct,

        -- Per-Share & Fundamental Metrics (STRING -> FLOAT64 / INT64)
        safe_cast(eps_diluted as float64)         as eps_diluted,
        safe_cast(eps_diluted_ttm as float64)     as eps_diluted_ttm,
        safe_cast(eps_ttm_yoy_pct as float64)     as eps_ttm_yoy_pct,
        safe_cast(revenue_ps_ttm as float64)      as revenue_ps_ttm,
        safe_cast(revenue_ttm_yoy_pct as float64) as revenue_ttm_yoy_pct,
        safe_cast(cfo_ps_ttm as float64)          as cfo_ps_ttm,
        safe_cast(fcf_ps_ttm as float64)          as fcf_ps_ttm,
        safe_cast(dps_ttm as float64)             as dps_ttm,
        safe_cast(book_value_ps as float64)       as book_value_ps,
        safe_cast(cash_ps as float64)             as cash_ps,
        safe_cast(lt_debt_ps as float64)          as lt_debt_ps,
        safe_cast(assets_ps as float64)           as assets_ps,
        safe_cast(liabilities_ps as float64)      as liabilities_ps,
        safe_cast(shares_out as int64)            as shares_out,
        id

        -- Excluded dimension columns: sector, sub_industry, date_added
        -- Excluded Meltano metadata: id, _sdc_*

    from source_data

),

fact_with_indicators as (

    select
        *,
        if(count(close) over w20  = 20,  avg(close) over w20,  null) as sma_20,
        if(count(close) over w50  = 50,  avg(close) over w50,  null) as sma_50,
        if(count(close) over w100 = 100, avg(close) over w100, null) as sma_100,
        if(count(close) over w200 = 200, avg(close) over w200, null) as sma_200,
        safe_divide(adj_close, lag(adj_close) over w_base) - 1        as daily_return

    from type_casted
    window
        w_base as (partition by ticker order by date),
        w20    as (partition by ticker order by date rows between 19 preceding and current row),
        w50    as (partition by ticker order by date rows between 49 preceding and current row),
        w100   as (partition by ticker order by date rows between 99 preceding and current row),
        w200   as (partition by ticker order by date rows between 199 preceding and current row)

)

select *
from fact_with_indicators
order by ticker, date