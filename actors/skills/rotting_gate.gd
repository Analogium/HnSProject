class_name RottingGate
extends Node3D

## Le portail de la Porte pourrissante : il crache une créature par période ; elles
## s'amassent autour de lui jusqu'à ce qu'un ennemi entre à portée, puis foncent
## exploser dessus — le souffle de la nova, au rayon du lancer. Pas de plafond : la
## durée sur la période borne déjà l'amas.
##
## **Les créatures ne sont pas des corps** : les ennemis ne les ciblent pas, elles ne
## vivent que pour exploser. Le portail les fait avancer et les dessine lui-même (`RotGateFx`),
## et celles qui restent tombent avec lui.

## D'où elles voient une proie, depuis le portail.
const SIGHT := 110.0
const SPEED := 120.0
## Au contact, centre à centre.
const CONTACT := 8.0
## Le cercle où elles s'amassent en attendant.
const HUDDLE := 16.0
## Entre deux recherches de proie.
const SEARCH_PERIOD := 0.2
## Le Nid porté (jalon 38) : où la faille se tient par rapport au joueur, à son épaule.
const NEST_OFFSET := Vector3(-12.0, 0.0, -4.0)


class Crawler:
	var at: Vector3
	## Où elle était au pas d'avant : le dessin glisse de l'un à l'autre entre deux pas.
	var was: Vector3
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
var _follow: Node3D
## La Laisse (jalon 45) : celui dont elles suivent la visée.
var _aimer: Player
## Le Grouillement : l'attente avant qu'un coup reçu en fasse cracher d'autres.
var _provoked := 0.0
var _fx: RotGateFx

## Toutes celles qui sont ouvertes : la Détonation de la Déferlante les cherche (jalon 45).
static var _open: Array[RottingGate] = []


static func open(
	parent: Node, point: Vector3, cast: SkillStats, author: StatusEffects, follow: Node3D = null,
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
	gate._fx = RotGateFx.open(gate, cast.nature, cast.duration, follow != null)
	return gate


func _exit_tree() -> void:
	_open.erase(self)


## La Détonation (jalon 45) : les créatures de cet auteur dans ce cercle éclatent sur-le-champ,
## plus fort.
static func detonate(center: Vector3, radius: float, author: StatusEffects, factor: float) -> void:
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
	if _age >= _cast.duration:
		queue_free()


func _spawn() -> void:
	var c: Crawler = Crawler.new()
	c.at = global_position
	c.was = c.at
	_fx.spit()
	c.angle = float(_born + _crawlers.size()) * 2.4
	_crawlers.append(c)


## Le Grouillement (jalon 45) : un coup reçu par le porteur du nid en fait cracher d'autres.
static func provoke(bearer: Node3D) -> void:
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
		big.was = big.at
		for i in SkillStats.AMALGAM_SIZE:
			var c: Crawler = idle.pop_back()
			_crawlers.erase(c)
			big.angle = c.angle
			big.waited = maxf(big.waited, c.waited)
		_crawlers.append(big)


## Chaque créature sans proie prend l'ennemi à portée le plus proche d'elle — sous la Laisse,
## le plus proche de la visée.
func _hunt() -> void:
	var seen := Targets.in_circle(get_world_3d(), global_position, SIGHT + _cast.seek_radius)
	if seen.is_empty():
		return
	var aimed := _aimer._aim_point() if is_instance_valid(_aimer) else Vector3.INF
	for c in _crawlers:
		if is_instance_valid(c.prey):
			continue
		var from := c.at if aimed == Vector3.INF else aimed
		var best_d := INF
		for target in seen:
			var d := from.distance_squared_to(target.global_position)
			if d < best_d:
				c.prey = target
				best_d = d


func _crawl(c: Crawler, delta: float) -> void:
	c.was = c.at
	var goal := global_position + Flat.from_angle(c.angle + _age) * HUDDLE
	if not is_instance_valid(c.prey):
		c.waited += delta
	else:
		goal = c.prey.global_position
		if c.at.distance_to(goal) <= CONTACT:
			_burst(c)
			return
	c.at = c.at.move_toward(goal, SPEED * (1.0 + _cast.crawl_speed * 0.01) * delta)


## La Gestation (jalon 45) : ce qu'elle a grossi à attendre — ses dégâts.
func _swell(c: Crawler) -> float:
	return 1.0 + _cast.gestation * 0.01 * minf(c.waited, SkillStats.GESTATION_MOST)


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
			freed.was = freed.at
			freed.angle = c.angle + float(i) * TAU / float(SkillStats.AMALGAM_SIZE)
			freed.loose = true
			_crawlers.append(freed)
	if c.last or c.small and _cast.lineage <= 0.0:
		return
	for i in int(_cast.hatchlings):
		var young: Crawler = Crawler.new()
		young.at = c.at
		young.was = young.at
		young.angle = c.angle + float(i + 1) * 2.4
		young.last = c.small
		young.small = true
		_crawlers.append(young)


## Le dessin des créatures, à l'image : entre deux pas, chacune glisse de `was` à `at`.
func _process(_delta: float) -> void:
	var k := Engine.get_physics_interpolation_fraction()
	var at: Array[Vector3] = []
	var sizes: Array[float] = []
	var heads: Array[Vector3] = []
	for c in _crawlers:
		at.append(c.was.lerp(c.at, k))
		sizes.append(RotGateFx.size_of(c.small, c.last, c.big, c.waited))
		heads.append(c.at - c.was if c.at.distance_squared_to(c.was) > 0.0001 else c.at - global_position)
	_fx.crawl(at, sizes, heads)
