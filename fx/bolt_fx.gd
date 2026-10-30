class_name BoltFx
extends Node3D

## Le trait de foudre en 3D (jalon 54), façon Kinetic Bolt de Path of Exile, électrique : « dents de
## scie » choisi sur une troisième planche, contre l'équerre, la ligne droite et un gros orbe (avant,
## des arcs photographiés étirés « ne ressemblaient pas à un éclair », puis un zigzag couché derrière
## le tir a été écarté pour cette référence). Un orbe de plasma qui file en zigzag **autour** de la
## vraie trajectoire, droite — le dessin s'en écarte, le coup non —, trois arcs qui crépitent autour,
## une longue traînée qui garde la forme du zigzag et survit au tir ; à sa fin, un éclat.
## **Le Trait de glace** (le trait passé au froid, « Kinetic de glace » choisi sur planche contre un
## javelot de cristal, un éclat photographié, un orbe dans la brume et une salve) : le même geste, un
## orbe de glace sans arcs, une traînée de givre, un éclatement ; mêlés au sol, pas additionnés.
## **En feu** (le Familier, « Kinetic de feu ») : la boule de `FlameFx`, une traînée de flammes. **Les
## Esquilles** : le trait en petit. **L'Orbe statique** (« boule de plasma ») : un gros orbe aux arcs,
## qui file droit et décharge en arcs ; **le Satellite** lui ajoute la traînée (« sillage »).
## **À la barre de Last Epoch** (« étincelles, distorsion » choisi sur planche contre l'actuel, les étincelles
## seules et une lueur au sol — un voile lilas) : chaque frappe de foudre jette des étincelles et pousse
## l'air (`shock()`) ; la Chaîne et les décharges de l'Orbe statique, des étincelles à chaque cible.

