class_name ToxicBreath
extends Node3D

## L'Haleine (jalon 38, transformation de la Déferlante toxique) : un cône de gaz devant le
## lanceur, qui s'allonge jusqu'à `REACH` fois le rayon et frappe chaque ennemi **une
## fois**, quand il l'atteint. Posé, il ne suit pas le lanceur.

const REACH := 2.5
## Le demi-angle du cône : 70° en tout.
const HALF_ANGLE := deg_to_rad(35.0)
const LIFETIME := 0.45

var _cast: SkillStats
var _author: StatusEffects
var _facing := Vector3.RIGHT
var _age := 0.0
## Un tirage pour tout le cône (invariant 3), au premier pas de physique.
var _parts: Array[float] = []
var _struck := {}


static func exhale(
	parent: Node, point: Vector3, facing: Vector3, cast: SkillStats, author: StatusEffects
) -> ToxicBreath:
	var breath := ToxicBreath.new()
	breath._cast = cast
	breath._author = author
	breath._facing = facing.normalized()
	parent.add_child(breath)
	Settings.veil(breath, Settings.SPELLS)
	breath.global_position = point
	return breath


## Jusqu'où il porte maintenant : vite au départ, lent au bout, comme l'Onde de givre.
func reach() -> float:
	return _reach_at(clampf(_age / LIFETIME, 0.0, 1.0))


func _reach_at(k: float) -> float:
	return _cast.radius * REACH * (1.0 - pow(1.0 - k, 2.0))


## Dans le cône : l'écart à l'axe, et non la distance, que le cercle de la requête tient.
func covers(at: Vector3) -> bool:
	var to := at - global_position
	return to.length_squared() < 1.0 or absf(Flat.angle_to(_facing, to)) <= HALF_ANGLE


func _physics_process(delta: float) -> void:
	if _parts.is_empty():
		_parts = _cast.roll(Game.rng)
	_age += delta
	for target in Targets.in_circle(get_world_3d(), global_position, reach()):
		var id := target.get_instance_id()
		if not _struck.has(id) and covers(target.global_position):
			_struck[id] = true
			Targets.strike(target, _parts, global_position, _author, _cast)
	if _age >= LIFETIME:
		queue_free()

