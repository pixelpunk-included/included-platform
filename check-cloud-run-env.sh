#!/bin/bash

# Script para verificar variáveis de ambiente atuais do Cloud Run

echo "🔍 Verificando configurações atuais do Cloud Run..."

gcloud run services describe included-backend \
  --region=us-central1 \
  --format="value(spec.template.spec.template.spec.containers[0].env[].name,spec.template.spec.template.spec.containers[0].env[].value)" \
  | while read name value; do
    if [ -n "$name" ]; then
      if [[ "$name" == *"PASSWORD"* ]] || [[ "$name" == *"SECRET"* ]]; then
        echo "  $name: [HIDDEN]"
      else
        echo "  $name: $value"
      fi
    fi
  done

echo ""
echo "📋 Para configurar novas variáveis, edite o arquivo configure-cloud-run-env.sh e execute:"
echo "   ./configure-cloud-run-env.sh"
