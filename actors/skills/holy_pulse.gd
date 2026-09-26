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
## Les dernières secondes où le halo au sol s'efface, pour qu'il ne disparaisse pas
## d'un coup sur sa dernière impulsion. Lui seul s'efface : il est tramé, donc fait
## pour ça.
const CLOSING := 0.5
## Les grains d'une onde. **Leur nombre ne change pas** : c'est en s'écartant les
## uns des autres qu'ils disent que l'onde s'ouvre, et ils n'ont donc jamais besoin
## de pâlir.
const GRAINS := 16

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
	Settings.veil(pulse, Settings.SPELLS)
	return pulse


## Pas de lumière ajoutée : les grains sont **dessinés**, et une planche cernée ne
## peut pas être additive — son contour sombre n'y ajoute rien.
func _ready() -> void:
	show_behind_parent = true


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


## Une onde de grains qui part du porteur à chaque impulsion, et le halo tramé qui
## dit jusqu'où elle mord. L'onde **arrive au bord**, elle ne le dépasse pas : une
## onde qui sort du cercle promettrait une portée que le coup n'a pas.
func _draw() -> void:
	var fade := clampf((_cast.duration - _age) / CLOSING, 0.0, 1.0)
	var radius := maxi(int(round(_cast.radius)), 1)
	draw_texture_rect(
		EffectForge.scorch(_tint, radius),
		Rect2(
			EffectForge.snap(self, -Vector2(radius, radius)),
			Vector2.ONE * float(radius * 2 + 1)
		),
		false, Color(1.0, 1.0, 1.0, fade)
	)

	var out := clampf(_since / (_cast.period * SPREADING), 0.0, 1.0) if _cast.period > 0.0 else 1.0
	if out >= 1.0:
		return
	for i in GRAINS:
		var at := Vector2.from_angle(TAU * float(i) / float(GRAINS) + out) * _cast.radius * out
		Holy.spark(self, at, _tint, fade)
