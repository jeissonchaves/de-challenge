{{ config(
    materialized = 'table',
    unique_key    = 'MEMBER_ID'
) }}

/*
    dim_member — Dimensión de Miembro
    ─────────────────────────────────────────────────────────────────────────────
    Un miembro puede pertenecer a múltiples grupos. Aquí se deduplica a nivel miembro tomando
    los atributos más recientes (MAX JOINED_AT) y se agregan métricas de actividad.

    Supuestos:
      - CITY / COUNTRY se toman del primer registro disponible (arbitrario pero
        consistente al no existir una tabla de perfil canónica).
      - TENURE_DAYS se calcula contra CURRENT_DATE() → varía con el tiempo.
      - TENURE_BUCKET clasifica antigüedad en 4 cuartiles operativos.
    ─────────────────────────────────────────────────────────────────────────────
*/

with members_base as (
    select
        MEMBER_ID,
        max(MEMBER_NAME)                                    as MEMBER_NAME,
        max(CITY_NAME)                                      as CITY,
        max(COUNTRY)                                        as COUNTRY,
        max(MEMBER_STATUS)                                  as STATUS,
        min(JOINED_AT)::date                                as JOINED_DATE,
        count(distinct GROUP_ID)                            as TOTAL_GROUPS
    from {{ ref('stg_members') }}
    group by MEMBER_ID
)

select
    MEMBER_ID,
    MEMBER_NAME,
    CITY,
    COUNTRY,
    STATUS,
    JOINED_DATE,
    to_number(to_char(JOINED_DATE, 'YYYYMMDD'))             as JOINED_DATE_KEY,
    TOTAL_GROUPS,
    datediff('day', JOINED_DATE, current_date())            as TENURE_DAYS,
    case
        when datediff('day', JOINED_DATE, current_date()) < 365  then '< 1yr'
        when datediff('day', JOINED_DATE, current_date()) < 730  then '1-2yr'
        when datediff('day', JOINED_DATE, current_date()) < 1825 then '2-5yr'
        else '5yr+'
    end                                                     as TENURE_BUCKET,
    case when TOTAL_GROUPS > 1 then true else false end     as IS_MULTI_GROUP,
    current_timestamp()                                     as LOADED_DATE

from members_base
