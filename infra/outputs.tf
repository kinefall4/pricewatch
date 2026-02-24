output "bucket_name" {
  value = aws_s3_bucket.site.bucket
}

output "website_url" {
  value = "http://${aws_s3_bucket_website_configuration.site.website_endpoint}"
}

output "codebuild_project_name" {
  value = aws_codebuild_project.build.name
}