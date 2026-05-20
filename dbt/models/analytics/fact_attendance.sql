{{ config(
    materialized = 'table',
    unique_key    = 'EVENT_ID'
) }}

/*
    fact_attendance — Hechos de Asistencia
    ─────────────────────────────────────────────────────────────────────────────
    Granularidad: una fila por evento.
    ─────────────────────────────────────────────────────────────────────────────
*/

select
    EVENT_ID,
    GROUP_ID,
    case
        when EVENT_TIME is not null
        then to_number(to_char(EVENT_TIME::date, 'YYYYMMDD'))
        else null
    end as EVENT_DATE_KEY,
    EVENT_NAME,
    EVENT_TIME,
    STATUS,
    coalesce(YES_RSVP_COUNT, 0) as YES_RSVP_COUNT,
    coalesce(MAYBE_RSVP_COUNT, 0) as MAYBE_RSVP_COUNT,
    coalesce(HEADCOUNT, 0) as HEADCOUNT,
    coalesce(WAITLIST_COUNT, 0) as WAITLIST_COUNT,
    RSVP_LIMIT,
    case when coalesce(FEE_AMOUNT, 0) > 0 then true else false end  as HAS_FEE,
    FEE_AMOUNT,
    case
        when RSVP_LIMIT > 0 and HEADCOUNT is not null
        then round(HEADCOUNT / RSVP_LIMIT, 4)
        else null
    end as ATTENDANCE_RATE,

    case
        when YES_RSVP_COUNT > 0 and HEADCOUNT is not null
        then round(HEADCOUNT / YES_RSVP_COUNT, 4)
        else null
    end as SHOW_RATE,
    RATING_AVERAGE,
    RATING_COUNT,
    VENUE_CITY,
    VENUE_COUNTRY,
    case
        when DURATION > 0
        then round(DURATION / 3600000.0, 2)
        else null
    end as DURATION_HOURS,
    current_timestamp() as LOADED_DATE
from {{ ref('stg_events') }}
