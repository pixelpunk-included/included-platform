#!/bin/bash

# Script para desenvolvimento local com Stripe
# Uso: ./dev-stripe.sh

echo "🚀 Configurando desenvolvimento local com Stripe..."

# Verificar se o Stripe CLI está instalado
if ! command -v stripe &> /dev/null; then
    echo "❌ Stripe CLI não encontrado. Instalando..."
    brew install stripe/stripe-cli/stripe
fi

# Verificar se está logado
if ! stripe config --list | grep -q "account_id"; then
    echo "🔑 Fazendo login no Stripe..."
    stripe login
fi

echo "📡 Iniciando escuta de webhooks..."
echo "   URL: http://localhost:8000/api/assinaturas/webhook/"
echo "   Pressione Ctrl+C para parar"
echo ""

# Obter a chave de webhook
echo "🔐 Chave de webhook para .env:"
stripe listen --forward-to localhost:8000/api/assinaturas/webhook/ --print-secret
