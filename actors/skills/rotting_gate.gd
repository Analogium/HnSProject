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
## Le Nid porté (jalon 38) : où la faille se tient par rapport au joueur, à son épaule.
const NEST_OFFSET := Vector2(-12.0, -4.0)


class Crawler:
	var at: Vector2
	var prey: Hurtbox
	## Sa place dans l'amas, en angle.
	var angle: float
	## Un petit de Progéniture : une part du coup, un demi-rayon, et rien après lui — sauf
	## sous la Lignée (jalon 45), où il en lâche une fois : ce sont les derniers.
	var small := false
	var last := false
	## La Gestation : le temps passé sans proie. L'Amalgame : trois fondues en une ; sous la
	## Masse critique, celles qu'il relâche en éclatant ne fusionnent plus.
	var waited := 0.0
	var big := false
	var loose := false

	## Ce que son éclat frappe, en part du coup et du rayon.
	func part() -> float:
		if big:
			return SkillStats.AMALGAM_MORE
		return SkillStats.SPLIT_PART * (SkillStats.SPLIT_PART if last else 1.0) if small else 1.0

	func reach() -> float:
		if big:
			return SkillStats.AMALGAM_RADIUS
		return (0.25 if last else 0.5) if small else 1.0


var _cast: SkillStats
var _author: StatusEffects
var _tint := Color.WHITE
var _age := 0.0
var _born := 0
var _search := 0.0
var _crawlers: Array[Crawler] = []
var _follow: Node2D
## La Laisse (jalon 45) : celui dont elles suivent la visée.
var _aimer: Player
## Le Grouillement : l'attente avant qu'un coup reçu en fasse cracher d'autres.
var _provoked := 0.0

## Toutes celles qui sont ouvertes : la Détonation de la Déferlante les cherche (jalon 45).
static var _open: Array[RottingGate] = []


static func open(
	parent: Node, point: Vector2, cast: SkillStats, author: StatusEffects, follow: Node2D = null,
	aimer: Player = null
) -> RottingGate:
	var gate := RottingGate.new()
	gate._follow = follow
	gate._aimer = aimer if cast.leash > 0.0 else null
	gate._cast = cast
	gate._author = author
	gate._tint = DamageType.COLORS[cast.nature]
	_open.append(gate)
	parent.add_child(gate)
	Settings.veil(gate, Settings.SPELLS)
	gate.global_position = point
	return gate


## Pas de lumière ajoutée : la faille et ses créatures sont **dessinées**.
func _ready() -> void:
	z_index = 3


func _exit_tree() -> void:
	_open.erase(self)


## La Détonation (jalon 45) : les créatures de cet auteur dans ce cercle éclatent sur-le-champ,
## plus fort.
static func detonate(center: Vector2, radius: float, author: StatusEffects, factor: float) -> void:
	for gate in _open:
		if gate._author != author:
			continue
		for c in gate._crawlers.duplicate():
			if c.at.distance_to(center) <= radius:
				gate._burst(c, factor)


## Les naissances se comptent par `strikes_over_duration()`, comme les impulsions du
## pilier : la fiche annonce une explosion par créature.
func _physics_process(delta: float) -> void:
	if is_instance_valid(_follow):
		global_position = _follow.global_position + NEST_OFFSET
	_age += delta
	_provoked = maxf(_provoked - delta, 0.0)
	var due := _cast.strikes_due(_age)
	while _born < due:
		_born += 1
		_spawn()
	if _cast.amalgam > 0.0:
		_fuse()
	_search -= delta
	if _search <= 0.0:
		_search = SEARCH_PERIOD
		_hunt()
	for c in _crawlers.duplicate():
		_crawl(c, delta)
	queue_redraw()
	if _age >= _cast.duration:
		queue_free()


func _spawn() -> void:
	var c: Crawler = Crawler.new()
	c.at = global_position
	c.angle = float(_born + _crawlers.size()) * 2.4
	_crawlers.append(c)


## Le Grouillement (jalon 45) : un coup reçu par le porteur du nid en fait cracher d'autres.
static func provoke(bearer: Node2D) -> void:
	for gate in _open:
		if gate._follow == bearer and gate._cast.swarming > 0.0 and gate._provoked <= 0.0:
			gate._provoked = SkillStats.SWARMING_PERIOD
			for i in int(gate._cast.swarming):
				gate._spawn()


