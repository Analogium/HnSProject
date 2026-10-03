class_name ToxicBreath
extends Node2D

## L'Haleine (jalon 38, transformation de la Déferlante toxique) : un cône de gaz devant le
## lanceur, qui s'allonge jusqu'à `REACH` fois le rayon et frappe chaque ennemi **une
## fois**, quand il l'atteint. Posé, il ne suit pas le lanceur.

const REACH := 2.5
## Le demi-angle du cône : 70° en tout.
const HALF_ANGLE := deg_to_rad(35.0)
const LIFETIME := 0.45
## Les formes du mur, une par cran de sa vie, comme le mur de la Déferlante.
const WALL_STEPS := 8

var _cast: SkillStats
var _author: StatusEffects
var _tint := Color.WHITE
var _facing := Vector2.RIGHT
var _age := 0.0
## Un tirage pour tout le cône (invariant 3), au premier pas de physique.
var _parts: Array[float] = []
var _struck := {}
## Le mur rastérisé de chaque cran déjà vu : à l'angle de ce geste, il ne sert qu'à lui.
var _walls := {}


static func exhale(
	parent: Node, point: Vector2, facing: Vector2, cast: SkillStats, author: StatusEffects
) -> ToxicBreath:
	var breath := ToxicBreath.new()
	breath._cast = cast
	breath._author = author
	breath._facing = facing.normalized()
	breath._tint = DamageType.COLORS[cast.nature]
	parent.add_child(breath)
	Settings.veil(breath, Settings.SPELLS)
	breath.global_position = point
	return breath


func _ready() -> void:
	z_index = 3


## Jusqu'où il porte maintenant : vite au départ, lent au bout, comme l'Onde de givre.
func reach() -> float:
	return _reach_at(clampf(_age / LIFETIME, 0.0, 1.0))


func _reach_at(k: float) -> float:
	return _cast.radius * REACH * (1.0 - pow(1.0 - k, 2.0))


## Dans le cône : l'écart à l'axe, et non la distance, que le cercle de la requête tient.
func covers(at: Vector2) -> bool:
	var to := at - global_position
	return to.length_squared() < 1.0 or absf(_facing.angle_to(to)) <= HALF_ANGLE


func _physics_process(delta: float) -> void:
	if _parts.is_empty():
		_parts = _cast.roll(Game.rng)
	_age += delta
	for target in Targets.in_circle(get_world_2d(), global_position, reach()):
		var id := target.get_instance_id()
		if not _struck.has(id) and covers(target.global_position):
			_struck[id] = true
			Targets.strike(target, _parts, global_position, _author, _cast)
	queue_redraw()
	if _age >= LIFETIME:
		queue_free()


## « Mur de gaz en arc », choisi sur planche (jalon 38) : le mur de la Déferlante sur
## l'arc du cône, qui avance avec le front, s'épaissit, puis se dissout.
func _draw() -> void:
	var step := Necrotic.step_of(clampf(_age / LIFETIME, 0.0, 1.0), WALL_STEPS - 1)
	if not _walls.has(step):
		var k := float(step) / float(WALL_STEPS - 1)
		_walls[step] = Necrotic.breath(_tint, _reach_at(k), HALF_ANGLE, _facing.angle(), k)
	Necrotic.put_band(self, _walls[step], Vector2.ZERO)
