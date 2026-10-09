class_name Meteor
extends Node2D

## La Boule de feu devenue Météore (jalon 34, « crinière » choisie sur planche) : elle
## tombe droit du ciel sur le point visé et y éclate **comme la boule** — même
## explosion (`Explosion.put()`). Son ombre grandit au sol : c'est elle qui dit où.

## D'où elle tombe, en pixels, et en combien de temps. Assez pour se voir venir, pas
## assez pour qu'un ennemi sorte du cercle en marchant.
const HEIGHT := 70.0
const FALL := 0.45
## Les bouffées au-dessus de la crinière, et leur écart.
const TRAIL := 3
const TRAIL_STEP := 7.0
## La crinière : cinq langues, une grande sur deux, l'écart entre deux pieds.
const MANE := 5
const MANE_STEP := 5.0
## L'ombre, du point de départ à l'impact : celle d'une boule de 21 px.
const SHADOW_FROM := 7
const SHADOW_TO := 20
const SHADOW := Color(0.06, 0.03, 0.02)
## Au réglage d'une aura, l'ombre disparaissait sur la terre sombre (vu à la capture) ;
## à 0,6, la boule de 21 px en couvrait tout le cœur dense.
const SHADOW_ALPHA := 0.9
## La secousse de l'impact, en part de celle d'un lancer du joueur.
const IMPACT_SHAKE := 2.0

var _cast: SkillStats
var _author: StatusEffects
## Le lanceur et la boule dont sortent les éclats de Fragmentation.
var _source: Node2D
var _shards: PackedScene
var _tint := Color.WHITE
var _age := 0.0
## Une mini-météorite de la Pluie (jalon 42) : la boule de 13 px et trois langues, sans
## secousse — la grande se sent, ses retombées non.
var small := false


static func fall(
	parent: Node, point: Vector2, cast: SkillStats, author: StatusEffects, source: Node2D = null,
	shards: PackedScene = null
) -> Meteor:
	var meteor := Meteor.new()
	meteor._cast = cast
	meteor._author = author
	meteor._source = source
	meteor._shards = shards
	meteor._tint = DamageType.COLORS[cast.nature]
	parent.add_child(meteor)
	Settings.veil(meteor, Settings.SPELLS)
	meteor.global_position = point
	return meteor


func _ready() -> void:
	z_index = 4


func _physics_process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _age >= FALL:
		Explosion.of_cast(get_parent(), global_position, _cast, _cast.radius, _author)
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
				get_parent(), _shards, global_position, Vector2.RIGHT, _cast.projectile_speed,
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
		var at := global_position + Vector2.from_angle(TAU * float(i) / float(count)) \
			* _cast.radius * SkillStats.SHOWER_SPREAD
		Meteor.fall(get_parent(), at, fallout, _author, _source).small = true


## La crinière : trois langues plantées sur la boule, pointe vers le ciel — elle
## tombe, donc sa flamme traîne au-dessus d'elle.
func _draw() -> void:
	var landed := clampf(_age / FALL, 0.0, 1.0)
	var shadow_to := SHADOW_TO / 2 if small else SHADOW_TO
	EffectForge.put_scorch(self, SHADOW, roundi(lerpf(SHADOW_FROM, shadow_to, landed)), 1.0, SHADOW_ALPHA)
	var at := Vector2(0.0, -HEIGHT * (1.0 - landed))
	var puffs := EffectForge.puffs(_tint)
	for i in TRAIL - 1 if small else TRAIL:
		EffectForge.put_centered(self, puffs[i], at + Vector2(0.0, -20.0 - TRAIL_STEP * float(i)))
	var frame := int(_age * EffectForge.FLAME_HZ)
	var short := EffectForge.small_flames(_tint)
	var tall := EffectForge.flames(_tint)
	var mane := MANE - 2 if small else MANE
	# Plantées sur le haut de la boule, qui s'arrondit : les langues du bord descendent.
	for k in mane:
		var dx := (float(k) - float(mane - 1) * 0.5) * MANE_STEP
		var sheet: Array = short if small or k % 2 == 1 else tall
		_foot(sheet[(frame + k) % sheet.size()], at + Vector2(dx, (-3.0 if small else -6.0) + absf(dx) * 0.4))
	if small:
		var balls := EffectForge.balls(_tint)
		EffectForge.put_centered(self, balls[int(_age * EffectForge.BALL_HZ) % balls.size()], at)
	else:
		EffectForge.put_centered(self, EffectForge.meteor(_tint), at)


func _foot(tex: Texture2D, at: Vector2) -> void:
	var corner := EffectForge.snap(self, at - Vector2(tex.get_width() * 0.5, tex.get_height() - 1))
	draw_texture_rect(tex, Rect2(corner, Vector2(tex.get_size())), false)
