class_name PutridCurse
extends Node2D

## La Malédiction putride : un sceau posé au curseur qui maudit d'un coup tout ce qu'il
## couvre, puis s'efface. **Elle ne frappe pas** : l'état se pose directement, sans
## passer par `Hurtbox.take_damage()` — un coup de zéro prendrait le plancher d'un point
## et pourrait s'esquiver. La seule exception au point de passage unique des états.
##
## Frappe à sa première image de physique, comme l'explosion : l'espace y est libre.
##
## **La Marque de mort** (forme `MARK`, jalon 38) : un seul ennemi, le plus proche du
## point visé, à `SkillStats.MARK_FACTOR` fois la force ; quand il perd la malédiction —
## mort, ses états effacés —, elle passe au plus proche, jusqu'au bout de sa durée.

## Ce que le sceau reste à l'écran : l'état est posé à la première image, le reste
## est pour l'œil du joueur.
const LIFETIME := 0.7
## Les instants de l'œil, en part de la vie : il s'entrouvre, s'ouvre, se referme.
const EYE_TIMES := [0.08, 0.2, 0.7, 0.82]
## De combien l'œil flotte au-dessus du centre, en part du rayon.
const EYE_LIFT := 0.62
## L'opacité de la nappe au sol, **plus dense qu'un halo d'aura** : c'est une marque.
const FILL := 0.5
## La Marque : où elle cherche sa cible, autour du point visé puis du marqué tombé.
const MARK_REACH := 80.0
## Au-dessus de la tête du marqué, en pixels.
const MARK_LIFT := 18.0

var _cast: SkillStats
var _author: StatusEffects
var _tint := Color.WHITE
var _age := 0.0
var _has_struck := false
var _caster: Player
var _marking := false
var _marked: Hurtbox


static func fall(
	parent: Node, point: Vector2, cast: SkillStats, author: StatusEffects, caster: Player = null
) -> PutridCurse:
	var curse := PutridCurse.new()
	curse._cast = cast
	curse._author = author
	curse._caster = caster
	curse._marking = cast.shape == Skill.Shape.MARK
	curse._tint = StatusEffects.color(cast.inflicted_state)
	parent.add_child(curse)
	Settings.veil(curse, Settings.SPELLS)
	curse.global_position = point
	return curse


## Pas de lumière ajoutée : le sceau est **dessiné**.
func _ready() -> void:
	z_index = 3


func _physics_process(delta: float) -> void:
	if not _has_struck:
		_has_struck = true
		if _marking:
			_mark(Targets.nearest(get_world_2d(), global_position, MARK_REACH))
		else:
			for target in Targets.in_circle(get_world_2d(), global_position, _cast.radius):
				_curse(target)
	_age += delta
	if _marking and not _holds():
		_mark(Targets.nearest(get_world_2d(), global_position, MARK_REACH, _spent()))
	queue_redraw()
	if _age >= (_cast.duration if _marking else LIFETIME) or (_marking and _marked == null):
		queue_free()


## La durée **qui reste** au lancer — la marque qui passe ne repart pas à zéro —, et le
## Tribut, par maudit.
func _curse(target: Hurtbox) -> void:
	if target.states == null:
		return
	target.states.put(
		_cast.inflicted_state, 0.0, _author, _cast.skill_id,
		_cast.strength_of(_cast.inflicted_state), maxf(_cast.duration - _age, 0.01)
	)
	if is_instance_valid(_caster):
		_caster.gain_mana(_cast.tribute)


func _mark(target: Hurtbox) -> void:
	_marked = target
	if target != null:
		_curse(target)
		global_position = target.global_position


## Le marqué la porte encore : la marque le suit.
func _holds() -> bool:
	if not is_instance_valid(_marked) or _marked.states == null \
			or not _marked.states.active(StatusEffects.Kind.CURSED):
		return false
	global_position = _marked.global_position
	return true


## Celui qui vient de la perdre ne la reprend pas : il est peut-être encore dans l'arbre.
func _spent() -> Dictionary:
	return {_marked.get_instance_id(): true} if is_instance_valid(_marked) else {}


## Choisi sur planche contre un sceau runique, une spirale qui se resserre et un crâne
## qui s'abat (jalon 26). La nappe tramée **s'efface en fondu** — un halo au sol est
## fait pour ça —, le cercle se dissout, l'œil se referme.
func _draw() -> void:
	if _marking:
		# L'œil ouvert au-dessus du marqué, et rien au sol : il n'y a pas de zone.
		Necrotic.centered(self, EffectForge.eyes(_tint)[2], Vector2(0.0, -MARK_LIFT))
		return
	var k := clampf(_age / LIFETIME, 0.0, 1.0)
	var fade := 1.0 - clampf((k - 0.55) * 2.2, 0.0, 1.0)
	EffectForge.put_scorch(self, _tint, int(_cast.radius), fade, FILL)
	Necrotic.put_band(self, Necrotic.ring(_tint, _cast.radius, 1.0 - fade), Vector2.ZERO)
	var eyes := EffectForge.eyes(_tint)
	var open := 0
	if k >= EYE_TIMES[0] and k < EYE_TIMES[3]:
		open = 2 if k >= EYE_TIMES[1] and k < EYE_TIMES[2] else 1
	Necrotic.centered(self, eyes[open], Vector2(0.0, -_cast.radius * EYE_LIFT))
