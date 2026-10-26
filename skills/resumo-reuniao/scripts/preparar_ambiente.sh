#!/usr/bin/env bash
# Garante um venv com faster-whisper. Idempotente: se ja estiver pronto, sai em
# menos de um segundo.
#
# Uso:   bash preparar_ambiente.sh
# Saida: imprime o caminho do interpretador python a usar.
#
# O venv fica em ~/.cache/transcritor/venv (ou $TRANSCRITOR_VENV_DIR) e sobrevive
# entre sessoes e atualizacoes do plugin.
#
# Funciona em Linux, macOS e Windows (Git Bash, que e o shell do Claude Code no
# Windows). La o venv guarda o interpretador em Scripts/python.exe, nao bin/python.

set -euo pipefail

V="${TRANSCRITOR_VENV_DIR:-$HOME/.cache/transcritor/venv}"

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) WINDOWS=1; PY="$V/Scripts/python.exe" ;;
    *)                    WINDOWS=0; PY="$V/bin/python" ;;
esac

# O PyAV 19 removeu o argumento metadata_errors que o faster-whisper 1.2.x passa ao
# av.open(); com ele a transcricao quebra logo ao abrir o audio. Fica preso abaixo
# do 19, e um venv antigo que ja tenha o 19 e corrigido abaixo.
AV='av<19'
PRONTO='import faster_whisper, av, sys; sys.exit(0 if int(av.__version__.split(".")[0]) < 19 else 1)'

if "$PY" -c "$PRONTO" 2>/dev/null; then
    echo "$PY"
    exit 0
fi

# Acha um Python 3.9+ que rode de verdade. No Windows, "python3" costuma ser o atalho
# da Microsoft Store: existe no PATH mas nao executa nada, entao testamos cada
# candidato em vez de so checar se o comando existe.
SISTEMA=""
for c in python3 python "py -3"; do
    if $c -c 'import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)' >/dev/null 2>&1; then
        SISTEMA="$c"
        break
    fi
done
[ -n "$SISTEMA" ] || { echo "Python 3.9+ nao encontrado; instale Python 3.9+" >&2; exit 1; }

mkdir -p "$(dirname "$V")"

if [ ! -x "$PY" ]; then
    if [ "$WINDOWS" = 1 ]; then
        # O instalador do python.org traz ensurepip, entao o venv ja nasce com pip.
        $SISTEMA -m venv "$V"
    else
        # python3-venv costuma vir sem ensurepip no Ubuntu, entao criamos o venv sem pip
        # e trazemos o pip pelo get-pip.py. Evita depender de apt/sudo.
        $SISTEMA -m venv --without-pip "$V"
    fi
fi

if ! "$PY" -m pip --version >/dev/null 2>&1; then
    curl -sSLo "$V/get-pip.py" https://bootstrap.pypa.io/pip/get-pip.py
    "$PY" "$V/get-pip.py" -q
fi

"$PY" -m pip install -q --no-input faster-whisper "$AV" >&2

"$PY" -c "$PRONTO" || { echo "falha ao instalar faster-whisper" >&2; exit 1; }
echo "$PY"
