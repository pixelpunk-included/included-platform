#!/bin/bash

# Script para configurar apenas as variáveis essenciais que o Cloud Build precisa
# Este script NÃO sobrescreve as outras variáveis já configuradas

echo "🔧 Configurando variáveis essenciais para o Cloud Build..."

# Configurar apenas as variáveis essenciais que o Cloud Build precisa
gcloud run services update included-backend \
  --region=us-central1 \
  --update-env-vars="ENVIRONMENT=production,DJANGO_SETTINGS_MODULE=included_backend.production_settings,DEBUG=false"

echo "✅ Variáveis essenciais configuradas!"
echo "📋 As outras variáveis (banco, API keys, etc.) foram preservadas."
echo ""
echo "🚀 Agora o Cloud Build não vai sobrescrever suas configurações!"
