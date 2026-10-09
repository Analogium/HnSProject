class_name StormCloud
extends Node2D

## Le nuage de Nuage d'orage : posé, il frappe tout ce qui est dessous à chaque
## période, puis se dissipe. Il ne fige jamais le jeu — une impulsion qui gèle
## toutes les demi-secondes hacherait l'image tant qu'il est posé.

## Le nuage flotte au-dessus de sa zone ; c'est le cercle au sol qui dit où elle est.
const HEIGHT := 22.0
## Porté par l'Orage portatif : à la hauteur d'un nuage posé, il cachait la tête du lanceur.
const HEIGHT_CARRIED := 40.0
const PUFFS := 7
const SPAWN := 0.2
const DISSIPATION := 0.3
## Le nuage s'éclaire de la couleur de la foudre juste après avoir frappé.
const FLASH_COLOR := 0.12
const FLASH_MIX := 0.35
const CLOUD := Color(0.30, 0.28, 0.40)
## Orage errant (`seek_radius`, jalon 35), en px/s : assez lent pour qu'un nuage posé
## reste un nuage posé, assez vif pour rattraper un ennemi qui marche.
const DRIFT_SPEED := 40.0


## Un éclair d'une frappe, du nuage ou de l'orbe statique : les deux tenaient chacun sa
## durée, son vieillissement et son dessin, à l'identique.
class Bolt:
	const LIFETIME := 0.14
	var of: Vector2
	var toward: Vector2
	var age := 0.0
	var shown := -1
	var pieces: Array[EffectForge.Piece]

	## Une seule fourche : l'éclair est court, deux le brouilleraient.
	func draw(ci: CanvasItem, flicker: RandomNumberGenerator, tint: Color) -> void:
		var beat := Lightning.hold(age)
		if beat != shown:
			shown = beat
			flicker.seed = int(ci.get_instance_id()) ^ beat ^ int(toward.x)
			pieces = Lightning.chain(
				PackedVector2Array([of, toward]), flicker, tint, 1, true, Lightning.gone(age, LIFETIME)
			)
		Lightning.put(ci, pieces)

	static func aged(bolts: Array[Bolt], delta: float) -> Array[Bolt]:
		for e in bolts:
			e.age += delta
		return bolts.filter(func(e: Bolt) -> bool: return e.age < LIFETIME)


static var _bodies := {}
## Tous ceux qui sont posés : `simultaneous` par lanceur au plus (jalon 43), le Familier
## compté à part, comme pour les serpents.
static var _live: Array[StormCloud] = []


var _cast: SkillStats
var _author: StatusEffects
var _tint := Color.WHITE
var _age := 0.0
var _strikes := 0
var _bolts: Array[Bolt] = []
var _flicker := RandomNumberGenerator.new()
## Orage portatif (`TEMPEST`) : celui qu'il suit. Sinon, l'ennemi vers lequel il dérive,
## choisi à chaque frappe.
var _follow: Node2D
var _prey := Vector2.INF
var _caster: Object
## La Traque (jalon 43) : la proie qu'il ne lâche plus.
var _quarry: Hurtbox
## L'Accumulation : les frappes tombées à vide, que la suivante qui touche paie.
var _charges := 0
## La Foudre jumelle : les secondes avant la seconde frappe, négatives sans elle.
var _twin := -1.0
## Le Front mobile : l'horloge des frappes, plus vive tant que son porteur marche.
var _clock := 0.0


