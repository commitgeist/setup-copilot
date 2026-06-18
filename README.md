# setup-copilot

> **Ferramenta**: [GitHub Copilot CLI](https://docs.github.com/copilot) — terminal de IA agêntico do GitHub.

Setup padronizado do GitHub Copilot CLI para times de desenvolvimento.
Um comando instala: agentes com guardrails, skills com templates,
copilot-instructions.md e ADR workflow — tudo adaptado à sua stack.

## Qual setup usar?

| Aspecto | setup-opencode | setup-opencode-dev | setup-opencode-devtools | setup-antigravity | **setup-copilot** |
|---|---|---|---|---|---|
| **Motor** | OpenCode | OpenCode | OpenCode | Gemini CLI | **GitHub Copilot CLI** |
| **Persona** | DevOps/SRE | Dev apps | Dev ferramentas | Multi-perfil | **Multi-perfil** |
| **Modelo** | Multi-provider | Multi-provider | Multi-provider | Gemini (Google) | **GPT-4o / Claude (GitHub)** |
| **Autenticação** | API Key por provider | API Key | API Key | API Key / OAuth / Vertex | **GitHub login** |
| **Config gerada** | opencode.json | opencode.json | opencode.json | settings.json + GEMINI.md | **copilot-instructions.md** |
| **Perfis** | fixo (DevOps) | fixo (Dev) | fixo (Tooling) | devops, appdev, tooling, custom | **devops, appdev, tooling, custom** |

---

## O que é o GitHub Copilot CLI?

O [GitHub Copilot CLI](https://docs.github.com/copilot) é o terminal de IA do GitHub —
um TUI (terminal UI) que conecta modelos de linguagem a ferramentas reais (bash,
leitura/escrita de arquivos, APIs GitHub) através de agentes integrados.

Conceitos-chave:

| Conceito | O que é | Exemplo |
|---|---|---|
| **Agent** | Especialista integrado para uma tarefa | `code-review`, `delegate` |
| **Command** | Ação rápida via `/` no chat | `/init`, `/review`, `/pr`, `/diff` |
| **File mention** | Referenciar arquivo com `@` | `@src/api.ts corrige o bug na linha 42` |
| **Issue/PR mention** | Referenciar issue/PR com `#` | `#123 precisa de testes` |
| **Shell escape** | Executar comando do sistema com `!` | `! git status`, `! npm test` |
| **Instructions** | Arquivo de instruções do repo | `copilot-instructions.md`, `AGENTS.md` |
| **Skill** | Pacote de instruções para uma área específica | `terraform`, `kubernetes`, `github-actions` |

> Este repo **não é o Copilot CLI** — é um setup que configura o Copilot CLI
> com agentes seguros, skills contextuais e workflow baseado em ADR.

---

## Comece por aqui

### 0. Pré-requisitos

```bash
# 1. Conta GitHub com Copilot ativo
#    - Copilot Free: inclui acesso ao CLI
#    - Copilot Pro/Business/Enterprise: acesso completo

# 2. Instalar o Copilot CLI
npm install -g @githubnext/github-copilot-cli
# ou via GitHub CLI:
gh extension install github/gh-copilot

# 3. Dependências do setup
jq --version    # apt install jq / brew install jq
bash --version  # precisa 4.3+ (macOS: brew install bash)

# 4. Autenticar
copilot /login
# ou: gh auth login --scopes copilot
```

### 1. Instalar o setup

```bash
git clone https://github.com/commitgeist/setup-copilot.git
cd setup-copilot
./setup.sh
```

O wizard de 8 passos pergunta seu perfil, stack e agentes — gera tudo
personalizado. Em ~1 minuto você tem agentes, skills, copilot-instructions.md
e ADR workflow prontos.

> Modo não-interativo (padronizar time / CI):
> `cp answers.env.example answers.env && vi answers.env && ./setup.sh --answers answers.env`

### 2. Estrutura gerada

```
setup-copilot/setup.sh  ──▶  seu-repo/
                               ├── .github/
                               │   ├── copilot-instructions.md  (instruções do projeto)
                               │   ├── agents/                  (agentes com guardrails)
                               │   └── skills/                  (terraform, k8s, etc)
                               └── docs/adr/                    (seus ADRs vão aqui)
```

O Copilot CLI carrega `.github/copilot-instructions.md` automaticamente via `/init`.
Os agentes e skills ficam acessíveis como contexto nas conversas.

### 3. Primeiro uso (pós-setup)

```bash
# Entrar no Copilot CLI
copilot

# Ou via GitHub CLI
gh copilot
```

No chat interativo:

```
> /init                           # Carrega instruções do repo
> /help                           # Ver todos os comandos
> Explique a arquitetura deste projeto
```

### 4. Comandos essenciais

#### Navegação e controle

| Comando | O que faz |
|---|---|
| `/help` | Ajuda completa |
| `/init` | Carrega instruções do repo (AGENTS.md, copilot-instructions.md) |
| `/settings` | Ver/configurar ajustes |
| `/login` / `/logout` | Autenticação GitHub |
| `ctrl+s` | Stash/pop prompt atual |
| `ctrl+q` | Enqueue prompt |
| `ctrl+c` | Cancelar geração |
| `ctrl+c` ×2 | Sair do CLI |

#### Agentes e automação

| Comando | O que faz |
|---|---|
| `/agent` | Listar agentes disponíveis |
| `/review` | Rodar code-review agent no código |
| `/delegate` | Delegar tarefa — cria branch + commits + PR automaticamente |
| `/pr` | Operar em pull requests (listar, criar, revisar) |
| `/diff` | Revisar mudanças no diretório atual |

#### Referências no chat

| Sintaxe | O que faz | Exemplo |
|---|---|---|
| `@arquivo` | Mencionar arquivo como contexto | `@src/api.ts explique esta função` |
| `#número` | Mencionar issue ou PR | `#42 implemente o que essa issue pede` |
| `! comando` | Executar comando shell | `! git log --oneline -5` |

#### Permissões de diretório

| Comando | O que faz |
|---|---|
| `/add-dir` | Adicionar diretório ao escopo (seletivo) |
| `/list-dirs` | Listar diretórios no escopo |
| `/allow-all` | Habilitar acesso a todos os diretórios (⚠️ use com cautela) |

### 5. Workflow recomendado

O setup instala agentes com o mesmo fluxo ADR dos outros setups:

```
┌───────────────┐     ┌──────────┐     ┌──────────────────┐     ┌──────────┐
│   architect   │────▶│  HUMANO  │────▶│   developer /    │────▶│ /review  │
│ planeja e gera│     │ revisa e │     │ devops-engineer  │     │ valida   │
│ o ADR         │     │ aprova   │     │ implementa       │     │          │
└───────────────┘     └──────────┘     └──────────────────┘     └──────────┘
```

1. **architect** gera `docs/adr/0001-titulo.md` com plano completo
2. **Você** revisa e aprova (gate humano obrigatório)
3. **developer/devops-engineer** lê o ADR e executa passo a passo
4. **`/review`** ou **@reviewer** valida o resultado
5. **Você** abre o PR (ou o `/delegate` já abriu)

#### Agentes disponíveis por perfil

| Perfil | Agentes disponíveis |
|---|---|
| **devops** | architect, devops-engineer, reviewer |
| **appdev** | architect, developer, reviewer, tester |
| **tooling** | architect, developer, reviewer, tester |
| **custom** | architect, developer, devops-engineer, reviewer, tester |

#### Os agentes em detalhe

| Agente | Papel | Escrever arquivos | Executar bash | Destruir recursos |
|---|---|---|---|---|
| `architect` | Orquestrador | Só `docs/adr/*`, `docs/design/*` | ❌ Bloqueado | ❌ |
| `devops-engineer` | Executor (infra) | ✅ Tudo | ✅ (apply=ask) | ❌ deny |
| `developer` | Executor (código) | ✅ Tudo | ✅ | ❌ deny |
| `reviewer` | Validador | ❌ Bloqueado | 🔍 Só leitura | ❌ |
| `tester` | Testador | Só arquivos de teste | ✅ (testes) | ❌ |

### 6. Como usar na vida real

> **Importante:** o setup-copilot é um **instalador**, não o repo onde você trabalha.
> Você roda o setup dentro do repo do seu projeto e depois trabalha
> no seu repo normalmente com `copilot`.

#### Exemplo completo: subir infra com Terraform e GitHub Actions (perfil devops)

```bash
# ── 1. Criar o repo do projeto ──
mkdir infra-ecs && cd infra-ecs
git init

# ── 2. Rodar o setup (uma vez só) ──
git clone https://github.com/commitgeist/setup-copilot.git /tmp/setup-copilot
/tmp/setup-copilot/setup.sh
#
#   Wizard pergunta:
#     Perfil? → devops
#     Cloud?  → AWS
#     IaC?    → Terraform
#     K8s?    → Não
#     CI/CD?  → GitHub Actions
#     Banco?  → Nenhum
#     Agents? → architect, devops-engineer, reviewer
#
#   Resultado: .github/ (copilot-instructions.md, agents/, skills/),
#   docs/adr/

# ── 3. Abrir o Copilot CLI ──
copilot
> /init
```

**No chat (architect)** — pedir o plano:

```
> Leia .github/agents/architect.md — assuma esse papel.
> Planeje a criação de um cluster ECS Fargate na AWS para a aplicação
> "api-pagamentos" (.NET 8, porta 8080). Preciso de:
> - VPC com subnets públicas e privadas
> - ALB com HTTPS (certificado ACM)
> - ECS Cluster Fargate com service e task definition
> - ECR para as imagens
> - CloudWatch logs
> - Autoscaling baseado em CPU (min 2, max 10)
> - GitHub Actions workflow para CI/CD
> Região us-east-1, tudo via Terraform.
> Gere o ADR em docs/adr/
```

O copilot gera `docs/adr/0001-criar-ecs-fargate-api-pagamentos.md` com:
- Contexto e motivação
- Decisão (Fargate vs EC2, por quê)
- Alternativas descartadas
- Estimativa de custo
- **Implementation Guidelines** com passo a passo numerado
- Workflow de CI/CD proposto

**Você revisa o ADR** — lê, ajusta se necessário, aprova.

**Mandar implementar** (devops-engineer):

```
> Leia .github/agents/devops-engineer.md — assuma esse papel.
> Implemente docs/adr/0001-criar-ecs-fargate-api-pagamentos.md
> Um passo por vez. Mostre o plan antes de qualquer apply.
> Leia .github/skills/terraform/ e .github/skills/github-actions/ para contexto.
```

O copilot:
1. Cria os módulos `.tf` (VPC, ALB, ECS, ECR, IAM)
2. Cria `.github/workflows/deploy.yml` com OIDC + Terraform
3. Roda `! terraform fmt` + `! terraform validate`
4. Mostra o plan

**Validar** (reviewer):

```
> Leia .github/agents/reviewer.md — assuma esse papel.
> Valide a implementação contra docs/adr/0001-criar-ecs-fargate-api-pagamentos.md
> ! terraform validate && ! tflint
```

**Ou use /delegate** para criar PR direto:

```
> /delegate
```

#### Exemplo completo: criar API Next.js com PostgreSQL (perfil appdev)

```bash
mkdir app-dashboard && cd app-dashboard
git init
/tmp/setup-copilot/setup.sh
#   Perfil? → appdev | Linguagens? → TypeScript | Framework? → NestJS
#   Frontend? → Next.js | Banco? → PostgreSQL | Docker? → Sim
#   Agents? → architect, developer, reviewer, tester
```

```bash
copilot
> /init
```

**Planejar**:

```
> Leia .github/agents/architect.md — assuma esse papel.
> Planeje um dashboard admin com:
> - Next.js 14 (App Router) para frontend
> - NestJS para API backend
> - PostgreSQL com Prisma ORM
> - Autenticação com NextAuth.js
> - Docker Compose para dev local
> - Testes com Jest (backend) e Playwright (e2e)
> Gere o ADR.
```

**Implementar**:

```
> Leia .github/agents/developer.md — assuma esse papel.
> Leia .github/skills/nextjs/ e .github/skills/typescript/ para contexto.
> Implemente docs/adr/0001-dashboard-admin.md
> Comece pela estrutura e modelos do banco.
```

**Testar**:

```
> Leia .github/agents/tester.md — assuma esse papel.
> Escreva testes para os endpoints CRUD do NestJS.
> Cubra: happy path, validação, not found, auth obrigatória.
> ! npm test
```

**Review**:

```
> /review
> Foque em: segurança (SQL injection, XSS), performance (N+1 queries),
> e cobertura de testes.
```

#### Exemplo DevOps: pipeline completa com GitHub Actions

```bash
mkdir microservices && cd microservices
git init
/tmp/setup-copilot/setup.sh
#   Perfil? → devops | Cloud? → AWS,Azure | IaC? → Terraform | K8s? → Sim
```

```
> /init
> Leia .github/skills/github-actions/ para contexto.
> Crie um workflow CI/CD completo com:
> - Lint + test + build em PR
> - Deploy para staging em merge para develop
> - Deploy para production em merge para main (com aprovação)
> - OIDC para AWS (nunca access keys)
> - Matrix: testar em Node 18 e 20
> - Cache de node_modules
```

#### Exemplo Tooling: CLI em Python

```bash
mkdir infra-cli && cd infra-cli
git init
/tmp/setup-copilot/setup.sh
#   Perfil? → tooling | Linguagens? → Python | Cloud? → AWS | K8s? → Sim
```

```
> /init
> Planeje uma CLI chamada "kctl" que simplifica operações K8s comuns:
> - kctl pods: lista pods com status colorido
> - kctl logs: tail de logs com filtro por app
> - kctl restart: restart graceful de deployment
> - kctl scale: scale com confirmação
> Usar click para CLI, kubernetes-client, rich para output.
```

#### Resumo visual

```
setup-copilot/setup.sh  ──▶  seu-repo/
                               ├── .github/
                               │   ├── copilot-instructions.md  (instruções do projeto)
                               │   ├── agents/                  (agentes com guardrails)
                               │   │   ├── architect.md
                               │   │   ├── developer.md
                               │   │   ├── devops-engineer.md
                               │   │   ├── reviewer.md
                               │   │   └── tester.md
                               │   └── skills/                  (terraform, k8s, etc)
                               │       ├── aws-infra/
                               │       ├── terraform/
                               │       ├── github-actions/
                               │       └── ...
                               ├── docs/adr/                    (seus ADRs vão aqui)
                               └── ... seu código
```

O setup configura. O Copilot CLI executa. Os agentes seguem os ADRs.
Depois de rodar o setup, você **esquece ele** e trabalha no seu repo.

### 7. Usar o Copilot CLI pra aprender

O Copilot CLI lê os arquivos do repo. Depois de rodar o setup, você pode
pedir pra ele te ensinar:

```bash
cd setup-copilot
copilot
> /init
```

#### Aprender sobre os agentes

```
> @.github/agents/architect.md explique as permissões deste agente.
> O que ele pode e não pode fazer? Por que essas restrições existem?
```

```
> Compare @.github/agents/developer.md com @.github/agents/reviewer.md
> Qual a diferença de permissões e por quê?
```

#### Entender as skills

```
> @.github/skills/terraform/SKILL.md me explique as regras invioláveis.
> Dê um exemplo prático de cada anti-pattern listado.
```

```
> @.github/skills/github-actions/SKILL.md quais são os patterns de
> segurança que devo seguir? Me mostre um workflow completo.
```

#### Aprender a criar coisas novas

```
> Com base em @.github/agents/architect.md me ensine como criar um
> agente novo "secops" que só pode ler e nunca pode executar bash
```

```
> Me guie passo a passo pra criar uma skill nova "helm-deploy"
> que padronize deploy via Helm charts no nosso cluster
```

#### Simular cenários

```
> Simule que sou novo no time. Me faça um onboarding de 15 minutos:
> o que eu preciso saber pra começar a operar sem quebrar nada?
```

```
> Finja que um pod está em CrashLoopBackOff. Me guie pelo processo de
> diagnóstico — quais comandos eu deveria rodar e em que ordem?
```

### 8. Comandos úteis no dia a dia

Dentro do Copilot CLI, esses prompts cobrem 80% do trabalho real:

#### Planejamento

```
> Leia .github/agents/architect.md — assuma esse papel.
> Planeje a criação de <recurso>. Considere custo, segurança e rollback.
> Gere o ADR em docs/adr/

> Preciso migrar <serviço> de <origem> para <destino>. Analise riscos,
> estime custo e proponha um ADR com implementation guidelines.
```

#### Implementação

```
> Leia .github/agents/devops-engineer.md — assuma esse papel.
> Implemente docs/adr/0001-titulo.md, um passo por vez.
> Mostre o plan antes de qualquer apply.

> ! terraform fmt && ! terraform validate && ! tflint
> Só me mostra se tiver erro.

> Crie o Dockerfile pra esta app .NET 8 seguindo CIS Benchmark.
> Multi-stage, non-root, healthcheck, pin de versão.
```

#### Validação e review

```
> /review

> Leia .github/agents/reviewer.md — assuma esse papel.
> Valide a implementação contra docs/adr/0001-titulo.md

> Audite todos os Dockerfiles do repo. Pra cada um, liste violações
> de segurança. Não modifique — só relatório.
```

#### Troubleshooting

```
> ! kubectl get pods -n myapp | grep -v Running
> Diagnostique os pods com problema. Verifique logs e events.

> ! terraform plan 2>&1 | tail -50
> O plan está mostrando destroy inesperado. Analise e explique.
```

#### Desenvolvimento

```
> Leia .github/agents/developer.md — assuma esse papel.
> Crie um endpoint POST /api/v1/orders com validação, persistência
> no PostgreSQL e testes. Leia .github/skills/typescript/ para contexto.

> /delegate
> Implemente a issue #42 conforme descrito nos acceptance criteria.
```

### 9. Diferença para os outros setups

| Aspecto | setup-opencode | setup-antigravity | **setup-copilot** |
|---|---|---|---|
| Motor | OpenCode CLI | Gemini CLI | GitHub Copilot CLI |
| Setup wizard | ✅ `setup.sh` 12+ steps | ✅ `setup.sh` 12 steps | ✅ `setup.sh` 8 steps |
| Config gerada | `opencode.json` + `AGENTS.md` | `settings.json` + `GEMINI.md` | `copilot-instructions.md` |
| Modelos | Multi-provider (Anthropic, OpenAI, Ollama) | Gemini (Google) | GPT-4o, Claude (via GitHub) |
| MCPs | Configuráveis via JSON | Configuráveis via JSON | Integrados (GitHub nativo) |
| PR automation | Manual | Manual | `/delegate` (branch + PR automático) |
| Code review | Via agente `@reviewer` | Via agente `@reviewer` | `/review` nativo + `@reviewer` |
| Custo | Depende do provider | Depende do tier Google | Copilot Free / Pro / Business |
| Skills | Mesma biblioteca | Mesma biblioteca | Mesma biblioteca |
| Agentes | Mesmos templates | Mesmos templates | Mesmos templates |

### 10. Vantagem exclusiva: /delegate

O Copilot CLI tem uma feature que os outros não têm — o `/delegate`:

```
> Leia a issue #42. Implemente conforme os acceptance criteria.
> /delegate
```

Isso cria automaticamente:
1. Branch com nome baseado na issue
2. Commits com as mudanças
3. Pull Request linkado à issue

É o único setup onde o agente pode **abrir PR sozinho** — os outros
precisam que você faça isso manualmente.

---

## Referência rápida

```bash
# Rodar o setup interativo
./setup.sh

# Rodar com respostas pré-definidas (CI / padronização)
./setup.sh --answers answers.env

# Ajuda
./setup.sh --help
```

### Variáveis do answers.env

| Variável | Valores | Descrição |
|---|---|---|
| `PROFILE` | `devops`, `appdev`, `tooling`, `custom` | Perfil de trabalho |
| `CLOUDS` | `AWS,Azure,GCP` | Clouds utilizadas |
| `LANGUAGES` | `TypeScript,Python,C#/.NET,Go,Rust,Java` | Linguagens |
| `IAC` | `Terraform`, `CloudFormation`, `Pulumi`, `Nenhum` | Ferramenta de IaC |
| `USE_K8S` | `Sim`, `Não` | Usa Kubernetes |
| `CICD` | `GitHub Actions`, `Azure Pipelines`, `GitLab CI` | CI/CD |
| `DBS` | `PostgreSQL,MySQL,MongoDB,Redis,SQLite` | Bancos de dados |
| `FRONTEND` | `React`, `Next.js`, `Vue`, `Angular`, `Svelte` | Frontend |
| `USE_DOCKER` | `Sim`, `Não` | Usar Docker |
| `AGENTS` | `architect,developer,devops-engineer,reviewer,tester` | Agentes |

---

## Boas práticas

1. **Sempre `/init`** ao começar sessão num repo — carrega as instruções
2. **Prefira `/add-dir`** sobre `/allow-all` — princípio do menor privilégio
3. **Use `@arquivo`** para dar contexto preciso — evita alucinação
4. **Leia os agents antes** — diga ao Copilot qual papel assumir
5. **Leia as skills** — diga ao Copilot para ler a skill relevante
6. **`/review` antes de PR** — pega problemas que você não viu
7. **`/delegate` para tarefas bem definidas** — issues com acceptance criteria claros
8. **`! comando`** para validar — não confie cegamente, execute testes
9. **Não execute scripts desconhecidos** sem revisar — mesma regra de sempre
10. **Skills** carregam contexto sob demanda — são o manual do agente

---

## Demo

O script `demo.sh` mostra os comandos de exemplo sem executar o CLI:

```bash
./demo.sh
```

## Referências

- [Documentação oficial do Copilot CLI](https://docs.github.com/copilot)
- [GitHub CLI + Copilot](https://cli.github.com/manual/gh_copilot)
