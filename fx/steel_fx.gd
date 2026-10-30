class_name SteelFx
extends RefCounted

## Le manuel du chevalier en 3D (jalon 54, à la barre de Last Epoch) : l'acier. Une lame laisse **la trace
## de sa taille** — la traînée photographiée de Qwen-Image (`fx/steel_slash.png`) sur un ruban que la lame
## parcourt (`fx/steel_slash.gdshader`) : un croissant couché pour un coup de taille, debout pour la Frappe
## lourde, un X dressé face à la caméra pour la croix, un fuseau pour l'estoc, un couloir pour la ruée, un arc
## pour le bond ; la vague, un croissant net et ses traînées (`fx/steel_wave.gdshader`). Ce qui frappe le sol le dit en matière : une onde de poussière photographiée qui s'ouvre et se
## ronge (`fx/steel_dust.gdshader`), des mottes qui volent et retombent, un cratère en décal ; le fer qui
## mord jette des étincelles chaudes et un éclat sur l'acier (`fx/steel_glint.png`). L'acier n'éclaire pas :
## aucune lumière portée. Les épées de l'Épée spirale sont celles du modèle (`weapon_sword`).
##
## Tout se libère seul ; ce qui suit un corps (le tour du Cyclone, la vague, les épées) vit sous lui.

const SLASH := preload("res://fx/steel_slash.gdshader")
const WAVE := preload("res://fx/steel_wave.gdshader")
const DUST := preload("res://fx/steel_dust.gdshader")
const STREAK := preload("res://fx/steel_slash.png")
const DUST_BAND := preload("res://fx/steel_dust.png")
const CRATER := preload("res://fx/steel_crater.png")
const FURROW := preload("res://fx/steel_furrow.png")
const BLOOD := preload("res://fx/steel_blood.png")
const GLINT := preload("res://fx/steel_glint.png")
## Le modèle dont l'Épée spirale prend son épée : celle que tiennent les classes.
const SWORD_MODEL := "res://art/models/swiftblade.glb"

## Le croissant d'un coup de taille, de part et d'autre de la visée, en radians ; son bord intérieur, en
## part du rayon. La lame va au-delà du centre de la hitbox : son rayon de capsule.
const SWING_HALF := 1.1
const INNER := 0.3
const BLADE := 8.0
## La Frappe lourde, debout : de l'épaule arrière au sol devant, en radians autour de la visée.
const OVERHEAD := Vector2(1.9, -0.35)
const OVERHEAD_LIFT := 9.0
## Ce qui reste à ronger après le geste : la tête s'arrête au bout, l'arc entier reste allumé, puis se ronge
## (rongé pendant sa course, il ne se voyait pas).
const FADE := 0.25
## La croix, « X debout » choisi sur planche : deux entailles dressées face à la caméra — couchées, elles ne se
## lisaient en croix que sous certaines visées —, de cette longueur en part de l'allonge, à cet angle de la
## verticale, à cette hauteur ; l'éclat au croisement, quand la seconde a fini.
const CROSS_LENGTH := 1.4
const CROSS_WIDTH := 12.0
const CROSS_TURN := 0.8
const CROSS_LIFT := 14.0
const CROSS_GLINT := 30.0
## L'onde de poussière : son ouverture, sa vie, en secondes.
const DUST_OPEN := 0.25
const DUST_EATEN := Vector2(0.15, 0.7)
const WARP_LIFE := 0.25
const WARP_STRENGTH := 0.018
## Les mottes : leur nombre au rayon 30, leur taille en pixels, la pesanteur, leur vie.
const CLODS := 14
const CLOD_SIZE := Vector2(2.0, 4.5)
const GRAVITY := 420.0
const CLOD_LIFE := 0.9
## Le cratère, en diamètres du rayon : à 2,4, un autocollant qui débordait du coup.
const CRATER_SPAN := 1.6
const CRATER_LIFE := 1.6
const CRATER_FADE := 0.6
## L'éclat sur l'acier : sa taille au plus, sa vie.
const GLINT_SIZE := 22.0
const GLINT_LIFE := 0.22
## Les étincelles du fer qui mord : chaudes (du meulage), et non l'acier de la lame.
const SPARK_RAMP := [Color(1.0, 0.92, 0.65), Color(1.0, 0.55, 0.15), Color(0.55, 0.16, 0.04)]
## Le tour du Cyclone : deux traînées de lame qui se poursuivent, chacune sur un demi-tour, la pointe
## devant (pliées en éventails, trois lames sortaient en plumes) ; sa vitesse.
const WHIRL_BLADES := 2
const WHIRL_ARC := PI
const WHIRL_SPIN := 13.0
## Il tourne tout le combat : plus pâle qu'un coup, il sortait en éventails blancs.
const WHIRL_BOOST := 0.4
## La vague, « croissant et traînées » choisi sur planche : l'arc du croissant et son bord intérieur, la
## largeur des traînées de ses pointes ; son apparition et sa fin, en secondes.
const WAVE_HALF := 1.1
const WAVE_INNER := 0.45
const WAVE_TRAIL := 2.0
const WAVE_SHOW := 0.06
const WAVE_GONE := 0.15
## Une épée de la ronde, en pixels de long, et sa largeur forcée : à l'échelle, une lame de 3 px se perdait
## dans sa traînée.
const SWORD_LENGTH := 20.0
const SWORD_WIDEN := 2.2

