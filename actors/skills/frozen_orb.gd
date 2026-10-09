class_name FrozenOrb
extends Node2D

## L'Orbe gelée (jalon 44), à la Frozen Orb de Diablo II : une orbe lente qui file droit en
## tournant, crache un éclat de glace à chaque période dans une direction qui tourne, puis
## éclate en couronne d'éclats. Elle ne frappe pas elle-même, sauf sous l'Orbe mordante ;
## un mur l'éclate plus tôt. Ses éclats sont les tirs du joueur, de son lancer.

## L'angle entre deux éclats crachés : assez pour une spirale lisible, pas assez pour qu'elle
## se referme en étoile.
const SPIN_STEP := 0.7
## Les tours de la facette par seconde.
const SPIN_HZ := 10.0

## Toutes celles qui volent : `simultaneous` par lanceur au plus, le Familier compté à part.
## Au-delà, les plus anciennes se dissolvent sans éclater.
static var _live: Array[FrozenOrb] = []

var _cast: SkillStats
var _author: StatusEffects
## Qui tire ses éclats : le joueur, ou l'épaule du Familier.
var _source: Node2D
var _shards: PackedScene
var _dir := Vector2.RIGHT
var _aim := Vector2.ZERO
## Le joueur dont le curseur la guide, sous le Guidage.
var _guide: Player
var _tint := Color.WHITE
var _age := 0.0
var _since_spit := 0.0
var _spin := 0.0
## Le Cristallin : depuis quand elle est arrêtée.
var _stopped := 0.0
## L'Orbe mordante : qui elle a déjà mordu.
var _bitten := {}


static func send(
	parent: Node, from: Vector2, direction: Vector2, cast: SkillStats, author: StatusEffects,
	source: Node2D, shards: PackedScene, aim: Vector2, guide: Player
) -> FrozenOrb:
	_live.assign(_live.filter(func(o) -> bool: return is_instance_valid(o) and not o.is_queued_for_deletion()))
	for old in cast.crowded(_live.filter(func(o: FrozenOrb) -> bool: return o._source == source)):
		old.queue_free()
	var orb := FrozenOrb.new()
	_live.append(orb)
	orb._cast = cast
	orb._author = author
	orb._source = source
	orb._shards = shards
	orb._dir = direction.normalized()
	orb._aim = aim
	orb._guide = guide
	orb._spin = direction.angle()
	orb._tint = DamageType.COLORS[cast.nature]
	parent.add_child(orb)
	Settings.veil(orb, Settings.SPELLS)
	orb.global_position = from + orb._dir * Projectile.MUZZLE
	return orb


func _ready() -> void:
	z_index = 5


## Son lanceur parti — le corbeau éteint —, elle se dissout : ses éclats n'auraient plus
## d'auteur.
func _physics_process(delta: float) -> void:
	if not is_instance_valid(_source):
		queue_free()
		return
	_age += delta
	if not _move(delta):
		_burst()
		queue_free()
		return
	_since_spit += delta
	var period := _cast.period / (1.0 + _cast.top * 0.01)
	while _since_spit >= period:
		_since_spit -= period
		_spit()
	if _cast.orb_bite > 0.0:
		_bite()
	queue_redraw()
	if _age >= _cast.duration:
		_burst()
		queue_free()


## Faux contre un mur. Sous la Stase, elle file au point visé et s'y arrête ; sous le
## Guidage, elle s'incurve vers le curseur d'un virage borné.
func _move(delta: float) -> bool:
	var step := _cast.projectile_speed * delta
	if _cast.stasis > 0.0:
		if global_position.distance_to(_aim) <= step:
			global_position = _aim
			_stopped += delta
			return true
		_dir = global_position.direction_to(_aim)
	elif _cast.guided > 0.0 and is_instance_valid(_guide):
		var turn := SkillStats.GUIDE_TURN * delta
		_dir = _dir.rotated(clampf(_dir.angle_to(_guide._aim_point() - global_position), -turn, turn))
	var next := global_position + _dir * step
	if not Targets.in_sight(get_world_2d(), global_position, next):
		return false
	global_position = next
	return true


## Le lancer de ses éclats : le sien, plus fort sous le Cristallin pour chaque seconde
## d'arrêt.
func _shard_cast() -> SkillStats:
	if _stopped <= 0.0 or _cast.crystalline <= 0.0:
		return _cast
	return _cast.echoed(1.0 + _cast.crystalline * 0.01 * _stopped)


## Un éclat sur la spirale ; sous le Viseur, vers l'ennemi le plus proche s'il y en a un.
func _spit() -> void:
	_spin += SPIN_STEP
	var dir := Vector2.from_angle(_spin)
	if _cast.aimed_spit > 0.0:
		var prey := Targets.nearest(get_world_2d(), global_position, SkillStats.SPIT_SIGHT)
		if prey != null:
			dir = global_position.direction_to(prey.global_position)
	var cast := _shard_cast()
	Projectile.spawn(
		get_parent(), _shards, global_position, dir, cast.roll(Game.rng), _source,
		SkillStats.SHARD_SPEED, cast.nature, cast
	)


## La couronne de la fin, qui part de la spirale où elle en était.
func _burst() -> void:
	var cast := _shard_cast()
	Projectile.split(
		get_parent(), _shards, global_position, Vector2.from_angle(_spin), SkillStats.SHARD_SPEED,
		cast.nature, _source, cast, SkillStats.FROST_ORB_BURST + int(_cast.shard_rain), {}
	)


## L'Orbe mordante : ce qu'elle traverse, une fois chacun, à une part du coup.
func _bite() -> void:
	for target in Targets.in_circle(get_world_2d(), global_position, SkillStats.ORB_REACH):
		var id := target.get_instance_id()
		if _bitten.has(id):
			continue
		_bitten[id] = true
		var parts := DamageType.scaled(_cast.roll(Game.rng), _cast.orb_bite * 0.01)
		Targets.strike(target, parts, global_position, _author, _cast)


func _draw() -> void:
	EffectForge.put_centered(self, Frost.orb(_tint, int(_age * SPIN_HZ)), Vector2.ZERO)
