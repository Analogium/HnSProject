class_name StunMark
extends Node2D

## L'assommé de la Retombée (jalon 46), choisi sur planche contre une spirale, un anneau de
## points, des oiseaux, une étoile qui palpite et deux étincelles : trois étoiles d'or qui
## tournent en ellipse autour du haut de la tête, plus petites quand elles passent derrière.
## Un seul par ennemi : assommé de nouveau, il dure le plus long des deux temps.

const COUNT := 3
const SPIN := 5.0
const RX := 9.0
const RY := 3.0

var _age := 0.0
var _left := 0.0


static func over(enemy: Enemy, seconds: float) -> void:
	var mark: StunMark = null
	for child in enemy.get_children():
		if child is StunMark:
			mark = child
	if mark == null:
		mark = StunMark.new()
		mark.position.y = SpriteForge.top(enemy.sprite.archetype)
		enemy.add_child(mark)
	mark._left = maxf(mark._left, seconds)


func _ready() -> void:
	z_index = 3


func _physics_process(delta: float) -> void:
	_age += delta
	_left -= delta
	if _left <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var stars := EffectForge.stun_stars()
	for i in COUNT:
		var angle := _age * SPIN + TAU * float(i) / float(COUNT)
		var behind := sin(angle) < 0.0
		EffectForge.put_centered(
			self, stars[1 if behind else 0], Vector2(cos(angle) * RX, sin(angle) * RY)
		)
