
resource "aws_kms_key" "source" {
  description             = "KMS key in the source region"
  deletion_window_in_days = var.kms_delete_window
}

resource "aws_s3_bucket" "source" {
  bucket = var.source_bucket_name
  acl    = var.s3_acl


  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.source.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  lifecycle {
    ignore_changes = [
      replication_configuration
    ]
  }

}

resource "aws_kms_key" "destination" {
  description             = "KMS key in the source region"
  deletion_window_in_days = var.kms_delete_window
}

resource "aws_s3_bucket" "destination" {
  bucket = var.destination_bucket_name
  acl    = var.s3_acl

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.destination.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }
}


data "aws_iam_policy_document" "s3_assume_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "s3_replication_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:ListBucket",
      "s3:GetReplicationConfiguration",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectRetention",
      "s3:GetObjectLegalHold"
    ]
    resources = [
      aws_s3_bucket.source.arn,
      "${aws_s3_bucket.source.arn}/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:GetObjectVersionTagging"
    ]
    condition {
      test     = "StringLikeIfExists"
      variable = "s3:x-amz-server-side-encryption"
      values = ["aws:kms",
        "AES256"
      ]
    }
    condition {
      test     = "StringLikeIfExists"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [aws_kms_key.destination.arn]
    }
    resources = [
      "${aws_s3_bucket.destination.arn}/*"
    ]
  }

  statement {
    effect  = "Allow"
    actions = ["kms:Decrypt"]

    condition {
      test     = "StringLike"
      values   = ["s3.${var.src_region}.amazonaws.com"]
      variable = "kms:ViaService"
    }
    condition {
      test     = "StringLike"
      values   = ["${aws_s3_bucket.source.arn}/*"]
      variable = "kms:EncryptionContext:aws:s3:arn"
    }
    resources = [aws_kms_key.source.arn]
  }

  statement {
    effect  = "Allow"
    actions = ["kms:Encrypt"]

    condition {
      test     = "StringLike"
      values   = ["s3.${var.dest_region}.amazonaws.com"]
      variable = "kms:ViaService"
    }

    condition {
      test     = "StringLike"
      values   = ["${aws_s3_bucket.destination.arn}/*"]
      variable = "kms:EncryptionContext:aws:s3:arn"
    }
    resources = [aws_kms_key.destination.arn]
  }
}

resource "aws_iam_role" "s3_replication" {
  name               = "s3-replication-role"
  assume_role_policy = data.aws_iam_policy_document.s3_assume_policy.json
}

resource "aws_iam_policy" "replication" {
  name   = "replication-policy"
  policy = data.aws_iam_policy_document.s3_replication_policy.json
}

resource "aws_iam_policy_attachment" "replication-attach" {
  name       = "s3-replication-attachment"
  roles      = [aws_iam_role.s3_replication.name]
  policy_arn = aws_iam_policy.replication.arn
}


# S3 Bucket replication config
resource "aws_s3_bucket_replication_configuration" "replication_config" {
  role   = aws_iam_role.s3_replication.arn
  bucket = aws_s3_bucket.source.id

  rule {
    id     = "replicate"
    status = "Enabled"

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = aws_s3_bucket.destination.arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = aws_kms_key.destination.arn
      }
    }
  }
}