# 🔧 Troubleshooting - Cloud Build com Submódulos

## ❌ Problema Identificado

**Erro:** `unable to prepare context: unable to evaluate symlinks in Dockerfile path: lstat /workspace/included-backend/Dockerfile: no such file or directory`

**Causa:** O Cloud Build não inicializa submódulos automaticamente, apenas baixa o repositório principal.

## ✅ Soluções Aplicadas

### 1. **Arquivos Atualizados:**

- ✅ `cloudbuild.yaml` - Adicionado step de inicialização de submódulos
- ✅ `cloudbuild/cloudbuild-dev.yaml` - Adicionado step de inicialização
- ✅ `cloudbuild/cloudbuild-test-submodules.yaml` - Arquivo de teste criado

### 2. **Mudanças Principais:**

#### Antes (❌ Problemático):
```yaml
steps:
  # Build do Backend Django
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-f', 'included-backend/Dockerfile', ...]
```

#### Depois (✅ Corrigido):
```yaml
steps:
  # Inicializar submódulos PRIMEIRO
  - name: 'gcr.io/cloud-builders/git'
    entrypoint: 'bash'
    args:
      - '-c'
      - |
        git submodule init
        git submodule update --recursive
    id: 'init-submodules'

  # Build do Backend Django (DEPOIS)
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-f', 'included-backend/Dockerfile', ...]
    waitFor: ['init-submodules']  # ← AGUARDA INICIALIZAÇÃO
```

## 🧪 Como Testar a Correção

### **Teste 1: Verificar Submódulos**

```bash
gcloud builds submit --config cloudbuild/cloudbuild-test-submodules.yaml
```

Este comando vai:
- ✅ Verificar se os submódulos estão sendo baixados
- ✅ Confirmar se os Dockerfiles existem
- ✅ Gerar relatório detalhado

### **Teste 2: Build Completo**

```bash
gcloud builds submit --config cloudbuild.yaml
```

## 📋 Checklist de Verificação

Antes de executar o build, confirme:

- [ ] **Submódulos configurados localmente:**
  ```bash
  git submodule status
  # Deve mostrar os 2 submódulos
  ```

- [ ] **Arquivos .gitmodules correto:**
  ```bash
  cat .gitmodules
  # Deve mostrar included-backend e included-frontend
  ```

- [ ] **Dockerfiles existem nos submódulos:**
  ```bash
  ls included-backend/Dockerfile
  ls included-frontend/Dockerfile.prod
  ```

## 🔍 Logs para Monitorar

### **No Cloud Build, procure por:**

✅ **Sucesso:**
```
🔄 Inicializando submódulos...
✅ Submódulos inicializados:
✅ included-backend encontrado
✅ included-frontend encontrado
```

❌ **Falha:**
```
❌ Backend não encontrado
❌ Frontend não encontrado
unable to prepare context: unable to evaluate symlinks
```

## 🚨 Problemas Comuns

### **1. Submódulos não inicializam**

**Sintomas:** Pastas vazias ou inexistentes

**Solução:**
```yaml
# Usar método alternativo de inicialização
- name: 'gcr.io/cloud-builders/git'
  args: ['submodule', 'update', '--init', '--recursive']
```

### **2. Permissões de acesso aos submódulos**

**Sintomas:** `Permission denied` ou `Authentication failed`

**Solução:**
- Verificar se o Cloud Build tem acesso aos repositórios dos submódulos
- Configurar GitHub App ou chaves SSH se necessário

### **3. Branch incorreta nos submódulos**

**Sintomas:** Arquivos desatualizados ou diferentes

**Solução:**
```bash
# Verificar qual branch está sendo usada
git submodule status
# Atualizar para branch específica se necessário
git submodule update --remote
```

## 📞 Como Reportar Problemas

Se o erro persistir, inclua estas informações:

1. **ID do Build:** (ex: `74cbf049-a960-4230-9f47-f8b3033bbf65`)
2. **Logs completos** da seção "Steps da versão"
3. **Branch sendo testada:** (ex: `launchpad`, `main`)
4. **Output do comando:**
   ```bash
   git submodule status
   ```

## 🎯 Próximos Passos

1. **Execute primeiro:** `cloudbuild/cloudbuild-test-submodules.yaml`
2. **Se der sucesso:** Execute `cloudbuild.yaml` 
3. **Monitore os logs** para confirmar que os submódulos estão sendo inicializados
4. **Ajuste conforme necessário**

---

**✅ Correção aplicada com sucesso!** 
Os arquivos foram atualizados para inicializar os submódulos automaticamente antes de tentar fazer o build. 