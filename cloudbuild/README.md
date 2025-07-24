# Cloud Build Configuration - IncludED Platform

Este diretório contém os arquivos de configuração do Google Cloud Build para automatizar o build e deploy da plataforma IncludED.

## Arquivos de Configuração

### Script de Deploy Automatizado
Use o script `deploy.sh` para facilitar os deploys:

```bash
# Deploy completo para produção
./deploy.sh deploy prod full

# Deploy para desenvolvimento
./deploy.sh deploy dev full

# Deploy apenas backend
./deploy.sh deploy prod backend

# Verificar status dos serviços
./deploy.sh status

# Ver ajuda
./deploy.sh help
```

### 1. `cloudbuild.yaml` - Build Completo (Produção)
Build e deploy completo de backend e frontend para produção.

**Comando para executar:**
```bash
gcloud builds submit --config cloudbuild/cloudbuild.yaml
```

### 2. `cloudbuild-backend.yaml` - Backend Apenas
Build e deploy apenas do backend Django.

**Comando para executar:**
```bash
gcloud builds submit --config cloudbuild/cloudbuild-backend.yaml
```

### 3. `cloudbuild-frontend.yaml` - Frontend Apenas
Build e deploy apenas do frontend React.

**Comando para executar:**
```bash
gcloud builds submit --config cloudbuild/cloudbuild-frontend.yaml
```

### 4. `cloudbuild-dev.yaml` - Ambiente de Desenvolvimento
Build e deploy para ambiente de desenvolvimento.

**Comando para executar:**
```bash
gcloud builds submit --config cloudbuild/cloudbuild-dev.yaml
```

## Pré-requisitos

1. **Google Cloud Project configurado**
2. **Cloud Build API habilitada**
3. **Container Registry habilitado**
4. **Cloud Run API habilitada**
5. **Permissões adequadas configuradas**

## Configuração Inicial

### 1. Habilitar APIs necessárias
```bash
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

### 2. Configurar permissões
```bash
# Dar permissão ao Cloud Build para fazer deploy no Cloud Run
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com" \
    --role="roles/run.admin"

# Dar permissão para invocar Cloud Run
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"
```

### 3. Configurar variáveis de ambiente
Antes de executar os builds, configure as variáveis de ambiente necessárias:

```bash
# Para o backend
export DATABASE_URL="postgresql://user:password@host:5432/database"
export SECRET_KEY="your-secret-key-here"

# Para o frontend
export API_URL="https://your-backend-url.com"
```

## Variáveis de Substituição

### Backend (`cloudbuild-backend.yaml`)
- `_REGION`: Região do Cloud Run (padrão: us-central1)
- `_DATABASE_URL`: URL de conexão com o banco de dados
- `_SECRET_KEY`: Chave secreta do Django

### Frontend (`cloudbuild-frontend.yaml`)
- `_REGION`: Região do Cloud Run (padrão: us-central1)
- `_API_URL`: URL da API do backend

### Desenvolvimento (`cloudbuild-dev.yaml`)
- `_REGION`: Região do Cloud Run (padrão: us-central1)
- `_DEV_API_URL`: URL da API de desenvolvimento

## Executando Builds com Substituições

```bash
# Build completo com variáveis customizadas
gcloud builds submit --config cloudbuild/cloudbuild.yaml \
    --substitutions=_REGION=us-central1,_DATABASE_URL="postgresql://...",_SECRET_KEY="..."

# Build do backend com variáveis
gcloud builds submit --config cloudbuild/cloudbuild-backend.yaml \
    --substitutions=_REGION=us-central1,_DATABASE_URL="postgresql://...",_SECRET_KEY="..."

# Build do frontend com variáveis
gcloud builds submit --config cloudbuild/cloudbuild-frontend.yaml \
    --substitutions=_REGION=us-central1,_API_URL="https://..."
```

## Configuração de Triggers (Opcional)

### Trigger para branch main (Produção)
```bash
gcloud builds triggers create github \
    --repo-name="included-platform" \
    --repo-owner="seu-usuario" \
    --branch-pattern="^main$" \
    --build-config="cloudbuild/cloudbuild.yaml"
```

### Trigger para branch develop (Desenvolvimento)
```bash
gcloud builds triggers create github \
    --repo-name="included-platform" \
    --repo-owner="seu-usuario" \
    --branch-pattern="^develop$" \
    --build-config="cloudbuild/cloudbuild-dev.yaml"
```

## Monitoramento

### Verificar status dos builds
```bash
gcloud builds list --limit=10
```

### Ver logs de um build específico
```bash
gcloud builds log [BUILD_ID]
```

### Ver serviços do Cloud Run
```bash
gcloud run services list --region=us-central1
```

## Troubleshooting

### Erro de permissão
Se encontrar erros de permissão, verifique se o Cloud Build tem as permissões necessárias:
```bash
gcloud projects get-iam-policy $PROJECT_ID \
    --flatten="bindings[].members" \
    --format="table(bindings.role)" \
    --filter="bindings.members:cloudbuild.gserviceaccount.com"
```

### Erro de imagem não encontrada
Verifique se as imagens foram criadas corretamente:
```bash
gcloud container images list --repository=gcr.io/$PROJECT_ID
```

### Erro de variáveis de ambiente
Certifique-se de que todas as variáveis de ambiente necessárias estão configuradas no Cloud Run:
```bash
gcloud run services describe included-backend --region=us-central1
```

## Estrutura dos Serviços

Após o deploy, você terá os seguintes serviços no Cloud Run:

### Produção
- `included-backend`: Backend Django (porta 8000)
- `included-frontend`: Frontend React (porta 80)

### Desenvolvimento
- `included-backend-dev`: Backend Django para desenvolvimento
- `included-frontend-dev`: Frontend React para desenvolvimento

## URLs dos Serviços

Os serviços estarão disponíveis em URLs como:
- `https://included-backend-xxxxx-uc.a.run.app`
- `https://included-frontend-xxxxx-uc.a.run.app`

Substitua `xxxxx` pelo ID único gerado pelo Cloud Run. 