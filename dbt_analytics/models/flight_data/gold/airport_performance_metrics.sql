-- Gold metrics: Airport-level performance aggregations
-- Grain: one row per airport

with fct as (

    select * from {{ ref('fct_flight_performance') }}

),

dim_airports as (

    select * from {{ ref('dim_airports') }}

),

-- Combine origin + destination operations per airport
airport_ops as (

    select origin_airport_key as airport_key, * exclude (origin_airport_key)
    from fct

    union all

    select dest_airport_key as airport_key, * exclude (dest_airport_key)
    from fct

),

aggregated as (

    select
        airport_key,

        count(*) as total_operations,
        sum(case when is_cancelled then 1 else 0 end) as total_cancellations,
        sum(case when is_arrival_delayed_15 then 1 else 0 end) as total_delayed_arrivals,
        sum(case when is_departure_delayed_15 then 1 else 0 end) as total_delayed_departures,

        avg(arr_delay_minutes) as avg_arrival_delay_minutes,
        avg(dep_delay_minutes) as avg_departure_delay_minutes,

        div0(sum(case when is_cancelled then 1 else 0 end), count(*)) as cancellation_rate,
        div0(sum(case when is_arrival_delayed_15 then 1 else 0 end), count(*)) as delay_rate,
        1 - div0(sum(case when is_arrival_delayed_15 then 1 else 0 end), count(*)) as on_time_rate

    from airport_ops
    group by 1

)

select
    dim_airports.airport_key,
    dim_airports.airport_code,
    dim_airports.display_airport_name,
    aggregated.total_operations,
    aggregated.total_cancellations,
    aggregated.total_delayed_arrivals,
    aggregated.total_delayed_departures,
    aggregated.avg_arrival_delay_minutes,
    aggregated.avg_departure_delay_minutes,
    aggregated.cancellation_rate,
    aggregated.delay_rate,
    aggregated.on_time_rate,
    rank() over (order by aggregated.on_time_rate desc) as on_time_rank
from aggregated
inner join dim_airports
    on aggregated.airport_key = dim_airports.airport_key
