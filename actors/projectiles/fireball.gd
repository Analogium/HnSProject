class_name Fireball
extends Projectile

## Le tir de Boule de feu. Le trajet et la touche directe sont ceux de
## `Projectile` ; le dessin et l'explosion sont à lui.

## Les bouffées de la traînée, et leur écart en pixels derrière la boule.
const TRAIL := 3
const TRAIL_STEP := 6.0

## Posé par le lanceur depuis le geste résolu : un nœud l'agrandit.
var explosion_radius := 0.0
## Deux hurtbox entrées dans le même pas ne font pas deux explosions.
var _burst := false


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
	var half := Vector2(EffectForge.PUFF_SIZE, EffectForge.PUFF_SIZE) * 0.5
	for i in TRAIL:
		var behind := -_dir * (TRAIL_STEP * float(i + 1))
		_blit(puffs[mini(i, puffs.size() - 1)], behind - half)

	var balls := EffectForge.balls(t)
	var frame := int(_life * EffectForge.BALL_HZ) % balls.size()
	_blit(balls[frame], -Vector2(EffectForge.BALL_SIZE, EffectForge.BALL_SIZE) * 0.5)


func _blit(tex: Texture2D, offset: Vector2) -> void:
	var corner := EffectForge.snap(self, offset)
	draw_texture_rect(tex, Rect2(corner, Vector2(tex.get_width(), tex.get_height())), false)


func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		_explode(area as Hurtbox)
	super(area)


func _on_body_entered(body: Node2D) -> void:
	_explode(null)
	super(body)


func _explode(direct_target: Hurtbox) -> void:
	if _burst:
		return
	_burst = true
	Explosion.put(
		get_parent(), global_position, _parts, explosion_radius, direct_target, tint(), _author, _cast
	)