const ARC := preload("res://fx/lightning_bolt.gdshader")
const PHOTO := preload("res://fx/lightning_spark.gdshader")
const TRAIL := preload("res://fx/lightning_trail.gdshader")
const BOLT_PHOTO := preload("res://fx/lightning_bolt.png")
const SPARK_PHOTO := preload("res://fx/lightning_spark.png")
const ORB_PHOTO := preload("res://fx/lightning_orb.png")
const FROST := preload("res://fx/frost_photo.gdshader")
const FROST_TRAIL := preload("res://fx/frost_trail.gdshader")
const FROST_ORB := preload("res://fx/frost_orb.png")
const FROST_STREAK := preload("res://fx/frost_streak.png")
const FROST_BURST := preload("res://fx/frost_burst.png")
const FIRE_BALL := preload("res://fx/fire_ball.png")
const FIRE_BLAST := preload("res://fx/fire_blast.png")
const FIRE_STREAK := preload("res://fx/fire_streak.png")
## L'écart du dessin à la trajectoire, et la longueur d'une dent, en pixels.
const AMP := 10.0
const STEP := 26.0
const ORB := 6.0
const SPARK := 10.0
const ARCS := 3
const ARC_LENGTH := 10.0
const ARC_WIDTH := 5.0
const ARC_SPIN := 11.0
const TRAIL_LIFE := 0.45
const TRAIL_WIDTH := 3.5
const LIGHT := 3.0
const REACH := 36.0
const FLARE := 20.0
const FLARE_LIFE := 0.18
## Un éclat des Esquilles : le trait en petit (« mini Kinetic » choisi sur planche).
const SHARD := 0.55
## Les arcs dessinés par frappe d'un nuage ou d'un orbe, quel que soit le nombre de cibles :
## un arc par cible coûtait 467 ms par seconde à six orbes chargés dans une meute (jalon 43).
const ARCS_MOST := 3
## Une décharge de l'Orbe statique : l'arc jusqu'à sa cible, et l'éclat qu'il y laisse.
const ZAP_WIDTH := 7.0
const ZAP_LIFE := 0.14
const ZAP_FLASH := 12.0
const ZAP_FLASH_LIFE := 0.2
## Un saut de la Chaîne d'éclairs (« tresse », choisie sur planche contre la photo ramifiée, le ruban
## seul, le ruban sur sa ramure et un arc qui court) : trois rubans fins aux coudes différents.
const BRAID := 3
const BRAID_WIDTH := 4.0
const BRAID_AMP := 2.5
const BRAID_KINKS := 7
const BRAID_BOOST := 0.75
const BRAID_LIGHT := 3.0
const BRAID_REACH := 34.0
## La Ruée d'orage (« éclair bref », contre une traînée de plasma, des brûlures et le semis
## d'étincelles) : deux brins du départ à l'arrivée, qui s'éteignent de la queue vers l'arrivée.
const DASH_STRANDS := 2
const DASH_KINKS := 9
const DASH_WIDTH := 6.0
const DASH_AMP := 1.6
const DASH_LIFE := 0.16
const DASH_FLASH := 14.0
const DASH_LANDING := 20.0
const DASH_LIGHT_REACH := 2.5
## L'appel du tonnerre (« arcs aux pieds », contre le halo d'étincelles) : trois arcs qui tournent.
const FEET := Vector2(16.0, 6.0)
const FEET_OFFSET := 12.0
const FEET_LIGHT := 2.0
const FEET_REACH := 28.0
## Une explosion de foudre (« couronne d'arcs », le parti pris de la 2D, contre une onde de choc
## photographiée et une brûlure de Lichtenberg) : un éclat, puis un anneau d'arcs qui s'ouvre de la
## moitié du rayon jusqu'au bord, et se défait.
const CROWN_STEP := 18.0
const CROWN_WIDTH := 4.0
const CROWN_OPEN := 0.22
const CROWN_FADE := 0.12
const CROWN_FLASH := 0.67
## L'Ionisation (« anneau qui s'ouvre », contre des arcs vers les engourdis et rien de plus) : la
## couronne en plus discret, du corps jusqu'à sa portée, à chaque impulsion.
const PULSE_START := 8.0
const PULSE_WIDTH := 3.0
const PULSE_BOOST := 0.6
const PULSE_OPEN := 0.35
## La Cage de Faraday (« dôme d'arcs », contre des barreaux et une bulle de plasma) : des méridiens
## d'arcs sur une demi-sphère qui tourne, le temps de l'invulnérabilité.
const CAGE_RADIUS := 16.0
const CAGE_MERIDIANS := 6
const CAGE_STEPS := 3
const CAGE_WIDTH := 3.0
const CAGE_BOOST := 0.9
const CAGE_TURN := 3.0
const CAGE_LIGHT := 1.5
## Une charge statique (« étincelle », contre un mini-orbe et une étoile d'arcs) : la gerbe
## photographiée qui tourne sur place, aussi large que le rayon qui mord.
const CHARGE_SPIN := 3.0
const CHARGE_LIGHT := 0.8
## Une frappe (`shock()`) : des étincelles, autant que `SHOCK_SPARKS` plus une par deux pixels de rayon,
## brèves et lancées loin ; la distorsion de la Nova qui s'ouvre en `SHOCK_OPEN` et retombe.
const SHOCK_SPARKS := 12
const SHOCK_LIFE := Vector2(0.15, 0.4)
const SHOCK_THROW := Vector2(5.0, 12.0)
const SHOCK_OPEN := 0.18
const SHOCK_WARP := 0.035
const SHOCK_WARP_LIFE := 0.25
## La Ruée d'orage sème ses étincelles en `DASH_SPARKS` gerbes le long du trait ; la Chaîne et l'Orbe
## statique en jettent à chaque cible.
const DASH_SPARKS := 5
const BRAID_SPARKS := 10

static var _arc_draw := {}
static var _photos := {}
static var _trails := {}
static var _ribbons := {}

var trail: Trail
var _orb: Node3D
var _nature := 0
var _look: Look
## Où le tir se voyait à l'image d'avant.
var _last := Vector3.ZERO
var _dir := Vector3.RIGHT
var _run := 0.0


