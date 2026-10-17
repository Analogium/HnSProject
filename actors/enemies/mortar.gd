class_name Mortar
extends Caster

## Le gobelin cuivré (jalon 27). Il se tient à distance comme le caster, mais tire
## **en cloche**, par-dessus les murs, là où se tenait sa victime : l'obus punit
## l'immobilité, pas la ligne de vue.

## Le vol et le télégraphe : l'obus tombe quand le plein atteint le bord.
const FLIGHT := 1.1
const BLAST := 26.0


## Par-dessus les murs.
func _has_line_of_sight(_victim: Node3D) -> bool:
	return true


func _fire(_dir: Vector3) -> void:
	var at := foe().global_position
	_danger(at, DangerZone.Shape.DISC, BLAST, FLIGHT, DamageType.Kind.FIRE)
	var shell := Shell.new()
	shell.from = global_position
	shell.to = at
	manager.projectile_parent.add_child(shell)
	Settings.veil(shell, Settings.ENEMY_ATTACKS)


## La boule de feu du joueur, en cloche : la planche existe déjà, et le souffle qui
## suit est celui de sa nature. Elle ne frappe pas : c'est la zone au sol.
class Shell:
	extends Node3D

	var from: Vector3
	var to: Vector3
	var _age := 0.0

	func _ready() -> void:
		global_position = from

	func _physics_process(delta: float) -> void:
		_age += delta
		var k := minf(_age / Mortar.FLIGHT, 1.0)
		global_position = from.lerp(to, k)
		if k >= 1.0:
			queue_free()
