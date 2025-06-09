provider "aws" {
  region  = "eu-north-1"
}

@REM bucket = "sec-pipeline-terraform-file" 
@REM     key    = "state.tf"
@REM     region = "eu-north-1"
@REM     dynamodb_table= "terraform-state-lock"


resource "aws_s3_bucket" "s3_bucket" {
  bucket = "sec-pipeline-terraform-file"
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
