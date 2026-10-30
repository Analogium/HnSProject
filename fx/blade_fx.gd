class_name BladeFx
extends Node3D

## Le manuel du Vive lame en 3D (jalon 54, à la barre de Last Epoch) : l'acier du chevalier (`SteelFx`, ses
## textures reprises), en traits vifs. Choisi sur planche :
## - **la Frappe vive** : le couloir de la lame du départ à l'arrivée, trois lignes de vitesse, la poussière
##   soulevée au départ, et sur la cible une entaille debout face à la caméra ;
## - **le Coup de grâce** : la croix gravée de la 2D, deux entailles debout à la taille d'une cible, un éclat
##   au croisement, une gerbe de sang ; **le Point final**, l'étoile de huit fuseaux, longs et courts ;
## - **le couteau** : l'épée du modèle réduite, pointe en avant, une traînée courte ; **les lames plantées**,
##   les mêmes fichées en haut de la cible, manche relevé, du côté d'où elles sont venues ;
## - **la Frénésie** : une étoile rouge par charge, qui tourne autour du Vive lame ;
## - **la Garde** : deux croissants d'acier pâles qui tournent bas autour de lui — une aura reste sobre.
##
## Ce qui frappe se pose dans le monde et se libère seul ; ce qui dure vit sur son buff, qui le libère.

## La Frappe vive : le couloir, ses lignes de vitesse (écart, largeur), la poussière du départ.
const CORRIDOR := 12.0
const LINE_GAP := 6.0
const LINE_WIDTH := 2.5
const DUST := 9.0
const SWEEP := 0.05
const FADE := 0.3
## L'entaille sur la cible, debout à hauteur de corps. Sans l'air poussé : sur un sort lancé sans cesse, sa
## distorsion coûtait 1,4 ms l'image à 270 ennemis (jalon 54, §13).
const BODY := 14.0
const GASH := Vector2(34.0, 9.0)
const GASH_TURN := 0.75
## La croix du Coup de grâce : ses deux branches, la seconde un temps après, l'éclat au croisement, le sang.
const CROSS := Vector2(40.0, 11.0)
const CROSS_TURN := 0.8
const CROSS_GAP := 0.08
const CROSS_GLINT := 30.0
const BLOOD := 14.0
## L'étoile du Point final : ses rais, en part du rayon pour les courts.
const STAR_RAYS := 8
const STAR_SHORT := 0.6
const STAR_SWEEP := 0.06
const STAR_FADE := 0.25
## Le couteau, en part de l'épée du modèle (`SteelFx.SWORD_LENGTH`), et sa traînée.
const KNIFE := 0.55
const KNIFE_TRAIL := 2.5
const KNIFE_TRAIL_LIFE := 0.15
## Une lame plantée : en haut du corps (`PLANT_SHOULDER` de sa hauteur, `PLANT_HEIGHT` px sans modèle), au flanc d'où
## elle vient, enfoncée de `PLANT_DEPTH` px, le manche relevé de `PLANT_TILT`. Au flanc, à la taille du couteau en vol,
## on n'en voyait au zoom du jeu que quelques pixels blancs.
const PLANT := 0.8
const PLANT_SIDE := 6.0
const PLANT_SHOULDER := 0.7
const PLANT_HEIGHT := 18.0
const PLANT_DEPTH := 6.0
const PLANT_TILT := 0.9
const PLANT_FAN := 0.5
## Une lame qui lâche sa cible : sa chute jusqu'au sol, où elle reste fichée `DROP_STAY` s, puis s'enfonce de
## `DROP_SINK` px en `DROP_GONE` s.
const DROP_FALL := 0.25
const DROP_STAY := 1.2
const DROP_SINK := 10.0
const DROP_GONE := 0.4
## La Frénésie : une étoile par charge, son orbite, son tour, sa traînée.
const CHARGE := 9.0
const ORBIT := 13.0
const ORBIT_HEIGHT := 14.0
const ORBIT_SPIN := 2.2
const CHARGE_TRAIL := 2.0
## Cœur, milieu, profond : le sang, en lieu de la rampe de l'acier.
const BLOOD_RAMP := [Color(1.0, 0.42, 0.34), Color(0.82, 0.07, 0.05), Color(0.36, 0.01, 0.02)]
## La Garde : ses croissants, leur rayon, leur tour, leur éclat.
const GUARD := 18.0
const GUARD_HALF := 0.7
const GUARD_SPIN := 3.0
const GUARD_BOOST := 0.5

static var _materials := {}

var _buff: Buff
var _clock := 0.0
var _stars: Array[MeshInstance3D] = []


