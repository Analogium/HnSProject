class_name LungeTrail
extends Node3D

## Ce que laisse une frappe vive, choisi sur planche (jalon 28) : un fil d'acier du
## départ à l'arrivée, et une entaille chaude en travers de la cible. Ne frappe rien :
## le coup est parti de `Player._lunge()`.
##
## Les deux traits partent dans n'importe quelle direction : rastérisés **à l'angle
## exact** à la naissance (`Slash.cleave()`), puis dissous en `STEPS` crans fabriqués
## d'avance — une planche ne pâlit pas.

const LIFETIME := 0.25

var _age := 0.0
var _toward := Vector3.ZERO
var _target := Vector3.ZERO


static func leave(parent: Node, from_value: Vector3, landing: Vector3, target: Vector3) -> LungeTrail:
	var trail := LungeTrail.new()
	trail._toward = landing - from_value
	trail._target = target - from_value
	parent.add_child(trail)
	Settings.veil(trail, Settings.SPELLS)
	trail.global_position = from_value
	ElementFx.line(trail, from_value, landing, DamageType.COLORS[DamageType.Kind.PHYSICAL])
	return trail


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()

