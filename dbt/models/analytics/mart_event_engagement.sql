{{ config(materialized = 'table') }}

/*
    mart_event_engagement — Engagement por evento
    ─────────────────────────────────────────────────────────────────────────────
    Preguntas que responde:
      ✓ ¿Cuántos asistentes tuvo cada evento?
      ✓ ¿Qué grupos tienen más engagement?
      ✓ ¿Qué categorías generan más asistencia?
    ─────────────────────────────────────────────────────────────────────────────
*/

with fact as (
    select * from {{ ref('fact_attendance') }}
),

groups as (
    select * from {{ ref('dim_group') }}
),

dates as (
    select * from {{ ref('dim_date') }}
)

select
    f.EVENT_ID,
    f.EVENT_NAME,
    f.STATUS as EVENT_STATUS,
    g.GROUP_ID,
    g.GROUP_NAME,
    g.CATEGORY,
    g.CATEGORY_SHORTNAME,
    coalesce(f.VENUE_CITY,  g.CITY) as CITY,
    coalesce(f.VENUE_COUNTRY, g.COUNTRY) as COUNTRY,
    f.EVENT_TIME,
    d.YEAR,
    d.QUARTER,
    d.MONTH_NUMBER,
    d.MONTH_NAME,
    d.WEEK_OF_YEAR,
    d.DAY_NAME,
    d.IS_WEEKEND,
    f.YES_RSVP_COUNT,
    f.MAYBE_RSVP_COUNT,
    f.HEADCOUNT,
    f.WAITLIST_COUNT,
    f.RSVP_LIMIT,
    f.SHOW_RATE,
    f.ATTENDANCE_RATE,
    f.RATING_AVERAGE,
    f.RATING_COUNT,
    f.HAS_FEE,
    f.FEE_AMOUNT,
    f.DURATION_HOURS,
    f.LOADED_DATE
from fact f
left join groups g
    on f.GROUP_ID = g.GROUP_ID
left join dates d
    on f.EVENT_DATE_KEY = d.DATE_KEY
