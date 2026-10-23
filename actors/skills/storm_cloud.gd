class_name StormCloud
extends Node3D

## Le nuage de Nuage d'orage : posé, il frappe tout ce qui est dessous à chaque
## période, puis se dissipe. Il ne fige jamais le jeu — une impulsion qui gèle
## toutes les demi-secondes hacherait l'image tant qu'il est posé.

## Orage errant (`seek_radius`, jalon 35), en px/s : assez lent pour qu'un nuage posé
## reste un nuage posé, assez vif pour rattraper un ennemi qui marche.
const DRIFT_SPEED := 40.0


## Tous ceux qui sont posés : `simultaneous` par lanceur au plus (jalon 43), le Familier
## compté à part, comme pour les serpents.
static var _live: Array[StormCloud] = []


var _cast: SkillStats
var _author: StatusEffects
var _age := 0.0
var _strikes := 0
## Orage portatif (`TEMPEST`) : celui qu'il suit. Sinon, l'ennemi vers lequel il dérive,
## choisi à chaque frappe.
var _follow: Node3D
var _prey := Vector3.INF
var _caster: Object
## La Traque (jalon 43) : la proie qu'il ne lâche plus.
var _quarry: Hurtbox
## L'Accumulation : les frappes tombées à vide, que la suivante qui touche paie.
var _charges := 0
## La Foudre jumelle : les secondes avant la seconde frappe, négatives sans elle.
var _twin := -1.0
## Le Front mobile : l'horloge des frappes, plus vive tant que son porteur marche.
var _clock := 0.0
var _fx: StormCloudFx


static func put(
	parent: Node, point: Vector3, cast: SkillStats, author: StatusEffects, follow: Node3D = null,
	caster: Object = null
) -> StormCloud:
	# Au-delà, les plus anciens se dissipent sans coup final.
	_live.assign(_live.filter(func(c) -> bool: return is_instance_valid(c) and not c.is_queued_for_deletion()))
	for old in cast.crowded(_live.filter(func(c: StormCloud) -> bool: return c._caster == caster)):
		old.queue_free()
	var cloud := StormCloud.new()
	cloud._caster = caster
	_live.append(cloud)
	cloud._cast = cast
	cloud._author = author
	cloud._follow = follow
	parent.add_child(cloud)
	Settings.veil(cloud, Settings.SPELLS)
	cloud.global_position = point
	cloud._fx = StormCloudFx.gather(cloud, cast.nature, cast.radius)
	return cloud


## Les frappes se comptent par `strikes_over_duration()`, la fonction même de
## l'estimation : la fiche et le nuage ne peuvent pas annoncer deux nombres.
func _physics_process(delta: float) -> void:
	_age += delta
	var moving := false
	if is_instance_valid(_follow):
		moving = not _follow.global_position.is_equal_approx(global_position)
		global_position = _follow.global_position
	elif is_instance_valid(_quarry):
		global_position = global_position.move_toward(
			_quarry.global_position, DRIFT_SPEED * SkillStats.HUNT_SPEED * delta
		)
	elif _prey != Vector3.INF:
		global_position = global_position.move_toward(_prey, DRIFT_SPEED * delta)
	_clock += delta * (1.0 + _cast.moving_front * 0.01 if moving else 1.0)
	# Sous le Front mobile, l'horloge n'est pas plafonnée : c'est l'âge qui le dissipe.
	var due := _cast.strikes_due(_clock) if _cast.moving_front <= 0.0 \
			else floori(_clock / _cast.period) + 1
	while _strikes < due:
		_strike()
		_strikes += 1
	if _twin >= 0.0:
		_twin -= delta
		if _twin < 0.0:
			_hit(_cast.radius, 1.0)
	if _age >= _cast.duration and (_strikes >= _cast.strikes_over_duration() or _cast.moving_front > 0.0):
		queue_free()


## Une frappe de la période : où errer, puis l'impulsion, chargée par l'Accumulation (jalon 43)
## — à pleines charges, le Point de rupture l'élargit —, et la Foudre jumelle à tirer.
func _strike() -> void:
	if _cast.seek_radius > 0.0 and not is_instance_valid(_follow):
		if _cast.hunt > 0.0:
			if not is_instance_valid(_quarry) or _quarry.is_queued_for_deletion():
				_quarry = Targets.nearest(get_world_3d(), global_position, _cast.seek_radius)
		else:
			# Personne en vue : le nuage s'arrête.
			var prey := Targets.nearest(get_world_3d(), global_position, _cast.seek_radius)
			_prey = prey.global_position if prey != null else Vector3.INF
	var full := _charges >= SkillStats.ACCUMULATION_MOST and _cast.breaking_point > 0.0
	var touched := _hit(
		_cast.radius * (SkillStats.BREAK_REACH if full else 1.0),
		1.0 + _cast.accumulation * 0.01 * float(_charges)
	)
	if _cast.accumulation > 0.0:
		_charges = 0 if touched else mini(_charges + 1, SkillStats.ACCUMULATION_MOST)
		_fx.charge = float(_charges) / SkillStats.ACCUMULATION_MOST
	if _cast.twin_strike > 0.0 and Game.rng.randf() * 100.0 < _cast.twin_strike:
		_twin = SkillStats.TWIN_DELAY


## L'impulsion elle-même, dans ce rayon et à ce facteur : l'Appel d'air tire vers le centre,
## le paratonnerre prend sa part (la Cible de l'orage), le Débordement arque vers un ennemi
## au-delà. Rend vrai si elle a touché quelqu'un dans son cercle. Le dessin frappe
## `Lightning.ARCS_MOST` cibles au plus, quel que soit leur nombre ; à vide, un point du cercle.
func _hit(reach: float, factor: float) -> bool:
	var world := get_world_3d()
	var targets := Targets.strike_circle(world, global_position, reach, _cast, _author, -_cast.pull, factor)
	var shown: Array[Node3D] = []
	shown.assign(targets.slice(0, Lightning.ARCS_MOST))
	# La Cible de l'orage (jalon 43) : le paratonnerre de l'Éclair vif prend aussi la frappe.
	var rod := LightningRod.storm_target_of(_author)
	if rod != null and rod not in targets \
			and global_position.distance_to(rod.global_position) <= SkillStats.STORM_ROD_REACH:
		Targets.strike(rod, _cast.roll(Game.rng), global_position, _author, _cast)
		shown.append(rod)
	if _cast.overflow > 0.0:
		var beyond := _overflow(world, reach, targets)
		if beyond != null:
			shown.append(beyond)
	var points: Array[Vector3] = []
	for target in shown:
		points.append(Vector3(target.global_position.x, global_position.y, target.global_position.z))
	if points.is_empty():
		points.append(global_position + Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU) * sqrt(randf()) * reach * 0.8)
	_fx.strike(points)
	return not targets.is_empty()


## Le Débordement : un arc vers l'ennemi le plus proche hors du cercle, jusqu'à
## `OVERFLOW_REACH` fois son rayon, à une part d'une frappe. Rend celui qu'il frappe.
func _overflow(world: World3D, reach: float, inside: Array[Hurtbox]) -> Hurtbox:
	var best: Hurtbox = null
	var best_distance := INF
	for target in Targets.in_circle(world, global_position, reach * SkillStats.OVERFLOW_REACH):
		var distance := global_position.distance_squared_to(target.global_position)
		if target not in inside and distance < best_distance:
			best = target
			best_distance = distance
	if best == null:
		return null
	var parts := DamageType.scaled(_cast.roll(Game.rng), _cast.overflow * 0.01)
	Targets.strike(best, parts, global_position, _author, _cast)
	return best

