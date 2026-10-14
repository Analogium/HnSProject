class_name FinalBurst
extends Node2D

## L'éclat du Point final (jalon 50) : l'étoile de fuseaux de `Slash.burst()`, qui jaillit du
## cœur jusqu'au rayon et se dissout. Ne frappe rien : `Player._finish_off()` a frappé.

const LIFETIME := 0.3

var _age := 0.0
var _tint := Color.WHITE
var _radius := 0.0


static func burst(parent: Node, at: Vector2, radius: float, tint: Color) -> FinalBurst:
	var b := FinalBurst.new()
	b._tint = tint
	b._radius = radius
	parent.add_child(b)
	Settings.veil(b, Settings.SPELLS)
	b.global_position = at
	return b


func _ready() -> void:
	z_index = 2


func _physics_process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _age >= LIFETIME:
		queue_free()


func _draw() -> void:
	var step := mini(int(_age / LIFETIME * Slash.BURST_STEPS), Slash.BURST_STEPS - 1)
	Slash.burst(_tint, _radius, step).put(self, Vector2.ZERO)
