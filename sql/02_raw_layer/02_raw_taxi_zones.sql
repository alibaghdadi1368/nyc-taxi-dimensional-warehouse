CREATE OR REPLACE TABLE raw_taxi_zones (
  location_id INT,
  borough STRING,
  zone STRING,
  service_zone STRING
);

COPY INTO raw_taxi_zones
FROM @s3_raw_stage/zones/taxi_zone_lookup.csv
FILE_FORMAT = csv_format
ON_ERROR = 'CONTINUE';

SELECT COUNT(*) FROM raw_taxi_zones;