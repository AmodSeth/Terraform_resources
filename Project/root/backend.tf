terraform {
  backend "s3" {
    bucket = "sec-pipeline-terraform-file" 
    key    = "state.tf"
    region = "eu-north-1"
    dynamodb_table= "terraform-state-lock"
  }
}