class_name GraceMark
extends Node3D

## La croix du Coup de grâce (jalon 50, « croix gravée » choisie sur planche ; en 3D, `BladeFx.grace`) :
## deux entailles en X sur la cible, la seconde un temps après la première. Ne frappe rien : le coup
## est parti de `Player._finish_off()`. Porte le voile des sorts, que le dessin reprend à sa naissance.

const LIFETIME := 0.45

var _age := 0.0


static func carve(parent: Node, at: Vector3, nature: int) -> GraceMark:
	var mark := GraceMark.new()
	parent.add_child(mark)
	Settings.veil(mark, Settings.SPELLS)
	mark.global_position = at
	BladeFx.grace(mark, at, nature)
	return mark


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
