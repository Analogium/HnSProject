class_name Meteor
extends Node2D

## La Boule de feu devenue Météore (jalon 34, « crinière » choisie sur planche) : elle
## tombe droit du ciel sur le point visé et y éclate **comme la boule** — même
## explosion, même sol brûlant (`Fireball.burst()`). Son ombre grandit au sol : c'est
## elle qui dit où.

## D'où elle tombe, en pixels, et en combien de temps. Assez pour se voir venir, pas
## assez pour qu'un ennemi sorte du cercle en marchant.
const HEIGHT := 70.0
const FALL := 0.45
## Les bouffées au-dessus de la crinière, et leur écart.
const TRAIL := 3
const TRAIL_STEP := 6.0
## L'ombre, du point de départ à l'impact.
const SHADOW_FROM := 4
const SHADOW_TO := 12
const SHADOW := Color(0.06, 0.03, 0.02)
## Au réglage d'une aura, l'ombre disparaissait sur la terre sombre (vu à la capture).
const SHADOW_ALPHA := 0.6
## L'écart entre deux météores d'une rangée : leurs explosions se touchent sans se couvrir.
const SPACING := 28.0

var _cast: SkillStats
var _author: StatusEffects
## Le lanceur et la boule dont sortent les éclats de Fragmentation.
var _source: Node2D
var _shards: PackedScene
var _tint := Color.WHITE
var _age := 0.0


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
		Fireball.burst(
			get_parent(), global_position, _cast.roll(Game.rng), _cast.radius, null, _tint, _author, _cast
		)
		# Fragmentation : l'étoile d'éclats part du point d'impact.
		if _cast.splits > 0.0 and _shards != null:
			Projectile.split(
				get_parent(), _shards, global_position, Vector2.RIGHT, _cast.projectile_speed,
				_cast.nature, _source, _cast.shard(), int(_cast.splits), {}
			)
		queue_free()


## La crinière : trois langues plantées sur la boule, pointe vers le ciel — elle
## tombe, donc sa flamme traîne au-dessus d'elle.
func _draw() -> void:
	var landed := clampf(_age / FALL, 0.0, 1.0)
	EffectForge.put_scorch(self, SHADOW, roundi(lerpf(SHADOW_FROM, SHADOW_TO, landed)), 1.0, SHADOW_ALPHA)
	var at := Vector2(0.0, -HEIGHT * (1.0 - landed))
	var puffs := EffectForge.puffs(_tint)
	for i in TRAIL:
		EffectForge.put_centered(self, puffs[i], at + Vector2(0.0, -12.0 - TRAIL_STEP * float(i)))
	var frame := int(_age * EffectForge.FLAME_HZ)
	var short := EffectForge.small_flames(_tint)
	var tall := EffectForge.flames(_tint)
	_foot(short[frame % short.size()], at + Vector2(-5.0, -2.0))
	_foot(short[(frame + 1) % short.size()], at + Vector2(5.0, -2.0))
	_foot(tall[frame % tall.size()], at + Vector2(0.0, -3.0))
	var balls := EffectForge.balls(_tint)
	EffectForge.put_centered(self, balls[int(_age * EffectForge.BALL_HZ) % balls.size()], at)


func _foot(tex: Texture2D, at: Vector2) -> void:
	var corner := EffectForge.snap(self, at - Vector2(tex.get_width() * 0.5, tex.get_height() - 1))
	draw_texture_rect(tex, Rect2(corner, Vector2(tex.get_size())), false)
