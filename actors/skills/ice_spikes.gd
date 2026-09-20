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
## Les deux bouts de la vie d'un pic : le temps qu'il met à percer, et celui qu'il
## met à **redescendre**. Il ne s'efface pas — un cristal à demi-transparent sur un
## sol sombre sort gris.
const RISE := 0.25
const SINK := 0.3
const SPIKES := 7

var _cast: SkillStats
var _author: StatusEffects
var _tint := Color.WHITE
var _age := 0.0
var _has_struck := false
## Les pieds dans le disque unité : le rayon change avec les nœuds, pas la
## répartition.
var _feet := PackedVector2Array()


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


## Pas de `ArtPalette.ADDITIVE` ici : les cristaux sont **dessinés**, et une
## planche cernée ne peut pas être additive — son contour sombre n'y ajoute rien.
func _ready() -> void:
	z_index = 3
	var rng := RandomNumberGenerator.new()
	rng.seed = int(get_instance_id())
	for i in SPIKES:
		var angle := TAU * float(i) / float(SPIKES) + rng.randf_range(-0.3, 0.3)
		# La racine carrée répartit à surface égale : sans elle, tout se tasse au
		# centre et le cercle qui mord ne se lit pas.
		_feet.append(Vector2.from_angle(angle) * sqrt(rng.randf_range(0.1, 1.0)))


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


## Des cristaux debout, pointe en haut : un pic vu de dessus en vue plongeante monte
## vers le ciel, comme les flammes d'Immolation.
##
## Un grand, un petit, alternés : sept pics de la même taille font une palissade —
## la leçon de la Ruée ardente, où le défaut n'était pas le nombre mais la
## régularité.
##
## Seul le givre au sol s'efface ; les cristaux, eux, **rentrent sous terre**.
func _draw() -> void:
	# Une seule valeur pour la fin du geste : les cristaux rentrent sous terre et le
	# givre s'efface au même rythme, sinon l'un survit à l'autre.
	var ending := clampf((LIFETIME - _age) / (LIFETIME * SINK), 0.0, 1.0)
	var out := minf(clampf(_age / (LIFETIME * RISE), 0.0, 1.0), ending)
	var radius := maxi(int(round(_cast.radius)), 1)
	# Le givre au sol dit où ça mord, et il est tramé : un anneau tracé est la
	# dernière chose qui trahit le vecteur au milieu d'un décor en pixels.
	draw_texture_rect(
		EffectForge.scorch(_tint, radius),
		Rect2(
			EffectForge.snap(self, -Vector2(radius, radius)),
			Vector2.ONE * float(radius * 2 + 1)
		),
		false, Color(1.0, 1.0, 1.0, ending)
	)
	for i in _feet.size():
		Frost.raise_spike(self, _feet[i] * _cast.radius, i % 2 == 0, out, _tint)
