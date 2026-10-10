class_name ThrustTrail
extends Node2D

## L'estoc de la Tierce (jalon 46), choisi sur planche contre le fil de la frappe vive, une
## lance, une épée portée en avant, des traits de vitesse et un chevron : un fuseau jusqu'à
## la pointe, qui se dissout en crans dans sa seconde moitié, et une étoile d'impact qui
## éclate à la pointe en trois temps. Ne frappe rien : le coup est parti de `Player._thrust()`.
##
## Le fuseau part dans n'importe quelle direction : rastérisé **à l'angle exact** à la
## naissance (`Slash.cleave()`), comme la frappe vive.

const LIFETIME := 0.25
const STEPS := 4
const HALF_WIDTH := 1.8

var _age := 0.0
var _tip := Vector2.ZERO
var _tint := Color.WHITE
var _shaft: Array[EffectForge.Piece] = []


static func leave(parent: Node, from_value: Vector2, tip: Vector2, tint: Color) -> ThrustTrail:
	var trail := ThrustTrail.new()
	trail._tip = tip - from_value
	trail._tint = tint
	parent.add_child(trail)
	Settings.veil(trail, Settings.SPELLS)
	trail.global_position = from_value
	return trail


func _ready() -> void:
	z_index = 2
	_shaft = EffectForge.dissolving(Slash.cleave(_tint, _tip, HALF_WIDTH), STEPS)


func _physics_process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _age >= LIFETIME:
		queue_free()


func _draw() -> void:
	var k := _age / LIFETIME
	# Plein la première moitié, puis il se dissout : c'est l'étoile qui dit le coup.
	var step := int(maxf(k - 0.5, 0.0) * 2.0 * STEPS)
	if step < STEPS:
		_shaft[step].put(self, Vector2.ZERO)
	var stars := EffectForge.thrust_stars(_tint)
	var frame := int(k * float(stars.size() + 1))
	if frame < stars.size():
		EffectForge.put_centered(self, stars[frame], _tip)
