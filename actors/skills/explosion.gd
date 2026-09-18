class_name Explosion
extends Node2D

## L'explosion d'une boule de feu : elle frappe une fois ce qui est dans son rayon,
## sauf la cible directe qui a déjà reçu le coup, puis s'efface.
##
## **Elle naît en différé et frappe à sa première image de physique** : l'impact
## arrive dans un rappel de collision, où rien ne doit entrer dans l'arbre et où
## l'espace physique refuse les requêtes (invariant 4).

const LIFETIME := 0.3
const SPARKS := 8
const WARM := Color(1.0, 0.9, 0.5)

var _parts: Array[float] = []
var _author: StatusEffects
var _cast: SkillStats
var _radius := 0.0
## L'identifiant et non la référence : la cible directe peut être libérée avant que
## l'explosion ne frappe, et une référence libérée ne se compare plus.
var _excluded := 0
var _tint := Color.WHITE
var _age := 0.0
var _has_struck := false


static func put(
	parent: Node, point: Vector2, parts: Array[float], radius: float, excluded: Hurtbox, tint: Color,
	author: StatusEffects, cast: SkillStats
) -> Explosion:
	var e := Explosion.new()
	e._author = author
	e._cast = cast
	e._parts = parts.duplicate()
	e._radius = radius
	e._excluded = excluded.get_instance_id() if excluded != null else 0
	e._tint = tint
	DeferredTree.add_deferred(parent, e, point)
	return e


func _ready() -> void:
	z_index = 3
	material = ArtPalette.ADDITIVE


func _physics_process(delta: float) -> void:
	if not _has_struck:
		_has_struck = true
		for target in Targets.in_circle(get_world_2d(), global_position, _radius):
			if target.get_instance_id() != _excluded:
				Targets.strike(target, _parts, global_position, _author, _cast)
	_age += delta
	queue_redraw()
	if _age >= LIFETIME:
		queue_free()


## Pas de disque plein qui dure : en mélange additif sur un sol sombre, un orange
## peu opaque sortait **brun**, et l'explosion se lisait comme une flaque. Le cœur
## est chaud et s'éteint vite, l'onde et les étincelles portent le reste.
func _draw() -> void:
	var k := clampf(_age / LIFETIME, 0.0, 1.0)
	var fade := 1.0 - k
	var r := _radius * (1.0 - pow(1.0 - minf(k * 1.6, 1.0), 3.0))
	var warm := _tint.lerp(WARM, 0.55)
	var heart := clampf(1.0 - k * 2.5, 0.0, 1.0)
	if heart > 0.0:
		draw_circle(Vector2.ZERO, maxf(r * 0.8, 1.0), Color(warm, 0.6 * heart))
	draw_arc(Vector2.ZERO, maxf(r, 0.5), 0.0, TAU, 32, Color(_tint, 0.85 * fade * fade), 1.5)
	for i in SPARKS:
		var d := Vector2.from_angle(TAU * float(i) / float(SPARKS) + 0.3)
		draw_line(d * (r * 0.9), d * (r * 1.1 + 8.0 * k), Color(warm, 0.9 * fade), 1.0)
