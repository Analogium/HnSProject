class_name SelectionPersonnage
extends Control

## L'écran d'accueil : choisir un personnage, en créer un, en supprimer un.
##
## C'est la première scène du jeu, et la seule qui existe avant qu'un
## personnage existe. Elle ne connaît que `Sauvegarde` et `Personnage` — jamais
## la zone, jamais le joueur : elle pose le personnage choisi sur `Game` et
## change de scène.
##
## La silhouette de chaque personnage est **la sienne**, animée, et non une
## vignette générique. La forge dessine déjà les quatre variantes ; voir son
## personnage dans la liste vaut mieux que lire son nom. C'est la génération
## procédurale employée comme règle de jeu, ce que le postulat du projet réclame
## depuis le début.

enum Etat { LISTE, CREATION, SUPPRESSION }

const LIGNE := 34.0
## Cinq lignes visibles : au-delà, la liste défile. Choisi sur la hauteur du
## cadrage (360 px), pas sur un nombre de personnages supposé.
const VISIBLES := 5
const LISTE_W := 340.0
const LISTE_Y := 56.0

## Le cadre de la fenêtre modale, création comme suppression. Les deux se
## dessinent au même endroit : une seule à la fois est visible, et les voir
## apparaître au même point évite de chercher où l'écran a changé.
const MODALE := Rect2(170.0, 74.0, 300.0, 196.0)

const FOND := Color(0.055, 0.051, 0.075)
const NOM_COLOR := Color(0.90, 0.88, 0.95)
const CHOISI := Color(0.20, 0.19, 0.26)
const ACCENT := Color(0.55, 0.75, 1.0)
## Un personnage dont le fichier ne se lit pas. Rouge éteint et non vif : ce
## n'est pas une alerte, c'est une entrée hors service qu'on peut supprimer.
const ABIME := Color(0.72, 0.42, 0.42)

const FONT_SIZE := 8
const NOM_SIZE := 10

## Les quatre vignettes de silhouette de l'écran de création : leur taille, leur
## écartement, et la hauteur de leur centre dans la fenêtre. Nommées parce que
## `_vignette_rect` est le seul à s'en servir et qu'un nombre nu dans un calcul
## de rectangle ne dit pas s'il est une largeur ou une marge.
const VIGNETTE := Vector2(34.0, 36.0)
const VIGNETTE_PAS := 56.0
const VIGNETTE_Y := 104.0

## Ce qu'il faut retaper pour supprimer un personnage dont on n'a pas su lire le
## nom. Les autres se confirment en retapant le leur.
const MOT_SANS_NOM := "SUPPRIMER"

## Le refus d'une saisie. Rouge franc, contrairement au gris d'une entrée
## abîmée : celui-là s'adresse à un geste qu'on vient de faire.
const ERREUR := Color(0.92, 0.45, 0.42)

@onready var titre: Label = $Titre
@onready var aide: Label = $Aide
@onready var message: Label = $Message
@onready var actions: Control = $Actions
@onready var bouton_jouer: Button = $Actions/Jouer
@onready var bouton_nouveau: Button = $Actions/Nouveau
@onready var bouton_supprimer: Button = $Actions/Supprimer

@onready var creation: Control = $Creation
@onready var champ_nom: LineEdit = $Creation/Nom
@onready var erreur_creation: Label = $Creation/Erreur

@onready var suppression: Control = $Suppression
@onready var avertissement: Label = $Suppression/Avertissement
@onready var champ_confirmation: LineEdit = $Suppression/Confirmation
@onready var erreur_suppression: Label = $Suppression/Erreur

@onready var silhouettes: Node2D = $Silhouettes

