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
## Elle **ne prend pas la souris**, contrairement au sac : il n'y a rien à
## cliquer, et on doit pouvoir la laisser ouverte pour regarder le mana remonter
## ou vérifier ce qu'un objet vient de changer.
##
## Les libellés viennent de StatMod.LABELS et les valeurs de StatMod.format :
## une statistique doit s'écrire pareil dans l'infobulle d'un affixe et sur la
## fiche, sinon « +8 % vitesse d'attaque » et « 108 % » cesseront un jour de
## parler de la même chose.

## Le panneau reprend le cadre du sac plutôt que d'en définir un second : les
## deux s'ouvrent côte à côte, et deux gris différents se liraient comme un
## défaut d'affichage. Le jour où un troisième panneau arrive, cette palette
## méritera son propre fichier — à deux, elle ne le paie pas.
##
## Seule l'opacité diverge, et le fond est rendu **entièrement opaque** au
## dessin. Le sac est une petite fenêtre posée sur le décor, où 0,97 se lit
## comme de la profondeur ; ce bandeau couvre toute la hauteur de l'écran et
## tombe sur le bandeau de débogage, dont le texte transparaissait au travers.
const BACK := InventoryPanel.BACK
const BORDER := InventoryPanel.BORDER
const HINT := InventoryPanel.HINT
const GROUP := InventoryPanel.EQUIP_LABEL

const PAD := 6.0
## Interligne et respiration entre groupes. Réglés pour que les cinq groupes —
## 19 lignes et 5 titres — tiennent dans les 360 px de haut du cadrage avec de
## la marge : 315 px de contenu, le reste sépare la dernière ligne de l'aide.
const LINE := 11.0
const GROUP_GAP := 7.0
const FONT_SIZE := 8
const TITLE_SIZE := 9
const HEADER := 15.0

const NAME_COLOR := Color(0.72, 0.70, 0.78)
const VALUE_COLOR := Color(0.92, 0.90, 0.96)

## Le coup de référence contre lequel l'armure est annoncée. Une notation nue ne
## veut rien dire — « 40 d'armure » n'apprend rien tant qu'on ne sait pas contre
## quoi. Dix, c'est l'ordre de grandeur d'un coup de grunt.
const ARMOR_REFERENCE_HIT := 10.0

## La fiche, dans l'ordre où elle se lit. En données et non en suite d'appels de
## dessin : ajouter une statistique au modèle ne doit demander qu'une ligne ici,
## et l'ordre des groupes se voit d'un coup d'œil au lieu de se reconstituer en
## parcourant _draw.
const GROUPS := [
	["VIE ET RESSOURCE", ["max_health", "health_regen", "max_mana", "mana_regen"]],
	["DÉFENSES", ["armor", "evasion"]],
	[
		"RÉSISTANCES",
		["res_cold", "res_fire", "res_lightning", "res_necrotic", "res_holy"],
	],
	[
		"OFFENSE",
		[
			"attack_damage", "attack_speed", "cast_speed", "attack_range",
			"crit_chance", "crit_multiplier",
		],
	],
	["DÉPLACEMENT", ["move_speed"]],
]

@onready var title: Label = $Title

var _player: Player
var _font: Font


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
	player.leveled_up.connect(func(_lvl: int) -> void: _refresh())
	player.health_changed.connect(func(_c: float, _m: float) -> void: _refresh())
	player.mana_changed.connect(func(_c: float, _m: float) -> void: _refresh())
	_refresh()


func toggle() -> void:
	visible = not visible
	_refresh()


## Caché, le panneau ne redessine rien : la régénération de mana émet son signal
## soixante fois par seconde, et la fiche est fermée la plupart du temps.
func _refresh() -> void:
	if not visible or _player == null:
		return
	title.text = "PERSONNAGE  —  NIV. %d" % _player.level
	queue_redraw()


## La valeur affichée d'une statistique. Quatre d'entre elles disent autre chose
## que leur champ : les deux réserves montrent le courant sur le maximum, et les
## deux notations défensives montrent ce qu'elles valent réellement — une
## notation d'armure nue n'apprend rien à personne.
func _value_of(field: String) -> String:
	var st := _player.stats
	match field:
		"max_health":
			return "%d / %d" % [ceili(_player.health), roundi(st.max_health)]
		"max_mana":
			return "%d / %d" % [ceili(_player.mana), roundi(st.max_mana)]
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

	var y := HEADER + PAD
	for g in GROUPS:
		draw_string(
			_font, Vector2(PAD, y + FONT_SIZE), g[0],
			HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, GROUP
		)
		y += LINE
		for field in g[1]:
			_draw_row(y, StatMod.LABELS.get(field, field), _value_of(field))
			y += LINE
		y += GROUP_GAP

	# Remontée au-dessus de la bande où passe la barre d'expérience, qui est
	# dessinée par-dessus le panneau.
	draw_string(
		_font, Vector2(PAD, size.y - 16.0), "C pour fermer",
		HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, HINT
	)


## Nom à gauche, valeur alignée à droite. L'alignement à droite est ce qui rend
## une colonne de nombres comparable d'un coup d'œil.
func _draw_row(y: float, name_text: String, value_text: String) -> void:
	var base := y + FONT_SIZE
	draw_string(
		_font, Vector2(PAD, base), name_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, NAME_COLOR
	)
	draw_string(
		_font, Vector2(PAD, base), value_text,
		HORIZONTAL_ALIGNMENT_RIGHT, roundi(size.x - PAD * 2.0), FONT_SIZE, VALUE_COLOR
	)
