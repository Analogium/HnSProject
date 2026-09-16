class_name Fireball
extends Projectile

## Le tir de Boule de feu. Le trajet et la touche directe sont ceux de
## `Projectile` ; le dessin et l'explosion sont à lui.

## Les langues de flamme qui traînent derrière la boule.
const TONGUES := 3
const LIGHT := Color(1.0, 0.96, 0.7)

## Posé par le lanceur depuis le geste résolu : un nœud l'agrandit.
var explosion_radius := 0.0
## Deux hurtbox entrées dans le même pas ne font pas deux explosions.
var _burst := false


func _draw() -> void:
	var t := tint()
	# Le nœud est déjà tourné sur sa trajectoire : derrière, c'est −x.
	for i in TONGUES:
		var spread := (float(i) - 1.0) * 2.2
		var length := 9.0 + _flicker.randf_range(-2.0, 2.5)
		draw_colored_polygon(PackedVector2Array([
			Vector2(1.0, spread - 2.0), Vector2(1.0, spread + 2.0),
			Vector2(-length, spread * 1.6 + _flicker.randf_range(-0.8, 0.8)),
		]), Color(t, 0.35))
	draw_circle(Vector2.ZERO, 6.5, Color(t, 0.14))
	draw_circle(Vector2(0.5, 0.0), 4.2, Color(t, 0.55))
	draw_circle(Vector2(1.2, 0.0), 2.4, Color(t.lerp(LIGHT, 0.65), 0.85))


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
