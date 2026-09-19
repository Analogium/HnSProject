class_name SwingArc
extends Node2D

## Trace du coup, dessinée à la volée : pas de sprite à fournir, et la portée se
## règle en même temps que la hitbox. Se place sous l'AttackPivot, donc l'arc est
## déjà orienté vers la cible.
##
## Le delta n'est volontairement pas dé-scalé : pendant le hit-stop, la lame se
## fige avec le reste du jeu.

## Le dessin, que la forme de la compétence choisit. La hitbox, elle, est la même
## pour les trois : chaque dessin reste dans sa capsule.
enum Style { ARC, STRIKE, CROSS }

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

## La frappe lourde : un croissant plus épais, plus ouvert, plus lent, qui finit sur
## un impact. Sa lenteur est celle du dessin seulement — la hitbox garde la durée
## du coup, sinon le coup lourd deviendrait aussi un coup plus long.
const STRIKE_RADIUS := 30.0
const STRIKE_THICKNESS := 15.0
const STRIKE_OPENING := 150.0
const STRIKE_SLOWNESS := 1.3
const STRIKE_COLOR := Color(1.0, 0.85, 0.6, 0.95)
## Le croissant occupe le début de la trace, l'impact commence avant qu'il ne
## finisse : un blanc entre les deux se lirait comme deux coups.
const STRIKE_CRESCENT_END := 0.6
const STRIKE_IMPACT_START := 0.45
## L'impact tombe au centre de la capsule de la hitbox.
const IMPACT := Vector2(20.0, 0.0)
const CRACKS := 5
## L'impact est posé **au sol** : une ellipse écrasée en hauteur, qui ne tourne pas
## avec la visée. Un cercle parfait traversé de fissures droites se lisait comme une
## roue à rayons.
const FLATTENED := Vector2(1.0, 0.55)
## Claires : sur le sol sombre des zones, des fissures et une poussière foncées ne
## se voyaient pas du tout à la capture.
const WAVE := Color(1.0, 0.92, 0.70)
const FISSURE := Color(0.85, 0.78, 0.62)
const DUST := Color(0.72, 0.66, 0.56)

## Le coup en croix : deux entailles droites en coordonnées du pivot, qui couvrent la
## capsule — de 6 à 30 pixels devant, 14 de part et d'autre.
const CROSS := [[Vector2(6.0, -14.0), Vector2(30.0, 14.0)], [Vector2(6.0, 14.0), Vector2(30.0, -14.0)]]
const CROSS_COLOR := Color(0.92, 0.96, 1.0, 0.95)
## Chaque entaille vit sur une fenêtre de la moitié de la trace ; la seconde part
## quand la première s'achève.
const CROSS_WINDOW := 0.5
const CROSS_OFFSET := 0.42
## Le moment où la seconde entaille passe sur la première, et l'éclat qui le marque.
const CROSS_CROSSING := 0.53
const CROSS_FLASH := 0.08

var _t := 1.0          # progression 0 → 1, 1 = terminé
var _duration := 0.12
var _flip := false     # un coup sur deux balaie dans l'autre sens
var _style := Style.ARC
## Chaque fissure est une ligne brisée, tirée au départ du coup.
var _cracks: Array[PackedVector2Array] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	visible = false
	set_process(false)
	_rng.seed = int(get_instance_id())


func play(duration: float, style := Style.ARC) -> void:
	_style = style
	_duration = maxf(duration * duration_scale * (STRIKE_SLOWNESS if style == Style.STRIKE else 1.0), 0.01)
	_t = 0.0
	_flip = not _flip
	if style == Style.STRIKE:
		# Des fissures neuves à chaque coup : les mêmes à chaque fois se liraient
		# comme un autocollant.
		_cracks.clear()
		for i in CRACKS:
			var d := Vector2.from_angle(TAU * float(i) / float(CRACKS) + _rng.randf_range(-0.4, 0.4))
			var length := _rng.randf_range(6.0, 11.0)
			var elbow := d * length * 0.5 + d.orthogonal() * _rng.randf_range(-1.8, 1.8)
			_cracks.append(PackedVector2Array([d * 2.5, elbow, d * length]))
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
	match _style:
		Style.STRIKE:
			_draw_strike()
		Style.CROSS:
			_draw_cross()
		_:
			_crescent(_t, outer_radius, thickness, arc_degrees, color, 2.0)


