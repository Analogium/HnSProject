class_name Meteor
extends Node3D

## La Boule de feu devenue Météore : elle tombe du ciel sur le point visé et y éclate **comme
## la boule** — même explosion, en flammes. En 3D (jalon 54, « boule et ombre » choisie sur
## planche) : la boule en grand (`FlameFx.as_meteor()`) tombe en biais, d'en haut à gauche — vue
## d'en haut, une chute droite ne se lit pas —, et son ombre grandit au sol : elle dit où.

## Le temps de sa chute : assez pour se voir venir, pas assez pour qu'un ennemi sorte du
## cercle en marchant.
const FALL := 0.45
## La secousse de l'impact, en part de celle d'un lancer du joueur.
const IMPACT_SHAKE := 2.0
## D'où elle tombe, en pixels du monde depuis le point d'impact.
const FROM := Vector3(-110.0, 260.0, -90.0)
## L'ombre, en part du rayon de l'explosion.
const SHADOW := 0.6

var _cast: SkillStats
var _author: StatusEffects
## Le lanceur et la boule dont sortent les éclats de Fragmentation.
var _source: Node3D
var _shards: PackedScene
var _age := 0.0
## Une mini-météorite de la Pluie (jalon 42) : la boule de 13 px et trois langues, sans
## secousse — la grande se sent, ses retombées non.
var small := false
var _faller: Node3D
var _shadow: MeshInstance3D
## La chute vue, à l'image : posée au pas de physique, la boule restait immobile entre deux pas
## et sa traînée sortait en perles.
var _seen := 0.0


static func fall(
	parent: Node, point: Vector3, cast: SkillStats, author: StatusEffects, source: Node3D = null,
	shards: PackedScene = null, is_small := false
) -> Meteor:
	var meteor := Meteor.new()
	meteor.small = is_small
	meteor._cast = cast
	meteor._author = author
	meteor._source = source
	meteor._shards = shards
	parent.add_child(meteor)
	Settings.veil(meteor, Settings.SPELLS)
	meteor.global_position = point
	meteor._faller = Node3D.new()
	# Posée à l'image, hors de l'interpolation de physique : immobile entre deux pas, sa traînée
	# sortait en perles.
	meteor._faller.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	meteor.add_child(meteor._faller)
	meteor._faller.position = FROM
	var ball := FlameFx.ball(meteor._faller, cast.nature)
	if not is_small:
		ball.as_meteor()
	meteor._shadow = FlameFx.shadow(meteor, cast.radius * SHADOW)
	return meteor


func _process(delta: float) -> void:
	_seen += delta
	# Elle accélère en tombant.
	var p := minf(_seen / FALL, 1.0)
	_faller.position = FROM * (1.0 - p * p)
	_shadow.set_instance_shader_parameter(&"progress", p)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= FALL:
		Explosion.of_cast(get_parent(), global_position, _cast, _cast.radius, _author).flames = true
		_rain()
		# Le poids de la chute : l'impact se sent, ce qui le sépare d'une boule de plus.
		# Valide d'abord : l'épaule du Familier peut s'être dissoute pendant la chute, et
		# l'erreur sautait le `queue_free()` — le météore explosait alors à chaque image.
		if is_instance_valid(_source) and _source is Player and not small:
			Game.hit_stop()
			Game.shake_camera((_source as Player).camera, (_source as Player).shake_amount * IMPACT_SHAKE)
		# Fragmentation : l'étoile d'éclats part du point d'impact.
		if _cast.splits > 0.0 and _shards != null:
			Projectile.split(
				get_parent(), _shards, global_position, Vector3.RIGHT, _cast.projectile_speed,
				_cast.nature, _source, _cast.shard(), int(_cast.splits), {}
			)
		queue_free()


## La Pluie de météorites : les retombées partent de l'impact, en couronne, et tombent à
## leur tour. Leur lancer n'en fait pas tomber d'autres (`SkillStats.shower()`).
func _rain() -> void:
	var count := int(_cast.meteor_shower)
	if count <= 0:
		return
	var fallout := _cast.shower()
	for i in count:
		var at := global_position + Flat.from_angle(TAU * float(i) / float(count)) \
			* _cast.radius * SkillStats.SHOWER_SPREAD
		Meteor.fall(get_parent(), at, fallout, _author, _source, null, true)

