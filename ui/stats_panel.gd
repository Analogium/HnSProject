class_name StatsPanel
extends Control

## La fiche de personnage, à la touche C : un bandeau collé au bord gauche, un
## quart de la largeur sur toute la hauteur, comme dans les jeux dont ce projet
## reprend les règles. Elle ne fait que lire : toutes les valeurs viennent de
## `player.stats`, la copie de travail recalculée à chaque niveau et à chaque
## objet équipé.
##
## Sa taille vient **des ancres de la scène**, jamais d'une constante : posée en
## dur, elle mentirait au premier changement de résolution, et le quart de
## largeur demandé n'aurait plus rien d'un quart.
##
## Elle ne prend la souris **que lorsqu'il reste des points d'attribut à
## placer** — c'est-à-dire seulement quand il y a quelque chose à cliquer. Le
## reste du temps elle est un affichage passif qu'on peut laisser ouvert pendant
## qu'on se bat, pour regarder le mana remonter ou vérifier ce qu'un objet vient
## de changer. Le joueur lit ses attaques par sondage, donc sans ce drapeau un
## clic sur un bouton déclencherait aussi un coup d'épée.
##
## Les libellés viennent de StatMod.LABELS et les valeurs de StatMod.format :
## une statistique doit s'écrire pareil dans l'infobulle d'un affixe et sur la
## fiche, sinon « +8 % vitesse d'attaque » et « 108 % » cesseront un jour de
## parler de la même chose.

## Le panneau prend son cadre dans UiPalette, comme le sac : les deux s'ouvrent
## côte à côte, et deux gris différents se liraient comme un défaut d'affichage.
##
## Seule l'opacité diverge, et le fond est rendu **entièrement opaque** au
## dessin. Le sac est une petite fenêtre posée sur le décor, où 0,97 se lit
## comme de la profondeur ; ce bandeau couvre toute la hauteur de l'écran et
## tombe sur le bandeau de débogage, dont le texte transparaissait au travers.
const BACK := UiPalette.BACK
const BORDER := UiPalette.BORDER
const HINT := UiPalette.HINT
const GROUP := UiPalette.LABEL

const PAD := 6.0
## Interligne et respiration entre groupes. Ils sont resserrés au minimum
## lisible parce que la fiche doit tenir **entière** dans la hauteur du cadrage :
## le groupe des attributs, ajouté après coup, avait fait déborder la dernière
## ligne sur l'aide du bas. C'est `test_la_fiche_tient_dans_sa_hauteur` qui garde
## l'invariant, pas ce commentaire.
const LINE := 10.0
const GROUP_GAP := 5.0
const FONT_SIZE := 8
const TITLE_SIZE := 9
const HEADER := 15.0

const NAME_COLOR := Color(0.72, 0.70, 0.78)
const VALUE_COLOR := Color(0.92, 0.90, 0.96)
## Les points à placer et les boutons qui vont avec. Vert : c'est un gain en
## attente, pas un avertissement.
const POINT_COLOR := Color(0.52, 0.88, 0.48)
const BUTTON_BACK := Color(0.20, 0.30, 0.20)
const BUTTON_HOVER := Color(0.30, 0.46, 0.29)
const BUTTON_W := 11.0
const BUTTON_H := 9.0

## Le coup de référence contre lequel l'armure est annoncée. Une notation nue ne
## veut rien dire — « 40 d'armure » n'apprend rien tant qu'on ne sait pas contre
## quoi. Dix, c'est l'ordre de grandeur d'un coup de grunt.
const ARMOR_REFERENCE_HIT := StatHelp.COUP_LEGER

## La ligne survolée, à peine éclaircie : elle dit quelle statistique l'infobulle
## explique, sans attirer l'œil plus que le texte lui-même.
const SURVOL := Color(1.0, 1.0, 1.0, 0.06)

## L'infobulle des statistiques. Elle s'ouvre **à droite** du panneau, qui est
## collé au bord gauche de l'écran : le seul côté où il y a de la place, et
## jamais par-dessus la ligne qui l'a déclenchée.
const TIP_W := 150.0
const TIP_PAD := 5.0
const TIP_LINE := 9.0
const TIP_GAP := 4.0

## La fiche, dans l'ordre où elle se lit. En données et non en suite d'appels de
## dessin : ajouter une statistique au modèle ne doit demander qu'une ligne ici,
## et l'ordre des groupes se voit d'un coup d'œil au lieu de se reconstituer en
## parcourant _draw.
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
			"attack_damage", "spell_damage", "attack_speed", "cast_speed",
			"attack_range", "crit_chance", "crit_multiplier",
		],
	],
	["DÉPLACEMENT", ["move_speed"]],
]

