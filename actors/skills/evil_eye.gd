class_name EvilEye
extends Node3D

## L'œil du Mauvais œil (jalon 49), posé au sol sous ceux qu'il maudit (`Witchcraft.eye()`) :
## il ne frappe rien, le Familier pose les états. Il s'ouvre et se referme, puis s'en va.

const LIFETIME := 0.6

var _radius := 0.0
var _tint := Color.WHITE
var _age := 0.0


## Sur le calque du sol : debout au milieu, il passerait sur les ennemis qu'il maudit.
static func open(parent: Node, at: Vector3, radius: float, tint: Color) -> EvilEye:
	var e := EvilEye.new()
	e._radius = radius
	e._tint = tint
	DashTrail.layer(parent).add_child(e)
	Settings.veil(e, Settings.SPELLS)
	e.global_position = at
	ElementFx.area(e, tint, radius)
	return e


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()

