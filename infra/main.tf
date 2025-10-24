resource "aws_s3_bucket" "site" {
  #S3 bucket names are global and must be lowercase; dots are okay
  bucket = local.bucket_name
  tags   = local.tags
}

# Make AWS owns all objects (no ACLs to manage)
resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.site.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

#Block any public access at the bucket level (we'll serve vic CloudFront later)
resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}
# Upload our landing page as a private S3 object
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"                                #the object name in S3
  source       = "${path.module}/../app/frontend/index.html" # path of your machine
  content_type = "text/html"                                 #correct MIME type
}
# Request an SSL/TLS certificate in the us-east-1 (required for CloudFront)
resource "aws_acm_certificate" "site_cert" {
  domain_name       = local.site_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Output tells us which DNS record to add in Bluehost
output "acm_dns_validation_records" {
  value = aws_acm_certificate.site_cert.domain_validation_options
}

#Let CloudFront access S3 privately via SigV4 (no public S3)
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "resume-oac"
  description                       = "OAC for ${local.site_domain}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Global CDN for the site, using my ACM cert (must be in us-east-1)
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  comment             = "Cloud Resume for ${local.site_domain}"
  default_root_object = "index.html"

  # ONE origin block (not 'origins = [...]')
  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id

    # Required with S3 + OAC; leave OAI empty
    s3_origin_config {
      origin_access_identity = ""
    }
  }

  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    # Use AWS managed "CachingOptimized" policy for static sites 
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

  }
  price_class = "PriceClass_100" # cheapest regions; fine for a resume site

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = local.tags
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

# Permit **this** CloudFront distriution to GET objects from the bucket 
resource "aws_s3_bucket_policy" "site_policy" {
  bucket = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "AllowCloudFrontRead",
      Effect    = "Allow",
      Principal = { Service = "cloudfront.amazonaws.com" },
      Action    = "s3:GetObject",
      Resource  = "${aws_s3_bucket.site.arn}/*",
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
        }
      }
    }]
  })
}