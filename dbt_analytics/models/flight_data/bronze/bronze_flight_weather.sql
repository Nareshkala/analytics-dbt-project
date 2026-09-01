-- Bronze layer: Raw hourly weather observations
-- Grain: one row per source record (no dedup applied yet)
-- Incremental (append): _loaded_at is the S3 file's real last-modified time
-- (captured once at COPY INTO time), so reruns with no new files add nothing.

with source as (

    select *
    from {{ source('raw_flight_data', 'flight_weather') }}

),

renamed as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'year', 'month', 'day', 'time', 'airport_code'
        ]) }} as _bronze_row_id,

        year,
        month,
        day,
        time,
        time_zone,
        sky_condition,
        visibility,
        weather_type,
        dry_bulb_farenheit,
        dry_bulb_celsius,
        wet_bulb_farenheit,
        wet_bulb_celsius,
        dew_point_farenheit,
        dew_point_celsius,
        relative_humidity,
        wind_speed,
        wind_direction,
        value_for_wind_character,
        station_pressure,
        pressure_tendency,
        pressure_change,
        sea_level_pressure,
        record_type,
        hourly_precip,
        altimeter,
        airport_code,
        display_airport_name,
        latitude,
        longitude,

        _copy_loaded_at as _loaded_at,
        _source_file_name

    from source

)

select * from renamed

{% if is_incremental() %}
where _loaded_at > (select coalesce(max(_loaded_at), '1900-01-01') from {{ this }})
{% endif %}