## La hauteur qu'occupe le contenu, titres et respirations compris. Publique et
## statique : le test qui vérifie que la fiche ne déborde pas ne doit pas avoir à
## recopier ce calcul, sinon il validerait sa propre copie.
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
## Position de la souris dans le repère du panneau, pour surligner le bouton
## survolé. Vector2.INF tant qu'elle n'y est jamais entrée.
var _mouse := Vector2.INF
## Rectangle cliquable par attribut, rempli au dessin. Calculé là plutôt que
## recalculé au clic : une seule définition de l'endroit où se trouve le bouton,
## donc pas de dérive entre ce qu'on voit et ce qu'on touche.
var _boutons := {}
## Rectangle survolable par statistique, rempli au dessin. Même raison que
## `_boutons` : une seule définition de l'endroit où se trouve une ligne, donc
## pas de dérive entre ce qu'on voit et ce qu'on survole.
var _lignes := {}


func _ready() -> void:
	visible = false
	_font = ThemeDB.fallback_font


func bind(player: Player) -> void:
	_player = player
	# Les quatre signaux qui peuvent changer une ligne de la fiche. Ouverte
	# pendant que le mana remonte, elle se redessine donc à chaque image — une
	# vingtaine de chaînes, mesurées comme négligeables, et c'est le prix pour
	# que le compte affiché ne soit jamais en retard sur la réserve réelle.
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


## Le drapeau doit retomber quoi qu'il arrive — y compris si la zone est
## rechargée fiche ouverte, sinon le joueur se retrouve incapable de frapper dans
## une scène où plus aucun panneau n'existe.
func _exit_tree() -> void:
	Game.grab_ui_input(self, false)


## Trois états, et ils ne disent pas la même chose.
##
## **STOP** quand il reste des points : il y a des boutons à cliquer, et le clic
## ne doit pas partir en coup d'épée. **PASS** quand la fiche est simplement
## ouverte : elle reçoit le survol — c'est ce qui fait vivre les infobulles —
## mais laisse passer les clics, donc on peut se battre la fiche ouverte, ce qui
## est tout l'intérêt de pouvoir la laisser ouverte. **IGNORE** fermée.
##
## Le drapeau `ui_grabs_input`, lui, ne suit que le premier cas : le joueur lit
## ses attaques par sondage, et le lever en mode PASS l'empêcherait de frapper.
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
			# Le dernier point placé rend la souris au jeu : il n'y a plus rien à
			# cliquer, et la fiche redevient un affichage qu'on laisse ouvert.
			_saisir_la_souris()
			accept_event()
			return


## Caché, le panneau ne redessine rien : la régénération de mana émet son signal
## soixante fois par seconde, et la fiche est fermée la plupart du temps.
func _refresh() -> void:
	if not visible or _player == null:
		return
	var restants := _points_restants()
	title.text = "PERSONNAGE  —  NIV. %d" % _player.level
	if restants > 0:
		title.text += "  (+%d)" % restants
	queue_redraw()


## La valeur affichée d'une statistique. Quatre d'entre elles disent autre chose
## que leur champ : les deux réserves montrent le courant sur le maximum, et les
## deux notations défensives montrent ce qu'elles valent réellement — une
## notation d'armure nue n'apprend rien à personne.
func _value_of(field: String) -> String:
	var st := _player.stats
	match field:
		"max_health":
			return StatMod.gauge(_player.health, st.max_health)
		"max_mana":
			return StatMod.gauge(_player.mana, st.max_mana)
		"armor":
			return "%d  (%d %%)" % [
				roundi(st.armor),
				roundi(st.armor_reduction(ARMOR_REFERENCE_HIT) * 100.0),
			]
		"evasion":
			return "%d  (%d %%)" % [
				roundi(st.evasion), roundi(st.evade_chance() * 100.0)
			]
	return StatMod.format(field, float(st.get(field)))


func _draw() -> void:
	if _player == null or _font == null:
		return

	draw_rect(Rect2(Vector2.ZERO, size), Color(BACK, 1.0))
	draw_rect(Rect2(Vector2.ZERO, size), BORDER, false, 1.0)

	var restants := _points_restants()
	_boutons.clear()
	_lignes.clear()

	var y := HEADER + PAD
	for g in GROUPS:
		draw_string(
			_font, Vector2(PAD, y + FONT_SIZE), g[0],
			HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, GROUP
		)
		if g[0] == "ATTRIBUTS" and restants > 0:
			draw_string(
				_font, Vector2(PAD, y + FONT_SIZE), "%d à placer" % restants,
				HORIZONTAL_ALIGNMENT_RIGHT, roundi(size.x - PAD * 2.0),
				FONT_SIZE, POINT_COLOR
			)
		y += LINE
		for field in g[1]:
			var bouton: bool = restants > 0 and field in CharacterStats.ATTRIBUTES
			var ligne := Rect2(0.0, y, size.x, LINE)
			_lignes[field] = ligne
			if ligne.has_point(_mouse):
				draw_rect(ligne, SURVOL)
			_draw_row(y, StatMod.LABELS.get(field, field), _value_of(field), bouton)
			if bouton:
				_boutons[field] = _draw_bouton(y)
			y += LINE
		y += GROUP_GAP

	# Remontée au-dessus de la bande où passe la barre d'expérience, qui est
	# dessinée par-dessus le panneau.
	draw_string(
		_font, Vector2(PAD, size.y - FOOTER), "C pour fermer",
		HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, HINT
	)

	# En dernier : l'infobulle déborde du panneau et doit passer par-dessus tout
	# ce qui précède, y compris les lignes voisines.
	_draw_infobulle()


