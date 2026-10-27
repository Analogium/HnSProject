class_name SacredPillarFx
extends Node3D

## Le Pilier sacré en 3D (jalon 54, à la barre de Last Epoch) : la colonne de la 2D, tombée du ciel, un
## cylindre de lumière où tourne une photo (`fx/holy_column.gdshader`) ; la lumière qu'elle pose au sol
## jusqu'au cercle qu'elle mord ; des grains qui montent ; une lumière portée. Chaque impulsion jette
## l'onde du souffle sacré (`HolyBlastFx`, sans rayons) et fait sursauter la colonne. Sous la
## Consécration, le sol consacré, en décal.
##
## Il vit à la racine du viewport et suit son pilier (le Pilier errant glisse) ; éteint, la colonne
## remonte au ciel en `OUT` secondes — sous l'Effondrement, elle s'écrase dans son éclat en `CRUSH`.

const COLUMN_SHADER := preload("res://fx/holy_column.gdshader")
const POOL_SHADER := preload("res://fx/holy_pool.gdshader")
const SHAFT := preload("res://fx/holy_shaft.png")
const GLYPH := preload("res://fx/holy_glyph.png")
## Le rayon de la colonne, en part de celui qu'elle mord, et sa hauteur en pixels.
const COLUMN := 0.45
const HEIGHT := 150.0
const FALL := 0.16
const OUT := 0.45
## Remontée au ciel, la colonne de l'Effondrement semblait s'éteindre sans rien faire.
const CRUSH := 0.15
const PULSE_LIFE := 0.3
const MOTES := 26.0
const MOTE_LIFE := 0.9
const LIGHT := 4.0
const LIGHT_PULSE := 4.0
## Le sol consacré : assez bas pour ne prendre que le sol.
const GLYPH_DEPTH := 8.0
const GLYPH_LIGHT := 1.5

static var _columns := {}
static var _pools := {}
static var _cylinder: CylinderMesh

var _host: Node3D
var _nature := DamageType.Kind.HOLY
var _radius := 0.0
var _clock := 0.0
var _out_at := -1.0
var _pulsed := -INF
var _collapses := false
var column: MeshInstance3D
var _ground: MeshInstance3D
var _glyph: Decal
var _light: OmniLight3D
var _motes: Sparks


## La colonne de `host`, à la nature et au rayon de son lancer ; `consecrated` : le sol consacré dessous ;
## `collapses` : elle finit par l'Effondrement.
static func raise(
	host: Node3D, nature: int, radius: float, consecrated := false, collapses := false
) -> SacredPillarFx:
	var fx := SacredPillarFx.new()
	fx._collapses = collapses
	fx._host = host
	fx._nature = nature
	fx._radius = radius
	fx.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	host.get_viewport().add_child(fx)
	# Ses grains et ses ondes naissent de lui : ils prennent le voile du pilier.
	ElementFx.veil_like(fx, host)
	fx.global_position = host.global_position
	var r := radius * COLUMN
	fx.column = MeshInstance3D.new()
	fx.column.mesh = _cylinder_mesh()
	fx.column.material_override = column_material(nature)
	fx.column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fx.column.scale = Vector3(r, HEIGHT, r)
	fx.column.position = Vector3.UP * HEIGHT * 0.5
	fx.add_child(fx.column)
	fx._ground = IceNovaFx.flat(fx, pool_material(nature), radius, DangerZone.LIFT + 0.3)
	fx._ground.set_instance_shader_parameter(&"column", COLUMN)
	if consecrated:
		fx._glyph = Decal.new()
		# C'est de la lumière : il brille, plutôt que de prendre le soleil comme un albédo.
		fx._glyph.texture_albedo = GLYPH
		fx._glyph.texture_emission = GLYPH
		fx._glyph.emission_energy = GLYPH_LIGHT
		fx._glyph.albedo_mix = 0.6
		fx._glyph.upper_fade = 0.5
		fx._glyph.lower_fade = 0.2
		fx._glyph.size = Vector3(radius * 2.0, GLYPH_DEPTH, radius * 2.0)
		fx._glyph.rotation.y = randf() * TAU
		fx.add_child(fx._glyph)
	fx._light = FlameFx.light_of(nature, LIGHT, radius * 3.0)
	fx._light.light_color = FlameFx.ramp(nature)[0]
	fx._light.position = Vector3.UP * 18.0
	fx.add_child(fx._light)
	for node in [fx.column, fx._ground, fx._glyph]:
		if node != null:
			ElementFx.veil_like(node, host)
	fx._motes = Sparks.trail(fx, nature, MOTES, MOTE_LIFE, fx._mote_source, true)
	fx._show()
	return fx


