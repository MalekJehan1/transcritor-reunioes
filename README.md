# transcritor — plugin do Claude Code

Transcreve gravações de reunião **localmente** (faster-whisper, o áudio não sai da máquina) e
gera um resumo estruturado: atualizações por pessoa, decisões, pendências e riscos. Aprende o
vocabulário da sua empresa — nomes, produtos, clientes, jargões — para errar menos a cada
reunião.

Não traz conector nenhum. Se você já tiver Confluence, Notion, Jira etc. conectados no Claude,
ele pode publicar o resumo e cruzar com os cards. Se não tiver, entrega um `.md`.

## Instalar

```bash
claude plugin marketplace add Rodrigobarb/transcritor-reunioes
```

```bash
claude plugin install transcritor@transcritor-reunioes
```

Depois, dentro do Claude Code:

```
/transcritor:configurar
```

O comando pergunta sobre a empresa, o time, quem participa das reuniões, onde guardar os
resumos e se você quer conectar com alguma ferramenta. Dá para rodar de novo a qualquer momento.

## Usar

Mande o áudio ou o vídeo e peça o resumo ("resume a daily de hoje", "ata dessa call"). O fluxo:

1. **Transcreve** em segundo plano (~2× tempo real em CPU com o modelo `medium`).
2. **Mapeia quem falou o quê** e pergunta só o que ficou em dúvida.
3. **Cruza com o rastreador** (Jira, Linear…), se estiver conectado.
4. **Escreve o resumo** no modelo do tipo de reunião (daily, retro, call com cliente, geral).
5. **Mostra para revisão** e só publica depois do seu OK.

## Requisitos

- Linux, macOS ou Windows, com Python 3.9+ (e `curl` no Linux/macOS). No Windows os scripts
  rodam no Git Bash, que é o shell do Claude Code ali, e aceitam `python`, `python3` ou `py`.
- ~2 GB livres: o ambiente Python fica em `~/.cache/transcritor/venv` e o modelo no cache do
  Hugging Face. A primeira transcrição baixa tudo isso; as seguintes começam na hora.

## Configuração

| Escopo | Pasta | Quando usar |
|---|---|---|
| Global | `~/.config/transcritor/` | o seu padrão |
| Projeto | `./.transcritor/` | um time ou cliente com vocabulário próprio; vence a global |

Cada pasta tem `config.json` (campos em
[`references/configuracao.md`](skills/resumo-reuniao/references/configuracao.md)) e
`glossario.md`, que cresce conforme você corrige os resumos.

## Estrutura

```
.claude-plugin/          plugin.json + marketplace.json
commands/configurar.md   /transcritor:configurar
skills/resumo-reuniao/
  SKILL.md               o fluxo de cinco fases
  scripts/               preparar_ambiente.sh, iniciar.sh, config.sh, transcrever.py
  assets/modelos/        daily, retro, cliente, geral
  references/            configuracao.md, integracoes.md
```
