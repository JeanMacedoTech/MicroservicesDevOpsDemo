provider "aws" {
  region = "sa-east-1"
}

resource "aws_s3_bucket" "artifactory_bucket" {
  bucket = "artifactory-bucket"
  acl    = "private"
}

resource "aws_ecr_repository" "ecr_repo" {
  name = "ecr-repo"
}