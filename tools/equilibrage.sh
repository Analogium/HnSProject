#!/usr/bin/env bash
# Régénère docs/EQUILIBRAGE.md : le calcul sur toute la grille, puis la simulation.
#
#   tools/equilibrage.sh          calcul et simulation
#   tools/equilibrage.sh calcul   le calcul seul, à relancer après chaque réglage
#
# Mêmes précautions que tools/catalogue.sh : copie temporaire sous un nom de projet
# distinct, processus ciblés par ligne de commande.

set -uo pipefail

GODOT="${GODOT:-/mnt/c/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe}"

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HORODATAGE="$(date +%s)-$$"
FOYER="/mnt/c/Users/$(cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r\n')"
TMP_WSL="$FOYER/AppData/Local/Temp/hns-banc-$HORODATAGE"
TMP_WIN="$(wslpath -w "$(dirname "$TMP_WSL")" 2>/dev/null | tr '\\' '/')/hns-banc-$HORODATAGE"
NOM_BANC="HnSProject-banc-$HORODATAGE"
USERDATA="$FOYER/AppData/Roaming/Godot/app_userdata/$NOM_BANC"

if [[ ! -x "$GODOT" ]]; then
	echo "Godot introuvable : $GODOT" >&2
	echo "Passer le chemin par la variable GODOT." >&2
	exit 2
fi

nettoyer() {
	powershell.exe -NoProfile -Command "
		Get-CimInstance Win32_Process |
			Where-Object { \$_.Name -like 'godot*' -and \$_.CommandLine -match 'hns-banc-$HORODATAGE' } |
			ForEach-Object { Stop-Process -Id \$_.ProcessId -Force }
	" >/dev/null 2>&1
	rm -rf "$TMP_WSL" "$USERDATA" 2>/dev/null
}
trap nettoyer EXIT INT TERM

mkdir -p "$TMP_WSL"
rsync -a --exclude '.godot' --exclude '.git' "$RACINE/" "$TMP_WSL/"
sed -i "s|^config/name=.*|config/name=\"$NOM_BANC\"|" "$TMP_WSL/project.godot"
sed -i "s|^run/main_scene=.*|run/main_scene=\"res://tools/equilibrage.tscn\"|" "$TMP_WSL/project.godot"

echo "== import =="
IMPORT="$("$GODOT" --headless --path "$TMP_WIN" --import 2>&1)"
if grep -qiE "SCRIPT ERROR|Parse Error|Failed to load" <<<"$IMPORT"; then
	grep -iE "SCRIPT ERROR|Parse Error|Failed to load" <<<"$IMPORT" | head -20
	echo "== IMPORT EN ÉCHEC =="
	exit 1
fi

echo "== banc =="
# --fixed-fps : la simulation avance d'une image de physique par image, aussi vite que la
# machine le permet, au lieu de suivre l'horloge.
SORTIE="$("$GODOT" --headless --path "$TMP_WIN" --language fr --fixed-fps 60 -- "$@" 2>&1)"
grep -E "^(calcul|simulation) " <<<"$SORTIE"
grep -iE "SCRIPT ERROR|ERROR" <<<"$SORTIE" | head -10

if [[ ! -f "$USERDATA/EQUILIBRAGE.md" ]]; then
	echo "== RIEN N'A ETE ECRIT ==" >&2
	echo "$SORTIE" | tail -20 >&2
	exit 1
fi

cp "$USERDATA/EQUILIBRAGE.md" "$RACINE/docs/EQUILIBRAGE.md"
echo "docs/EQUILIBRAGE.md : $(wc -l < "$RACINE/docs/EQUILIBRAGE.md") lignes"
