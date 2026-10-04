class_name FlyingSword
extends Node2D

## La Volée d'épées (jalon 39) : une épée de la couronne, au bout de sa durée, file droit
## vers l'ennemi le plus proche et traverse tout ce qu'elle croise, une fois par corps,
## jusqu'à la portée de la volée. Sans ennemi à portée, elle part droit devant elle.

const SPEED := 320.0

var _cast: SkillStats
var _author: StatusEffects
var _toward := Vector2.RIGHT
var _flown := 0.0
var _bitten: Targets.Contacts


static func throw(
	parent: Node, from_value: Vector2, outward: Vector2, cast: SkillStats, author: StatusEffects
) -> FlyingSword:
	var sword := FlyingSword.new()
	sword._cast = cast
	sword._author = author
	sword._bitten = Targets.Contacts.new(cast.sword_volley / SPEED)
	parent.add_child(sword)
	Settings.veil(sword, Settings.SPELLS)
	sword.global_position = from_value
	var prey := Targets.nearest(sword.get_world_2d(), from_value, cast.sword_volley)
	sword._toward = from_value.direction_to(prey.global_position) if prey != null else outward.normalized()
	return sword


func _ready() -> void:
	z_index = 3


func _physics_process(delta: float) -> void:
	var step := SPEED * delta
	position += _toward * step
	_flown += step
	_bitten.advance(delta)
	for target in Targets.in_circle(get_world_2d(), global_position, BladeCrown.CONTACT):
		if _bitten.accepts(target):
			Targets.strike(target, _cast.roll(Game.rng), global_position, _author, _cast)
	queue_redraw()
	if _flown >= _cast.sword_volley:
		queue_free()


## L'épée de la couronne, pointe en avant.
func _draw() -> void:
	Slash.sword(DamageType.COLORS[_cast.nature], Slash.turn_of(_toward.angle()), false, 0.0).put(
		self, Vector2.ZERO
	)
