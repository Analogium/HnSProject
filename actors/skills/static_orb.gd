class_name StaticOrb
extends Node3D

## L'Orbe statique (jalon 35, transformation d'Éclair vif) : un orbe lent qui file droit
## et foudroie à chaque période ce qui passe dans son rayon. Il ne frappe pas à l'impact
## et traverse les ennemis ; un mur l'éteint.


## Tous ceux qui volent : `simultaneous` par lanceur au plus (jalon 43), le Familier compté
## à part. Au-delà, les plus anciens se dissolvent.
static var _live: Array[StaticOrb] = []

var _cast: SkillStats
var _author: StatusEffects
var _dir := Vector3.RIGHT
var _age := 0.0
var _strikes := 0
## Son lanceur, pour la limite ; le Satellite (jalon 43) tourne autour, et dit où il en est.
var _around: Node3D
var _orbits := false
var _angle := 0.0
## L'Orbe chargé : les ennemis qu'il a déjà frappés, qui l'ont grossi.
var _met := {}


static func send(
	parent: Node, from: Vector3, direction: Vector3, cast: SkillStats, author: StatusEffects,
	around: Node3D = null
) -> StaticOrb:
	_live.assign(_live.filter(func(o) -> bool: return is_instance_valid(o) and not o.is_queued_for_deletion()))
	for old in cast.crowded(_live.filter(func(o: StaticOrb) -> bool: return o._around == around)):
		old.queue_free()
	var orb := StaticOrb.new()
	orb._around = around
	_live.append(orb)
	orb._cast = cast
	orb._author = author
	orb._dir = direction.normalized()
	parent.add_child(orb)
	Settings.veil(orb, Settings.SPELLS)
	orb.global_position = from + orb._dir * Projectile.MUZZLE
	if cast.satellite > 0.0 and around != null:
		orb._orbits = true
		orb._angle = Flat.angle(orb._dir)
		orb.global_position = from + orb._dir * SkillStats.SATELLITE_RADIUS
	return orb


## Les frappes se comptent par `strikes_due()`, comme le nuage : la fiche et l'orbe ne
## peuvent pas annoncer deux nombres.
func _physics_process(delta: float) -> void:
	_age += delta
	if _orbits:
		# Sur son orbite, il passe les murs : c'est son lanceur qui les longe.
		if not is_instance_valid(_around):
			queue_free()
			return
		_angle += _cast.projectile_speed / SkillStats.SATELLITE_RADIUS * delta
		global_position = _around.global_position + Flat.from_angle(_angle) * SkillStats.SATELLITE_RADIUS
	else:
		var step := _dir * _cast.projectile_speed * delta
		if not Targets.in_sight(get_world_3d(), global_position, global_position + step):
			queue_free()
			return
		global_position += step
	var due := _cast.strikes_due(_age)
	while _strikes < due:
		_strike()
		_strikes += 1
	if _age >= _cast.duration:
		_disperse()
		queue_free()


## La Dispersion de la Nuée (jalon 45) : au bout de sa course, des petits essaims en étoile,
## sans lanceur à suivre — la limite des orbes ne les compte pas.
func _disperse() -> void:
	var count := int(_cast.dispersal)
	if count <= 0:
		return
	var small := _cast.dispersed()
	for i in count:
		StaticOrb.send(get_parent(), global_position, Flat.rotated(_dir, TAU * float(i) / float(count)), small, _author)


func _strike() -> void:
	var targets := Targets.strike_circle(get_world_3d(), global_position, reach(), _cast, _author)
	for target in targets:
		_met[target.get_instance_id()] = true


## Son rayon de frappe, grossi par l'Orbe chargé à chaque ennemi rencontré.
func reach() -> float:
	var met := mini(_met.size(), SkillStats.CHARGED_ORB_MOST)
	return _cast.radius * (1.0 + _cast.charged_orb * 0.01 * float(met))

