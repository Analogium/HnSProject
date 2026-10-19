class_name LeapArc
extends Node3D

## Ce que laisse le Bond (jalon 34, « arc et cratère » choisi sur planche) : un arc de
## bouffées du départ à l'arrivée, qui s'éteint **depuis le départ**, et un cratère de
## brûlures à l'arrivée. Il ne frappe pas : la morsure, c'est l'explosion d'arrivée.
## Rien ne pâlit — une bouffée se coupe, le cratère se coupe.

const CRATER_LIFE := 1.0

var _tint := Color.WHITE
## En repère local : le nœud est posé au départ.
var _toward := Vector3.ZERO
var _age := 0.0


static func leave(parent: Node, from_value: Vector3, to: Vector3, cast: SkillStats) -> LeapArc:
	var arc := LeapArc.new()
	arc._tint = DamageType.COLORS[cast.nature]
	arc._toward = to - from_value
	parent.add_child(arc)
	Settings.veil(arc, Settings.SPELLS)
	arc.global_position = from_value
	ElementFx.line(arc, from_value, to, DamageType.COLORS[cast.nature])
	return arc


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= CRATER_LIFE:
		queue_free()

