#!/usr/bin/env python3
"""Transcreve o audio (ou video) de uma reuniao com faster-whisper, localmente.

Uso:
    python3 transcrever.py <arquivo> [--config config.json] [--saida arquivo.txt]
                           [--modelo medium] [--idioma pt] [--tipo daily]

O vocabulario da empresa (participantes, produtos, clientes, termos) vem do
config.json gerado por /transcritor:configurar e vira o "initial_prompt" do
Whisper, que e o que faz ele acertar nomes proprios.

Escreve os segmentos com timestamp incrementalmente, de modo que uma interrupcao
no meio preserva o que ja saiu. Imprime "DONE" na ultima linha quando conclui.
"""

import argparse
import json
import os
import sys
import time

# O Whisper so aproveita ~224 tokens de prompt; acima disso o excesso e cortado
# pelo inicio, que e justamente onde fica o contexto mais importante.
LIMITE_PROMPT = 800


def carregar_config(caminho):
    if not caminho or not os.path.exists(caminho):
        return {}
    with open(caminho, encoding="utf-8") as f:
        return json.load(f)


def montar_prompt(cfg, tipo):
    partes = []
    cabecalho = f"Reuniao {tipo}" if tipo else "Reuniao"
    if cfg.get("time"):
        cabecalho += f" do time {cfg['time']}"
    if cfg.get("empresa"):
        cabecalho += f" da {cfg['empresa']}"
    partes.append(cabecalho + ".")

    apelidos = []
    for p in cfg.get("participantes", []):
        apelidos.extend(p.get("apelidos") or [])
        if p.get("nome"):
            apelidos.append(p["nome"])
    for rotulo, itens in (
        ("Participantes", apelidos),
        ("Produtos", cfg.get("produtos", [])),
        ("Clientes", cfg.get("clientes", [])),
        ("Termos", cfg.get("termos", [])),
    ):
        unicos = list(dict.fromkeys(i for i in itens if i))
        if unicos:
            partes.append(f"{rotulo}: {', '.join(unicos)}.")

    prompt = " ".join(partes)
    return prompt[:LIMITE_PROMPT]


def main():
    p = argparse.ArgumentParser()
    p.add_argument("audio")
    p.add_argument("--config", default=None)
    p.add_argument("--saida", default=None)
    p.add_argument("--modelo", default=None)
    p.add_argument("--idioma", default=None)
    p.add_argument("--tipo", default=None, help="daily, retro, planning, cliente...")
    p.add_argument("--threads", type=int, default=max(1, (os.cpu_count() or 4) - 2))
    args = p.parse_args()

    if not os.path.exists(args.audio):
        sys.exit(f"arquivo nao encontrado: {args.audio}")

    cfg = carregar_config(args.config)
    modelo_nome = args.modelo or cfg.get("modelo_whisper") or "medium"
    idioma = args.idioma or cfg.get("idioma") or "pt"
    tipo = args.tipo or cfg.get("tipo_reuniao_padrao") or ""
    dispositivo = cfg.get("dispositivo") or "cpu"
    saida = args.saida or os.path.splitext(args.audio)[0] + ".transcript.txt"
    prompt = montar_prompt(cfg, tipo)

    from faster_whisper import WhisperModel

    print(f"[{time.strftime('%H:%M:%S')}] carregando modelo {modelo_nome} ({dispositivo})...", flush=True)
    modelo = WhisperModel(
        modelo_nome,
        device=dispositivo,
        compute_type="int8" if dispositivo == "cpu" else "float16",
        cpu_threads=args.threads,
    )
    print(f"[{time.strftime('%H:%M:%S')}] modelo pronto, transcrevendo...", flush=True)

    segmentos, info = modelo.transcribe(
        args.audio,
        language=idioma,
        beam_size=5,
        vad_filter=True,
        vad_parameters=dict(min_silence_duration_ms=700),
        condition_on_previous_text=False,
        initial_prompt=prompt or None,
    )
    print(f"[{time.strftime('%H:%M:%S')}] duracao do audio: {info.duration:.0f}s", flush=True)

    with open(saida, "w", encoding="utf-8") as f:
        for s in segmentos:
            ini = int(s.start)
            linha = f"[{ini // 60:02d}:{ini % 60:02d}] {s.text.strip()}"
            f.write(linha + "\n")
            f.flush()
            print(linha, flush=True)

    print(f"[{time.strftime('%H:%M:%S')}] transcricao salva em {saida}", flush=True)
    print("DONE", flush=True)


if __name__ == "__main__":
    main()
