class_name ElementFx
extends GPUParticles3D

## Le visuel générique d'une compétence en 3D (jalon 54, étape 4) : des étincelles à la
## couleur de sa nature, choisies sur planche contre une lumière pleine, un mélange et des
## aplats. **Toute compétence sans dessin propre le montre**, par sa famille : la traînée d'un
## projectile, la gerbe d'un éclatement, le disque d'une zone qui dure, le semis d'un trait.
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
const AREA_LIFE := 0.6

static var _draw: QuadMesh
static var _materials := {}
static var _warmed := false

var _host: Node3D
var _offset := Vector3.ZERO


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


## Le disque d'une zone de rayon `radius` qui dure tant que `host` vit : les étincelles
## montent du sol.
static func area(host: Node3D, tint: Color, radius: float) -> ElementFx:
	var fx := _make(host, tint, AREA_LIFE, clampi(int(radius * 1.2), 12, 96), 15.0, 18.0, radius)
	fx._follow(host, Vector3.UP * 2.0)
	return fx


## Le disque d'une aura dont la nature ou le rayon changent en route (l'immolation qui monte,
## un nœud pris en cours) : `fx` créé à la première demande, puis repris. La matière change,
## pas le nombre d'étincelles — le changer relance l'émetteur.
static func keep(fx: ElementFx, host: Node3D, tint: Color, radius: float) -> ElementFx:
	if not is_instance_valid(fx) or not fx.emitting:
		return area(host, tint, radius)
	fx.process_material = _process_material(tint, 15.0, 18.0, radius, 0.0)
	return fx


