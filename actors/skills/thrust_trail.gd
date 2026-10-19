class_name ThrustTrail
extends Node3D

## L'estoc de la Tierce (jalon 46), choisi sur planche contre le fil de la frappe vive, une
## lance, une épée portée en avant, des traits de vitesse et un chevron : un fuseau jusqu'à
## la pointe, qui se dissout en crans dans sa seconde moitié, et une étoile d'impact qui
## éclate à la pointe en trois temps. Ne frappe rien : le coup est parti de `Player._thrust()`.
##
## Le fuseau part dans n'importe quelle direction : rastérisé **à l'angle exact** à la
## naissance (`Slash.cleave()`), comme la frappe vive.
##
## Le Vive lame (jalon 50, choisis sur planche) le reprend à sa façon : la Rafale en fuseaux
## fins décalés en peigne, le Coup de grâce en fuseau lourd sans étoile — sa croix le suit,
## `GraceMark` —, la riposte en fuseau fin précédé d'une étincelle de parade.

const LIFETIME := 0.25
const HALF_WIDTH := 1.8
## Les fuseaux du Vive lame : fins et écartés en peigne pour la Rafale, lourd pour le Coup de
## grâce, fin pour la riposte.
const COMB_WIDTH := 1.3
const COMB_GAP := 4.0
const HEAVY_WIDTH := 2.5
const PARRY_WIDTH := 1.2

var _age := 0.0
var _tip := Vector3.ZERO
var _tint := Color.WHITE
var _half_width := HALF_WIDTH
var _star := true
var _parry := false


static func leave(
	parent: Node, from_value: Vector3, tip: Vector3, tint: Color, half_width := HALF_WIDTH,
	star := true, parry := false
) -> ThrustTrail:
	var trail := ThrustTrail.new()
	trail._tip = tip - from_value
	trail._tint = tint
	trail._half_width = half_width
	trail._star = star
	trail._parry = parry
	parent.add_child(trail)
	Settings.veil(trail, Settings.SPELLS)
	trail.global_position = from_value
	ElementFx.line(trail, from_value, tip, tint)
	return trail


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()

