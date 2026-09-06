#!/usr/bin/env bash
# Lance la suite de tests du projet.
#
#   tests/run.sh              toutes les suites
#   tests/run.sh unit         seulement les tests unitaires (rapide)
#   tests/run.sh integration  seulement l'intégration
#   tests/run.sh e2e          seulement la partie qui joue toute seule (lent)
#
# Le projet est **recopié dans un dossier temporaire** avant d'être lancé. Deux
# raisons, toutes deux vérifiées à leurs dépens : lancer Godot sur le dossier de
# travail réimporte son cache .godot/ pendant que l'éditeur y est ouvert, et un
# test qui écrit dans user:// laisse des fichiers dans le vrai projet.

set -uo pipefail

GODOT="${GODOT:-/mnt/c/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe}"
SUITE="${1:-all}"

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HORODATAGE="$(date +%s)-$$"
FOYER="/mnt/c/Users/$(cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r\n')"
TMP_WSL="$FOYER/AppData/Local/Temp/hns-test-$HORODATAGE"
TMP_WIN="$(wslpath -w "$(dirname "$TMP_WSL")" 2>/dev/null | tr '\\' '/')/hns-test-$HORODATAGE"
# La copie tourne sous un **nom de projet distinct**. Sans ça son `user://` est
# celui du vrai projet — même nom, même dossier — et chaque campagne y laissait
# le répertoire de travail de GUT, au milieu des données de l'éditeur.
NOM_TEST="HnSProject-test-$HORODATAGE"
USERDATA="$FOYER/AppData/Roaming/Godot/app_userdata/$NOM_TEST"

if [[ ! -x "$GODOT" ]]; then
	echo "Godot introuvable : $GODOT" >&2
	echo "Passer le chemin par la variable GODOT." >&2
	exit 2
fi

case "$SUITE" in
	all)         DIRS="res://tests/unit,res://tests/integration,res://tests/e2e" ;;
	unit)        DIRS="res://tests/unit" ;;
	integration) DIRS="res://tests/integration" ;;
	e2e)         DIRS="res://tests/e2e" ;;
	*) echo "suite inconnue : $SUITE (all|unit|integration|e2e)" >&2; exit 2 ;;
esac

# Nettoyage systématique, y compris si le script est interrompu : sans ça, un
# Ctrl-C laisse un Godot accroché au dossier temporaire, qui devient
# insupprimable.
nettoyer() {
	# Par ligne de commande et jamais par nom d'image : tuer tous les godot.exe
	# fermerait l'éditeur ouvert de l'utilisateur.
	powershell.exe -NoProfile -Command "
		Get-CimInstance Win32_Process |
			Where-Object { \$_.Name -like 'godot*' -and \$_.CommandLine -match 'hns-test-$HORODATAGE' } |
			ForEach-Object { Stop-Process -Id \$_.ProcessId -Force }
	" >/dev/null 2>&1
	rm -rf "$TMP_WSL" "$USERDATA" 2>/dev/null
}
trap nettoyer EXIT INT TERM

mkdir -p "$TMP_WSL"
rsync -a --exclude '.godot' --exclude '.git' "$RACINE/" "$TMP_WSL/"
sed -i "s|^config/name=.*|config/name=\"$NOM_TEST\"|" "$TMP_WSL/project.godot"

echo "== import =="
IMPORT="$("$GODOT" --headless --path "$TMP_WIN" --import 2>&1)"
if grep -qiE "SCRIPT ERROR|Parse Error|Failed to load" <<<"$IMPORT"; then
	echo "$IMPORT" | grep -iE "SCRIPT ERROR|Parse Error|Failed to load" | head -20
	echo "== IMPORT EN ÉCHEC =="
	exit 1
fi
echo "propre"

echo "== tests : $SUITE =="
"$GODOT" --headless --path "$TMP_WIN" \
	-s res://addons/gut/gut_cmdln.gd \
	-gdir="$DIRS" -ginclude_subdirs -gexit -gdisable_colors
CODE=$?

echo "== code de sortie : $CODE =="
exit $CODE
