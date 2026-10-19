class_name Dervish
extends Node3D

## Les Derviches du Cyclone (jalon 46) : un petit tour qui file droit devant et fauche ce
## qu'il croise, une fois par période du cyclone ; sous la Trombe, il s'incurve vers
## l'ennemi le plus proche. Une spirale d'acier qui tourne (`Slash.spiral()`, planche du
## jalon 46).

## Son virage sous la Trombe, en radians par seconde.
const TURN := 4.0

var _cast: SkillStats
var _author: StatusEffects
var _toward := Vector3.RIGHT
var _age := 0.0
var _bitten: Targets.Contacts


static func send(
	parent: Node, from_value: Vector3, toward: Vector3, cast: SkillStats, author: StatusEffects
) -> Dervish:
	var dervish := Dervish.new()
	dervish._cast = cast.echoed(SkillStats.DERVISH_PART)
	dervish._author = author
	dervish._toward = toward.normalized()
	dervish._bitten = Targets.Contacts.new(cast.period)
	parent.add_child(dervish)
	Settings.veil(dervish, Settings.SPELLS)
	dervish.global_position = from_value
	ElementFx.trail(dervish, DamageType.COLORS[cast.nature])
	return dervish


func _physics_process(delta: float) -> void:
	_age += delta
	if _cast.waterspout > 0.0:
		var prey := Targets.nearest(get_world_3d(), global_position, SkillStats.DERVISH_SIGHT)
		if prey != null:
			var wanted := Flat.angle(global_position.direction_to(prey.global_position))
			_toward = Flat.from_angle(rotate_toward(Flat.angle(_toward), wanted, TURN * delta))
	position += _toward * SkillStats.DERVISH_SPEED * delta
	_bitten.advance(delta)
	for target in Targets.in_circle(get_world_3d(), global_position, SkillStats.DERVISH_RADIUS):
		if _bitten.accepts(target):
			Targets.strike(target, _cast.roll(Game.rng), global_position, _author, _cast)
	if _age >= SkillStats.DERVISH_LIFE:
		queue_free()

