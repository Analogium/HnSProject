class_name ElementFx
extends GPUParticles3D

## Le visuel générique d'une compétence en 3D (jalon 54, étape 4) : des étincelles à la
## couleur de sa nature, choisies sur planche contre une lumière pleine, un mélange et des
## aplats. **Toute compétence sans dessin propre le montre**, par sa famille : la traînée d'un
## projectile, la gerbe d'un éclatement, le balayage d'un coup, le disque d'une zone qui dure,
## le semis d'un trait.
##
## L'émetteur vit **à la racine du viewport de son porteur** — son monde, hors des conteneurs
## que le jeu compte (les tirs, les effets) — et le suit : un projectile qui touche se
## libère, sa traînée finit de retomber au lieu de disparaître avec lui.

const MATERIAL := preload("res://fx/element_spark.gdshader")
## La hauteur où vole un projectile et où passe une lame, en pixels du monde.
const LIFT := 10.0
## Au-dessus de 1, le tonemapping blanchit la couleur : les trois natures ne se distinguaient
## plus sur la planche. Le départ tire un quart vers le blanc, la fin s'éteint dans la nature.
const WHITE_START := 0.25
const SPARK := 7.0

const TRAIL_LIFE := 0.35
const BURST_LIFE := 0.45
const SWEEP_LIFE := 0.3
const AREA_LIFE := 0.6
## Le balayage d'un coup, de part et d'autre de la visée, en radians.
const SWEEP_HALF := 1.1

static var _draw: QuadMesh
static var _materials := {}

var _host: Node3D
var _offset := Vector3.ZERO
## Le balayage : son rayon, sa durée et où il en est (0 → 1).
var _sweep_radius := 0.0
var _sweep_time := 0.0
var _sweep_t := -1.0


## La traînée d'un projectile, tant qu'il vit.
static func trail(host: Node3D, tint: Color) -> ElementFx:
	var fx := _make(host, tint, TRAIL_LIFE, 48, 180.0, 12.0)
	fx._follow(host, Vector3.UP * LIFT)
	return fx


## La gerbe d'un éclatement de rayon `radius`, posée en `at` ; elle se libère seule.
static func burst(host: Node3D, at: Vector3, tint: Color, radius: float) -> ElementFx:
	var fx := _make(host, tint, BURST_LIFE, clampi(int(radius * 2.0), 24, 128), 180.0, radius * 2.4)
	fx.one_shot = true
	fx.explosiveness = 1.0
	host.get_viewport().add_child(fx)
	fx.global_position = at + Vector3.UP * SPARK
	# Et non `finished`, que les particules n'émettent pas sans rendu (en headless).
	fx.get_tree().create_timer(fx.lifetime).timeout.connect(fx.queue_free)
	return fx


## Le balayage d'un coup : l'émetteur parcourt l'arc devant `host` (son x local est la
## visée) en `duration` secondes, au rayon `radius`.
static func sweep(host: Node3D, tint: Color, radius: float, duration: float) -> ElementFx:
	var fx := _make(host, tint, SWEEP_LIFE, 32, 30.0, 30.0)
	fx._sweep_radius = radius
	fx._sweep_time = maxf(duration, 0.01)
	fx._sweep_t = 0.0
	fx._follow(host, Vector3.UP * LIFT)
	return fx


## Le disque d'une zone de rayon `radius` qui dure tant que `host` vit : les étincelles
## montent du sol.
static func area(host: Node3D, tint: Color, radius: float) -> ElementFx:
	var fx := _make(host, tint, AREA_LIFE, clampi(int(radius * 1.2), 12, 96), 15.0, 18.0, radius)
	fx._follow(host, Vector3.UP * 2.0)
	return fx