## Le dessin d'une frappe vive, de `from` à `landing`, la cible en `target`.
static func lunge(host: Node3D, from: Vector3, landing: Vector3, target: Vector3, nature := DamageType.Kind.PHYSICAL) -> void:
	SteelFx.cut(host, from, landing, nature, CORRIDOR, SWEEP, FADE)
	var along := (landing - from).normalized()
	var side := Flat.orthogonal(along).normalized()
	for k in 3:
		# Les lignes du bord partent après et s'arrêtent avant : le couloir les dépasse aux deux bouts.
		var outer := absf(k - 1.0)
		var off := side * (k - 1.0) * LINE_GAP
		SteelFx.cut(host, from + off + along * outer * 12.0, landing + off - along * outer * 6.0, nature,
				LINE_WIDTH, SWEEP + 0.015 * k, FADE - 0.02)
	SteelFx.dust(host, from, DUST)
	SteelFx.slit(host, target + Vector3.UP * BODY, nature, GASH_TURN, GASH.x, GASH.y, SWEEP, FADE)
	SteelFx.glint(host, target + Vector3.UP * BODY, nature)
	Sparks.burst(host, target, nature, 10, 7.0, Vector2(0.15, 0.4), Vector2(2.0, 5.0))


## La croix gravée du Coup de grâce sur sa cible, en `at`.
static func grace(host: Node3D, at: Vector3, nature: int) -> void:
	var crossing := at + Vector3.UP * BODY
	for i in 2:
		SteelFx.slit(host, crossing, nature, CROSS_TURN * (1.0 if i == 0 else -1.0), CROSS.x, CROSS.y,
				SWEEP, FADE, CROSS_GAP * i)
	# L'éclat attend sur un ancrage du viewport : le porteur peut partir avant lui.
	var mark := SteelFx.laid(host, crossing)
	mark.get_tree().create_timer(CROSS_GAP + SWEEP).timeout.connect(func() -> void:
		SteelFx.glint(mark, crossing, nature, CROSS_GLINT)
		mark.queue_free())
	Sparks.burst(host, at, nature, 12, 8.0, Vector2(0.15, 0.4), Vector2(2.0, 5.0))
	SteelFx.blast(host, at, BLOOD, true)


## L'étoile du Point final, en `at`, jusqu'à `radius`.
static func final_point(host: Node3D, at: Vector3, radius: float, nature: int) -> void:
	var turn := randf() * TAU
	for k in STAR_RAYS:
		var ray := Flat.from_angle(turn + TAU * k / STAR_RAYS)
		var long := k % 2 == 0
		SteelFx.cut(host, at + ray * 4.0, at + ray * radius * (1.0 if long else STAR_SHORT), nature,
				6.0 if long else 4.5, STAR_SWEEP, STAR_FADE)
	SteelFx.glint(host, at + Vector3.UP * ElementFx.LIFT, nature, CROSS_GLINT + 4.0)
	SteelFx.dust(host, at, radius * 0.8)
	SteelFx.warp(host, at, radius, nature)


## Le couteau sur son tir : l'épée réduite, sa pointe vers le -Z du nœud rendu, et sa traînée.
static func knife(host: Node3D, nature: int) -> Node3D:
	var shown := SteelFx.bare_sword(host)
	shown.scale = Vector3.ONE * KNIFE
	var trail := BoltFx.Trail.new()
	trail.material_override = SteelFx.trail_material(nature)
	trail.width = KNIFE_TRAIL
	trail.life = KNIFE_TRAIL_LIFE
	trail.target = shown
	host.get_viewport().add_child(trail)
	ElementFx.veil_like(trail, host)
	return shown


## La `i`-ième lame plantée sous `host` (enfant de la cible, haute de `height` px), venue en suivant `heading` :
## fichée en haut du corps, du côté d'où elle arrive, en éventail, le manche dehors — le parti pris de la 2D.
static func plant(host: Node3D, heading: Vector3, i: int, height := 0.0) -> Node3D:
	var pin := Node3D.new()
	host.add_child(pin)
	var fan := (i % 3 - 1) * PLANT_FAN
	var top := height * PLANT_SHOULDER if height > 0.0 else PLANT_HEIGHT
	pin.position = -Flat.rotated(heading, fan) * PLANT_SIDE + Vector3.UP * (top - (i / 3) * 3.0)
	pin.rotation = Vector3(-PLANT_TILT, -Flat.angle(heading) - PI * 0.5 + fan, 0.0)
	var shown := SteelFx.bare_sword(pin)
	shown.scale = Vector3.ONE * PLANT
	shown.position = Vector3.BACK * (SteelFx.SWORD_LENGTH * PLANT * 0.5 - PLANT_DEPTH)
	return pin


