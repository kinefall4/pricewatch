terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  bucket_name = "${var.bucket_prefix}-${random_id.suffix.hex}"
}

# ---------------- S3 website ----------------
resource "aws_s3_bucket" "site" {
  bucket        = local.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id
  index_document { suffix = "index.html" }
  error_document { key = "404.html" }
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "public_read" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
    principals {
  type        = "*"
  identifiers = ["*"]
}
  }
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.public_read.json
}

# ---------------- CodeBuild role ----------------
data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    effect = "Allow"
    principals {
  type        = "Service"
  identifiers = ["codebuild.amazonaws.com"]
}
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild_role" {
  name               = "${var.project_name}-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

data "aws_iam_policy_document" "codebuild_policy" {
  statement {
    effect  = "Allow"
    actions = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"]
    resources = ["*"]
  }
  statement {
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [aws_s3_bucket.site.arn]
  }
  statement {
    effect  = "Allow"
    actions = ["s3:GetObject","s3:PutObject","s3:DeleteObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
  }
}

resource "aws_iam_role_policy" "codebuild_inline" {
  name   = "${var.project_name}-codebuild-inline"
  role   = aws_iam_role.codebuild_role.id
  policy = data.aws_iam_policy_document.codebuild_policy.json
}

resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/codebuild/${var.project_name}"
  retention_in_days = 14
}

# ---------------- CodeBuild project ----------------
resource "aws_codebuild_project" "build" {
  name         = "${var.project_name}-build"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts { type = "NO_ARTIFACTS" }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "S3_BUCKET"
      value = local.bucket_name
    }
  }

  source {
    type      = "GITHUB"
    location  = var.github_repo_url
    buildspec = "buildspec.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild.name
      stream_name = "build"
    }
  }
}

# ---------------- Scheduled build trigger (automation) ----------------
data "aws_iam_policy_document" "events_assume" {
  statement {
    effect = "Allow"
    principals {
  type        = "Service"
  identifiers = ["events.amazonaws.com"]
}
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "events_role" {
  name               = "${var.project_name}-events-role"
  assume_role_policy = data.aws_iam_policy_document.events_assume.json
}

data "aws_iam_policy_document" "events_policy" {
  statement {
    effect  = "Allow"
    actions = ["codebuild:StartBuild"]
    resources = [aws_codebuild_project.build.arn]
  }
}

resource "aws_iam_role_policy" "events_inline" {
  name   = "${var.project_name}-events-inline"
  role   = aws_iam_role.events_role.id
  policy = data.aws_iam_policy_document.events_policy.json
}

resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${var.project_name}-schedule"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "schedule_target" {
  rule     = aws_cloudwatch_event_rule.schedule.name
  arn      = aws_codebuild_project.build.arn
  role_arn = aws_iam_role.events_role.arn
}