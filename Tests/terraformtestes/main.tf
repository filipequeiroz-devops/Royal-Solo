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

data "aws_route53_zone" "meu_dominio" {
  name = "filipe-deabreu.com" #domínio já existente na AWS
}

output "zone_id" {
  value = data.aws_route53_zone.meu_dominio.zone_id
}
