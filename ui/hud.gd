class_name Hud
extends Control

## L'affichage tête haute : la vie, le mana, le niveau et la progression vers le
## suivant.
##
## Branché par signal et non par lecture à chaque image — la barre ne bouge
## qu'aux morts d'ennemis, soit quelques fois par seconde au plus fort d'un
## combat, contre soixante lectures par seconde en interrogeant le joueur.
##
## Tout est dessiné à la volée, textes compris. Les deux Label posés dans la
## scène ont disparu : le HUD dessinait déjà ses jauges et leurs comptes à la
## main, et deux mécanismes de texte dans le même fichier obligeaient à rouvrir
## l'éditeur pour déplacer une ligne d'un pixel.

const MARGIN := 12.0
const HEIGHT := 3.0
const BOTTOM := 8.0

## Les deux jauges de ressource, empilées au-dessus de la ligne d'expérience et
## **centrées**. Elles étaient à gauche ; la fiche de personnage occupe désormais
## le quart gauche de l'écran sur toute sa hauteur et les recouvrait. Au centre,
## ni elle ni le sac — qui tient le bas-droite — ne passe devant, quel que soit
## ce qui est ouvert.
const BAR_W := 104.0
## Largeur réservée au compte en clair. Fixe et non mesurée : le texte change à
## chaque coup reçu, et une largeur qui suit le texte ferait glisser les deux
## jauges horizontalement à chaque point de vie perdu.
const VALUE_W := 48.0
const BAR_H := 7.0
const HEALTH_TOP := 52.0   # depuis le bas
const MANA_TOP := 42.0
const VALUE_SIZE := 8

const BACK := Color(0.06, 0.05, 0.08, 0.90)
const EDGE := Color(0.02, 0.02, 0.03, 0.95)
## Le bleu du joueur, celui de sa tunique : la barre est sa progression à lui.
## L'or reste réservé aux critiques et aux élites.
const FILL := Color(0.24, 0.45, 0.86)
const FLASH := Color(1.0, 0.94, 0.76)
const FLASH_TIME := 0.45

## Le mana en bleu-vert : assez loin du bleu de l'expérience, qui est la barre
## juste en dessous, et assez loin du cyan du froid pour qu'une jauge et un
## dégât ne se confondent pas.
const MANA_FILL := Color(0.28, 0.66, 0.88)
## La vie reprend les couleurs de la barre du monde plutôt que d'en définir des
## siennes : c'est la même information, elle doit avoir la même couleur, et le
## seuil rouge doit basculer au même moment aux deux endroits.
const HEALTH_FULL := HealthBar.FULL
const HEALTH_LOW := HealthBar.LOW

const LABEL_COLOR := Color(0.86, 0.84, 0.90)

var _ratio := 0.0
var _level := 1
var _xp := 0
var _xp_needed := 0
var _flash := 0.0
var _health := 0.0
var _health_max := 0.0
var _mana := 0.0
var _mana_max := 0.0
var _font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	set_process(false)


## Appelée par la scène, qui est la seule à connaître les deux nœuds.
func bind(player: Player) -> void:
	player.xp_changed.connect(_on_xp_changed)
	player.leveled_up.connect(_on_leveled_up)
	player.health_changed.connect(_on_health_changed)
	player.mana_changed.connect(_on_mana_changed)
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
	_ratio = 0.0 if needed <= 0 else clampf(float(current) / float(needed), 0.0, 1.0)
	_xp = current
	_xp_needed = needed
	_level = level
	queue_redraw()


func _on_leveled_up(_level: int) -> void:
	_flash = FLASH_TIME
	set_process(true)


## Ne tourne que pendant l'éclat de montée de niveau, puis s'éteint.
func _process(delta: float) -> void:
	_flash -= delta
	if _flash <= 0.0:
		_flash = 0.0
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

	# La barre et son compte sont centrés d'un bloc, pas la barre seule : sinon
	# l'ensemble paraîtrait décalé vers la droite de la moitié du texte.
	var gx := roundf((size.x - (BAR_W + 5.0 + VALUE_W)) * 0.5)
	var health_ratio := _ratio_of(_health, _health_max)
	_draw_gauge(
		gx,
		roundf(size.y - HEALTH_TOP),
		health_ratio,
		HEALTH_LOW if health_ratio <= HealthBar.LOW_RATIO else HEALTH_FULL,
		_health,
		_health_max
	)
	# Une réserve nulle ne s'affiche pas du tout : une jauge vide en permanence
	# annoncerait une ressource que ce personnage n'a pas.
	if _mana_max > 0.0:
		_draw_gauge(
			gx, roundf(size.y - MANA_TOP), _ratio_of(_mana, _mana_max),
			MANA_FILL, _mana, _mana_max
		)

	if _font == null:
		return
	# Le niveau coiffe le bloc de ressources : niveau, vie et mana sont ce qu'on
	# consulte du coin de l'œil, ils doivent tenir dans un seul regard.
	_text(Vector2(gx, roundf(size.y - HEALTH_TOP - 3.0)), "Niv. %d" % _level,
		HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_COLOR)
	# Le compte exact reste au bord droit, au-dessus de sa propre barre.
	_text(
		Vector2(roundf(MARGIN), roundf(size.y - BOTTOM - HEIGHT - 3.0)),
		"%d exp / %d exp" % [_xp, _xp_needed],
		HORIZONTAL_ALIGNMENT_RIGHT, roundi(w), LABEL_COLOR
	)


static func _ratio_of(current: float, maximum: float) -> float:
	return 0.0 if maximum <= 0.0 else clampf(current / maximum, 0.0, 1.0)


## Le cadre, le fond, le remplissage. Les trois barres de l'écran l'appellent :
## écrits à la main trois fois, un ajustement d'un pixel n'aurait été reporté
## que sur deux d'entre elles.
func _draw_bar(r: Rect2, ratio: float, fill: Color) -> void:
	draw_rect(Rect2(r.position - Vector2.ONE, r.size + Vector2(2.0, 2.0)), EDGE)
	draw_rect(r, BACK)
	draw_rect(Rect2(r.position, Vector2(roundf(r.size.x * ratio), r.size.y)), fill)


## Une jauge de ressource : la barre, et le compte en clair à sa droite. Le
## chiffre exact compte — « il me reste de quoi tirer deux fois » ne se lit pas
## sur une longueur.
func _draw_gauge(
	x: float, y: float, ratio: float, fill: Color, current: float, maximum: float
) -> void:
	_draw_bar(Rect2(x, y, BAR_W, BAR_H), ratio, fill)
	if _font == null:
		return
	# ceili et non roundi sur la valeur courante : à 0,4 PV on est vivant, et une
	# jauge qui annonce 0 alors qu'on tient encore est un mensonge.
	var text := "%d / %d" % [ceili(current), roundi(maximum)]
	_text(
		Vector2(roundf(x + BAR_W + 5.0), roundf(y + BAR_H - 1.0)), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fill
	)


## Texte cerné de noir. Quatre appelants sur cet écran, et la même raison pour
## tous : le HUD passe sur du décor clair comme sur du sombre selon l'endroit de
## la carte, et aucune couleur ne tient sans contour.
func _text(
	pos: Vector2, text: String, align: int, width: int, tint: Color
) -> void:
	draw_string_outline(
		_font, pos, text, align, width, VALUE_SIZE, 1, Color(0, 0, 0, 1)
	)
	draw_string(_font, pos, text, align, width, VALUE_SIZE, tint)
