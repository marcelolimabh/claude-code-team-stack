# claude-code-team-stack

**Um kit inicial, enxuto e opinativo, para padronizar o Claude Code em um time de
desenvolvimento:** plugins revisados, guardrails de segurança e scripts de setup para
projetos Java/Spring Boot e Node/TypeScript/React/Next.js.

🇺🇸 [Read in English](README.md)

> Projeto comunitário não oficial, sem vínculo com a Anthropic.
> Nomes e comportamento dos plugins mudam com frequência: este kit foi montado em novembro de 2026.
> Veja o [CHANGELOG.md](CHANGELOG.md) para o que mudou desde então.

## Por quê

Quando um time adota o Claude Code, cada dev tende a configurar do seu jeito: um instala dez
plugins, outro nenhum, um terceiro pega uma skill de um repositório qualquer. Este kit dá ao time
uma configuração única, versionada em cada repositório e alterada só via PR.

Princípios:

- **Menos é mais.** Cada plugin ativo consome contexto em toda conversa. Só entra o que dá para justificar.
- **Oficial primeiro.** Quase tudo vem do marketplace oficial da Anthropic (`claude-plugins-official`).
- **Local primeiro.** Ferramentas que rodam na máquina do dev vêm antes de serviços que enviam código para fora.
- **Tudo versionado.** A configuração fica em `.claude/settings.json`; mudar a stack é um PR.

## O que tem aqui

```
templates/
  java-spring/.claude/settings.json       # projetos Java / Spring Boot
  node-react-next/.claude/settings.json   # projetos Node / TypeScript / React / Next.js
scripts/
  setup-claude-stack.sh                   # macOS, Linux, WSL2
  setup-claude-stack-windows.ps1          # Windows (WSL2 ou nativo sem LSP)
```

### Plugins (todos gratuitos)

| Plugin | Para quê | Java | Node/Front |
|---|---|:-:|:-:|
| `jdtls-lsp` | Claude vê erros de compilação Java logo após cada edição | ✅ | |
| `typescript-lsp` | O mesmo para TS/JS | | ✅ |
| `superpowers` | Fluxo disciplinado: brainstorm → plano → TDD → review → verificação | ✅ | ✅ |
| `code-review`, `pr-review-toolkit` | Review de código e de PR com subagentes em paralelo | ✅ | ✅ |
| `security-guidance` | Claude revisa vulnerabilidades no próprio código enquanto escreve | ✅ | ✅ |
| `commit-commands` | Commit / push / PR em um comando | ✅ | ✅ |
| `github` | Contexto de issues e PRs | ✅ | ✅ |
| `context7` | Documentação atualizada das libs (plano free, exige conta) | ✅ | ✅ |
| `frontend-design`, `playwright` | UI de qualidade e teste no browser | | ✅ |

### Guardrails (`permissions` no settings.json)

- **deny:** leitura de `.env`, chaves, keystores (`*.pem`, `*.key`, `*.jks`, `*.p12`), `secrets/`,
  configs de produção (`application-prod*`, `.env.production`); `git push --force`; `rm -rf`.
- **ask:** `git push`, `git reset`, `gh pr merge`, instalação de pacotes npm.
- **allow:** build, testes e lint (`mvnw`, `gradlew`, `npm test`, `eslint`...) e git somente leitura.

## Como adotar em um repositório (tech lead, uma vez)

1. Copie o template correspondente para a raiz do repo como `.claude/settings.json`.
   Monorepo com as duas stacks? Junte os `enabledPlugins` e as `permissions` dos dois templates.
2. Ajuste `permissions` aos comandos do projeto (yarn, pnpm, make...).
3. Faça commit do `.claude/settings.json`. Nunca versione o `.claude/settings.local.json` (é pessoal).

## Como configurar cada máquina (cada dev, uma vez)

### macOS / Linux
```bash
cd ~/dev/<repo>
bash /caminho/para/claude-code-team-stack/scripts/setup-claude-stack.sh
```
Pré-requisitos: Claude Code, git, Python 3.9+, Node LTS (projetos TS). Em projetos Java, o macOS
usa o Homebrew para instalar o jdtls e recorre ao download direto (exige JDK 21+) quando o Homebrew não
existe ou falha, como em Macs Intel; o Linux precisa de JDK 21+ (o jdtls precisa dele para rodar; o projeto pode continuar em 17).

