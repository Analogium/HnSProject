class_name WitchFx
extends Node3D

## Le reste du manuel de la sorcière en 3D (jalon 54, à la barre de Last Epoch), dans la langue des Glyphes :
## le même cercle runique en lumière (`GlyphFx.material()`).
## - **L'Amplification** : le cercle aux pieds, petit, qui tourne, et des grains qui montent ; sous
##   l'Incarnation, il prend l'élément incarné, et l'Aura qui frappe l'ouvre jusqu'à sa portée (`pulse()`).
## - **La Trinité** : une rune par charge d'Harmonie, qui tourne autour de la sorcière, dans le tour des
##   éléments.
## - **La Triade** : trois comètes, le trait du joueur dans chaque élément (`BoltFx`), et leurs trois
##   souffles à la jonction.
## - **Le Mauvais œil** : l'œil de la Malédiction (`fx/curse_eye.png`, repris), couché au sol à la rampe de
##   l'élément, qui s'ouvre et se referme.
##
## Il vit sur ce qu'il montre (le buff, la Triade, l'œil), qui le libère avec lui.

## L'Amplification : son cercle, ses grains, sa lumière.
const CIRCLE := 15.0
const CIRCLE_SPIN := 0.5
const MOTES := 10.0
const MOTE_LIFE := 0.8
const LIGHT := 1.2
## L'Aura qui frappe : le cercle ouvert jusqu'à sa portée en `PULSE` secondes.
const PULSE := 0.45
## La Trinité : ses runes, leur orbite et leur tour.
const RUNE := 8.0
const ORBIT := 13.0
const ORBIT_HEIGHT := 14.0
const ORBIT_SPIN := 1.6
## La jonction : le rayon de chaque souffle, en part du sien, quand ils sont plusieurs.
const NESTED := {DamageType.Kind.FIRE: 0.55, DamageType.Kind.LIGHTNING: 0.8, DamageType.Kind.COLD: 1.0}
## Le Mauvais œil, en part de son rayon.
const EYE := 0.6

static var _eyes := {}
static var _standing := {}

var _buff: Buff
var _nature := DamageType.Kind.LIGHTNING
var _clock := 0.0
var _circle: MeshInstance3D
var _light: OmniLight3D
var _runes: Array[MeshInstance3D] = []
## La Triade : ses comètes, d'où chacune part relativement au point visé, en combien de temps.
var _comets: Array[Node3D] = []
var _starts: Array[Vector3] = []
var _travel := 0.0
## Le Mauvais œil : sa paupière, et ce qu'il dure.
var _eye: MeshInstance3D
var _life := 0.0


## L'Amplification sur son buff : le cercle aux pieds, les grains, la lumière.
static func amplify(buff: Buff, nature: int) -> WitchFx:
	var fx := _on(buff)
	fx._buff = buff
	fx._nature = nature
	fx._circle = IceNovaFx.flat(fx, GlyphFx.material(nature), CIRCLE, DangerZone.LIFT + 0.4)
	fx._light = FlameFx.light_of(nature, LIGHT, CIRCLE * 3.0)
	fx._light.position = Vector3.UP * 8.0
	fx.add_child(fx._light)
	Sparks.trail(fx, nature, MOTES, MOTE_LIFE, fx._mote_source, true)
	fx._veil(buff)
	return fx


## La Trinité sur son buff : une rune par charge.
static func harmony(buff: Buff) -> WitchFx:
	var fx := _on(buff)
	fx._buff = buff
	return fx


## L'Aura de l'Incarnation qui frappe : un cercle qui s'ouvre de ses pieds à `reach` et se ronge.
static func pulse(buff: Node3D, nature: int, reach: float) -> void:
	var ring := IceNovaFx.flat(buff, GlyphFx.material(nature), CIRCLE, DangerZone.LIFT + 0.5)
	ElementFx.veil_like(ring, buff)
	ring.rotation.y = randf() * TAU
	var tween := ring.create_tween()
	tween.tween_method(func(t: float) -> void:
		ring.scale = Vector3.ONE * lerpf(CIRCLE, reach, ease(t, 0.4))
		ring.set_instance_shader_parameter(&"glow", 1.6 * (1.0 - t * 0.5))
		ring.set_instance_shader_parameter(&"dissolve", smoothstep(0.35, 1.0, t)), 0.0, 1.0, PULSE)
	tween.tween_callback(ring.queue_free)


## Les comètes de la Triade, une par élément de `natures`, qui partent de `starts` (relatifs au point
## visé) et s'y rejoignent en `travel` secondes, en accélérant.
static func triad(t: Node3D, natures: Array[int], starts: Array[Vector3], travel: float) -> WitchFx:
	var fx := _on(t)
	fx._starts = starts
	fx._travel = travel
	for i in natures.size():
		var comet := Node3D.new()
		comet.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		fx.add_child(comet)
		comet.position = starts[i]
		ElementFx.veil_like(comet, t)
		BoltFx.show_on(comet, natures[i]).straighten()
		fx._comets.append(comet)
	return fx


