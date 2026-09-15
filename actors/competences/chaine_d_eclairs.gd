class_name ChaineDEclairs
extends Node2D

## La décharge de Chaîne d'éclairs : elle choisit ses cibles, les frappe, puis
## reste un quart de seconde à l'écran en trait brisé.

const PORTEE := 150.0
## Le cône de la première cible, en cosinus du demi-angle : 45° de part et d'autre
## de la visée. Plus large, la décharge part sur le voisin de l'ennemi visé.
const COS_DU_DEMI_CONE := 0.7071
const SAUT := 90.0
## Sans cible, la décharge part quand même : un sort payé qui ne montre rien se lit
## comme une touche morte.
const DANS_LE_VIDE := 100.0
const VIE := 0.22
const GIGUE := 4.0
const PAS := 9.0

var _points := PackedVector2Array()
var _teinte := Color.WHITE
var _age := 0.0
## Tirage local et jamais `Game.rng` : un grésillement qui y puiserait décalerait
## tous les tirages de la partie (invariant 3).
var _scintille := RandomNumberGenerator.new()


## Choisit les cibles, les frappe et laisse le trait. Rend le nombre d'ennemis
## touchés : le lanceur ne fige le jeu que s'il y en a.
##
## **Toutes les cibles sont choisies avant le premier coup** : une mort en cours de
## chaîne changerait ce que la requête suivante trouve.
static func decharger(
	parent: Node, lanceur: Node2D, geste: StatsDeCompetence, direction: Vector2
) -> int:
	var monde := lanceur.get_world_2d()
	var points := PackedVector2Array([lanceur.global_position])
	var touches: Array[Hurtbox] = []
	for i in geste.nombre_de_cibles():
		var depuis := points[points.size() - 1]
		var cible := _la_plus_proche(
			monde, depuis, PORTEE if i == 0 else SAUT, touches,
			direction if i == 0 else Vector2.ZERO
		)
		if cible == null:
			break
		touches.append(cible)
		points.append(cible.global_position)
	if touches.is_empty():
		points.append(lanceur.global_position + direction * DANS_LE_VIDE)

	var parts := geste.tirer(Game.rng)
	var auteur := Etats.de(lanceur)
	for i in touches.size():
		Cibles.frapper(touches[i], parts, points[i], auteur)

	var trace := ChaineDEclairs.new()
	trace._points = points
	trace._teinte = DamageType.COLORS[geste.nature_dominante()]
	parent.add_child(trace)
	return touches.size()


## `cone` nul : pas de contrainte d'angle, c'est un saut.
static func _la_plus_proche(
	monde: World2D, depuis: Vector2, portee: float, exclues: Array[Hurtbox], cone: Vector2
) -> Hurtbox:
	var meilleure: Hurtbox = null
	var meilleure_distance := INF
	for cible in Cibles.dans_le_cercle(monde, depuis, portee):
		if exclues.has(cible):
			continue
		var vers := cible.global_position - depuis
		var distance := vers.length_squared()
		if cone != Vector2.ZERO and distance > 0.01 and cone.dot(vers.normalized()) < COS_DU_DEMI_CONE:
			continue
		if distance < meilleure_distance and Cibles.a_vue(monde, depuis, cible.global_position):
			meilleure = cible
			meilleure_distance = distance
	return meilleure


## Un trait droit cassé en sommets déplacés au hasard. Partagé avec les éclairs du
## nuage : deux foudres dessinées de deux façons ne se liraient pas comme la même.
static func brisee(
	a: Vector2, b: Vector2, rng: RandomNumberGenerator, gigue := GIGUE
) -> PackedVector2Array:
	var n := maxi(ceili(a.distance_to(b) / PAS), 2)
	var travers := (b - a).orthogonal().normalized()
	var out := PackedVector2Array([a])
	for k in range(1, n):
		out.append(a.lerp(b, float(k) / float(n)) + travers * rng.randf_range(-gigue, gigue))
	out.append(b)
	return out


func _ready() -> void:
	_scintille.seed = int(get_instance_id())
	z_index = 5
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m


func _process(delta: float) -> void:
	_age += delta
	if _age >= VIE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var fondu := clampf(1.0 - _age / VIE, 0.0, 1.0)
	var halo := Color(_teinte, 0.35 * fondu)
	var coeur := Color(_teinte.lerp(Color.WHITE, 0.55), 0.9 * fondu)
	for i in _points.size() - 1:
		var brise := brisee(to_local(_points[i]), to_local(_points[i + 1]), _scintille)
		draw_polyline(brise, halo, 3.0)
		draw_polyline(brise, coeur, 1.0)
	for i in range(1, _points.size()):
		draw_circle(to_local(_points[i]), 3.5, halo)
