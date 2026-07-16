terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.36.0"
    }
  }
   backend "s3" {
    bucket  = "terraform-states-bucket-filipe"
    key     = "website-royal-solo/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}
