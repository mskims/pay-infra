locals {
  environment = "${terraform.workspace == "default" ? "prod" : "${terraform.workspace}"}"
}

resource "aws_s3_bucket" "ridi_pay_frontend_bucket" {
  bucket = "ridi-pay-frontend-${local.environment}"
}
