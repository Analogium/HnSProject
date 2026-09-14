class_name Immolation
extends Node2D

## Le brasier d'Immolation, porté par le joueur : il frappe les ennemis de son
## cercle à chaque période et brûle son porteur à chaque image.
##
## **Il se résout à chaque impulsion** par `Player.resoudre()`, et relit les points
## à chaque image : un anneau retiré change la frappe suivante, et une compétence
## qu'on ne sait plus lancer — son livre a quitté le râtelier — s'éteint.

const FLAMMES := 16
const BRAISES := 10
const ALLUMAGE := 0.15
const MONTEE := 18.0
const CLAIR := Color(1.0, 0.95, 0.6)

var _joueur: Player
var _competence: Competence
var _geste: StatsDeCompetence
var _age := 0.0
var _prochaine := 0.0
## Les points de départ des escarbilles, dans le disque unité : le rayon change
## avec les nœuds, pas leur répartition.
var _braises: Array[Vector2] = []


static func allumer(joueur: Player, competence: Competence) -> Immolation:
	var aura := Immolation.new()
	aura._joueur = joueur
	aura._competence = competence
	joueur.add_child(aura)
	return aura


func _ready() -> void:
	show_behind_parent = true
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m
	var rng := RandomNumberGenerator.new()
	rng.seed = int(get_instance_id())
	for i in BRAISES:
		_braises.append(Vector2.from_angle(rng.randf_range(0.0, TAU)) * sqrt(rng.randf()) * 0.8)


func allumee() -> bool:
	return not is_queued_for_deletion()


func eteindre() -> void:
	set_physics_process(false)
	queue_free()


func _physics_process(delta: float) -> void:
	var points := _joueur.points_de_competence(_competence.id)
	if points <= 0 or _joueur.is_dead:
		eteindre()
		return
	_age += delta
	if _geste == null or _age >= _prochaine:
		_geste = _joueur.resoudre(_competence, points)
		_prochaine = _age + _geste.periode
		_frapper()
	queue_redraw()
	# En dernier : la brûlure peut tuer le porteur, qui éteint alors l'aura.
	_joueur.bruler(_geste.brulure, _geste.repartition(), delta)


func _frapper() -> void:
	var parts := _geste.tirer(Game.rng)
	for cible in Cibles.dans_le_cercle(get_world_2d(), global_position, _geste.rayon):
		Cibles.frapper(cible, parts, global_position)


func _draw() -> void:
	if _geste == null:
		return
	var r := _geste.rayon * minf(_age / ALLUMAGE, 1.0)
	var teinte: Color = DamageType.COLORS[_geste.nature_dominante()]
	var clair := teinte.lerp(CLAIR, 0.6)
	draw_circle(Vector2.ZERO, r, Color(teinte, 0.10))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(teinte, 0.30), 1.5)

	for i in FLAMMES:
		var pied := Vector2.from_angle(TAU * float(i) / float(FLAMMES) + _age * 0.5) * r * 0.92
		var hauteur := 7.0 + 3.0 * sin(_age * 9.0 + float(i) * 1.7) + 2.0 * sin(_age * 13.0 + float(i) * 0.6)
		_flamme(pied, hauteur, 2.6, Color(teinte, 0.45))
		_flamme(pied, hauteur * 0.55, 1.3, Color(clair, 0.55))

	for i in BRAISES:
		var montee := fmod(_age * 0.7 + float(i) * 0.137, 1.0)
		var p := _braises[i] * r + Vector2(sin(_age * 3.0 + float(i)) * 1.5, -montee * MONTEE)
		draw_rect(Rect2(p, Vector2.ONE), Color(clair, 0.8 * (1.0 - montee)))


## Les flammes montent vers le haut de l'écran quel que soit leur angle : un
## brasier vu de dessus en vue plongeante brûle vers le ciel, pas vers l'extérieur.
func _flamme(pied: Vector2, hauteur: float, demi_largeur: float, couleur: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		pied + Vector2(-demi_largeur, 0.0),
		pied + Vector2(demi_largeur, 0.0),
		pied + Vector2(sin(_age * 7.0 + pied.x) * 1.2, -hauteur),
	]), couleur)
