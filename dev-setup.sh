#!/bin/bash

# Script para desenvolvimento facilitado
# Detecta automaticamente novas dependências e configura o ambiente

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

# Função para mostrar banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    INCLUDED PLATFORM                        ║"
    echo "║              Desenvolvimento Automatizado                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Função para verificar se o Docker está rodando
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_status $RED "❌" "Docker não está rodando. Por favor, inicie o Docker primeiro."
        exit 1
    fi
}

# Função para detectar novas dependências
detect_new_dependencies() {
    local frontend_dir="./included-frontend"
    
    if [ ! -f "$frontend_dir/package.json" ]; then
        print_status $RED "❌" "Diretório frontend não encontrado!"
        return 1
    fi
    
    # Verificar se há mudanças no package.json
    if [ -f "$frontend_dir/.package_hash" ]; then
        local current_hash=$(md5sum "$frontend_dir/package.json" | awk '{print $1}')
        local stored_hash=$(cat "$frontend_dir/.package_hash")
        
        if [ "$current_hash" != "$stored_hash" ]; then
            print_status $YELLOW "📦" "Detectadas novas dependências!"
            
            # Verificar se o container está rodando
            if docker-compose ps frontend | grep -q "Up"; then
                print_status $BLUE "🔄" "Container está rodando, instalando dependências automaticamente..."
                
                # Instalar no container em execução (sem parar)
                docker-compose exec frontend pnpm install
                
                print_status $GREEN "✅" "Dependências instaladas no container em execução!"
            else
                print_status $BLUE "🔄" "Container parado, rebuildando..."
                docker-compose build frontend
            fi
            
            # Atualizar hash
            echo "$current_hash" > "$frontend_dir/.package_hash"
            return 0
        fi
    else
        # Primeira execução, criar hash
        md5sum "$frontend_dir/package.json" | awk '{print $1}' > "$frontend_dir/.package_hash"
    fi
    
    return 1
}

# Função para iniciar ambiente
start_environment() {
    show_banner
    print_status $GREEN "🚀" "Iniciando ambiente de desenvolvimento..."
    
    # Verificar Docker
    check_docker
    
    # Detectar novas dependências
    if detect_new_dependencies; then
        print_status $GREEN "✅" "Dependências atualizadas automaticamente!"
    fi
    
    # Iniciar ambiente
    print_status $BLUE "🎯" "Iniciando containers..."
    docker-compose up --build
}

# Função para monitorar mudanças em tempo real
watch_dependencies() {
    show_banner
    print_status $CYAN "👀" "Monitorando mudanças nas dependências..."
    print_status $YELLOW "⚠️" "Pressione Ctrl+C para sair"
    echo ""
    
    local frontend_dir="./included-frontend"
    local last_hash=""
    
    # Obter hash inicial
    if [ -f "$frontend_dir/package.json" ]; then
        last_hash=$(md5sum "$frontend_dir/package.json" | awk '{print $1}')
    fi
    
    while true; do
        if [ -f "$frontend_dir/package.json" ]; then
            local current_hash=$(md5sum "$frontend_dir/package.json" | awk '{print $1}')
            
            if [ "$current_hash" != "$last_hash" ]; then
                echo ""
                print_status $YELLOW "📦" "Mudança detectada no package.json!"
                
                # Verificar se o container está rodando
                if docker-compose ps frontend | grep -q "Up"; then
                    print_status $BLUE "🔄" "Instalando dependências no container..."
                    docker-compose exec frontend pnpm install
                    print_status $GREEN "✅" "Dependências atualizadas!"
                else
                    print_status $BLUE "🔄" "Container parado, iniciando..."
                    docker-compose up -d frontend
                fi
                
                last_hash=$current_hash
                echo "$current_hash" > "$frontend_dir/.package_hash"
            fi
        fi
        
        sleep 2
    done
}

