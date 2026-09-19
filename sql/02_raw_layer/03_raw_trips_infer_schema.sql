-- INFER_SCHEMA was used to automatically detect the actual Parquet file schema instead of manually guessing column data types.
CREATE OR REPLACE TABLE raw_trips
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
    FROM TABLE(
      INFER_SCHEMA(
        LOCATION => '@s3_raw_stage/trips/',
        FILE_FORMAT => 'parquet_format'
      )
    )
  );

COPY INTO raw_trips
FROM @s3_raw_stage/trips/yellow_tripdata_sample.parquet
FILE_FORMAT = parquet_format
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
ON_ERROR = 'CONTINUE';

SELECT COUNT(*) FROM raw_trips;