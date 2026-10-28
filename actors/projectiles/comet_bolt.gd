class_name CometBolt
extends Projectile

## Le tir du Projectile élémentaire : le trait du joueur dans l'élément du lancer (`BoltFx`, par
## `Projectile._dress()`), **sans zigzag** : un simple projectile (l'utilisateur, jalon 54). Le trajet
## et la touche sont ceux de `Projectile`.


func _dress() -> void:
	super()
	if _bolt_fx != null:
		_bolt_fx.straighten()

