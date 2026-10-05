class_name FrostRing
extends Node2D

## L'Onde de givre (jalon 36, transformation de la Nova de glace) : un anneau qui
## s'élargit depuis le lanceur jusqu'à `REACH` fois le rayon, et frappe chaque ennemi
## **une fois**, quand il le passe. Posé, il ne suit pas le lanceur.

const REACH := 3.0
const LIFETIME := 0.8
## « Javelots projetés », choisi sur planche : ceux du Trait de glace, pointe vers
## l'extérieur, un tous les seize pixels de cercle — plus serrés, ils font un hérisson.
const JAVELIN_STEP := 16.0
## L'angle d'or : un javelot de plus quand l'anneau grandit ne déplace pas les autres.
const GOLDEN := 2.399963
## La dernière part de sa vie, où il se vide un javelot après l'autre au lieu de pâlir.
const EMPTYING := 0.35
## L'Onde brûlante du Bond (jalon 42), le même anneau en feu : « couronne alternée »,
## choisie sur planche — une grande langue, une petite, tous les quatorze pixels.
const FLAME_STEP := 14.0

var _cast: SkillStats
var _author: StatusEffects
var _tint := Color.WHITE
var _age := 0.0
## Un tirage pour tout l'anneau (invariant 3), au premier pas de physique.
var _parts: Array[float] = []
var _struck := {}
## Sa portée, en multiple du rayon de son lancer.
var _reach := REACH


static func spread(
	parent: Node, point: Vector2, cast: SkillStats, author: StatusEffects, reach_factor := REACH
) -> FrostRing:
	var ring := FrostRing.new()
	ring._reach = reach_factor
	ring._cast = cast
	ring._author = author
	ring._tint = DamageType.COLORS[cast.nature]
	parent.add_child(ring)
	Settings.veil(ring, Settings.SPELLS)
	ring.global_position = point
	return ring


func _ready() -> void:
	z_index = 3


## Ce qu'il couvre maintenant : vite au départ, lent au bout — une onde qui s'épuise.
func reach() -> float:
	var k := clampf(_age / LIFETIME, 0.0, 1.0)
	return _cast.radius * _reach * (1.0 - pow(1.0 - k, 2.0))


func _physics_process(delta: float) -> void:
	if _parts.is_empty():
		_parts = _cast.roll(Game.rng)
	_age += delta
	for target in Targets.in_circle(get_world_2d(), global_position, reach()):
		var id := target.get_instance_id()
		if not _struck.has(id):
			_struck[id] = true
			Targets.strike(target, _parts, global_position, _author, _cast)
	queue_redraw()
	if _age >= LIFETIME:
		queue_free()


## Un léger décalage de chaque javelot sur le rayon, fixé par son rang : le désordre de
## la planche, sans tirage — l'anneau ne scintille pas d'une image à l'autre.
func _draw() -> void:
	var r := reach()
	var left := clampf((LIFETIME - _age) / (LIFETIME * EMPTYING), 0.0, 1.0)
	if _cast.nature == DamageType.Kind.FIRE:
		_crown(r, left)
		return
	for i in maxi(int(TAU * r / JAVELIN_STEP), 1):
		if fmod(float(i) * 0.618, 1.0) > left:
			continue
		var angle := float(i) * GOLDEN
		var out := Vector2.from_angle(angle)
		Frost.javelin(_tint, Slash.turn_of(angle)).put(self, out * (r + 4.0 * sin(float(i) * 7.1)))


## Les langues, pieds sur le cercle, et qui s'éteignent une à une comme les javelots.
func _crown(r: float, left: float) -> void:
	var big := EffectForge.flames(_tint)
	var small := EffectForge.small_flames(_tint)
	var n := maxi(int(TAU * r / FLAME_STEP), 6)
	for i in n:
		if fmod(float(i) * 0.618, 1.0) > left:
			continue
		var frames := big if i % 2 == 0 else small
		var tex: Texture2D = frames[int(_age * EffectForge.FLAME_HZ + float(i) * 1.7) % frames.size()]
		var foot := Vector2.from_angle(TAU * float(i) / float(n)) * r
		var size := Vector2(tex.get_width(), tex.get_height())
		draw_texture_rect(tex, Rect2(EffectForge.snap(self, foot - Vector2(size.x * 0.5, size.y)), size), false)
