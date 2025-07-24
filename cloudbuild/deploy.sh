#!/bin/bash

# Script para facilitar o deploy da plataforma IncludED
# Uso: ./deploy.sh [ambiente] [componente]

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  IncludED Platform Deploy${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Verificar se o gcloud está configurado
check_gcloud() {
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI não está instalado. Instale o Google Cloud SDK."
        exit 1
    fi

    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "Você não está autenticado no gcloud. Execute 'gcloud auth login'"
        exit 1
    fi

    print_message "gcloud CLI configurado corretamente"
}

# Carregar variáveis de ambiente
load_env() {
    if [ -f "cloudbuild/cloudbuild.env" ]; then
        print_message "Carregando variáveis de ambiente de cloudbuild/cloudbuild.env"
        export $(cat cloudbuild/cloudbuild.env | grep -v '^#' | xargs)
    else
        print_warning "Arquivo cloudbuild/cloudbuild.env não encontrado. Usando variáveis padrão."
    fi
}

# Função para deploy completo
deploy_full() {
    local env=$1
    print_message "Iniciando deploy completo para ambiente: $env"
    
    if [ "$env" = "prod" ]; then
        gcloud builds submit --config cloudbuild/cloudbuild.yaml
    elif [ "$env" = "dev" ]; then
        gcloud builds submit --config cloudbuild/cloudbuild-dev.yaml
    else
        print_error "Ambiente inválido. Use 'prod' ou 'dev'"
        exit 1
    fi
}

# Função para deploy do backend
deploy_backend() {
    local env=$1
    print_message "Iniciando deploy do backend para ambiente: $env"
    
    if [ "$env" = "prod" ]; then
        gcloud builds submit --config cloudbuild/cloudbuild-backend.yaml
    elif [ "$env" = "dev" ]; then
        print_warning "Deploy específico do backend para desenvolvimento não configurado"
        print_message "Usando deploy completo de desenvolvimento"
        gcloud builds submit --config cloudbuild/cloudbuild-dev.yaml
    else
        print_error "Ambiente inválido. Use 'prod' ou 'dev'"
        exit 1
    fi
}

# Função para deploy do frontend
deploy_frontend() {
    local env=$1
    print_message "Iniciando deploy do frontend para ambiente: $env"
    
    if [ "$env" = "prod" ]; then
        gcloud builds submit --config cloudbuild/cloudbuild-frontend.yaml
    elif [ "$env" = "dev" ]; then
        print_warning "Deploy específico do frontend para desenvolvimento não configurado"
        print_message "Usando deploy completo de desenvolvimento"
        gcloud builds submit --config cloudbuild/cloudbuild-dev.yaml
    else
        print_error "Ambiente inválido. Use 'prod' ou 'dev'"
        exit 1
    fi
}

# Função para mostrar status
show_status() {
    print_message "Verificando status dos serviços..."
    
    echo -e "\n${BLUE}Serviços Cloud Run:${NC}"
    gcloud run services list --region=${REGION:-us-central1} --format="table(metadata.name,status.url,status.conditions[0].status)"
    
    echo -e "\n${BLUE}Últimos builds:${NC}"
    gcloud builds list --limit=5 --format="table(id,status,createTime,source.repoSource.branchName)"
}

# Função para mostrar ajuda
show_help() {
    echo "Uso: $0 [comando] [ambiente] [componente]"
    echo ""
    echo "Comandos:"
    echo "  deploy    - Fazer deploy (padrão)"
    echo "  status    - Mostrar status dos serviços"
    echo "  help      - Mostrar esta ajuda"
    echo ""
    echo "Ambientes:"
    echo "  prod      - Produção"
    echo "  dev       - Desenvolvimento"
    echo ""
    echo "Componentes:"
    echo "  full      - Backend + Frontend (padrão)"
    echo "  backend   - Apenas backend"
    echo "  frontend  - Apenas frontend"
    echo ""
    echo "Exemplos:"
    echo "  $0 deploy prod full      # Deploy completo para produção"
    echo "  $0 deploy dev backend    # Deploy do backend para desenvolvimento"
    echo "  $0 status                # Mostrar status dos serviços"
}

# Função principal
main() {
    print_header
    
    # Verificar dependências
    check_gcloud
    
    # Carregar variáveis de ambiente
    load_env
    
    # Parsear argumentos
    local command=${1:-deploy}
    local environment=${2:-prod}
    local component=${3:-full}
    
    case $command in
        "deploy")
            case $component in
                "full")
                    deploy_full $environment
                    ;;
                "backend")
                    deploy_backend $environment
                    ;;
                "frontend")
                    deploy_frontend $environment
                    ;;
                *)
                    print_error "Componente inválido: $component"
                    show_help
                    exit 1
                    ;;
            esac
            ;;
        "status")
            show_status
            ;;
        "help")
            show_help
            ;;
        *)
            print_error "Comando inválido: $command"
            show_help
            exit 1
            ;;
    esac
    
    print_message "Deploy concluído com sucesso!"
}

# Executar função principal
main "$@" 