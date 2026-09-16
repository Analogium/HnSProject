class_name ChainLightning
extends Node2D

## La décharge de Chaîne d'éclairs : elle choisit ses cibles, les frappe, puis
## reste un quart de seconde à l'écran en trait brisé.

const SCOPE := 150.0
## Le cône de la première cible, en cosinus du demi-angle : 45° de part et d'autre
## de la visée. Plus large, la décharge part sur le voisin de l'ennemi visé.
const COS_HALF_CONE := 0.7071
const JUMP := 90.0
## Sans cible, la décharge part quand même : un sort payé qui ne montre rien se lit
## comme une touche morte.
const INTO_THE_VOID := 100.0
const LIFETIME := 0.22
const JITTER := 4.0
const STEP := 9.0

var _points := PackedVector2Array()
var _tint := Color.WHITE
var _age := 0.0
## Tirage local et jamais `Game.rng` : un grésillement qui y puiserait décalerait
## tous les tirages de la partie (invariant 3).
var _flicker := RandomNumberGenerator.new()


## Choisit les cibles, les frappe et laisse le trait. Rend le nombre d'ennemis
## touchés : le lanceur ne fige le jeu que s'il y en a.
##
## **Toutes les cibles sont choisies avant le premier coup** : une mort en cours de
## chaîne changerait ce que la requête suivante trouve.
static func unload(
	parent: Node, caster_node: Node2D, cast: SkillStats, direction: Vector2
) -> int:
	var world := caster_node.get_world_2d()
	var points := PackedVector2Array([caster_node.global_position])
	var touches: Array[Hurtbox] = []
	for i in cast.target_count():
		var from_value := points[points.size() - 1]
		var target := _nearest_one(
			world, from_value, SCOPE if i == 0 else JUMP, touches,
			direction if i == 0 else Vector2.ZERO
		)
		if target == null:
			break
		touches.append(target)
		points.append(target.global_position)
	if touches.is_empty():
		points.append(caster_node.global_position + direction * INTO_THE_VOID)

	var parts := cast.roll(Game.rng)
	var author := StatusEffects.of(caster_node)
	for i in touches.size():
		Targets.strike(touches[i], parts, points[i], author, cast)

	var trace := ChainLightning.new()
	trace._points = points
	trace._tint = DamageType.COLORS[cast.dominant_nature()]
	parent.add_child(trace)
	return touches.size()


## `cone` nul : pas de contrainte d'angle, c'est un saut.
static func _nearest_one(
	world: World2D, from_value: Vector2, scope: float, excluded_all: Array[Hurtbox], cone: Vector2
) -> Hurtbox:
	var best_one: Hurtbox = null
	var best_distance := INF
	for target in Targets.in_circle(world, from_value, scope):
		if excluded_all.has(target):
			continue
		var toward := target.global_position - from_value
		var distance := toward.length_squared()
		if cone != Vector2.ZERO and distance > 0.01 and cone.dot(toward.normalized()) < COS_HALF_CONE:
			continue
		if distance < best_distance and Targets.in_sight(world, from_value, target.global_position):
			best_one = target
			best_distance = distance
	return best_one


## Un trait droit cassé en sommets déplacés au hasard. Partagé avec les éclairs du
## nuage : deux foudres dessinées de deux façons ne se liraient pas comme la même.
static func broken(
	a: Vector2, b: Vector2, rng: RandomNumberGenerator, jitter_amount := JITTER
) -> PackedVector2Array:
	var n := maxi(ceili(a.distance_to(b) / STEP), 2)
	var across := (b - a).orthogonal().normalized()
	var out := PackedVector2Array([a])
	for k in range(1, n):
		out.append(a.lerp(b, float(k) / float(n)) + across * rng.randf_range(-jitter_amount, jitter_amount))
	out.append(b)
	return out


func _ready() -> void:
	_flicker.seed = int(get_instance_id())
	z_index = 5
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var fade := clampf(1.0 - _age / LIFETIME, 0.0, 1.0)
	var halo := Color(_tint, 0.35 * fade)
	var heart := Color(_tint.lerp(Color.WHITE, 0.55), 0.9 * fade)
	for i in _points.size() - 1:
		var breaks := broken(to_local(_points[i]), to_local(_points[i + 1]), _flicker)
		draw_polyline(breaks, halo, 3.0)
		draw_polyline(breaks, heart, 1.0)
	for i in range(1, _points.size()):
		draw_circle(to_local(_points[i]), 3.5, halo)
