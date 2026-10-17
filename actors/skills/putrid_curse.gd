class_name PutridCurse
extends Node3D

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
## La Marque : où elle cherche sa cible, autour du point visé puis du marqué tombé.
const MARK_REACH := 80.0

var _cast: SkillStats
var _author: StatusEffects
var _age := 0.0
var _has_struck := false
var _caster: Player
var _marking := false
var _marked: Hurtbox
## Le Présage (jalon 45) : ce qu'il reste avant que le sceau tombe. L'Héritage : les
## passages de la marque.
var _wait := 0.0
var _passes := 0


static func fall(
	parent: Node, point: Vector3, cast: SkillStats, author: StatusEffects, caster: Player = null
) -> PutridCurse:
	var curse := PutridCurse.new()
	curse._cast = cast
	curse._author = author
	curse._caster = caster
	curse._marking = cast.shape == Skill.Shape.MARK
	curse._wait = cast.omen
	parent.add_child(curse)
	Settings.veil(curse, Settings.SPELLS)
	curse.global_position = point
	return curse


func _physics_process(delta: float) -> void:
	if _wait > 0.0:
		_wait -= delta
		return
	if not _has_struck:
		_has_struck = true
		if _marking:
			_mark(Targets.nearest(get_world_3d(), global_position, MARK_REACH))
		else:
			for target in _covered():
				_curse(target)
	_age += delta
	if _marking and not _holds():
		_passes += 1
		_mark(Targets.nearest(get_world_3d(), global_position, MARK_REACH, _spent()))
	if _age >= (_cast.duration if _marking else LIFETIME) or (_marking and _marked == null):
		queue_free()


## Son cercle, ou sous la Peste noire (jalon 53) tous les porteurs de rats autour du lanceur.
func _covered() -> Array[Hurtbox]:
	if _cast.black_death <= 0.0 or not is_instance_valid(_caster):
		return Targets.in_circle(get_world_3d(), global_position, _cast.radius)
	return Targets.in_circle(get_world_3d(), _caster.global_position, SkillStats.SCREEN_REACH).filter(
		func(t: Hurtbox) -> bool: return t.states != null and t.states.rats() > 0
	)


## La durée **qui reste** au lancer — la marque qui passe ne repart pas à zéro —, et le
## Tribut, par maudit.
func _curse(target: Hurtbox) -> void:
	if target.states == null:
		return
	var gained := 1.0 + _cast.legacy * 0.01 * float(mini(_passes, SkillStats.LEGACY_MOST))
	target.states.put(
		_cast.inflicted_state, 0.0, _author, _cast.skill_id,
		_cast.strength_of(_cast.inflicted_state) * gained, maxf(_cast.duration - _age, 0.01)
	)
	target.states.attach(_cast.inflicted_state, _cast)
	# Le Porteur sain (jalon 53) : un maudit sans rat en reçoit, au rongement de l'éclat.
	if _cast.carrier > 0.0 and target.states.rats() == 0:
		target.states.add_rats(
			int(_cast.carrier), _cast.average_per_hit() * StatusEffects.GNAW_PART, _author,
			_cast.skill_id, _cast
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

