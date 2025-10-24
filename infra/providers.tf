provider "aws" {
  region = "us-east-1"
}

locals {
  bucket_name = "resume.sladesanctuary.com" # S3 bucket name I already created 
  site_domain = "resume.sladesanctuary.com" # The domain you'll serve over HTTPS

  tags = {
    owner      = "michael"
    managed-by = "terraform"
    project    = "cloud-resume"
  }
}