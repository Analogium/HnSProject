class_name PutridCurse
extends Node2D

## La Malédiction putride : un sceau posé au curseur qui maudit d'un coup tout ce qu'il
## couvre, puis s'efface. **Elle ne frappe pas** : l'état se pose directement, sans
## passer par `Hurtbox.take_damage()` — un coup de zéro prendrait le plancher d'un point
## et pourrait s'esquiver. La seule exception au point de passage unique des états.
##
## Frappe à sa première image de physique, comme l'explosion : l'espace y est libre.

## Ce que le sceau reste à l'écran : l'état est posé à la première image, le reste
## est pour l'œil du joueur.
const LIFETIME := 0.7
## Les instants de l'œil, en part de la vie : il s'entrouvre, s'ouvre, se referme.
const EYE_TIMES := [0.08, 0.2, 0.7, 0.82]
## De combien l'œil flotte au-dessus du centre, en part du rayon.
const EYE_LIFT := 0.62
## L'opacité de la nappe au sol, **plus dense qu'un halo d'aura** : c'est une marque.
const FILL := 0.5

var _cast: SkillStats
var _author: StatusEffects
var _tint := Color.WHITE
var _age := 0.0
var _has_struck := false


static func fall(
	parent: Node, point: Vector2, cast: SkillStats, author: StatusEffects
) -> PutridCurse:
	var curse := PutridCurse.new()
	curse._cast = cast
	curse._author = author
	curse._tint = StatusEffects.color(cast.inflicted_state)
	parent.add_child(curse)
	curse.global_position = point
	return curse


## Pas de lumière ajoutée : le sceau est **dessiné**.
func _ready() -> void:
	z_index = 3


func _physics_process(delta: float) -> void:
	if not _has_struck:
		_has_struck = true
		for target in Targets.in_circle(get_world_2d(), global_position, _cast.radius):
			if target.states != null:
				target.states.put(_cast.inflicted_state, 0.0, _author, _cast.skill_id)
	_age += delta
	queue_redraw()
	if _age >= LIFETIME:
		queue_free()


## Choisi sur planche contre un sceau runique, une spirale qui se resserre et un crâne
## qui s'abat (jalon 26). La nappe tramée **s'efface en fondu** — un halo au sol est
## fait pour ça —, le cercle se dissout, l'œil se referme.
func _draw() -> void:
	var k := clampf(_age / LIFETIME, 0.0, 1.0)
	var span := int(_cast.radius)
	var fade := 1.0 - clampf((k - 0.55) * 2.2, 0.0, 1.0)
	draw_texture_rect(
		EffectForge.scorch(_tint, span, FILL),
		Rect2(EffectForge.snap(self, -Vector2(span, span)), Vector2.ONE * float(span * 2 + 1)),
		false, Color(1.0, 1.0, 1.0, fade)
	)
	Necrotic.put_band(self, Necrotic.ring(_tint, _cast.radius, 1.0 - fade), Vector2.ZERO)
	var eyes := EffectForge.eyes(_tint)
	var open := 0
	if k >= EYE_TIMES[0] and k < EYE_TIMES[3]:
		open = 2 if k >= EYE_TIMES[1] and k < EYE_TIMES[2] else 1
	Necrotic.centered(self, eyes[open], Vector2(0.0, -_cast.radius * EYE_LIFT))