static var _meshes := {}
static var _materials := {}
static var _sword: Array[Array] = []
static var _sword_fit := Transform3D.IDENTITY


## Le coup d'arme de `host` (la `SwingArc`, dont le x local est la visée) : `reach`, le centre de la hitbox ;
## `duration`, le temps du geste. La Frappe lourde jette aussi son impact. **Posé dans le monde** où et vers où
## le coup part : sous la visée, la trace, plus longue que le coup, tournait avec la souris une fois le coup fini.
static func swing(host: Node3D, nature: int, reach: float, duration: float, style: int) -> void:
	var at := laid(host, host.global_position)
	at.global_basis = host.global_basis
	var life := duration + FADE
	match style:
		SwingArc.Style.STRIKE:
			var arc := ribbon(at, sector(OVERHEAD.x, OVERHEAD.y), nature, duration * 0.6, FADE)
			arc.basis = Basis(Vector3.RIGHT, -PI * 0.5).scaled(Vector3.ONE * (reach + BLADE))
			arc.position.y = OVERHEAD_LIFT
			impact(host, at.to_global(Vector3.RIGHT * (reach + BLADE * 0.5)), nature, reach)
		SwingArc.Style.CROSS:
			var crossing := at.to_global(Vector3(reach, CROSS_LIFT, 0.0))
			for i in 2:
				var side := 1.0 if i == 0 else -1.0
				slit(host, crossing, nature, CROSS_TURN * side, (reach + BLADE) * CROSS_LENGTH, CROSS_WIDTH,
						duration * 0.3, FADE + duration * 0.3, duration * 0.3 * i)
			at.get_tree().create_timer(duration * 0.6).timeout.connect(
				func() -> void: glint(at, crossing, nature, CROSS_GLINT))
			life += duration * 0.3
		_:
			var arc := ribbon(at, sector(-SWING_HALF, SWING_HALF), nature, duration, FADE)
			arc.scale = Vector3.ONE * (reach + BLADE)
			arc.position.y = ElementFx.LIFT
	at.get_tree().create_timer(life + 0.05).timeout.connect(at.queue_free)


## Ce que mord un coup lourd, en `at` : étincelles, éclat, une bouffée de poussière et l'air poussé ; sur le
## sol (`ground`, le Brise-sol), le cratère et les mottes en plus.
static func impact(host: Node3D, at: Vector3, nature: int, radius: float, ground := false) -> void:
	Sparks.burst(host, at, nature, 10 + roundi(radius * 0.4), radius * 0.5, Vector2(0.2, 0.5), Vector2(2.0, 6.0))
	glint(host, at + Vector3.UP * ElementFx.LIFT * 0.6, nature)
	dust(host, at, radius * (1.1 if ground else 0.7))
	warp(host, at, radius, nature)
	if ground:
		crater(host, at, radius, CRATER)
		clods(host, at, radius)


