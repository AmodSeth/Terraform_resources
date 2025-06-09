provider "aws" {
  region  = "eu-north-1"
}




resource "aws_s3_bucket" "s3_bucket" {
  bucket = "sec-pipeline-terraform-statefile"
} 



resource "aws_dynamodb_table" "basic-dynamodb-table" {


  hash_key         = "LockID"
  name             = "terraform-state-lock"
  billing_mode     = "PAY_PER_REQUEST"

  

  attribute {
    name = "LockID"
    type = "S"
  }
}
