CREATE OR REPLACE TABLE fct_trips AS
SELECT
  t.vendor_id AS vendor_key,
  YEAR(t.tpep_pickup_datetime) * 10000 
    + MONTH(t.tpep_pickup_datetime) * 100 
    + DAY(t.tpep_pickup_datetime) AS pickup_date_key,
  t.payment_type AS payment_type_key,
  pu.zone_sk AS pickup_zone_sk,
  do.zone_sk AS dropoff_zone_sk,
  t.passenger_count,
  t.trip_distance,
  t.fare_amount,
  t.tip_amount,
  t.total_amount,
  DATEDIFF('minute', t.tpep_pickup_datetime, t.tpep_dropoff_datetime) AS trip_duration_minutes
FROM raw_trips_clean t
LEFT JOIN dim_zone pu ON t.pu_location_id = pu.location_id AND pu.is_current = TRUE
LEFT JOIN dim_zone do ON t.do_location_id = do.location_id AND do.is_current = TRUE
WHERE t.fare_amount > 0 AND t.trip_distance > 0;

SELECT COUNT(*) FROM fct_trips;