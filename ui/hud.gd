class_name Hud
extends Control

## Le HUD : vie, mana, niveau et expérience, branché par signal et dessiné à la main,
## textes compris.

const MARGIN := 12.0
const HEIGHT := 3.0
const BOTTOM := 8.0

## Les jauges, **centrées** : ni la fiche, à gauche, ni le sac, en bas à droite, ne
## passent devant.
const BAR_W := 104.0
## Fixe : une largeur qui suivrait le texte ferait glisser les jauges à chaque coup.
const VALUE_W := 48.0
const BAR_H := 7.0
const HEALTH_TOP := 52.0   # depuis le bas
const MANA_TOP := 42.0
const VALUE_SIZE := 8

## Fond propre au HUD, plus opaque ; le **liseré** vient de la barre du monde, pour
## qu'il n'y en ait qu'un.
const BACK := Color(0.06, 0.05, 0.08, 0.90)
const EDGE := HealthBar.EDGE
## Le bleu de la tunique du joueur ; l'or reste aux critiques et aux élites.
const FILL := Color(0.24, 0.45, 0.86)
const FLASH := Color(1.0, 0.94, 0.76)
const FLASH_TIME := 0.45

## Bleu-vert : loin du bleu de l'expérience et du cyan du froid.
const MANA_FILL := Color(0.28, 0.66, 0.88)
## Les couleurs de la barre du monde : même information, même seuil rouge.
const HEALTH_FULL := HealthBar.FULL
const HEALTH_LOW := HealthBar.LOW

const LABEL_COLOR := Color(0.86, 0.84, 0.90)

## Les points d'arbre non placés, une ligne au-dessus du niveau. L'or des choses à
## faire : rien d'autre dans le HUD ne demande une action.
const POINTS_TOP := HEALTH_TOP + 10.0
const POINTS_COLOR := Color(1.0, 0.82, 0.35)

## Les gestes entretenus allumés, **à gauche des jauges** : la bande y est déjà réservée
## aux fenêtres flottantes (`gauges_top`), donc rien n'a à reculer pour eux. Le cadre
## fait `SkillIcon.SIDE` : en dessous, le facteur entier ne réduit pas et l'icône
## déborderait.
const BUFF_SIDE := float(SkillIcon.SIDE)
const BUFF_GAP := 4.0
## Ce qu'il reste d'un buff à durée, en voile descendant — celui de la barre.
const BUFF_SPENT := Color(0.02, 0.02, 0.04, 0.62)

var _player: Player
var _points_left := 0
var _ratio := 0.0
var _level := 1
var _xp := 0
var _xp_needed := 0
var _flash := 0.0
var _health := 0.0
var _health_max := 0.0
var _mana := 0.0
var _mana_max := 0.0
## Relus à chaque image tant qu'il y en a : un voile de durée descend, et une aura
## s'éteint sans que rien ne le dise.
var _lit: Array[Skill] = []
var _font: Font


## La borne basse de toute fenêtre flottante : le HUD, dessiné après les panneaux,
## passerait par-dessus. « Niv. » et l'indicateur de points compris — il monte d'une
## ligne, et une infobulle qui le couvrirait cacherait la seule chose à faire.
static func gauges_top(height: float) -> float:
	return height - POINTS_TOP - BAR_H


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	set_process(false)


## Dessiné à la main et repeint seulement aux signaux : à redessiner.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()


## Appelée par la scène, qui est la seule à connaître les deux nœuds.
func bind(player: Player) -> void:
	_player = player
	player.passives_changed.connect(_refresh_points)
	player.xp_changed.connect(_on_xp_changed)
	player.leveled_up.connect(_on_leveled_up)
	player.health_changed.connect(_on_health_changed)
	player.mana_changed.connect(_on_mana_changed)
	player.buffs_changed.connect(_on_buffs_changed)
	_on_xp_changed(player.xp, player.xp_to_next, player.level)
	_on_health_changed(player.health, player.stats.max_health)
	_on_mana_changed(player.mana, player.stats.max_mana)


func _on_health_changed(current: float, maximum: float) -> void:
	_health = current
	_health_max = maximum
	queue_redraw()


func _on_mana_changed(current: float, maximum: float) -> void:
	_mana = current
	_mana_max = maximum
	queue_redraw()


func _on_xp_changed(current: int, needed: int, level: int) -> void:
	_ratio = StatMod.ratio(float(current), float(needed))
	_xp = current
	_xp_needed = needed
	_level = level
	# Un niveau de plus est un point de plus : le compte se refait ici aussi.
	_refresh_points()


## Le compte reste chez `PassiveTree` : le HUD le lit, il ne le refait pas.
func _refresh_points() -> void:
	if _player != null:
		_points_left = PassiveTree.remaining_points(_player.passives, _player.level)
	queue_redraw()


func _on_leveled_up(_level: int) -> void:
	_flash = FLASH_TIME
	set_process(true)


## Un geste entretenu s'est allumé ou éteint : la liste change, et l'image doit suivre
## tant qu'il en reste un.
func _on_buffs_changed() -> void:
	_lit = _player.lit_skills()
	if not _lit.is_empty():
		set_process(true)
	queue_redraw()


## Ne tourne que pendant l'éclat de montée de niveau et tant qu'un geste brûle.
func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(_flash - delta, 0.0)
	_lit = _player.lit_skills()
	if _flash <= 0.0 and _lit.is_empty():
		set_process(false)
	queue_redraw()


