class_name ChainLightning
extends Node2D

## La décharge de Chaîne d'éclairs : elle choisit ses cibles, les frappe, puis
## reste un quart de seconde à l'écran en trait brisé.

const SCOPE := 150.0
## Le cône de la première cible, en cosinus du demi-angle : 45° de part et d'autre
## de la visée. Plus large, la décharge part sur le voisin de l'ennemi visé.
const COS_HALF_CONE := 0.7071
const JUMP := 90.0
## Sans cible, la décharge part quand même : un sort payé qui ne montre rien se lit
## comme une touche morte.
const INTO_THE_VOID := 100.0
const LIFETIME := 0.22

var _points := PackedVector2Array()
var _tint := Color.WHITE
var _age := 0.0
## Tirage local et jamais `Game.rng` : un grésillement qui y puiserait décalerait
## tous les tirages de la partie (invariant 3).
var _flicker := RandomNumberGenerator.new()
## La forme montrée et le battement qui l'a fabriquée : une par battement, pas par image.
var _shown := -1
var _pieces: Array[EffectForge.Piece]


## Le Relais (jalon 43) : le rayon où éclate une charge statique prise.
const RELAY_RADIUS := 20.0


## Un trajet de la décharge : ses points depuis son départ, ce qu'elle prend à chaque saut
## — ennemis, et charges sous le Relais —, et ses bifurcations : le point d'où part la
## branche et les sauts qu'elle emporte.
class Run:
	var points := PackedVector2Array()
	var taken: Array[Node2D] = []
	var forks: Array[Vector2i] = []


## Choisit les cibles, les frappe et laisse le trait. Rend le nombre d'ennemis
## touchés : le lanceur ne fige le jeu que s'il y en a.
##
## **Toutes les cibles sont choisies avant le premier coup** : une mort en cours de
## chaîne changerait ce que la requête suivante trouve. La Toile d'arcs (`WEB`, jalon 35)
## ne saute pas : chaque cible part du lanceur, et un trait par cible.
static func unload(
	parent: Node, caster_node: Node2D, cast: SkillStats, direction: Vector2
) -> int:
	return discharge(
		parent, caster_node.get_world_2d(), caster_node.global_position,
		StatusEffects.of(caster_node), cast, direction, caster_node
	)


## La décharge depuis un point : celle du lanceur, ou celle que le Survoltage relance d'un
## tué (`direction` nulle : pas de cône, un saut). `caster`, s'il y en a un, reçoit le
## Retour par la masse.
static func discharge(
	parent: Node, world: World2D, origin: Vector2, author: StatusEffects, cast: SkillStats,
	direction: Vector2, caster: Node2D = null
) -> int:
	var tint: Color = DamageType.COLORS[cast.nature]
	var parts := cast.roll(Game.rng)
	if cast.shape == Skill.Shape.WEB:
		return _web(parent, world, origin, author, cast, parts, tint, direction)
	var excluded: Array[Node2D] = []
	var main := _run(world, origin, cast, direction, cast.target_count(), excluded, true)
	var runs: Array[Run] = [main]
	# Les branches après le tronc, qui garde ses cibles ; une branche ne bifurque plus.
	var offsets: Array[int] = [0]
	for fork in main.forks:
		runs.append(_run(world, main.points[fork.x], cast, Vector2.ZERO, fork.y, excluded, false))
		offsets.append(fork.x)
	var struck := 0
	for r in runs.size():
		struck += _strike(parent, runs[r], offsets[r], cast, parts, author, tint)
	if main.taken.is_empty():
		main.points.append(origin + direction * INTO_THE_VOID)
	for run in runs:
		if run.points.size() > 1:
			trace(parent, run.points, tint)
	# Le Retour par la masse (jalon 43) : la décharge revient au lanceur, et lui rend du mana.
	if cast.grounding > 0.0 and struck > 0 and is_instance_valid(caster):
		trace(parent, PackedVector2Array([main.points[-1], caster.global_position]), tint)
		if caster is Player:
			(caster as Player).gain_mana(cast.grounding * float(struck))
	return struck


## Saute de proche en proche, `left` fois au plus. Le premier saut dans le cône de la
## visée, s'il y en a une.
static func _run(
	world: World2D, from_value: Vector2, cast: SkillStats, cone: Vector2, left: int,
	excluded: Array[Node2D], forks: bool
) -> Run:
	var run := Run.new()
	run.points.append(from_value)
	var jumps := 0
	while left > 0 and jumps < SkillStats.CHAIN_JUMPS_MOST:
		var aimed := jumps == 0 and cone != Vector2.ZERO
		var next := _nearest_one(
			world, run.points[-1], SCOPE if aimed else JUMP + cast.jump_reach, excluded,
			cone if aimed else Vector2.ZERO, cast.relay > 0.0
		)
		if next == null:
			break
		excluded.append(next)
		run.taken.append(next)
		run.points.append(next.global_position)
		jumps += 1
		if not _free_hop(next, cast):
			left -= 1
		# La Bifurcation : la branche part du point d'avant, vers un autre ennemi.
		if forks and cast.bifurcation > 0.0 and jumps > 1 and left > 0 \
				and Game.rng.randf() * 100.0 < cast.bifurcation:
			run.forks.append(Vector2i(run.points.size() - 2, left))
	return run


