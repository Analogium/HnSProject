class_name IceSpikes
extends Node2D

## Les pics de glace : ils percent le sol au point visé, frappent **une fois** ce qui
## est dans leur cercle, puis retombent. Rien ne reste — c'est ce qui les sépare du
## vortex, qui dure.
##
## Ils frappent à leur première image de physique et non à la pose : le lancer peut
## venir d'un rappel de collision, où l'espace physique refuse les requêtes
## (invariant 4).

const LIFETIME := 0.45
## La part de sa vie que le pic met à sortir ; il reste dressé, puis s'efface.
const RISE := 0.25
## Ce qui les distingue d'un cercle de traits : chacun a sa hauteur et son angle.
const SPIKES := 7
const HEIGHT := 18.0

class Spike:
	## Dans le disque unité : le rayon change avec les nœuds, pas la répartition.
	var foot: Vector2
	var height: float
	var half_width: float


var _cast: SkillStats
var _author: StatusEffects
var _tint := Color.WHITE
var _age := 0.0
var _has_struck := false
var _spikes: Array[Spike] = []


static func raise_at(
	parent: Node, point: Vector2, cast: SkillStats, author: StatusEffects
) -> IceSpikes:
	var spikes := IceSpikes.new()
	spikes._cast = cast
	spikes._author = author
	spikes._tint = DamageType.COLORS[cast.dominant_nature()]
	parent.add_child(spikes)
	spikes.global_position = point
	return spikes


func _ready() -> void:
	z_index = 3
	material = ArtPalette.ADDITIVE
	var rng := RandomNumberGenerator.new()
	rng.seed = int(get_instance_id())
	for i in SPIKES:
		var spike := Spike.new()
		var angle := TAU * float(i) / float(SPIKES) + rng.randf_range(-0.3, 0.3)
		var tall := rng.randf_range(0.6, 1.0)
		spike.foot = Vector2.from_angle(angle) * sqrt(rng.randf_range(0.1, 1.0))
		spike.height = HEIGHT * tall
		spike.half_width = 1.4 + tall
		_spikes.append(spike)


func _physics_process(delta: float) -> void:
	if not _has_struck:
		_has_struck = true
		var parts := _cast.roll(Game.rng)
		for target in Targets.in_circle(get_world_2d(), global_position, _cast.radius):
			Targets.strike(target, parts, global_position, _author, _cast)
	_age += delta
	queue_redraw()
	if _age >= LIFETIME:
		queue_free()


## Des triangles debout, pointe en haut : un pic vu de dessus en vue plongeante monte
## vers le ciel, comme les flammes d'Immolation.
func _draw() -> void:
	var out := clampf(_age / (LIFETIME * RISE), 0.0, 1.0)
	var fade := clampf((LIFETIME - _age) / (LIFETIME * 0.4), 0.0, 1.0)
	var light_color := _tint.lerp(Color.WHITE, 0.55)
	Glow.draw_ring(self, Vector2.ZERO, _cast.radius, Color(_tint, 0.32 * fade))
	for spike in _spikes:
		var foot := spike.foot * _cast.radius
		var height := spike.height * out
		var half := spike.half_width
		draw_colored_polygon(PackedVector2Array([
			foot + Vector2(-half, 0.0),
			foot + Vector2(half, 0.0),
			foot + Vector2(0.0, -height),
		]), Color(_tint, 0.70 * fade))
		# L'arête claire sur un seul bord : sans elle, un triangle plat n'a pas de facette.
		draw_line(
			foot + Vector2(-half * 0.4, 0.0), foot + Vector2(0.0, -height),
			Color(light_color, 0.9 * fade), 1.0
		)
