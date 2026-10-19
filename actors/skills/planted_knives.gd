class_name PlantedKnives
extends Node3D

## Les lames plantées dans un ennemi (jalon 50) : combien, et ce qu'il leur reste. Le Coup de
## grâce les arrache (`rip()`), le Hérisson fait subir davantage à leur porteur. Enfant de la
## hurtbox : elles suivent le corps et tombent avec lui.

## Les couteaux plantés se voient en étincelles sur la cible, à ce rayon.
const SPARKS := 6.0

var count := 0
var _left := 0.0
var _hedgehog := 0.0
var _target: Hurtbox


## En différé : la lame arrive d'un rappel de collision (invariant 4).
static func plant(target: Hurtbox, cast: SkillStats) -> void:
	if not is_instance_valid(target):
		return
	var knives := of(target)
	if knives == null:
		knives = PlantedKnives.new()
		knives._target = target
		target.add_child(knives)
		ElementFx.area(knives, DamageType.COLORS[cast.nature], SPARKS)
	knives.count = mini(knives.count + 1, SkillStats.PLANT_MOST)
	knives._left = SkillStats.PLANT_TIME + cast.anchorage
	knives._hedgehog = cast.hedgehog
	knives._expose()


static func of(target: Hurtbox) -> PlantedKnives:
	for child in target.get_children():
		if child is PlantedKnives and not child.is_queued_for_deletion():
			return child
	return null


## Les retire toutes, et rend combien il y en avait.
static func rip(target: Hurtbox) -> int:
	var knives := of(target) if is_instance_valid(target) else null
	if knives == null:
		return 0
	var ripped := knives.count
	knives._fall()
	return ripped


func _expose() -> void:
	if _hedgehog > 0.0 and _target.states != null:
		_target.states.open_up(_hedgehog * float(count), _left)


## Le Hérisson s'éteint de lui-même : posé pour le temps qu'il leur restait.
func _fall() -> void:
	queue_free()


func _physics_process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		_fall()

