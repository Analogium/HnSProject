class_name HolyPulse
extends Node2D

## L'émanation de Pulsation sacrée : portée par le joueur, elle frappe son cercle à
## chaque période pendant sa durée, puis s'en va. Ce qui la sépare de l'Immolation
## n'est pas le dessin mais le prix : celle-ci ne se paie pas à la seconde, donc elle
## **finit**, et ne s'éteint pas à la touche.
##
## Comme tout ce qui dure, elle ne fige jamais le jeu.

## La part de la période que met une onde à atteindre le bord : au-delà, deux ondes se
## chevaucheraient et le cercle ne se lirait plus.
const SPREADING := 0.8
## Les dernières secondes où le cercle s'efface, pour qu'il ne disparaisse pas d'un
## coup sur sa dernière impulsion.
const CLOSING := 0.5

var _player: Player
var _cast: SkillStats
var _tint := Color.WHITE
var _age := 0.0
var _strikes := 0
## Depuis la dernière impulsion : c'est elle que l'onde dessine.
var _since := 0.0


## L'auteur n'est pas un paramètre : portée par le joueur, elle frappe forcément pour
## lui, et le passer à part laisserait les deux se contredire.
static func emanate(player: Player, cast: SkillStats) -> HolyPulse:
	var pulse := HolyPulse.new()
	pulse._player = player
	pulse._cast = cast
	pulse._tint = DamageType.COLORS[cast.dominant_nature()]
	player.add_child(pulse)
	return pulse


func _ready() -> void:
	show_behind_parent = true
	material = ArtPalette.ADDITIVE


## Les impulsions se comptent par `strikes_over_duration()`, la fonction même de
## l'estimation : la fiche et l'émanation ne peuvent pas annoncer deux nombres.
func _physics_process(delta: float) -> void:
	if _player.is_dead:
		queue_free()
		return
	_age += delta
	_since += delta
	var total := _cast.strikes_over_duration()
	while _strikes < total and _age >= float(_strikes) * _cast.period:
		_strike()
		_strikes += 1
		_since = 0.0
	queue_redraw()
	if _age >= _cast.duration and _strikes >= total:
		queue_free()


## Un tirage par impulsion, qu'elle touche ou non : c'est un geste de l'émanation.
func _strike() -> void:
	var parts := _cast.roll(Game.rng)
	for target in Targets.in_circle(get_world_2d(), global_position, _cast.radius):
		Targets.strike(target, parts, global_position, _player.states, _cast)


## Une onde qui part du porteur à chaque impulsion, et le cercle mat qui dit jusqu'où
## elle mord. L'onde **arrive au bord**, elle ne le dépasse pas : une onde qui sort du
## cercle promettrait une portée que le coup n'a pas.
func _draw() -> void:
	var fade := clampf((_cast.duration - _age) / CLOSING, 0.0, 1.0)
	var light_color := _tint.lerp(Color.WHITE, 0.55)
	draw_circle(Vector2.ZERO, _cast.radius, Color(_tint, 0.06 * fade))
	Glow.draw_ring(self, Vector2.ZERO, _cast.radius, Color(_tint, 0.26 * fade))

	var out := clampf(_since / (_cast.period * SPREADING), 0.0, 1.0) if _cast.period > 0.0 else 1.0
	if out < 1.0:
		Glow.draw_ring(
			self, Vector2.ZERO, _cast.radius * out,
			Color(light_color, 0.9 * (1.0 - out) * fade)
		)
