-- Gold fact: Flight performance with weather enrichment
-- Grain: one row per flight

with flights as (

    select * from {{ ref('silver_flights') }}

),

dim_date as (

    select * from {{ ref('dim_date') }}

),

dim_airports as (

    select * from {{ ref('dim_airports') }}

),

-- Aggregate weather to one row per airport per day so the join to flights
-- (grain: one row per flight) doesn't fan out
weather_daily as (

    select
        airport_code,
        observation_date,
        avg(temperature_f) as avg_temperature_f,
        min(visibility_miles) as min_visibility_miles,
        max(wind_speed_mph) as max_wind_speed_mph,
        sum(hourly_precip) as total_precip,
        max(case when is_adverse_weather then 1 else 0 end) = 1 as had_adverse_weather
    from {{ ref('silver_weather') }}
    group by 1, 2

),

joined as (

    select
        flights.flight_key,
        dim_date.date_key,
        origin_dim.airport_key as origin_airport_key,
        dest_dim.airport_key as dest_airport_key,

        flights.flight_date,
        flights.carrier,
        flights.origin_airport_code,
        flights.dest_airport_code,
        flights.crs_dep_time,
        flights.crs_arr_time,
        flights.dep_delay_minutes,
        flights.arr_delay_minutes,
        flights.is_departure_delayed_15,
        flights.is_arrival_delayed_15,
        flights.is_cancelled,
        flights.flight_status,

        origin_weather.avg_temperature_f as origin_avg_temperature_f,
        origin_weather.min_visibility_miles as origin_min_visibility_miles,
        origin_weather.max_wind_speed_mph as origin_max_wind_speed_mph,
        coalesce(origin_weather.had_adverse_weather, false) as origin_had_adverse_weather,

        dest_weather.avg_temperature_f as dest_avg_temperature_f,
        dest_weather.min_visibility_miles as dest_min_visibility_miles,
        dest_weather.max_wind_speed_mph as dest_max_wind_speed_mph,
        coalesce(dest_weather.had_adverse_weather, false) as dest_had_adverse_weather

    from flights
    left join dim_date
        on flights.flight_date = dim_date.date
    left join dim_airports as origin_dim
        on flights.origin_airport_code = origin_dim.airport_code
    left join dim_airports as dest_dim
        on flights.dest_airport_code = dest_dim.airport_code
    left join weather_daily as origin_weather
        on flights.origin_airport_code = origin_weather.airport_code
        and flights.flight_date = origin_weather.observation_date
    left join weather_daily as dest_weather
        on flights.dest_airport_code = dest_weather.airport_code
        and flights.flight_date = dest_weather.observation_date

)

select * from joined