var _personnages: Array[Personnage] = []
var _index := 0
## Premier personnage affiché : la liste défile quand la sélection sort du cadre.
var _premier := 0
var _etat := Etat.LISTE
var _silhouette := 0
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	# Les couleurs viennent d'ici et non du `.tscn` : une couleur écrite dans une
	# scène est une seconde définition, qui ne suit pas quand la palette bouge.
	titre.add_theme_color_override("font_color", NOM_COLOR)
	aide.add_theme_color_override("font_color", UiPalette.HINT)
	message.add_theme_color_override("font_color", ACCENT)
	($Creation/Titre as Label).add_theme_color_override("font_color", NOM_COLOR)
	($Creation/Silhouette as Label).add_theme_color_override("font_color", UiPalette.HINT)
	avertissement.add_theme_color_override("font_color", NOM_COLOR)
	for etiquette in [erreur_creation, erreur_suppression]:
		etiquette.add_theme_color_override("font_color", ERREUR)

	bouton_jouer.pressed.connect(_jouer)
	bouton_nouveau.pressed.connect(_ouvrir_creation)
	bouton_supprimer.pressed.connect(_ouvrir_suppression)
	($Creation/Creer as Button).pressed.connect(_creer)
	($Creation/Annuler as Button).pressed.connect(_retour_liste)
	($Suppression/Confirmer as Button).pressed.connect(_supprimer)
	($Suppression/Annuler as Button).pressed.connect(_retour_liste)
	champ_nom.text_submitted.connect(func(_t: String) -> void: _creer())
	champ_confirmation.text_submitted.connect(func(_t: String) -> void: _supprimer())

	recharger()


## Publique : c'est aussi le point d'entrée du test, qui pose des personnages
## sur le disque puis demande à l'écran de les relire.
func recharger() -> void:
	_personnages = Sauvegarde.lister()
	_index = clampi(_index, 0, maxi(_personnages.size() - 1, 0))
	_etat = Etat.LISTE
	_rafraichir()


func selection() -> Personnage:
	if _index < 0 or _index >= _personnages.size():
		return null
	return _personnages[_index]


func _unhandled_input(event: InputEvent) -> void:
	var touche := Touches.enfoncee(event)
	if touche == KEY_NONE:
		return

	if _etat != Etat.LISTE:
		if touche == KEY_ESCAPE:
			_retour_liste()
			get_viewport().set_input_as_handled()
		return

	match touche:
		KEY_UP: _deplacer(-1)
		KEY_DOWN: _deplacer(1)
		KEY_ENTER, KEY_KP_ENTER: _jouer()
		KEY_N: _ouvrir_creation()
		KEY_DELETE: _ouvrir_suppression()
		KEY_ESCAPE: get_tree().quit()
		_: return
	get_viewport().set_input_as_handled()


## Clic dans la liste : on choisit la ligne visée. Le double-clic lance la
## partie — c'est le geste attendu d'une liste, et il évite l'aller-retour vers
## le bouton pour l'action qu'on fait neuf fois sur dix.
func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var clic := event as InputEventMouseButton
	if not clic.pressed or clic.button_index != MOUSE_BUTTON_LEFT:
		return

	if _etat == Etat.CREATION:
		_clic_silhouette(clic.position)
		return
	if _etat != Etat.LISTE:
		return

	var cadre := _rect_liste()
	if not cadre.has_point(clic.position):
		return
	var ligne := _premier + int((clic.position.y - cadre.position.y) / LIGNE)
	if ligne < 0 or ligne >= _personnages.size():
		return
	_index = ligne
	if clic.double_click:
		_jouer()
	else:
		_rafraichir()


func _deplacer(pas: int) -> void:
	if _personnages.is_empty():
		return
	_index = clampi(_index + pas, 0, _personnages.size() - 1)
	_rafraichir()


func _jouer() -> void:
	var p := selection()
	if p == null:
		_dire("Aucun personnage. [N] pour en créer un.")
		return
	if p.illisible:
		_dire("Cette sauvegarde ne se lit pas. Son fichier est toujours là.")
		return
	Game.personnage = p
	Game.goto_scene("res://world/zone.tscn")


func _ouvrir_creation() -> void:
	_etat = Etat.CREATION
	_silhouette = 0
	champ_nom.text = ""
	erreur_creation.text = ""
	_dire("")
	_rafraichir()
	champ_nom.grab_focus()


func _creer() -> void:
	var nom := champ_nom.text.strip_edges()
	if not Personnage.nom_valide(nom):
		erreur_creation.text = "Nom vide ou trop long (%d au plus)." % Personnage.NOM_MAX
		return

	var p := Sauvegarde.creer(nom, _silhouette)
	if p == null:
		erreur_creation.text = "Écriture impossible sur le disque."
		return

	recharger()
	# On se place sur le personnage qu'on vient de créer : la liste est triée
	# par date, et retomber sur une autre ligne donnerait l'impression que la
	# création a échoué.
	for i in _personnages.size():
		if _personnages[i].id == p.id:
			_index = i
	_rafraichir()
	_dire("« %s » créé." % p.nom)