func _draw() -> void:
	var w := roundf(size.x - MARGIN * 2.0)
	var x := roundf(MARGIN)
	if w <= 0.0:
		return

	var fill := FILL
	if _flash > 0.0:
		fill = FILL.lerp(FLASH, _flash / FLASH_TIME)
	_draw_bar(Rect2(x, roundf(size.y - BOTTOM - HEIGHT), w, HEIGHT), _ratio, fill)

	# Barre et compte centrés d'un bloc.
	var gx := _gauges_x()
	var health_ratio := StatMod.ratio(_health, _health_max)
	_draw_gauge(
		gx,
		roundf(size.y - HEALTH_TOP),
		health_ratio,
		HEALTH_LOW if health_ratio <= HealthBar.LOW_RATIO else HEALTH_FULL,
		_health,
		_health_max
	)
	# Une réserve nulle ne s'affiche pas.
	if _mana_max > 0.0:
		_draw_gauge(
			gx, roundf(size.y - MANA_TOP), StatMod.ratio(_mana, _mana_max),
			MANA_FILL, _mana, _mana_max
		)

	_draw_buffs()

	if _font == null:
		return
	# Le niveau coiffe vie et mana : un seul regard.
	_text(Vector2(gx, roundf(size.y - HEALTH_TOP - 3.0)), Texts.t("Niv. %d") % _level,
		HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_COLOR)
	# Le pluriel par la traduction, comme la page du manuel. Un texte à lui : « points
	# à placer » y désigne déjà ceux d'un manuel.
	if _points_left > 0:
		_text(
			Vector2(gx, roundf(size.y - POINTS_TOP - 3.0)),
			Texts.tn(
				"{points} point d'arbre (P pour ouvrir)", "{points} points d'arbre (P pour ouvrir)", _points_left
			).format({"points": _points_left}),
			HORIZONTAL_ALIGNMENT_LEFT, -1, POINTS_COLOR
		)
	# Le compte d'expérience au centre, la seule bande que ni la barre de compétences ni
	# la fiche ne couvrent.
	_text(
		Vector2(roundf(MARGIN), roundf(size.y - BOTTOM - HEIGHT - 3.0)),
		Texts.t("{courant} exp / {total} exp").format({"courant": _xp, "total": _xp_needed})
			if _xp_needed > 0 else Texts.t("niveau maximal"),
		HORIZONTAL_ALIGNMENT_CENTER, roundi(w), LABEL_COLOR
	)


## Les gestes entretenus, de la droite vers la gauche à partir du bord des jauges : le
## dernier allumé s'ajoute à gauche, et les autres ne bougent pas. Centrés sur le bloc
## des deux jauges, qu'aucun ne dépasse vers le bas.
func _draw_buffs() -> void:
	for i in _lit.size():
		var skill := _lit[i]
		var r := _buff_rect(i)
		draw_rect(r, BACK)
		SkillIcon.draw_into(self, r, skill)
		# Ce qu'il reste descend comme le voile de recharge de la barre ; un geste qu'on
		# entretient n'en a pas, et son cadre le dit déjà.
		var left := _player.lit_ratio(skill.id)
		if left < 1.0:
			draw_rect(
				Rect2(r.position, Vector2(BUFF_SIDE, roundf(BUFF_SIDE * (1.0 - left)))),
				BUFF_SPENT
			)
		draw_rect(r, DamageType.COLORS[skill.nature].lerp(Color.WHITE, 0.3), false, 1.0)


## L'abscisse du bloc des jauges : le niveau, les deux barres et les gestes allumés s'y
## accrochent.
func _gauges_x() -> float:
	return roundf((size.x - (BAR_W + 5.0 + VALUE_W)) * 0.5)


## Le cadre du ième geste allumé. **La fonction du dessin** : un test qui recopierait le
## calcul validerait sa propre copie.
func _buff_rect(index: int) -> Rect2:
	return Rect2(
		roundf(_gauges_x() - float(index + 1) * (BUFF_SIDE + BUFF_GAP)),
		roundf((size.y - HEALTH_TOP + size.y - MANA_TOP + BAR_H - BUFF_SIDE) * 0.5),
		BUFF_SIDE, BUFF_SIDE
	)


## Le cadre, le fond, le remplissage : écrits une fois pour les trois barres.
func _draw_bar(r: Rect2, ratio: float, fill: Color) -> void:
	draw_rect(Rect2(r.position - Vector2.ONE, r.size + Vector2(2.0, 2.0)), EDGE)
	draw_rect(r, BACK)
	draw_rect(Rect2(r.position, Vector2(roundf(r.size.x * ratio), r.size.y)), fill)


## La barre et le compte en clair : « de quoi tirer deux fois » ne se lit pas sur une
## longueur.
func _draw_gauge(
	x: float, y: float, ratio: float, fill: Color, current: float, maximum: float
) -> void:
	_draw_bar(Rect2(x, y, BAR_W, BAR_H), ratio, fill)
	if _font == null:
		return
	_text(
		Vector2(roundf(x + BAR_W + 5.0), roundf(y + BAR_H - 1.0)),
		StatMod.gauge(current, maximum),
		HORIZONTAL_ALIGNMENT_LEFT, -1, fill
	)


## Cerné de noir : lisible sur tous les sols.
func _text(
	pos: Vector2, text: String, align: int, width: int, tint: Color
) -> void:
	draw_string_outline(
		_font, pos, text, align, width, VALUE_SIZE, 1, Color(0, 0, 0, 1)
	)
	draw_string(_font, pos, text, align, width, VALUE_SIZE, tint)
