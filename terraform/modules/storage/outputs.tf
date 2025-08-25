output data_bucket_name {
  description = "Name of the data S3 bucket"
  value       = aws_s3_bucket.data_bucket.bucket
}