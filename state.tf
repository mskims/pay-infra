resource "aws_s3_bucket" "terraform_state" {
  count = "${terraform.workspace == "default" ? 1 : 0}"
  bucket = "ridi-pay-terraform-state"
  versioning {
    enabled = true
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  count = "${terraform.workspace == "default" ? 1 : 0}"
  name           = "terraform-state-lock"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
