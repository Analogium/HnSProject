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

const FLAMES := 5
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
	var light_color := _tint.lerp(Color.WHITE, 0.5)
	var last := _toward
	var wide := _cast.radius * 0.5
	draw_line(Vector2.ZERO, last, Color(_tint, 0.10 * fade), _cast.radius * 2.0)
	draw_line(Vector2.ZERO, last, Color(_tint, 0.35 * fade), 2.0)
	draw_circle(Vector2.ZERO, wide, Color(_tint, 0.12 * fade))
	draw_circle(last, wide, Color(_tint, 0.12 * fade))

	# Les langues montent vers le haut de l'écran, comme celles d'Immolation : une
	# traînée vue de dessus brûle vers le ciel.
	for i in FLAMES:
		var u := (float(i) + 0.5) / float(FLAMES)
		var foot := last * u
		var height := 5.0 + 3.0 * sin(_age * 8.0 + float(i) * 1.9)
		var half := 1.0 + wide * 0.2
		draw_colored_polygon(PackedVector2Array([
			foot + Vector2(-half, 0.0),
			foot + Vector2(half, 0.0),
			foot + Vector2(sin(_age * 6.0 + foot.x) * 1.2, -height * fade),
		]), Color(light_color, 0.5 * fade))
