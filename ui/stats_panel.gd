class_name StatsPanel
extends Control

## La fiche de personnage (C), collée au bord gauche, qui ne fait que lire. Taille par
## les ancres de la scène. Elle ne prend la souris **que s'il reste des points à
## placer** : sinon un clic frapperait aussi. Libellés et valeurs par `StatMod`.

## Couleurs d'UiPalette, jamais redéfinies : le sac s'ouvre à côté.
const PAD := 6.0
## Resserré au minimum lisible : la fiche tient **entière** dans le cadrage
## (`test_la_fiche_tient_dans_sa_hauteur`).
const LINE := 10.0
const GROUP_GAP := 5.0
const FONT_SIZE := 8
const TITLE_SIZE := 9
const HEADER := 15.0

const NAME_COLOR := Color(0.72, 0.70, 0.78)
const VALUE_COLOR := Color(0.92, 0.90, 0.96)
const BUTTON_BACK := Color(0.20, 0.30, 0.20)
const BUTTON_HOVER := Color(0.30, 0.46, 0.29)
const BUTTON_W := 11.0
const BUTTON_H := 9.0

## Le coup de référence de l'armure, l'ordre d'un coup de grunt.
const ARMOR_REFERENCE_HIT := StatHelp.COUP_LEGER

## La ligne survolée, à peine éclaircie.
const SURVOL := Color(1.0, 1.0, 1.0, 0.06)

## L'infobulle, à **droite** du panneau collé à gauche : le seul côté libre.
const TIP_W := 150.0
const TIP_PAD := 5.0
const TIP_LINE := 9.0
const TIP_GAP := 4.0

## La fiche dans son ordre de lecture, en données : une statistique, une ligne ici.
const GROUPS := [
	["ATTRIBUTS", CharacterStats.ATTRIBUTES],
	["VIE ET RESSOURCE", ["max_health", "health_regen", "max_mana", "mana_regen"]],
	["DÉFENSES", ["armor", "evasion"]],
	[
		"RÉSISTANCES",
		["res_cold", "res_fire", "res_lightning", "res_necrotic", "res_holy"],
	],
	[
		"OFFENSE",
		[
			CompetenceCatalog.ID_ATTAQUE, CompetenceCatalog.ID_TIR,
			"attack_speed", "cast_speed", "attack_range", "crit_chance", "crit_multiplier",
		],
	],
	["DÉPLACEMENT", ["move_speed"]],
]

## Publique et statique : le test de hauteur lit ce calcul sans en garder de copie.
static func content_height() -> float:
	var h := HEADER + PAD
	for g in GROUPS:
		h += LINE * float(1 + (g[1] as Array).size()) + GROUP_GAP
	return h


## Hauteur réservée à la ligne d'aide, en bas.
const FOOTER := 16.0

@onready var title: Label = $Title

var _player: Player
var _font: Font
## Dans le repère du panneau ; INF tant qu'elle n'y est pas entrée.
var _mouse := Vector2.INF
## Remplis au dessin : ce qu'on voit est ce qu'on clique.
var _boutons := {}
var _lignes := {}


func _ready() -> void:
	visible = false
	_font = ThemeDB.fallback_font
	title.add_theme_color_override("font_color", UiPalette.TITRE)


func bind(player: Player) -> void:
	_player = player
	# Mana qui remonte, fiche ouverte : un redessin par image, mesuré négligeable.
	player.equipment_changed.connect(_refresh)
	player.points_changed.connect(func(_n: int) -> void: _refresh())
	player.leveled_up.connect(func(_lvl: int) -> void: _refresh())
	player.health_changed.connect(func(_c: float, _m: float) -> void: _refresh())
	player.mana_changed.connect(func(_c: float, _m: float) -> void: _refresh())
	_refresh()


func toggle() -> void:
	visible = not visible
	_saisir_la_souris()
	_refresh()
	if visible:
		queue_redraw()


## Rend la souris quoi qu'il arrive, même quand la zone est rechargée fiche ouverte.
func _exit_tree() -> void:
	Game.grab_ui_input(self, false)


## Titre et lignes dessinés par le code : à refaire.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_refresh()


