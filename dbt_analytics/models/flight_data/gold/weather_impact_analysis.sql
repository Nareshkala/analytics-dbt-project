-- Gold metrics: Weather impact on flight delays
-- Grain: one row per weather category/range

with fct as (

    select * from {{ ref('fct_flight_performance') }}

),

categorized as (

    select
        case
            when origin_had_adverse_weather or dest_had_adverse_weather then 'ADVERSE'
            else 'CLEAR'
        end as weather_category,

        case
            when least(
                    coalesce(origin_min_visibility_miles, 999),
                    coalesce(dest_min_visibility_miles, 999)
                 ) < 1 then '< 1 mile'
            when least(
                    coalesce(origin_min_visibility_miles, 999),
                    coalesce(dest_min_visibility_miles, 999)
                 ) < 3 then '1-3 miles'
            else '3+ miles'
        end as visibility_range,

        is_cancelled,
        is_arrival_delayed_15,
        arr_delay_minutes

    from fct

),

aggregated as (

    select
        weather_category,
        visibility_range,

        count(*) as total_flights,
        sum(case when is_cancelled then 1 else 0 end) as total_cancellations,
        sum(case when is_arrival_delayed_15 then 1 else 0 end) as total_delayed_flights,
        avg(arr_delay_minutes) as avg_arrival_delay_minutes,

        div0(sum(case when is_cancelled then 1 else 0 end), count(*)) as cancellation_rate,
        div0(sum(case when is_arrival_delayed_15 then 1 else 0 end), count(*)) as delay_rate

    from categorized
    group by 1, 2

)

select * from aggregated
order by weather_category, visibility_range
