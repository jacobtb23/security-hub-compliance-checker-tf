terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.8.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-storage-<account-id>" //account ID
    dynamodb_table = "terraform-state-lock-<account-id>"    //account ID
    key            = "compliance-checker-lambda.tfstate"
    region         = "us-west-2"
    profile        = "<sso_profile>"
  }
}

provider "aws" {
  region              = var.region
  allowed_account_ids = [var.account_id]
  profile             = var.account_profile
}