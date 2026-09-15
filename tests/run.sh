#!/usr/bin/env bash
# Lance la suite de tests du projet.
#
#   tests/run.sh              toutes les suites
#   tests/run.sh unit         seulement les tests unitaires (rapide)
#   tests/run.sh integration  seulement l'intégration
#   tests/run.sh e2e          seulement la partie qui joue toute seule (lent)
#   tests/run.sh balance      les couloirs du banc d'équilibrage, hors de « all »
#
# Le projet est **recopié dans un dossier temporaire** avant d'être lancé. Deux
# raisons, toutes deux vérifiées à leurs dépens : lancer Godot sur le dossier de
# travail réimporte son cache .godot/ pendant que l'éditeur y est ouvert, et un
# test qui écrit dans user:// laisse des fichiers dans le vrai projet.

set -uo pipefail

GODOT="${GODOT:-/mnt/c/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe}"
SUITE="${1:-all}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="$(date +%s)-$$"
HOME_DIR="/mnt/c/Users/$(cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r\n')"
TMP_WSL="$HOME_DIR/AppData/Local/Temp/hns-test-$STAMP"
TMP_WIN="$(wslpath -w "$(dirname "$TMP_WSL")" 2>/dev/null | tr '\\' '/')/hns-test-$STAMP"
# La copie tourne sous un **nom de projet distinct**. Sans ça son `user://` est
# celui du vrai projet — même nom, même dossier — et chaque campagne y laissait
# le répertoire de travail de GUT, au milieu des données de l'éditeur.
TEST_NAME="HnSProject-test-$STAMP"
USERDATA="$HOME_DIR/AppData/Roaming/Godot/app_userdata/$TEST_NAME"

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
	# Hors de « all » : un réglage en cours ne bloque pas une livraison sans rapport.
	balance)     DIRS="res://tests/balance" ;;
	*) echo "suite inconnue : $SUITE (all|unit|integration|e2e|balance)" >&2; exit 2 ;;
esac

# Nettoyage systématique, y compris si le script est interrompu : sans ça, un
# Ctrl-C laisse un Godot accroché au dossier temporaire, qui devient
# insupprimable.
cleanup() {
	# Par ligne de commande et jamais par nom d'image : tuer tous les godot.exe
	# fermerait l'éditeur ouvert de l'utilisateur.
	powershell.exe -NoProfile -Command "
		Get-CimInstance Win32_Process |
			Where-Object { \$_.Name -like 'godot*' -and \$_.CommandLine -match 'hns-test-$STAMP' } |
			ForEach-Object { Stop-Process -Id \$_.ProcessId -Force }
	" >/dev/null 2>&1
	rm -rf "$TMP_WSL" "$USERDATA" 2>/dev/null
}
trap cleanup EXIT INT TERM

mkdir -p "$TMP_WSL"
rsync -a --exclude '.godot' --exclude '.git' "$ROOT/" "$TMP_WSL/"
sed -i "s|^config/name=.*|config/name=\"$TEST_NAME\"|" "$TMP_WSL/project.godot"

echo "== import =="
IMPORT="$("$GODOT" --headless --path "$TMP_WIN" --import 2>&1)"
if grep -qiE "SCRIPT ERROR|Parse Error|Failed to load" <<<"$IMPORT"; then
	echo "$IMPORT" | grep -iE "SCRIPT ERROR|Parse Error|Failed to load" | head -20
	echo "== IMPORT EN ÉCHEC =="
	exit 1
fi
echo "propre"

echo "== tests : $SUITE =="
# --language fr : la campagne affirme des textes français. Sans lui, la langue
# vient du système, et les tests passeraient ici pour échouer sur un Windows
# anglais — l'échec le plus cher à comprendre, celui qui ne se reproduit pas.
OUTPUT="$("$GODOT" --headless --path "$TMP_WIN" --language fr \
	-s res://addons/gut/gut_cmdln.gd \
	-gdir="$DIRS" -ginclude_subdirs -gexit -gdisable_colors 2>&1)"
CODE=$?
echo "$OUTPUT"

# Un fichier de test qui ne compile pas est **ignoré** par GUT, qui annonce
# ensuite « All tests passed » sans lui. C'est arrivé : un test e2e entier
# absent de la campagne, et un rapport vert. L'étape --import ne l'attrape pas
# non plus, elle ne parse pas les scripts de test.
if grep -qE "Failed to load script|Parse Error" <<<"$OUTPUT"; then
	echo "== UN SCRIPT DE TEST NE COMPILE PAS : il n'a pas été exécuté =="
	grep -E "Failed to load script|Parse Error" <<<"$OUTPUT" | head -10
	CODE=1
fi

echo "== code de sortie : $CODE =="
exit $CODE
