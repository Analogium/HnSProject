class_name IceSpikes
extends Node2D

## Les pics de glace : ils percent le sol au point visé, frappent **une fois** ce qui
## est dans leur cercle, puis retombent. Rien ne reste — c'est ce qui les sépare du
## vortex, qui dure.
##
## Ils frappent à leur première image de physique et non à la pose : le lancer peut
## venir d'un rappel de collision, où l'espace physique refuse les requêtes
## (invariant 4).

const LIFETIME := 0.45
## Les deux bouts de la vie d'un pic : le temps qu'il met à percer, et celui qu'il
## met à **redescendre**. Il ne s'efface pas — un cristal à demi-transparent sur un
## sol sombre sort gris.
const RISE := 0.25
const SINK := 0.3
const SPIKES := 7
## Le Sillon de glace (jalon 36) : l'écart entre deux cercles qui percent, en secondes.
## Les cercles se touchent sans se chevaucher — un ennemi n'est mordu qu'une fois.
const FISSURE_STEP := 0.07

var _cast: SkillStats
var _author: StatusEffects
var _tint := Color.WHITE
var _age := 0.0
var _has_struck := false
## Avant de percer : rien ne se voit ni ne frappe, le Sillon les échelonne ainsi.
var _delay := 0.0
## Les éclats qu'il projette en retombant (`splits`) : la scène des tirs, ou rien.
var _shards: PackedScene
var _source: Node2D
var _struck := {}
## Les pieds dans le disque unité : le rayon change avec les nœuds, pas la
## répartition.
var _feet := PackedVector2Array()


static func raise_at(
	parent: Node, point: Vector2, cast: SkillStats, author: StatusEffects,
	source: Node2D = null, shards: PackedScene = null, delay := 0.0
) -> IceSpikes:
	var spikes := IceSpikes.new()
	spikes._cast = cast
	spikes._author = author
	spikes._shards = shards
	spikes._source = source
	spikes._delay = delay
	spikes._tint = DamageType.COLORS[cast.nature]
	parent.add_child(spikes)
	Settings.veil(spikes, Settings.SPELLS)
	spikes.global_position = point
	return spikes


## Le Bosquet (jalon 44) : des cercles de plus, posés contre le premier, de part et d'autre
## du cap — un seul se pose sur le côté.
static func grove(
	parent: Node, point: Vector2, toward: Vector2, cast: SkillStats, author: StatusEffects,
	source: Node2D, shards: PackedScene
) -> void:
	raise_at(parent, point, cast, author, source, shards)
	var extra := int(cast.grove)
	for i in extra:
		var side := Vector2.from_angle(toward.angle() + PI * 0.5 + TAU * float(i) / float(extra))
		raise_at(parent, point + side * cast.radius * 2.0, cast, author, source, shards)


## Le Sillon : des cercles en ligne, de `from` à `to`, chacun un peu après le précédent,
## et chacun projette ses éclats en retombant.
static func fissure(
	parent: Node, from: Vector2, to: Vector2, cast: SkillStats, author: StatusEffects,
	source: Node2D, shards: PackedScene
) -> void:
	var step := maxf(cast.radius * 2.0, 1.0)
	var dir := from.direction_to(to) if from != to else Vector2.RIGHT
	var count := maxi(ceili((from.distance_to(to) - cast.radius) / step), 1)
	for i in count:
		raise_at(
			parent, from + dir * (cast.radius + step * float(i)), cast, author, source, shards,
			FISSURE_STEP * float(i)
		)
	if cast.crevasse > 0.0:
		raise_at(
			parent, to, cast.swollen(1.0, SkillStats.CREVASSE_RADIUS), author, source, shards,
			FISSURE_STEP * float(count)
		)


## Pas de `ArtPalette.ADDITIVE` ici : les cristaux sont **dessinés**, et une
## planche cernée ne peut pas être additive — son contour sombre n'y ajoute rien.
func _ready() -> void:
	z_index = 3
	var rng := RandomNumberGenerator.new()
	rng.seed = int(get_instance_id())
	for i in SPIKES:
		var angle := TAU * float(i) / float(SPIKES) + rng.randf_range(-0.3, 0.3)
		# La racine carrée répartit à surface égale : sans elle, tout se tasse au
		# centre et le cercle qui mord ne se lit pas.
		_feet.append(Vector2.from_angle(angle) * sqrt(rng.randf_range(0.1, 1.0)))


func _physics_process(delta: float) -> void:
	if _delay > 0.0:
		_delay -= delta
		return
	if not _has_struck:
		_has_struck = true
		_strike()
		if _cast.ground_duration > 0.0:
			DashTrail.patch(get_parent(), global_position, _cast.ground(), _author)
		if _cast.aftershock > 0.0:
			for i in int(_cast.tremors) + 1:
				raise_at(
					get_parent(), global_position, _cast.aftershock_of(), _author, _source, _shards,
					SkillStats.AFTERSHOCK_GAP * float(i + 1)
				)
	_age += delta
	queue_redraw()
	if _age >= LIFETIME:
		# En retombant : l'étoile d'éclats épargne ce que les pics ont mordu.
		if _cast.splits > 0.0 and _shards != null:
			Projectile.split(
				get_parent(), _shards, global_position, Vector2.RIGHT, 0.0, _cast.nature,
				_source, _cast.shard(), int(_cast.splits), _struck
			)
		queue_free()


## Un tirage pour tout le cercle (invariant 3) ; le Plein centre (jalon 44) frappe plus fort
## ce qui est au cœur, la part qu'a l'Œil du brasier.
func _strike() -> void:
	var parts := _cast.roll(Game.rng)
	var eyed := parts.duplicate()
	for i in eyed.size():
		eyed[i] *= 1.0 + _cast.eye * 0.01
	var core := _cast.radius * SkillStats.EYE_PART
	for target in Targets.in_circle(get_world_2d(), global_position, _cast.radius):
		var inside := target.global_position.distance_to(global_position) <= core
		Targets.strike(target, eyed if inside else parts, global_position, _author, _cast)
		_struck[target.get_instance_id()] = true


## Des cristaux debout, pointe en haut : un pic vu de dessus en vue plongeante monte
## vers le ciel, comme les flammes d'Immolation.
##
## Un grand, un petit, alternés : sept pics de la même taille font une palissade —
## la leçon de la Ruée ardente, où le défaut n'était pas le nombre mais la
## régularité.
##
## Seul le givre au sol s'efface ; les cristaux, eux, **rentrent sous terre**.
func _draw() -> void:
	if _delay > 0.0:
		return
	# Une seule valeur pour la fin du geste : les cristaux rentrent sous terre et le
	# givre s'efface au même rythme, sinon l'un survit à l'autre.
	var ending := clampf((LIFETIME - _age) / (LIFETIME * SINK), 0.0, 1.0)
	var out := minf(clampf(_age / (LIFETIME * RISE), 0.0, 1.0), ending)
	# Le givre au sol dit où ça mord, et il est tramé : un anneau tracé est la
	# dernière chose qui trahit le vecteur au milieu d'un décor en pixels.
	EffectForge.put_scorch(self, _tint, maxi(roundi(_cast.radius), 1), ending)
	for i in _feet.size():
		Frost.raise_spike(self, _feet[i] * _cast.radius, i % 2 == 0, out, _tint)
