class_name StunMark
extends Node3D

## L'assommé de la Retombée (jalon 46), choisi sur planche contre une spirale, un anneau de
## points, des oiseaux, une étoile qui palpite et deux étincelles : trois étoiles d'or qui
## tournent autour du haut de la tête. En 3D (jalon 54), les étoiles de la Nova
## (`fx/frost_glint.gdshader`) en or ; la perspective les rapetisse quand elles passent derrière.
## Un seul par ennemi : assommé de nouveau, il dure le plus long des deux temps.

const STARS := 3
## En pixels : le rayon du tour, sa hauteur au-dessus de la tête, la taille d'une étoile.
const ORBIT := 7.0
const ABOVE := 4.0
const SIZE := 6.0
## En radians par seconde.
const SPIN := 5.0
const GOLD := Color(1.0, 0.82, 0.3)

static var _material: ShaderMaterial

var _left := 0.0
var _clock := 0.0
var _head := 0.0
var _stars: MultiMeshInstance3D


static func over(enemy: Enemy, seconds: float) -> void:
	var mark: StunMark = null
	for child in enemy.get_children():
		if child is StunMark:
			mark = child
	if mark == null:
		mark = StunMark.new()
		mark._head = LightningRod.head_of(enemy.hurtbox)
		enemy.add_child(mark)
		mark._stars = IceNovaFx.multimesh(mark, QuadMesh.new(), STARS, _gold(), true)
		for i in STARS:
			IceNovaFx.shine(mark._stars, i, 1.0)
		mark._turn()
	mark._left = maxf(mark._left, seconds)


func _physics_process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()


func _process(delta: float) -> void:
	_clock += delta
	_turn()


## L'étoile `i` à cet instant ; publique pour les tests, le moteur sans rendu ne relit pas un `MultiMesh`.
func star(i: int) -> Transform3D:
	var a := _clock * SPIN + TAU * float(i) / float(STARS)
	return Transform3D(Basis.from_scale(Vector3.ONE * SIZE), Vector3(cos(a) * ORBIT, _head + ABOVE, sin(a) * ORBIT))


func _turn() -> void:
	for i in STARS:
		_stars.multimesh.set_instance_transform(i, star(i))


static func _gold() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = IceNovaFx.GLINT
		_material.set_shader_parameter(&"rime", Vector3(GOLD.r, GOLD.g, GOLD.b))
	return _material
