class_name RatTide
extends Node3D

## La Marée de rats (jalon 53) : un tapis de rats qui déferle au sol jusqu'au bout de sa course
## (`radius`) et mord **une fois** chaque corps qu'il couvre, d'un coup et de rats. Sous le
## Contre-courant elle revient vers son lanceur et remord ; sous le Roi des Rats elle tourne
## autour de lui. Ses parts sont tirées une fois, à la naissance, comme la vague tranchante.
## Son dessin, le « tapis serré » choisi sur planche, court au sol sous les corps (`Piper`).

## Devant son point de départ, en pixels : née sur le lanceur, elle le recouvrait de rats.
const START := 16.0

var _cast: SkillStats
var _author: StatusEffects
var _caster: Node3D
var _parts: Array[float] = []
var _toward := Vector3.RIGHT
var _half_width := 0.0
var _run := 0.0
var _returning := false
## Les corps déjà mordus dans ce passage, par identifiant.
var _bitten := {}
## La ronde du Roi : son rayon autour du lanceur, zéro pour une marée qui court ; son angle.
var _orbit := 0.0
var _angle := 0.0
var _age := 0.0


## La marée d'un lancer : ses branches en éventail (les Trois rigoles), puis celles de la Seconde
## vague, chacune depuis où se tient alors le lanceur.
static func unleash(
	parent: Node, from_value: Vector3, toward: Vector3, cast: SkillStats, author: StatusEffects,
	caster: Node3D
) -> void:
	_fan(parent, from_value, toward, cast, author, caster)
	for k in int(cast.second_tide):
		parent.get_tree().create_timer(SkillStats.TIDE_GAP * float(k + 1), false).timeout.connect(
			func() -> void:
				if is_instance_valid(parent) and is_instance_valid(caster):
					_fan(parent, caster.global_position, toward, cast, author, caster)
		)


static func _fan(
	parent: Node, from_value: Vector3, toward: Vector3, cast: SkillStats, author: StatusEffects,
	caster: Node3D
) -> void:
	var count := 1 + int(cast.rivulets)
	for i in count:
		var turn := deg_to_rad((float(i) - float(count - 1) * 0.5) * SkillStats.TIDE_FAN)
		send(parent, from_value, Flat.rotated(toward, turn), cast, author, caster)


static func send(
	parent: Node, from_value: Vector3, toward: Vector3, cast: SkillStats, author: StatusEffects,
	caster: Node3D
) -> RatTide:
	var tide := RatTide.new()
	tide._cast = cast
	tide._author = author
	tide._caster = caster
	tide._parts = cast.roll(Game.rng)
	tide._toward = toward.normalized()
	tide._half_width = SkillStats.TIDE_WIDTH * 0.5 * maxf(1.0 + cast.breadth * 0.01, 0.1)
	# Sous les corps, sur la couche du sol : des rats qui courent entre les pieds.
	DashTrail.layer(parent).add_child(tide)
	Settings.veil(tide, Settings.SPELLS)
	tide.global_position = from_value + tide._toward * START
	return tide


## La ronde du Roi des Rats : une marée par branche, réparties autour de lui, qui en font le
## tour une fois.
static func orbit(parent: Node, caster: Node3D, cast: SkillStats, author: StatusEffects) -> void:
	var count := 1 + int(cast.rivulets)
	for i in count:
		var tide := send(parent, caster.global_position, Vector3.RIGHT, cast, author, caster)
		tide._orbit = SkillStats.TIDE_ORBIT
		tide._angle = TAU * float(i) / float(count)
		tide._place_on_orbit()


func _physics_process(delta: float) -> void:
	_age += delta
	if _orbit > 0.0:
		if not is_instance_valid(_caster) or _age >= SkillStats.TIDE_ORBIT_TIME:
			queue_free()
			return
		_angle += TAU / SkillStats.TIDE_ORBIT_TIME * delta
		_place_on_orbit()
	else:
		var step := SkillStats.TIDE_SPEED * delta
		global_position += _heading() * step
		_run += step
	_bite()
	var home := _returning and is_instance_valid(_caster) \
		and global_position.distance_to(_caster.global_position) < _half_width
	if _orbit <= 0.0 and (_run >= _cast.radius or home):
		_end_of_run()


## Où courent les rats : la visée, le lanceur au retour, la tangente de la ronde.
func _heading() -> Vector3:
	if _orbit > 0.0:
		return Flat.from_angle(_angle + PI * 0.5)
	if _returning and is_instance_valid(_caster):
		return global_position.direction_to(_caster.global_position)
	return _toward


func _place_on_orbit() -> void:
	global_position = _caster.global_position + Flat.from_angle(_angle) * _orbit


func _bite() -> void:
	for target in Targets.in_circle(get_world_3d(), global_position, _half_width):
		var id := target.get_instance_id()
		if _bitten.has(id):
			continue
		_bitten[id] = true
		var hit := _cast
		# Les Rats de cale : sous l'Air de Hamelin, la marée en accroche davantage.
		if _cast.hold_rats > 0.0 and HamelinAir.covers(target.global_position):
			hit = _cast.echoed(1.0)
			hit.rats += _cast.hold_rats
		Targets.strike(target, _parts, global_position, _author, hit, _cast.knockback)
		var body := target.get_parent() as Enemy
		if body != null and _cast.stumble > 0.0 and not body.is_dead:
			body.stun(_cast.stumble)
		if _cast.mana_on_hit > 0.0 and _caster is Player:
			(_caster as Player).gain_mana(_cast.mana_on_hit)


## Au bout de la course : le Contre-courant la ramène vers son lanceur, le Mascaret la renforce.
func _end_of_run() -> void:
	if _returning or _cast.backwash <= 0.0 or not is_instance_valid(_caster):
		queue_free()
		return
	_returning = true
	_run = 0.0
	_bitten.clear()
	_parts = DamageType.scaled(_parts, 1.0 + _cast.mascaret * 0.01)
