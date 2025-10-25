terraform {
  backend "s3" {
    bucket         = "cloud-resume-tfstate-446050219344"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cloud-resume-tflock"
    encrypt        = true
  }
}