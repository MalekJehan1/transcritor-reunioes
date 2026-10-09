#!/usr/bin/env bash
# Garante um venv com faster-whisper. Idempotente: se ja estiver pronto, sai em
# menos de um segundo.
#
# Uso:   bash preparar_ambiente.sh
# Saida: imprime o caminho do interpretador python a usar.
#
# O venv fica em ~/.cache/transcritor/venv (ou $TRANSCRITOR_VENV_DIR) e sobrevive
# entre sessoes e atualizacoes do plugin.

set -euo pipefail

V="${TRANSCRITOR_VENV_DIR:-$HOME/.cache/transcritor/venv}"
PY="$V/bin/python"

if "$PY" -c "import faster_whisper" 2>/dev/null; then
    echo "$PY"
    exit 0
fi

command -v python3 >/dev/null || { echo "python3 nao encontrado; instale Python 3.9+" >&2; exit 1; }
python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)' \
    || { echo "Python 3.9+ necessario (achei $(python3 --version))" >&2; exit 1; }

mkdir -p "$(dirname "$V")"

# python3-venv costuma vir sem ensurepip no Ubuntu, entao criamos o venv sem pip
# e trazemos o pip pelo get-pip.py. Evita depender de apt/sudo.
if [ ! -x "$PY" ]; then
    python3 -m venv --without-pip "$V"
fi

if ! "$PY" -m pip --version >/dev/null 2>&1; then
    curl -sSLo "$V/get-pip.py" https://bootstrap.pypa.io/pip/get-pip.py
    "$PY" "$V/get-pip.py" -q
fi

"$PY" -m pip install -q --no-input faster-whisper >&2

"$PY" -c "import faster_whisper" || { echo "falha ao instalar faster-whisper" >&2; exit 1; }
echo "$PY"