## Une explosion d'acier, en `at` : la poussière, les mottes, les étincelles, l'air poussé. `blood` : la
## Gerbe de sang, un tué qui éclate en sang et non en poussière.
static func blast(host: Node3D, at: Vector3, radius: float, blood := false) -> void:
	if blood:
		crater(host, at, radius, BLOOD)
		clods(host, at, radius, _blood_material())
		return
	Sparks.burst(host, at, DamageType.Kind.PHYSICAL, 8 + roundi(radius * 0.3), radius * 0.5)
	dust(host, at, radius)
	clods(host, at, radius)
	warp(host, at, radius, DamageType.Kind.PHYSICAL)


## Un fuseau droit de `from` à `to` (l'estoc, la ruée, une entaille), à hauteur de lame : la tête le parcourt
## en `sweep`, puis il se ronge en `fade`.
static func cut(host: Node3D, from: Vector3, to: Vector3, nature: int, width: float, sweep: float, fade: float) -> void:
	var holder := laid(host, (from + to) * 0.5)
	var span := to - from
	var line := ribbon(holder, _strip(), nature, sweep, fade)
	line.basis = Basis(Vector3.UP, -Flat.angle(span)) * Basis.from_scale(Vector3(maxf(span.length(), 1.0), 1.0, width))
	line.position.y = ElementFx.LIFT
	holder.get_tree().create_timer(sweep + fade + 0.05).timeout.connect(holder.queue_free)


## Une entaille debout face à la caméra en `at`, tournée de `turn`, de `length` sur `width` (une branche de la
## croix, l'entaille du Vive lame) : la tête la parcourt en `sweep` après `delay`, puis elle se ronge en `fade`.
static func slit(
	host: Node3D, at: Vector3, nature: int, turn: float, length: float, width: float, sweep: float, fade: float,
	delay := 0.0
) -> void:
	var face := laid(host, at)
	var camera := host.get_viewport().get_camera_3d()
	if camera != null:
		face.global_basis = camera.global_basis
	var cut := ribbon(face, _strip(), nature, sweep, fade, delay)
	cut.basis = Basis(Vector3.BACK, turn) * Basis(Vector3.RIGHT, PI * 0.5) * Basis.from_scale(Vector3(length, 1.0, width))
	face.get_tree().create_timer(delay + sweep + fade + 0.05).timeout.connect(face.queue_free)


## Une croix brève en `at`, de `size` pixels : la ruée qui taille ce qu'elle traverse.
static func nick(host: Node3D, at: Vector3, nature: int, size: float) -> void:
	var holder := laid(host, at)
	var turn := randf() * TAU
	for i in 2:
		var line := ribbon(holder, _strip(), nature, 0.05, 0.16, 0.04 * i)
		line.basis = Basis(Vector3.UP, turn + PI * 0.5 * i) * Basis.from_scale(Vector3(size, 1.0, size * 0.3))
		line.position.y = ElementFx.LIFT
	holder.get_tree().create_timer(0.3).timeout.connect(holder.queue_free)


## L'arc du bond, de `from` à `to` : un ruban couché qui suit la course en l'air, puis se ronge.
static func arch(host: Node3D, from: Vector3, to: Vector3, nature: int, width: float) -> void:
	var holder := laid(host, from)
	var span := to - from
	var height := minf(span.length() * 0.35, 40.0)
	var side := Flat.orthogonal(span).normalized() if span.length() > 0.1 else Vector3.FORWARD
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var steps := 16
	for i in steps + 1:
		var k := float(i) / float(steps)
		var p := span * k + Vector3.UP * (height * 4.0 * k * (1.0 - k) + ElementFx.LIFT)
		for edge in [0.0, 1.0]:
			st.set_uv(Vector2(k, lerpf(0.05, 0.95, edge)))
			st.add_vertex(p + side * width * (edge - 0.5))
	ribbon(holder, st.commit(), nature, 0.12, 0.35)
	dust(host, from, width * 2.0)
	holder.get_tree().create_timer(0.55).timeout.connect(holder.queue_free)


