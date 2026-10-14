class_name ThrowingKnife
extends Projectile

## Un couteau des Lames de jet (jalon 50) : le trajet et la touche de `Projectile`, et **un
## couteau qui critique traverse** sa cible au lieu de s'y arrêter. Son arbre : il frappe
## plus fort de loin (Tir lointain) et de corps en corps (Enfilade), revient vers son lanceur
## (Retour de lame) ou se plante (Lame plantée).

## Sur le chemin du retour : il ne s'arrête plus, et chaque corps peut être refrappé une fois.
var _returning := false


## Dessiné : le couteau droit choisi sur planche, fabriqué à son cap (`Slash.knife()`).
func _drawn() -> bool:
	return true


func _draw() -> void:
	Slash.knife(Slash.turn_of(_dir.angle())).put(self, Vector2.ZERO)


func _keeps_flying(info: DamageInfo) -> bool:
	return info.is_crit or _returning


func _hit_factor() -> float:
	if _cast == null:
		return 1.0
	var travelled := speed * _life
	var far := 1.0 + _cast.long_shot * 0.01 * floorf(travelled / SkillStats.LONG_SHOT_STEP)
	return far * (1.0 + _cast.enfilade * 0.01 * float(_struck.size() - 1))


func _lodge(target: Hurtbox) -> bool:
	if _cast == null or _cast.planted <= 0.0 or _returning:
		return false
	PlantedKnives.plant.call_deferred(target, _cast)
	queue_free()
	return true


func _physics_process(delta: float) -> void:
	if _returning:
		if not is_instance_valid(_source):
			super._finish()
			return
		_dir = global_position.direction_to(_source.global_position)
		if global_position.distance_to(_source.global_position) <= SkillStats.CATCH_REACH:
			_caught()
			return
	super(delta)


## La fin de course : sous le Retour de lame, il repart vers son lanceur — sa course
## recommence, ce qu'il a frappé à l'aller peut l'être au retour.
func _finish() -> void:
	if _cast == null or _cast.return_blade <= 0.0 or _returning or is_queued_for_deletion():
		super()
		return
	_returning = true
	_struck.clear()
	_life = 0.0


## Rattrapé : la Récupération rend du mana.
func _caught() -> void:
	var player := _source as Player
	if player != null and _cast.recovery > 0.0:
		player.gain_mana(_cast.recovery)
	queue_free()
