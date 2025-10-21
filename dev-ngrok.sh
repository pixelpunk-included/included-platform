#!/bin/bash

echo "🚀 Iniciando ambiente de desenvolvimento com ngrok..."

# Verificar se NGROK_AUTHTOKEN está definido
if [ -z "$NGROK_AUTHTOKEN" ]; then
    echo "❌ NGROK_AUTHTOKEN não definido!"
    echo "📝 Configure com: export NGROK_AUTHTOKEN=seu_authtoken_aqui"
    echo "🔗 Obtenha seu authtoken em: https://dashboard.ngrok.com/get-started/your-authtoken"
    exit 1
fi

# Parar containers existentes
echo "🛑 Parando containers existentes..."
docker-compose down

# Iniciar com ngrok
echo "🐳 Iniciando containers com ngrok..."
docker-compose up -d

# Aguardar containers inicializarem
echo "⏳ Aguardando containers inicializarem..."
sleep 10

# Obter URL do ngrok
echo "🔍 Obtendo URL do ngrok..."
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for tunnel in data.get('tunnels', []):
        if 'backend' in tunnel.get('name', ''):
            print(tunnel['public_url'])
            break
except:
    print('')
")

if [ -n "$NGROK_URL" ]; then
    echo "✅ ngrok iniciado com sucesso!"
    echo "🌐 Backend URL: $NGROK_URL"
    echo "🔗 Webhook URL: $NGROK_URL/api/assinaturas/webhook/"
    echo "🌐 ngrok Web Interface: http://localhost:4040"
    echo ""
    echo "📝 Configure no Stripe Dashboard:"
    echo "   URL: $NGROK_URL/api/assinaturas/webhook/"
    echo ""
    echo "🖥️  Frontend: http://localhost:5173"
    echo "🖥️  Backend: http://localhost:8000"
else
    echo "⚠️  ngrok iniciado, mas não foi possível obter a URL"
    echo "🌐 Acesse http://localhost:4040 para ver as URLs"
fi

echo ""
echo "🎉 Ambiente de desenvolvimento pronto!"
echo "💡 Use 'docker-compose logs -f ngrok' para ver logs do ngrok"
echo "💡 Use 'docker-compose down' para parar todos os serviços"
