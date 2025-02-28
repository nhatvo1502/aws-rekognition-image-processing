![alt text](<images/Rekognition.png>)

Build a serverless image processing pipeline using AWS Lambda, S3, and AWS Rekognition with Terraform. This project will automatically resize and analyze newly uploaded image from Input S3 bucket and store the metadata into an Output S3 bucket.

## Setup:
1. Install AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-source-install.html 
2. Create AWS CLI developer account with sufficient permission to create and execute: AWS Lambda Function, AWS S3 Buckets, AWS Rekognition, AWS S3 Event Trigger, IAM Assumps Roles, AWS CloudWatch
https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html
3. Install Terraform CLI: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
4. Deploy
```sh
terraform plan
terraform apply --auto-approve
```

## Using Instruction:
1. Upload a picture into *serverless-image-input-bucket* 
2. Download the metadata from *serverless-image-output-bucket* \
![alt text](<images/s3output.jpg>)
![alt text](<images/bird.jpg>)
![alt text](<images/metadata.png>)