## Le trait de `host`, qui le porte ; sa traînée vit à la racine du viewport et lui survit. L'Orbe
## statique (`orb`) a le gros orbe qui ne zigzague pas, et pas de traînée hors du Satellite.
static func show_on(host: Node3D, nature: int, orb := false, orbits := false) -> BoltFx:
	var fx := BoltFx.new()
	fx._nature = nature
	fx._look = Look.of(nature, orb)
	host.add_child(fx)
	fx.position = Vector3.UP * ElementFx.LIFT
	fx._last = fx.global_position
	fx._orb = Node3D.new()
	# Son écart se pose à l'image ; le tir qui le porte, lui, est interpolé par le moteur.
	fx._orb.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	fx.add_child(fx._orb)
	var look := fx._look
	var shown: Array[GeometryInstance3D] = [_photo_quad(nature, look.orb, look.cell, look.size, look.spin)]
	if look.spark:
		shown.append(_photo_quad(nature, SPARK_PHOTO, Look.WHOLE, SPARK, -6.0))
	for i in look.arcs:
		var arc := _arc(nature, look.arc)
		arc.rotation.y = TAU * float(i) / float(look.arcs)
		shown.append(arc)
	for node in shown:
		fx._orb.add_child(node)
	fx._orb.add_child(FlameFx.light_of(nature, LIGHT, REACH))
	if not orb or orbits:
		fx.trail = Trail.new()
		fx.trail.material_override = trail_material(nature)
		fx.trail.target = fx._orb
		host.get_viewport().add_child(fx.trail)
		shown.append(fx.trail)
	for node in shown:
		ElementFx.veil_like(node, host)
	return fx


## Un simple projectile, qui file droit : le Projectile élémentaire, ses gouttes et ses comètes.
func straighten() -> void:
	_look.amp = 0.0


## Un éclat des Esquilles : tout en petit, traînée comprise.
func shrink() -> void:
	scale = Vector3.ONE * SHARD
	trail.width = TRAIL_WIDTH * SHARD


## L'éclat de fin de course, sur l'orbe. **Différé** : la fin arrive souvent d'un rappel de collision.
func flare() -> void:
	flare_at.call_deferred(get_viewport(), _orb.global_position, get_parent(), _nature, scale.x)


## Une décharge de l'Orbe statique : un arc de l'orbe à chaque cible, `ARCS_MOST` au plus,
## qui s'y éteint sur un éclat.
func zap(targets: Array) -> void:
	var from := _orb.global_position
	for target: Node3D in targets.slice(0, ARCS_MOST):
		var to := target.global_position + Vector3.UP * ElementFx.LIFT * 0.5
		var arc := _arc(_nature, Vector2(from.distance_to(to), ZAP_WIDTH))
		arc.top_level = true
		add_child(arc)
		arc.global_position = to
		arc.rotation.y = -Flat.angle(to - from)
		var flash := flash_of(_nature)
		get_viewport().add_child(flash)
		flash.global_position = to
		for node: GeometryInstance3D in [arc, flash]:
			ElementFx.veil_like(node, get_parent())
		fade(arc, Vector3(arc.scale.x, ZAP_WIDTH, 1.0), ZAP_LIFE)
		fade(flash, Vector3.ONE * ZAP_FLASH, ZAP_FLASH_LIFE)
		if _nature == DamageType.Kind.LIGHTNING:
			Sparks.burst(flash, target.global_position, _nature, BRAID_SPARKS, 5.0, SHOCK_LIFE, SHOCK_THROW)


## Le cap se lit sur le chemin fait depuis l'image d'avant : le tir ne le dit pas, et un rebond
## le change d'un pas à l'autre. L'écart suit une dent de scie le long du chemin, nul au départ.
func _process(delta: float) -> void:
	var at := get_global_transform_interpolated().origin
	var moved := at - _last
	_last = at
	if moved.length_squared() > 0.0001:
		_dir = moved.normalized()
		_run += moved.length()
	var tooth := (absf(fposmod(_run / (STEP * 2.0) + 0.25, 1.0) * 2.0 - 1.0) * 2.0 - 1.0) * _look.amp
	_orb.position = Vector3(-_dir.z, 0.0, _dir.x) * tooth
	_orb.rotation.y += delta * ARC_SPIN


