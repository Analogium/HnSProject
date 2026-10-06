class_name Fireball
extends Projectile

## Le tir de Boule de feu. Le trajet et la touche directe sont ceux de
## `Projectile` ; le dessin et l'explosion sont à lui.

const SCENE := "res://actors/projectiles/player_fireball.tscn"
## Les bouffées de la traînée, et leur écart en pixels derrière la boule.
const TRAIL := 3
const TRAIL_STEP := 6.0

## Posé par le lanceur depuis le geste résolu : un nœud l'agrandit.
var explosion_radius := 0.0
## Un éclat de Fragmentation : la mini-boule et deux bouffées, pas la boule entière —
## sinon on ne distingue pas les éclats de la boule qui les a lâchés.
var is_shard := false
## Deux hurtbox entrées dans le même pas ne font pas deux explosions ; une boule qui
## traverse en fait une par cible, à des pas différents.
var _burst_frame := -1
## Le Gonflement (jalon 42) : sa propre forme de touche, que la boule agrandit en volant —
## celle de la scène est partagée par toutes les boules (invariant 2).
var _hit_shape: CircleShape2D
var _hit_radius := 0.0


## Une étincelle lancée par ce qui n'a pas de corps à états : le crachat du serpent, les
## escarbilles de l'Immolation, les boules du Brasero. La petite boule des éclats, sans gel — ce qui dure ne fige
## jamais —, l'auteur posé à la main. Chargée à l'appel : la scène porte ce script.
## `burst` à faux : pas d'explosion, la touche directe seule — les boules du Brasero.
static func spark(
	parent: Node, from: Vector2, toward: Vector2, cast: SkillStats, author: StatusEffects,
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


func _ready() -> void:
	super()
	# **Une planche cernée ne peut pas être additive** : son contour sombre n'y
	# ajoute rien, il disparaît, et avec lui ce qui la rattache au décor.
	material = null


## **La boule ne tourne pas.** `Projectile` aligne son nœud sur la trajectoire, ce
## qui convient à un tracé et jamais à une planche : pivotée, elle se
## rééchantillonne et ses pixels se brisent. Une boule n'a pas d'orientation, et sa
## traînée se place à la main.
func setup(
	dir: Vector2, parts: Array[float], source: Node2D, p_speed := 0.0, nature := -1
) -> void:
	super(dir, parts, source, p_speed, nature)
	rotation = 0.0


func _draw() -> void:
	var t := tint()
	var puffs := EffectForge.puffs(t)
	if is_shard:
		EffectForge.put_centered(self, puffs[1], -_dir * 5.0)
		EffectForge.put_centered(self, puffs[2], -_dir * 9.0)
		EffectForge.put_centered(self, EffectForge.shard(t), Vector2.ZERO)
		return
	# Gonflée, la boule est fabriquée à sa taille, impaire, et sa traînée recule d'autant.
	var side := 2 * floori(EffectForge.BALL_SIZE * 0.5 * size()) + 1
	var behind := float(side - EffectForge.BALL_SIZE) * 0.5
	for i in TRAIL:
		EffectForge.put_centered(
			self, puffs[mini(i, puffs.size() - 1)], -_dir * (behind + TRAIL_STEP * float(i + 1))
		)

	var balls := EffectForge.balls(t) if side <= EffectForge.BALL_SIZE else EffectForge.grown_balls(t, side)
	EffectForge.put_centered(self, balls[int(_life * EffectForge.BALL_HZ) % balls.size()], Vector2.ZERO)


func _physics_process(delta: float) -> void:
	super(delta)
	if _cast == null or _cast.girth <= 0.0:
		return
	if _hit_shape == null:
		var holder := get_node("CollisionShape2D") as CollisionShape2D
		_hit_shape = holder.shape.duplicate()
		holder.shape = _hit_shape
		_hit_radius = _hit_shape.radius
	_hit_shape.radius = _hit_radius * size()


## Sa taille, en multiple de la sienne : un sous le Gonflement, plafonnée à `GIRTH_MOST`.
func size() -> float:
	if _cast == null or _cast.girth <= 0.0:
		return 1.0
	return minf(1.0 + _cast.girth * 0.01 * speed * _life / SkillStats.SWELL_STEP, SkillStats.GIRTH_MOST)


func _on_area_entered(area: Area2D) -> void:
	if strikes(area):
		_explode(area as Hurtbox)
	super(area)


func _on_body_entered(body: Node2D) -> void:
	_explode(null)
	super(body)


func _explode(direct_target: Hurtbox) -> void:
	if explosion_radius <= 0.0 or _burst_frame == Engine.get_physics_frames():
		return
	_burst_frame = Engine.get_physics_frames()
	var parts: Array[float] = _parts.duplicate()
	var radius := explosion_radius
	# La Prise d'air (jalon 42) : plus la boule a volé, plus elle éclate fort et large.
	if _cast != null and _cast.swell > 0.0:
		var gain := 1.0 + _cast.swell * 0.01 * speed * _life / SkillStats.SWELL_STEP
		for i in parts.size():
			parts[i] *= gain
		radius *= gain
	Explosion.put(get_parent(), global_position, parts, radius, direct_target, tint(), _author, _cast)
