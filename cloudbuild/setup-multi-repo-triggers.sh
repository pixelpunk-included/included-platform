#!/bin/bash

# =============================================================================
# Setup Multi-Repo Cloud Build Triggers
# Script para configurar triggers entre múltiplos repositórios
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções auxiliares
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar se gcloud está instalado
check_gcloud() {
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI não encontrado. Instale o Google Cloud SDK."
        exit 1
    fi
    
    log_success "gcloud CLI encontrado"
}

# Verificar se o projeto está configurado
check_project() {
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    if [ -z "$PROJECT_ID" ]; then
        log_error "Projeto GCP não configurado. Execute: gcloud config set project SEU_PROJECT_ID"
        exit 1
    fi
    
    log_info "Projeto configurado: $PROJECT_ID"
}

# Habilitar APIs necessárias
enable_apis() {
    log_info "Habilitando APIs necessárias..."
    
    apis=(
        "cloudbuild.googleapis.com"
        "run.googleapis.com"
        "containerregistry.googleapis.com"
        "sourcerepo.googleapis.com"
    )
    
    for api in "${apis[@]}"; do
        if gcloud services enable "$api" --quiet; then
            log_success "API habilitada: $api"
        else
            log_warning "Falha ao habilitar: $api (pode já estar habilitada)"
        fi
    done
}

# Configurar permissões do Cloud Build
setup_permissions() {
    log_info "Configurando permissões do Cloud Build..."
    
    PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
    SERVICE_ACCOUNT="$PROJECT_NUMBER@cloudbuild.gserviceaccount.com"
    
    # Permissões necessárias
    roles=(
        "roles/run.admin"
        "roles/iam.serviceAccountUser"
        "roles/cloudbuild.builds.builder"
        "roles/source.admin"
    )
    
    for role in "${roles[@]}"; do
        if gcloud projects add-iam-policy-binding "$PROJECT_ID" \
            --member="serviceAccount:$SERVICE_ACCOUNT" \
            --role="$role" --quiet; then
            log_success "Permissão adicionada: $role"
        else
            log_warning "Falha ao adicionar permissão: $role (pode já existir)"
        fi
    done
}

# Criar trigger para um repositório
create_trigger() {
    local repo_name="$1"
    local repo_owner="$2"
    local branch="$3"
    local config_file="$4"
    local trigger_name="$5"
    local description="$6"
    
    log_info "Criando trigger: $trigger_name"
    
    if gcloud builds triggers create github \
        --repo-name="$repo_name" \
        --repo-owner="$repo_owner" \
        --branch-pattern="^$branch$" \
        --build-config="$config_file" \
        --name="$trigger_name" \
        --description="$description" \
        --include-logs-with-status \
        --quiet; then
        log_success "Trigger criado: $trigger_name"
    else
        log_warning "Falha ao criar trigger: $trigger_name (pode já existir)"
    fi
}