## Une impulsion : l'onde au sol et la colonne qui sursaute.
func strike() -> void:
	if _out_at >= 0.0:
		return
	_pulsed = _clock
	HolyBlastFx.blow(_host, global_position, _nature, _radius, false)


func _process(delta: float) -> void:
	_clock += delta
	if _out_at < 0.0:
		if is_instance_valid(_host) and _host.is_inside_tree():
			global_position = _host.get_global_transform_interpolated().origin
		else:
			_out_at = _clock
	_show()
	if _out_at >= 0.0 and _clock - _out_at >= _out_time():
		queue_free()


func _out_time() -> float:
	return CRUSH if _collapses else OUT


func _show() -> void:
	var out := clampf((_clock - _out_at) / _out_time(), 0.0, 1.0) if _out_at >= 0.0 else 0.0
	var pulse := 1.0 - clampf((_clock - _pulsed) / PULSE_LIFE, 0.0, 1.0)
	column.set_instance_shader_parameter(&"fall", ease(clampf(_clock / FALL, 0.0, 1.0), 0.5))
	column.set_instance_shader_parameter(&"clock", _clock)
	column.set_instance_shader_parameter(&"pulse", pulse)
	column.set_instance_shader_parameter(&"lift", 0.0 if _collapses else ease(out, 0.6))
	column.set_instance_shader_parameter(&"crush", ease(out, 2.0) if _collapses else 0.0)
	_ground.set_instance_shader_parameter(&"glow", (1.0 + pulse * 0.6) * (1.0 - out))
	if _glyph != null:
		_glyph.modulate.a = Settings.veil_of(_glyph) * (1.0 - out) * clampf(_clock / FALL, 0.0, 1.0)
	_light.light_energy = (LIGHT + LIGHT_PULSE * pulse) * (1.0 - out)


## D'où monte un grain : dans la colonne, près du sol.
func _mote_source() -> Vector3:
	var h := randf() * TAU
	var r := _radius * COLUMN * sqrt(randf())
	return global_position + Vector3(cos(h) * r, randf_range(2.0, 20.0), sin(h) * r)


static func _cylinder_mesh() -> CylinderMesh:
	if _cylinder == null:
		_cylinder = CylinderMesh.new()
		_cylinder.top_radius = 1.0
		_cylinder.bottom_radius = 1.0
		_cylinder.height = 1.0
		_cylinder.cap_top = false
		_cylinder.cap_bottom = false
		_cylinder.radial_segments = 32
		_cylinder.rings = 8
	return _cylinder


## Une colonne et un sol par nature, gardés : un sort converti garde sa colonne, à sa teinte.
static func column_material(nature: int) -> ShaderMaterial:
	if not _columns.has(nature):
		_columns[nature] = HolyBlastFx.ramped(COLUMN_SHADER, SHAFT, nature)
	return _columns[nature]


static func pool_material(nature: int) -> ShaderMaterial:
	if not _pools.has(nature):
		var m := ShaderMaterial.new()
		m.shader = POOL_SHADER
		var ramp := FlameFx.ramp(nature)
		m.set_shader_parameter(&"heart", Vector3(ramp[0].r, ramp[0].g, ramp[0].b))
		m.set_shader_parameter(&"tint", Vector3(ramp[1].r, ramp[1].g, ramp[1].b))
		_pools[nature] = m
	return _pools[nature]
