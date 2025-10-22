#!/bin/bash

# Script para configurar variáveis de ambiente do frontend em produção

echo "🔧 Configurando variáveis de ambiente do frontend..."

# Configurar variáveis de ambiente do frontend
gcloud run services update included-frontend \
  --region=us-central1 \
  --set-env-vars="VITE_API_URL=https://included-backend-556028162987.us-central1.run.app,VITE_STRIPE_PUBLISHABLE_KEY=pk_test_51RbltECBNk6vzSul7HZb5VwOvF6Fkfj6Ciu8sm6puvxqEqjh1NtvO0s077fkzwO79byokJEjTXoUw1HdlEnrCl9400wZSLiXif"

echo "✅ Variáveis de ambiente do frontend configuradas!"
echo "📋 Frontend agora aponta para: https://included-backend-556028162987.us-central1.run.app"
echo ""
echo "🚀 Execute o deploy do frontend novamente para aplicar as mudanças."