# Função principal para configurar triggers
setup_triggers() {
    log_info "=== Configurando Triggers Multi-Repo ==="
    
    # Solicitar informações dos repositórios
    echo ""
    log_info "Digite as informações dos seus repositórios:"
    
    read -p "GitHub Owner/Organization: " GITHUB_OWNER
    read -p "Nome do Repositório 1 (este - included-platform): " REPO1_NAME
    read -p "Nome do Repositório 2: " REPO2_NAME
    read -p "Nome do Repositório 3: " REPO3_NAME
    
    echo ""
    log_info "Repositórios configurados:"
    echo "  1. $GITHUB_OWNER/$REPO1_NAME (principal/orquestrador)"
    echo "  2. $GITHUB_OWNER/$REPO2_NAME"
    echo "  3. $GITHUB_OWNER/$REPO3_NAME"
    
    read -p "Confirma a configuração? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Configuração cancelada"
        exit 0
    fi
    
    # Criar triggers para cada repositório
    echo ""
    log_info "Criando triggers..."
    
    # Repositório 1 (included-platform) - Orquestrador Principal
    create_trigger "$REPO1_NAME" "$GITHUB_OWNER" "main" "cloudbuild.yaml" \
        "${REPO1_NAME}-main-orchestrator" \
        "Build principal e orquestração multi-repo - Branch main"
    
    create_trigger "$REPO1_NAME" "$GITHUB_OWNER" "develop" "cloudbuild/cloudbuild-dev.yaml" \
        "${REPO1_NAME}-develop" \
        "Build de desenvolvimento - Branch develop"
    
    # Multi-repo orchestration trigger
    create_trigger "$REPO1_NAME" "$GITHUB_OWNER" "main" "cloudbuild/cloudbuild-multi-repo.yaml" \
        "${REPO1_NAME}-multi-repo" \
        "Orquestração completa entre todos os repositórios"
    
    # Repositório 2
    create_trigger "$REPO2_NAME" "$GITHUB_OWNER" "main" "cloudbuild.yaml" \
        "${REPO2_NAME}-main" \
        "Build principal do repositório 2 - Branch main"
    
    create_trigger "$REPO2_NAME" "$GITHUB_OWNER" "develop" "cloudbuild.yaml" \
        "${REPO2_NAME}-develop" \
        "Build de desenvolvimento do repositório 2 - Branch develop"
    
    # Repositório 3
    create_trigger "$REPO3_NAME" "$GITHUB_OWNER" "main" "cloudbuild.yaml" \
        "${REPO3_NAME}-main" \
        "Build principal do repositório 3 - Branch main"
    
    create_trigger "$REPO3_NAME" "$GITHUB_OWNER" "develop" "cloudbuild.yaml" \
        "${REPO3_NAME}-develop" \
        "Build de desenvolvimento do repositório 3 - Branch develop"
}

# Listar triggers existentes
list_triggers() {
    log_info "=== Triggers Configurados ==="
    gcloud builds triggers list --format="table(name,github.owner,github.name,github.push.branch,filename,disabled)"
}

# Testar orquestração
test_orchestration() {
    log_info "=== Testando Orquestração ==="
    
    read -p "Deseja executar um teste da orquestração multi-repo? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Executando build de teste..."
        
        gcloud builds submit --config cloudbuild/cloudbuild-multi-repo.yaml \
            --substitutions=_GITHUB_OWNER="$GITHUB_OWNER",_REPO2_NAME="$REPO2_NAME",_REPO3_NAME="$REPO3_NAME",_ENVIRONMENT=test
    fi
}

# Menu principal
show_menu() {
    echo ""
    log_info "=== Setup Multi-Repo Cloud Build Triggers ==="
    echo "1. Configuração completa (recomendado)"
    echo "2. Apenas habilitar APIs"
    echo "3. Apenas configurar permissões"
    echo "4. Apenas criar triggers"
    echo "5. Listar triggers existentes"
    echo "6. Testar orquestração"
    echo "0. Sair"
    echo ""
    read -p "Escolha uma opção: " choice
    
    case $choice in
        1)
            check_gcloud
            check_project
            enable_apis
            setup_permissions
            setup_triggers
            list_triggers
            test_orchestration
            ;;
        2)
            check_gcloud
            check_project
            enable_apis
            ;;
        3)
            check_gcloud
            check_project
            setup_permissions
            ;;
        4)
            check_gcloud
            check_project
            setup_triggers
            ;;
        5)
            check_gcloud
            check_project
            list_triggers
            ;;
        6)
            check_gcloud
            check_project
            test_orchestration
            ;;
        0)
            log_info "Saindo..."
            exit 0
            ;;
        *)
            log_error "Opção inválida"
            show_menu
            ;;
    esac
}

# Verificar argumentos da linha de comando
if [ $# -eq 0 ]; then
    show_menu
else
    case $1 in
        "setup"|"install")
            check_gcloud
            check_project
            enable_apis
            setup_permissions
            setup_triggers
            list_triggers
            ;;
        "list")
            check_gcloud
            check_project
            list_triggers
            ;;
        "test")
            check_gcloud
            check_project
            test_orchestration
            ;;
        "help"|"-h"|"--help")
            echo "Uso: $0 [comando]"
            echo ""
            echo "Comandos:"
            echo "  setup    - Configuração completa"
            echo "  list     - Listar triggers"
            echo "  test     - Testar orquestração"
            echo "  help     - Mostrar esta ajuda"
            echo ""
            echo "Sem argumentos: Mostrar menu interativo"
            ;;
        *)
            log_error "Comando desconhecido: $1"
            echo "Use '$0 help' para ver comandos disponíveis"
            exit 1
            ;;
    esac
fi 