variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "project_name" {
  type    = string
  default = "pricewatch"
}

variable "bucket_prefix" {
  type    = string
  default = "pricewatch-kinefall4"
}

variable "github_repo_url" {
  type        = string
  description = "Example: https://github.com/kinefall4/pricewatch.git"
}

variable "schedule_expression" {
  type    = string
  default = "rate(1 hour)" # for testing; change to rate(1 day) later
}