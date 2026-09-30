# parametros do comando
param(
    [Parameter(Mandatory = $true)]
    [string]$NomeProjeto,

    [Parameter(Mandatory = $true)]
    [ValidateSet("java")]
    [string]$Linguagem,

    [Parameter(Mandatory = $false)]
    [Switch]$Docker,

    [Parameter(Mandatory = $false)]
    [Switch]$PostgreSQL,

    [Parameter(Mandatory = $false)]
    [Switch]$Hibernate,
    
    [Parameter(Mandatory = $false)]
    [Switch]$ApacheStruts,
    
    [Parameter(Mandatory = $false)]
    [Switch]$JasperReports,

    [Parameter(Mandatory = $false)]
    [Switch]$Lombok,

    [Parameter(Mandatory = $false)]
    [Switch]$MapStruct
)




function Adicionar-Dependency {
    param (
        [String]$tipo,
        [String]$nome
    )

    $DependencyPath = Join-Path $RootPath "$tipo\$nome\dependency.xml"

    if (-not (Test-Path $DependencyPath)) {
        Write-Host "Dependência '$nome' não encontrada."
        return
    }

    $PomContent = Get-Content $PomPath -Raw

    $Dependency = Get-Content $DependencyPath -Raw

    # Adiciona a indentação em cada linha da dependência
    $Dependency = ($Dependency -split "`r?`n" |
         ForEach-Object {
            if ($_.Trim() -ne "") {
                "        $($_.Trim())"
            }
        }) -join "`r`n"

    $PomContent = $PomContent.Replace(
        "</dependencies>",
        "$Dependency`r`n </dependencies>"
    )
    
    Set-Content -Path $PomPath -Value $PomContent

    Write-Host "Dependência '$nome' adicionada."
}

# configuracoes

# caminho da pasta deste script
$RootPath = $PSScriptRoot
# dono do repositorio
$Owner = "Renhenq"
# caminho da pasta do terraform
$TerraformBasePath = Join-Path $RootPath "terraform"
# diretorio terraform para o novo projeto
$TerraformProjectPath = Join-Path $TerraformBasePath "projects\$NomeProjeto"
# adiciona caminho do template selecionado
$TemplatePath = switch ($Linguagem) {
    "java" {
        Join-Path $RootPath "templates\java-spring"
    }
}
# diretorio do projeto
$ProjetosPath = Join-Path $RootPath "projetos"

$RepositorioPath = Join-Path $ProjetosPath $NomeProjeto

$RepositorioUrl = "https://github.com/$Owner/$NomeProjeto.git"



Write-Host "Projeto:    $NomeProjeto"
Write-Host "Linguagem:  $Linguagem"
Write-Host "Template:   $TemplatePath"
Write-Host ""

if (-not (Test-Path $TemplatePath)) {
    Write-Host "Template nao encontrado."
    Write-Host $TemplatePath
    exit 1
}

if (-not (Test-Path $TerraformBasePath)) {
    Write-Host "Pasta do Terraform nao encontrada."
    exit 1
}

if (-not $env:GITHUB_TOKEN) {
    Write-Host "GITHUB_TOKEN nao esta configurado."
    Write-Host 'Configure o token antes de executar o script:'
    Write-Host '$env:GITHUB_TOKEN="SEU_TOKEN"'
    exit 1
}

if (Test-Path $RepositorioPath) {
    Write-Host "A pasta local do projeto ja existe:"
    Write-Host $RepositorioPath
    exit 1
}



Write-Host "1. Preparando Terraform..."
# cria pasta do projeto
if (-not (Test-Path $TerraformProjectPath)) {
    New-Item `
        -ItemType Directory `
        -Path $TerraformProjectPath `
        -Force | Out-Null
}

# Copia os arquivos .tf da configuracao base
Get-ChildItem `
    -Path $TerraformBasePath `
    -Filter "*.tf" `
    -File |
    Copy-Item `
        -Destination $TerraformProjectPath `
        -Force


# variavel de nome do projeto para o terraform
$env:TF_VAR_project_name = $NomeProjeto

# variavel para o provider 
$env:TF_VAR_github_token = $env:GITHUB_TOKEN


Write-Host "2. Inicializando Terraform..."
# terraform init
terraform -chdir="$TerraformProjectPath" init -input=false

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Terraform init falhou."
    exit 1
}


