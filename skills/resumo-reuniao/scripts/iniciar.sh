#!/usr/bin/env bash
# Dispara a transcricao desacoplada da sessao do Claude Code e devolve o log.
#
# Uso:   bash iniciar.sh <arquivo-de-audio> [opcoes extras do transcrever.py]
# Saida: imprime o caminho do log; a ultima linha do log sera "DONE".
#
# O desacoplamento (setsid/nohup) existe porque sessoes do Claude Code encerram
# processos filhos comuns ao terminar - uma transcricao longa morreria no meio.

set -euo pipefail
AQUI="$(cd "$(dirname "$0")" && pwd)"

[ $# -ge 1 ] || { echo "uso: iniciar.sh <audio> [opcoes]" >&2; exit 1; }
AUDIO="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
shift
[ -f "$AUDIO" ] || { echo "arquivo nao encontrado: $AUDIO" >&2; exit 1; }

CONFIG="$(bash "$AQUI/config.sh" caminho)"
PY="$(bash "$AQUI/preparar_ambiente.sh")"

LOGDIR="$HOME/.cache/transcritor/logs"
mkdir -p "$LOGDIR"
LOG="$LOGDIR/$(basename "${AUDIO%.*}").log"

CMD=("$PY" "$AQUI/transcrever.py" "$AUDIO" "$@")
[ -n "$CONFIG" ] && CMD+=(--config "$CONFIG")

if command -v setsid >/dev/null; then
    setsid nohup "${CMD[@]}" > "$LOG" 2>&1 < /dev/null &
else
    # macOS nao tem setsid; nohup + disown basta para sobreviver ao fim da sessao.
    nohup "${CMD[@]}" > "$LOG" 2>&1 < /dev/null &
    disown || true
fi

echo "$LOG"