## Un saut de la Chaîne d'éclairs, de `from` à `to`, sous `host` qui le dissout ; à l'arrivée, un
## éclat et une lumière, qui se libèrent seuls.
static func braid(host: Node3D, from: Vector3, to: Vector3, nature: int) -> void:
	from += Vector3.UP * ElementFx.LIFT
	to += Vector3.UP * ElementFx.LIFT
	var length := from.distance_to(to)
	if length < 0.01:
		return
	for i in BRAID:
		var strand := MeshInstance3D.new()
		strand.mesh = _ribbon_mesh(nature, BRAID_KINKS + i, BRAID_AMP, BRAID_BOOST)
		strand.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		strand.scale = Vector3(length, BRAID_WIDTH, 1.0)
		strand.extra_cull_margin = length
		strand.set_instance_shader_parameter(&"seed", randf() * 100.0)
		host.add_child(strand)
		strand.global_position = to
		strand.rotation.y = -Flat.angle(to - from)
		ElementFx.veil_like(strand, host)
	var flash := flash_of(nature)
	host.get_viewport().add_child(flash)
	flash.global_position = to
	ElementFx.veil_like(flash, host)
	var light := FlameFx.light_of(nature, BRAID_LIGHT, BRAID_REACH)
	flash.add_child(light)
	light.create_tween().tween_property(light, ^"light_energy", 0.0, ZAP_FLASH_LIFE)
	fade(flash, Vector3.ONE * ZAP_FLASH, ZAP_FLASH_LIFE)
	if nature == DamageType.Kind.LIGHTNING:
		Sparks.burst(host, to - Vector3.UP * ElementFx.LIFT, nature, BRAID_SPARKS, 5.0, SHOCK_LIFE, SHOCK_THROW)


## La Ruée d'orage de `from` à `to` : deux brins, un éclat à chaque bout, à la racine de `viewport`.
static func dash(viewport: Viewport, from: Vector3, to: Vector3) -> void:
	var nature := DamageType.Kind.LIGHTNING
	from += Vector3.UP * ElementFx.LIFT
	to += Vector3.UP * ElementFx.LIFT
	var length := maxf(from.distance_to(to), 0.01)
	for i in DASH_STRANDS:
		var strand := MeshInstance3D.new()
		strand.mesh = _ribbon_mesh(nature, DASH_KINKS + 3 * i, DASH_AMP, 1.0)
		strand.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		strand.scale = Vector3(length, DASH_WIDTH - float(i), 1.0)
		strand.extra_cull_margin = length
		strand.set_instance_shader_parameter(&"seed", randf() * 100.0)
		viewport.add_child(strand)
		Settings.veil(strand, Settings.SPELLS)
		strand.global_position = to
		strand.rotation.y = -Flat.angle(to - from)
		var tween := strand.create_tween()
		tween.tween_method(func(t: float) -> void: strand.set_instance_shader_parameter(&"gone", t), 0.0, 1.0, DASH_LIFE)
		tween.tween_callback(strand.queue_free)
	var landing: MeshInstance3D
	for end: Array in [[from, DASH_FLASH], [to, DASH_LANDING]]:
		var flash := flash_of(nature)
		landing = flash
		viewport.add_child(flash)
		Settings.veil(flash, Settings.SPELLS)
		flash.global_position = end[0]
		var light := FlameFx.light_of(nature, BRAID_LIGHT, float(end[1]) * DASH_LIGHT_REACH)
		flash.add_child(light)
		light.create_tween().tween_property(light, ^"light_energy", 0.0, FLARE_LIFE)
		fade(flash, Vector3.ONE * float(end[1]), FLARE_LIFE)
	# L'éclat d'arrivée, voilé, porte le reste : on ne lui demande que son viewport et son voile.
	for k in DASH_SPARKS:
		var at := from.lerp(to, (k + 0.5) / DASH_SPARKS) - Vector3.UP * ElementFx.LIFT
		Sparks.burst(landing, at, nature, 5, 4.0, SHOCK_LIFE * 0.8, SHOCK_THROW * 0.8)
	shock(landing, to - Vector3.UP * ElementFx.LIFT, nature, 14.0)


## L'appel du tonnerre sous `host` (le buff, qui suit son porteur) : trois arcs qui tournent autour
## des pieds, une lueur ; ils partent avec lui.
static func feet(host: Node3D) -> Node3D:
	var nature := DamageType.Kind.LIGHTNING
	var ring := Node3D.new()
	ring.position = Vector3.UP * 2.0
	host.add_child(ring)
	for i in ARCS:
		var arm := Node3D.new()
		arm.rotation.y = TAU * float(i) / float(ARCS)
		ring.add_child(arm)
		var arc := _arc(nature, FEET)
		arc.position = Vector3.RIGHT * FEET_OFFSET
		arm.add_child(arc)
		ElementFx.veil_like(arc, host)
	var light := FlameFx.light_of(nature, FEET_LIGHT, FEET_REACH)
	light.position = Vector3.UP * 4.0
	ring.add_child(light)
	ring.create_tween().set_loops().tween_property(ring, ^"rotation:y", TAU, TAU / ARC_SPIN).as_relative()
	return ring


