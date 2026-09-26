class_name Brute
extends Enemy

## Le colosse en armure (jalon 27). Lent et épais ; au contact il se plante, montre un
## cône devant lui et abat ses poings quand le plein atteint le bord. Rester collé à
## lui se paie : on frappe, puis on sort du cône.

const ACCEL := 0.06
const WINDUP := 0.8
const REACH := 54.0
## Le demi-angle du cône, en radians.
const SPREAD := 0.6
const SHAKE := 4.0

## Tant qu'elle court, il est planté : la zone frappe à la fin, et tombe avec lui.
var _zone: DangerZone
var _timer := 0.0
var _dir := Vector2.DOWN


func tick(delta: float) -> void:
	if not _should_act():
		return
	_cool_down(delta)
	if _zone != null:
		# L'horloge de la zone, pas ralentie par le gel : le geste suit la frappe.
		_timer -= delta
		if _timer <= 0.0:
			_zone = null
			_strike(_dir)
			if target is Player:
				Game.shake_camera((target as Player).camera, SHAKE)
		return
	var victim := foe()
	var to_victim := victim.global_position - global_position
	if to_victim.length() < stats.attack_range and _attack_cd <= 0.0:
		_dir = to_victim.normalized()
		velocity = Vector2.ZERO
		sprite.set_state(false, _dir)
		_zone = _danger(
			global_position, DangerZone.Shape.CONE, REACH, WINDUP, DamageType.Kind.PHYSICAL,
			_dir, SPREAD
		)
		_zone.knockback = stats.knockback_force
		_zone.bound = self
		_timer = WINDUP
		return
	_close_in(victim, ACCEL)
	_animate()