## La jonction : le souffle de chaque élément, au rayon qui frappe. À plusieurs, ils s'emboîtent — le feu au
## cœur, la foudre autour, le froid dehors : superposés au même rayon, le froid couvrait tout.
static func junction(host: Node3D, at: Vector3, natures: Array[int], radius: float) -> void:
	for nature in natures:
		var r: float = radius * (NESTED[nature] if natures.size() > 1 else 1.0)
		Explosion.paint(host, at, nature, r, DamageType.COLORS[nature], nature == DamageType.Kind.FIRE)


## L'œil du Mauvais œil, couché sur `host`, à son rayon, ouvert `life` secondes.
static func evil_eye(host: Node3D, nature: int, radius: float, life: float) -> WitchFx:
	var fx := _on(host)
	fx._life = life
	fx._eye = IceNovaFx.flat(fx, _eye_material(nature), radius * EYE, DangerZone.LIFT + 0.4)
	fx._eye.scale.z *= 0.7
	fx._veil(host)
	fx._show_eye()
	return fx


## Sous `host`, à son voile : ses grains le reprennent.
static func _on(host: Node3D) -> WitchFx:
	var fx := WitchFx.new()
	host.add_child(fx)
	ElementFx.veil_like(fx, host)
	return fx


func _veil(host: Node) -> void:
	for node in find_children("*", "GeometryInstance3D", true, false):
		ElementFx.veil_like(node, host)


func _process(delta: float) -> void:
	_clock += delta
	if _circle != null:
		_show_circle()
	elif _buff != null:
		_show_runes()
	elif not _comets.is_empty():
		var k := minf(_clock / _travel, 1.0)
		for i in _comets.size():
			_comets[i].position = _starts[i].lerp(Vector3.ZERO, k * k)
	elif _eye != null:
		_show_eye()


func _show_circle() -> void:
	var incarnate := _buff.incarnation if _buff.incarnation >= 0 else _nature
	if _circle.material_override != GlyphFx.material(incarnate):
		_circle.material_override = GlyphFx.material(incarnate)
		_light.light_color = FlameFx.ramp(incarnate)[1]
	_circle.rotation.y = _clock * CIRCLE_SPIN
	_circle.set_instance_shader_parameter(&"clock", _clock)
	# Il se trace à l'allumage, et s'éteint avec elle sur sa fin.
	var left := _buff.remaining()
	var ending := 1.0 - clampf(left / 0.4, 0.0, 1.0) if left > 0.0 else 0.0
	_circle.set_instance_shader_parameter(&"dissolve", maxf(ending, 1.0 - ease(minf(_clock / 0.3, 1.0), 0.5)))


## Une rune par charge, dans le tour feu → froid → foudre, réparties sur l'orbite.
func _show_runes() -> void:
	while _runes.size() < _buff.stacks:
		var kind: int = DamageType.ELEMENTS[_runes.size() % DamageType.ELEMENTS.size()]
		var rune := MeshInstance3D.new()
		rune.mesh = QuadMesh.new()
		rune.material_override = _rune_material(kind)
		rune.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		rune.scale = Vector3.ONE * RUNE
		add_child(rune)
		ElementFx.veil_like(rune, _buff)
		_runes.append(rune)
	while _runes.size() > _buff.stacks:
		_runes.pop_back().queue_free()
	for i in _runes.size():
		var a := _clock * ORBIT_SPIN + TAU * float(i) / float(_runes.size())
		_runes[i].position = Vector3(cos(a) * ORBIT, ORBIT_HEIGHT + sin(_clock * 3.0 + i) * 1.5, sin(a) * ORBIT)
		_runes[i].set_instance_shader_parameter(&"clock", _clock)
		_runes[i].set_instance_shader_parameter(&"glow", 1.6)


func _show_eye() -> void:
	var open := ease(clampf(_clock / (_life * 0.3), 0.0, 1.0), 0.4)
	var closing := clampf((_clock - _life * 0.7) / (_life * 0.3), 0.0, 1.0)
	_eye.set_instance_shader_parameter(&"lid", open * (1.0 - closing))
	_eye.set_instance_shader_parameter(&"life", 0.0)


func _mote_source() -> Vector3:
	var h := randf() * TAU
	var r := CIRCLE * sqrt(randf())
	return global_position + Vector3(cos(h) * r, 1.0, sin(h) * r)


## Le cercle tourné vers la caméra.
static func _rune_material(nature: int) -> ShaderMaterial:
	if not _standing.has(nature):
		var m: ShaderMaterial = GlyphFx.material(nature).duplicate()
		m.set_shader_parameter(&"lying", false)
		_standing[nature] = m
	return _standing[nature]


## Couché au sol, à la rampe de l'élément : aux couleurs de sa photo, un œil nécrotique.
static func _eye_material(nature: int) -> ShaderMaterial:
	if not _eyes.has(nature):
		var m: ShaderMaterial = RotBlastFx.photo_material(CurseFx.EYE, nature).duplicate()
		m.set_shader_parameter(&"lying", true)
		m.set_shader_parameter(&"density", 3.0)
		_eyes[nature] = m
	return _eyes[nature]
