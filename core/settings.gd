extends Node

## Les réglages du joueur, distincts de Game qui porte l'état de la partie.
##
## Un signal plutôt qu'une lecture directe : avec trois cents barres de vie à
## l'écran, faire interroger le réglage par chacune à chaque image se paierait
## pour une valeur qui change une fois par heure.
##
## **Ils survivent à la fermeture du jeu.** Un réglage qui se remet à zéro à
## chaque lancement n'est pas un réglage, c'est une case à recocher.

signal changed

## Distinct des sauvegardes de personnages : ces réglages valent pour la machine,
## et supprimer un héros ne doit pas remettre la fenêtre à sa taille d'origine.
const FICHIER := "user://reglages.json"

## Ce que « plein écran » vaut dans `echelle`. Zéro et non -1 : c'est l'absence
## de facteur de zoom, pas un facteur négatif.
const PLEIN_ECRAN := 0

## Barres de vie au-dessus des acteurs, ennemis comme alliés.
var show_health_bars := true:
	set(value):
		if value == show_health_bars:
			return
		show_health_bars = value
		changed.emit()
		_ecrire()

## Noms des affixes empilés au-dessus des ennemis qui en portent.
var show_affix_names := true:
	set(value):
		if value == show_affix_names:
			return
		show_affix_names = value
		changed.emit()
		_ecrire()

## Le facteur d'agrandissement de la fenêtre, ou PLEIN_ECRAN.
##
## **Le jeu remplit toujours la fenêtre**, quelle qu'elle soit : `stretch/mode`
## vaut `canvas_items` et l'échelle est fractionnaire, donc redimensionner à la
## main donne une image qui occupe tout, sans bande noire.
##
## Ces facteurs entiers ne sont donc pas une contrainte mais un **raccourci vers
## les tailles nettes** : à 2,5× une ligne de pixels sur deux est doublée et
## l'autre triplée, ce qui se voit sur un sprite de trente-deux pixels. Le bord de
## la fenêtre reste libre pour qui préfère remplir son écran au pixel près.
##
## Pas de signal `changed` : les barres de vie n'ont rien à réapprendre parce que
## la fenêtre a grandi.
var echelle := 2:
	set(value):
		var borne := clampi(value, PLEIN_ECRAN, echelle_maximale())
		if borne == echelle:
			return
		echelle = borne
		# Pendant une lecture, on note la valeur sans toucher à la fenêtre :
		# c'est `_ready` qui décide s'il faut l'appliquer.
		if _chargement:
			return
		_appliquer()
		_ecrire()

## Vrai pendant la lecture du fichier : sans ce garde-fou, chaque champ relu
## réécrirait le fichier qu'on est en train de lire.
var _chargement := false


## **On n'impose la taille que si le joueur l'a choisie.**
##
## Sans fichier de réglages, la fenêtre reste celle que l'environnement a posée et
## on se contente de lire le facteur qu'elle représente, pour que le bouton des
## options ne mente pas. Autrement le jeu écraserait au démarrage toute taille
## qu'il n'a pas décidée — celle du cadre de jeu intégré à l'éditeur, par
## exemple, qui a son propre sélecteur.
func _ready() -> void:
	var choisie := FileAccess.file_exists(FICHIER)
	_charger()
	if choisie:
		_appliquer()
		return

	_chargement = true
	echelle = echelle_observee()
	_chargement = false


# --------------------------------------------------------------------------
# La taille de la fenêtre
# --------------------------------------------------------------------------

## La taille à laquelle le jeu est dessiné, lue dans les réglages du projet et
## non recopiée ici : c'est elle qui décide de tout le reste, et deux définitions
## de 640 × 360 finiraient par se contredire.
static func taille_de_base() -> Vector2i:
	return Vector2i(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", 640)),
		int(ProjectSettings.get_setting("display/window/size/viewport_height", 360))
	)


## Le plus grand facteur entier qui tient dans cet écran. Pure et statique : le
## test ne doit pas dépendre de l'écran de la machine qui le lance.
##
## Au moins 1 : une machine dont l'écran serait plus petit que le cadrage du jeu
## doit quand même pouvoir le lancer, quitte à ce qu'il déborde.
static func echelle_qui_tient(ecran: Vector2i, base: Vector2i) -> int:
	if base.x <= 0 or base.y <= 0:
		return 1
	return maxi(mini(ecran.x / base.x, ecran.y / base.y), 1)


