# Skill: GitHub Actions

## Quando usar

- Criar ou modificar workflows (`.github/workflows/*.yml`)
- Configurar CI/CD com GitHub Actions
- Debugar falhas de workflow

## Convenções

### Estrutura de workflow

```yaml
name: Nome descritivo
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read  # Princípio do menor privilégio

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Step descritivo
        run: |
          comando
```

### Regras invioláveis

1. **Pin de versões**: sempre use SHA ou tag específica em actions (`@v4`, nunca `@main`)
2. **Permissions mínimas**: declare `permissions:` no nível do workflow E do job
3. **Secrets**: use `${{ secrets.NOME }}` — NUNCA hardcode
4. **OIDC para cloud**: prefira `aws-actions/configure-aws-credentials` com OIDC
5. **Cache**: use `actions/cache` para node_modules, pip, go modules
6. **Timeout**: defina `timeout-minutes:` em todo job
7. **Concurrency**: use `concurrency:` para evitar deploys paralelos

### Patterns comuns

#### CI básico (lint + test + build)
```yaml
jobs:
  ci:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npm test
      - run: npm run build
```

#### Deploy com aprovação
```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production  # Requer aprovação configurada no repo
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789:role/deploy
          aws-region: us-east-1
```

#### Matrix strategy
```yaml
jobs:
  test:
    strategy:
      matrix:
        node-version: [18, 20, 22]
        os: [ubuntu-latest, windows-latest]
    runs-on: ${{ matrix.os }}
```

### Anti-patterns (NUNCA faça)

- ❌ `actions/checkout@main` — pin sempre com tag ou SHA
- ❌ `permissions: write-all` — declare apenas o necessário
- ❌ `${{ github.event.pull_request.title }}` em `run:` sem sanitizar — injection risk
- ❌ Secrets em logs: cuidado com `echo` e `set -x`
- ❌ Self-hosted runners sem hardening — isole em containers

### Validação antes de merge

```bash
# Lint do workflow YAML
actionlint .github/workflows/*.yml

# Validar com act (local)
act -n  # dry-run
```
