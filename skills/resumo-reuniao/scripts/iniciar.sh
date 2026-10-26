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

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
        # No Windows o Claude Code encerra a arvore de processos inteira (job object),
        # e nohup/setsid nao a deixam. Criar o processo pelo WMI o coloca fora dessa
        # arvore. O pythonw.exe roda sem janela; como ele nao tem stdout, o proprio
        # script grava o log (--log). Os caminhos vao no formato C:/... do Windows.
        w() { cygpath -m "$1"; }
        LINHA="\"$(w "$(dirname "$PY")/pythonw.exe")\" \"$(w "$AQUI/transcrever.py")\" \"$(w "$AUDIO")\""
        for a in "$@"; do LINHA+=" \"$a\""; done
        [ -n "$CONFIG" ] && LINHA+=" --config \"$(w "$CONFIG")\""
        LINHA+=" --log \"$(w "$LOG")\""
        : > "$LOG"
        TRANSCRITOR_CMD="$LINHA" powershell.exe -NoProfile -NonInteractive -Command \
            '$r = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine = $env:TRANSCRITOR_CMD}; if ($r.ReturnValue -ne 0) { Write-Error "Win32_Process.Create falhou: $($r.ReturnValue)"; exit 1 }' \
            > /dev/null
        ;;
    *)
        CMD=("$PY" "$AQUI/transcrever.py" "$AUDIO" "$@")
        [ -n "$CONFIG" ] && CMD+=(--config "$CONFIG")

        if command -v setsid >/dev/null; then
            setsid nohup "${CMD[@]}" > "$LOG" 2>&1 < /dev/null &
        else
            # macOS nao tem setsid; nohup + disown basta para sobreviver ao fim da sessao.
            nohup "${CMD[@]}" > "$LOG" 2>&1 < /dev/null &
            disown || true
        fi
        ;;
esac

echo "$LOG"
