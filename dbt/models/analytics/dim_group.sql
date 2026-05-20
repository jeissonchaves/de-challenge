{{ config(
    materialized = 'table',
    unique_key    = 'GROUP_ID'
) }}

/*
    dim_group — Dimensión de Grupo
    ─────────────────────────────────────────────────────────────────────────────
    Atributos del grupo enriquecidos con categoría y flags de calidad.
    ─────────────────────────────────────────────────────────────────────────────
*/

select
    GROUP_ID,
    GROUP_NAME,
    CATEGORY_NAME as CATEGORY,
    CATEGORY_SHORTNAME, 
    CITY_NAME as CITY,
    COUNTRY,
    CREATED_AT::date as CREATED_DATE,
    case
        when CREATED_AT is not null
        then to_number(to_char(CREATED_AT::date, 'YYYYMMDD'))
        else null
    end as CREATED_DATE_KEY,
    VISIBILITY,
    JOIN_MODE,
    MEMBERS_COUNT,
    RATING,
    IS_ORPHAN_GROUP as IS_ORPHAN,
    current_timestamp() as LOADED_DATE
from {{ ref('stg_groups') }}
