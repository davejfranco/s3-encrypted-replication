output "source_kms_arn" {
  value = aws_kms_key.source.arn
}

output "destination_kms_arn" {
  value = aws_kms_key.destination.arn
}

output "source_bucket_arn" {
  value = aws_s3_bucket.source.arn
}

output "destination_bucket_arn" {
  value = aws_s3_bucket.destination.arn
}