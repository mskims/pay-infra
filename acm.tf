data "aws_acm_certificate" "cert" {
  domain = "pay.ridibooks.com"
}

data "aws_acm_certificate" "cert-us-east-1" {
  domain = "pay.ridibooks.com"
  provider = "aws.us-east-1"
}
