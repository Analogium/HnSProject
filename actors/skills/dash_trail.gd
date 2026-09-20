class_name DashTrail
extends Node2D

## Ce qu'une ruée laisse derrière elle : un couloir qui frappe ce qui s'y trouve, une
## fois par période, jusqu'à la fin de sa durée. Il ne fige jamais le jeu, comme tout
## ce qui dure.
##
## Le couloir est une **file de cercles** le long du segment : `Targets.in_circle()` est
## le seul chemin des coups sans collision, et il ne connaît que le cercle.

## L'écart entre deux sondes, en part du rayon. Au-delà de 1, un ennemi peut tenir entre
## deux cercles ; en dessous, on paie des requêtes pour rien.
const STEP := 0.9

## Une langue tous les treize pixels, quatre au moins : à cinq langues pour un
## couloir entier, on voyait le ruban brun avant de voir le feu.
const FLAME_STEP := 13.0
const FLAMES_MIN := 4
const SPAWN := 0.12
const FADE := 0.35

var _cast: SkillStats
var _author: StatusEffects
var _tint := Color.WHITE
## En repère local : le nœud est posé au départ de la ruée.
var _toward := Vector2.ZERO
var _age := 0.0
var _strikes := 0
var _flicker := RandomNumberGenerator.new()


static func leave(
	parent: Node, from_value: Vector2, to: Vector2, cast: SkillStats, author: StatusEffects
) -> DashTrail:
	var trail := DashTrail.new()
	trail._cast = cast
	trail._author = author
	trail._toward = to - from_value
	trail._tint = DamageType.COLORS[cast.dominant_nature()]
	parent.add_child(trail)
	trail.global_position = from_value
	return trail


func _ready() -> void:
	z_index = 2
	material = ArtPalette.ADDITIVE
	_flicker.seed = int(get_instance_id())


## Les impulsions se comptent par `strikes_over_duration()`, la fonction même de
## l'estimation : la fiche et la trace ne peuvent pas annoncer deux nombres.
func _physics_process(delta: float) -> void:
	_age += delta
	var total := _cast.strikes_over_duration()
	while _strikes < total and _age >= float(_strikes) * _cast.period:
		_strike()
		_strikes += 1
	queue_redraw()
	if _age >= _cast.duration and _strikes >= total:
		queue_free()


## Un tirage par impulsion et non par cercle : c'est un geste de la trace, pas un coup
## par sonde. Une cible sous deux cercles ne reçoit qu'un coup.
func _strike() -> void:
	var parts := _cast.roll(Game.rng)
	var struck := {}
	for point in _probes():
		for target in Targets.in_circle(get_world_2d(), point, _cast.radius):
			var id := target.get_instance_id()
			if struck.has(id):
				continue
			struck[id] = true
			Targets.strike(target, parts, point, _author, _cast)


## Les centres des sondes, en repère global : les deux bouts au moins.
func _probes() -> Array[Vector2]:
	var out: Array[Vector2] = []
	var span := _toward.length()
	var count := maxi(ceili(span / maxf(_cast.radius * STEP, 1.0)), 1)
	for i in count + 1:
		out.append(global_position + _toward * (float(i) / float(count)))
	return out


func _draw() -> void:
	var fade := minf(_age / SPAWN, 1.0) * clampf((_cast.duration - _age) / FADE, 0.0, 1.0)
	var last := _toward
	var wide := _cast.radius * 0.5
	# Le ruban large dit la portée et rien d'autre : à 0,10 d'un orange, il sortait
	# **brun**, et on voyait un tapis avant de voir le feu (même piège qu'`Explosion`).
	draw_line(Vector2.ZERO, last, Color(_tint, 0.06 * fade), _cast.radius * 2.0)
	Glow.draw_blob(self, Vector2.ZERO, wide, Color(_tint, 0.30 * fade))
	Glow.draw_blob(self, last, wide, Color(_tint, 0.30 * fade))

	# **Le couloir luit pour tout le monde ; sa matière est par nature.** Le feu
	# lèche, la foudre grésille, le reste ne fait que luire : une ruée de glace
	# n'avait aucune raison de laisser des flammes. Aucun de ces dessins ne frappe
	# — la morsure, c'est le couloir.
	match _cast.dominant_nature():
		DamageType.Kind.LIGHTNING:
			# Refait deux fois par dixième de seconde : c'est le grésillement.
			_flicker.seed = int(get_instance_id()) ^ Lightning.hold(_age)
			Lightning.draw_bolt(self, Vector2.ZERO, last, _flicker, _tint, 0.85 * fade, 0.7, 2)
		DamageType.Kind.FIRE:
			var flames := maxi(int(last.length() / FLAME_STEP), FLAMES_MIN)
			for i in flames:
				var foot := last * ((float(i) + 0.5) / float(flames))
				var tall := 6.0 + 4.0 * float((i * 7) % 5) / 4.0
				Fire.draw_tongue(
					self, foot, Vector2.UP, (tall + 3.0 * Fire.breath(_age, i)) * fade,
					1.0 + wide * 0.2, _tint, fade, 1.4 * Fire.breath(_age * 0.7, i + 5)
				)
		_:
			# Les natures sans matière propre n'ont que ce trait : le feu et la foudre
			# s'en passent, il leur barrait leurs propres flammes d'une ligne droite.
			draw_line(Vector2.ZERO, last, Color(_tint, 0.30 * fade), 2.0)
