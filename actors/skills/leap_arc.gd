class_name LeapArc
extends Node3D

## Ce que laisse le Bond (jalon 34) : l'arc de la course en l'air (`SteelFx.arch`), à la rampe de
## sa nature, qui se ronge, et une bouffée de poussière au départ. Il ne frappe pas : la morsure,
## c'est l'explosion d'arrivée.

const LIFE := 1.0

## Le ruban de l'arc, en pixels de large.
const WIDTH := 7.0

var _age := 0.0


static func leave(parent: Node, from_value: Vector3, to: Vector3, cast: SkillStats) -> LeapArc:
	var arc := LeapArc.new()
	parent.add_child(arc)
	Settings.veil(arc, Settings.SPELLS)
	arc.global_position = from_value
	SteelFx.arch(arc, from_value, to, cast.nature, WIDTH)
	return arc


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFE:
		queue_free()

