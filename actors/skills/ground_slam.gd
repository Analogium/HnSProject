class_name GroundSlam
extends Node3D

## Ce que laisse le Brise-sol (jalon 39) : le sol frappé sous l'impact (`SteelFx.impact`) — la
## lame qui s'abat, le cratère, la poussière et les mottes. Il ne frappe pas — le coup est porté
## par `Player._slam()`, sur l'instant. Sous les corps, comme une traînée.

const LIFE := 0.45

var _age := 0.0


static func leave(parent: Node, at: Vector3, cast: SkillStats) -> GroundSlam:
	var slam := GroundSlam.new()
	DashTrail.layer(parent).add_child(slam)
	Settings.veil(slam, Settings.SPELLS)
	slam.global_position = at
	SteelFx.impact(slam, at, cast.nature, cast.radius, true)
	return slam


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFE:
		queue_free()
