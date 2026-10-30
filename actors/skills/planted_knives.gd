class_name PlantedKnives
extends Node3D

## Les lames plantées dans un ennemi (jalon 50) : combien, et ce qu'il leur reste. Le Coup de
## grâce les arrache (`rip()`), le Hérisson fait subir davantage à leur porteur. Enfant de la
## hurtbox : elles suivent le corps. Chacune se voit fichée dans la cible (`BladeFx.plant`), du
## côté d'où elle est venue ; quand elles la quittent — sa mort, le Coup de grâce, leur durée —,
## elles tombent au sol (`BladeFx.drop`). Le couteau qui tue se plante dans un mort, libéré dans
## la même image : sans cette chute, on ne le voyait jamais.

var count := 0
var _left := 0.0
var _hedgehog := 0.0
var _target: Hurtbox


## En différé : la lame arrive d'un rappel de collision (invariant 4).
static func plant(target: Hurtbox, cast: SkillStats, heading: Vector3) -> void:
	if not is_instance_valid(target):
		return
	var enemy := target.get_parent() as Enemy
	var knives := of(target)
	if knives == null:
		knives = PlantedKnives.new()
		knives._target = target
		target.add_child(knives)
		Settings.veil(knives, Settings.SPELLS)
		if enemy != null:
			enemy.died.connect(knives._fall.unbind(1))
	if knives.count < SkillStats.PLANT_MOST:
		BladeFx.plant(knives, heading, knives.count, enemy.model.height() if enemy != null else 0.0)
	knives.count = mini(knives.count + 1, SkillStats.PLANT_MOST)
	knives._left = SkillStats.PLANT_TIME + cast.anchorage
	knives._hedgehog = cast.hedgehog
	knives._expose()
	if enemy != null and enemy.is_dead:
		knives._fall()


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


## Elles lâchent leur cible et tombent. Le Hérisson s'éteint de lui-même : posé pour le temps qu'il leur restait.
func _fall() -> void:
	if is_queued_for_deletion():
		return
	BladeFx.drop(self)
	queue_free()


func _physics_process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		_fall()

