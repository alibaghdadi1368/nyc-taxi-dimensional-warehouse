-- Key discovery: date columns were stored as raw microsecond values since the epoch-not actual TIMESTAMPs, so they needed to be converted. We also renamed the columns to a simple format that does not require quoting.
CREATE OR REPLACE TABLE raw_trips_clean AS
SELECT
  "VendorID" AS vendor_id,
  TO_TIMESTAMP_NTZ("tpep_pickup_datetime" / 1000000) AS tpep_pickup_datetime,
  TO_TIMESTAMP_NTZ("tpep_dropoff_datetime" / 1000000) AS tpep_dropoff_datetime,
  "passenger_count" AS passenger_count,
  "trip_distance" AS trip_distance,
  "PULocationID" AS pu_location_id,
  "DOLocationID" AS do_location_id,
  "payment_type" AS payment_type,
  "fare_amount" AS fare_amount,
  "tip_amount" AS tip_amount,
  "total_amount" AS total_amount
FROM raw_trips;

SELECT * FROM raw_trips_clean LIMIT 5;