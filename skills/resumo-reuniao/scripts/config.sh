#!/usr/bin/env bash
# Resolve onde fica a configuracao do transcritor.
#
#   bash config.sh caminho   -> config ativa (projeto, senao global); vazio se nao houver
#   bash config.sh pasta     -> pasta da config ativa (onde ficam config.json e glossario.md)
#   bash config.sh global    -> pasta global, mesmo que ainda nao exista
#   bash config.sh projeto   -> pasta do projeto atual, mesmo que ainda nao exista
#
# A config de projeto (./.transcritor/) vence a global: assim cada time ou cliente
# pode ter o proprio vocabulario e destino sem mexer na dos outros.

set -euo pipefail
GLOBAL="${XDG_CONFIG_HOME:-$HOME/.config}/transcritor"
PROJETO="$PWD/.transcritor"

case "${1:-caminho}" in
    global)  echo "$GLOBAL" ;;
    projeto) echo "$PROJETO" ;;
    caminho|pasta)
        for d in "$PROJETO" "$GLOBAL"; do
            if [ -f "$d/config.json" ]; then
                [ "${1:-caminho}" = pasta ] && echo "$d" || echo "$d/config.json"
                exit 0
            fi
        done
        echo "" ;;
    *) echo "uso: config.sh [caminho|pasta|global|projeto]" >&2; exit 1 ;;
esac