## Le sillon que laisse une vague (le Sillon d'acier), de `from` à `to`, `life` secondes : la terre fendue en
## décal, qui s'efface à la fin.
static func furrow(host: Node3D, from: Vector3, to: Vector3, width: float, life: float) -> void:
	var span := to - from
	var holder := laid(host, (from + to) * 0.5)
	var scar := Decal.new()
	scar.texture_albedo = FURROW
	scar.upper_fade = 0.5
	scar.lower_fade = 0.2
	scar.size = Vector3(span.length() + width, 8.0, width * 2.0)
	scar.rotation.y = -Flat.angle(span)
	holder.add_child(scar)
	ElementFx.veil_like(scar, host)
	var veil := scar.modulate.a
	var tween := holder.create_tween()
	tween.tween_method(func(t: float) -> void:
		scar.modulate.a = veil * smoothstep(0.0, 0.1, t) * (1.0 - smoothstep(life - CRATER_FADE, life, t)), 0.0, life, life)
	tween.tween_callback(holder.queue_free)


## Le tour du Cyclone (et d'un Derviche) sous `host`, à ce rayon : des lames qui tournent, la poussière à ses
## pieds. Il vit sous son porteur ; `let_go()` le ronge.
static func whirl(host: Node3D, nature: int, radius: float) -> Whirl:
	var fx := Whirl.new()
	host.add_child(fx)
	for i in WHIRL_BLADES:
		var blade := ribbon(fx, sector(-WHIRL_ARC * 0.5, WHIRL_ARC * 0.5), nature, 0.0, 0.0)
		blade.set_instance_shader_parameter(&"head", 1.0)
		blade.set_instance_shader_parameter(&"boost", WHIRL_BOOST)
		blade.rotation.y = TAU * float(i) / float(WHIRL_BLADES)
		blade.position.y = ElementFx.LIFT * (0.7 + 0.3 * float(i % 2))
		fx.blades.append(blade)
	fx.floor_dust = IceNovaFx.flat(fx, dust_material(), 1.0, DangerZone.LIFT + 0.5)
	fx.floor_dust.set_instance_shader_parameter(&"front", 0.95)
	fx.floor_dust.set_instance_shader_parameter(&"width", 0.35)
	fx.floor_dust.set_instance_shader_parameter(&"dissolve", 0.3)
	for node in fx.find_children("*", "GeometryInstance3D", true, false):
		ElementFx.veil_like(node, host)
	fx.resize(radius)
	return fx


## La vague qui vole, sous `host` (la `SlashWave`), à ce rayon : un croissant net, et une traînée de chaque
## pointe.
static func wave(host: Node3D, nature: int, radius: float) -> MeshInstance3D:
	var arc := MeshInstance3D.new()
	arc.mesh = sector(-WAVE_HALF, WAVE_HALF, WAVE_INNER, Vector2(0.0, 1.0))
	arc.material_override = wave_material(nature)
	arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arc.set_instance_shader_parameter(&"dissolve", 1.0)
	host.add_child(arc)
	ElementFx.veil_like(arc, host)
	arc.scale = Vector3.ONE * radius
	arc.position.y = ElementFx.LIFT
	for side in [-1.0, 1.0]:
		var tip := Node3D.new()
		arc.add_child(tip)
		tip.position = Vector3(cos(WAVE_HALF), 0.0, side * sin(WAVE_HALF))
		var trail := BoltFx.Trail.new()
		trail.material_override = trail_material(nature)
		trail.width = WAVE_TRAIL
		trail.target = tip
		host.get_viewport().add_child(trail)
		ElementFx.veil_like(trail, host)
	var tween := arc.create_tween()
	tween.tween_method(func(t: float) -> void: arc.set_instance_shader_parameter(&"dissolve", 1.0 - t), 0.0, 1.0, WAVE_SHOW)
	return arc


