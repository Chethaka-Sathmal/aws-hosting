output "state_bucket" {
  description = "Pass to the main stack: terraform init -backend-config=\"bucket=<this>\""
  value       = aws_s3_bucket.state.bucket
}

output "region" {
  description = "Region of the state bucket."
  value       = var.region
}
