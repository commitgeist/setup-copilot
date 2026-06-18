#!/usr/bin/env bash
# setup-copilot — Wizard de setup do GitHub Copilot CLI
# Versão: 1.0.0
# Uso:  bash setup.sh [--answers FILE] [-h|--help]
set -euo pipefail

VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"

# ── Requisitos ────────────────────────────────────────────────────────────────
if [[ "${BASH_VERSINFO[0]}" -lt 4 ]] || { [[ "${BASH_VERSINFO[0]}" -eq 4 ]] && [[ "${BASH_VERSINFO[1]}" -lt 3 ]]; }; then
  echo "ERRO: Bash 4.3+ necessário (namerefs). Versão atual: ${BASH_VERSION}" >&2
  [[ "$(uname)" == "Darwin" ]] && echo "Dica: brew install bash" >&2
  exit 1
fi
command -v jq >/dev/null 2>&1 || { echo "ERRO: 'jq' é necessário. Instale com: sudo apt install jq / brew install jq" >&2; exit 1; }
[[ -d "${TEMPLATES_DIR}" ]] || { echo "ERRO: Diretório templates/ não encontrado em ${SCRIPT_DIR}" >&2; exit 1; }

# ── Cores ─────────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
  BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
else
  RED=''; GREEN=''; CYAN=''; YELLOW=''; BOLD=''; DIM=''; NC=''
fi

