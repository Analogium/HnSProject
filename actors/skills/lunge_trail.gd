class_name LungeTrail
extends Node3D

## Ce que laisse une frappe vive (`BladeFx.lunge`) : le couloir de la lame du départ à l'arrivée et
## l'entaille sur la cible. Ne frappe rien : le coup est parti de `Player._lunge()`. Porte le voile
## des sorts, que le dessin reprend à sa naissance.

const LIFETIME := 0.25

var _age := 0.0


static func leave(parent: Node, from_value: Vector3, landing: Vector3, target: Vector3, nature: int) -> LungeTrail:
	var trail := LungeTrail.new()
	parent.add_child(trail)
	Settings.veil(trail, Settings.SPELLS)
	trail.global_position = from_value
	BladeFx.lunge(trail, from_value, landing, target, nature)
	return trail


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
