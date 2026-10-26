class_name FireEmbers
extends MultiMeshInstance3D

## Des braises de feu en 3D (jalon 54, la « pile rouge » du manuel des flammes à la barre de Last Epoch) :
## des points chauds étirés sur leur course (`fx/fire_ember.gdshader`), du cœur de la rampe au rouge
## profond. Balistiques et posées par `ember(i)` à un instant — des particules ne se posent pas, ni sur
## planche ni en test : jetées d'un coup (`burst`, l'explosion) ou semées au fil d'un porteur (`trail`, la
## boule, le serpent). Elles vivent à la racine du viewport et se libèrent éteintes.

const SHADER := preload("res://fx/fire_ember.gdshader")
## Le freinage de l'air, par seconde ; la chute d'une étincelle jetée, la montée d'une braise semée.
const DRAG := 4.0
const FALL := 20.0
const RISE := 12.0
const WIDTH := 2.4

static var _materials := {}

## Semées : le point d'où elles partent, rendu à chaque image ; vide, elles ne naissent plus.
var _source: Callable
var _rising := false
## Semées par seconde, et ce qui reste dû d'une image à l'autre : par image, leur nombre aurait suivi
## l'écran (165 Hz).
var _rate := 0.0
var _due := 0.0
var _clock := 0.0
var _embers: Array[Ember] = []
var _next := 0


class Ember:
	var from: Vector3
	var speed: Vector3
	var born := -INF
	var life := 1.0


## Jetées d'un coup en `at`, sous le voile de `host`, aussi loin que `radius` : elles retombent.
static func burst(host: Node3D, at: Vector3, nature: int, count: int, radius: float) -> FireEmbers:
	var fx := _make(host, nature, count)
	fx.global_position = at
	for e in fx._embers:
		var h := randf() * TAU
		var out := randf_range(radius * 2.0, radius * 5.0)
		e.from = Vector3.UP * ElementFx.LIFT * 0.6
		e.speed = Vector3(cos(h) * out, randf_range(30.0, 90.0), sin(h) * out)
		e.born = 0.0
		e.life = randf_range(0.45, 0.9)
	fx.get_tree().create_timer(0.95).timeout.connect(fx.queue_free)
	fx.pose()
	return fx


## Semées derrière `host` tant qu'il vit, `rate` par seconde, de `source`, en repère global ; `rising`, elles
## montent au lieu de retomber. Chacune vit au plus `life` secondes.
static func trail(host: Node3D, nature: int, rate: float, life: float, source: Callable, rising := false) -> FireEmbers:
	var fx := _make(host, nature, ceili(rate * life))
	fx._source = source
	fx._rising = rising
	fx._rate = rate
	for e in fx._embers:
		e.life = randf_range(life * 0.6, life)
	host.tree_exiting.connect(fx._orphan)
	return fx


static func _make(host: Node3D, nature: int, count: int) -> FireEmbers:
	var fx := FireEmbers.new()
	fx.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = QuadMesh.new()
	mm.instance_count = count
	fx.multimesh = mm
	fx.material_override = _material(nature)
	fx.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in count:
		fx._embers.append(Ember.new())
	host.get_viewport().add_child(fx)
	ElementFx.veil_like(fx, host)
	return fx


func _orphan() -> void:
	_source = Callable()
	get_tree().create_timer(_longest()).timeout.connect(queue_free)


func _longest() -> float:
	var most := 0.0
	for e in _embers:
		most = maxf(most, e.life)
	return most


func _process(delta: float) -> void:
	_clock += delta
	_due += delta * _rate
	while _due >= 1.0 and _source.is_valid():
		_due -= 1.0
		var e := _embers[_next % _embers.size()]
		_next += 1
		e.from = _source.call() + Vector3(randf_range(-3, 3), randf_range(-3, 3), randf_range(-3, 3))
		e.speed = (Vector3(randf_range(-20, 20), randf_range(30, 60), randf_range(-20, 20)) if _rising
				else Vector3(randf_range(-25, 25), randf_range(10, 40), randf_range(-25, 25)))
		e.born = _clock
	pose()


func pose() -> void:
	for i in _embers.size():
		var age := (_clock - _embers[i].born) / _embers[i].life
		multimesh.set_instance_transform(i, ember(i))
		multimesh.set_instance_custom_data(i, Color(clampf(age, 0.0, 1.0), 0.0, 0.0, 0.0))


## La braise `i` à cet instant, couchée sur sa course ; publique pour les tests, le moteur sans rendu ne
## relit pas un `MultiMesh`. Éteinte, réduite à rien.
func ember(i: int) -> Transform3D:
	var e := _embers[i]
	var a := _clock - e.born
	if a < 0.0 or a >= e.life:
		return Transform3D(Basis.from_scale(Vector3.ONE * 0.001), e.from)
	var fall := -RISE if _rising else FALL
	var v := e.speed * exp(-DRAG * a) + Vector3.DOWN * fall * 2.0 * a
	var at := e.from + e.speed * (1.0 - exp(-DRAG * a)) / DRAG + Vector3.DOWN * fall * a * a
	at.y = maxf(at.y, 1.0)
	var axis := v.normalized() if v.length() > 1.0 else Vector3.UP
	var side := axis.cross(Vector3.UP).normalized() if absf(axis.y) < 0.99 else Vector3.RIGHT
	return Transform3D(Basis(side * WIDTH, axis * (2.4 + v.length() * 0.03), side.cross(axis)), at)


static func _material(nature: int) -> ShaderMaterial:
	if not _materials.has(nature):
		var m := ShaderMaterial.new()
		m.shader = SHADER
		var ramp := FlameFx.ramp(nature)
		for k in 3:
			m.set_shader_parameter([&"heart", &"tint", &"deep"][k], Vector3(ramp[k].r, ramp[k].g, ramp[k].b))
		_materials[nature] = m
	return _materials[nature]
