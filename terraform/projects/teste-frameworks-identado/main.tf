# github provider do terraform realiza as chamadas de api github
# integrations/github como provider para utilizar recursos github
terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

# token de autenticação para api github
provider "github" {
  token = var.github_token
}
# declaracação de variável token
variable "github_token" {
  type      = string
  sensitive = true
}
# declaracação de nome do projeto
variable "project_name" {
  type = string
}

# github_repository = tipo de recurso a ser criado
resource "github_repository" "projeto" {
  name = var.project_name
  description = "Repositorio criado automaticamente pela plataforma"

  visibility = "public"
}

# cria uma ruleset para o Repositorio
resource "github_repository_ruleset" "proteger_main" {
  name        = "Protect main"
  repository  = github_repository.projeto.name # aplica ao repositorio criado
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    pull_request {
      required_approving_review_count = 0
    }

    non_fast_forward = true
  }
}