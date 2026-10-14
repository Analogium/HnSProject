class_name GraceMark
extends Node2D

## La croix du Coup de grâce (jalon 50, « croix gravée » choisie sur planche) : deux entailles
## en X sur la cible, la seconde un temps après la première, puis elles se dissolvent. Ne
## frappe rien : le coup est parti de `Player._finish_off()`.
##
## Ses deux entailles ont toujours la même forme : fabriquées une fois par teinte et gardées.

const LIFETIME := 0.45
const REACH := 7.0
const WIDTH := 2.0
const STEPS := 4
## Quand la seconde entaille paraît, en part de la vie de la croix.
const SECOND := 0.2

static var _cuts := {}

var _age := 0.0
var _tint := Color.WHITE


static func carve(parent: Node, at: Vector2, tint: Color) -> GraceMark:
	var mark := GraceMark.new()
	mark._tint = tint
	parent.add_child(mark)
	Settings.veil(mark, Settings.SPELLS)
	mark.global_position = at
	return mark


## Les deux entailles, chacune en `STEPS` crans de dissolution.
static func cuts(tint: Color) -> Array:
	var key := tint.to_html(false)
	if not _cuts.has(key):
		_cuts[key] = [
			EffectForge.dissolving(Slash.cleave(tint, Vector2(REACH, REACH) * 2.0, WIDTH), STEPS),
			EffectForge.dissolving(Slash.cleave(tint, Vector2(-REACH, REACH) * 2.0, WIDTH), STEPS),
		]
	return _cuts[key]


func _ready() -> void:
	z_index = 2


func _physics_process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _age >= LIFETIME:
		queue_free()


func _draw() -> void:
	var k := _age / LIFETIME
	var step := int(maxf(k - 0.5, 0.0) * 2.0 * STEPS)
	if step >= STEPS:
		return
	var pair := cuts(_tint)
	(pair[0][step] as EffectForge.Piece).put(self, Vector2(-REACH, -REACH))
	if k >= SECOND:
		(pair[1][step] as EffectForge.Piece).put(self, Vector2(REACH, -REACH))
