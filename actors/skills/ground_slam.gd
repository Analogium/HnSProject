class_name GroundSlam
extends Node2D

## Ce que laisse le Brise-sol (jalon 39) : le sol fendu sous l'impact, `Slash.fissures()`.
## Il ne frappe pas — le coup est porté par `Player._slam()`, sur l'instant — et se
## dissout. Sous les corps, comme une traînée : par-dessus, il fendrait les ennemis.

const LIFE := 0.45

var _cast: SkillStats
var _pattern := 0
var _age := 0.0


static func leave(parent: Node, at: Vector2, cast: SkillStats) -> GroundSlam:
	var slam := GroundSlam.new()
	slam._cast = cast
	slam._pattern = Game.rng.randi() % Slash.FISSURE_PATTERNS
	DashTrail.layer(parent).add_child(slam)
	Settings.veil(slam, Settings.SPELLS)
	slam.global_position = at
	return slam


func _physics_process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _age >= LIFE:
		queue_free()


func _draw() -> void:
	var step := mini(int(_age / LIFE * 4.0), 3)
	Slash.fissures(DamageType.COLORS[_cast.nature], _cast.radius, _pattern, step).put(self, Vector2.ZERO)
