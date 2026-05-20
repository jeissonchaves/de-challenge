{{ config(
    materialized = 'table',
    unique_key    = 'DATE_KEY'
) }}

/*
    dim_date — Dimensión de Tiempo
    ─────────────────────────────────────────────────────────────────────────────
    Generada con GENERATOR de Snowflake. 
    Cubre el período 2010-01-01 → 2030-12-31 (~7670 filas).
    DATE_KEY usa formato YYYYMMDD (INT) para joins eficientes en Snowflake.
    ─────────────────────────────────────────────────────────────────────────────
*/

with date_spine as (
    select
        dateadd(day, seq4(), '2010-01-01'::date) as full_date
    from table(generator(rowcount => 7671))
)
select
    to_number(to_char(full_date, 'YYYYMMDD'))  as DATE_KEY,
    full_date                                   as FULL_DATE,
    dayofweekiso(full_date)                     as DAY_OF_WEEK,
    dayname(full_date)                          as DAY_NAME,
    dayofmonth(full_date)                       as DAY_OF_MONTH,
    dayofyear(full_date)                        as DAY_OF_YEAR,
    weekofyear(full_date)                       as WEEK_OF_YEAR,
    month(full_date)                            as MONTH_NUMBER,
    monthname(full_date)                        as MONTH_NAME,
    quarter(full_date)                          as QUARTER,
    year(full_date)                             as YEAR,
    case when dayofweekiso(full_date) in (6, 7)
         then true else false end               as IS_WEEKEND,
    case when dayofweekiso(full_date) not in (6, 7)
         then true else false end               as IS_WEEKDAY,
    current_timestamp()                         as LOADED_DATE
from date_spine
order by full_date