### Windows
**Recomendado: rodar o Claude Code dentro do WSL2.** No Windows nativo os plugins de LSP ainda
falham ao iniciar o servidor de linguagem (veja [Problemas conhecidos](#problemas-conhecidos)); o resto funciona.
```powershell
.\scripts\setup-claude-stack-windows.ps1          # verifica/instala o WSL2 e mostra os próximos passos
.\scripts\setup-claude-stack-windows.ps1 -Native  # Windows nativo, sem os plugins de LSP
```
No WSL, clone os repos em `~/dev` (não em `/mnt/c`) e rode o `setup-claude-stack.sh`.

### Conferindo
Abra o Claude Code no repo, confie na pasta e rode `/plugin`. Os plugins do projeto devem aparecer ativos.

## Regras de time que recomendamos

- **Plugin novo só via PR** na sua cópia deste kit, depois de alguém ler o `SKILL.md`, os hooks e
  o código do plugin. Skills de terceiros rodam com os seus privilégios.
- **Não remova as regras `deny` de segredos.**
- **Código sensível / setores regulados:** não conecte serviços externos (review de código em
  SaaS, SCA na nuvem, indexação de repos privados) sem aprovação de segurança/compliance.
- Quer desligar um plugin só para você? Use `.claude/settings.local.json`:
  ```json
  { "enabledPlugins": { "superpowers@claude-plugins-official": false } }
  ```
- Mantenha o Claude Code atualizado (`claude update`).

## Complementos pagos (opcional)

Dá para ir longe sem gastar nada. Se quiser investir, uma ordem razoável:

1. Plugin do **SonarQube** (marketplace oficial): quality gate, duplicação, complexidade, SAST e
   segredos também no código gerado pelo Claude.
2. Planos pagos do **Snyk** (dependências vulneráveis) ou do **Semgrep**.
3. **CodeRabbit** ou **Claude Code Review** (Team/Enterprise) para review de PR. Escolha um, não os dois.

Os itens 2 e 3 enviam código para serviços externos: peça aprovação antes se o código for sensível.

## Problemas conhecidos

- **Plugins de LSP no Windows nativo** não conseguem iniciar o servidor de linguagem
  ([#37897](https://claudeissues.com/issue/37897-lsp-plugins-fail-on-windows-spawn-enoent-for-npm-global-shim-scripts),
  [#78188](https://claudeissues.com/issue/78188-bug-jdtls-lsp-plugin-lsp-tool-fails-with-command-jdtls-not-found-or-is-in-an-uns)).
  Contorno: WSL2.
- **`enabledPlugins` no projeto pode não pedir instalação** aos colegas para plugins do marketplace oficial
  ([#41669](https://claudeissues.com/issue/41669-project-level-enabledplugins-should-auto-install-or-prompt-to-install-plugins-fr)).
  Contorno: os scripts de setup instalam o que o `settings.json` listar.
- **O `claude plugin install --scope project` pode reescrever o `.claude/settings.json`** com as chaves em
  outra ordem. O conteúdo é o mesmo; descarte a mudança com `git checkout .claude/settings.json`.

## Referências

- [Claude Code docs: plugins para organizações](https://code.claude.com/docs/pt/plugins/org)
- [Claude Code docs: plugins de code intelligence (LSP)](https://code.claude.com/docs/en/plugins/code-intelligence)
- [Claude Code docs: security guidance](https://code.claude.com/docs/en/security-guidance)
- [Cloud Security Alliance: Agent Context Poisoning (SKILL.md)](https://labs.cloudsecurityalliance.org/research/briefing-csa-research-note-skill-md-agent-context-poisoning/)

## Contribuindo

Issues e PRs são bem-vindos, principalmente relatos de teste no Windows/WSL e no Linux e templates
para outras stacks. Veja [CONTRIBUTING.md](CONTRIBUTING.md) e [SECURITY.md](SECURITY.md).

## Licença

[MIT](LICENSE)
