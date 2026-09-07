class_name Grunt
extends Enemy

## Le fonceur. Il va droit sur toi et frappe au contact. C'est la masse :
## individuellement inoffensif, dangereux en nombre parce qu'il te bloque
## et t'encercle.

const ACCEL := 0.08
const SEPARATION_RADIUS := 18.0
const SEPARATION_FORCE := 0.35


func tick(delta: float) -> void:
	if not _should_act():
		return

	var to_target := target.global_position - global_position
	var dist := to_target.length()
	# La distance reste à vol d'oiseau — c'est elle qui décide s'il est au
	# contact — mais la direction suit le chemin, qui contourne les murs.
	var desired := heading()

	# Séparation : sans ça les grunts se superposent en une bouillie illisible.
	desired += _separation() * SEPARATION_FORCE

	velocity = velocity.lerp(desired.normalized() * stats.move_speed, ACCEL)
	move_and_slide()

	_cool_down(delta)
	if dist < stats.attack_range and _attack_cd <= 0.0:
		_strike(to_target)
		var info := DamageInfo.new(
			stats.attack_damage, global_position, stats.knockback_force
		)
		(target as Player).hurtbox.take_damage(info)
		# Après take_damage : info.amount a pu être réduit par une armure, et on
		# ne vole que ce qu'on a réellement infligé.
		on_damage_dealt(info.amount)
	else:
		_animate()


## Repousse les voisins proches. Approximation grossière mais suffisante :
## on interroge les corps déjà en contact plutôt que de faire une requête spatiale.
##
## Ne renvoie quelque chose que si les grunts se percutent réellement, donc leur
## masque de collision doit inclure leur propre layer (voir grunt.tscn) — sinon
## get_slide_collision ne voit rien et la séparation est silencieusement morte.
func _separation() -> Vector2:
	var push := Vector2.ZERO
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var other := col.get_collider()
		if other is Enemy:
			var away: Vector2 = global_position - (other as Node2D).global_position
			if away.length() < SEPARATION_RADIUS:
				push += away.normalized()
	return push
