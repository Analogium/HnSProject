class_name DashTrail
extends Node3D

## Ce qu'une ruée laisse derrière elle : un couloir qui frappe ce qui s'y trouve, une
## fois par période, jusqu'à la fin de sa durée. Il ne fige jamais le jeu, comme tout
## ce qui dure.
##
## Le couloir est une **file de cercles** le long du segment : `Targets.in_circle()` est
## le seul chemin des coups sans collision, et il ne connaît que le cercle.

## L'écart entre deux sondes, en part du rayon. Au-delà de 1, un ennemi peut tenir entre
## deux cercles ; en dessous, on paie des requêtes pour rien.
const STEP := 0.9
## Le temps qu'un sol met à paraître : ravivé, il repart déjà paru (`_renew()`).
const SPAWN := 0.12
## La couche sous les corps, au-dessus du sol (`Zone.ground`, où se posent aussi les
## zones de danger). Sans elle, le couloir retombe chez qui le pose.
const GROUND_LAYER := "ground_layer"
## La Mèche (jalon 42) : le temps entre deux plaques qui explosent, du départ à l'arrivée.
const WICK_DELAY := 0.05

var _cast: SkillStats
var _author: StatusEffects
var _tint := Color.WHITE
## En repère local : le nœud est posé au départ de la ruée.
var _toward := Vector3.ZERO
var _age := 0.0
var _strikes := 0
## Un sol (`patch()`) et non le couloir d'une ruée : lui seul ne cumule pas.
var _ground := false
## Sa case dans `_laid`, pour un sol : où il se tient, de quelle compétence et de quelle nature.
var _key := ""
## Où posent ses explosions — au-dessus des corps, pas sur sa couche. Le temps depuis que
## la Mèche s'est allumée, et les plaques déjà parties.
var _effects: Node
var _fuse := 0.0
var _fused := 0

## Les sols vivants par case : **un sol ne se pose pas sur un sol** de la même compétence et
## de la même nature, il le ravive. Ils ne cumulent pas leurs coups ; sans cela, 144 serpents
## en tenaient 1 800, 52 ms par image (jalon 41).
static var _laid := {}
## Le côté d'une case, en part du rayon : un sol ravivé est au plus à 0,7 rayon de celui qu'on posait.
const LAID_CELL := 0.5


## `ground` : un sol en long — le Sillon d'acier d'une vague —, qui ne cumule pas.
static func leave(
	parent: Node, from_value: Vector3, to: Vector3, cast: SkillStats, author: StatusEffects,
	ground := false
) -> DashTrail:
	var trail := DashTrail.new()
	trail._cast = cast
	trail._author = author
	trail._ground = ground
	trail._toward = to - from_value
	trail._tint = DamageType.COLORS[cast.nature]
	trail._effects = parent
	layer(parent).add_child(trail)
	Settings.veil(trail, Settings.SPELLS)
	trail.global_position = from_value
	return trail


## Le **sol brûlant** (jalon 34) : un sillage sans longueur, posé sur place. Différé,
## parce qu'il naît aussi d'une mort, donc d'un rappel de collision.
static func patch(
	parent: Node, at: Vector3, ground: SkillStats, author: StatusEffects
) -> DashTrail:
	var side := maxf(ground.radius * LAID_CELL, 1.0)
	var cell := Vector2i(floori(at.x / side), floori(at.z / side))
	var key := "%s@%d@%d@%d" % [ground.skill_id, ground.nature, cell.x, cell.y]
	var laid: DashTrail = _laid.get(key)
	if is_instance_valid(laid) and not laid.is_queued_for_deletion():
		laid._renew()
		return laid
	var trail := DashTrail.new()
	trail._key = key
	_laid[key] = trail
	trail._cast = ground
	trail._author = author
	trail._ground = true
	trail._tint = DamageType.COLORS[ground.nature]
	Settings.veil(trail, Settings.SPELLS)
	DeferredTree.add_deferred(layer(parent), trail, at)
	return trail


