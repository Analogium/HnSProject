extends Node

## Les réglages du joueur — `Game` porte la partie —, écrits sur le disque. Par
## signal : trois cents barres de vie n'ont pas à relire le réglage à chaque image.

signal changed

## Distinct des personnages : ces réglages valent pour la machine.
const FICHIER := "user://reglages.json"

## Ce que « plein écran » vaut dans `echelle`.
const PLEIN_ECRAN := 0

## Le français est la langue source : ses textes sont les clés, l'anglais vit dans
## `i18n/en.po`.
const FRANCAIS := "fr"
const ANGLAIS := "en"

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

## Deux cases : ce que subit le joueur, brûlures comprises, et ce que subissent
## les ennemis.
var degats_subis_visibles := true:
	set(value):
		if value == degats_subis_visibles:
			return
		degats_subis_visibles = value
		changed.emit()
		_ecrire()

var degats_infliges_visibles := true:
	set(value):
		if value == degats_infliges_visibles:
			return
		degats_infliges_visibles = value
		changed.emit()
		_ecrire()


## Le choix entre les deux cases, ici et nulle part ailleurs.
func montre_les_degats(sur_le_joueur: bool) -> bool:
	return degats_subis_visibles if sur_le_joueur else degats_infliges_visibles

## « fr » ou « en », toujours normalisée. La poser change la locale du moteur, qui
## retraduit les scènes et notifie les panneaux dessinés.
var langue := FRANCAIS:
	set(value):
		var choisie := normaliser(value)
		if choisie == langue:
			return
		langue = choisie
		TranslationServer.set_locale(langue)
		changed.emit()
		_ecrire()

## Le facteur de la fenêtre, ou PLEIN_ECRAN. Le jeu remplit toujours la fenêtre
## (échelle fractionnaire) : ces facteurs sont des raccourcis vers les tailles
## nettes. Pas de signal `changed` : rien n'a à y réagir.
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

## Pendant la lecture : sans lui, chaque champ relu réécrirait le fichier.
var _chargement := false


## **On n'impose la taille que si le joueur l'a choisie** : sans fichier, on lit le
## facteur de la fenêtre en place (le cadre de l'éditeur a son propre sélecteur).
## La langue suit la même règle, posée sans écrire : un premier lancement ne doit
## pas créer un fichier qui ferait passer les défauts pour un choix.
func _ready() -> void:
	var choisie := FileAccess.file_exists(FICHIER)

	_chargement = true
	langue = normaliser(TranslationServer.get_locale())
	_chargement = false
	_charger()

	# Toujours : le moteur doit tourner sur « fr » ou « en », jamais sur « fr_CA ».
	TranslationServer.set_locale(langue)

	if choisie:
		_appliquer()
		return

	_chargement = true
	echelle = echelle_observee()
	_chargement = false


# --------------------------------------------------------------------------
# La langue
# --------------------------------------------------------------------------

## Ce qui commence par « fr » donne le français, le reste l'anglais : un système
## allemand afficherait sinon les clés. Statique, pour que le test ne dépende pas
## de la machine.
static func normaliser(locale: String) -> String:
	return FRANCAIS if locale.to_lower().begins_with(FRANCAIS) else ANGLAIS


## La langue en cours écrite dans cette langue, jamais traduite : un joueur perdu
## doit reconnaître la sienne.
const LIBELLES_DE_LANGUE := {
	FRANCAIS: "Langue : Français",
	ANGLAIS: "Language: English",
}


static func libelle_de_langue(valeur: String) -> String:
	return LIBELLES_DE_LANGUE.get(normaliser(valeur), "")


func libelle_de_langue_courante() -> String:
	return libelle_de_langue(langue)


## Écrite comme une ronde : une troisième langue ne touchera pas aux boutons.
static func langue_suivante(courante: String) -> String:
	return ANGLAIS if normaliser(courante) == FRANCAIS else FRANCAIS


## Appelée par les options et par l'écran des personnages.
func cycler_langue() -> void:
	langue = langue_suivante(langue)


# --------------------------------------------------------------------------
# La taille de la fenêtre
# --------------------------------------------------------------------------

## Lue dans les réglages du projet, jamais recopiée.
static func taille_de_base() -> Vector2i:
	return Vector2i(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", 640)),
		int(ProjectSettings.get_setting("display/window/size/viewport_height", 360))
	)


## Au moins 1, même sur un écran plus petit que le cadrage. Statique, pour le test.
static func echelle_qui_tient(ecran: Vector2i, base: Vector2i) -> int:
	if base.x <= 0 or base.y <= 0:
		return 1
	return maxi(mini(ecran.x / base.x, ecran.y / base.y), 1)


## Arrondi vers le bas, par la même formule que l'écran.
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


## 1, 2, … maximum, plein écran, puis 1 : on sort du plein écran en continuant.
static func echelle_suivante(courante: int, maximum: int) -> int:
	if courante == PLEIN_ECRAN:
		return 1
	if courante >= maximum:
		return PLEIN_ECRAN
	return courante + 1


## Le texte du bouton des options.
static func libelle(valeur: int, base: Vector2i) -> String:
	if valeur == PLEIN_ECRAN:
		return Textes.t("Fenêtre : plein écran")
	return Textes.t("Fenêtre : ×{facteur}  ({largeur} × {hauteur})").format({
		"facteur": valeur, "largeur": base.x * valeur, "hauteur": base.y * valeur
	})


func libelle_courant() -> String:
	return libelle(echelle, taille_de_base())


## Passe au réglage suivant. Appelée par le menu des options.
func cycler_echelle() -> void:
	echelle = echelle_suivante(echelle, echelle_maximale())


## Recentrée : agrandie depuis son coin, elle sortirait par le bas.
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

## Un dictionnaire nommé : un réglage ajouté ne décale pas les autres.
func vers_dict() -> Dictionary:
	return {
		"barres_de_vie": show_health_bars,
		"noms_d_affixes": show_affix_names,
		"degats_subis": degats_subis_visibles,
		"degats_infliges": degats_infliges_visibles,
		"langue": langue,
		"echelle": echelle,
	}


## Un champ absent garde son défaut : un fichier plus ancien sert encore.
func depuis_dict(source: Dictionary) -> void:
	_chargement = true
	show_health_bars = bool(source.get("barres_de_vie", show_health_bars))
	show_affix_names = bool(source.get("noms_d_affixes", show_affix_names))
	degats_subis_visibles = bool(source.get("degats_subis", degats_subis_visibles))
	degats_infliges_visibles = bool(source.get("degats_infliges", degats_infliges_visibles))
	# Normalisée par le setter : un fichier écrit à la main peut dire « de ».
	langue = String(source.get("langue", langue))
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


## Sans écriture atomique, contrairement aux personnages : perdre les réglages coûte
## trois clics.
func _ecrire() -> void:
	if _chargement:
		return
	var fichier := FileAccess.open(FICHIER, FileAccess.WRITE)
	if fichier == null:
		push_warning("Réglages non enregistrés : écriture impossible.")
		return
	fichier.store_string(JSON.stringify(vers_dict(), "\t"))
	fichier.close()
