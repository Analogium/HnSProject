class_name SacredPillar
extends Node2D

## Le pilier de Pilier sacré : une colonne de lumière tombée du ciel sur le point
## visé, qui frappe son cercle à chaque période puis s'éteint. Comme le nuage
## d'orage, il ne fige jamais le jeu — une impulsion qui gèle toutes les demi-secondes
## hacherait l'image tant qu'il brûle.

## La hauteur de la colonne, en pixels. Mesurée à la capture : à 200 elle traversait
## les 360 px du cadrage et se lisait comme un projecteur, à 130 elle tombe du bord.
const HEIGHT := 130.0
## Ce qu'elle met à s'ouvrir et à se refermer, en secondes.
const OPENING := 0.12
const CLOSING := 0.35
## Les grains de lumière qui montent dans la colonne — c'est le seul détail qui la
## sépare d'un rectangle clair.
const MOTES := 9
const RISE := 40.0

var _cast: SkillStats
var _author: StatusEffects
var _tint := Color.WHITE
var _age := 0.0
var _strikes := 0


static func fall(
	parent: Node, point: Vector2, cast: SkillStats, author: StatusEffects
) -> SacredPillar:
	var pillar := SacredPillar.new()
	pillar._cast = cast
	pillar._author = author
	pillar._tint = DamageType.COLORS[cast.dominant_nature()]
	parent.add_child(pillar)
	pillar.global_position = point
	return pillar


func _ready() -> void:
	z_index = 4
	material = ArtPalette.ADDITIVE


## Les impulsions se comptent par `strikes_over_duration()`, la fonction même de
## l'estimation : la fiche et le pilier ne peuvent pas annoncer deux nombres.
func _physics_process(delta: float) -> void:
	_age += delta
	var total := _cast.strikes_over_duration()
	while _strikes < total and _age >= float(_strikes) * _cast.period:
		_strike()
		_strikes += 1
	queue_redraw()
	if _age >= _cast.duration and _strikes >= total:
		queue_free()


## Un tirage par impulsion, qu'elle touche ou non : c'est un geste du pilier.
func _strike() -> void:
	var parts := _cast.roll(Game.rng)
	for target in Targets.in_circle(get_world_2d(), global_position, _cast.radius):
		Targets.strike(target, parts, global_position, _author, _cast)


## La colonne s'élargit vers le bas : un rectangle droit se lit comme un mur, un
## évasement comme quelque chose qui tombe. Le disque au sol dit **où elle mord** — la
## colonne est plus étroite que le cercle, et lui seul donne la portée.
func _draw() -> void:
	var width := _cast.radius * 0.55 * clampf(_age / OPENING, 0.0, 1.0)
	var fade := clampf((_cast.duration - _age) / CLOSING, 0.0, 1.0)
	var light_color := _tint.lerp(Color.WHITE, 0.6)

	draw_circle(Vector2.ZERO, _cast.radius, Color(_tint, 0.10 * fade))
	Glow.draw_ring(self, Vector2.ZERO, _cast.radius, Color(_tint, 0.42 * fade))

	draw_colored_polygon(PackedVector2Array([
		Vector2(-width * 0.45, -HEIGHT), Vector2(width * 0.45, -HEIGHT),
		Vector2(width, 0.0), Vector2(-width, 0.0),
	]), Color(_tint, 0.22 * fade))
	draw_line(Vector2(0.0, -HEIGHT), Vector2.ZERO, Color(light_color, 0.85 * fade), width * 0.3)

	for i in MOTES:
		# Elles montent : la colonne verse au sol, ce qui en remonte dit qu'elle brûle.
		var rise := fmod(_age * 0.9 + float(i) * 0.113, 1.0)
		var across := sin(float(i) * 2.4) * width
		draw_rect(
			Rect2(Vector2(across * (1.0 - rise), -rise * RISE), Vector2.ONE),
			Color(light_color, 0.8 * (1.0 - rise) * fade)
		)
