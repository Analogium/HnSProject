class_name Caster
extends Enemy

## Le tireur à distance. Il se rapproche s'il est trop loin, tourne autour
## sinon, et tire. Il change la façon de jouer : on ne peut plus rester au
## milieu de la mêlée, il faut choisir des cibles prioritaires.
##
## C'est ça, avoir deux types d'ennemis différents : la différence est
## comportementale, et elle pose au joueur une question différente.
##
## Écart avec le document : il ne fuit pas quand le joueur le rejoint. Le doc
## prévoit un recul sous flee_distance, mais un tireur qui décroche transforme
## chaque engagement en course-poursuite. Ici, percer jusqu'à lui est
## récompensé — il reste mobile en tournant, pas en s'échappant.

const ACCEL := 0.06

@export var projectile_scene: PackedScene
@export var preferred_distance: float = 150.0
@export var strafe_bias: float = 0.7
## Avance angulaire du point visé sur l'orbite, en radians. C'est ce qui règle
## la dérive : trop petit, le retard du lerp fait spiraler vers l'extérieur ;
## trop grand, le caster coupe la corde et se resserre sur le joueur.
@export var orbit_step: float = 0.15

var _cast_cd := 0.0
var _strafe_dir := 1.0


func setup(p_target: Node2D) -> void:
	super(p_target)
	_strafe_dir = 1.0 if Game.rng.randf() < 0.5 else -1.0


func tick(delta: float) -> void:
	if not _should_act():
		return

	var to_target := target.global_position - global_position
	var dist := to_target.length()
	var dir := to_target.normalized()

	var move := Vector2.ZERO
	var strafing := false
	if dist > preferred_distance:
		move = dir                                            # se rapproche
	else:
		# On vise un point plus loin sur le cercle de rayon actuel, plutôt que
		# de suivre la tangente. Avec la tangente, le retard du lerp (ACCEL est
		# volontairement très bas) laisse la vitesse pointer le long de l'ancienne
		# tangente, et le caster spirale vers l'extérieur — ce qui se lit comme
		# une fuite lente. En visant sur le cercle, il tourne sans s'éloigner.
		var offset := global_position - target.global_position
		var goal := target.global_position + offset.rotated(_strafe_dir * orbit_step)
		move = (goal - global_position).normalized() * strafe_bias
		strafing = true

	velocity = velocity.lerp(move * stats.move_speed, ACCEL)
	move_and_slide()

	# Sans ça il s'use contre les murs en tournant toujours du même côté.
	if strafing and get_slide_collision_count() > 0:
		_strafe_dir = -_strafe_dir

	_cast_cd = maxf(_cast_cd - delta, 0.0)
	if dist < preferred_distance * 1.4 and _cast_cd <= 0.0 and _has_line_of_sight():
		_cast_cd = stats.attack_cooldown
		_fire(dir)
		sprite.set_state(false, dir)
		sprite.attack()
	else:
		_animate()


## Pas dans le document, mais une arène à piliers rend l'absence de test
## immédiatement visible : sans lui le caster tire à travers les murs.
func _has_line_of_sight() -> bool:
	var params := PhysicsRayQueryParameters2D.create(
		global_position, target.global_position, 1   # layer 1 = décor
	)
	params.collide_with_areas = false
	return get_world_2d().direct_space_state.intersect_ray(params).is_empty()


func _fire(dir: Vector2) -> void:
	if projectile_scene == null:
		return
	var p: Projectile = projectile_scene.instantiate()
	# add_child d'abord : global_position n'a de sens qu'une fois dans l'arbre.
	manager.projectile_parent.add_child(p)
	p.global_position = global_position + dir * 12.0
	p.setup(dir, stats.attack_damage, self)