static func put(
	parent: Node, point: Vector2, cast: SkillStats, author: StatusEffects, follow: Node2D = null,
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
	cloud._tint = DamageType.COLORS[cast.nature]
	parent.add_child(cloud)
	Settings.veil(cloud, Settings.SPELLS)
	cloud.global_position = point
	return cloud


func _ready() -> void:
	z_index = 4
	_flicker.seed = int(get_instance_id())


## Le corps du nuage, rastérisé d'un coup — sept bosses, une silhouette, un
## contour — et gardé : un rayon ne change qu'avec un point de talent. Choisi sur
## planche : le nuage **bombé**, éclairé d'en haut à gauche comme le reste du jeu.
static func body(radius: float, tint: Color, flash: bool, gone: float) -> EffectForge.Piece:
	var key := "%s|%d|%d|%d" % [tint.to_html(false), int(radius), int(flash), int(round(gone * 16.0))]
	if _bodies.has(key):
		return _bodies[key]
	# Graine fixe : le même nuage à chaque lancer, ses quatre états compris.
	var rng := RandomNumberGenerator.new()
	rng.seed = PUFFS
	var extent := radius * 0.7
	var margin := 16.0
	var canvas := PixelCanvas.new(int(ceil((extent + margin) * 2.0)), int(margin * 2.0))
	var middle := Vector2(canvas.width, canvas.height) * 0.5
	for i in PUFFS:
		var u := float(i) / float(PUFFS - 1)
		# Plus gros au milieu : un nuage est bombé, une rangée de disques égaux se lit
		# comme une chenille.
		canvas.disc(
			middle + Vector2(lerpf(-extent, extent, u) + rng.randf_range(-2.0, 2.0), rng.randf_range(-4.0, 3.0)),
			lerpf(5.5, 9.5, 1.0 - absf(u - 0.5) * 2.0), 0
		)
	var img := canvas.to_image([ArtPalette.ramp(CLOUD.lerp(tint, FLASH_MIX) if flash else CLOUD)])
	EffectForge.dissolve(img, gone)
	var piece := EffectForge.Piece.new(ImageTexture.create_from_image(img), -middle)
	_bodies[key] = piece
	return piece


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
	elif _prey != Vector2.INF:
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
	_bolts = Bolt.aged(_bolts, delta)
	queue_redraw()
	if _age >= _cast.duration and (_strikes >= _cast.strikes_over_duration() or _cast.moving_front > 0.0):
		queue_free()


## Une frappe de la période : où errer, puis l'impulsion, chargée par l'Accumulation (jalon 43)
## — à pleines charges, le Point de rupture l'élargit —, et la Foudre jumelle à tirer.
func _strike() -> void:
	if _cast.seek_radius > 0.0 and not is_instance_valid(_follow):
		if _cast.hunt > 0.0:
			if not is_instance_valid(_quarry) or _quarry.is_queued_for_deletion():
				_quarry = Targets.nearest(get_world_2d(), global_position, _cast.seek_radius)
		else:
			# Personne en vue : le nuage s'arrête.
			var prey := Targets.nearest(get_world_2d(), global_position, _cast.seek_radius)
			_prey = prey.global_position if prey != null else Vector2.INF
	var full := _charges >= SkillStats.ACCUMULATION_MOST and _cast.breaking_point > 0.0
	var touched := _hit(
		_cast.radius * (SkillStats.BREAK_REACH if full else 1.0),
		1.0 + _cast.accumulation * 0.01 * float(_charges)
	)
	if _cast.accumulation > 0.0:
		_charges = 0 if touched else mini(_charges + 1, SkillStats.ACCUMULATION_MOST)
	if _cast.twin_strike > 0.0 and Game.rng.randf() * 100.0 < _cast.twin_strike:
		_twin = SkillStats.TWIN_DELAY


## L'impulsion elle-même, dans ce rayon et à ce facteur : l'Appel d'air tire vers le centre,
## le paratonnerre prend sa part (la Cible de l'orage), le Débordement arque vers un ennemi
## au-delà. Rend vrai si elle a touché quelqu'un dans son cercle.
func _hit(reach: float, factor: float) -> bool:
	var world := get_world_2d()
	var targets := Targets.strike_circle(world, global_position, reach, _cast, _author, -_cast.pull, factor)
	for target in targets.slice(0, Lightning.ARCS_MOST):
		_bolt_to(to_local(target.global_position))
	# La Cible de l'orage (jalon 43) : le paratonnerre de l'Éclair vif prend aussi la frappe.
	var rod := LightningRod.storm_target_of(_author)
	if rod != null and rod not in targets \
			and global_position.distance_to(rod.global_position) <= SkillStats.STORM_ROD_REACH:
		Targets.strike(rod, _cast.roll(Game.rng), global_position, _author, _cast)
		_bolt_to(to_local(rod.global_position))
	if _cast.overflow > 0.0:
		_overflow(world, reach, targets)
	if targets.is_empty():
		# Un éclair au sol même sans cible : le nuage montre qu'il frappe, et où.
		_bolt_to(
			Vector2.from_angle(_flicker.randf_range(0.0, TAU))
			* _flicker.randf_range(0.0, reach * 0.8)
		)
	return not targets.is_empty()


## Le Débordement : un arc vers l'ennemi le plus proche hors du cercle, jusqu'à
## `OVERFLOW_REACH` fois son rayon, à une part d'une frappe.
func _overflow(world: World2D, reach: float, inside: Array[Hurtbox]) -> void:
	var best: Hurtbox = null
	var best_distance := INF
	for target in Targets.in_circle(world, global_position, reach * SkillStats.OVERFLOW_REACH):
		var distance := global_position.distance_squared_to(target.global_position)
		if target not in inside and distance < best_distance:
			best = target
			best_distance = distance
	if best == null:
		return
	var parts := DamageType.scaled(_cast.roll(Game.rng), _cast.overflow * 0.01)
	Targets.strike(best, parts, global_position, _author, _cast)
	_bolt_to(to_local(best.global_position))


func _height() -> float:
	return HEIGHT_CARRIED if is_instance_valid(_follow) else HEIGHT


func _bolt_to(point: Vector2) -> void:
	var e := Bolt.new()
	var edge := _cast.radius * 0.6
	e.of = Vector2(clampf(point.x, -edge, edge), -_height() + 4.0)
	e.toward = point
	_bolts.append(e)


func _draw() -> void:
	var fade := minf(_age / SPAWN, 1.0) * clampf((_cast.duration - _age) / DISSIPATION, 0.0, 1.0)
	# Le halo au sol dit la zone : tramé, il a le droit de s'effacer. Le nuage, lui,
	# se défait en naissant et en se dissipant.
	var zone := EffectForge.scorch(_tint, int(round(_cast.radius)))
	var zone_size := Vector2(zone.get_width(), zone.get_height())
	draw_texture(zone, EffectForge.snap(self, -zone_size * 0.5), Color(1.0, 1.0, 1.0, fade))

	var since := _age - float(maxi(_strikes - 1, 0)) * _cast.period
	var bob := Vector2(0.0, roundf(sin(_age * 1.8)))
	body(
		_cast.radius, _tint, since < FLASH_COLOR, 0.0 if fade >= 1.0 else Lightning.GONE
	).put(self, Vector2(0.0, -_height()) + bob)

	for e in _bolts:
		e.draw(self, _flicker, _tint)
