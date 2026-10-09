---
name: resumo-reuniao
description: Transcreve localmente a gravação de uma reunião (daily, standup, retro, planning, call com cliente) e gera um resumo estruturado — por pessoa, decisões, pendências e riscos — usando o vocabulário da empresa configurado em /transcritor:configurar, com publicação opcional em Confluence, Notion etc. Use sempre que o usuário enviar ou apontar um arquivo de áudio/vídeo de reunião, ou pedir transcrição, resumo, ata ou notas de uma reunião — inclusive quando ele só anexar o áudio e disser algo curto como "daily de hoje" ou "resume aí".
---

# Resumo de reunião

Fluxo em cinco fases: transcrever, mapear locutores, cruzar com as ferramentas da empresa,
escrever, publicar. As fases 2 e 5 têm uma **parada obrigatória** para confirmação do usuário
— são os dois pontos onde um erro sai caro.

Scripts: `${CLAUDE_PLUGIN_ROOT}/skills/resumo-reuniao/scripts/` (abaixo, `$S`).

## Fase 0 — Carregar a configuração

```bash
S="${CLAUDE_PLUGIN_ROOT}/skills/resumo-reuniao/scripts"
bash "$S/config.sh" pasta
```

- **Vazio:** não há configuração. Diga em uma linha que dá para personalizar com
  `/transcritor:configurar` (nomes, produtos, destino) e pergunte se quer configurar agora ou
  seguir com o padrão (`medium`, `pt`, resumo local ao lado do áudio). Não bloqueie.
- **Achou:** leia `config.json` e `glossario.md` dessa pasta. Os campos estão em
  `references/configuracao.md`.

O resumo e as conversas saem no `idioma` da config (padrão: português do Brasil), mantendo
termos técnicos em inglês quando é assim que o time fala.

## Fase 1 — Transcrever

Se o áudio não estiver em `pasta_saida`, pergunte se pode copiá-lo para lá (na subpasta
`DD-MM-AAAA/` quando `pasta_por_data` for `true`). O trabalho fica lado a lado: o áudio, o
`.transcript.txt` e o `-resumo.md`.

```bash
LOG=$(bash "$S/iniciar.sh" <caminho-do-audio> [--tipo retro] [--modelo small])
```

O `iniciar.sh` prepara o ambiente Python (`~/.cache/transcritor/venv`, só na primeira vez),
aplica o vocabulário da config e dispara a transcrição **desacoplada da sessão**: sessões do
Claude Code encerram processos filhos comuns, e uma transcrição longa morreria no meio. O
script também grava linha a linha, então uma interrupção preserva o que já saiu.

Estimativa: `medium` em CPU roda a ~2× tempo real (26 min de áudio ≈ 13 min). Na primeira
execução ele ainda instala o faster-whisper e baixa ~1,5 GB de modelo — avise o usuário.
Acompanhe o `$LOG` com um `Monitor` até a última linha ser `DONE` e dê notícias de progresso
de vez em quando, sem perguntar a cada 30 segundos; o usuário prefere fazer outra coisa
enquanto isso. Se o log terminar sem `DONE`, mostre as últimas linhas e diagnostique.

## Fase 2 — Mapear locutores e confirmar

Não há diarização automática. A atribuição sai do conteúdo e da ordem da conversa — e é onde
mais se erra. **Confirme antes de escrever o resumo**: um locutor trocado contamina o texto
inteiro e obriga a reescrever tudo.

1. **Segmente por mudança de assunto.** Numa daily cada pessoa fala um bloco contínuo.
   Marcadores de virada: "então vamos começar", "e você, fulano?", "ok, show", "onde a gente
   parou?". Em reuniões livres, segmente por tema e só atribua falas com sinal claro.
2. **Colha as auto-referências.** Quem cita outro em terceira pessoa ("o fulano me passou")
   não é essa pessoa. Quem é interpelado pelo nome ("boa explicação, fulano") falou no bloco
   anterior. Se dois sinais se contradizem, o problema costuma ser a fronteira do bloco, não a
   identidade.
