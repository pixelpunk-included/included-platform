#!/bin/bash

# Script para desenvolvimento com Docker
# Uso: ./docker-dev.sh [comando]

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Função para imprimir com cores
print_status() {
    local color=$1
    local icon=$2
    local message=$3
    echo -e "${color}${icon} ${message}${NC}"
}

# Função para verificar se o Docker está rodando
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_status $RED "❌" "Docker não está rodando. Por favor, inicie o Docker primeiro."
        exit 1
    fi
}

# Função para mostrar banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    INCLUDED PLATFORM                        ║"
    echo "║                   Docker Development                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Função para mostrar ajuda
show_help() {
    show_banner
    echo -e "${WHITE}Uso: $0 {comando}${NC}"
    echo ""
    echo -e "${YELLOW}Comandos disponíveis:${NC}"
    echo ""
    echo -e "  ${GREEN}up${NC}       - 🚀 Inicia o ambiente completo"
    echo -e "  ${GREEN}down${NC}     - 🛑 Para o ambiente"
    echo -e "  ${GREEN}restart${NC}  - 🔄 Reinicia o ambiente"
    echo -e "  ${GREEN}logs${NC}     - 📋 Mostra logs em tempo real"
    echo -e "  ${GREEN}backend${NC}  - 🐍 Executa apenas o backend"
    echo -e "  ${GREEN}frontend${NC} - ⚛️  Executa apenas o frontend"
    echo -e "  ${GREEN}storybook${NC} - 📚 Executa apenas o Storybook"
    echo -e "  ${GREEN}clean${NC}    - 🧹 Limpa containers e volumes"
    echo -e "  ${GREEN}build${NC}    - 🔨 Faz build de todos os serviços"
    echo -e "  ${GREEN}status${NC}   - 📊 Mostra status dos containers"
    echo -e "  ${GREEN}shell${NC}    - 🐚 Abre shell no container especificado"
    echo ""
    echo -e "${YELLOW}Exemplos:${NC}"
    echo -e "  $0 up"
    echo -e "  $0 logs"
    echo -e "  $0 shell backend"
    echo ""
}

# Função para mostrar status dos containers
show_status() {
    print_status $CYAN "📊" "Status dos containers:"
    echo ""
    docker-compose ps
    echo ""
    print_status $CYAN "💾" "Uso de disco:"
    docker system df
}

# Função para abrir shell no container
open_shell() {
    local service=$2
    if [ -z "$service" ]; then
        print_status $RED "❌" "Especifique um serviço (backend/frontend/storybook)"
        echo -e "Uso: $0 shell {backend|frontend|storybook}"
        exit 1
    fi
    
    print_status $PURPLE "🐚" "Abrindo shell no container $service..."
    docker-compose exec $service /bin/bash
}

# Configuração de erro
set -e

# Verificar se o Docker está rodando
check_docker

# Verificar se docker-compose.yml existe
if [ ! -f "docker-compose.yml" ]; then
    print_status $RED "❌" "Arquivo docker-compose.yml não encontrado!"
    exit 1
fi

case "$1" in
    "up")
        show_banner
        print_status $GREEN "🚀" "Iniciando ambiente de desenvolvimento..."
        docker-compose up --build
        ;;
    "down")
        show_banner
        print_status $YELLOW "🛑" "Parando ambiente de desenvolvimento..."
        docker-compose down
        print_status $GREEN "✅" "Ambiente parado com sucesso!"
        ;;
    "restart")
        show_banner
        print_status $BLUE "🔄" "Reiniciando ambiente de desenvolvimento..."
        docker-compose down
        print_status $CYAN "⏳" "Aguardando containers pararem..."
        sleep 2
        docker-compose up --build
        ;;
    "logs")
        show_banner
        print_status $CYAN "📋" "Mostrando logs em tempo real..."
        print_status $YELLOW "⚠️" "Pressione Ctrl+C para sair"
        echo ""
        docker-compose logs -f
        ;;
    "backend")
        show_banner
        print_status $GREEN "🐍" "Executando apenas o backend..."
        docker-compose up --build backend
        ;;
    "frontend")
        show_banner
        print_status $GREEN "⚛️" "Executando apenas o frontend..."
        docker-compose up --build frontend
        ;;
    "storybook")
        show_banner
        print_status $GREEN "📚" "Executando apenas o Storybook..."
        docker-compose up --build storybook
        ;;
    "clean")
        show_banner
        print_status $YELLOW "🧹" "Limpando containers e volumes..."
        print_status $YELLOW "⚠️" "Isso irá remover todos os dados!"
        read -p "Tem certeza? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker-compose down -v
            docker system prune -f
            print_status $GREEN "✅" "Limpeza concluída!"
        else
            print_status $BLUE "ℹ️" "Operação cancelada."
        fi
        ;;
    "build")
        show_banner
        print_status $BLUE "🔨" "Fazendo build de todos os serviços..."
        docker-compose build
        print_status $GREEN "✅" "Build concluído!"
        ;;
    "status")
        show_banner
        show_status
        ;;
    "shell")
        show_banner
        open_shell "$@"
        ;;
    "help"|"-h"|"--help"|"")
        show_help
        ;;
    *)
        print_status $RED "❌" "Comando inválido: $1"
        echo ""
        show_help
        exit 1
        ;;
esac 