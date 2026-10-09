# Integrações opcionais

O plugin **não traz conector nenhum**. Ele só usa as ferramentas que a sessão já tiver
(conectores do claude.ai, servidores MCP que a pessoa instalou por conta própria). Sem
nenhuma, o fluxo inteiro funciona e o resultado é o arquivo `.md` local.

## Como descobrir se a integração está disponível

Antes de consultar ou publicar, procure as ferramentas com `ToolSearch` usando palavras da
ferramenta configurada (ex.: `confluence page`, `jira search`, `notion page`, `linear issue`).

- **Achou e funciona:** siga.
- **Achou, mas pede autenticação:** diga que o conector precisa ser autorizado (conectores do
  claude.ai nas configurações de conectores; outros servidores via `/mcp`). Não peça token.
- **Não achou:** não trave. Entregue o arquivo local e diga em uma linha que dá para ligar a
  integração depois conectando a ferramenta. Não tente instalar nada.

Nunca conclua "não há acesso" sem ter procurado — servidores MCP às vezes ainda estão
conectando no começo da sessão e o `ToolSearch` espera por eles.

## Cruzar com o rastreador de tarefas (Jira, Linear, Asana, GitHub…)

É o que mais aumenta a precisão do resumo: o responsável pelo card que alguém descreve
confirma quem falou, e o título traz a grafia oficial de produtos e clientes.

- Busque os itens **atualizados desde o dia útil anterior** à reunião, no projeto configurado,
  trazendo só chave, título, status e responsável. Ex. Jira:
  `project = ABC AND updated >= "AAAA-MM-DD" ORDER BY updated DESC`.
- Se a resposta vier grande e for salva em arquivo, extraia as quatro colunas com um script
  curto em vez de ler o JSON inteiro.
- Cite os itens como **link clicável**, montado com `rastreador_config.url_card` quando houver
  (`[ABC-123](https://acme.atlassian.net/browse/ABC-123)`), nunca a chave solta.
- Somente leitura. Criar, comentar ou mover card é outra tarefa e precisa de pedido explícito.

## Buscar nomenclatura (Confluence, Notion, Drive…)

Para termos que soaram estranhos na transcrição, busque pelo termo na base de conhecimento
conectada. Duas armadilhas comuns:

- Várias condições com `OR` numa só busca às vezes voltam vazias mesmo havendo resultado.
  Se vier vazio e você esperava algo, refaça termo a termo.
- Zero resultados não prova que o termo está errado. Marque `⟨…⟩` e pergunte.

## Publicar

Só depois do OK explícito do usuário (ver Fase 5 do SKILL.md).

| Destino | Como |
|---|---|
| `confluence` | Página filha de `destino.pagina_pai` no espaço `destino.espaco`. Prefira corpo em markdown se a ferramenta aceitar. Título = data por extenso (ou o título da reunião), **sem** repetir o H1 no corpo. Se a página-pai não existir, pergunte antes de criá-la — duplicar a página-índice bagunça o espaço. |
| `notion` | Página filha de `destino.pagina_pai`, mesmo critério de título. |
| `google_docs` | Documento novo na pasta `destino.pasta`, se houver. |
| `outro` | Siga o que estiver descrito em `destino`; na dúvida, pergunte. |

Depois de publicar, devolva o link. Grave no `config.json` o ID da página-pai/espaço que você
descobriu (pergunte antes de escrever na config), para a próxima vez pular a busca. Se o
usuário pedir mudança num resumo já publicado, **edite a página existente**, não crie outra.

Mandar o resumo por Slack, e-mail ou chat é envio de mensagem em nome do usuário: só com
pedido explícito e confirmação do destinatário naquela vez.
