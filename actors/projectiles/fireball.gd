class_name Fireball
extends Projectile

## Le tir de Boule de feu. Le trajet et la touche directe sont ceux de
## `Projectile` ; le dessin (`FlameFx`) et l'explosion sont à lui.

const SCENE := "res://actors/projectiles/player_fireball.tscn"
## Posé par le lanceur depuis le geste résolu : un nœud l'agrandit.
var explosion_radius := 0.0
## Un éclat de Fragmentation : la mini-boule et deux bouffées, pas la boule entière —
## sinon on ne distingue pas les éclats de la boule qui les a lâchés.
var is_shard := false:
	set(value):
		if value and not is_shard and _flame != null:
			_flame.as_shard()
		is_shard = value
## Deux hurtbox entrées dans le même pas ne font pas deux explosions ; une boule qui
## traverse en fait une par cible, à des pas différents.
var _burst_frame := -1
## Le Gonflement (jalon 42) : sa propre forme de touche, que la boule agrandit en volant —
## celle de la scène est partagée par toutes les boules (invariant 2).
var _hit_shape: SphereShape3D
var _hit_radius := 0.0
var _flame: FlameFx


## Une étincelle lancée par ce qui n'a pas de corps à états : le crachat du serpent, les
## escarbilles de l'Immolation, les boules du Brasero. La petite boule des éclats, sans gel — ce qui dure ne fige
## jamais —, l'auteur posé à la main. Chargée à l'appel : la scène porte ce script.
## `burst` à faux : pas d'explosion, la touche directe seule — les boules du Brasero.
static func spark(
	parent: Node, from: Vector3, toward: Vector3, cast: SkillStats, author: StatusEffects,
	burst := true
) -> Fireball:
	var ball := Projectile.spawn(
		parent, load(SCENE), from, toward, cast.roll(Game.rng), null, cast.projectile_speed,
		cast.nature, cast
	) as Fireball
	ball.is_shard = true
	ball.explosion_radius = SkillStats.SPARK_RADIUS if burst else 0.0
	ball.hit_stop_on_impact = false
	ball._author = author
	return ball


func _physics_process(delta: float) -> void:
	super(delta)
	if _cast == null or _cast.girth <= 0.0:
		return
	if _hit_shape == null:
		var holder := get_node("CollisionShape3D") as CollisionShape3D
		_hit_shape = holder.shape.duplicate()
		holder.shape = _hit_shape
		_hit_radius = _hit_shape.radius
	_hit_shape.radius = _hit_radius * size()
	_flame.core.scale = Vector3.ONE * size() * (FlameFx.SHARD if is_shard else 1.0)


## Son voile, puis son feu, à la place des étincelles génériques.
func _show(group: StringName) -> void:
	Settings.veil(self, group)
	_flame = FlameFx.ball(self, nature())


## Sa taille, en multiple de la sienne : un sous le Gonflement, plafonnée à `GIRTH_MOST`.
func size() -> float:
	if _cast == null or _cast.girth <= 0.0:
		return 1.0
	return minf(1.0 + _cast.girth * 0.01 * speed * _life / SkillStats.SWELL_STEP, SkillStats.GIRTH_MOST)


func _on_area_entered(area: Area3D) -> void:
	if strikes(area):
		_explode(area as Hurtbox)
	super(area)


func _on_body_entered(body: Node3D) -> void:
	_explode(null)
	super(body)


func _explode(direct_target: Hurtbox) -> void:
	if explosion_radius <= 0.0 or _burst_frame == Engine.get_physics_frames():
		return
	_burst_frame = Engine.get_physics_frames()
	var parts := _parts
	var radius := explosion_radius
	# La Prise d'air (jalon 42) : plus la boule a volé, plus elle éclate fort et large.
	if _cast != null and _cast.swell > 0.0:
		var gain := 1.0 + _cast.swell * 0.01 * speed * _life / SkillStats.SWELL_STEP
		parts = DamageType.scaled(parts, gain)
		radius *= gain
	Explosion.put(get_parent(), global_position, parts, radius, direct_target, tint(), _author, _cast).flames = true
