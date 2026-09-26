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


## Choisit les cibles, les frappe et laisse le trait. Rend le nombre d'ennemis
## touchés : le lanceur ne fige le jeu que s'il y en a.
##
## **Toutes les cibles sont choisies avant le premier coup** : une mort en cours de
## chaîne changerait ce que la requête suivante trouve.
static func unload(
	parent: Node, caster_node: Node2D, cast: SkillStats, direction: Vector2
) -> int:
	var world := caster_node.get_world_2d()
	var points := PackedVector2Array([caster_node.global_position])
	var touches: Array[Hurtbox] = []
	for i in cast.target_count():
		var from_value := points[points.size() - 1]
		var target := _nearest_one(
			world, from_value, SCOPE if i == 0 else JUMP, touches,
			direction if i == 0 else Vector2.ZERO
		)
		if target == null:
			break
		touches.append(target)
		points.append(target.global_position)
	if touches.is_empty():
		points.append(caster_node.global_position + direction * INTO_THE_VOID)

	var parts := cast.roll(Game.rng)
	var author := StatusEffects.of(caster_node)
	for i in touches.size():
		Targets.strike(touches[i], parts, points[i], author, cast)

	var trace := ChainLightning.new()
	trace._points = points
	trace._tint = DamageType.COLORS[cast.dominant_nature()]
	parent.add_child(trace)
	Settings.veil(trace, Settings.SPELLS)
	return touches.size()


## `cone` nul : pas de contrainte d'angle, c'est un saut.
static func _nearest_one(
	world: World2D, from_value: Vector2, scope: float, excluded_all: Array[Hurtbox], cone: Vector2
) -> Hurtbox:
	var best_one: Hurtbox = null
	var best_distance := INF
	for target in Targets.in_circle(world, from_value, scope):
		if excluded_all.has(target):
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
