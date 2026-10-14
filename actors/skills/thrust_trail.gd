class_name ThrustTrail
extends Node2D

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
const STEPS := 4
const HALF_WIDTH := 1.8
## L'étincelle de parade de la riposte : où elle éclate devant le lanceur, et la part de
## la vie du trait qu'elle tient.
const PARRY_AHEAD := Vector2(6, -4)
## Les fuseaux du Vive lame : fins et écartés en peigne pour la Rafale, lourd pour le Coup de
## grâce, fin pour la riposte.
const COMB_WIDTH := 1.3
const COMB_GAP := 4.0
const HEAVY_WIDTH := 2.5
const PARRY_WIDTH := 1.2
const PARRY_SHARE := 0.35

var _age := 0.0
var _tip := Vector2.ZERO
var _tint := Color.WHITE
var _shaft: Array[EffectForge.Piece] = []
var _half_width := HALF_WIDTH
var _star := true
var _parry := false


static func leave(
	parent: Node, from_value: Vector2, tip: Vector2, tint: Color, half_width := HALF_WIDTH,
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
	return trail


func _ready() -> void:
	z_index = 2
	_shaft = EffectForge.dissolving(Slash.cleave(_tint, _tip, _half_width), STEPS)


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
	if _parry and k < PARRY_SHARE:
		var ahead := Vector2(PARRY_AHEAD.x * signf(_tip.x if _tip.x != 0.0 else 1.0), PARRY_AHEAD.y)
		EffectForge.put_centered(self, EffectForge.stun_stars()[0], ahead)
	if not _star:
		return
	var stars := EffectForge.thrust_stars(_tint)
	var frame := int(k * float(stars.size() + 1))
	if frame < stars.size():
		EffectForge.put_centered(self, stars[frame], _tip)
