class_name Explosion
extends Node2D

## L'explosion d'une boule de feu : elle frappe une fois ce qui est dans son rayon,
## sauf la cible directe qui a déjà reçu le coup, puis s'efface.
##
## **Elle naît en différé et frappe à sa première image de physique** : l'impact
## arrive dans un rappel de collision, où rien ne doit entrer dans l'arbre et où
## l'espace physique refuse les requêtes (invariant 4).

const VIE := 0.3
const ETINCELLES := 8
const CHAUD := Color(1.0, 0.9, 0.5)

var _parts: Array[float] = []
var _rayon := 0.0
## L'identifiant et non la référence : la cible directe peut être libérée avant que
## l'explosion ne frappe, et une référence libérée ne se compare plus.
var _exclue := 0
var _teinte := Color.WHITE
var _age := 0.0
var _a_frappe := false


static func poser(
	parent: Node, point: Vector2, parts: Array[float], rayon: float, exclue: Hurtbox, teinte: Color
) -> Explosion:
	var e := Explosion.new()
	e._parts = parts.duplicate()
	e._rayon = rayon
	e._exclue = exclue.get_instance_id() if exclue != null else 0
	e._teinte = teinte
	parent.add_child.call_deferred(e)
	e.set_deferred("global_position", point)
	return e


func _ready() -> void:
	z_index = 3
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m


func _physics_process(delta: float) -> void:
	if not _a_frappe:
		_a_frappe = true
		for cible in Cibles.dans_le_cercle(get_world_2d(), global_position, _rayon):
			if cible.get_instance_id() != _exclue:
				Cibles.frapper(cible, _parts, global_position)
	_age += delta
	queue_redraw()
	if _age >= VIE:
		queue_free()


## Pas de disque plein qui dure : en mélange additif sur un sol sombre, un orange
## peu opaque sortait **brun**, et l'explosion se lisait comme une flaque. Le cœur
## est chaud et s'éteint vite, l'onde et les étincelles portent le reste.
func _draw() -> void:
	var k := clampf(_age / VIE, 0.0, 1.0)
	var fondu := 1.0 - k
	var r := _rayon * (1.0 - pow(1.0 - minf(k * 1.6, 1.0), 3.0))
	var chaud := _teinte.lerp(CHAUD, 0.55)
	var coeur := clampf(1.0 - k * 2.5, 0.0, 1.0)
	if coeur > 0.0:
		draw_circle(Vector2.ZERO, maxf(r * 0.8, 1.0), Color(chaud, 0.6 * coeur))
	draw_arc(Vector2.ZERO, maxf(r, 0.5), 0.0, TAU, 32, Color(_teinte, 0.85 * fondu * fondu), 1.5)
	for i in ETINCELLES:
		var d := Vector2.from_angle(TAU * float(i) / float(ETINCELLES) + 0.3)
		draw_line(d * (r * 0.9), d * (r * 1.1 + 8.0 * k), Color(chaud, 0.9 * fondu), 1.0)
