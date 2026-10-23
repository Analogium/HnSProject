class_name StaticOrb
extends Node3D

## L'Orbe statique (jalon 35, transformation d'Éclair vif) : un orbe lent qui file droit
## et foudroie à chaque période ce qui passe dans son rayon. Il ne frappe pas à l'impact
## et traverse les ennemis ; un mur l'éteint. Dessiné par `BoltFx` : la boule de plasma, ses
## décharges en arcs, et la traînée du Satellite.


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
var _fx: BoltFx


static func send(
	parent: Node, from: Vector3, direction: Vector3, cast: SkillStats, author: StatusEffects,
	around: Node3D = null, fill := false
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
		orb._angle = _widest_gap(around) if fill else Flat.angle(orb._dir)
		orb._orbits = true
		orb.global_position = around.global_position + Flat.from_angle(orb._angle) * SkillStats.SATELLITE_RADIUS
	orb._fx = BoltFx.show_on(orb, cast.nature, true, orb._orbits)
	return orb


## Des orbes tournent-ils déjà autour de `around` ? Sinon, le lancer part vers la visée.
static func circling(around: Node3D) -> bool:
	return not _orbiting(around).is_empty()


## Le milieu du plus grand vide de l'orbite : nés devant le lanceur, les orbes d'un tir rapide ou
## multiple se tassaient en paquets superposés, et laissaient le reste du cercle vide.
static func _widest_gap(around: Node3D) -> float:
	var angles: Array[float] = []
	for o in _orbiting(around):
		angles.append(fposmod(o._angle, TAU))
	angles.sort()
	var widest: float = TAU - angles.back() + angles[0]
	var at: float = angles.back() + widest * 0.5
	for i in range(1, angles.size()):
		if angles[i] - angles[i - 1] > widest:
			widest = angles[i] - angles[i - 1]
			at = angles[i - 1] + widest * 0.5
	return at


static func _orbiting(around: Node3D) -> Array:
	return _live.filter(func(o) -> bool:
		return is_instance_valid(o) and not o.is_queued_for_deletion() and o._orbits and o._around == around)


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
	_fx.zap(targets)


## Son rayon de frappe, grossi par l'Orbe chargé à chaque ennemi rencontré.
func reach() -> float:
	var met := mini(_met.size(), SkillStats.CHARGED_ORB_MOST)
	return _cast.radius * (1.0 + _cast.charged_orb * 0.01 * float(met))