## Ce qui suivait un corps parti (la vague au bout de sa course) : laissé où il est, rongé, libéré.
static func release(node: GeometryInstance3D, gone := WAVE_GONE) -> void:
	if not is_instance_valid(node) or not node.is_inside_tree():
		return
	node.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	node.reparent(node.get_viewport())
	var tween := node.create_tween()
	tween.tween_method(func(t: float) -> void: node.set_instance_shader_parameter(&"dissolve", t), 0.0, 1.0, gone)
	tween.tween_callback(node.queue_free)


## Une épée de la ronde ou de la volée, sous `parent` : le modèle, et sa traînée posée dans `frame` (la
## ronde tourne autour de son porteur ; posée dans le monde, la traînée se courbait quand il marchait). Sa
## pointe va vers le -Z du nœud rendu, le plat vers le ciel.
static func sword(parent: Node3D, host: Node3D, nature: int, frame: Node3D = null) -> Node3D:
	var holder := bare_sword(parent)
	holder.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var trail := BoltFx.Trail.new()
	trail.material_override = trail_material(nature)
	trail.width = 2.5
	trail.target = holder
	trail.frame = frame
	host.get_viewport().add_child(trail)
	ElementFx.veil_like(trail, host)
	return holder


## L'épée du modèle seule, à `SWORD_LENGTH`, sous `parent` : pointe vers -Z, le plat vers le ciel. Les couteaux
## du Vive lame la réduisent (`BladeFx`).
static func bare_sword(parent: Node) -> Node3D:
	var holder := Node3D.new()
	parent.add_child(holder)
	for part: Array in sword_parts():
		var body := MeshInstance3D.new()
		body.mesh = part[0]
		body.transform = _sword_fit * (part[1] as Transform3D)
		body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(body)
	return holder


## Les pièces de l'épée du modèle des classes (lame, garde, poignée : des volumes de Blender), chacune
## [maillage, repère sous la poignée], gardées ; et ce qui la met à `SWORD_LENGTH`, centrée. Le glTF couche
## déjà la lame le long de -Z, le plat vers +Y (le +Y de Blender).
static func sword_parts() -> Array[Array]:
	if _sword.is_empty():
		var model := (load(SWORD_MODEL) as PackedScene).instantiate()
		var held: Node3D = model.find_child("weapon_sword", true, false)
		var span := AABB()
		for node in held.find_children("*", "MeshInstance3D", true, false):
			var at := Transform3D.IDENTITY
			var up: Node = node
			while up != held:
				at = (up as Node3D).transform * at
				up = up.get_parent()
			var mesh := (node as MeshInstance3D).mesh
			_sword.append([mesh, at])
			span = (at * mesh.get_aabb()) if _sword.size() == 1 else span.merge(at * mesh.get_aabb())
		model.free()
		var scale := SWORD_LENGTH / maxf(span.size.z, 0.0001)
		var fit := Basis.from_scale(Vector3(scale * SWORD_WIDEN, scale, scale))
		_sword_fit = Transform3D(fit, -(fit * span.get_center()))
	return _sword


## Une lame qui mord ce qu'elle traverse (une épée de la volée ou de l'escorte) : un éclat, quelques étincelles.
static func bite(host: Node3D, at: Vector3, nature: int) -> void:
	glint(host, at + Vector3.UP * ElementFx.LIFT, nature, GLINT_SIZE * 0.7)
	Sparks.burst(host, at, nature, 6, 6.0, Vector2(0.15, 0.35), Vector2(2.0, 5.0))


## L'éclat bref sur l'acier, tourné vers la caméra.
static func glint(host: Node3D, at: Vector3, nature: int, size := GLINT_SIZE) -> void:
	var flare := MeshInstance3D.new()
	flare.mesh = QuadMesh.new()
	flare.material_override = glint_material(nature)
	flare.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flare.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	host.get_viewport().add_child(flare)
	flare.global_position = at
	flare.rotation.z = randf() * TAU
	ElementFx.veil_like(flare, host)
	var tween := flare.create_tween()
	tween.tween_method(func(t: float) -> void:
		var f := t / GLINT_LIFE
		flare.scale = Vector3.ONE * size * (0.5 + 0.5 * ease(f, 0.3))
		flare.set_instance_shader_parameter(&"glow", pow(1.0 - f, 2.0)), 0.0, GLINT_LIFE, GLINT_LIFE)
	tween.tween_callback(flare.queue_free)


