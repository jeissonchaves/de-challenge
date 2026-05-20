{{ config(unique_key='GROUP_ID') }}
select
    "group_id" as GROUP_ID,
    trim("group_name") as GROUP_NAME,
    try_to_timestamp("created"::string) as CREATED_AT,
    "city_id" as CITY_ID,
    trim("city") as CITY_NAME,
    trim("state") as STATE,
    trim("country") as COUNTRY,
    "category_id" as CATEGORY_ID,
    trim("category.name") as CATEGORY_NAME,
    trim("category.shortname") as CATEGORY_SHORTNAME,
    trim("description") as DESCRIPTION,
    trim("join_mode") as JOIN_MODE,
    "lat" as LATITUDE,
    "lon" as LONGITUDE,
    trim("link") as LINK,
    "rating" as RATING,
    trim("timezone") as TIMEZONE,
    trim("urlname") as URLNAME,
    "utc_offset" as UTC_OFFSET,
    trim("visibility") as VISIBILITY,
    trim("who") as WHO,
    "members" as MEMBERS_COUNT,
    trim("group_photo.base_url") as GROUP_PHOTO_BASE_URL,
    trim("group_photo.highres_link") as GROUP_PHOTO_HIGHRES_LINK,
    trim("group_photo.photo_id") as GROUP_PHOTO_ID,
    trim("group_photo.photo_link") as GROUP_PHOTO_LINK,
    trim("group_photo.thumb_link") as GROUP_PHOTO_THUMB_LINK,
    trim("group_photo.type") as GROUP_PHOTO_TYPE,
    "organizer.member_id" as ORGANIZER_MEMBER_ID,
    trim("organizer.name") as ORGANIZER_NAME,
    trim("organizer.photo.base_url") as ORGANIZER_PHOTO_BASE_URL,
    trim("organizer.photo.highres_link") as ORGANIZER_PHOTO_HIGHRES_LINK,
    trim("organizer.photo.photo_id") as ORGANIZER_PHOTO_ID,
    trim("organizer.photo.photo_link") as ORGANIZER_PHOTO_LINK,
    trim("organizer.photo.thumb_link") as ORGANIZER_PHOTO_THUMB_LINK,
    trim("organizer.photo.type") as ORGANIZER_PHOTO_TYPE,
    -- Flag de calidad
        CASE
            WHEN "organizer.name" = 'not_found' THEN TRUE
            ELSE FALSE
        END AS is_orphan_group
    FROM source,
    CURRENT_TIMESTAMP() as LOADED_DATE
from {{ source('raw', 'groups') }}
