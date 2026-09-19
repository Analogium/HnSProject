class_name StormCloud
extends Node2D

## Le nuage de Nuage d'orage : posé, il frappe tout ce qui est dessous à chaque
## période, puis se dissipe. Il ne fige jamais le jeu — une impulsion qui gèle
## toutes les demi-secondes hacherait l'image tant qu'il est posé.

## Le nuage flotte au-dessus de sa zone ; c'est le cercle au sol qui dit où elle est.
const HEIGHT := 22.0
const PUFFS := 7
const SPAWN := 0.2
const DISSIPATION := 0.3
const BOLT_LIFETIME := 0.14
## Le nuage s'éclaire de la couleur de la foudre juste après avoir frappé.
const FLASH_COLOR := 0.12
const BODY := Color(0.20, 0.19, 0.27)
const ABOVE := Color(0.38, 0.36, 0.48)


class Puff:
	var center: Vector2
	var radius: float
	var phase: float


class Bolt:
	var of: Vector2
	var toward: Vector2
	var age := 0.0


var _cast: SkillStats
var _author: StatusEffects
var _tint := Color.WHITE
var _age := 0.0
var _strikes := 0
var _puffs: Array[Puff] = []
var _bolts: Array[Bolt] = []
var _flicker := RandomNumberGenerator.new()


static func put(parent: Node, point: Vector2, cast: SkillStats, author: StatusEffects) -> StormCloud:
	var cloud := StormCloud.new()
	cloud._cast = cast
	cloud._author = author
	cloud._tint = DamageType.COLORS[cast.dominant_nature()]
	parent.add_child(cloud)
	cloud.global_position = point
	return cloud


func _ready() -> void:
	z_index = 4
	_flicker.seed = int(get_instance_id())
	var extent := _cast.radius * 0.7
	for i in PUFFS:
		var b := Puff.new()
		var u := float(i) / float(PUFFS - 1)
		b.center = Vector2(
			lerpf(-extent, extent, u) + _flicker.randf_range(-2.0, 2.0),
			-HEIGHT + _flicker.randf_range(-4.0, 3.0)
		)
		# Plus gros au milieu : un nuage est bombé, une rangée de disques égaux se lit
		# comme une chenille.
		b.radius = lerpf(5.5, 9.5, 1.0 - absf(u - 0.5) * 2.0)
		b.phase = _flicker.randf_range(0.0, TAU)
		_puffs.append(b)


## Les frappes se comptent par `strikes_over_duration()`, la fonction même de
## l'estimation : la fiche et le nuage ne peuvent pas annoncer deux nombres.
func _physics_process(delta: float) -> void:
	_age += delta
	var total := _cast.strikes_over_duration()
	while _strikes < total and _age >= float(_strikes) * _cast.period:
		_strike()
		_strikes += 1
	for e in _bolts:
		e.age += delta
	_bolts = _bolts.filter(func(e: Bolt) -> bool: return e.age < BOLT_LIFETIME)
	queue_redraw()
	if _age >= _cast.duration and _strikes >= total:
		queue_free()


## Un tirage par impulsion, qu'elle touche ou non : c'est un geste du nuage.
func _strike() -> void:
	var parts := _cast.roll(Game.rng)
	var targets := Targets.in_circle(get_world_2d(), global_position, _cast.radius)
	for target in targets:
		_bolt_to(to_local(target.global_position))
		Targets.strike(target, parts, global_position, _author, _cast)
	if targets.is_empty():
		# Un éclair au sol même sans cible : le nuage montre qu'il frappe, et où.
		_bolt_to(
			Vector2.from_angle(_flicker.randf_range(0.0, TAU))
			* _flicker.randf_range(0.0, _cast.radius * 0.8)
		)


func _bolt_to(point: Vector2) -> void:
	var e := Bolt.new()
	var edge := _cast.radius * 0.6
	e.of = Vector2(clampf(point.x, -edge, edge), -HEIGHT + 4.0)
	e.toward = point
	_bolts.append(e)


func _draw() -> void:
	var fade := minf(_age / SPAWN, 1.0) * clampf((_cast.duration - _age) / DISSIPATION, 0.0, 1.0)
	draw_circle(Vector2.ZERO, _cast.radius, Color(_tint, 0.07 * fade))
	Glow.draw_ring(self, Vector2.ZERO, _cast.radius, Color(_tint, 0.36 * fade))

	var from_value := _age - float(maxi(_strikes - 1, 0)) * _cast.period
	var flash := clampf(1.0 - from_value / FLASH_COLOR, 0.0, 1.0)
	var dark := Color(BODY.lerp(_tint, 0.25 * flash), 0.9 * fade)
	var light_color := Color(ABOVE.lerp(_tint, 0.45 * flash), 0.9 * fade)
	for b in _puffs:
		draw_circle(b.center + Vector2(0.0, sin(_age * 1.8 + b.phase)), b.radius, dark)
	# Le dessus plus clair, décalé vers la lumière du jeu — en haut à gauche.
	for b in _puffs:
		draw_circle(b.center + Vector2(-1.0, sin(_age * 1.8 + b.phase) - 2.0), b.radius * 0.6, light_color)

	for e in _bolts:
		var k := 1.0 - e.age / BOLT_LIFETIME
		_flicker.seed = int(get_instance_id()) ^ Lightning.hold(e.age) ^ int(e.toward.x)
		# Une seule fourche : l'éclair du nuage est court, deux le brouilleraient.
		Lightning.draw_bolt(self, e.of, e.toward, _flicker, _tint, k, 0.75, 1)
		Lightning.draw_strike(self, e.toward, _tint, k, 6.0)
