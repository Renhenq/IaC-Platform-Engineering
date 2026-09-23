# v1
# param(
#     [Parameter(Mandatory=$true)]
#     [string]$NomeProjeto
# )

# function Create-Project {
#     param(
#         [Parameter(Mandatory=$true)]
#         [string]$ProjectName
#     )

#     $env:TF_VAR_project_name = $ProjectName

#     Set-Location ".\terraform"

#     terraform apply -auto-approve
# }

# Create-Project $NomeProjeto

#v2
# param(
#     [Parameter(Mandatory=$true)]
#     [string]$NomeProjeto  # parametro nome

#     [Parameter(Mandatory=$true)]
#     [ValidateSet("java")] # valida e aceita "java"
#     [String]$Linguagem
# )

# $terraformBase = ".\terraform"
# # cria pasta para o projeto
# $projetoDir = "$terraformBase\projetos\$NomeProjeto"

# $templatePath = switch ($Linguagem) {
#     "java" {
#         ".\templates\java-spring"
#     }
# }

# if (Test-Path $projetoDir) {
#     Write-Host "O projeto '$NomeProjeto' ja possui um ambiente Terraform."
#     exit 1
# }

# New-Item -ItemType Directory -Path $projetoDir -Force | Out-Null

# # copia main.tf; cada projeto tem sua configuração
# Copy-Item "$terraformBase\main.tf" $projetoDir
# # variavel de nome para o terraform
# $env:TF_VAR_project_name = $NomeProjeto
# # altera diretorio para pasta do projeto
# Set-Location $projetoDir
# # inicializa terraform
# terraform init
# # aplica para gerar o repositório
# terraform apply -auto-approve


#v3
param(
    [Parameter(Mandatory=$true)]
    [string]$NomeProjeto,  # parametro nome

    [Parameter(Mandatory=$true)]
    [ValidateSet("java")] # valida e aceita "java"
    [String]$Linguagem
)

# caminho da pasta deste script
$RootPath = $PSScriptRoot

# adiciona caminho do template selecionado
$tempaltePath = switch ($Linguagem) {
    "java" {
        Join-Path $RootPath "templates\java-spring"
    }
}

if (-not (Test-Path $templatePath)) {
    Write-Host "Erro: template não encontrado."
    Write-Host "Caminho esperado: $templatePath"
    exit 1
}

Write-Host ""
Write-Host "Projeto: $NomeProjeto"
Write-Host "Linguagem: $Linguagem"
Write-Host "Template selecionado: $templatePath"
Write-Host ""

# variavel de nome para o terraform
$env:TF_VAR_project_name = $NomeProjeto

# adiciona caminho do terraform
$terraformPath = Join-Path $RootPath "terraform"

if (-not (Test-Path $terraformPath)) {
    Write-Host "Erro: pasta do Terraform não encontrada."
    Write-Host "Caminho esperado: $terraformPath"
    exit 1
}

# altera diretorio para pasta do projeto
Set-Location $terraformPath

Write-Host "Criando e configurando o repositorio..."

# aplica para gerar o repositório
terraform apply -auto-approve

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Erro ao executar o Terraform."
    exit 1
}

Write-Host ""
Write-Host "Repositorio criado e configurado com sucesso!"

Write-Host ""
Write-Host "Template selecionado: $Linguagem"
Write-Host "O template sera aplicado ao repositorio na proxima etapa."