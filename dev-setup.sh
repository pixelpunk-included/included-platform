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

# Função para verificar se o Stripe CLI está instalado
check_stripe_cli() {
    if ! command -v stripe &> /dev/null; then
        return 1
    fi
    return 0
}

# Função para instalar Stripe CLI
install_stripe_cli() {
    print_status $BLUE "🔧" "Instalando Stripe CLI..."

    # Detectar sistema operacional
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install stripe/stripe-cli/stripe
        else
            print_status $YELLOW "⚠️" "Homebrew não encontrado. Instalando via curl..."
            curl -s https://packages.stripe.dev/api/security/keypair/stripe-cli-gpg/public | gpg --dearmor | sudo tee /usr/share/keyrings/stripe.gpg
            echo "deb [signed-by=/usr/share/keyrings/stripe.gpg] https://packages.stripe.dev/stripe-cli-debian-local stable main" | sudo tee -a /etc/apt/sources.list.d/stripe.list
            sudo apt update
            sudo apt install stripe
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        curl -s https://packages.stripe.dev/api/security/keypair/stripe-cli-gpg/public | gpg --dearmor | sudo tee /usr/share/keyrings/stripe.gpg
        echo "deb [signed-by=/usr/share/keyrings/stripe.gpg] https://packages.stripe.dev/stripe-cli-debian-local stable main" | sudo tee -a /etc/apt/sources.list.d/stripe.list
        sudo apt update
        sudo apt install stripe
    else
        print_status $RED "❌" "Sistema operacional não suportado para instalação automática."
        print_status $YELLOW "💡" "Instale manualmente: https://stripe.com/docs/stripe-cli"
        return 1
    fi

    if check_stripe_cli; then
        print_status $GREEN "✅" "Stripe CLI instalado com sucesso!"
        return 0
    else
        print_status $RED "❌" "Falha na instalação do Stripe CLI."
        return 1
    fi
}

# Função para configurar Stripe CLI
setup_stripe_cli() {
    print_status $BLUE "🔑" "Configurando Stripe CLI..."

    if ! check_stripe_cli; then
        print_status $YELLOW "⚠️" "Stripe CLI não encontrado. Instalando..."
        if ! install_stripe_cli; then
            return 1
        fi
    fi

    # Verificar se já está logado
    if stripe config --list | grep -q "api_key"; then
        print_status $GREEN "✅" "Stripe CLI já configurado!"
        return 0
    fi

    print_status $YELLOW "🔐" "Você precisa fazer login no Stripe CLI."
    print_status $CYAN "💡" "1. Acesse: https://dashboard.stripe.com/apikeys"
    print_status $CYAN "💡" "2. Copie sua chave secreta (sk_test_...)"
    print_status $CYAN "💡" "3. Execute: stripe login"
    echo ""

    read -p "Pressione Enter quando estiver pronto para continuar..."

    # Tentar fazer login
    if stripe login; then
        print_status $GREEN "✅" "Login no Stripe CLI realizado com sucesso!"
        return 0
    else
        print_status $RED "❌" "Falha no login do Stripe CLI."
        return 1
    fi
}

# Função para configurar webhook automaticamente
setup_stripe_webhook() {
    print_status $BLUE "🔗" "Configurando webhook do Stripe..."

    if ! check_stripe_cli; then
        print_status $RED "❌" "Stripe CLI não encontrado. Execute 'setup' primeiro."
        return 1
    fi

    # Verificar se já existe webhook
    local webhook_url="http://localhost:8000/api/assinaturas/webhook/"
    local existing_webhooks=$(stripe webhook_endpoints list --limit 10 2>/dev/null | grep -c "$webhook_url" || echo "0")

    if [ "$existing_webhooks" -gt 0 ]; then
        print_status $GREEN "✅" "Webhook já configurado!"
        return 0
    fi

    print_status $BLUE "🔧" "Criando webhook endpoint..."

    # Criar webhook
    local webhook_output=$(stripe webhook_endpoints create \
        --url "$webhook_url" \
        --enabled-events checkout.session.completed \
        --enabled-events customer.subscription.created \
        --enabled-events customer.subscription.updated \
        --enabled-events customer.subscription.deleted \
        --enabled-events invoice.payment_succeeded \
        --enabled-events invoice.payment_failed \
        --description "IncludED Development Webhook" 2>/dev/null)

    if [ $? -eq 0 ]; then
        # Extrair webhook secret
        local webhook_secret=$(echo "$webhook_output" | grep -o 'whsec_[a-zA-Z0-9_]*' | head -1)

        if [ -n "$webhook_secret" ]; then
            print_status $GREEN "✅" "Webhook criado com sucesso!"
            print_status $CYAN "🔑" "Webhook Secret: $webhook_secret"

            # Atualizar .env se existir
            if [ -f ".env" ]; then
                if grep -q "STRIPE_WEBHOOK_SECRET" .env; then
                    sed -i.bak "s/STRIPE_WEBHOOK_SECRET=.*/STRIPE_WEBHOOK_SECRET=$webhook_secret/" .env
                else
                    echo "STRIPE_WEBHOOK_SECRET=$webhook_secret" >> .env
                fi
                print_status $GREEN "✅" "Webhook secret adicionado ao .env!"
            else
                print_status $YELLOW "⚠️" "Arquivo .env não encontrado. Adicione manualmente:"
                print_status $CYAN "💡" "STRIPE_WEBHOOK_SECRET=$webhook_secret"
            fi

            return 0
        else
            print_status $RED "❌" "Falha ao extrair webhook secret."
            return 1
        fi
    else
        print_status $RED "❌" "Falha ao criar webhook."
        return 1
    fi
}