## L'explosion de foudre de `host`, en `at`, à ce rayon : à la racine du viewport, elle se libère seule.
static func crown(host: Node3D, at: Vector3, radius: float, nature: int) -> void:
	var viewport := host.get_viewport()
	var flash := flash_of(nature)
	viewport.add_child(flash)
	ElementFx.veil_like(flash, host)
	flash.global_position = at + Vector3.UP * ElementFx.LIFT * 0.6
	var light := FlameFx.light_of(nature, BRAID_LIGHT, radius * CROWN_FLASH * DASH_LIGHT_REACH)
	flash.add_child(light)
	light.create_tween().tween_property(light, ^"light_energy", 0.0, FLARE_LIFE)
	fade(flash, Vector3.ONE * radius * CROWN_FLASH, FLARE_LIFE)
	_ring(host, at + Vector3.UP * 3.0, _ribbon_mesh(nature, 3, 0.8, 1.0), radius * 0.5, radius, CROWN_WIDTH, CROWN_OPEN)
	shock(host, at, nature, radius)


## Une frappe de foudre en `at`, sous le voile de `host`, à ce rayon : des étincelles jetées et l'air
## poussé vers le dehors, à la racine du viewport ; tout se libère seul. La foudre seule : la glace a ses
## esquilles, le feu ses braises.
static func shock(host: Node3D, at: Vector3, nature: int, radius: float) -> void:
	if nature != DamageType.Kind.LIGHTNING:
		return
	Sparks.burst(host, at, nature, SHOCK_SPARKS + roundi(radius * 0.5), radius, SHOCK_LIFE, SHOCK_THROW)
	var holder := Node3D.new()
	host.get_viewport().add_child(holder)
	holder.global_position = at
	var warp := IceNovaFx.flat(holder, IceNovaFx.material(IceNovaFx.WARP, nature), radius * 1.4, DangerZone.LIFT + 0.8)
	ElementFx.veil_like(warp, host)
	var tween := holder.create_tween()
	tween.tween_method(func(t: float) -> void:
		warp.set_instance_shader_parameter(&"front", lerpf(0.15, 0.9, ease(clampf(t / SHOCK_OPEN, 0.0, 1.0), 0.4)))
		warp.set_instance_shader_parameter(&"strength", SHOCK_WARP * (1.0 - smoothstep(0.05, SHOCK_WARP_LIFE, t))),
		0.0, SHOCK_WARP_LIFE, SHOCK_WARP_LIFE)
	tween.tween_callback(holder.queue_free)


## Une impulsion de l'Ionisation autour de `host` (le buff, au porteur), jusqu'à `radius`.
static func pulse(host: Node3D, radius: float) -> void:
	var mesh := _ribbon_mesh(DamageType.Kind.LIGHTNING, 3, 0.8, PULSE_BOOST)
	_ring(host, host.global_position + Vector3.UP * 2.0, mesh, PULSE_START, radius, PULSE_WIDTH, PULSE_OPEN)


## Un anneau d'arcs qui s'ouvre de `start` à `end` en `open`, puis se défait, à la racine du viewport.
## Chaque arc est une corde du cercle, posée par sa tête : le cercle s'ouvre, la largeur reste.
static func _ring(host: Node3D, at: Vector3, mesh: QuadMesh, start: float, end: float, width: float, open: float) -> void:
	var ring := Node3D.new()
	host.get_viewport().add_child(ring)
	ring.global_position = at
	var count := clampi(roundi(TAU * end / CROWN_STEP), 8, 24)
	var arcs: Array[MeshInstance3D] = []
	for i in count:
		var arc := MeshInstance3D.new()
		arc.mesh = mesh
		arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arc.set_instance_shader_parameter(&"seed", randf() * 100.0)
		arc.rotation.y = -(TAU * (float(i) + 0.5) / float(count) + PI * 0.5)
		ring.add_child(arc)
		ElementFx.veil_like(arc, host)
		arcs.append(arc)
	var spread := func(r: float) -> void:
		for i in count:
			var head := TAU * float(i + 1) / float(count)
			arcs[i].position = Vector3(cos(head), 0.0, sin(head)) * r
			arcs[i].scale = Vector3(2.0 * r * sin(PI / float(count)), width, 1.0)
			arcs[i].extra_cull_margin = r
	spread.call(start)
	var tween := ring.create_tween()
	tween.tween_method(spread, start, end, open).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(o: float) -> void:
		for arc in arcs:
			arc.set_instance_shader_parameter(&"opacity", o * Settings.veil_of(arc)), 1.0, 0.0, CROWN_FADE)
	tween.tween_callback(ring.queue_free)


