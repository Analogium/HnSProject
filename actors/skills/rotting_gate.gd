class_name RottingGate
extends Node2D

## Le portail de la Porte pourrissante : il crache une créature par période ; elles
## s'amassent autour de lui jusqu'à ce qu'un ennemi entre à portée, puis foncent
## exploser dessus — le souffle de la nova, au rayon du lancer. Pas de plafond : la
## durée sur la période borne déjà l'amas.
##
## **Les créatures ne sont pas des corps** : les ennemis ne les ciblent pas, elles ne
## vivent que pour exploser. Le portail les fait avancer et les dessine lui-même, et
## celles qui restent tombent avec lui.

## D'où elles voient une proie, depuis le portail.
const SIGHT := 110.0
const SPEED := 120.0
## Au contact, centre à centre.
const CONTACT := 8.0
## Le cercle où elles s'amassent en attendant.
const HUDDLE := 16.0
## Entre deux recherches de proie.
const SEARCH_PERIOD := 0.2
## Ce que la faille met à s'ouvrir et à se refermer, en secondes.
const OPENING := 0.2
const CLOSING := 0.3


class Crawler:
	var at: Vector2
	var prey: Hurtbox
	## Sa place dans l'amas, en angle.
	var angle: float


var _cast: SkillStats
var _author: StatusEffects
var _tint := Color.WHITE
var _age := 0.0
var _born := 0
var _search := 0.0
var _crawlers: Array[Crawler] = []


static func open(
	parent: Node, point: Vector2, cast: SkillStats, author: StatusEffects
) -> RottingGate:
	var gate := RottingGate.new()
	gate._cast = cast
	gate._author = author
	gate._tint = DamageType.COLORS[cast.dominant_nature()]
	parent.add_child(gate)
	gate.global_position = point
	return gate


## Pas de lumière ajoutée : la faille et ses créatures sont **dessinées**.
func _ready() -> void:
	z_index = 3


## Les naissances se comptent par `strikes_over_duration()`, comme les impulsions du
## pilier : la fiche annonce une explosion par créature.
func _physics_process(delta: float) -> void:
	_age += delta
	var total := _cast.strikes_over_duration()
	while _born < total and _age >= float(_born) * _cast.period:
		_born += 1
		var c := Crawler.new()
		c.at = global_position
		c.angle = float(_born) * 2.4
		_crawlers.append(c)
	_search -= delta
	if _search <= 0.0:
		_search = SEARCH_PERIOD
		_hunt()
	for c in _crawlers.duplicate():
		_crawl(c, delta)
	queue_redraw()
	if _age >= _cast.duration:
		queue_free()


## Chaque créature sans proie prend l'ennemi à portée le plus proche d'elle.
func _hunt() -> void:
	var seen := Targets.in_circle(get_world_2d(), global_position, SIGHT)
	if seen.is_empty():
		return
	for c in _crawlers:
		if is_instance_valid(c.prey):
			continue
		var best_d := INF
		for target in seen:
			var d := c.at.distance_squared_to(target.global_position)
			if d < best_d:
				c.prey = target
				best_d = d


func _crawl(c: Crawler, delta: float) -> void:
	var goal := global_position + Vector2.from_angle(c.angle + _age) * HUDDLE
	if is_instance_valid(c.prey):
		goal = c.prey.global_position
		if c.at.distance_to(goal) <= CONTACT:
			_crawlers.erase(c)
			Explosion.put(
				get_parent(), c.at, _cast.roll(Game.rng), _cast.radius, null, _tint, _author, _cast
			)
			return
	c.at = c.at.move_toward(goal, SPEED * delta)


## La faille **debout**, sa base sur le point visé, qui s'ouvre et se referme en se
## **découpant** depuis son milieu — une planche ne s'étire pas. Choisie sur planche
## contre une fosse, une arche et une gueule (jalon 26). Les créatures sautillent
## chacune à son temps.
func _draw() -> void:
	var rifts := EffectForge.rifts(_tint)
	var rift: Texture2D = rifts[int(_age * EffectForge.RIFT_HZ) % rifts.size()]
	var shown := clampf(_age / OPENING, 0.0, 1.0) * clampf((_cast.duration - _age) / CLOSING, 0.0, 1.0)
	var size := Vector2(rift.get_width(), rift.get_height())
	var rows := roundf(size.y * shown)
	if rows >= 1.0:
		var band := Rect2(0.0, floorf((size.y - rows) * 0.5), size.x, rows)
		var corner := EffectForge.snap(self, Vector2(-floorf(size.x * 0.5), -size.y + band.position.y))
		draw_texture_rect_region(rift, Rect2(corner, band.size), band)
	var crawlers := EffectForge.crawlers(_tint)
	for i in _crawlers.size():
		var hop := int(_age * EffectForge.CRAWLER_HZ + float(i) * 0.7) % crawlers.size()
		Necrotic.centered(self, crawlers[hop], to_local(_crawlers[i].at) - Vector2(0.0, 3.0))