# Função para setup completo
setup_complete() {
    show_banner
    print_status $PURPLE "🚀" "SETUP COMPLETO DA FERRAMENTA"
    print_status $CYAN "📋" "Configurando ambiente de desenvolvimento completo..."
    echo ""

    # 1. Verificar Docker
    print_status $BLUE "1️⃣" "Verificando Docker..."
    if ! check_docker; then
        print_status $RED "❌" "Docker não está rodando. Inicie o Docker e tente novamente."
        exit 1
    fi
    print_status $GREEN "✅" "Docker OK!"
    echo ""

    # 2. Instalar dependências do frontend
    print_status $BLUE "2️⃣" "Instalando dependências do frontend..."
    if [ -f "included-frontend/package.json" ]; then
        cd included-frontend
        if command -v pnpm &> /dev/null; then
            pnpm install
        else
            print_status $YELLOW "⚠️" "pnpm não encontrado. Instalando..."
            npm install -g pnpm
            pnpm install
        fi
        cd ..
        print_status $GREEN "✅" "Dependências do frontend instaladas!"
    else
        print_status $YELLOW "⚠️" "package.json não encontrado no frontend."
    fi
    echo ""

    # 3. Configurar Stripe CLI
    print_status $BLUE "3️⃣" "Configurando Stripe CLI..."
    if setup_stripe_cli; then
        print_status $GREEN "✅" "Stripe CLI configurado!"
    else
        print_status $YELLOW "⚠️" "Stripe CLI não configurado. Configure manualmente depois."
    fi
    echo ""

    # 4. Configurar webhook
    print_status $BLUE "4️⃣" "Configurando webhook do Stripe..."
    if setup_stripe_webhook; then
        print_status $GREEN "✅" "Webhook configurado!"
    else
        print_status $YELLOW "⚠️" "Webhook não configurado. Configure manualmente depois."
    fi
    echo ""

    # 5. Configurar produtos Stripe
    print_status $BLUE "5️⃣" "Configurando produtos Stripe..."
    if [ -f "included-backend/manage.py" ]; then
        cd included-backend
        if [ -f ".env" ] || [ -f "../.env" ]; then
            python manage.py setup_stripe_products
            print_status $GREEN "✅" "Produtos Stripe configurados!"
        else
            print_status $YELLOW "⚠️" "Arquivo .env não encontrado. Configure as variáveis do Stripe primeiro."
        fi
        cd ..
    else
        print_status $YELLOW "⚠️" "manage.py não encontrado no backend."
    fi
    echo ""

    # 6. Iniciar ambiente
    print_status $BLUE "6️⃣" "Iniciando ambiente de desenvolvimento..."
    print_status $CYAN "💡" "Iniciando containers Docker..."
    docker-compose up --build -d

    # Aguardar containers iniciarem
    sleep 10

    print_status $GREEN "✅" "Setup completo finalizado!"
    echo ""
    print_status $PURPLE "🎉" "AMBIENTE PRONTO PARA DESENVOLVIMENTO!"
    echo ""
    print_status $CYAN "📋" "Próximos passos:"
    print_status $WHITE "   • Frontend: http://localhost:5173"
    print_status $WHITE "   • Backend: http://localhost:8000"
    print_status $WHITE "   • Admin: http://localhost:8000/admin"
    echo ""
    print_status $CYAN "🔧" "Comandos úteis:"
    print_status $WHITE "   • Ver logs: $0 logs"
    print_status $WHITE "   • Parar: $0 stop"
    print_status $WHITE "   • Status: $0 status"
    echo ""
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
    echo -e "  ${GREEN}setup${NC}     - 🚀 SETUP COMPLETO (instala tudo e configura Stripe)"
    echo -e "  ${GREEN}start${NC}     - 🚀 Inicia o ambiente completo (detecta dependências automaticamente)"
    echo -e "  ${GREEN}install${NC}   - 📦 Instala uma nova dependência (ex: $0 install @radix-ui/react-checkbox)"
    echo -e "  ${GREEN}watch${NC}     - 👀 Monitora mudanças nas dependências em tempo real"
    echo -e "  ${GREEN}stop${NC}      - 🛑 Para o ambiente"
    echo -e "  ${GREEN}restart${NC}   - 🔄 Reinicia o ambiente"
    echo -e "  ${GREEN}logs${NC}      - 📋 Mostra logs em tempo real"
    echo -e "  ${GREEN}clean${NC}     - 🧹 Limpa containers e volumes"
    echo -e "  ${GREEN}status${NC}    - 📊 Mostra status dos containers"
    echo ""
    echo -e "${PURPLE}Comandos Stripe:${NC}"
    echo -e "  ${GREEN}stripe-setup${NC}  - 🔧 Instala e configura Stripe CLI"
    echo -e "  ${GREEN}webhook-setup${NC} - 🔗 Configura webhook do Stripe"
    echo ""
    echo -e "${YELLOW}Exemplos:${NC}"
    echo -e "  $0 setup                    # Setup completo (recomendado para primeira vez)"
    echo -e "  $0 start                    # Iniciar ambiente"
    echo -e "  $0 install @radix-ui/react-checkbox"
    echo -e "  $0 stripe-setup             # Configurar apenas Stripe CLI"
    echo -e "  $0 webhook-setup            # Configurar apenas webhook"
    echo ""
    echo -e "${CYAN}💡 Dica: Use 'setup' para configuração completa na primeira vez!${NC}"
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
    "setup")
        setup_complete
        ;;
    "start")
        start_environment
        ;;
    "install")
        install_dependency "$2"
        ;;
    "stripe-setup")
        show_banner
        setup_stripe_cli
        ;;
    "webhook-setup")
        show_banner
        setup_stripe_webhook
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
