class_name FinalBurst
extends Node3D

## L'éclat du Point final (jalon 50) : l'étoile de fuseaux qui jaillit du cœur jusqu'au rayon
## (`BladeFx.final_point`). Ne frappe rien : `Player._finish_off()` a frappé. Porte le voile des sorts.

const LIFETIME := 0.3

var _age := 0.0


static func burst(parent: Node, at: Vector3, radius: float, nature: int) -> FinalBurst:
	var b := FinalBurst.new()
	parent.add_child(b)
	Settings.veil(b, Settings.SPELLS)
	b.global_position = at
	BladeFx.final_point(b, at, radius, nature)
	return b


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
