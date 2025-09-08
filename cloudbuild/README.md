# IncludED Platform - Cloud Build

Configuração limpa e direta para build dos 3 repositórios da plataforma IncludED.

## 🏗️ Estrutura

```
included-platform/
├── cloudbuild.yaml                 # Build produção (branch main)
├── cloudbuild/
│   ├── cloudbuild-dev.yaml         # Build desenvolvimento
│   └── README.md
├── included-backend/                # Django + MySQL
└── included-frontend/               # React + Vite + TypeScript
```

## 🚀 Comandos

**Produção:**

```bash
gcloud builds submit --config cloudbuild.yaml --substitutions COMMIT_SHA=$(git rev-parse HEAD)
```

**Desenvolvimento:**

```bash
gcloud builds submit --config cloudbuild/cloudbuild-dev.yaml --substitutions COMMIT_SHA=$(git rev-parse HEAD)
```

## 📋 O que faz

1. **Download** dos submódulos (backend + frontend)
2. **Build** das imagens Docker específicas para cada componente
3. **Deploy** automático no Cloud Run

**Simples. Direto. Funciona.** ✅