func _draw_strike() -> void:
	var t_arc := _t / STRIKE_CRESCENT_END
	if t_arc < 1.0:
		_crescent(t_arc, STRIKE_RADIUS, STRIKE_THICKNESS, STRIKE_OPENING, STRIKE_COLOR, 3.0)

	var k := (_t - STRIKE_IMPACT_START) / (1.0 - STRIKE_IMPACT_START)
	if k <= 0.0:
		return
	var fade_amount := 1.0 - k
	var wave := 1.0 - pow(1.0 - k, 2.0)
	# Le repère du sol : on défait la rotation du pivot, puis on écrase la hauteur.
	draw_set_transform_matrix(Transform2D(-global_rotation, FLATTENED, 0.0, IMPACT))
	# L'éclat du choc, au tout début : c'est lui qui dit « ça a porté ».
	var flash := 1.0 - k * 4.0
	if flash > 0.0:
		Glow.draw_blob(self, Vector2.ZERO, 3.0 + 7.0 * flash, Color(WAVE, flash))
	Glow.draw_ring(self, Vector2.ZERO, 3.0 + 9.0 * wave, Color(WAVE, 0.85 * fade_amount * fade_amount))
	# Les fissures se tracent en un tiers de l'impact, puis restent le temps qu'il
	# s'efface.
	var trace := minf(k * 3.0, 1.0)
	for f in _cracks:
		draw_polyline(PackedVector2Array([f[0], f[0].lerp(f[1], trace), f[1].lerp(f[2], trace)]), Color(FISSURE, 0.9 * fade_amount), 1.0)
	for i in 6:
		var d := Vector2.from_angle(TAU * float(i) / 6.0 + 0.4)
		draw_circle(d * (6.0 + 9.0 * wave), 2.0, Color(DUST, 0.55 * fade_amount))
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_cross() -> void:
	for i in CROSS.size():
		var u := (_t - CROSS_OFFSET * float(i)) / CROSS_WINDOW
		if u <= 0.0:
			continue
		var a: Vector2 = CROSS[i][0]
		var b: Vector2 = CROSS[i][1]
		var head := minf(u / 0.45, 1.0)
		var tail_u := clampf((u - 0.3) / 0.7, 0.0, 1.0) * head
		var fade_amount := 1.0 - smoothstep(0.55, 1.0, u)
		if head - tail_u < 0.02 or fade_amount <= 0.0:
			continue
		var p0 := a.lerp(b, tail_u)
		var p1 := a.lerp(b, head)
		var across := (b - a).orthogonal().normalized() * 3.0
		var middle := (p0 + p1) * 0.5
		draw_colored_polygon(
			PackedVector2Array([p0, middle + across, p1, middle - across]),
			Color(CROSS_COLOR, CROSS_COLOR.a * fade_amount)
		)
	var flash := 1.0 - absf(_t - CROSS_CROSSING) / CROSS_FLASH
	if flash > 0.0:
		var center := (CROSS[0][0] + CROSS[0][1]) * 0.5
		var c := Color(CROSS_COLOR, flash)
		draw_line(center + Vector2(-5.0, 0.0), center + Vector2(5.0, 0.0), c, 1.0)
		draw_line(center + Vector2(0.0, -5.0), center + Vector2(0.0, 5.0), c, 1.0)
		draw_circle(center, 2.0, c)


## Le croissant du balayage, à ces proportions. `t` va de 0 à 1 sur sa propre durée ;
## `curve` règle l'amorti — plus fort, la lame part plus vite et finit plus lourd.
func _crescent(t: float, radius: float, thickness: float, opening: float, tint: Color, curve: float) -> void:
	var eased := 1.0 - pow(1.0 - t, curve)
	var total := deg_to_rad(opening)
	var head := -total * 0.5 + eased * total
	var tail := maxf(head - total * trail_ratio, -total * 0.5)
	var fade := 1.0 - smoothstep(fade_start, 1.0, t)
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
		var r0 := radius - maxf(thickness * pow(sin(PI * u0), 0.6), 0.4)
		var r1 := radius - maxf(thickness * pow(sin(PI * u1), 0.6), 0.4)

		var c0 := tint
		var c1 := tint
		c0.a = tint.a * fade * (0.2 + 0.8 * u0)
		c1.a = tint.a * fade * (0.2 + 0.8 * u1)

		draw_polygon(
			PackedVector2Array([d0 * radius, d1 * radius, d1 * r1, d0 * r0]),
			PackedColorArray([c0, c1, c1, c0])
		)