## L'onde de poussière couchée en `at`, jusqu'à `radius`.
static func dust(host: Node3D, at: Vector3, radius: float) -> void:
	var holder := laid(host, at)
	var ring := IceNovaFx.flat(holder, dust_material(), radius, DangerZone.LIFT + 0.5)
	ring.rotation.y = randf() * TAU
	ElementFx.veil_like(ring, host)
	var life := DUST_EATEN.y
	var tween := holder.create_tween()
	tween.tween_method(func(t: float) -> void:
		var front := ease(clampf(t / DUST_OPEN, 0.0, 1.0), 0.4)
		ring.set_instance_shader_parameter(&"front", 0.3 + 0.65 * front)
		ring.set_instance_shader_parameter(&"width", 0.3 + 0.45 * front)
		ring.set_instance_shader_parameter(&"clock", t)
		ring.set_instance_shader_parameter(&"dissolve", smoothstep(DUST_EATEN.x, DUST_EATEN.y, t)), 0.0, life, life)
	tween.tween_callback(holder.queue_free)


## L'air poussé par le coup, sur son front.
static func warp(host: Node3D, at: Vector3, radius: float, nature: int) -> void:
	var holder := laid(host, at)
	var air := IceNovaFx.flat(holder, IceNovaFx.material(IceNovaFx.WARP, nature), radius * 1.4, DangerZone.LIFT + 0.8)
	ElementFx.veil_like(air, host)
	var tween := holder.create_tween()
	tween.tween_method(func(t: float) -> void:
		air.set_instance_shader_parameter(&"front", lerpf(0.15, 0.9, ease(clampf(t / DUST_OPEN, 0.0, 1.0), 0.4)))
		air.set_instance_shader_parameter(&"strength", WARP_STRENGTH * (1.0 - smoothstep(0.05, WARP_LIFE, t))),
		0.0, WARP_LIFE, WARP_LIFE)
	tween.tween_callback(holder.queue_free)


## Le sol frappé en décal (`texture`, le cratère ou le sang), qui épouse le relief et s'efface.
static func crater(host: Node3D, at: Vector3, radius: float, texture: Texture2D) -> void:
	var holder := laid(host, at)
	var mark := Decal.new()
	mark.texture_albedo = texture
	mark.upper_fade = 0.5
	mark.lower_fade = 0.2
	mark.size = Vector3(radius * CRATER_SPAN, 8.0, radius * CRATER_SPAN)
	mark.rotation.y = randf() * TAU
	holder.add_child(mark)
	ElementFx.veil_like(mark, host)
	var veil := mark.modulate.a
	var tween := holder.create_tween()
	tween.tween_method(func(t: float) -> void:
		mark.modulate.a = veil * (1.0 - smoothstep(CRATER_LIFE - CRATER_FADE, CRATER_LIFE, t)), 0.0, CRATER_LIFE, CRATER_LIFE)
	tween.tween_callback(holder.queue_free)


## Des mottes de terre qui jaillissent de `at` et retombent, éclairées comme le sol.
static func clods(host: Node3D, at: Vector3, radius: float, m: Material = null) -> void:
	var holder := laid(host, at)
	var count := clampi(roundi(CLODS * sqrt(radius / 30.0)), 6, 30)
	var lumps := IceNovaFx.multimesh(holder, _pebble(), count, m if m != null else _clod_material())
	ElementFx.veil_like(lumps, host)
	var flights: Array[Clod] = []
	for i in count:
		var h := randf() * TAU
		var out := radius * randf_range(1.2, 3.2)
		var clod := Clod.new()
		clod.speed = Vector3(cos(h) * out, randf_range(70.0, 150.0), sin(h) * out)
		clod.turn = Basis(Vector3(randf(), randf(), randf()).normalized(), randf() * TAU)
		clod.size = randf_range(CLOD_SIZE.x, CLOD_SIZE.y)
		clod.spin = randf_range(-12.0, 12.0)
		flights.append(clod)
	var tween := holder.create_tween()
	tween.tween_method(func(t: float) -> void:
		for i in count:
			lumps.multimesh.set_instance_transform(i, flights[i].at(t)),
		0.0, CLOD_LIFE, CLOD_LIFE)
	tween.tween_callback(holder.queue_free)


