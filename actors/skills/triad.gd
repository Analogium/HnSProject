class_name Triad
extends Node2D

## La Triade (jalon 41) : trois comètes, une par élément, naissent autour du lanceur et se
## rejoignent au point visé, où elles éclatent ensemble — un coup qui porte les trois
## natures (`SkillStats.blend()`), donc trois tirages d'état. **En route, chacune perce** :
## ce qu'elle traverse prend sa part, dans son seul élément, une fois. Ce qui est déjà dans
## le cercle de l'éclat n'est frappé que par lui, sans quoi le point visé prendrait tout deux fois.

## À quelle distance du lanceur elles naissent, et le temps qu'elles mettent à se rejoindre.
const SPAWN := 16.0
const TRAVEL := 0.35
## La largeur de ce qu'une comète touche en route : sa tête (`Comet.HEAD`, de rayon 2,6).
const WIDTH := 6.0

var _cast: SkillStats
var _author: StatusEffects
## Le départ de chaque comète, relatif au point visé, sa teinte, sa part du coup — tirée
## une fois au départ, comme un trait —, et ce qu'elle a déjà frappé.
var _starts: Array[Vector2] = []
var _tints: Array[Color] = []
var _parts: Array = []
var _struck: Array[Dictionary] = []
var _age := 0.0


static func converge(
	parent: Node, origin: Vector2, aim: Vector2, cast: SkillStats, author: StatusEffects
) -> Triad:
	var t := Triad.new()
	t._cast = cast
	t._author = author
	var natures: Array[int] = []
	for n in cast.damage_max.size():
		if cast.damage_max[n] > 0.0:
			natures.append(n)
	if natures.is_empty():
		natures.append(cast.nature)
	var toward := origin.direction_to(aim) if origin != aim else Vector2.RIGHT
	var rolled := cast.roll(Game.rng)
	for i in natures.size():
		var around := toward.rotated(TAU * float(i) / float(natures.size())) * SPAWN
		t._starts.append(origin + around - aim)
		t._tints.append(DamageType.COLORS[natures[i]])
		var own := DamageType.empty_parts()
		own[natures[i]] = rolled[natures[i]]
		t._parts.append(own)
		t._struck.append({})
	parent.add_child(t)
	Settings.veil(t, Settings.SPELLS)
	t.global_position = aim
	return t


func _physics_process(delta: float) -> void:
	var before := _age
	_age = minf(_age + delta, TRAVEL)
	for i in _starts.size():
		_pierce(i, _at(i, before), _at(i, _age))
	if _age >= TRAVEL:
		Explosion.of_cast(get_parent(), global_position, _cast, _cast.radius, _author)
		queue_free()
		return
	queue_redraw()


## Où est la comète `i` à cet âge, relativement au point visé : elle accélère en arrivant.
func _at(i: int, age: float) -> Vector2:
	var t := age / TRAVEL
	return _starts[i].lerp(Vector2.ZERO, t * t)


## Ce que la comète a traversé depuis l'image précédente, hors du cercle de l'éclat.
func _pierce(i: int, from: Vector2, to: Vector2) -> void:
	for target in Targets.in_capsule(get_world_2d(), global_position + from, global_position + to, WIDTH):
		var id := target.get_instance_id()
		if _struck[i].has(id) or target.global_position.distance_to(global_position) <= _cast.radius:
			continue
		_struck[i][id] = true
		Targets.strike(target, _parts[i], global_position + to, _author, _cast)


func _draw() -> void:
	for i in _starts.size():
		var turn := Slash.turn_of((-_starts[i]).angle())
		Comet.piece(_tints[i], turn, int(_age * Comet.HZ) + i).put(self, _at(i, _age))
