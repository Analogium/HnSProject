class_name IceSpikes
extends Node3D

## Les pics de glace : ils percent le sol au point visé, frappent **une fois** ce qui
## est dans leur cercle, puis retombent. Rien ne reste — c'est ce qui les sépare du
## vortex, qui dure.
##
## Ils frappent à leur première image de physique et non à la pose : le lancer peut
## venir d'un rappel de collision, où l'espace physique refuse les requêtes
## (invariant 4).

const LIFETIME := 0.45
## Le Sillon de glace (jalon 36) : l'écart entre deux cercles qui percent, en secondes.
## Les cercles se touchent sans se chevaucher — un ennemi n'est mordu qu'une fois.
const FISSURE_STEP := 0.07
## Les éclats d'un même flanc s'écartent de ce pas, en radians.
const FLANK_FAN := 0.35

var _cast: SkillStats
var _author: StatusEffects
var _age := 0.0
var _has_struck := false
## Avant de percer : rien ne se voit ni ne frappe, le Sillon les échelonne ainsi.
var _delay := 0.0
## Les éclats qu'il projette en retombant (`splits`) : la scène des tirs, ou rien.
var _shards: PackedScene
var _source: Node3D
## La direction du lancer : les éclats partent de part et d'autre.
var _toward := Vector3.RIGHT
var _struck := {}


static func raise_at(
	parent: Node, point: Vector3, toward: Vector3, cast: SkillStats, author: StatusEffects,
	source: Node3D = null, shards: PackedScene = null, delay := 0.0
) -> IceSpikes:
	var spikes := IceSpikes.new()
	spikes._toward = toward
	spikes._cast = cast
	spikes._author = author
	spikes._shards = shards
	spikes._source = source
	spikes._delay = delay
	parent.add_child(spikes)
	Settings.veil(spikes, Settings.SPELLS)
	spikes.global_position = point
	return spikes


## Le Bosquet (jalon 44) : des cercles de plus, posés contre le premier, de part et d'autre
## du cap — un seul se pose sur le côté.
static func grove(
	parent: Node, point: Vector3, toward: Vector3, cast: SkillStats, author: StatusEffects,
	source: Node3D, shards: PackedScene
) -> void:
	raise_at(parent, point, toward, cast, author, source, shards)
	var extra := int(cast.grove)
	for i in extra:
		var side := Flat.from_angle(Flat.angle(toward) + PI * 0.5 + TAU * float(i) / float(extra))
		raise_at(parent, point + side * cast.radius * 2.0, toward, cast, author, source, shards)


## Le Sillon : des cercles en ligne, de `from` à `to`, chacun un peu après le précédent,
## et chacun projette ses éclats en retombant.
static func fissure(
	parent: Node, from: Vector3, to: Vector3, cast: SkillStats, author: StatusEffects,
	source: Node3D, shards: PackedScene
) -> void:
	var step := maxf(cast.radius * 2.0, 1.0)
	var dir := from.direction_to(to) if from != to else Vector3.RIGHT
	var count := maxi(ceili((from.distance_to(to) - cast.radius) / step), 1)
	for i in count:
		raise_at(
			parent, from + dir * (cast.radius + step * float(i)), dir, cast, author, source, shards,
			FISSURE_STEP * float(i)
		)
	if cast.crevasse > 0.0:
		raise_at(
			parent, to, dir, cast.swollen(1.0, SkillStats.CREVASSE_RADIUS), author, source, shards,
			FISSURE_STEP * float(count)
		)


func _physics_process(delta: float) -> void:
	if _delay > 0.0:
		_delay -= delta
		return
	if not _has_struck:
		_has_struck = true
		_strike()
		IceSpikesFx.raise(self, global_position, _cast.nature, _cast.radius)
		if _cast.ground_duration > 0.0:
			DashTrail.patch(get_parent(), global_position, _cast.ground(), _author)
		if _cast.aftershock > 0.0:
			for i in int(_cast.tremors) + 1:
				raise_at(
					get_parent(), global_position, _toward, _cast.aftershock_of(), _author, _source, _shards,
					SkillStats.AFTERSHOCK_GAP * float(i + 1)
				)
	_age += delta
	if _age >= LIFETIME:
		# En retombant : les éclats épargnent ce que les pics ont mordu.
		if _cast.splits > 0.0 and _shards != null:
			for shard in Projectile.scatter(
				get_parent(), _shards, global_position, flanks(_toward, int(_cast.splits)), 0.0,
				_cast.nature, _source, _cast.shard(), _struck
			):
				shard.wear_sliver()
		queue_free()


## Les éclats de part et d'autre du lancer, un flanc puis l'autre : visé vers le haut de l'écran,
## ils partent à gauche et à droite. Ceux d'un même flanc s'ouvrent en éventail.
static func flanks(toward: Vector3, count: int) -> Array[Vector3]:
	var across := Flat.orthogonal(toward).normalized()
	var directions: Array[Vector3] = []
	for i in count:
		var side := across if i % 2 == 0 else -across
		var on_side := (count + 1 - i % 2) / 2
		var rank := float(i / 2) - float(on_side - 1) * 0.5
		directions.append(Flat.rotated(side, rank * FLANK_FAN))
	return directions


## Un tirage pour tout le cercle (invariant 3) ; le Plein centre (jalon 44) frappe plus fort
## ce qui est au cœur, la part qu'a l'Œil du brasier.
func _strike() -> void:
	var parts := _cast.roll(Game.rng)
	var eyed := DamageType.scaled(parts, 1.0 + _cast.eye * 0.01)
	var core := _cast.radius * SkillStats.EYE_PART
	for target in Targets.in_circle(get_world_3d(), global_position, _cast.radius):
		var inside := target.global_position.distance_to(global_position) <= core
		Targets.strike(target, eyed if inside else parts, global_position, _author, _cast)
		_struck[target.get_instance_id()] = true

