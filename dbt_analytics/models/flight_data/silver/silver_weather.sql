-- Silver layer: Cleaned weather data with derived categories
-- Grain: one row per airport per hour
-- Incremental (merge): only bronze rows newer than what's already in silver
-- (per _loaded_at, the real file-arrival timestamp) get reprocessed.

{{ config(unique_key='weather_key') }}

with bronze as (

    select *
    from {{ ref('bronze_flight_weather') }}

),

cleaned as (

    select
        _bronze_row_id as weather_key,

        try_to_date(
            lpad(year::string, 4, '0') || '-' ||
            lpad(month::string, 2, '0') || '-' ||
            lpad(day::string, 2, '0'),
            'YYYY-MM-DD'
        ) as observation_date,

        year,
        month,
        day,
        time,

        upper(trim(airport_code)) as airport_code,
        trim(display_airport_name) as display_airport_name,

        dry_bulb_farenheit::float as temperature_f,
        visibility::float as visibility_miles,
        wind_speed::float as wind_speed_mph,
        relative_humidity::float as relative_humidity,
        hourly_precip::float as hourly_precip,
        upper(trim(sky_condition)) as sky_condition,
        upper(trim(weather_type)) as weather_type,

        -- Derived visibility category
        case
            when visibility::float < 1 then 'LOW'
            when visibility::float < 3 then 'MODERATE'
            when visibility::float is null then 'UNKNOWN'
            else 'GOOD'
        end as visibility_category,

        -- Derived wind category
        case
            when wind_speed::float >= 30 then 'HIGH'
            when wind_speed::float >= 15 then 'MODERATE'
            when wind_speed::float is null then 'UNKNOWN'
            else 'LOW'
        end as wind_category,

        -- Adverse weather flag (rain, snow, low visibility, or high wind)
        case
            when weather_type is not null and weather_type != '' then true
            when visibility::float < 1 then true
            when wind_speed::float >= 30 then true
            else false
        end as is_adverse_weather,

        _loaded_at

    from bronze
    where airport_code is not null

),

-- Same protection as silver_flights: guarantee one row per weather_key
-- before the merge, rather than letting a future duplicate collision fail.
deduped as (

    select
        *,
        row_number() over (
            partition by weather_key
            order by _loaded_at desc
        ) as _rn
    from cleaned

)

select * exclude (_rn) from deduped
where _rn = 1

{% if is_incremental() %}
and _loaded_at > (select coalesce(max(_loaded_at), '1900-01-01') from {{ this }})
{% endif %}