## Un ruban de `mesh` sous `parent`, que la tête parcourt de 0 au bout en `sweep` après `delay`, puis qui se
## ronge en `fade`. Sans `sweep`, il reste tel quel : son porteur le règle.
static func ribbon(parent: Node3D, mesh: Mesh, nature: int, sweep: float, fade: float, delay := 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = slash_material(nature)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.set_instance_shader_parameter(&"head", -1.0)
	parent.add_child(node)
	ElementFx.veil_like(node, parent)
	if sweep <= 0.0:
		return node
	var tween := node.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_method(func(t: float) -> void:
		node.set_instance_shader_parameter(&"head", ease(clampf(t / sweep, 0.0, 1.0), 0.5))
		node.set_instance_shader_parameter(&"clock", t)
		node.set_instance_shader_parameter(&"dissolve", smoothstep(sweep, sweep + fade, t)),
		0.0, sweep + fade, sweep + fade)
	tween.tween_callback(node.queue_free)
	return node


## Posé à la racine du viewport en `at` : ce qui reste où le coup a porté.
static func laid(host: Node3D, at: Vector3) -> Node3D:
	var holder := Node3D.new()
	holder.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	host.get_viewport().add_child(holder)
	holder.global_position = at
	# Ce qui naît dessous prend son voile (`_ribbon`).
	ElementFx.veil_like(holder, host)
	return holder


## Un croissant de rayon 1 couché autour de +X, de `from` à `to` (UV.x le long, la tête au bout), son bord
## intérieur à `inner` ; UV.y va de `rows.x` (dedans) à `rows.y` (dehors) : pour la traînée, la photo y met sa
## ligne claire près du bord extérieur, là où la pointe de la lame passe le plus vite.
static func sector(from: float, to: float, inner := INNER, rows := Vector2(0.95, 0.3)) -> ArrayMesh:
	var key := "sector %s %s %s %s" % [from, to, inner, rows]
	if not _meshes.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		var steps := 32
		for i in steps + 1:
			var k := float(i) / float(steps)
			var a := lerpf(from, to, k)
			for edge: Array in [[inner, rows.x], [1.0, rows.y]]:
				st.set_uv(Vector2(k, edge[1]))
				st.add_vertex(Vector3(cos(a), 0.0, sin(a)) * float(edge[0]))
		_meshes[key] = st.commit()
	return _meshes[key]


## Une entaille droite de côté 1, le long de x, centrée.
static func _strip() -> ArrayMesh:
	if not _meshes.has("strip"):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		for x in [-0.5, 0.5]:
			for z in [-0.5, 0.5]:
				st.set_uv(Vector2(x + 0.5, lerpf(0.05, 0.95, z + 0.5)))
				st.add_vertex(Vector3(x, 0.0, z))
		_meshes["strip"] = st.commit()
	return _meshes["strip"]


## Une motte : une boule à pans, de diamètre 1.
static func _pebble() -> Mesh:
	if not _meshes.has("pebble"):
		var ball := SphereMesh.new()
		ball.radius = 0.5
		ball.height = 0.8
		ball.radial_segments = 5
		ball.rings = 3
		_meshes["pebble"] = ball
	return _meshes["pebble"]


static func slash_material(nature: int) -> ShaderMaterial:
	return _kept("slash", nature, func() -> ShaderMaterial:
		return HolyBlastFx.ramped(SLASH, STREAK, nature) if nature == DamageType.Kind.HOLY \
				else BoltFx.ramped(SLASH, STREAK, nature))


static func wave_material(nature: int) -> ShaderMaterial:
	return _kept("wave", nature, func() -> ShaderMaterial: return BoltFx.ramped(WAVE, STREAK, nature))


static func trail_material(nature: int) -> ShaderMaterial:
	return _kept("trail", nature, func() -> ShaderMaterial:
		var m := BoltFx.ramped(BoltFx.TRAIL, STREAK, nature)
		m.set_shader_parameter(&"boost", 0.7)
		return m)


static func glint_material(nature: int) -> ShaderMaterial:
	return _kept("glint", nature, func() -> ShaderMaterial:
		return BoltFx.ramped(HolyBlastFx.FLARE_SHADER, GLINT, nature))


static func dust_material() -> ShaderMaterial:
	return _kept("dust", 0, func() -> ShaderMaterial:
		var m := ShaderMaterial.new()
		m.shader = DUST
		m.set_shader_parameter(&"dust", DUST_BAND)
		return m)


static func _clod_material() -> Material:
	return _kept("clod", 0, func() -> Material:
		var m := StandardMaterial3D.new()
		# Plus sombre que le sol : de sa couleur, elles ne se voyaient pas.
		m.albedo_color = Color(0.28, 0.21, 0.15)
		m.roughness = 1.0
		return m)


static func _blood_material() -> Material:
	return _kept("blood", 0, func() -> Material:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.38, 0.03, 0.03)
		m.roughness = 0.35
		return m)


