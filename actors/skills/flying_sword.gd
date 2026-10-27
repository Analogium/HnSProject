class_name FlyingSword
extends Node3D

## La Volée d'épées (jalon 39) : une épée de la couronne, au bout de sa durée, file droit
## vers l'ennemi le plus proche et traverse tout ce qu'elle croise, une fois par corps,
## jusqu'à la portée de la volée. Sans ennemi à portée, elle part droit devant elle.

const SPEED := 320.0
## L'Escorte vole moins vite : à 320, elle traversait les quelques pixels jusqu'à sa cible en un dixième de
## seconde, et ne se voyait pas partir.
const ESCORT_SPEED := 130.0

var _cast: SkillStats
var _author: StatusEffects
var _toward := Vector3.RIGHT
var _flown := 0.0
var _speed := SPEED
var _bitten: Targets.Contacts
## Le Ralliement (jalon 46) : la couronne où elle revient au bout de sa course.
var home: BladeCrown


static func throw(
	parent: Node, from_value: Vector3, outward: Vector3, cast: SkillStats, author: StatusEffects,
	prey: Hurtbox = null, speed := SPEED
) -> FlyingSword:
	var sword := FlyingSword.new()
	sword._cast = cast
	sword._author = author
	sword._speed = speed
	sword._bitten = Targets.Contacts.new(cast.sword_volley / speed)
	parent.add_child(sword)
	Settings.veil(sword, Settings.SPELLS)
	sword.global_position = from_value
	var shown := SteelFx.sword(sword, sword, cast.nature)
	shown.position = Vector3.UP * ElementFx.LIFT
	# L'Escorte (jalon 46) vise sa cible ; la volée, la plus proche.
	if prey == null:
		prey = Targets.nearest(sword.get_world_3d(), from_value, cast.sword_volley)
	sword._toward = from_value.direction_to(prey.global_position) if prey != null else outward.normalized()
	shown.basis = Basis.looking_at(Flat.from_angle(Flat.angle(sword._toward)))
	return sword


func _physics_process(delta: float) -> void:
	var step := _speed * delta
	position += _toward * step
	_flown += step
	_bitten.advance(delta)
	for target in Targets.in_circle(get_world_3d(), global_position, BladeCrown.CONTACT):
		if _bitten.accepts(target):
			Targets.strike(target, _cast.roll(Game.rng), global_position, _author, _cast)
			SteelFx.bite(self, target.global_position, _cast.nature)
	if _flown >= _cast.sword_volley:
		if is_instance_valid(home):
			home.rally(_cast)
		queue_free()