# Função para instalar nova dependência
install_dependency() {
    if [ -z "$1" ]; then
        print_status $YELLOW "⚠️" "Nenhuma dependência especificada."
        echo -e "${BLUE}Uso: $0 install {pacote}${NC}"
        echo -e "${BLUE}Exemplo: $0 install @radix-ui/react-checkbox${NC}"
        exit 1
    fi
    
    local package=$1
    
    show_banner
    print_status $BLUE "📦" "Instalando $package..."
    
    # Instalar localmente
    cd included-frontend
    pnpm add "$package"
    cd ..
    
    # Atualizar hash
    md5sum "included-frontend/package.json" | awk '{print $1}' > "included-frontend/.package_hash"
    
    print_status $GREEN "✅" "Dependência $package instalada localmente!"
    
    # Verificar se o container está rodando e instalar automaticamente
    if docker-compose ps frontend | grep -q "Up"; then
        print_status $BLUE "🔄" "Instalando no container em execução..."
        docker-compose exec frontend pnpm install
        print_status $GREEN "✅" "Dependência instalada no container!"
    else
        print_status $YELLOW "💡" "Container não está rodando. Execute '$0 start' para iniciar."
    fi
}

# Função para mostrar ajuda
show_help() {
    show_banner
    echo -e "${WHITE}Uso: $0 {comando} [opções]${NC}"
    echo ""
    echo -e "${YELLOW}Comandos disponíveis:${NC}"
    echo ""
    echo -e "  ${GREEN}start${NC}     - 🚀 Inicia o ambiente completo (detecta dependências automaticamente)"
    echo -e "  ${GREEN}install${NC}   - 📦 Instala uma nova dependência (ex: $0 install @radix-ui/react-checkbox)"
    echo -e "  ${GREEN}watch${NC}     - 👀 Monitora mudanças nas dependências em tempo real"
    echo -e "  ${GREEN}stop${NC}      - 🛑 Para o ambiente"
    echo -e "  ${GREEN}restart${NC}   - 🔄 Reinicia o ambiente"
    echo -e "  ${GREEN}logs${NC}      - 📋 Mostra logs em tempo real"
    echo -e "  ${GREEN}clean${NC}     - 🧹 Limpa containers e volumes"
    echo -e "  ${GREEN}status${NC}    - 📊 Mostra status dos containers"
    echo ""
    echo -e "${YELLOW}Exemplos:${NC}"
    echo -e "  $0 start"
    echo -e "  $0 install @radix-ui/react-checkbox"
    echo -e "  $0 watch"
    echo -e "  $0 logs"
    echo ""
    echo -e "${CYAN}💡 Dica: Use 'watch' para monitorar mudanças automaticamente!${NC}"
    echo -e "${CYAN}💡 Dica: O ambiente detecta automaticamente novas dependências!${NC}"
}

# Configuração de erro
set -e

# Verificar se docker-compose.yml existe
if [ ! -f "docker-compose.yml" ]; then
    print_status $RED "❌" "Arquivo docker-compose.yml não encontrado!"
    exit 1
fi

case "$1" in
    "start")
        start_environment
        ;;
    "install")
        install_dependency "$2"
        ;;
    "stop")
        show_banner
        print_status $YELLOW "🛑" "Parando ambiente..."
        docker-compose down
        print_status $GREEN "✅" "Ambiente parado!"
        ;;
    "restart")
        show_banner
        print_status $BLUE "🔄" "Reiniciando ambiente..."
        docker-compose down
        sleep 2
        start_environment
        ;;
    "logs")
        show_banner
        print_status $CYAN "📋" "Mostrando logs..."
        docker-compose logs -f
        ;;
    "clean")
        show_banner
        print_status $YELLOW "🧹" "Limpando ambiente..."
        docker-compose down -v
        docker system prune -f
        print_status $GREEN "✅" "Limpeza concluída!"
        ;;
    "status")
        show_banner
        print_status $CYAN "📊" "Status dos containers:"
        docker-compose ps
        ;;
    "watch")
        watch_dependencies
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