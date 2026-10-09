---
description: Configura o transcritor para a sua empresa — time, nomes, produtos, clientes, destino do resumo e integrações opcionais
argument-hint: "[global|projeto]"
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion, ToolSearch
---

Você vai configurar o plugin **transcritor** para quem está usando agora. A configuração
serve para duas coisas: ensinar ao Whisper os nomes próprios da empresa (é o que mais erra na
transcrição) e dizer à skill `resumo-reuniao` onde entregar o resumo.

O formato dos arquivos está em
`${CLAUDE_PLUGIN_ROOT}/skills/resumo-reuniao/references/configuracao.md` — leia antes de
escrever. Escreva tudo no idioma que o usuário estiver usando.

Mantenha a conversa curta: no máximo três rodadas de perguntas. Tudo é opcional; o que o
usuário pular fica vazio e pode ser preenchido depois rodando este comando de novo.

## 1. Ver o que já existe

```bash
S="${CLAUDE_PLUGIN_ROOT}/skills/resumo-reuniao/scripts"
bash "$S/config.sh" pasta; bash "$S/config.sh" global; bash "$S/config.sh" projeto
```

Se já houver config, leia e mostre um resumo de uma linha por campo, e pergunte o que quer
mudar em vez de refazer o questionário inteiro.

## 2. Escolhas rápidas (uma chamada de AskUserQuestion)

Faça estas perguntas juntas. Pule a de escopo se `$ARGUMENTS` já disser `global` ou `projeto`.

- **Escopo** — "Global (Recomendado)": vale em qualquer pasta, em `~/.config/transcritor/`;
  "Só este projeto": em `./.transcritor/`, para um time ou cliente com vocabulário próprio
  (essa vence a global).
- **Tipo de reunião mais comum** — Daily/standup, Retrospectiva, Call com cliente, Reuniões
  variadas (geral).
- **Qualidade x velocidade** — "Medium (Recomendado)": ~2× tempo real em CPU, ~1,5 GB;
  "Small": bem mais rápido, erra mais nomes; "Large-v3": a melhor, ~2× mais lenta e ~3 GB.
- **Onde entregar o resumo** — "Só arquivo local (Recomendado)", "Confluence", "Notion",
  "Google Docs". Deixe claro na descrição que o plugin não instala conector: ele usa o que já
  estiver conectado na conta.

## 3. Sobre a empresa (uma mensagem em texto livre)

Peça, numa mensagem só, com um exemplo curto de resposta:

1. Nome da empresa e do time.
2. Quem participa das reuniões: nome completo, como é chamado na fala (apelidos) e papel.
3. Produtos/sistemas, clientes e jargões que aparecem nas reuniões.
4. Idioma das reuniões, se não for português.
5. Pasta onde guardar áudios e resumos (padrão `~/reunioes`, uma subpasta por data).
6. Se usam um rastreador de tarefas (Jira, Linear, Asana, GitHub Issues) — cruzar com ele
   ajuda a saber quem falou o quê e a citar os cards no resumo.

Se o usuário já tiver Jira/Confluence/Notion conectados e preferir, ofereça puxar os nomes de
pessoas, produtos e clientes de lá (cards e páginas recentes) e mostrar a lista para ele
aprovar, em vez de digitar tudo.

## 4. Integrações (só se escolheu alguma)

Para cada ferramenta escolhida (destino ou rastreador):

- Pergunte as coordenadas que faltam: Confluence → site, espaço e página-pai; Notion →
  página-pai; Google Docs → pasta; Jira/Linear → site e projeto/time.
- Verifique com `ToolSearch` se há ferramentas dessa integração na sessão (siga
  `references/integracoes.md`). Relate o resultado em uma linha:
  - disponível → ótimo, faça uma consulta de leitura simples para confirmar o acesso
    (ex.: achar o espaço ou o projeto) e guarde os IDs encontrados;
  - pede autenticação → diga para autorizar o conector (claude.ai → conectores, ou `/mcp`);
  - ausente → diga que o resumo sai como arquivo até a ferramenta ser conectada, e grave a
    preferência mesmo assim.
- Nunca peça tokens, senhas ou chaves de API, e não instale servidores MCP.

## 5. Gravar

Monte o `config.json` e mostre-o ao usuário antes de gravar. Com o OK:

- crie a pasta de config escolhida e grave `config.json`;
- crie `glossario.md` com uma tabela de pessoas (como falam → nome completo → papel), as
  listas de produtos, clientes e termos, e uma seção vazia **Erros recorrentes da
  transcrição** (como soou → grafia certa), que a skill vai alimentando com o uso;
- crie a `pasta_saida`, se não existir;
- se o escopo for projeto e a pasta for um repositório git, pergunte se `.transcritor/` deve
  ir para o `.gitignore` ou ser versionado para o time inteiro.

Termine com três linhas: onde ficou a config, o que acontece agora ("é só me mandar o áudio
da próxima reunião") e como mudar depois (`/transcritor:configurar`). Ofereça, se o usuário
tiver um áudio à mão, fazer a primeira transcrição já.