## La Cage de Faraday sur `host` (le joueur, qu'elle suit) pendant `life` secondes.
static func cage(host: Node3D, life: float) -> Node3D:
	var nature := DamageType.Kind.LIGHTNING
	var dome := Node3D.new()
	host.add_child(dome)
	var mesh := _ribbon_mesh(nature, 2, 0.8, CAGE_BOOST)
	for m in CAGE_MERIDIANS:
		var meridian := Node3D.new()
		meridian.rotation.y = TAU * float(m) / float(CAGE_MERIDIANS)
		dome.add_child(meridian)
		for k in CAGE_STEPS:
			var low := Vector3.RIGHT.rotated(Vector3.FORWARD, -PI * 0.5 * float(k) / float(CAGE_STEPS)) * CAGE_RADIUS
			var high := Vector3.RIGHT.rotated(Vector3.FORWARD, -PI * 0.5 * float(k + 1) / float(CAGE_STEPS)) * CAGE_RADIUS
			var along := high - low
			var arc := MeshInstance3D.new()
			arc.mesh = mesh
			arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			arc.set_instance_shader_parameter(&"seed", randf() * 100.0)
			arc.extra_cull_margin = CAGE_RADIUS
			# Posé par sa tête, couché de la base vers le sommet ; le shader le tourne vers la caméra.
			arc.transform = Transform3D(Basis(along, Vector3.FORWARD * CAGE_WIDTH, along.normalized().cross(Vector3.FORWARD)), high)
			meridian.add_child(arc)
			Settings.veil(arc, Settings.SPELLS)
	var light := FlameFx.light_of(nature, CAGE_LIGHT, CAGE_RADIUS * 2.0)
	light.position = Vector3.UP * CAGE_RADIUS * 0.75
	dome.add_child(light)
	var tween := dome.create_tween()
	tween.tween_property(dome, ^"rotation:y", TAU * life / CAGE_TURN, life)
	tween.tween_callback(dome.queue_free)
	return dome


## Une charge statique sous `host`, aussi large que `reach`, le rayon qui mord.
static func spark(host: Node3D, reach: float) -> MeshInstance3D:
	var nature := DamageType.Kind.LIGHTNING
	var node := _photo_quad(nature, SPARK_PHOTO, Look.WHOLE, reach * 2.0, CHARGE_SPIN)
	# Centrée au sol, sa moitié basse passait sous le relief : levée de son rayon.
	node.position = Vector3.UP * reach
	host.add_child(node)
	ElementFx.veil_like(node, host)
	node.add_child(FlameFx.light_of(nature, CHARGE_LIGHT, reach * 2.0))
	return node


## L'éclat de fin de course de `nature` en `at`, à `size` : public pour l'éclat des pics.
static func flare_at(viewport: Viewport, at: Vector3, host: Node, nature: int, size: float) -> void:
	if not is_instance_valid(viewport):
		return
	var flash := flash_of(nature)
	viewport.add_child(flash)
	if is_instance_valid(host):
		ElementFx.veil_like(flash, host)
	flash.global_position = at
	fade(flash, Vector3.ONE * FLARE * size, FLARE_LIFE)
	# L'éclat, voilé comme le tir, porte la frappe : le tir, différé jusqu'ici, peut être parti.
	shock(flash, at - Vector3.UP * ElementFx.LIFT, nature, 6.0 * size)


## Grandit jusqu'à `to` en s'éteignant, sous son voile, puis se libère.
static func fade(node: GeometryInstance3D, to: Vector3, life: float) -> void:
	var tween := node.create_tween().set_parallel()
	tween.tween_property(node, "scale", to, life)
	tween.tween_method(
		func(o: float) -> void: node.set_instance_shader_parameter(&"opacity", o * Settings.veil_of(node)), 1.0, 0.0, life
	)
	tween.chain().tween_callback(node.queue_free)


## L'éclat de fin de course, petit : `_flare()` le grandit. Public pour `ElementFx.warm()`.
static func flash_of(nature: int) -> MeshInstance3D:
	var look := Look.of(nature, false)
	return _photo_quad(nature, look.flash, look.flash_cell, 4.0, 0.0)