# ── Logging ───────────────────────────────────────────────────────────────────
info()  { echo -e "${CYAN}[setup]${NC} $*" >&2; }
ok()    { echo -e "${GREEN}[ok]${NC} $*" >&2; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*" >&2; }
err()   { echo -e "${RED}[err]${NC} $*" >&2; }

# ── Argumentos ────────────────────────────────────────────────────────────────
ANSWERS_FILE=""
NONINTERACTIVE=false

usage() {
  cat >&2 <<EOF
${BOLD}setup-copilot${NC} v${VERSION}
Wizard de configuração do GitHub Copilot CLI para projetos.

${BOLD}Uso:${NC}
  bash setup.sh                    # Modo interativo (wizard)
  bash setup.sh --answers FILE     # Modo não-interativo
  bash setup.sh -h | --help        # Ajuda

${BOLD}Opções:${NC}
  --answers FILE   Arquivo com respostas pré-definidas (shell-sourceable)
  -h, --help       Mostra esta ajuda

${BOLD}O que é gerado:${NC}
  .github/copilot-instructions.md  Instruções do projeto
  .github/agents/*.md              Agentes com guardrails
  .github/skills/*.md              Skills por área
  docs/adr/                        Diretório para ADRs
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --answers)
      [[ -z "${2:-}" ]] && { err "Faltou o caminho do arquivo após --answers"; exit 1; }
      ANSWERS_FILE="$2"; NONINTERACTIVE=true; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      err "Opção desconhecida: $1"; usage; exit 1 ;;
  esac
done

if [[ "$NONINTERACTIVE" == true ]]; then
  [[ -f "$ANSWERS_FILE" ]] || { err "Arquivo de respostas não encontrado: $ANSWERS_FILE"; exit 1; }
  # shellcheck disable=SC1090
  source "$ANSWERS_FILE"
fi

# ── Helpers de prompt ─────────────────────────────────────────────────────────
ask() {
  local var="$1" prompt="$2" default="${3:-}"
  if [[ "$NONINTERACTIVE" == true ]]; then
    [[ -z "${!var:-}" ]] && declare -g "$var"="$default"
    return
  fi
  local input
  if [[ -n "$default" ]]; then
    read -r -p "$(echo -e "${CYAN}?${NC} ${prompt} [${DIM}${default}${NC}]: ")" input >&2
    declare -g "$var"="${input:-$default}"
  else
    read -r -p "$(echo -e "${CYAN}?${NC} ${prompt}: ")" input >&2
    declare -g "$var"="$input"
  fi
}

pick() {
  local var="$1" prompt="$2" options_csv="$3"
  IFS=',' read -ra options <<< "$options_csv"
  if [[ "$NONINTERACTIVE" == true ]]; then
    [[ -z "${!var:-}" ]] && declare -g "$var"="${options[0]}"
    return
  fi
  echo -e "\n${CYAN}?${NC} ${prompt}" >&2
  local i=1
  for opt in "${options[@]}"; do
    echo -e "  ${BOLD}${i})${NC} ${opt}" >&2
    ((i++))
  done
  local choice
  read -r -p "$(echo -e "${CYAN}→${NC} Escolha [1]: ")" choice >&2
  choice="${choice:-1}"
  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
    declare -g "$var"="${options[$((choice-1))]}"
  else
    declare -g "$var"="${options[0]}"
  fi
}

multiselect() {
  local var="$1" prompt="$2" options_csv="$3" out_var="$4"
  local -n __ms_out="$out_var"
  IFS=',' read -ra options <<< "$options_csv"

  if [[ "$NONINTERACTIVE" == true ]]; then
    local val="${!var:-}"
    if [[ -n "$val" ]]; then
      IFS=',' read -ra __ms_out <<< "$val"
    else
      __ms_out=("${options[@]}")
    fi
    return
  fi

  echo -e "\n${CYAN}?${NC} ${prompt} ${DIM}(números separados por vírgula)${NC}" >&2
  local i=1
  for opt in "${options[@]}"; do
    echo -e "  ${BOLD}${i})${NC} ${opt}" >&2
    ((i++))
  done
  local choices
  read -r -p "$(echo -e "${CYAN}→${NC} Escolha [todos]: ")" choices >&2
  if [[ -z "$choices" ]]; then
    __ms_out=("${options[@]}")
  else
    __ms_out=()
    IFS=',' read -ra nums <<< "$choices"
    for n in "${nums[@]}"; do
      n="$(echo "$n" | tr -d ' ')"
      if [[ "$n" =~ ^[0-9]+$ ]] && (( n >= 1 && n <= ${#options[@]} )); then
        __ms_out+=("${options[$((n-1))]}")
      fi
    done
  fi
  declare -g "$var"="$(IFS=','; echo "${__ms_out[*]}")"
}

# ── Utilidades ────────────────────────────────────────────────────────────────
has() { local needle="$1"; shift; for item in "$@"; do [[ "$item" == "$needle" ]] && return 0; done; return 1; }

backup_if_exists() {
  local f="$1"
  if [[ -e "$f" ]]; then
    local bak="${f}.bak.$(date +%Y%m%d%H%M%S)"
    cp -a "$f" "$bak"
    warn "Backup: ${f} → ${bak}"
  fi
}

install_template() {
  local src="$1" dest="$2"
  local dest_dir; dest_dir="$(dirname "$dest")"
  mkdir -p "$dest_dir"
  backup_if_exists "$dest"
  cp -a "$src" "$dest"
}

# ═══════════════════════════════════════════════════════════════════════════════
# WIZARD
# ═══════════════════════════════════════════════════════════════════════════════
echo -e "\n${BOLD}╔══════════════════════════════════════════════╗${NC}" >&2
echo -e "${BOLD}║   🐙 setup-copilot v${VERSION}                 ║${NC}" >&2
echo -e "${BOLD}║   Configuração do GitHub Copilot CLI         ║${NC}" >&2
echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}\n" >&2

# ── Step 1: Perfil ────────────────────────────────────────────────────────────
info "Step 1/8 — Perfil"
pick PROFILE "Qual o seu perfil de trabalho?" "devops,appdev,tooling,custom"

# ── Step 2: Stack (dinâmico por perfil) ───────────────────────────────────────
info "Step 2/8 — Stack"

declare -a CLOUDS_ARR=() LANGUAGES_ARR=() DBS_ARR=()
CICD="" IAC="" USE_K8S="" FRONTEND="" BACKEND_FRAMEWORK="" USE_DOCKER="" VCS=""

case "$PROFILE" in
  devops)
    multiselect CLOUDS "Clouds utilizadas" "AWS,Azure,GCP" CLOUDS_ARR
    pick IAC "Ferramenta de IaC" "Terraform,CloudFormation,Pulumi,Nenhum"
    pick USE_K8S "Usa Kubernetes?" "Sim,Não"
    pick CICD "CI/CD" "GitHub Actions,Azure Pipelines,GitLab CI,Nenhum"
    multiselect DBS "Bancos de dados" "PostgreSQL,MySQL,MongoDB,Redis,Nenhum" DBS_ARR
    ;;
  appdev)
    multiselect LANGUAGES "Linguagens" "TypeScript,Python,C#/.NET,Go,Rust,Java" LANGUAGES_ARR

    if has "TypeScript" "${LANGUAGES_ARR[@]:-}"; then
      pick BACKEND_FRAMEWORK "Framework Node.js" "Express,Fastify,NestJS,Hono,Nenhum"
    elif has "Python" "${LANGUAGES_ARR[@]:-}"; then
      pick BACKEND_FRAMEWORK "Framework Python" "FastAPI,Django,Flask,Nenhum"
    elif has "C#/.NET" "${LANGUAGES_ARR[@]:-}"; then
      pick BACKEND_FRAMEWORK "Framework .NET" "Minimal API,ASP.NET MVC,Nenhum"
    elif has "Go" "${LANGUAGES_ARR[@]:-}"; then
      pick BACKEND_FRAMEWORK "Framework Go" "Gin,Echo,Chi,stdlib,Nenhum"
    fi

    pick FRONTEND "Frontend" "React,Next.js,Vue,Angular,Svelte,Nenhum"
    multiselect DBS "Bancos de dados" "PostgreSQL,MySQL,MongoDB,Redis,SQLite,Nenhum" DBS_ARR
    pick USE_DOCKER "Usar Docker?" "Sim,Não"
    ;;
  tooling)
    multiselect LANGUAGES "Linguagens" "Python,Go,TypeScript" LANGUAGES_ARR
    multiselect CLOUDS "Cloud APIs" "AWS,Azure,GCP,Nenhum" CLOUDS_ARR
    pick USE_K8S "Interage com Kubernetes?" "Sim,Não"
    pick USE_DOCKER "Usar Docker?" "Sim,Não"
    ;;
  custom)
    multiselect CLOUDS "Clouds" "AWS,Azure,GCP,Nenhum" CLOUDS_ARR
    multiselect LANGUAGES "Linguagens" "TypeScript,Python,C#/.NET,Go,Rust,Java" LANGUAGES_ARR
    pick IAC "IaC" "Terraform,CloudFormation,Pulumi,Nenhum"
    pick USE_K8S "Kubernetes?" "Sim,Não"
    pick CICD "CI/CD" "GitHub Actions,Azure Pipelines,GitLab CI,Nenhum"
    pick FRONTEND "Frontend" "React,Next.js,Vue,Angular,Svelte,Nenhum"
    multiselect DBS "Bancos de dados" "PostgreSQL,MySQL,MongoDB,Redis,SQLite,Nenhum" DBS_ARR
    pick USE_DOCKER "Docker?" "Sim,Não"
    ;;
esac

# ── Step 3: Agents ────────────────────────────────────────────────────────────
info "Step 3/8 — Agents"

declare -a AGENTS_ARR=()
case "$PROFILE" in
  devops)
    multiselect AGENTS "Agents a instalar" "architect,devops-engineer,reviewer" AGENTS_ARR
    ;;
  appdev|tooling)
    multiselect AGENTS "Agents a instalar" "architect,developer,reviewer,tester" AGENTS_ARR
    ;;
  custom)
    multiselect AGENTS "Agents a instalar" "architect,developer,devops-engineer,reviewer,tester" AGENTS_ARR
    ;;
esac

# ── Step 4: Instalar Agents ──────────────────────────────────────────────────
info "Step 4/8 — Instalando agents"
AGENTS_DIR=".github/agents"
mkdir -p "$AGENTS_DIR"

for agent in "${AGENTS_ARR[@]}"; do
  local_tpl="${TEMPLATES_DIR}/agents/${agent}.md.tpl"
  if [[ -f "$local_tpl" ]]; then
    dest="${AGENTS_DIR}/${agent}.md"
    install_template "$local_tpl" "$dest"
    ok "Agent: ${agent}"
  else
    warn "Template não encontrado: ${agent}.md.tpl"
  fi
done

# ── Step 5: Instalar Skills ──────────────────────────────────────────────────
info "Step 5/8 — Instalando skills"
SKILLS_DIR=".github/skills"
mkdir -p "$SKILLS_DIR"
INSTALLED_SKILLS=()

install_skill() {
  local name="$1"
  local src="${TEMPLATES_DIR}/skills/${name}"
  if [[ -d "$src" ]]; then
    local dest="${SKILLS_DIR}/${name}"
    mkdir -p "$dest"
    cp -a "$src/." "$dest/"
    INSTALLED_SKILLS+=("$name")
    ok "Skill: ${name}"
  else
    warn "Skill não encontrada: ${name}"
  fi
}

# Skills condicionais por stack
# Infra
has "AWS"              "${CLOUDS_ARR[@]:-}" && install_skill "aws-infra"
has "Azure"            "${CLOUDS_ARR[@]:-}" && install_skill "azure-infra"
[[ "${IAC:-}" == "Terraform" ]]             && install_skill "terraform"
[[ "${USE_K8S:-}" == "Sim" ]]               && install_skill "kubernetes"
[[ "${CICD:-}" == "GitHub Actions" ]]       && install_skill "github-actions"
[[ "${CICD:-}" == "Azure Pipelines" ]]      && install_skill "azure-pipelines"
has "PostgreSQL"       "${DBS_ARR[@]:-}"    && install_skill "postgres"

# Dev
has "TypeScript"       "${LANGUAGES_ARR[@]:-}" && install_skill "typescript"
has "Python"           "${LANGUAGES_ARR[@]:-}" && install_skill "python"
has "C#/.NET"          "${LANGUAGES_ARR[@]:-}" && install_skill "dotnet"
has "Go"              "${LANGUAGES_ARR[@]:-}" && install_skill "golang"
[[ "${FRONTEND:-}" == "React" ]]               && install_skill "react"
[[ "${FRONTEND:-}" == "Next.js" ]]             && install_skill "nextjs"

# Docker
[[ "${USE_DOCKER:-}" == "Sim" ]] && install_skill "docker"

# Sempre instaladas
install_skill "testing"
install_skill "git-workflow"

# ── Step 6: Docs/ADR ─────────────────────────────────────────────────────────
info "Step 6/8 — Documentação"
mkdir -p docs/adr
if [[ -f "${TEMPLATES_DIR}/docs/adr/TEMPLATE.md" ]]; then
  install_template "${TEMPLATES_DIR}/docs/adr/TEMPLATE.md" "docs/adr/TEMPLATE.md"
fi
if [[ -f "${TEMPLATES_DIR}/docs/adr/README.md" ]]; then
  install_template "${TEMPLATES_DIR}/docs/adr/README.md" "docs/adr/README.md"
fi
ok "docs/adr/ criado"

# ── Step 7: Gerar copilot-instructions.md ────────────────────────────────────
info "Step 7/8 — Gerando copilot-instructions.md"
INSTRUCTIONS_FILE=".github/copilot-instructions.md"
mkdir -p .github
backup_if_exists "$INSTRUCTIONS_FILE"

{
  echo "# Instruções do Projeto — GitHub Copilot"
  echo ""
  echo "> Gerado por setup-copilot v${VERSION} em $(date -Iseconds)"
  echo "> Carregado automaticamente pelo Copilot CLI via \`/init\`"
  echo ""

  # Agents
  echo "## Agents Disponíveis"
  echo ""
  for agent in "${AGENTS_ARR[@]}"; do
    case "$agent" in
      architect)        echo "- **@architect** — Planeja e projeta soluções. Nunca implementa diretamente." ;;
      developer)        echo "- **@developer** — Implementa features, APIs e serviços." ;;
      devops-engineer)  echo "- **@devops-engineer** — Gerencia infra, CI/CD e deploys." ;;
      reviewer)         echo "- **@reviewer** — Revisa código (read-only). Roda linters e testes." ;;
      tester)           echo "- **@tester** — Escreve apenas arquivos de teste." ;;
    esac
  done
  echo ""

  # Stack
  echo "## Stack"
  echo ""
  echo "- **Perfil**: ${PROFILE}"
  [[ -n "${CLOUDS:-}" ]]             && echo "- **Clouds**: ${CLOUDS}"
  [[ -n "${LANGUAGES:-}" ]]          && echo "- **Linguagens**: ${LANGUAGES}"
  [[ -n "${BACKEND_FRAMEWORK:-}" && "${BACKEND_FRAMEWORK}" != "Nenhum" ]] && echo "- **Framework**: ${BACKEND_FRAMEWORK}"
  [[ -n "${FRONTEND:-}" && "${FRONTEND}" != "Nenhum" ]]                   && echo "- **Frontend**: ${FRONTEND}"
  [[ -n "${IAC:-}" && "${IAC}" != "Nenhum" ]]     && echo "- **IaC**: ${IAC}"
  [[ -n "${USE_K8S:-}" ]]            && echo "- **Kubernetes**: ${USE_K8S}"
  [[ -n "${CICD:-}" && "${CICD}" != "Nenhum" ]]   && echo "- **CI/CD**: ${CICD}"
  [[ -n "${DBS:-}" ]]                && echo "- **Bancos**: ${DBS}"
  [[ -n "${USE_DOCKER:-}" ]]         && echo "- **Docker**: ${USE_DOCKER}"
  echo ""

  # Skills
  echo "## Skills Instaladas"
  echo ""
  echo "Skills ficam em \`.github/skills/\` — cada uma é um pacote de instruções"
  echo "que dá contexto especializado ao agente para uma área específica."
  echo ""
  for skill in "${INSTALLED_SKILLS[@]}"; do
    echo "- \`${skill}\` → .github/skills/${skill}/"
  done
  echo ""

  # Regras
  echo "## Regras do Projeto"
  echo ""
  echo "1. **ADR antes de implementar** — Mudanças complexas passam pelo architect primeiro"
  echo "2. **Código = Teste** — Toda feature deve ter testes correspondentes"
  echo "3. **Valide antes de commitar** — Rode linters/testes antes de abrir PR"
  echo "4. **Secrets** — NUNCA hardcode. Use variáveis de ambiente ou secret managers"
  echo "5. **Conventional Commits** — feat:, fix:, docs:, chore:, refactor:, test:, ci:"
  echo "6. **PRs pequenos** — Máximo ~300 linhas. Mudanças grandes passam pelo architect primeiro"
  echo "7. **Não afirme estado sem verificar** — Sempre confirme com ferramentas antes de afirmar"
  echo "8. **Não invente flags/opções de CLI** — Consulte --help ou documentação"
  echo ""

  # Workflow
  echo "## Workflow"
  echo ""
  echo "### Mudança complexa"
  echo "1. architect → ADR em docs/adr/ → aprovação humana → developer/devops-engineer → reviewer → PR"
  echo ""
  echo "### Mudança simples"
  echo "1. developer (com plano) → reviewer → PR"
  echo ""
  echo "### Troubleshooting"
  echo "1. Diagnóstico → propõe fix → tester valida → PR"
  echo ""

  # Permissões
  echo "## Permissões dos Agents"
  echo ""
  echo "| Agent | Escrever arquivos | Executar comandos | Destruir recursos |"
  echo "|---|---|---|---|"
  for agent in "${AGENTS_ARR[@]}"; do
    case "$agent" in
      architect)        echo "| architect | Só docs/adr/, docs/design/ | ❌ Bloqueado | ❌ |" ;;
      developer)        echo "| developer | ✅ Tudo | ✅ | ❌ deny destrutivos |" ;;
      devops-engineer)  echo "| devops-engineer | ✅ Tudo | ✅ (apply=ask) | ❌ deny |" ;;
      reviewer)         echo "| reviewer | ❌ Bloqueado | 🔍 Só leitura | ❌ |" ;;
      tester)           echo "| tester | Só arquivos de teste | ✅ (testes) | ❌ |" ;;
    esac
  done
  echo ""

} > "$INSTRUCTIONS_FILE"

ok "copilot-instructions.md gerado"

# ── Step 8: Resumo ───────────────────────────────────────────────────────────
info "Step 8/8 — Resumo"

echo "" >&2
echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}" >&2
echo -e "${BOLD}║   ✅ Setup concluído com sucesso!            ║${NC}" >&2
echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}" >&2
echo "" >&2
echo -e "  ${BOLD}Perfil:${NC}       ${PROFILE}" >&2
echo -e "  ${BOLD}Agents:${NC}       ${AGENTS}" >&2
echo -e "  ${BOLD}Skills:${NC}       $(IFS=','; echo "${INSTALLED_SKILLS[*]}")" >&2
echo -e "  ${BOLD}Instruções:${NC}   ${INSTRUCTIONS_FILE}" >&2
echo -e "  ${BOLD}Agents dir:${NC}   ${AGENTS_DIR}/" >&2
echo -e "  ${BOLD}Skills dir:${NC}   ${SKILLS_DIR}/" >&2
echo "" >&2
echo -e "  ${CYAN}Próximos passos:${NC}" >&2
echo -e "    1. Abra o Copilot CLI: ${BOLD}copilot${NC} (ou ${BOLD}gh copilot${NC})" >&2
echo -e "    2. Rode ${BOLD}/init${NC} para carregar as instruções" >&2
echo -e "    3. Comece com: ${BOLD}Planeje <sua mudança>${NC}" >&2
echo "" >&2
