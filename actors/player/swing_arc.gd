class_name SwingArc
extends Node2D

## Trace du coup, dessinée à la volée : pas de sprite à fournir, et la portée se
## règle en même temps que la hitbox. Se place sous l'AttackPivot, donc l'arc est
## déjà orienté vers la cible.
##
## Le delta n'est volontairement pas dé-scalé : pendant le hit-stop, la lame se
## fige avec le reste du jeu.

## Bord extérieur de la lame. À garder proche de la portée de la hitbox
## (capsule décalée de 20 px, rayon 8 → 28 px de portée).
@export var outer_radius: float = 28.0
## Épaisseur maximale du croissant, atteinte au milieu de la traîne.
@export var thickness: float = 10.0
## Ouverture totale du balayage, en degrés.
@export var arc_degrees: float = 120.0
## Longueur de la traîne, en fraction de l'ouverture.
@export_range(0.1, 1.0) var trail_ratio: float = 0.5
## Moment où la trace commence à s'effacer, en fraction de la durée.
@export_range(0.0, 1.0) var fade_start: float = 0.55
## La trace vit un peu plus longtemps que la hitbox : 0.12 s de fenêtre de coup
## ne fait que 7 images, trop peu pour que l'œil lise le balayage.
@export var duration_scale: float = 1.5
@export var color: Color = Color(1.0, 0.98, 0.85, 0.9)
@export var segments: int = 18

var _t := 1.0          # progression 0 → 1, 1 = terminé
var _duration := 0.12
var _flip := false     # un coup sur deux balaie dans l'autre sens


func _ready() -> void:
	visible = false
	set_process(false)


func play(duration: float) -> void:
	_duration = maxf(duration * duration_scale, 0.01)
	_t = 0.0
	_flip = not _flip
	visible = true
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta / _duration
	if _t >= 1.0:
		_t = 1.0
		visible = false
		set_process(false)
	queue_redraw()


func _draw() -> void:
	if _t >= 1.0:
		return

	# Ease-out léger : la lame part vite puis ralentit, sans écraser le
	# balayage sur la première image.
	var eased := 1.0 - pow(1.0 - _t, 2.0)
	var total := deg_to_rad(arc_degrees)
	var head := -total * 0.5 + eased * total
	var tail := maxf(head - total * trail_ratio, -total * 0.5)
	var fade := 1.0 - smoothstep(fade_start, 1.0, _t)
	var dir := -1.0 if _flip else 1.0

	# À la toute première image, tête et traîne sont confondues : la bande a
	# une longueur angulaire nulle et draw_polygon échoue sur des quads
	# réduits à un point.
	if head - tail < 0.01:
		return

	# Un quad convexe par segment : draw_polygon triangule mal les bandes
	# concaves, et 18 appels de dessin ne coûtent rien.
	for i in segments:
		var u0 := float(i) / float(segments)
		var u1 := float(i + 1) / float(segments)
		var a0 := lerpf(tail, head, u0) * dir
		var a1 := lerpf(tail, head, u1) * dir
		var d0 := Vector2(cos(a0), sin(a0))
		var d1 := Vector2(cos(a1), sin(a1))

		# Bord extérieur circulaire, bord intérieur creusé : c'est ce qui
		# fait lire un croissant plutôt qu'un triangle. Pointes fines aux
		# deux bouts, épaisseur maximale au milieu.
		# Épaisseur minimale non nulle : à zéro le quad est dégénéré et
		# draw_polygon échoue ("triangulation failed") sur les segments des pointes.
		var r0 := outer_radius - maxf(thickness * pow(sin(PI * u0), 0.6), 0.4)
		var r1 := outer_radius - maxf(thickness * pow(sin(PI * u1), 0.6), 0.4)

		var c0 := color
		var c1 := color
		c0.a = color.a * fade * (0.2 + 0.8 * u0)
		c1.a = color.a * fade * (0.2 + 0.8 * u1)

		draw_polygon(
			PackedVector2Array([d0 * outer_radius, d1 * outer_radius, d1 * r1, d0 * r0]),
			PackedColorArray([c0, c1, c1, c0])
		)
