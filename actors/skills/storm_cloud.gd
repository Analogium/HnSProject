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
const FLASH_MIX := 0.35
const CLOUD := Color(0.30, 0.28, 0.40)


class Bolt:
	var of: Vector2
	var toward: Vector2
	var age := 0.0
	var shown := -1
	var pieces: Array[EffectForge.Piece]


static var _bodies := {}


var _cast: SkillStats
var _author: StatusEffects
var _tint := Color.WHITE
var _age := 0.0
var _strikes := 0
var _bolts: Array[Bolt] = []
var _flicker := RandomNumberGenerator.new()


static func put(parent: Node, point: Vector2, cast: SkillStats, author: StatusEffects) -> StormCloud:
	var cloud := StormCloud.new()
	cloud._cast = cast
	cloud._author = author
	cloud._tint = DamageType.COLORS[cast.dominant_nature()]
	parent.add_child(cloud)
	Settings.veil(cloud, Settings.SPELLS)
	cloud.global_position = point
	return cloud


func _ready() -> void:
	z_index = 4
	_flicker.seed = int(get_instance_id())


## Le corps du nuage, rastérisé d'un coup — sept bosses, une silhouette, un
## contour — et gardé : un rayon ne change qu'avec un point de talent. Choisi sur
## planche : le nuage **bombé**, éclairé d'en haut à gauche comme le reste du jeu.
static func body(radius: float, tint: Color, flash: bool, gone: float) -> EffectForge.Piece:
	var key := "%s|%d|%d|%d" % [tint.to_html(false), int(radius), int(flash), int(round(gone * 16.0))]
	if _bodies.has(key):
		return _bodies[key]
	# Graine fixe : le même nuage à chaque lancer, ses quatre états compris.
	var rng := RandomNumberGenerator.new()
	rng.seed = PUFFS
	var extent := radius * 0.7
	var margin := 16.0
	var canvas := PixelCanvas.new(int(ceil((extent + margin) * 2.0)), int(margin * 2.0))
	var middle := Vector2(canvas.width, canvas.height) * 0.5
	for i in PUFFS:
		var u := float(i) / float(PUFFS - 1)
		# Plus gros au milieu : un nuage est bombé, une rangée de disques égaux se lit
		# comme une chenille.
		canvas.disc(
			middle + Vector2(lerpf(-extent, extent, u) + rng.randf_range(-2.0, 2.0), rng.randf_range(-4.0, 3.0)),
			lerpf(5.5, 9.5, 1.0 - absf(u - 0.5) * 2.0), 0
		)
	var img := canvas.to_image([ArtPalette.ramp(CLOUD.lerp(tint, FLASH_MIX) if flash else CLOUD)])
	EffectForge.dissolve(img, gone)
	var piece := EffectForge.Piece.new(ImageTexture.create_from_image(img), -middle)
	_bodies[key] = piece
	return piece


## Les frappes se comptent par `strikes_over_duration()`, la fonction même de
## l'estimation : la fiche et le nuage ne peuvent pas annoncer deux nombres.
func _physics_process(delta: float) -> void:
	_age += delta
	var due := _cast.strikes_due(_age)
	while _strikes < due:
		_strike()
		_strikes += 1
	for e in _bolts:
		e.age += delta
	_bolts = _bolts.filter(func(e: Bolt) -> bool: return e.age < BOLT_LIFETIME)
	queue_redraw()
	if _age >= _cast.duration and _strikes >= _cast.strikes_over_duration():
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
	# Le halo au sol dit la zone : tramé, il a le droit de s'effacer. Le nuage, lui,
	# se défait en naissant et en se dissipant.
	var zone := EffectForge.scorch(_tint, int(round(_cast.radius)))
	var zone_size := Vector2(zone.get_width(), zone.get_height())
	draw_texture(zone, EffectForge.snap(self, -zone_size * 0.5), Color(1.0, 1.0, 1.0, fade))

	var since := _age - float(maxi(_strikes - 1, 0)) * _cast.period
	var bob := Vector2(0.0, roundf(sin(_age * 1.8)))
	body(
		_cast.radius, _tint, since < FLASH_COLOR, 0.0 if fade >= 1.0 else Lightning.GONE
	).put(self, Vector2(0.0, -HEIGHT) + bob)

	for e in _bolts:
		var beat := Lightning.hold(e.age)
		if beat != e.shown:
			e.shown = beat
			_flicker.seed = int(get_instance_id()) ^ beat ^ int(e.toward.x)
			# Une seule fourche : l'éclair du nuage est court, deux le brouilleraient.
			e.pieces = Lightning.chain(
				PackedVector2Array([e.of, e.toward]), _flicker, _tint, 1, true,
				Lightning.gone(e.age, BOLT_LIFETIME)
			)
		Lightning.put(self, e.pieces)
