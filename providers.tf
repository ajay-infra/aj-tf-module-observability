terraform {
  required_version = "= 1.7.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.100.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "= 2.12.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "= 2.27.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "= 3.6.3"
    }
  }

  # Backend configured dynamically by pipelines via -backend-config
  # backend "s3" {
  #   bucket         = "<tf-state-bucket>"
  #   key            = "central/<env>/observability/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "tf-locks-central"
  # }
}

provider "aws" {
  region = var.aws_region

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_region_validation      = true

  default_tags {
    tags = local.full_tags
  }
}

# Helm and Kubernetes providers require a live EKS cluster at apply time.
# terraform validate works without real credentials — providers are loaded but not connected.
provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_ca_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.aws_region]
    }
  }
}

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.aws_region]
  }
}

provider "random" {}
