resource "aws_s3_bucket" "img_api_bucket" {
  #checkov:skip=CKV_AWS_6
  #checkov:skip=CKV_AWS_21
  #checkov:skip=CKV_AWS_61
  #checkov:skip=CKV_AWS_62
  #checkov:skip=CKV_AWS_118
  #checkov:skip=CKV_AWS_144
  #checkov:skip=CKV_AWS_145
  bucket = var.images_bucket
  tags = {
    Description        = "S3 Backend bucket which stores images received form API call for account ${data.aws_caller_identity.current.account_id}."
    ManagedByTerraform = "true"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "img_api_bucket_sse_conf" {
  bucket = aws_s3_bucket.img_api_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = null
      sse_algorithm     = "AES256"
    }
  }
}
