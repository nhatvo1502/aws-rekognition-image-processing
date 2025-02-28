import boto3
import os
from PIL import Image
import json

s3 = boto3.client("s3")
rekognition = boto3.client("rekognition")

def lambda_handler(event, context):
    bucket = event["Records"][0]["s3"]["bucket"]["name"]
    key = event["Records"][0]["s3"]["object"]["key"]

    # Download image
    download_path = f"/tmp/{key}"
    s3.download_file(bucket, key, download_path)

    # Resize image
    resize_path = f"/tmp/resized-{key}"
    with Image.open(download_path) as img:
        img = img.resize((300, 300))
        img.save(resize_path)

    # Upload resized image
    output_bucket = os.environ["OUTPUT_BUCKET"]
    s3.upload_file(resize_path, output_bucket, f"resized-{key}")

    # Analyze image using Rekognition
    with open(download_path, "rb") as image:
        response = rekognition.detect_labels(Image={"Bytes": image.read()})

    labels = [label["Name"] for label in response["Labels"]]

    # Store metadata in S3 as JSON
    metadata = {"image": key, "labels": labels}
    s3.put_object(
        Bucket=output_bucket,
        Key=f"metadata/{key}.json",
        Body=json.dumps(metadata)
    )

    return {"statusCode": 200, "body": json.dumps(f"Processed {key}")}