static func _photo_quad(nature: int, photo: Texture2D, cell: Vector4, size: float, spin: float) -> MeshInstance3D:
	var key := "%d %s %s %s" % [nature, photo.resource_path, cell, spin]
	if not _photos.has(key):
		var m := ramped(FROST if nature == DamageType.Kind.COLD else PHOTO, photo, nature)
		m.set_shader_parameter(&"spin", spin)
		if cell != Look.WHOLE:
			m.set_shader_parameter(&"cell", cell)
		if nature == DamageType.Kind.FIRE:
			m.set_shader_parameter(&"boost", 0.55)
		var quad := QuadMesh.new()
		quad.material = m
		_photos[key] = quad
	var node := MeshInstance3D.new()
	node.mesh = _photos[key]
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.scale = Vector3.ONE * size
	return node


## Un arc qui crépite, couché de x = −`size.x` à 0 : les coudes sortent du quad, que le moteur
## jugerait hors champ trop tôt.
static func _arc(nature: int, size: Vector2) -> MeshInstance3D:
	var arc := MeshInstance3D.new()
	arc.mesh = _arc_mesh(nature)
	arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arc.scale = Vector3(size.x, size.y, 1.0)
	arc.extra_cull_margin = maxf(size.x, size.y)
	arc.set_instance_shader_parameter(&"seed", randf() * 100.0)
	return arc


## Un quad couché du centre de l'orbe (x = −1) à son bord (x = 0), assez découpé pour se casser.
static func _arc_mesh(nature: int) -> QuadMesh:
	if not _arc_draw.has(nature):
		var quad := QuadMesh.new()
		quad.center_offset = Vector3(-0.5, 0.0, 0.0)
		quad.subdivide_width = 24
		var m := ramped(ARC, BOLT_PHOTO, nature)
		m.set_shader_parameter(&"kinks", 3.0)
		m.set_shader_parameter(&"boost", 1.0)
		quad.material = m
		_arc_draw[nature] = quad
	return _arc_draw[nature]


## Un brin qui relie deux points (la tresse, la ruée) : ses coudes à lui, assez de crans pour
## qu'aucun ne tombe entre deux sommets, plein dès sa source.
static func _ribbon_mesh(nature: int, kinks: int, amp: float, boost: float) -> QuadMesh:
	var key := "%d %d %s %s" % [nature, kinks, amp, boost]
	if not _ribbons.has(key):
		var quad := QuadMesh.new()
		quad.center_offset = Vector3(-0.5, 0.0, 0.0)
		quad.subdivide_width = 64
		var m := ramped(ARC, BOLT_PHOTO, nature)
		m.set_shader_parameter(&"kinks", float(kinks))
		m.set_shader_parameter(&"amp", amp)
		m.set_shader_parameter(&"boost", boost)
		m.set_shader_parameter(&"tail", 0.03)
		quad.material = m
		_ribbons[key] = quad
	return _ribbons[key]


static func trail_material(nature: int) -> ShaderMaterial:
	if not _trails.has(nature):
		var look := Look.of(nature, false)
		var m := ramped(FROST_TRAIL if nature == DamageType.Kind.COLD else TRAIL, look.streak, nature)
		if nature == DamageType.Kind.FIRE:
			# La photo d'une comète, tête à droite : la traînée n'en prend que le corps.
			m.set_shader_parameter(&"along", 0.65)
			m.set_shader_parameter(&"boost", 0.9)
		_trails[nature] = m
	return _trails[nature]


## La matière d'une photo passée par la rampe de sa nature (`fx/lightning_common.gdshaderinc`) ;
## l'éclair du Nuage d'orage la prend aussi.
static func ramped(shader: Shader, photo: Texture2D, nature: int) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter(&"photo", photo)
	var ramp := FlameFx.ramp(nature)
	for i in 3:
		var c: Color = ramp[i]
		m.set_shader_parameter([&"heart", &"tint", &"deep"][i], Vector3(c.r, c.g, c.b))
	if nature == DamageType.Kind.FIRE:
		# Le cœur blanc de la foudre, sur du feu, sortait bleuté.
		m.set_shader_parameter(&"core", Vector3(1.0, 0.85, 0.45))
	return m