3. **Cruze com o rastreador antes de perguntar** (Fase 3), se houver um configurado. O
   responsável pelo card que a pessoa descreve resolve a maior parte das ambiguidades.
4. **Apresente o mapa bloco a bloco, com cada dúvida colada no bloco a que se refere** — não
   uma tabela seguida de uma lista de dúvidas no fim. Cada bloco traz início, palpite, trecho
   de uma linha e o que sustenta o palpite. Bloco sem dúvida fica em uma linha, com ✅.

> **Bloco 1 · 00:00 · Maria** ✅
> "finalizei os ajustes que o QA pediu" — `ABC-142` está com ela.
>
> **Bloco 2 · 02:02 · João**
> "fiquei mexendo no módulo de relatórios inteiro" — ⟨só pela ordem da rodada⟩
> ❓ Foi o João mesmo ou o Pedro? Nenhum card de relatórios está com ele.

Diga abertamente de quais blocos não tem certeza. Corrigir agora custa uma frase; depois
custa o documento todo.

## Fase 3 — Cruzar com as ferramentas da empresa (opcional)

Só se `integracoes.rastreador` ou `integracoes.publicar_em` apontarem para alguma ferramenta.
Leia `references/integracoes.md` — explica como descobrir se o conector está disponível, o
que consultar e o que fazer quando não está.

Independente de integração, use o `glossario.md`: a transcrição erra nomes próprios de forma
previsível. Quando nem o glossário nem uma busca resolverem, **marque `⟨…⟩` em vez de escolher
a grafia mais plausível** — um nome inventado publicado é pior que uma lacuna assumida.

## Fase 4 — Escrever o resumo

Escolha o modelo em `assets/modelos/` pelo tipo da reunião (`daily`, `retro`, `cliente`;
`geral` para planning e o resto). Se o tipo real não bater com o padrão da config, use o real.
Salve como `<pasta-do-áudio>/<nome-do-áudio>-resumo.md`.

O que separa um resumo útil de uma transcrição encurtada:

- **Registre a decisão, não o debate.** O estado final da regra: o que passa a valer, para
  quem, controlado por quê. Quem quiser o caminho até lá tem a transcrição.
- **Cite cards como link clicável** quando conseguir amarrar o item a um card, em todo lugar
  do resumo — destaques, atualizações, tabelas.
- **Preserve a causa raiz.** "Corrigiu bug de notificação" não ajuda ninguém; "o ícone não
  aparecia porque faltava o recurso no manifesto" ajuda quem cair no mesmo problema.
- **Riscos merecem seção própria.** Regra que diverge entre clientes, configuração que quebra
  outros ambientes, uma pessoa sozinha segurando uma área — isso se perde na fala.
- **Números e nomes conforme ditos.** Prazos, percentuais e horários vêm do áudio; não
  arredonde nem "melhore".
- **Alguém não falou:** não invente seção. Ausência é informação.
- **Trecho ilegível** (áudio cortado, gente falando junto): diga qual intervalo ficou ruim em
  vez de preencher com inferência.

## Fase 5 — Revisar e publicar

**Mostre o resumo e espere o OK explícito.** Junto, em poucas linhas:

- o que mudou desde a última versão, se houver;
- os itens ainda marcados `⟨…⟩`, agrupados pela seção/pessoa onde aparecem, com o trecho ao
  lado — nunca numa lista solta;
- qualquer trecho da transcrição que contradiga o que você escreveu.

Com o OK:

- `publicar_em` = `arquivo` (ou sem config): o `.md` já é a entrega. Devolva o caminho.
- Outro destino: publique conforme `references/integracoes.md` e devolva o link. Se o
  conector não estiver disponível, entregue o arquivo e diga como ligar a integração.

## Aprender com as correções

Quando o usuário corrigir uma grafia, um apelido ou um termo que vai se repetir nas próximas
reuniões, ofereça (uma vez, no fim) acrescentar ao `glossario.md` da config ativa — e aos
`participantes`/`termos` do `config.json` quando for algo que o Whisper precisa ouvir certo.
É assim que o transcritor fica melhor a cada reunião.
