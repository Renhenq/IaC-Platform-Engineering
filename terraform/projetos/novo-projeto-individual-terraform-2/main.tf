terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  token = var.github_token
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "project_name" {
  type = string
}

resource "github_repository" "projeto" {
  name = var.project_name
  description = "Repositorio criado automaticamente pela plataforma"

  visibility = "private"
}