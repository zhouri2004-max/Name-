#!/usr/bin/env bash
set -euo pipefail

python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo "[+] Dependencies installed."
echo "[+] Edit .env, then run: python discord_selfbot.py"