func _ouvrir_suppression() -> void:
	var p := selection()
	if p == null:
		return
	_etat = Etat.SUPPRESSION
	champ_confirmation.text = ""
	erreur_suppression.text = ""
	avertissement.text = "\n".join([
		"Supprimer « %s » définitivement ?" % _nom_affiche(p),
		"",
		"Tapez %s pour confirmer." % _mot_a_taper(p),
	])
	_dire("")
	_rafraichir()
	champ_confirmation.grab_focus()


## La confirmation se tape à l'identique, majuscules comprises. C'est agaçant
## exprès : c'est la seule action du jeu qui détruit des heures de jeu, et elle
## est irréversible.
func _supprimer() -> void:
	var p := selection()
	if p == null:
		_retour_liste()
		return
	if champ_confirmation.text.strip_edges() != _mot_a_taper(p):
		erreur_suppression.text = "Ce n'est pas ce qui était demandé."
		return

	var nom := _nom_affiche(p)
	if not Sauvegarde.supprimer(p.id):
		erreur_suppression.text = "Suppression impossible."
		return
	recharger()
	_dire("« %s » supprimé." % nom)


func _retour_liste() -> void:
	_etat = Etat.LISTE
	# Sans ça, le champ garde le clavier et les flèches ne défilent plus la liste.
	champ_nom.release_focus()
	champ_confirmation.release_focus()
	_rafraichir()


func _mot_a_taper(p: Personnage) -> String:
	return p.nom if not p.nom.is_empty() else MOT_SANS_NOM


func _nom_affiche(p: Personnage) -> String:
	if not p.nom.is_empty():
		return p.nom
	return "sauvegarde illisible"


func _dire(texte: String) -> void:
	message.text = texte


func _rect_liste() -> Rect2:
	return Rect2(
		(size.x - LISTE_W) * 0.5, LISTE_Y, LISTE_W, LIGNE * float(VISIBLES)
	)


func _rafraichir() -> void:
	# Le défilement suit la sélection, dans les deux sens.
	_premier = clampi(_premier, maxi(_index - VISIBLES + 1, 0), _index)
	_premier = clampi(_premier, 0, maxi(_personnages.size() - VISIBLES, 0))

	var en_liste := _etat == Etat.LISTE
	actions.visible = en_liste
	aide.visible = en_liste
	creation.visible = _etat == Etat.CREATION
	suppression.visible = _etat == Etat.SUPPRESSION

	var choisi := selection()
	bouton_jouer.disabled = choisi == null or choisi.illisible
	bouton_supprimer.disabled = choisi == null

	titre.text = "PERSONNAGES" if en_liste else ""
	_poser_silhouettes()
	queue_redraw()


## Les sprites sont des nœuds, pas du dessin : ils s'animent tout seuls. Ils
## sont refaits à chaque rafraîchissement plutôt que déplacés — une poignée de
## nœuds, et les planches viennent du cache de la forge, donc la reconstruction
## ne redessine aucun pixel.
func _poser_silhouettes() -> void:
	for enfant in silhouettes.get_children():
		enfant.queue_free()

	if _etat == Etat.CREATION:
		for v in SpriteForge.VARIANTS:
			_silhouette_a(_vignette_rect(v).get_center(), v)
		return

	if _etat != Etat.LISTE:
		return

	var cadre := _rect_liste()
	for i in range(_premier, mini(_premier + VISIBLES, _personnages.size())):
		var p := _personnages[i]
		if p.illisible:
			continue
		_silhouette_a(
			Vector2(cadre.position.x + 24.0, cadre.position.y + LIGNE * float(i - _premier) + LIGNE * 0.5),
			p.silhouette
		)


func _silhouette_a(centre: Vector2, variante: int) -> void:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = SpriteForge.frames("player", posmod(variante, SpriteForge.VARIANTS))
	s.position = centre
	s.play("idle_down")
	silhouettes.add_child(s)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), FOND)

	if _etat == Etat.LISTE:
		_dessiner_liste()
	else:
		draw_rect(MODALE, UiPalette.BACK_PLEIN)
		draw_rect(MODALE, UiPalette.BORDER, false, 1.0)
		if _etat == Etat.CREATION:
			_dessiner_choix_silhouette()


