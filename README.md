# setup-copilot

> **Ferramenta**: [GitHub Copilot CLI](https://docs.github.com/copilot) — terminal de IA agêntico do GitHub.

Guia prático e demo do GitHub Copilot CLI para times de desenvolvimento.
Referência rápida de comandos, workflow com agentes e exemplos reais.

## Qual setup usar?

| Aspecto | setup-opencode | setup-opencode-dev | setup-opencode-devtools | setup-antigravity | **setup-copilot** |
|---|---|---|---|---|---|
| **Motor** | OpenCode | OpenCode | OpenCode | Gemini CLI | **GitHub Copilot CLI** |
| **Persona** | DevOps/SRE | Dev apps | Dev ferramentas | Multi-perfil | **Dev geral** |
| **Modelo** | Multi-provider | Multi-provider | Multi-provider | Gemini (Google) | **GPT-4o / Claude (GitHub)** |
| **Autenticação** | API Key por provider | API Key | API Key | API Key / OAuth / Vertex | **GitHub login** |
| **Config** | opencode.json | opencode.json | opencode.json | settings.json | **copilot-instructions.md** |

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

> Este repo **não é o Copilot CLI** — é um guia prático com exemplos e demo script.

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

# 3. Autenticar
copilot /login
# ou: gh auth login --scopes copilot
```

### 1. Primeiro uso

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

### 2. Comandos essenciais

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

### 3. Workflow recomendado

O Copilot CLI funciona bem com o mesmo fluxo ADR dos outros setups:

```
┌───────────────┐     ┌──────────┐     ┌──────────────────┐     ┌──────────┐
│   Copilot     │────▶│  HUMANO  │────▶│   Copilot        │────▶│ /review  │
│  planeja      │     │ revisa e │     │  implementa      │     │ valida   │
│  (chat)       │     │ aprova   │     │  (/delegate)     │     │          │
└───────────────┘     └──────────┘     └──────────────────┘     └──────────┘
```

1. **Planejar** no chat — pedir análise e plano
2. **Você** revisa o plano
3. **`/delegate`** ou implementação manual — Copilot executa
4. **`/review`** valida o resultado
5. **Você** abre (ou o `/delegate` já abriu) o PR

### 4. Como usar na vida real

#### Exemplo 1: Revisar mudanças antes de commitar

```bash
copilot
```

```
> /diff
> Revise as mudanças e me diga se tem algum problema de segurança
```

#### Exemplo 2: Implementar uma issue via delegate

```bash
copilot
```

```
> #42 implemente essa feature
> /delegate
```

O Copilot cria branch, implementa, commita e abre PR — tudo automaticamente.

#### Exemplo 3: Code review em PR aberto

```bash
copilot
```

```
> /pr
> /review
> Foque em: segurança, performance e cobertura de testes
```

#### Exemplo 4: Explorar codebase desconhecido

```bash
cd ~/projetos/repo-novo
copilot
```

```
> /init
> Me dê um overview da arquitetura deste projeto
> @README.md @package.json quais são as dependências principais?
> ! find src -name "*.ts" | head -20
> Quais são os padrões de código usados aqui?
```

#### Exemplo 5: Troubleshooting rápido

```bash
copilot
```

```
> ! npm test 2>&1 | tail -30
> Os testes acima estão falhando. Diagnostique e proponha fix.
> @src/auth/jwt.service.ts o problema parece ser aqui — corrija.
```

### 5. Diferença para os outros setups

| Aspecto | setup-opencode | setup-antigravity | **setup-copilot** |
|---|---|---|---|
| Motor | OpenCode CLI | Gemini CLI | GitHub Copilot CLI |
| Setup wizard | ✅ `setup.sh` com 12+ steps | ✅ `setup.sh` com 12 steps | ❌ Não precisa (já vem integrado) |
| Config gerada | `opencode.json` + `AGENTS.md` | `settings.json` + `GEMINI.md` | `copilot-instructions.md` |
| Modelos | Multi-provider (Anthropic, OpenAI, Ollama) | Gemini (Google) | GPT-4o, Claude (via GitHub) |
| MCPs | Configuráveis | Configuráveis | Integrados (GitHub nativo) |
| PR automation | Manual | Manual | `/delegate` (branch + PR automático) |
| Code review | Via agente `@reviewer` | Via agente `@reviewer` | `/review` nativo |
| Custo | Depende do provider | Depende do tier Google | Copilot Free / Pro / Business |

### 6. Instruções para o repositório

Para que o `/init` carregue contexto do seu projeto, crie um arquivo
de instruções na raiz do repo:

**`copilot-instructions.md`** (ou `.github/copilot-instructions.md`):

```markdown
# Instruções do Projeto

## Stack
- TypeScript, Node.js 20, Express
- PostgreSQL 16, Prisma ORM
- Jest para testes
- Docker Compose para dev local

## Convenções
- Conventional Commits: feat:, fix:, docs:, chore:
- PRs pequenos (max ~300 linhas)
- Todo código novo precisa de testes
- Secrets via variáveis de ambiente (nunca hardcode)

## Estrutura
- src/         — código-fonte
- tests/       — testes
- docs/        — documentação
- infra/       — Terraform / Docker
```

---

## Boas práticas

1. **Sempre `/init`** ao começar sessão num repo — carrega as instruções
2. **Prefira `/add-dir`** sobre `/allow-all` — princípio do menor privilégio
3. **Use `@arquivo`** para dar contexto preciso — evita alucinação
4. **`/review` antes de PR** — pega problemas que você não viu
5. **`/delegate` para tarefas bem definidas** — issues com acceptance criteria claros
6. **`! comando`** para validar — não confie cegamente, execute testes
7. **Não execute scripts desconhecidos** sem revisar — mesma regra de sempre

---

## Demo

O script `demo.sh` mostra os comandos de exemplo sem executar o CLI:

```bash
./demo.sh
```

## Referências

- [Documentação oficial do Copilot CLI](https://docs.github.com/copilot)
- [GitHub CLI + Copilot](https://cli.github.com/manual/gh_copilot)
