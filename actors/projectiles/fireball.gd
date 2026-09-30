class_name Fireball
extends Projectile

## Le tir de Boule de feu. Le trajet et la touche directe sont ceux de
## `Projectile` ; le dessin et l'explosion sont à lui.

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
	for i in TRAIL:
		EffectForge.put_centered(self, puffs[mini(i, puffs.size() - 1)], -_dir * (TRAIL_STEP * float(i + 1)))

	var balls := EffectForge.balls(t)
	EffectForge.put_centered(self, balls[int(_life * EffectForge.BALL_HZ) % balls.size()], Vector2.ZERO)


func _on_area_entered(area: Area2D) -> void:
	if strikes(area):
		_explode(area as Hurtbox)
	super(area)


func _on_body_entered(body: Node2D) -> void:
	_explode(null)
	super(body)


func _explode(direct_target: Hurtbox) -> void:
	if _burst_frame == Engine.get_physics_frames():
		return
	_burst_frame = Engine.get_physics_frames()
	burst(get_parent(), global_position, _parts, explosion_radius, direct_target, tint(), _author, _cast)


## **L'éclatement de la boule**, où qu'elle éclate : en vol ou tombée du ciel (le
## Météore). L'explosion, puis le sol brûlant qu'un nœud lui fait laisser.
static func burst(
	parent: Node, at: Vector2, parts: Array[float], radius: float, excluded: Hurtbox,
	tint_of: Color, author: StatusEffects, cast: SkillStats
) -> void:
	Explosion.put(parent, at, parts, radius, excluded, tint_of, author, cast)
	if cast != null and cast.ground_duration > 0.0:
		DashTrail.patch(parent, at, cast.ground(), author)