## Le facteur que la fenêtre en place représente **déjà**, arrondi vers le bas.
##
## Même calcul que pour l'écran : « combien de fois le cadrage tient-il
## là-dedans » est la même question, et deux formules finiraient par diverger d'un
## pixel — le bouton annoncerait ×2 sur une fenêtre en ×3.
static func echelle_observee() -> int:
	if DisplayServer.get_name() == "headless":
		return 1
	return echelle_qui_tient(DisplayServer.window_get_size(), taille_de_base())


## Le plus grand facteur que cet écran-ci accepte.
static func echelle_maximale() -> int:
	var utile := DisplayServer.screen_get_usable_rect(
		DisplayServer.window_get_current_screen()
	).size
	return echelle_qui_tient(utile, taille_de_base())


## Le facteur suivant dans la ronde : 1, 2, … jusqu'au maximum, puis plein écran,
## puis on repart à 1. Le plein écran est **après** les facteurs : on en sort en
## continuant d'appuyer, sans deviner qu'il faudrait revenir en arrière.
static func echelle_suivante(courante: int, maximum: int) -> int:
	if courante == PLEIN_ECRAN:
		return 1
	if courante >= maximum:
		return PLEIN_ECRAN
	return courante + 1


## Ce que le bouton des options affiche. Ici et non dans le menu : c'est le même
## texte qu'un écran de démarrage écrira un jour.
static func libelle(valeur: int, base: Vector2i) -> String:
	if valeur == PLEIN_ECRAN:
		return "Fenêtre : plein écran"
	return "Fenêtre : ×%d  (%d × %d)" % [valeur, base.x * valeur, base.y * valeur]


func libelle_courant() -> String:
	return libelle(echelle, taille_de_base())


## Passe au réglage suivant. Appelée par le menu des options.
func cycler_echelle() -> void:
	echelle = echelle_suivante(echelle, echelle_maximale())


## Pose réellement la fenêtre. Recentrée après coup : agrandie depuis son coin
## haut-gauche, elle sort de l'écran par le bas dès le facteur 3.
func _appliquer() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if echelle == PLEIN_ECRAN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var base := taille_de_base()
	DisplayServer.window_set_size(base * echelle)
	var utile := DisplayServer.screen_get_usable_rect(
		DisplayServer.window_get_current_screen()
	)
	DisplayServer.window_set_position(
		utile.position + (utile.size - base * echelle) / 2
	)


# --------------------------------------------------------------------------
# Le disque
# --------------------------------------------------------------------------

## Ce qui part sur le disque. Un dictionnaire nommé plutôt qu'une suite de
## valeurs : un réglage ajouté au milieu ne doit pas décaler la lecture des
## autres.
func vers_dict() -> Dictionary:
	return {
		"barres_de_vie": show_health_bars,
		"noms_d_affixes": show_affix_names,
		"echelle": echelle,
	}


## Un champ absent garde sa valeur par défaut plutôt que de faire échouer la
## lecture entière : un fichier écrit par une version plus ancienne doit encore
## servir.
func depuis_dict(source: Dictionary) -> void:
	_chargement = true
	show_health_bars = bool(source.get("barres_de_vie", show_health_bars))
	show_affix_names = bool(source.get("noms_d_affixes", show_affix_names))
	var lue: Variant = source.get("echelle", echelle)
	if lue is float or lue is int:
		# Bornée à la lecture : un fichier écrit sur un écran plus grand
		# demanderait un facteur que celui-ci ne peut pas afficher.
		echelle = clampi(int(lue), PLEIN_ECRAN, echelle_maximale())
	_chargement = false


func _charger() -> void:
	var fichier := FileAccess.open(FICHIER, FileAccess.READ)
	if fichier == null:
		return
	var texte := fichier.get_as_text()
	fichier.close()

	# Une instance de JSON et non la fonction statique : celle-ci journalise une
	# erreur du moteur sur un fichier abîmé, alors que le cas est attendu ici.
	var lecteur := JSON.new()
	if lecteur.parse(texte) != OK or not lecteur.data is Dictionary:
		push_warning("Réglages illisibles : les valeurs par défaut s'appliquent.")
		return
	depuis_dict(lecteur.data)


## Sans écriture atomique, contrairement aux personnages : perdre les réglages
## coûte trois clics, perdre un héros coûte des heures. Le fichier temporaire et
## son renommage ne se paient pas ici.
func _ecrire() -> void:
	if _chargement:
		return
	var fichier := FileAccess.open(FICHIER, FileAccess.WRITE)
	if fichier == null:
		push_warning("Réglages non enregistrés : écriture impossible.")
		return
	fichier.store_string(JSON.stringify(vers_dict(), "\t"))
	fichier.close()
