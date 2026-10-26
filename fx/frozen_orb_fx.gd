class_name FrozenOrbFx
extends Node3D

## L'Orbe gelée en 3D (jalon 54, « oursin, brume légère » choisi sur planche contre l'oursin seul, la photo
## de l'orbe du Trait en grand — une boule bleue qui luit —, un cœur dans la brume, une sphère hérissée et la
## photo de la brume seule) : huit cristaux des Pics en étoile, qui tournent, devant une brume de givre
## photographiée par Qwen-Image (`fx/frozen_orb_mist.png`) ; la traînée de givre du Trait, élargie ; des
## scintillements qui tournent autour ; une lumière froide. À la fin, l'éclat de fin du Trait, en grand :
## les éclats qui partent sont les vrais tirs de l'orbe, en esquilles des Pics (`IceShardFx`).
##
## Il vit sur l'orbe et part avec elle ; la traînée, à la racine du viewport, lui survit.

## Les cristaux, en px : la portée de l'Orbe mordante (`SkillStats.ORB_REACH`) en est le rayon.
const LENGTH := Vector2(11.0, 16.0)
const WIDTH := Vector2(4.5, 6.5)
## En radians par seconde, autour de la verticale.
const SPIN := 3.0
const TILT := 0.5
const MIST := preload("res://fx/frozen_orb_mist.png")
const MIST_SIZE := 26.0
## Sous le 0,68 du Trait : plus haut, la brume sortait en boule qui luit.
const MIST_LEVEL := 0.5
const MIST_SPIN := 2.0
const TRAIL := 2.4
const GLINTS := 6
const GLINT_ORBIT := 13.0
const LIGHT := 1.6
const FLARE := 2.0

static var _mists := {}

var trail: BoltFx.Trail
var _nature := 0
var _clock := 0.0
var _core: Node3D
var _glints: MultiMeshInstance3D
var _glint_phases: Array[float] = []


## L'oursin de `orb`, dans sa nature.
static func dress(orb: Node3D, nature: int) -> FrozenOrbFx:
	var fx := FrozenOrbFx.new()
	fx._nature = nature
	# Il tourne à l'image ; l'orbe qui le porte, elle, est interpolée par le moteur.
	fx.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	orb.add_child(fx)
	fx.position = Vector3.UP * ElementFx.LIFT
	fx._core = Node3D.new()
	fx.add_child(fx._core)
	var axes: Array[Vector3] = [Vector3.UP, Vector3.DOWN]
	for i in 6:
		var h := TAU * float(i) / 6.0
		axes.append(Vector3(cos(h), randf_range(-0.35, 0.35), sin(h)).normalized())
	for i in axes.size():
		var length := randf_range(LENGTH.x, LENGTH.y)
		var crystal := MeshInstance3D.new()
		crystal.mesh = IceSpikesFx.crystals()[i % IceSpikesFx.SHAPES]
		crystal.material_override = IceSpikesFx.crystal(nature)
		crystal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Pointe dehors, le pied enfoncé dans le cœur.
		crystal.transform = Transform3D(Basis(Quaternion(Vector3.UP, axes[i]))
				* Basis.from_scale(Vector3(randf_range(WIDTH.x, WIDTH.y), length, randf_range(WIDTH.x, WIDTH.y))),
				-axes[i] * length * 0.25)
		fx._core.add_child(crystal)
	var mist := MeshInstance3D.new()
	mist.mesh = _mist(nature)
	mist.scale = Vector3.ONE * MIST_SIZE
	mist.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Derrière les cristaux : triée avec eux, elle passait devant et les grisait.
	mist.sorting_offset = -MIST_SIZE
	fx.add_child(mist)
	fx._glints = IceNovaFx.multimesh(fx, QuadMesh.new(), GLINTS, IceNovaFx.material(IceNovaFx.GLINT, nature), true)
	for i in GLINTS:
		fx._glint_phases.append(randf() * TAU)
	var light := FlameFx.light_of(nature, LIGHT, 60.0)
	light.light_color = FlameFx.ramp(nature)[0]
	fx.add_child(light)
	fx.trail = BoltFx.Trail.new()
	fx.trail.material_override = BoltFx.trail_material(nature)
	fx.trail.width = BoltFx.TRAIL_WIDTH * TRAIL
	fx.trail.target = fx
	orb.get_viewport().add_child(fx.trail)
	for node in fx.find_children("*", "GeometryInstance3D", true, false) + [fx.trail]:
		ElementFx.veil_like(node, orb)
	fx._show()
	return fx


func _process(delta: float) -> void:
	_clock += delta
	_show()


func _show() -> void:
	_core.basis = Basis(Vector3.UP, _clock * SPIN) * Basis(Vector3.RIGHT, TILT)
	for i in GLINTS:
		var h := _clock * 2.0 + TAU * float(i) / float(GLINTS)
		var at := Vector3(cos(h), sin(h * 1.7) * 0.5, sin(h)) * GLINT_ORBIT
		_glints.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * 5.0), at))
		IceNovaFx.shine(_glints, i, IceNovaFx.twinkle(_clock, _glint_phases[i], 7.0, 4.0))


## La brume d'une nature, gardée.
static func _mist(nature: int) -> QuadMesh:
	if not _mists.has(nature):
		var m := BoltFx.ramped(BoltFx.FROST, MIST, nature)
		m.set_shader_parameter(&"spin", MIST_SPIN)
		m.set_shader_parameter(&"level", MIST_LEVEL)
		var quad := QuadMesh.new()
		quad.material = m
		_mists[nature] = quad
	return _mists[nature]


## L'orbe éclate : l'éclat de fin du Trait, en grand. **Différé** : un mur l'éclate d'un pas de physique.
func flare() -> void:
	BoltFx.flare_at.call_deferred(get_viewport(), global_position, get_parent(), _nature, FLARE)
