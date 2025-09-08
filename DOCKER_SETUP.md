# Configuração Docker - IncludED

Este projeto está organizado com uma arquitetura Docker separada para backend (Django) e frontend (React).

## 📁 Estrutura dos Projetos

```
IncludED/
├── included-backend/          # Backend Django
│   ├── Dockerfile            # Desenvolvimento
│   ├── Dockerfile.prod       # Produção
│   ├── .dockerignore
│   ├── requirements.txt
│   └── nginx.conf           # Configuração nginx
├── included-frontend/         # Frontend React
│   ├── Dockerfile            # Desenvolvimento
│   ├── Dockerfile.prod       # Produção
│   ├── .dockerignore
│   └── package.json
├── docker-compose.yml        # Desenvolvimento
├── docker-compose.prod.yml   # Produção
└── docker-dev.sh            # Scripts de conveniência
```

## 🚀 Desenvolvimento Local

### Pré-requisitos

- Docker e Docker Compose instalados
- Git

### Comandos Rápidos

```bash
# Iniciar ambiente completo
./docker-dev.sh up

# Parar ambiente
./docker-dev.sh down

# Reiniciar ambiente
./docker-dev.sh restart

# Ver logs
./docker-dev.sh logs

# Executar apenas backend
./docker-dev.sh backend

# Executar apenas frontend
./docker-dev.sh frontend

# Limpar tudo
./docker-dev.sh clean
```

### Acessos

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **Admin Django**: http://localhost:8000/admin
- **MySQL**: localhost:3306
- **Redis**: localhost:6379

## 🏭 Produção

### Build e Deploy

```bash
# Build de produção
docker-compose -f docker-compose.prod.yml build

# Executar em produção
docker-compose -f docker-compose.prod.yml up -d

# Parar produção
docker-compose -f docker-compose.prod.yml down
```

### Variáveis de Ambiente

Crie os arquivos `.env` necessários:

**Backend** (`included-backend/.env`):

```env
DEBUG=True
MYSQL_DB=included_db
MYSQL_USER=included
MYSQL_PASSWORD=included123
MYSQL_HOST=localhost
MYSQL_PORT=3306
SECRET_KEY=your-secret-key
```

**Backend Produção** (`included-backend/.env.production`):

```env
DEBUG=False
MYSQL_DB=included_db
MYSQL_USER=included
MYSQL_PASSWORD=included123
MYSQL_HOST=db
MYSQL_PORT=3306
SECRET_KEY=your-production-secret-key
REDIS_URL=redis://redis:6379/0
```

## 🔧 Configurações Específicas

### Backend (Django)

**Dockerfile** - Desenvolvimento:

- Python 3.12
- Hot reload com `runserver`
- Volumes montados para desenvolvimento

**Dockerfile.prod** - Produção:

- Gunicorn como servidor WSGI
- Coleta de arquivos estáticos
- Otimizado para produção

### Frontend (React + Vite + pnpm)

**Dockerfile** - Desenvolvimento:

- Node 20 Alpine
- pnpm para gerenciamento de dependências
- Hot reload com Vite

**Dockerfile.prod** - Produção:

- Multi-stage build
- Build otimizado
- Nginx para servir arquivos estáticos

### Nginx

O arquivo `nginx.conf` no backend configura:

- Proxy reverso para API Django
- Servir arquivos estáticos do React
- Headers de segurança
- Compressão gzip
- Rate limiting

## 🛠️ Comandos Úteis

### Desenvolvimento Individual

```bash
# Build apenas do backend
docker build -t included-backend ./included-backend

# Build apenas do frontend
docker build -t included-frontend ./included-frontend

# Executar backend isoladamente
docker run -p 8000:8000 included-backend

# Executar frontend isoladamente
docker run -p 3000:3000 included-frontend
```

### Debugging

```bash
# Entrar no container do backend
docker-compose exec backend bash

# Entrar no container do frontend
docker-compose exec frontend sh

# Ver logs específicos
docker-compose logs backend
docker-compose logs frontend
```

### Limpeza

```bash
# Remover containers parados
docker container prune

# Remover imagens não utilizadas
docker image prune

# Limpeza completa
docker system prune -a
```

## 📝 Notas Importantes

1. **Volumes**: Os volumes estão configurados para desenvolvimento com hot reload
2. **Networks**: Todos os serviços estão na mesma rede `included-network`
3. **Portas**: Evite conflitos de porta com outros serviços
4. **Dependências**: O frontend depende do backend estar rodando
5. **Banco de Dados**: MySQL é usado em todos os ambientes (desenvolvimento e produção)

## 🔍 Troubleshooting

### Problemas Comuns

1. **Porta já em uso**:

   ```bash
   # Verificar portas em uso
   lsof -i :8000
   lsof -i :3000
   ```

2. **Build falhando**:

   ```bash
   # Limpar cache do Docker
   docker system prune -f
   # Rebuild
   docker-compose build --no-cache
   ```

3. **Volumes não sincronizando**:

   ```bash
   # Rebuild sem cache
   docker-compose up --build --force-recreate
   ```

4. **Permissões de arquivo**:
   ```bash
   # Corrigir permissões do script
   chmod +x docker-dev.sh
   ```

## 🚀 Próximos Passos

1. Configurar CI/CD com GitHub Actions
2. Adicionar testes automatizados
3. Configurar monitoramento e logs
4. Implementar backup automático do banco
5. Configurar SSL/TLS para produção
