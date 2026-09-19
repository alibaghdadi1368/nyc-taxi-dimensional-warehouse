import requests
import os

os.makedirs("../data", exist_ok=True)

files = {
    "taxi_zone_lookup.csv": "https://d37ci6vzurychx.cloudfront.net/misc/taxi+_zone_lookup.csv",
    "yellow_tripdata_2023-01.parquet": "https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2023-01.parquet",
}

for filename, url in files.items():
    print(f"Downloading {filename}...")
    r = requests.get(url, stream=True)
    r.raise_for_status()
    path = f"../data/{filename}"
    with open(path, "wb") as f:
        for chunk in r.iter_content(chunk_size=8192):
            f.write(chunk)
    size_mb = os.path.getsize(path) / (1024 * 1024)
    print(f"  Saved {filename} ({size_mb:.1f} MB)")

print("Done.")