## **STOP** avec des points à placer, le clic ne devant pas frapper ; **PASS** ouverte
## (survol et infobulles, clics transmis) ; **IGNORE** fermée. `ui_grabs_input` ne
## suit que STOP.
func _saisir_la_souris() -> void:
	var boutons := visible and _points_restants() > 0
	Game.grab_ui_input(self, boutons)
	if boutons:
		mouse_filter = Control.MOUSE_FILTER_STOP
	elif visible:
		mouse_filter = Control.MOUSE_FILTER_PASS
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not visible:
		_mouse = Vector2.INF


func _points_restants() -> int:
	return 0 if _player == null else _player.unspent_points


func _gui_input(event: InputEvent) -> void:
	var deplacement := event as InputEventMouseMotion
	if deplacement != null:
		_mouse = deplacement.position
		queue_redraw()
		return

	var clic := event as InputEventMouseButton
	if clic == null or not clic.pressed or clic.button_index != MOUSE_BUTTON_LEFT:
		return
	for attribut in _boutons:
		if (_boutons[attribut] as Rect2).has_point(clic.position):
			_player.spend_point(attribut)
			# Le dernier point placé rend la souris au jeu.
			_saisir_la_souris()
			accept_event()
			return


## Caché, rien ne se redessine : le mana émet à chaque image.
func _refresh() -> void:
	if not visible or _player == null:
		return
	var restants := _points_restants()
	title.text = Textes.t("PERSONNAGE  —  NIV. %d") % _player.level
	if restants > 0:
		title.text += "  (+%d)" % restants
	queue_redraw()


## Les réserves en courant sur maximum, les notations défensives en valeur réelle.
func _value_of(field: String) -> String:
	if _est_une_competence(field):
		return _degats_de(field)
	var st := _player.stats
	match field:
		"max_health":
			return StatMod.gauge(_player.health, st.max_health)
		"max_mana":
			return StatMod.gauge(_player.mana, st.max_mana)
		"armor":
			return "%d  (%s)" % [
				roundi(st.armor),
				StatMod.pourcentage(roundi(st.armor_reduction(ARMOR_REFERENCE_HIT) * 100.0)),
			]
		"evasion":
			return "%d  (%s)" % [
				roundi(st.evasion), StatMod.pourcentage(roundi(st.evade_chance() * 100.0))
			]
	return StatMod.format(field, float(st.get(field)))


## Les attaques de départ, qu'aucune page de manuel ne décrit.
static func _est_une_competence(field: String) -> bool:
	return CompetenceCatalog.est_de_depart(field)


## Par le chemin du lancer : lue sur la compétence, la ligne ignorerait l'épée.
func _degats_de(id: String) -> String:
	var geste := _player.resoudre(CompetenceCatalog.by_id(id), _player.points_de_competence(id))
	return StatsDeCompetence.fourchette_lisible(geste.total_min(), geste.total_max())


func _libelle_of(field: String) -> String:
	if _est_une_competence(field):
		return CompetenceCatalog.by_id(field).nom_affiche().to_lower()
	return StatMod.nom(field)


