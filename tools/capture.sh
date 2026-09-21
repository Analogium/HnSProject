#!/usr/bin/env bash
# Joue un scénario de capture dans le vrai jeu, **en fenêtré** — en headless le
# pilote de rendu est un bouchon et les captures sortent vides. Voir le skill
# /dessiner-un-effet, et tools/capture_scenario.gd pour le gabarit.
#
#   tools/capture.sh <scénario .gd> <sujet>
#
# Le scénario est greffé en autoload sur une copie du projet, sous un config/name
# distinct ; ses PNG sont rapatriés dans C:\Users\Theo\Desktop\hns-captures-<sujet>\.
set -uo pipefail

[ $# -eq 2 ] || { echo "usage : tools/capture.sh <scenario.gd> <sujet>"; exit 2; }
GODOT="${GODOT:-/mnt/c/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="/mnt/c/Users/Theo"
NAME="HnSProject-capture"
TMP_WSL="$HOME_DIR/AppData/Local/Temp/hns-capture"
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
cp "$1" "$TMP_WSL/capture/shot.gd"
sed -i "s|^config/name=.*|config/name=\"$NAME\"|" "$TMP_WSL/project.godot"
grep -q "config/name=\"$NAME\"" "$TMP_WSL/project.godot" || { echo "config/name non posé : arrêt"; exit 1; }
sed -i "s|^Settings=.*|&\nShot=\"*res://capture/shot.gd\"|" "$TMP_WSL/project.godot"

"$GODOT" --headless --path "$TMP_WIN" --import >/dev/null 2>&1
timeout 120 "$GODOT" --path "$TMP_WIN" --language fr 2>&1 | grep -viE "^\s*$" | head -40

cp "$USERDATA"/*.png "$OUT"/ 2>/dev/null && ls "$OUT" | tail -8
