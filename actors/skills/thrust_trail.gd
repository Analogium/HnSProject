class_name ThrustTrail
extends Node3D

## L'estoc de la Tierce (jalon 46) : un fuseau d'acier jusqu'à la pointe (`SteelFx.cut`), et
## l'éclat de l'impact qui éclate à la pointe. Ne frappe rien : le coup est parti de
## `Player._thrust()`.
##
## Le Vive lame (jalon 50, choisis sur planche) le reprend à sa façon : la Rafale en fuseaux
## fins décalés en peigne, le Coup de grâce en fuseau lourd sans éclat — sa croix le suit,
## `GraceMark` —, la riposte en fuseau fin précédé d'un éclat de parade.

const LIFETIME := 0.25
const HALF_WIDTH := 1.8
## Les fuseaux du Vive lame : fins et écartés en peigne pour la Rafale, lourd pour le Coup de
## grâce, fin pour la riposte.
const COMB_WIDTH := 1.3
const COMB_GAP := 4.0
const HEAVY_WIDTH := 2.5
const PARRY_WIDTH := 1.2
## Le fuseau d'acier, en part de la demi-largeur du coup, et le temps que la pointe met à l'atteindre.
const SPAN := 5.0
const SWEEP := 0.06

var _age := 0.0


static func leave(
	parent: Node, from_value: Vector3, tip: Vector3, nature: int, half_width := HALF_WIDTH,
	star := true, parry := false
) -> ThrustTrail:
	var trail := ThrustTrail.new()
	parent.add_child(trail)
	Settings.veil(trail, Settings.SPELLS)
	trail.global_position = from_value
	var lift := Vector3.UP * ElementFx.LIFT
	if parry:
		SteelFx.glint(trail, from_value + lift, nature)
	SteelFx.cut(trail, from_value, tip, nature, half_width * SPAN, SWEEP, LIFETIME - SWEEP)
	if star:
		SteelFx.glint(trail, tip + lift, nature, SteelFx.GLINT_SIZE * 0.8)
		Sparks.burst(trail, tip, nature, 8, 6.0, Vector2(0.15, 0.4), Vector2(2.0, 5.0))
	return trail


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
