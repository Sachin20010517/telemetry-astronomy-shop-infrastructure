provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_s3_bucket" "my_s3_bucket" {
    bucket = "telemetry-astronomy-state-bucket"
    
    lifecycle {
      prevent_destroy = false
    }
}

resource "aws_dynamodb_table" "my_dynamodb_table" {
  name = "telemetry-astronomy-prod-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}