## Un trait de `from` à `to` (une chaîne, un sillon) : des étincelles semées tout du long, une fois.
static func line(host: Node3D, from: Vector3, to: Vector3, tint: Color) -> ElementFx:
	var length := from.distance_to(to)
	var fx := _make(host, tint, BURST_LIFE, clampi(int(length / 3.0), 8, 96), 180.0, 15.0, 0.0, length)
	fx.one_shot = true
	fx.explosiveness = 1.0
	host.get_viewport().add_child(fx)
	fx.global_position = (from + to) * 0.5 + Vector3.UP * LIFT
	if length > 0.01:
		fx.global_basis = Basis(Vector3.UP, -Flat.angle(to - from))
	fx.get_tree().create_timer(fx.lifetime).timeout.connect(fx.queue_free)
	return fx


static func _make(
	host: Node3D, tint: Color, life: float, count: int, spread: float, speed: float, ring := 0.0, length := 0.0
) -> ElementFx:
	var fx := ElementFx.new()
	fx.amount = count
	fx.lifetime = life
	fx.local_coords = false
	# Par défaut, elles naissent à 30 images par seconde : un tir rapide laissait des perles.
	fx.fixed_fps = 0
	fx.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fx.process_material = _process_material(tint, spread, speed, ring, length)
	if _draw == null:
		_draw = QuadMesh.new()
		_draw.size = Vector2.ONE * SPARK
		var m := ShaderMaterial.new()
		m.shader = MATERIAL
		_draw.material = m
	fx.draw_pass_1 = _draw
	# Le voile du porteur : sort ou attaque ennemie, réglé dans les options.
	for group in [Settings.SPELLS, Settings.ENEMY_ATTACKS]:
		if host.is_in_group(group):
			Settings.veil(fx, group)
	return fx


## Une par nature, mouvement et forme (`ring` : un disque de ce rayon ; `length` : un trait),
## gardée : fabriquée à chaque tir, sa rampe partait au GPU à chaque fois.
static func _process_material(
	tint: Color, spread: float, speed: float, ring: float, length: float
) -> ParticleProcessMaterial:
	var key := "%s %s %s %d %d" % [tint.to_html(), spread, speed, roundi(ring), roundi(length)]
	if _materials.has(key):
		return _materials[key]
	var pm := ParticleProcessMaterial.new()
	pm.gravity = Vector3.ZERO
	pm.direction = Vector3.UP
	pm.spread = spread
	if ring > 0.0:
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
		pm.emission_ring_axis = Vector3.UP
		pm.emission_ring_radius = ring
		pm.emission_ring_inner_radius = 0.0
		pm.emission_ring_height = 1.0
	elif length > 0.0:
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(length * 0.5, 1.0, 1.0)
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	pm.initial_velocity_min = speed * 0.5
	pm.initial_velocity_max = speed
	pm.damping_min = speed
	pm.damping_max = speed * 1.5
	var ramp := Gradient.new()
	ramp.set_color(0, tint.lerp(Color.WHITE, WHITE_START))
	ramp.set_color(1, Color(tint, 0.0))
	var texture := GradientTexture1D.new()
	texture.gradient = ramp
	pm.color_ramp = texture
	_materials[key] = pm
	return pm


func _follow(host: Node3D, offset: Vector3) -> void:
	_host = host
	_offset = offset
	host.get_viewport().add_child(self)
	_place()


func _process(delta: float) -> void:
	if not emitting:
		return
	# `== null` ne voit pas un porteur libéré : il resterait suivi à jamais.
	if not is_instance_valid(_host) or not _host.is_inside_tree():
		_let_go()
		return
	if _sweep_t >= 0.0:
		_sweep_t += delta / _sweep_time
		if _sweep_t >= 1.0:
			_let_go()
			return
	_place()


func _place() -> void:
	var at := _host.global_position
	if _sweep_t >= 0.0:
		var a := lerpf(-SWEEP_HALF, SWEEP_HALF, _sweep_t)
		at = _host.global_transform * (Vector3(cos(a), 0.0, sin(a)) * _sweep_radius)
	global_position = at + _offset


## Le porteur parti ou le coup fini : plus rien ne naît, ce qui vole retombe, puis rien.
func _let_go() -> void:
	emitting = false
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
