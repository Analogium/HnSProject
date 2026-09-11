class_name Caster
extends Enemy

## Le tireur à distance. Il se rapproche s'il est trop loin, tourne autour sinon,
## et tire. On ne peut plus rester au milieu de la mêlée : il faut choisir des
## cibles prioritaires.
##
## **Il ne fuit pas quand le joueur le rejoint**, contrairement au document : un
## tireur qui décroche transforme chaque engagement en course-poursuite. Ici,
## percer jusqu'à lui est récompensé — il reste mobile en tournant.

const ACCEL := 0.06

@export var projectile_scene: PackedScene
@export var preferred_distance: float = 150.0
@export var strafe_bias: float = 0.7
## Avance angulaire du point visé sur l'orbite, en radians. C'est ce qui règle
## la dérive : trop petit, le retard du lerp fait spiraler vers l'extérieur ;
## trop grand, le caster coupe la corde et se resserre sur le joueur.
@export var orbit_step: float = 0.15

var _strafe_dir := 1.0


## Le sens de rotation se déduit de la case d'apparition, comme la silhouette
## (voir ActorSprite._pick). Surtout pas Game.rng : un caster qui tourne dans
## l'autre sens change tout l'engagement, et une graine doit redonner le même.
func setup(p_target: Node2D) -> void:
	super(p_target)
	_strafe_dir = 1.0 if absi(hash(Vector2i(position.round()))) % 2 == 0 else -1.0


func tick(delta: float) -> void:
	if not _should_act():
		return

	var to_target := target.global_position - global_position
	var dist := to_target.length()
	var dir := to_target.normalized()

	var move := Vector2.ZERO
	var strafing := false
	if dist > preferred_distance:
		# Le chemin, pas la ligne droite : c'est en se rapprochant qu'il a des
		# murs à contourner. Une fois à distance, il tourne, et l'orbite est un
		# mouvement local dont le champ n'a rien à dire.
		move = heading()
	else:
		# On vise un point plus loin sur le cercle de rayon actuel, plutôt que la
		# tangente : avec elle, le retard du lerp (ACCEL est volontairement très
		# bas) fait spiraler le caster vers l'extérieur, ce qui se lit comme une
		# fuite lente.
		var offset := global_position - target.global_position
		var goal := target.global_position + offset.rotated(_strafe_dir * orbit_step)
		move = (goal - global_position).normalized() * strafe_bias
		strafing = true

	velocity = velocity.lerp(move * stats.move_speed, ACCEL)
	move_and_slide()

	# Sans ça il s'use contre les murs en tournant toujours du même côté.
	if strafing and get_slide_collision_count() > 0:
		_strafe_dir = -_strafe_dir

	_cool_down(delta)
	if dist < preferred_distance * 1.4 and _attack_cd <= 0.0 and _has_line_of_sight():
		_strike(dir)
		_fire(dir)
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
	Projectile.spawn_d_une_nature(
		manager.projectile_parent, projectile_scene,
		global_position, dir, stats.attack_damage, self
	)
