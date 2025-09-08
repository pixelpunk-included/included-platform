# IncludED Platform

Plataforma educacional inclusiva para gestão de PEI (Plano Educacional Individualizado).

## 🏗️ Estrutura do Projeto

```
included-platform/
├── included-backend/          # Backend Django
├── included-frontend/         # Frontend React
├── cloudbuild.yaml           # 🆕 Build principal (raiz)
├── cloudbuild/               # Configurações Cloud Build
│   ├── cloudbuild-dev.yaml   # Build desenvolvimento
│   ├── cloudbuild-backend.yaml
│   ├── cloudbuild-frontend.yaml
│   ├── cloudbuild.env.example
│   ├── deploy.sh
│   └── README.md
├── docker-compose.yml        # Desenvolvimento local
├── docker-compose.prod.yml   # Produção local
└── README.md                 # Este arquivo
```

## 🚀 Deploy Automatizado

### Pré-requisitos

- Google Cloud Project configurado
- gcloud CLI instalado e autenticado
- APIs habilitadas (Cloud Build, Cloud Run, Container Registry)

### Deploy Rápido

```bash
# Deploy completo para produção
./cloudbuild/deploy.sh deploy prod full

# Deploy para desenvolvimento
./cloudbuild/deploy.sh deploy dev full

# Deploy apenas backend
./cloudbuild/deploy.sh deploy prod backend

# Verificar status
./cloudbuild/deploy.sh status
```

### Deploy Manual

```bash
# Produção (usando arquivo da raiz)
gcloud builds submit --config cloudbuild.yaml

# Desenvolvimento
gcloud builds submit --config cloudbuild/cloudbuild-dev.yaml

# Backend apenas
gcloud builds submit --config cloudbuild/cloudbuild-backend.yaml

# Frontend apenas
gcloud builds submit --config cloudbuild/cloudbuild-frontend.yaml
```

## 🛠️ Desenvolvimento Local

### Com Docker Compose

```bash
# Desenvolvimento
./docker-dev.sh

# Ou manualmente
docker-compose up -d
```

### Sem Docker

```bash
# Backend
cd included-backend
python -m venv venv
source venv/bin/activate  # Linux/Mac
# ou venv\Scripts\activate  # Windows
pip install -r requirements.txt
python manage.py runserver

# Frontend
cd included-frontend
pnpm install
pnpm dev
```

## 📚 Documentação

- [Configuração Cloud Build](cloudbuild/README.md) - Guia detalhado de deploy
- [Docker Setup](DOCKER_SETUP.md) - Configuração de containers
- [Backend API](included-backend/) - Documentação da API Django
- [Frontend](included-frontend/) - Documentação do React

## 🔧 Configuração

### Variáveis de Ambiente

Copie o arquivo de exemplo e configure suas variáveis:

```bash
cp cloudbuild/cloudbuild.env.example cloudbuild/cloudbuild.env
# Edite cloudbuild/cloudbuild.env com suas configurações
```

### Configuração Inicial do Google Cloud

```bash
# Habilitar APIs
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

# Configurar permissões
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com" \
    --role="roles/run.admin"
```

## 📦 Tecnologias

- **Backend**: Django, Django REST Framework, MySQL
- **Frontend**: React, TypeScript, Vite, Tailwind CSS
- **Infraestrutura**: Google Cloud Platform, Cloud Run, Cloud Build
- **Containerização**: Docker, Docker Compose

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.
