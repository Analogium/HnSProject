class_name StunMark
extends Node3D

## L'assommé de la Retombée (jalon 46), choisi sur planche contre une spirale, un anneau de
## points, des oiseaux, une étoile qui palpite et deux étincelles : trois étoiles d'or qui
## tournent en ellipse autour du haut de la tête, plus petites quand elles passent derrière.
## Un seul par ennemi : assommé de nouveau, il dure le plus long des deux temps.

var _left := 0.0


static func over(enemy: Enemy, seconds: float) -> void:
	var mark: StunMark = null
	for child in enemy.get_children():
		if child is StunMark:
			mark = child
	if mark == null:
		mark = StunMark.new()
		enemy.add_child(mark)
	mark._left = maxf(mark._left, seconds)


func _physics_process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()

