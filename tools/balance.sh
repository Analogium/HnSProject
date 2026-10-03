#!/usr/bin/env bash
# Régénère docs/EQUILIBRAGE.md : le calcul sur toute la grille, puis la simulation.
#
#   tools/balance.sh               calcul et simulation
#   tools/balance.sh calculation   le calcul seul, à relancer après chaque réglage
#   tools/balance.sh trees         le banc des arbres, docs/ARBRES.md (PARTS processus)
#
# Mêmes précautions que tools/catalog.sh : copie temporaire sous un nom de projet
# distinct, processus ciblés par ligne de commande.

set -uo pipefail

GODOT="${GODOT:-/mnt/c/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="$(date +%s)-$$"
HOME_DIR="/mnt/c/Users/$(cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r\n')"
TMP_WSL="$HOME_DIR/AppData/Local/Temp/hns-banc-$STAMP"
TMP_WIN="$(wslpath -w "$(dirname "$TMP_WSL")" 2>/dev/null | tr '\\' '/')/hns-banc-$STAMP"
BENCH_NAME="HnSProject-banc-$STAMP"
USERDATA="$HOME_DIR/AppData/Roaming/Godot/app_userdata/$BENCH_NAME"

if [[ ! -x "$GODOT" ]]; then
	echo "Godot introuvable : $GODOT" >&2
	echo "Passer le chemin par la variable GODOT." >&2
	exit 2
fi

cleanup() {
	powershell.exe -NoProfile -Command "
		Get-CimInstance Win32_Process |
			Where-Object { \$_.Name -like 'godot*' -and \$_.CommandLine -match 'hns-banc-$STAMP' } |
			ForEach-Object { Stop-Process -Id \$_.ProcessId -Force }
	" >/dev/null 2>&1
	rm -rf "$TMP_WSL" "$USERDATA" 2>/dev/null
}
trap cleanup EXIT INT TERM

mkdir -p "$TMP_WSL"
rsync -a --exclude '.godot' --exclude '.git' "$ROOT/" "$TMP_WSL/"
sed -i "s|^config/name=.*|config/name=\"$BENCH_NAME\"|" "$TMP_WSL/project.godot"
sed -i "s|^run/main_scene=.*|run/main_scene=\"res://tools/balance.tscn\"|" "$TMP_WSL/project.godot"

echo "== import =="
IMPORT="$("$GODOT" --headless --path "$TMP_WIN" --import 2>&1)"
if grep -qiE "SCRIPT ERROR|Parse Error|Failed to load" <<<"$IMPORT"; then
	grep -iE "SCRIPT ERROR|Parse Error|Failed to load" <<<"$IMPORT" | head -20
	echo "== IMPORT EN ÉCHEC =="
	exit 1
fi

echo "== banc =="
# Le banc des arbres en parallèle : une compétence sur PARTS par processus, et le rapport
# rassemblé de leurs sections. Seul, il prenait 36 min.
if [[ " $* " == *" trees "* ]]; then
	PARTS="${PARTS:-11}"
	[[ " $* " == *" measure="* ]] && PARTS=1
	for ((i = 0; i < PARTS; i++)); do
		"$GODOT" --headless --path "$TMP_WIN" --language fr --fixed-fps 60 -- "$@" "part=$i/$PARTS" \
			> "$TMP_WSL/part-$i.log" 2>&1 &
	done
	wait
	cat "$TMP_WSL"/part-*.log | grep -E "^arbres "
	cat "$TMP_WSL"/part-*.log | grep -iE "SCRIPT ERROR|ERROR" | head -10
	if [[ -f "$USERDATA/arbres/00.md" && " $* " != *" measure="* ]]; then
		cat "$USERDATA"/arbres/*.md > "$ROOT/docs/ARBRES.md"
		echo "docs/ARBRES.md : $(wc -l < "$ROOT/docs/ARBRES.md") lignes"
	fi
	exit 0
fi

# --fixed-fps : la simulation avance d'une image de physique par image, aussi vite que la
# machine le permet, au lieu de suivre l'horloge.
OUTPUT="$("$GODOT" --headless --path "$TMP_WIN" --language fr --fixed-fps 60 -- "$@" 2>&1)"
grep -E "^(calcul|simulation) " <<<"$OUTPUT"
grep -iE "SCRIPT ERROR|ERROR" <<<"$OUTPUT" | head -10

if [[ ! -f "$USERDATA/EQUILIBRAGE.md" ]]; then
	echo "== RIEN N'A ETE ECRIT ==" >&2
	echo "$OUTPUT" | tail -20 >&2
	exit 1
fi

cp "$USERDATA/EQUILIBRAGE.md" "$ROOT/docs/EQUILIBRAGE.md"
echo "docs/EQUILIBRAGE.md : $(wc -l < "$ROOT/docs/EQUILIBRAGE.md") lignes"
