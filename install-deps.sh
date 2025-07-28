#!/bin/bash

# Script para instalar novas dependências no Docker
# Uso: ./install-deps.sh [pacote]

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir com cores
print_status() {
    local color=$1
    local icon=$2
    local message=$3
    echo -e "${color}${icon} ${message}${NC}"
}

# Verificar se o Docker está rodando
if ! docker info > /dev/null 2>&1; then
    print_status $RED "❌" "Docker não está rodando. Por favor, inicie o Docker primeiro."
    exit 1
fi

# Verificar se docker-compose.yml existe
if [ ! -f "docker-compose.yml" ]; then
    print_status $RED "❌" "Arquivo docker-compose.yml não encontrado!"
    exit 1
fi

if [ -z "$1" ]; then
    print_status $YELLOW "⚠️" "Nenhum pacote especificado."
    echo -e "${BLUE}Uso: $0 {pacote}${NC}"
    echo -e "${BLUE}Exemplo: $0 @radix-ui/react-checkbox${NC}"
    exit 1
fi

PACKAGE=$1

print_status $BLUE "📦" "Instalando $PACKAGE no container frontend..."

# Parar o container frontend se estiver rodando
print_status $YELLOW "⏳" "Parando container frontend..."
docker-compose stop frontend

# Instalar a dependência no container
print_status $GREEN "🔧" "Instalando $PACKAGE..."
docker-compose run --rm frontend pnpm add $PACKAGE

# Reinstalar localmente também
print_status $GREEN "🔧" "Instalando $PACKAGE localmente..."
cd included-frontend
pnpm add $PACKAGE
cd ..

# Rebuildar a imagem
print_status $BLUE "🔨" "Rebuildando imagem frontend..."
docker-compose build frontend

print_status $GREEN "✅" "Dependência $PACKAGE instalada com sucesso!"
print_status $YELLOW "💡" "Execute 'docker-compose up' para iniciar o ambiente." 