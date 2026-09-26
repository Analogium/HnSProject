class_name Mortar
extends Caster

## Le gobelin cuivré (jalon 27). Il se tient à distance comme le caster, mais tire
## **en cloche**, par-dessus les murs, là où se tenait sa victime : l'obus punit
## l'immobilité, pas la ligne de vue.

## Le vol et le télégraphe : l'obus tombe quand le plein atteint le bord.
const FLIGHT := 1.1
const BLAST := 26.0
const ARC_HEIGHT := 40.0


## Par-dessus les murs.
func _has_line_of_sight(_victim: Node2D) -> bool:
	return true


func _fire(_dir: Vector2) -> void:
	var at := foe().global_position
	var zone := DangerZone.put(manager.ground(), at, DangerZone.Shape.DISC, BLAST, FLIGHT)
	zone.parts = DamageType.empty_parts()
	zone.parts[DamageType.Kind.FIRE] = stats.attack_damage
	zone.author = states
	var shell := Shell.new()
	shell.from = global_position
	shell.to = at
	manager.projectile_parent.add_child(shell)


## La boule de feu du joueur, en cloche : la planche existe déjà, et le souffle qui
## suit est celui de sa nature.
class Shell:
	extends Node2D

	var from: Vector2
	var to: Vector2
	var _age := 0.0

	func _ready() -> void:
		z_index = 3
		global_position = from

	func _physics_process(delta: float) -> void:
		_age += delta
		var k := minf(_age / Mortar.FLIGHT, 1.0)
		global_position = from.lerp(to, k) + Vector2(0.0, -Mortar.ARC_HEIGHT * 4.0 * k * (1.0 - k))
		queue_redraw()
		if k >= 1.0:
			queue_free()

	func _draw() -> void:
		var balls := EffectForge.balls(DamageType.COLORS[DamageType.Kind.FIRE])
		var tex: Texture2D = balls[int(_age * EffectForge.BALL_HZ) % balls.size()]
		var corner := EffectForge.snap(self, -Vector2(EffectForge.BALL_SIZE, EffectForge.BALL_SIZE) * 0.5)
		draw_texture_rect(tex, Rect2(corner, tex.get_size()), false)
