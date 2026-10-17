class_name GraceMark
extends Node3D

## La croix du Coup de grâce (jalon 50, « croix gravée » choisie sur planche) : deux entailles
## en X sur la cible, la seconde un temps après la première, puis elles se dissolvent. Ne
## frappe rien : le coup est parti de `Player._finish_off()`.

const LIFETIME := 0.45

var _age := 0.0
var _tint := Color.WHITE


static func carve(parent: Node, at: Vector3, tint: Color) -> GraceMark:
	var mark := GraceMark.new()
	mark._tint = tint
	parent.add_child(mark)
	Settings.veil(mark, Settings.SPELLS)
	mark.global_position = at
	return mark


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()