Write-Host "3. Criando repositorio no GitHub..."
# terraform aply
terraform -chdir="$TerraformProjectPath" apply -auto-approve -input=false

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Terraform apply falhou."
    exit 1
}


Write-Host "4. Criando repositorio local..."
# cria pasta projetos
if (-not (Test-Path $ProjetosPath)) {
    New-Item `
        -ItemType Directory `
        -Path $ProjetosPath `
        -Force | Out-Null
}


Write-Host "5. Clonando repositorio..."

git clone $RepositorioUrl $RepositorioPath

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Nao foi possivel clonar o repositorio."
    exit 1
}


Write-Host "6. Aplicando template: $Linguagem..."

# Copia todos os arquivos do template
# lista todos arquivos do diretorio
Get-ChildItem `
    -Path $TemplatePath `
    -Force |
    Where-Object { $_.Name -ne ".git" } | # ignora .git
    # copia para a pasta do projeto
    Copy-Item `
        -Destination $RepositorioPath `
        -Recurse `
        -Force


$PomPath = Join-Path $RepositorioPath "pom.xml"

# Frameworks
 
if ($Linguagem -eq "Java") {

    if ($Hibernate) {
        Adicionar-Dependency -tipo "frameworks" -nome "hibernate"
    }

    if ($ApacheStruts) {
        Adicionar-Dependency -tipo "frameworks" -nome "apacheStruts"
    }

    if ($JasperReports) {
        Adicionar-Dependency -tipo "libraries" -nome "jasperReports"
    }

    if ($Lombok) {
        Adicionar-Dependency -tipo "libraries" -nome "lombok"
    }
    
    if ($MapStruct) {
        Adicionar-Dependency -tipo "libraries" -nome "mapstruct"
    }
    
}


# Componentes    
if ($Docker) {
    $DockerPath = Join-Path $RootPath "components\docker"

    if (-not (Test-Path $DockerPath)) {
        Write-Host "Componente Docker nao encontrado."
        exit 1
    }

    Get-ChildItem `
        -Path $DockerPath `
        -Force |
        Copy-Item `
            -Destination $RepositorioPath `
            -Recurse `
            -Force

    Write-Host "Componente Docker criado."
}

if ($PostgreSQL) {
    $PostgresqlPath = Join-Path $RootPath "components\postgresql"

    if (-not (Test-Path $PostgresqlPath)) {
        Write-Host "Componente PostgreSQL não encontrado."
        exit 1
    }

    Get-ChildItem `
        -Path $PostgresqlPath `
        -Force |
        Copy-Item `
            -Destination $RepositorioPath `
            -Recurse `
            -Force

    Write-Host "Componente PostgreSQL criado."
}


Write-Host "7. Criando commit..."
# pasta para realizar o commit
Push-Location $RepositorioPath

git add .

if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-Host "git add falhou."
    exit 1
}

git commit -m "inicializa projeto com template $Linguagem"

if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-Host "git commit falhou."
    exit 1
}


Write-Host "8. Enviando projeto para o GitHub..."

git push -u origin main

if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-Host ""
    Write-Host "git push falhou."
    exit 1
}
# volta caminho do diretorio
Pop-Location


Write-Host ""
Write-Host "Projeto criado"
Write-Host "Projeto:   $NomeProjeto"
Write-Host "Linguagem: $Linguagem"
Write-Host "Template:  $TemplatePath"
Write-Host "GitHub:    $RepositorioUrl"
Write-Host ""






function Adicionar-Dependency {
    param (
        [String]$tipo,
        [String]$nome
    )

    $DependencyPath = Join-Path $RootPath "$tipo\$nome\dependency.xml"

    if (-not (Test-Path $DependencyPath)) {
        Write-Host "Dependência '$nome' não encontrada."
        return
    }

    $PomContent = Get-Content $PomPath -Raw

    $Dependency = Get-Content $DependencyPath -Raw

    $PomContent = $PomContent.Replace(
        "</dependencies>",
        "$Dependency`r`n </dependencies>"
    )
    
    Set-Content -Path $PomPath -Value $PomContent

    Write-Host "Dependência '$nome' adicionada."
}