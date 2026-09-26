class_name Grunt
extends Enemy

## Le fonceur. Il va droit sur toi et frappe au contact. C'est la masse :
## individuellement inoffensif, dangereux en nombre parce qu'il te bloque
## et t'encercle.

const ACCEL := 0.08


func tick(delta: float) -> void:
	if not _should_act():
		return

	var victim := foe()
	var to_target := victim.global_position - global_position
	# La distance reste à vol d'oiseau — c'est elle qui décide s'il est au
	# contact — mais la direction suit le chemin, qui contourne les murs.
	var dist := to_target.length()
	_close_in(victim, ACCEL)

	_cool_down(delta)
	if dist < stats.attack_range and _attack_cd <= 0.0:
		_strike(to_target)
		_hurt(victim.get("hurtbox") as Hurtbox, global_position)
	else:
		_animate()