## Les lames plantées sous `knives` lâchent leur cible : chacune, refaite à la racine du viewport où elle était
## (le corps part avec ce qu'il porte), tombe pointe en bas jusqu'au sol, y reste fichée puis s'enfonce.
static func drop(knives: Node3D) -> void:
	for pin: Node3D in knives.get_children():
		var held := pin.get_child(0) as Node3D
		var fallen := SteelFx.bare_sword(knives.get_viewport())
		fallen.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		fallen.global_transform = held.global_transform
		ElementFx.veil_like(fallen, knives)
		# La pointe dans le sol, sous les pieds de la cible (le relief) : le centre de la lame s'arrête à sa
		# demi-longueur penchée au-dessus, moins ce qui s'enfonce.
		var tip_down := -fallen.global_basis.z.normalized().y
		var rest := knives.global_position.y \
				+ maxf(SteelFx.SWORD_LENGTH * PLANT * 0.5 * tip_down - PLANT_DEPTH * 0.5, 1.0)
		var tween := fallen.create_tween()
		tween.tween_property(fallen, ^"global_position:y", rest, DROP_FALL).set_ease(Tween.EASE_IN) \
				.set_trans(Tween.TRANS_QUAD)
		tween.tween_interval(DROP_STAY)
		tween.tween_property(fallen, ^"global_position:y", rest - DROP_SINK, DROP_GONE)
		tween.tween_callback(fallen.queue_free)


## La Frénésie sur son buff : une étoile par charge.
static func frenzy(buff: Buff) -> BladeFx:
	var fx := BladeFx.new()
	fx._buff = buff
	buff.add_child(fx)
	return fx


## La Garde sur son buff : deux croissants qui tournent.
static func guard(buff: Buff) -> BladeFx:
	var fx := BladeFx.new()
	buff.add_child(fx)
	ElementFx.veil_like(fx, buff)
	for k in 2:
		var arc := SteelFx.ribbon(fx, SteelFx.sector(-GUARD_HALF, GUARD_HALF, 0.75), DamageType.Kind.PHYSICAL, 0.0, 0.0)
		arc.set_instance_shader_parameter(&"head", 1.0)
		arc.set_instance_shader_parameter(&"boost", GUARD_BOOST)
		arc.scale = Vector3.ONE * GUARD
		arc.position.y = ElementFx.LIFT
		arc.rotation.y = PI * k
	return fx


func _process(delta: float) -> void:
	_clock += delta
	if _buff == null:
		rotation.y = -_clock * GUARD_SPIN
		return
	while _stars.size() < _buff.stacks:
		_stars.append(_star())
	while _stars.size() > _buff.stacks:
		_stars.pop_back().queue_free()
	for i in _stars.size():
		var a := _clock * ORBIT_SPIN + TAU * float(i) / float(_stars.size())
		_stars[i].position = Vector3(cos(a) * ORBIT, ORBIT_HEIGHT + sin(_clock * 3.0 + i) * 1.5, sin(a) * ORBIT)


func _star() -> MeshInstance3D:
	var star := MeshInstance3D.new()
	star.mesh = QuadMesh.new()
	star.material_override = blood_material(&"glint", SteelFx.glint_material(DamageType.Kind.PHYSICAL))
	star.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	star.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	star.scale = Vector3.ONE * CHARGE
	star.set_instance_shader_parameter(&"glow", 1.2)
	add_child(star)
	ElementFx.veil_like(star, _buff)
	# Dans le repère du Vive lame : posée dans le monde, la traînée se courbait quand il marchait.
	var trail := BoltFx.Trail.new()
	trail.material_override = blood_material(&"trail", SteelFx.trail_material(DamageType.Kind.PHYSICAL))
	trail.width = CHARGE_TRAIL
	trail.target = star
	trail.frame = self
	get_viewport().add_child(trail)
	ElementFx.veil_like(trail, _buff)
	return star


## `steel` à la rampe du sang, gardée sous `kind`.
static func blood_material(kind: StringName, steel: ShaderMaterial) -> ShaderMaterial:
	if not _materials.has(kind):
		var m: ShaderMaterial = steel.duplicate()
		for i in 3:
			var c: Color = BLOOD_RAMP[i]
			m.set_shader_parameter([&"heart", &"tint", &"deep"][i], Vector3(c.r, c.g, c.b))
		m.set_shader_parameter(&"core", Vector3(1.0, 0.6, 0.5))
		_materials[kind] = m
	return _materials[kind]