func _dessiner_liste() -> void:
	var cadre := _rect_liste()
	draw_rect(cadre, UiPalette.BACK_PLEIN)
	draw_rect(cadre, UiPalette.BORDER, false, 1.0)

	if _personnages.is_empty():
		draw_string(
			_font, cadre.position + Vector2(0.0, cadre.size.y * 0.5),
			"Aucun personnage pour l'instant.", HORIZONTAL_ALIGNMENT_CENTER,
			cadre.size.x, NOM_SIZE, UiPalette.HINT
		)
		return

	for i in range(_premier, mini(_premier + VISIBLES, _personnages.size())):
		_dessiner_ligne(_personnages[i], cadre, i)

	# La barre de défilement n'apparaît que s'il y a de quoi défiler.
	if _personnages.size() > VISIBLES:
		var haut := cadre.size.y * float(_premier) / float(_personnages.size())
		var hauteur := cadre.size.y * float(VISIBLES) / float(_personnages.size())
		draw_rect(
			Rect2(cadre.end.x - 3.0, cadre.position.y + haut, 2.0, hauteur), UiPalette.BORDER
		)


func _dessiner_ligne(p: Personnage, cadre: Rect2, i: int) -> void:
	var y := cadre.position.y + LIGNE * float(i - _premier)
	var ligne := Rect2(cadre.position.x + 1.0, y + 1.0, cadre.size.x - 2.0, LIGNE - 2.0)

	if i == _index:
		draw_rect(ligne, CHOISI)
		draw_rect(Rect2(ligne.position, Vector2(2.0, ligne.size.y)), ACCENT)

	var x := cadre.position.x + 46.0
	if p.illisible:
		draw_string(
			_font, Vector2(x, y + 16.0), "sauvegarde illisible",
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, NOM_SIZE, ABIME
		)
		draw_string(
			_font, Vector2(x, y + 27.0), p.id,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, UiPalette.HINT
		)
		return

	draw_string(
		_font, Vector2(x, y + 16.0), p.nom,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, NOM_SIZE, NOM_COLOR
	)
	draw_string(
		_font, Vector2(x, y + 27.0), "niveau %d" % p.niveau,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, UiPalette.HINT
	)
	draw_string(
		_font, Vector2(cadre.position.x, y + 27.0), "joué le %s" % p.joue_le,
		HORIZONTAL_ALIGNMENT_RIGHT, cadre.size.x - 10.0, FONT_SIZE, UiPalette.LABEL
	)


## Où se trouve la vignette d'une silhouette, cadre compris.
##
## **Le seul endroit qui le sait.** Trois fonctions recalculaient ce rectangle
## chacune de son côté — celle qui pose le sprite, celle qui dessine le cadre,
## celle qui teste le clic — avec les mêmes six nombres réécrits à la main. Ce
## genre de triplet ne se contredit pas au moment où on l'écrit : il se
## contredit le jour où l'on décale les vignettes de deux pixels et où le clic
## reste sur les anciennes, sans que rien ne le signale.
func _vignette_rect(variante: int) -> Rect2:
	var x0 := MODALE.position.x + MODALE.size.x * 0.5 - VIGNETTE_PAS * 1.5
	return Rect2(
		x0 + VIGNETTE_PAS * float(variante) - VIGNETTE.x * 0.5,
		MODALE.position.y + VIGNETTE_Y - VIGNETTE.y * 0.5,
		VIGNETTE.x, VIGNETTE.y
	)


## Le cadre autour de la silhouette choisie. Les sprites eux-mêmes sont des
## nœuds posés par _poser_silhouettes ; ici on ne dessine que la sélection.
func _dessiner_choix_silhouette() -> void:
	for v in SpriteForge.VARIANTS:
		var boite := _vignette_rect(v)
		draw_rect(boite, CHOISI if v == _silhouette else UiPalette.BACK_PLEIN)
		draw_rect(boite, ACCENT if v == _silhouette else UiPalette.BORDER, false, 1.0)


## Le choix de la silhouette se fait à la souris sur les quatre vignettes.
## Traité ici et non par des boutons : un bouton dessinerait son propre cadre
## par-dessus le sprite.
func _clic_silhouette(position_locale: Vector2) -> void:
	for v in SpriteForge.VARIANTS:
		if _vignette_rect(v).has_point(position_locale):
			_silhouette = v
			_rafraichir()
			return
