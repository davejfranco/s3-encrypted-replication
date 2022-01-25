# AWS S3 bucket replication with encryption

A Terraform module to showcase how to set two encrypted s3 buckets and replicate one into the other like in a DRP scenario

## Usage

```hcl
module "s3_replication" {
    source                   = "github.com/davejfranco/s3-encrypted-replication"
    src_region               = "eu-west-1"
    dest_region              = "eu-central-1"
    source_bucket_name       = "source"
    destination_bucket_name  = "destination"
}
```

## Notes

- This module will deploy two s3 buckets and two kms keys
- The purpose of this module is to showcase s3 bucket replication in the same aws account 
- More info about S3 replication in this [link](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-example-walkthroughs.html)