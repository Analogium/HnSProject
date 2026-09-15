class_name BouleDeFeu
extends Projectile

## Le tir de Boule de feu. Le trajet et la touche directe sont ceux de
## `Projectile` ; le dessin et l'explosion sont à lui.

## Les langues de flamme qui traînent derrière la boule.
const LANGUES := 3
const CLAIR := Color(1.0, 0.96, 0.7)

## Posé par le lanceur depuis le geste résolu : un nœud l'agrandit.
var rayon_d_explosion := 0.0
## Deux hurtbox entrées dans le même pas ne font pas deux explosions.
var _eclatee := false


func _draw() -> void:
	var t := teinte()
	# Le nœud est déjà tourné sur sa trajectoire : derrière, c'est −x.
	for i in LANGUES:
		var ecart := (float(i) - 1.0) * 2.2
		var longueur := 9.0 + _scintille.randf_range(-2.0, 2.5)
		draw_colored_polygon(PackedVector2Array([
			Vector2(1.0, ecart - 2.0), Vector2(1.0, ecart + 2.0),
			Vector2(-longueur, ecart * 1.6 + _scintille.randf_range(-0.8, 0.8)),
		]), Color(t, 0.35))
	draw_circle(Vector2.ZERO, 6.5, Color(t, 0.14))
	draw_circle(Vector2(0.5, 0.0), 4.2, Color(t, 0.55))
	draw_circle(Vector2(1.2, 0.0), 2.4, Color(t.lerp(CLAIR, 0.65), 0.85))


func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		_eclater(area as Hurtbox)
	super(area)


func _on_body_entered(body: Node2D) -> void:
	_eclater(null)
	super(body)


func _eclater(cible_directe: Hurtbox) -> void:
	if _eclatee:
		return
	_eclatee = true
	Explosion.poser(get_parent(), global_position, _parts, rayon_d_explosion, cible_directe, teinte(), _auteur)
