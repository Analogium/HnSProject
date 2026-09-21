#!/usr/bin/env bash
# Rend une planche de comparaison hors du jeu, en headless : pur calcul
# (PixelCanvas, Image.save_png), aucune fenêtre. Voir le skill /dessiner-un-effet.
#
#   tools/planche.sh <script SceneTree .gd> <sujet>
#
# Le script écrit ses PNG dans user:// ; ils sont rapatriés dans
# C:\Users\Theo\Desktop\hns-captures-<sujet>\ — AppData est masqué dans l'Explorateur.
# Le projet est recopié sous un config/name distinct : jamais le user:// du vrai
# projet, jamais le .godot/ de l'éditeur ouvert (CLAUDE.md).
set -uo pipefail

[ $# -eq 2 ] || { echo "usage : tools/planche.sh <script.gd> <sujet>"; exit 2; }
GODOT="${GODOT:-/mnt/c/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="/mnt/c/Users/Theo"
NAME="HnSProject-planche"
TMP_WSL="$HOME_DIR/AppData/Local/Temp/hns-planche"
TMP_WIN="$(wslpath -w "$TMP_WSL" | tr '\\' '/')"
USERDATA="$HOME_DIR/AppData/Roaming/Godot/app_userdata/$NAME"
OUT="$HOME_DIR/Desktop/hns-captures-$2"

powershell.exe -NoProfile -Command "
  Get-CimInstance Win32_Process |
    Where-Object { \$_.Name -like 'godot*' -and \$_.CommandLine -match 'Temp[\\\\/]hns-' } |
    ForEach-Object { Stop-Process -Id \$_.ProcessId -Force }
" >/dev/null 2>&1

rm -rf "$TMP_WSL" "$USERDATA"
mkdir -p "$TMP_WSL/capture" "$OUT"
rsync -a --exclude '.godot' --exclude '.git' "$ROOT/" "$TMP_WSL/"
cp "$1" "$TMP_WSL/capture/planche.gd"
sed -i "s|^config/name=.*|config/name=\"$NAME\"|" "$TMP_WSL/project.godot"
grep -q "config/name=\"$NAME\"" "$TMP_WSL/project.godot" || { echo "config/name non posé : arrêt"; exit 1; }

"$GODOT" --headless --path "$TMP_WIN" --import >/dev/null 2>&1
# Un script lancé par --script ne voit pas les autoloads (Game…) : une classe qui
# les nomme ne compile pas ici. Recopier ses constantes plutôt que de la citer.
timeout 180 "$GODOT" --headless --path "$TMP_WIN" --script res://capture/planche.gd 2>&1 \
  | grep -viE "^\s*$" | head -40

cp "$USERDATA"/*.png "$OUT"/ 2>/dev/null && ls "$OUT" | tail -5
