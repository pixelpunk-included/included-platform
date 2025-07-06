#!/bin/bash

# Script para desenvolvimento com Docker
# Uso: ./docker-dev.sh [comando]

set -e

case "$1" in
    "up")
        echo "🚀 Iniciando ambiente de desenvolvimento..."
        docker-compose up --build
        ;;
    "down")
        echo "🛑 Parando ambiente de desenvolvimento..."
        docker-compose down
        ;;
    "restart")
        echo "🔄 Reiniciando ambiente de desenvolvimento..."
        docker-compose down
        docker-compose up --build
        ;;
    "logs")
        echo "📋 Mostrando logs..."
        docker-compose logs -f
        ;;
    "backend")
        echo "🐍 Executando apenas o backend..."
        docker-compose up --build backend
        ;;
    "frontend")
        echo "⚛️ Executando apenas o frontend..."
        docker-compose up --build frontend
        ;;
    "clean")
        echo "🧹 Limpando containers e volumes..."
        docker-compose down -v
        docker system prune -f
        ;;
    "build")
        echo "🔨 Fazendo build de todos os serviços..."
        docker-compose build
        ;;
    *)
        echo "Uso: $0 {up|down|restart|logs|backend|frontend|clean|build}"
        echo ""
        echo "Comandos:"
        echo "  up       - Inicia o ambiente completo"
        echo "  down     - Para o ambiente"
        echo "  restart  - Reinicia o ambiente"
        echo "  logs     - Mostra logs em tempo real"
        echo "  backend  - Executa apenas o backend"
        echo "  frontend - Executa apenas o frontend"
        echo "  clean    - Limpa containers e volumes"
        echo "  build    - Faz build de todos os serviços"
        exit 1
        ;;
esac 