## Un saut qui ne s'use pas : vers un engourdi sous la Conductance, vers une charge sous le
## Réamorçage (jalon 43).
static func _free_hop(next: Node2D, cast: SkillStats) -> bool:
	if next is StaticCharge:
		return cast.relay_refund > 0.0
	return cast.conductance > 0.0 and (next as Hurtbox).has_state(StatusEffects.Kind.NUMB)


## Frappe ce qu'un trajet a pris, chaque saut plus fort sous le Crescendo — une branche
## reprend le compte là où elle part. Une charge prise éclate (le Relais). Rend les ennemis.
static func _strike(
	parent: Node, run: Run, offset: int, cast: SkillStats, parts: Array[float],
	author: StatusEffects, tint: Color
) -> int:
	var struck := 0
	for i in run.taken.size():
		var hit := DamageType.scaled(parts, 1.0 + cast.jump_gain * 0.01 * float(offset + i))
		var next := run.taken[i]
		if next is StaticCharge:
			Explosion.put(parent, next.global_position, hit, RELAY_RADIUS, null, tint, author, cast)
			next.queue_free()
			continue
		Targets.strike(next as Hurtbox, hit, run.points[i], author, cast)
		struck += 1
	return struck


## La Toile d'arcs : un arc du lanceur à chaque cible. La Ramure (jalon 43) : chaque arc
## saute encore une fois depuis sa cible, à une part du coup — choisis avant de frapper.
static func _web(
	parent: Node, world: World2D, origin: Vector2, author: StatusEffects, cast: SkillStats,
	parts: Array[float], tint: Color, direction: Vector2
) -> int:
	var excluded: Array[Node2D] = []
	var arcs: Array[Hurtbox] = []
	for i in cast.target_count():
		var target := _nearest_one(world, origin, SCOPE, excluded, Vector2.ZERO) as Hurtbox
		if target == null:
			break
		excluded.append(target)
		arcs.append(target)
	var leaps := {}
	if cast.web_branch > 0.0:
		for target in arcs:
			var next := _nearest_one(world, target.global_position, JUMP, excluded, Vector2.ZERO) as Hurtbox
			if next != null:
				excluded.append(next)
				leaps[target] = next
	var leap := DamageType.scaled(parts, cast.web_branch * 0.01)
	for target in arcs:
		Targets.strike(target, parts, origin, author, cast)
		trace(parent, PackedVector2Array([origin, target.global_position]), tint)
		if leaps.has(target):
			var next: Hurtbox = leaps[target]
			Targets.strike(next, leap, target.global_position, author, cast)
			trace(parent, PackedVector2Array([target.global_position, next.global_position]), tint)
	if arcs.is_empty():
		trace(parent, PackedVector2Array([origin, origin + direction * INTO_THE_VOID]), tint)
	return arcs.size() + leaps.size()


## Le Survoltage (jalon 43) : une petite chaîne depuis un engourdi tué. Différée par
## l'appelant — le tué meurt dans un rappel de collision, où l'espace refuse les requêtes.
static func surge(
	parent: Node, world: World2D, at: Vector2, author: StatusEffects, cast: SkillStats
) -> void:
	if is_instance_valid(parent):
		discharge(parent, world, at, author, cast, Vector2.ZERO)


static func trace(parent: Node, points: PackedVector2Array, tint: Color) -> void:
	var trace := ChainLightning.new()
	trace._points = points
	trace._tint = tint
	parent.add_child(trace)
	Settings.veil(trace, Settings.SPELLS)


## `cone` nul : pas de contrainte d'angle, c'est un saut. `charges` : les charges
## statiques sont des cibles comme les ennemis (le Relais).
static func _nearest_one(
	world: World2D, from_value: Vector2, scope: float, excluded_all: Array[Node2D], cone: Vector2,
	charges := false
) -> Node2D:
	var candidates: Array[Node2D] = []
	candidates.assign(Targets.in_circle(world, from_value, scope))
	if charges:
		for charge in StaticCharge.live():
			if from_value.distance_to(charge.global_position) <= scope:
				candidates.append(charge)
	var best_one: Node2D = null
	var best_distance := INF
	for target in candidates:
		if excluded_all.has(target) or target.is_queued_for_deletion():
			continue
		var toward := target.global_position - from_value
		var distance := toward.length_squared()
		if cone != Vector2.ZERO and distance > 0.01 and cone.dot(toward.normalized()) < COS_HALF_CONE:
			continue
		if distance < best_distance and Targets.in_sight(world, from_value, target.global_position):
			best_one = target
			best_distance = distance
	return best_one


func _ready() -> void:
	z_index = 5


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
	queue_redraw()


## La décharge ne s'éteint pas, elle **bat** : la forme tient une dix-huitième de
## seconde puis saute, et se défait sur son dernier tiers.
func _draw() -> void:
	var beat := Lightning.hold(_age)
	if beat != _shown:
		_shown = beat
		_flicker.seed = int(get_instance_id()) ^ beat
		var local := PackedVector2Array()
		for p in _points:
			local.append(to_local(p))
		_pieces = Lightning.chain(local, _flicker, _tint, 2, true, Lightning.gone(_age, LIFETIME))
	Lightning.put(self, _pieces)