## Ce que fait la statistique survolée, comment elle se calcule quand ce n'est
## pas évident, et ce qu'elle vaut à cet instant.
##
## La fiche annonce « armure 40 (44 %) » : un joueur qui découvre le jeu ne peut
## pas deviner que l'armure protège proportionnellement plus des petits coups,
## ni qu'elle ne couvre pas les éléments. Rien de tout ça ne se lit sur un
## nombre.
func _draw_infobulle() -> void:
	var champ := _survole()
	if champ.is_empty():
		return
	var lignes := StatHelp.lines(champ, _player.stats)
	if lignes.is_empty():
		return

	# Repliées à la largeur du panneau : les explications sont des phrases, pas
	# des valeurs, et une bulle plus large que la fiche sortirait de l'écran.
	var enroulees := PackedStringArray()
	for texte in lignes:
		for morceau in _replier(texte, TIP_W - TIP_PAD * 2.0):
			enroulees.append(morceau)

	var h := TIP_PAD * 2.0 + TIP_LINE * float(enroulees.size() + 1)
	var ancre: Rect2 = _lignes[champ]
	# Posée à droite du panneau — le seul côté libre, la fiche étant collée au
	# bord gauche — et remontée au-dessus du bloc de jauges quand elle
	# descendrait dedans.
	#
	# La limite vient du HUD lui-même et n'est pas réécrite ici : les jauges sont
	# dessinées **après** ce panneau et passeraient par-dessus l'infobulle, dont
	# la deuxième ligne devenait illisible pour les dernières statistiques de la
	# fiche. C'est le genre de chose qu'aucune assertion n'attrape.
	var plancher := size.y - Hud.HEALTH_TOP - Hud.BAR_H - TIP_GAP
	var r := Rect2(
		Vector2(size.x + TIP_GAP, clampf(ancre.position.y, PAD, plancher - h)),
		Vector2(TIP_W, h)
	)

	draw_rect(r, UiPalette.TIP_BACK)
	draw_rect(r, BORDER, false, 1.0)

	var y := r.position.y + TIP_PAD + TIP_LINE - 2.0
	draw_string(
		_font, Vector2(r.position.x + TIP_PAD, y), StatMod.LABELS.get(champ, champ),
		HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_SIZE, VALUE_COLOR
	)
	for texte in enroulees:
		y += TIP_LINE
		draw_string(
			_font, Vector2(r.position.x + TIP_PAD, y), texte,
			HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, NAME_COLOR
		)


## La statistique sous le curseur, vide s'il n'y en a pas. Le survol d'un bouton
## n'en est pas un : on y explique déjà ce qu'on va cliquer.
func _survole() -> String:
	if _mouse == Vector2.INF:
		return ""
	for champ in _lignes:
		if (_lignes[champ] as Rect2).has_point(_mouse) and StatHelp.has(champ):
			return champ
	return ""


## Coupe un texte en lignes qui tiennent dans `largeur`. Aux espaces seulement :
## couper un mot en deux dans une bulle de six mots se lit comme un défaut
## d'affichage.
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


## Le bouton d'ajout, et le rectangle qu'il occupe — c'est ce même rectangle que
## le clic consultera, donc l'endroit dessiné et l'endroit cliquable ne peuvent
## pas diverger.
func _draw_bouton(y: float) -> Rect2:
	var r := Rect2(
		roundf(size.x - PAD - BUTTON_W), roundf(y + (LINE - BUTTON_H) * 0.5),
		BUTTON_W, BUTTON_H
	)
	draw_rect(r, BUTTON_HOVER if r.has_point(_mouse) else BUTTON_BACK)
	draw_rect(r, POINT_COLOR, false, 1.0)
	draw_string(
		_font, Vector2(r.position.x, r.position.y + BUTTON_H - 1.0), "+",
		HORIZONTAL_ALIGNMENT_CENTER, roundi(BUTTON_W), FONT_SIZE, POINT_COLOR
	)
	return r


## Nom à gauche, valeur alignée à droite. L'alignement à droite est ce qui rend
## une colonne de nombres comparable d'un coup d'œil.
func _draw_row(
	y: float, name_text: String, value_text: String, place_un_bouton := false
) -> void:
	var base := y + FONT_SIZE
	draw_string(
		_font, Vector2(PAD, base), name_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, NAME_COLOR
	)
	# La valeur se décale pour laisser la place au bouton, sinon les deux se
	# chevauchent sur les seules lignes où l'on peut cliquer.
	var largeur := size.x - PAD * 2.0
	if place_un_bouton:
		largeur -= BUTTON_W + 3.0
	draw_string(
		_font, Vector2(PAD, base), value_text,
		HORIZONTAL_ALIGNMENT_RIGHT, roundi(largeur), FONT_SIZE, VALUE_COLOR
	)