## Une matière par sorte et par nature, gardée : fabriquée à chaque coup, elle repartait au GPU.
static func _kept(kind: String, nature: int, make: Callable) -> Material:
	var key := "%s@%d" % [kind, nature]
	if not _materials.has(key):
		_materials[key] = make.call()
	return _materials[key]


## Une motte en vol ; publique pour les tests, le moteur sans rendu ne relit pas un `MultiMesh`.
class Clod:
	var speed: Vector3
	var turn: Basis
	var size := 1.0
	var spin := 0.0

	## Où elle est à `t` secondes : retombée, elle reste où elle touche le sol, puis rapetisse.
	func at(t: float) -> Transform3D:
		var landed := maxf(speed.y * 2.0 / GRAVITY, 0.0)
		var flown := minf(t, landed)
		var p := speed * flown + Vector3.DOWN * GRAVITY * 0.5 * flown * flown
		var shrink := 1.0 - smoothstep(CLOD_LIFE - 0.25, CLOD_LIFE, t)
		return Transform3D((turn * Basis(Vector3.UP, spin * flown)).scaled(Vector3.ONE * size * shrink), p)


## Le tour du Cyclone : il tourne à l'image, hors de l'interpolation, sous son porteur.
## Il tourne au pas de physique, interpolé comme le corps qu'il emporte (`body`, le joueur sous le
## Cyclone) : tournés à l'image chacun de leur côté, l'épée et la tête de la traînée se décalaient.
class Whirl extends Node3D:
	var blades: Array[MeshInstance3D] = []
	var floor_dust: MeshInstance3D
	## Le corps qui tourne avec lui, l'épée à la tête de la première traînée (son +Z) ; null sinon.
	var body: Node3D
	## Sa vitesse, en part de `WHIRL_SPIN` : la vitesse d'attaque du porteur sous le Cyclone.
	var pace := 1.0
	var _clock := 0.0

	func resize(radius: float) -> void:
		for blade in blades:
			blade.scale = Vector3.ONE * radius
		floor_dust.scale = Vector3.ONE * radius * 1.1

	func _physics_process(delta: float) -> void:
		rotation.y = wrapf(rotation.y - WHIRL_SPIN * pace * delta, -PI, PI)
		if is_instance_valid(body):
			body.rotation.y = rotation.y

	func _process(delta: float) -> void:
		_clock += delta
		for blade in blades:
			blade.set_instance_shader_parameter(&"clock", _clock)
		floor_dust.set_instance_shader_parameter(&"clock", _clock)

	## Le porteur éteint : laissé où il est, rongé, libéré.
	func let_go() -> void:
		for node: GeometryInstance3D in blades + [floor_dust]:
			SteelFx.release(node)
		queue_free()
