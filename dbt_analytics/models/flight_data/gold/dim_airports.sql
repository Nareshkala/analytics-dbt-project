-- Gold dimension: Airport dimension for analytics
-- Grain: one row per airport

with silver_airports as (

    select * from {{ ref('silver_airports') }}

)

select
    airport_key,
    airport_code,
    display_airport_name,
    latitude,
    longitude
from silver_airports
