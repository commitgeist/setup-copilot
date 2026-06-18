# Guia rápido: GitHub Copilot CLI (Copilot CLI)

Este guia mostra como usar o Copilot CLI (interface interativa) com comandos e exemplos práticos.

Resumo rápido
- Interface interativa baseada em comandos (prefixo `/` para comandos internos).
- `!` executa comandos shell; `@` menciona arquivos; `#` menciona PRs/Issues.
- Atalhos: `ctrl+s` stash/pop prompt, `ctrl+q` enqueue, `ctrl+c` cancelar, `ctrl+c`×2 sair.

Instalação (exemplo macOS/Linux):
# Instalar via pacote recomendado pelo GitHub
# Consulte docs oficiais se necessário

Comandos úteis
- /help — ajuda completa
- /init — inicializa instruções do Copilot para o repositório
- /agent — listar/agendar agentes
- /pr — operar em pull requests
- /review — rodar code-review agent
- /search — procurar na timeline
- /settings — ver/configurar ajustes
- /allow-all, /add-dir, /list-dirs — permissões de acesso a diretórios
- /login, /logout — autenticação

Operações de código e shell
- ! <cmd> — executar comando shell (ex: `! git status`)
- /diff — revisar mudanças no diretório atual
- /delegate — delegar tarefa para criar PR automaticamente

Exemplo rápido de sessão
1. /init
2. /help
3. /agent — escolher um agent (ex: code-review)
4. ! git status
5. /pr — listar PRs abertos
6. /review — rodar revisão em um PR

Boas práticas
- Use `/init` para carregar instruções do repositório (CLAUDE.md, AGENTS.md etc.)
- Evite habilitar permissões amplas sem revisão (`/allow-all`) — prefira `/add-dir`
- Use `!` para comandos rápidos; não execute scripts desconhecidos sem revisão

Referências
- Documentação oficial (resumida): https://docs.github.com/copilot/how-tos/use-copilot-agents/use-copilot-cli

Fim.