## **Sous les corps** : au-dessus d'eux, on marchait sous sa propre traînée ; parmi les
## tirs, elle se triait en Y avec les corps et passait devant qui se tenait au-dessus.
##
## **Le premier qu'on voit** : la zone quittée pour la ville garde son sol, caché et figé
## (`Zone._freeze_zone`), et ce qui s'y posait en ville n'apparaissait ni ne bougeait.
static func layer(parent: Node) -> Node:
	if not parent.is_inside_tree():
		return parent
	for ground: Node3D in parent.get_tree().get_nodes_in_group(GROUND_LAYER):
		if ground.is_visible_in_tree():
			return ground
	return parent


## Ravivé par un sol posé sur lui : il repart pour sa durée, déjà paru, et frappe aussitôt —
## sans doubler un coup, un sol ne frappant qu'une fois par période (`_first_ground_on()`).
func _renew() -> void:
	_age = SPAWN
	_strikes = 0


func _exit_tree() -> void:
	if _laid.get(_key) == self:
		_laid.erase(_key)


## Les impulsions se comptent par `strikes_over_duration()`, la fonction même de
## l'estimation : la fiche et la trace ne peuvent pas annoncer deux nombres.
func _physics_process(delta: float) -> void:
	_age += delta
	var due := _cast.strikes_due(_age)
	while _strikes < due:
		_strike()
		_strikes += 1
	var spent := _age >= _cast.duration and _strikes >= _cast.strikes_over_duration()
	# La Mèche brûle quand la traînée s'éteint ; la Mèche courte dès qu'elle est posée, et
	# la traînée part avec elle.
	if _cast.wick > 0.0 and not _ground and (spent or _cast.short_fuse > 0.0):
		if not _burn_fuse(delta):
			queue_free()
	elif spent:
		queue_free()


## Une explosion par plaque — une sonde sur deux, qu'elles ne se chevauchent pas —, à la
## part `wick` d'une impulsion, un tirage chacune. Vrai tant qu'il en reste à faire partir.
func _burn_fuse(delta: float) -> bool:
	_fuse += delta
	var points := _probes()
	var plates := ceili(float(points.size()) / 2.0)
	var due := mini(int(_fuse / WICK_DELAY) + 1, plates)
	while _fused < due:
		var parts := DamageType.scaled(_cast.roll(Game.rng), _cast.wick * 0.01)
		Explosion.put(_effects, points[_fused * 2], parts, _cast.radius, null, _tint, _author, _cast)
		_fused += 1
	return _fused < plates


## Un tirage par impulsion et non par cercle : c'est un geste de la trace, pas un coup
## par sonde. Une cible sous deux cercles ne reçoit qu'un coup.
func _strike() -> void:
	var parts := _cast.roll(Game.rng)
	var struck := {}
	for point in _probes():
		for target in Targets.in_circle(get_world_3d(), point, _cast.radius):
			var id := target.get_instance_id()
			if struck.has(id) or (_ground and not _first_ground_on(target)):
				continue
			struck[id] = true
			Targets.strike(target, parts, point, _author, _cast)


## **Un sol ne cumule pas** (jalon 37) : une cible déjà frappée par un sol de la même
## compétence dans la période en cours ne l'est pas une seconde fois. Le Serpent en
## empilait des dizaines sous une cible immobile — ×19 en duel au banc des arbres.
func _first_ground_on(target: Hurtbox) -> bool:
	var key := StringName("ground_" + _cast.skill_id)
	var now := Engine.get_physics_frames()
	if now - int(target.get_meta(key, -1_000_000)) < roundi(_cast.period * Engine.physics_ticks_per_second):
		return false
	target.set_meta(key, now)
	return true


## Les centres des sondes, en repère global : les deux bouts au moins.
func _probes() -> Array[Vector3]:
	var out: Array[Vector3] = []
	var span := _toward.length()
	var count := maxi(ceili(span / maxf(_cast.radius * STEP, 1.0)), 1)
	for i in count + 1:
		out.append(global_position + _toward * (float(i) / float(count)))
	return out

