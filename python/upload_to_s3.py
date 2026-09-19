import boto3

BUCKET = "your-bucket-name-here"
REGION = "your-aws-region-here"

s3 = boto3.client("s3", region_name=REGION)

files_to_upload = {
    "../data/taxi_zone_lookup.csv": "raw/zones/taxi_zone_lookup.csv",
    "../data/yellow_tripdata_sample.parquet": "raw/trips/yellow_tripdata_sample.parquet",
}

for local_path, s3_key in files_to_upload.items():
    print(f"Uploading {local_path} -> s3://{BUCKET}/{s3_key}")
    s3.upload_file(local_path, BUCKET, s3_key)

print("Upload complete.")