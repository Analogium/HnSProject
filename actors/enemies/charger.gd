class_name Charger
extends Enemy

## Le chevalier bélier (jalon 27). À portée, il se plante, montre son couloir au sol,
## puis charge en ligne droite : on l'évite **de côté**, pas en reculant. Un mur
## l'arrête net et l'étourdit — c'est la fenêtre pour le frapper.

enum Phase { APPROACH, WINDUP, CHARGE, STUNNED }

const ACCEL := 0.08
const WINDUP := 0.6
const CHARGE_SPEED := 280.0
## La longueur du couloir, et de la charge.
const REACH := 170.0
const LANE_HALF := 7.0
## Plus près, il frappe dans le vide avant d'avoir pris son élan : il marche.
const MIN_RANGE := 40.0
const HIT_RADIUS := 12.0
const STUN := 0.9

var _phase := Phase.APPROACH
var _timer := 0.0
var _dir := Vector2.RIGHT
## Ce que cette charge a déjà touché : une charge frappe chacun une fois.
var _hit: Array[Hurtbox] = []


func tick(delta: float) -> void:
	if not _should_act():
		return
	_cool_down(delta)
	# Le gel ralentit l'élan et l'étourdissement comme il ralentit la marche.
	var slowed := delta * states.speed_factor
	match _phase:
		Phase.APPROACH:
			_approach()
		Phase.WINDUP:
			_timer -= slowed
			if _timer <= 0.0:
				_phase = Phase.CHARGE
				_timer = REACH / CHARGE_SPEED
				_hit.clear()
				_strike(_dir)
		Phase.CHARGE:
			_timer -= slowed
			_charge()
			if _timer <= 0.0:
				_phase = Phase.APPROACH
		Phase.STUNNED:
			_timer -= slowed
			if _timer <= 0.0:
				_phase = Phase.APPROACH


func _approach() -> void:
	var victim := foe()
	var to_victim := victim.global_position - global_position
	var dist := to_victim.length()
	if (
		_attack_cd <= 0.0 and dist <= stats.attack_range and dist >= MIN_RANGE
		and Targets.in_sight(get_world_2d(), global_position, victim.global_position)
	):
		_phase = Phase.WINDUP
		_timer = WINDUP
		_dir = to_victim / dist
		velocity = Vector2.ZERO
		sprite.set_state(false, _dir)
		var lane := DangerZone.put(
			manager.ground(), global_position, DangerZone.Shape.LANE, REACH, WINDUP, _dir, LANE_HALF
		)
		lane.bound = self
		return
	_close_in(victim, ACCEL)
	_animate()


func _charge() -> void:
	velocity = _dir * CHARGE_SPEED * states.speed_factor
	move_and_slide()
	sprite.set_state(true, _dir)
	for hurtbox in Targets.in_circle(get_world_2d(), global_position, HIT_RADIUS, Targets.PLAYER_SIDE):
		if hurtbox in _hit:
			continue
		_hit.append(hurtbox)
		# La source derrière lui : le recul part dans le sens de la charge.
		var info := DamageInfo.new(stats.attack_damage, global_position - _dir, stats.knockback_force)
		info.author = states
		hurtbox.take_damage(info)
		on_damage_dealt(info.amount)
	for i in get_slide_collision_count():
		# Un corps l'arrête sans l'étourdir ; le décor, si.
		if not get_slide_collision(i).get_collider() is CharacterBody2D:
			_phase = Phase.STUNNED
			_timer = STUN
			velocity = Vector2.ZERO
			sprite.set_state(false, _dir)
			return
