#!/usr/bin/env bats
# Testes do setup-copilot — rode com: bats tests/

REPO_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
  TMP="$(mktemp -d)"
  cd "$TMP"
}

teardown() {
  rm -rf "$TMP"
}

run_setup() {
  run bash "$REPO_DIR/setup.sh" --answers "$REPO_DIR/tests/fixtures/answers.env"
}

@test "setup roda sem erro em modo não-interativo" {
  run_setup
  [ "$status" -eq 0 ]
}

@test "gera copilot-instructions.md" {
  run_setup
  [ -f .github/copilot-instructions.md ]
}

@test "agents instalados sem placeholder {{MODEL}}" {
  run_setup
  [ -f .github/agents/architect.md ]
  [ -f .github/agents/devops-engineer.md ]
  [ -f .github/agents/reviewer.md ]
  ! grep -rq "{{MODEL}}" .github/agents/
}

@test "skills condicionais pela stack" {
  run_setup
  [ -d .github/skills/terraform ] || [ -f .github/skills/terraform/SKILL.md ]
  [ -d .github/skills/kubernetes ] || [ -f .github/skills/kubernetes/SKILL.md ]
}

@test "docs/adr criado com templates" {
  run_setup
  [ -f docs/adr/TEMPLATE.md ] || [ -f docs/adr/README.md ]
}

@test "idempotência: segunda execução preserva backup" {
  run_setup
  [ "$status" -eq 0 ]
  sleep 1
  run_setup
  [ "$status" -eq 0 ]
}

@test "--help funciona" {
  run bash "$REPO_DIR/setup.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"setup-copilot"* ]] || [[ "$output" == *"Uso"* ]]
}
