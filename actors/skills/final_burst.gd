class_name FinalBurst
extends Node3D

## L'éclat du Point final (jalon 50) : l'étoile de fuseaux de `Slash.burst()`, qui jaillit du
## cœur jusqu'au rayon et se dissout. Ne frappe rien : `Player._finish_off()` a frappé.

const LIFETIME := 0.3

var _age := 0.0
var _tint := Color.WHITE
var _radius := 0.0


static func burst(parent: Node, at: Vector3, radius: float, tint: Color) -> FinalBurst:
	var b := FinalBurst.new()
	b._tint = tint
	b._radius = radius
	parent.add_child(b)
	Settings.veil(b, Settings.SPELLS)
	b.global_position = at
	ElementFx.burst(b, at, tint, radius)
	return b


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()

