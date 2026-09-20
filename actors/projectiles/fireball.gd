class_name Fireball
extends Projectile

## Le tir de Boule de feu. Le trajet et la touche directe sont ceux de
## `Projectile` ; le dessin et l'explosion sont à lui.

## Les langues de flamme qui traînent derrière la boule.
const TONGUES := 3

## Posé par le lanceur depuis le geste résolu : un nœud l'agrandit.
var explosion_radius := 0.0
## Deux hurtbox entrées dans le même pas ne font pas deux explosions.
var _burst := false


func _draw() -> void:
	var t := tint()
	# Le nœud est tourné sur sa trajectoire : derrière, c'est −x. **La seule chose
	# du jeu qui vole**, donc les seules langues qui ne montent pas vers le haut de
	# l'écran : une boule de feu traîne son feu, elle ne le laisse pas monter.
	for i in TONGUES:
		# Le `sway` se compte sur le côté de la langue : couchée vers −x, son côté
		# pointe vers le haut de l'écran, d'où le signe qui écarte l'éventail.
		var spread := (float(i) - 1.0) * 2.4
		Fire.draw_tongue(
			self, Vector2(1.0, spread), Vector2.LEFT, 11.0 + 2.5 * Fire.breath(_life, i),
			2.4, t, 1.0, -spread * 1.2 + 1.2 * Fire.breath(_life * 0.7, i + 4)
		)
	# Le cœur porte la lumière, et lui seul : `Fire.heart` le pose à 0,92 de
	# luminance, quand le blanc local d'avant plafonnait à 0,836 — sous le seuil.
	Glow.draw_blob(self, Vector2.ZERO, 7.5, Color(t, 0.42))
	Glow.draw_blob(self, Vector2(1.2, 0.0), 3.4, Color(Fire.heart(t), 1.0))


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
