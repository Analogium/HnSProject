class_name FrostRing
extends Node3D

## L'Onde de givre (jalon 36, transformation de la Nova de glace) : un anneau qui
## s'élargit depuis le lanceur jusqu'à `REACH` fois le rayon, et frappe chaque ennemi
## **une fois**, quand il le passe. Posé, il ne suit pas le lanceur. Sous le Reflux
## (jalon 44), il se referme ensuite sur son centre et refrappe chacun une fois.

const REACH := 3.0
const LIFETIME := 0.8

var _cast: SkillStats
var _author: StatusEffects
var _age := 0.0
## Un tirage pour tout l'anneau (invariant 3), au premier pas de physique.
var _parts: Array[float] = []
var _struck := {}
## Sa portée, en multiple du rayon de son lancer.
var _reach := REACH


static func spread(
	parent: Node, point: Vector3, cast: SkillStats, author: StatusEffects, reach_factor := REACH
) -> FrostRing:
	var ring := FrostRing.new()
	ring._reach = reach_factor
	ring._cast = cast
	ring._author = author
	parent.add_child(ring)
	Settings.veil(ring, Settings.SPELLS)
	ring.global_position = point
	return ring


## Ce qu'il couvre maintenant : vite au départ, lent au bout — une onde qui s'épuise.
func reach() -> float:
	var k := clampf(_age / LIFETIME, 0.0, 1.0)
	if _returning():
		k = clampf(2.0 - _age / LIFETIME, 0.0, 1.0)
	return _cast.radius * _reach * (1.0 - pow(1.0 - k, 2.0))


func _returning() -> bool:
	return _cast.ebb > 0.0 and _age > LIFETIME


func _life_span() -> float:
	return LIFETIME * (2.0 if _cast.ebb > 0.0 else 1.0)


func _physics_process(delta: float) -> void:
	if _parts.is_empty():
		_parts = _cast.roll(Game.rng)
	var was_returning := _returning()
	_age += delta
	if _returning() and not was_returning:
		_struck.clear()
	var r := reach()
	for target in Targets.in_circle(get_world_3d(), global_position, r):
		var id := target.get_instance_id()
		# Au retour, seul ce que l'anneau croise en se refermant, sur un rayon de large.
		if _struck.has(id) or (_returning() and target.global_position.distance_to(global_position) < r - _cast.radius):
			continue
		_struck[id] = true
		Targets.strike(target, _parts, global_position, _author, _cast, _cast.knockback)
	if _age >= _life_span():
		queue_free()

