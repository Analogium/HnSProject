class_name CometBolt
extends Projectile

## Le tir du Projectile élémentaire : une comète dessinée (`Comet`), dans la teinte de
## l'élément du lancer. Le trajet et la touche sont ceux de `Projectile`.


## Une planche cernée ne peut pas être additive : son contour sombre n'y ajoute rien.
func _ready() -> void:
	super()
	material = null


## **La comète ne tourne pas** : elle est fabriquée au cap, une planche pivotée se
## rééchantillonnerait.
func setup(
	dir: Vector2, parts: Array[float], source: Node2D, p_speed := 0.0, nature := -1
) -> void:
	super(dir, parts, source, p_speed, nature)
	rotation = 0.0


func _draw() -> void:
	var form := int(_life * Comet.HZ) + int(get_instance_id())
	Comet.piece(tint(), Slash.turn_of(_dir.angle()), form).put(self, Vector2.ZERO)
