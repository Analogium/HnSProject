class_name HolyBeam
extends Node2D

## Le trait de Frappe sacrée : il jaillit du lanceur, frappe **une fois** tout ce qui
## est sur sa ligne, puis s'efface. Rien ne reste — le geste entier tient dans son
## premier instant, et ce qu'on voit n'est que la rémanence.
##
## Il frappe à sa première image de physique et non à la pose : le lancer peut venir
## d'un rappel de collision, où l'espace physique refuse les requêtes (invariant 4).

## La rémanence, en secondes : assez pour qu'un trait parti toutes les demi-secondes se
## voie, trop court pour qu'on le prenne pour une présence.
const LIFETIME := 0.16
## Sa largeur en pixels, celle du coup comme celle du dessin : `radius` porte sa
## longueur, et aucun nœud ne vise l'épaisseur.
const WIDTH := 6.0

var _cast: SkillStats
var _author: StatusEffects
var _tint := Color.WHITE
## Dans le repère du trait, qui ne tourne pas : l'extrémité, en local.
var _tip := Vector2.ZERO
var _age := 0.0
var _has_struck := false


static func fire(
	parent: Node, of: Vector2, direction: Vector2, cast: SkillStats, author: StatusEffects
) -> HolyBeam:
	var beam := HolyBeam.new()
	beam._cast = cast
	beam._author = author
	beam._tint = DamageType.COLORS[cast.dominant_nature()]
	beam._tip = direction.normalized() * cast.radius
	parent.add_child(beam)
	beam.global_position = of
	return beam


func _ready() -> void:
	z_index = 5
	material = ArtPalette.ADDITIVE


func _physics_process(delta: float) -> void:
	if not _has_struck:
		_has_struck = true
		var parts := _cast.roll(Game.rng)
		for target in Targets.in_capsule(get_world_2d(), global_position, to_global(_tip), WIDTH):
			Targets.strike(target, parts, global_position, _author, _cast)
	_age += delta
	queue_redraw()
	if _age >= LIFETIME:
		queue_free()


## Trois épaisseurs et **un éclat au départ**. Mesuré à la capture : les deux
## épaisseurs de la chaîne suffisent à un trait brisé, mais donnent à un trait droit un
## bâton gris uniforme. C'est l'éclat qui dit d'où il part, et le halo large qui lui
## rend une gradation.
func _draw() -> void:
	var fade := clampf(1.0 - _age / LIFETIME, 0.0, 1.0)
	var light_color := _tint.lerp(Color.WHITE, 0.8)
	draw_line(Vector2.ZERO, _tip, Color(_tint, 0.18 * fade), WIDTH * 1.8)
	# Le halo garde la moitié de son épaisseur jusqu'au bout : à s'amincir jusqu'à
	# rien, le trait disparaissait avant d'avoir été vu.
	draw_line(Vector2.ZERO, _tip, Color(_tint, 0.50 * fade), WIDTH * (0.5 + 0.5 * fade))
	draw_line(Vector2.ZERO, _tip, Color(light_color, fade), 2.0)
	draw_circle(Vector2.ZERO, WIDTH * (0.6 + 0.9 * fade), Color(light_color, 0.8 * fade))
	draw_circle(_tip, WIDTH * 0.6 * fade, Color(light_color, 0.7 * fade))