## Ce que montre une nature. La foudre crépite (son orbe, une étincelle, des arcs) ; la glace s'ombre,
## mêlée au sol (additionné à l'ocre, son cyan sortait blanc) ; le feu porte la boule de `FlameFx`.
## L'Orbe statique (`orb`) a le gros orbe aux arcs, qui ne zigzague pas.
class Look:
	const WHOLE := Vector4(0.0, 0.0, 1.0, 1.0)
	var orb: Texture2D = ORB_PHOTO
	## La case de la photo, dans un atlas.
	var cell := WHOLE
	var size := ORB
	var spin := 4.0
	var spark := true
	var arcs := ARCS
	var arc := Vector2(ARC_LENGTH, ARC_WIDTH)
	var amp := AMP
	var streak: Texture2D = BOLT_PHOTO
	var flash: Texture2D = SPARK_PHOTO
	var flash_cell := WHOLE

	static func of(nature: int, orb_shape: bool) -> Look:
		var look := Look.new()
		if orb_shape:
			look.size = 16.0
			look.spin = 3.0
			look.spark = false
			look.arc = Vector2(12.0, 6.0)
			look.amp = 0.0
		elif nature == DamageType.Kind.COLD:
			look.orb = FROST_ORB
			look.size = 10.0
			look.spin = 2.0
			look.spark = false
			look.arcs = 0
			look.streak = FROST_STREAK
			look.flash = FROST_BURST
		elif nature == DamageType.Kind.FIRE:
			look.orb = FIRE_BALL
			look.cell = Vector4(0.0, 0.0, 1.0 / 3.0, 1.0)
			look.size = 11.0
			look.spin = 3.0
			look.spark = false
			look.arcs = 0
			look.streak = FIRE_STREAK
			look.flash = FIRE_BLAST
			look.flash_cell = Vector4(0.0, 0.0, 0.5, 1.0)
		return look


## La traînée : les positions passées de sa cible, chacune avec son âge, en ruban tourné vers la
## caméra. Sa cible partie, elle finit de s'éteindre puis se libère.
class Trail extends MeshInstance3D:
	var target: Node3D
	var width := TRAIL_WIDTH
	## Le couteau du Vive lame la veut courte : à 460 px/s, `TRAIL_LIFE` lui traînait 200 px.
	var life := TRAIL_LIFE
	## Le repère où elle se pose, null pour le monde : le marteau de la Gravitation tourne autour de son
	## lanceur, et posée dans le monde, sa traînée se courbait quand il avançait.
	var frame: Node3D
	## [position dans le repère, âge en secondes], du plus vieux au plus jeune.
	var points: Array = []
	var _strip := ImmediateMesh.new()

	func _init() -> void:
		mesh = _strip
		cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	func _process(delta: float) -> void:
		for p: Array in points:
			p[1] += delta
		while not points.is_empty() and float(points[0][1]) > life:
			points.pop_front()
		if is_instance_valid(target) and target.is_inside_tree():
			add_point(target.get_global_transform_interpolated().origin - _base())
		elif points.is_empty():
			queue_free()
			return
		_build()

	func _base() -> Vector3:
		return frame.get_global_transform_interpolated().origin if is_instance_valid(frame) else Vector3.ZERO

	## Un point de plus, dans le repère, s'il s'est assez écarté du dernier.
	func add_point(at: Vector3) -> void:
		if points.is_empty() or (points.back()[0] as Vector3).distance_squared_to(at) > 0.25:
			points.append([at, 0.0])

	func _build() -> void:
		_strip.clear_surfaces()
		if points.size() < 2:
			return
		var camera := get_viewport().get_camera_3d()
		var base := _base()
		_strip.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		var along := 0.0
		for i in points.size():
			var p: Vector3 = points[i][0] + base
			var q: Vector3 = (points[maxi(i - 1, 0)][0] if i > 0 else points[1][0]) + base
			var dir := (p - q) if i > 0 else (q - p)
			along += p.distance_to(q) if i > 0 else 0.0
			var eye := (camera.global_position - p) if camera != null else Vector3.UP
			var left := clampf(1.0 - float(points[i][1]) / life, 0.0, 1.0)
			var side := dir.cross(eye).normalized() * width * (0.6 + 0.4 * left)
			for edge in [-1.0, 1.0]:
				_strip.surface_set_color(Color(1.0, 1.0, 1.0, left))
				_strip.surface_set_uv(Vector2(along / 70.0, 0.5 + edge * 0.5))
				_strip.surface_add_vertex(p + side * edge)
		_strip.surface_end()
