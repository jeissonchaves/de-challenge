{{ config(unique_key='VENUE_ID') }}
select
    "venue_id" as VENUE_ID,
    trim("venue_name") as VENUE_NAME,
    LOWER(TRIM("city")) AS CITY_NAME,
    trim("state") as STATE,
    trim("address_1") as ADDRESS_1,
    UPPER(TRIM("country")) AS COUNTRY,
    trim("localized_country_name") as LOCALIZED_COUNTRY_NAME,
    "zip" as ZIP_CODE,
    "distance" as DISTANCE,
    "rating" as RATING,
    "rating_count" as RATING_COUNT,
    "normalised_rating" as NORMALIZED_RATING,
    case 
        when "lat" between -90 and 90 then "lat" 
        else NULL 
    end as LAT,
    case 
        when "lon" between -180 and 180 then "lon" 
        else NULL 
    end as LON,
    CURRENT_TIMESTAMP() as LOADED_DATE
from {{ source('raw', 'venues') }}