func _draw() -> void:
	if _player == null or _font == null:
		return

	draw_rect(Rect2(Vector2.ZERO, size), UiPalette.BACK_PLEIN)
	draw_rect(Rect2(Vector2.ZERO, size), UiPalette.BORDER, false, 1.0)

	var restants := _points_restants()
	_boutons.clear()
	_lignes.clear()

	var y := HEADER + PAD
	for g in GROUPS:
		draw_string(
			_font, Vector2(PAD, y + FONT_SIZE), Textes.t(g[0]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, UiPalette.LABEL
		)
		# Sur le titre **français**, qui est la clé.
		if g[0] == "ATTRIBUTS" and restants > 0:
			draw_string(
				_font, Vector2(PAD, y + FONT_SIZE), Textes.t("%d à placer") % restants,
				HORIZONTAL_ALIGNMENT_RIGHT, roundi(size.x - PAD * 2.0),
				FONT_SIZE, UiPalette.A_PLACER
			)
		y += LINE
		for field in g[1]:
			var bouton: bool = restants > 0 and field in CharacterStats.ATTRIBUTES
			var ligne := Rect2(0.0, y, size.x, LINE)
			_lignes[field] = ligne
			if ligne.has_point(_mouse):
				draw_rect(ligne, SURVOL)
			_draw_row(y, _libelle_of(field), _value_of(field), bouton)
			if bouton:
				_boutons[field] = _draw_bouton(y)
			y += LINE
		y += GROUP_GAP

	# Au-dessus de la barre d'expérience, dessinée par-dessus.
	draw_string(
		_font, Vector2(PAD, size.y - FOOTER), Textes.t("C pour fermer"),
		HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, UiPalette.HINT
	)

	# En dernier : l'infobulle passe par-dessus tout.
	_draw_infobulle()


## Ce que fait la statistique survolée, et ce qu'elle vaut maintenant.
func _draw_infobulle() -> void:
	var champ := _survole()
	if champ.is_empty():
		return
	var lignes := StatHelp.lines(champ, _player.stats)
	if lignes.is_empty():
		return

	# Repliées à la largeur du panneau.
	var enroulees := PackedStringArray()
	for texte in lignes:
		for morceau in _replier(texte, TIP_W - TIP_PAD * 2.0):
			enroulees.append(morceau)

	var h := TIP_PAD * 2.0 + TIP_LINE * float(enroulees.size() + 1)
	var ancre: Rect2 = _lignes[champ]
	# À droite, au-dessus des jauges du HUD, dessinées après ce panneau.
	var plancher := Hud.haut_des_jauges(size.y) - TIP_GAP
	var r := Rect2(
		Vector2(size.x + TIP_GAP, clampf(ancre.position.y, PAD, plancher - h)),
		Vector2(TIP_W, h)
	)

	draw_rect(r, UiPalette.TIP_BACK)
	draw_rect(r, UiPalette.BORDER, false, 1.0)

	var y := r.position.y + TIP_PAD + TIP_LINE - 2.0
	draw_string(
		_font, Vector2(r.position.x + TIP_PAD, y), _libelle_of(champ),
		HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_SIZE, VALUE_COLOR
	)
	for texte in enroulees:
		y += TIP_LINE
		draw_string(
			_font, Vector2(r.position.x + TIP_PAD, y), texte,
			HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, NAME_COLOR
		)


## La statistique sous le curseur ; un bouton survolé n'en est pas une.
func _survole() -> String:
	if _mouse == Vector2.INF:
		return ""
	for champ in _lignes:
		if (_lignes[champ] as Rect2).has_point(_mouse) and StatHelp.has(champ):
			return champ
	return ""


## Coupe un texte en lignes qui tiennent dans `largeur`, aux espaces seulement.
func _replier(texte: String, largeur: float) -> PackedStringArray:
	var out := PackedStringArray()
	var courante := ""
	for mot in texte.split(" ", false):
		var essai := mot if courante.is_empty() else courante + " " + mot
		if _font.get_string_size(essai, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x > largeur:
			if not courante.is_empty():
				out.append(courante)
			courante = mot
		else:
			courante = essai
	if not courante.is_empty():
		out.append(courante)
	return out


## Le bouton et son rectangle, celui que le clic consultera.
func _draw_bouton(y: float) -> Rect2:
	var r := Rect2(
		roundf(size.x - PAD - BUTTON_W), roundf(y + (LINE - BUTTON_H) * 0.5),
		BUTTON_W, BUTTON_H
	)
	draw_rect(r, BUTTON_HOVER if r.has_point(_mouse) else BUTTON_BACK)
	draw_rect(r, UiPalette.A_PLACER, false, 1.0)
	draw_string(
		_font, Vector2(r.position.x, r.position.y + BUTTON_H - 1.0), "+",
		HORIZONTAL_ALIGNMENT_CENTER, roundi(BUTTON_W), FONT_SIZE, UiPalette.A_PLACER
	)
	return r


## Nom à gauche, valeur à droite : une colonne se compare d'un coup d'œil.
func _draw_row(
	y: float, name_text: String, value_text: String, place_un_bouton := false
) -> void:
	var base := y + FONT_SIZE
	draw_string(
		_font, Vector2(PAD, base), name_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, NAME_COLOR
	)
	# La valeur laisse la place au bouton.
	var largeur := size.x - PAD * 2.0
	if place_un_bouton:
		largeur -= BUTTON_W + 3.0
	draw_string(
		_font, Vector2(PAD, base), value_text,
		HORIZONTAL_ALIGNMENT_RIGHT, roundi(largeur), FONT_SIZE, VALUE_COLOR
	)
