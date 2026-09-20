class_name IceVortex
extends Node2D

## Le vortex de Désastre hivernal : posé sur le personnage, il **grandit pendant toute
## sa durée** et frappe son cercle à chaque période. C'est la croissance qui le sépare du
## nuage d'orage : on le pose tôt, il paie tard.
##
## Il ne fige jamais le jeu — une impulsion qui gèle toutes les demi-secondes hacherait
## l'image tant qu'il tourne.

## Le rayon de départ, en part du rayon final : sous un tiers, ses premières impulsions
## ne toucheraient que ce qui est déjà sur le personnage.
const SEED_PART := 0.35
## Les bras de la spirale, leur vitesse en tours par seconde, et le nombre de
## segments de chacun — c'est leur petit nombre qui rend la spirale brisée.
const ARMS := 4
const SPIN := 1.6
const STEPS := 5
## Les éclats emportés par le tour.
const SHARDS := 12
const FADE := 0.4

var _cast: SkillStats
var _author: StatusEffects
var _tint := Color.WHITE
var _age := 0.0
var _strikes := 0
var _flicker := RandomNumberGenerator.new()


static func open(
	parent: Node, point: Vector2, cast: SkillStats, author: StatusEffects
) -> IceVortex:
	var vortex := IceVortex.new()
	vortex._cast = cast
	vortex._author = author
	vortex._tint = DamageType.COLORS[cast.dominant_nature()]
	parent.add_child(vortex)
	vortex.global_position = point
	return vortex


func _ready() -> void:
	z_index = 3
	material = ArtPalette.ADDITIVE
	_flicker.seed = int(get_instance_id())


## Ce qu'il couvre maintenant : de `SEED_PART` à son rayon plein, linéairement.
func reach() -> float:
	var grown := clampf(_age / _cast.duration, 0.0, 1.0) if _cast.duration > 0.0 else 1.0
	return _cast.radius * lerpf(SEED_PART, 1.0, grown)


## Les impulsions se comptent par `strikes_over_duration()`, la fonction même de
## l'estimation : la fiche et le vortex ne peuvent pas annoncer deux nombres.
func _physics_process(delta: float) -> void:
	_age += delta
	var total := _cast.strikes_over_duration()
	while _strikes < total and _age >= float(_strikes) * _cast.period:
		_strike()
		_strikes += 1
	queue_redraw()
	if _age >= _cast.duration and _strikes >= total:
		queue_free()


## Un tirage par impulsion, qu'elle touche ou non : c'est un geste du vortex.
func _strike() -> void:
	var parts := _cast.roll(Game.rng)
	for target in Targets.in_circle(get_world_2d(), global_position, reach()):
		Targets.strike(target, parts, global_position, _author, _cast)


## Des bras en spirale plutôt qu'un disque : c'est le seul dessin qui montre à la fois
## où il mord — le cercle au bout des bras — et qu'il tourne.
func _draw() -> void:
	var r := reach()
	var fade := clampf((_cast.duration - _age) / (_cast.duration * FADE), 0.0, 1.0)
	var rim := Frost.rim(_tint)
	# Un disque plein sortait comme une flaque à bord net ; le cœur de lumière a la
	# même portée et s'éteint vers le bord, et c'est l'anneau qui dit où ça mord.
	Glow.draw_blob(self, Vector2.ZERO, r, Color(_tint, 0.12 * fade))
	Glow.draw_ring(self, Vector2.ZERO, r, Color(_tint, 0.42 * fade))

	for i in ARMS:
		var base := TAU * float(i) / float(ARMS) + _age * SPIN
		var curve := PackedVector2Array()
		# Cinq segments et non neuf : une spirale lisse se lit comme un coup de
		# pinceau, une spirale brisée comme de la glace.
		for step in STEPS + 1:
			var u := float(step) / float(STEPS)
			# L'angle avance avec le rayon : c'est ce décalage qui fait la spirale.
			curve.append(Vector2.from_angle(base + u * 1.9) * r * u)
		# Deux passes : un bras d'un seul pixel est un tracé, pas une bourrasque.
		draw_polyline(curve, Color(_tint, 0.32 * fade), 4.0)
		draw_polyline(curve, Color(rim, 0.60 * fade), 1.0)
		# Une lame au bout du bras, couchée sur la spirale : c'est elle qui donne le
		# sens de rotation, qu'un trait qui tourne ne donne pas.
		var last := curve[curve.size() - 1]
		var along := (last - curve[curve.size() - 2]).normalized()
		Frost.draw_shard(self, last - along * 9.0, along, 9.0, 2.6, _tint, fade, 1.5)

	for i in SHARDS:
		var turn := _age * SPIN * 1.4 + TAU * float(i) / float(SHARDS)
		# Ils tombent vers le cœur : un vortex aspire, il ne rayonne pas.
		var away := 1.0 - fmod(_age * 0.6 + float(i) * 0.137, 1.0)
		Frost.draw_flake(self, Vector2.from_angle(turn) * r * away, _tint, 0.8 * away * fade)