## Une fois par partie, chaque famille paraît, invisible, sous `host` : la première apparition
## d'une matière se compile en ~100 ms (étincelles 89, boule de feu 105, son explosion 130,
## mesurés le 19 octobre) — en plein combat, sinon.
static func warm(host: Node3D) -> void:
	if _warmed:
		return
	_warmed = true
	var probe := Node3D.new()
	host.add_child(probe)
	var at := probe.global_position
	# Ce qui vit à la racine du viewport (nuage, Pics, Nova, braises, explosion de feu) s'éteint aussi.
	var rooted := host.get_viewport().get_children()
	var made: Array[Node] = [
		trail(probe, Color.WHITE), burst(probe, at, Color.WHITE, 10.0), area(probe, Color.WHITE, 10.0),
		line(probe, at, at + Vector3.RIGHT * 10.0, Color.WHITE), FlameFx.ball(probe, DamageType.Kind.FIRE),
	]
	made.append_array(FlameFx.blast(probe, at, DamageType.Kind.FIRE, 10.0))
	var straight: Array[Vector3] = []
	for i in HellSnake.RINGS:
		straight.append(at - Vector3.RIGHT * HellSnake.SPACING * i)
	SerpentBody.dress(probe, DamageType.Kind.FIRE).lay(straight, 1.0, 0.0)
	var meteor := FlameFx.ball(probe, DamageType.Kind.FIRE)
	meteor.as_meteor()
	made.append(meteor)
	FlameFx.shadow(probe, 10.0)
	FireRing.light_up(probe).show_as(DamageType.Kind.FIRE, 10.0)
	BurntPath.lay(probe, Vector3.RIGHT * 10.0, DamageType.Kind.FIRE, 10.0, 1.0)
	# La traînée vit hors du tir : ramenée sous la sonde, avec de quoi se dessiner.
	for nature in [DamageType.Kind.LIGHTNING, DamageType.Kind.COLD, DamageType.Kind.FIRE]:
		var bolt := BoltFx.show_on(probe, nature)
		bolt.trail.reparent(probe)
		bolt.trail.add_point(at + Vector3.RIGHT * 10.0)
		probe.add_child(BoltFx.flash_of(nature))
	BoltFx.show_on(probe, DamageType.Kind.LIGHTNING, true)
	# Le fer ne lit pas `opacity` : réduit à un point, il se compile sans se voir.
	BrazierFx.light_up(probe, DamageType.Kind.FIRE).body.scale = Vector3.ONE * 0.001
	probe.add_child(StormCloudFx.bolt_of(DamageType.Kind.LIGHTNING))
	probe.add_child(StormCloudFx.stone())
	# Le nuage vit hors de la sonde : libéré avec elle, sans se dissiper.
	var storm := StormCloudFx.gather(probe, DamageType.Kind.LIGHTNING, 10.0)
	host.get_tree().create_timer(0.2).timeout.connect(storm.queue_free)
	# Figés, brisés d'emblée : la lumière ne se rallume pas, les éclats compilent leur matière.
	var spikes := IceSpikesFx.raise(probe, at, DamageType.Kind.COLD, 10.0)
	spikes.process_mode = Node.PROCESS_MODE_DISABLED
	spikes._clock = IceSpikesFx.SHATTER + 0.05
	spikes._show()
	IceNovaFx.flat(probe, IceNovaFx.material(IceVortexFx.SWIRL, DamageType.Kind.COLD), 10.0, 0.0)
	var nova := IceNovaFx.blow(probe, at, DamageType.Kind.COLD, 10.0)
	nova.process_mode = Node.PROCESS_MODE_DISABLED
	HolyBlastFx.blow(probe, at, DamageType.Kind.HOLY, 10.0)
	SacredPillarFx.raise(probe, DamageType.Kind.HOLY, 10.0, true)
	# Le marteau veut son marteau : sa matière et sa traînée paraissent seules.
	for m: Material in [HolyHammerFx.material(DamageType.Kind.HOLY), HolyHammerFx.trail_material(DamageType.Kind.HOLY)]:
		var plate := IceNovaFx.flat(probe, m, 1.0, 0.0)
		plate.mesh = HolyHammerFx.mesh()
	var rot := DamageType.Kind.NECROTIC
	RotBlastFx.blow(probe, at, rot, 10.0)
	PlagueFx.show_on(probe, rot)
	PlagueFx.show_on(probe, rot, true)
	PlagueFx.bone(probe)
	CurseFx.fall(probe, rot, 10.0, 0.2)
	RotGateFx.open(probe, rot, 0.2).crawl([at], [1.0], [Vector3.RIGHT])
	# L'acier : ses rubans, sa poussière et ses mottes, une épée de la ronde. Le cratère, un décal, n'a pas de
	# matière à compiler.
	var steel := DamageType.Kind.PHYSICAL
	SteelFx.swing(probe, steel, 10.0, 0.1, SwingArc.Style.ARC)
	SteelFx.blast(probe, at, 10.0)
	# Le fer de l'épée ne lit pas `opacity` : réduit à un point, comme celui du Brasero.
	SteelFx.sword(probe, probe, steel).scale = Vector3.ONE * 0.001
	SteelFx.whirl(probe, steel, 10.0)
	SteelFx.wave(probe, steel, 10.0)
	# La sorcière : le cercle additionné et le froid mêlé, le Sceau, un fil et le triangle, le chaudron (sa fonte
	# réduite à un point, comme le Brasero), le corbeau (son shader de vol, réduit aussi), l'œil couché.
	var witch: Array[int] = [DamageType.Kind.FIRE, DamageType.Kind.COLD, DamageType.Kind.LIGHTNING]
	# Un glyphe se pose à côté du sien : sur la sonde, sous un repère à elle.
	var mark := Node3D.new()
	probe.add_child(mark)
	GlyphFx.trace(mark, DamageType.Kind.FIRE, 10.0, 0.0)
	GlyphFx.trace(mark, DamageType.Kind.COLD, 10.0, 0.0, true)
	GlyphFx.weave(probe, [at, at + Vector3.RIGHT, at + Vector3.BACK], witch, probe)
	CauldronFx.set_down(probe, witch, 10.0).body.scale = Vector3.ONE * 0.001
	CrowFx.perch(probe).scale = Vector3.ONE * 0.001
	WitchFx.evil_eye(probe, DamageType.Kind.FIRE, 10.0, 0.2)
	made.append_array(probe.find_children("*", "", true, false))
	for node in host.get_viewport().get_children():
		if node not in rooted:
			made.append_array(node.find_children("*", "", true, false))
			made.append(node)
	for node in made:
		if node is GeometryInstance3D:
			node.set_instance_shader_parameter(&"opacity", 0.0)
		elif node is Light3D:
			node.light_energy = 0.0
	host.get_tree().create_timer(0.2).timeout.connect(probe.queue_free)


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
	veil_like(fx, host)
	return fx


## Le voile du porteur : sort ou attaque ennemie, réglé dans les options.
static func veil_like(node: Node, host: Node) -> void:
	for group in [Settings.SPELLS, Settings.ENEMY_ATTACKS]:
		if host.is_in_group(group):
			Settings.veil(node, group)


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


## Posé à l'image sur le porteur **où il se voit** : interpolé lui-même, l'émetteur traînerait d'un pas.
func _follow(host: Node3D, offset: Vector3) -> void:
	_host = host
	_offset = offset
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	host.get_viewport().add_child(self)
	_place()


func _process(_delta: float) -> void:
	if not emitting:
		return
	# `== null` ne voit pas un porteur libéré : il resterait suivi à jamais.
	if not is_instance_valid(_host) or not _host.is_inside_tree():
		let_go()
		return
	_place()


func _place() -> void:
	global_position = _host.get_global_transform_interpolated().origin + _offset


## Le porteur parti ou le coup fini : plus rien ne naît, ce qui vole retombe, puis rien.
func let_go() -> void:
	emitting = false
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
