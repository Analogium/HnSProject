#!/usr/bin/env bash
# Régénère docs/CATALOGUE.md depuis les .tres du projet.
#
#   tools/catalogue.sh
#
# À lancer après avoir ajouté ou retouché une base d'objet, un affixe, ou l'une
# des deux règles qui décident des fenêtres (MARGE_DE_RELEVE, PALIERS_OUVERTS).
#
# Même précaution que tests/run.sh, et pour les mêmes raisons apprises à leurs
# dépens : le projet est recopié dans un dossier temporaire sous un nom distinct,
# parce que lancer Godot sur le dossier de travail lui réimporte son cache
# .godot/ pendant que l'éditeur y est ouvert, et parce qu'un `user://` homonyme
# écrirait dans les données du vrai projet.

set -uo pipefail

GODOT="${GODOT:-/mnt/c/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe}"

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HORODATAGE="$(date +%s)-$$"
FOYER="/mnt/c/Users/$(cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r\n')"
TMP_WSL="$FOYER/AppData/Local/Temp/hns-doc-$HORODATAGE"
TMP_WIN="$(wslpath -w "$(dirname "$TMP_WSL")" 2>/dev/null | tr '\\' '/')/hns-doc-$HORODATAGE"
NOM_DOC="HnSProject-doc-$HORODATAGE"
USERDATA="$FOYER/AppData/Roaming/Godot/app_userdata/$NOM_DOC"

if [[ ! -x "$GODOT" ]]; then
	echo "Godot introuvable : $GODOT" >&2
	echo "Passer le chemin par la variable GODOT." >&2
	exit 2
fi

nettoyer() {
	# Par ligne de commande et jamais par nom d'image : tuer tous les godot.exe
	# fermerait l'éditeur ouvert de l'utilisateur.
	powershell.exe -NoProfile -Command "
		Get-CimInstance Win32_Process |
			Where-Object { \$_.Name -like 'godot*' -and \$_.CommandLine -match 'hns-doc-$HORODATAGE' } |
			ForEach-Object { Stop-Process -Id \$_.ProcessId -Force }
	" >/dev/null 2>&1
	rm -rf "$TMP_WSL" "$USERDATA" 2>/dev/null
}
trap nettoyer EXIT INT TERM

mkdir -p "$TMP_WSL"
rsync -a --exclude '.godot' --exclude '.git' "$RACINE/" "$TMP_WSL/"
sed -i "s|^config/name=.*|config/name=\"$NOM_DOC\"|" "$TMP_WSL/project.godot"
sed -i "s|^run/main_scene=.*|run/main_scene=\"res://tools/catalogue.tscn\"|" "$TMP_WSL/project.godot"

echo "== import =="
IMPORT="$("$GODOT" --headless --path "$TMP_WIN" --import 2>&1)"
if grep -qiE "SCRIPT ERROR|Parse Error|Failed to load" <<<"$IMPORT"; then
	grep -iE "SCRIPT ERROR|Parse Error|Failed to load" <<<"$IMPORT" | head -20
	echo "== IMPORT EN ÉCHEC =="
	exit 1
fi

echo "== generation =="
# --language fr : le catalogue est un document français. Sans lui, il se
# régénérerait en anglais sur une machine anglaise, et le diff ferait croire à
# une retouche de contenu.
SORTIE="$("$GODOT" --headless --path "$TMP_WIN" --language fr 2>&1)"
grep -iE "SCRIPT ERROR|ERROR" <<<"$SORTIE" | head -10

if [[ ! -f "$USERDATA/CATALOGUE.md" ]]; then
	echo "== RIEN N'A ETE ECRIT ==" >&2
	echo "$SORTIE" | tail -20 >&2
	exit 1
fi

mkdir -p "$RACINE/docs"
cp "$USERDATA/CATALOGUE.md" "$RACINE/docs/CATALOGUE.md"
echo "docs/CATALOGUE.md : $(wc -l < "$RACINE/docs/CATALOGUE.md") lignes"