## L'Amalgame (jalon 45) : trois qui attendent sans proie se fondent en une.
func _fuse() -> void:
	var idle := _crawlers.filter(
		func(c: Crawler) -> bool:
			return not c.small and not c.big and not c.loose and not is_instance_valid(c.prey)
	)
	while idle.size() >= SkillStats.AMALGAM_SIZE:
		var big: Crawler = Crawler.new()
		big.big = true
		big.at = global_position
		for i in SkillStats.AMALGAM_SIZE:
			var c: Crawler = idle.pop_back()
			_crawlers.erase(c)
			big.angle = c.angle
			big.waited = maxf(big.waited, c.waited)
		_crawlers.append(big)


## Chaque créature sans proie prend l'ennemi à portée le plus proche d'elle — sous la Laisse,
## le plus proche de la visée.
func _hunt() -> void:
	var seen := Targets.in_circle(get_world_2d(), global_position, SIGHT + _cast.seek_radius)
	if seen.is_empty():
		return
	var aimed := _aimer._aim_point() if is_instance_valid(_aimer) else Vector2.INF
	for c in _crawlers:
		if is_instance_valid(c.prey):
			continue
		var from := c.at if aimed == Vector2.INF else aimed
		var best_d := INF
		for target in seen:
			var d := from.distance_squared_to(target.global_position)
			if d < best_d:
				c.prey = target
				best_d = d


func _crawl(c: Crawler, delta: float) -> void:
	var goal := global_position + Vector2.from_angle(c.angle + _age) * HUDDLE
	if not is_instance_valid(c.prey):
		c.waited += delta
	else:
		goal = c.prey.global_position
		if c.at.distance_to(goal) <= CONTACT:
			_burst(c)
			return
	c.at = c.at.move_toward(goal, SPEED * (1.0 + _cast.crawl_speed * 0.01) * delta)


## La Gestation (jalon 45) : ce qu'elle a grossi à attendre — ses dégâts, et son dessin.
func _swell(c: Crawler) -> float:
	return 1.0 + _cast.gestation * 0.01 * minf(c.waited, SkillStats.GESTATION_MOST)


## Sa taille dessinée : la Gestation la fait enfler par paliers impairs — une planche ne
## s'étire pas —, l'amalgame part de plus grand.
func _side(c: Crawler) -> int:
	var base := EffectForge.AMALGAM_SIDE if c.big else EffectForge.CRAWLER_SIZE
	return floori(float(base) * _swell(c) * 0.5) * 2 + 1


## Elle éclate ; Progéniture en lâche des petits là où elle était, qui chassent à leur tour.
## La Masse critique fait relâcher à l'amalgame celles qui le formaient.
func _burst(c: Crawler, factor := 1.0) -> void:
	_crawlers.erase(c)
	var parts := DamageType.scaled(_cast.roll(Game.rng), factor * c.part() * _swell(c))
	Explosion.put(get_parent(), c.at, parts, _cast.radius * c.reach(), null, _tint, _author, _cast)
	if c.big and _cast.critical_mass > 0.0:
		for i in SkillStats.AMALGAM_SIZE:
			var freed: Crawler = Crawler.new()
			freed.at = c.at
			freed.angle = c.angle + float(i) * TAU / float(SkillStats.AMALGAM_SIZE)
			freed.loose = true
			_crawlers.append(freed)
	if c.last or c.small and _cast.lineage <= 0.0:
		return
	for i in int(_cast.hatchlings):
		var young: Crawler = Crawler.new()
		young.at = c.at
		young.angle = c.angle + float(i + 1) * 2.4
		young.last = c.small
		young.small = true
		_crawlers.append(young)


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
		var c := _crawlers[i]
		var side := _side(c)
		var tex: Texture2D = crawlers[hop]
		if side != EffectForge.CRAWLER_SIZE or c.big:
			tex = EffectForge.grown_crawlers(_tint, side, c.big)[hop]
		Necrotic.centered(self, tex, to_local(c.at) - Vector2(0.0, floorf(float(side) * 0.5)))
