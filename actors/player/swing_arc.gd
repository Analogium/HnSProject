class_name SwingArc
extends Node2D

## Trace du coup, **dessinée en pixels** et fabriquée au cap de la visée par
## `Slash` : la portée se règle en même temps que la hitbox. Se place sous
## l'AttackPivot, qui tourne avec la visée — le dessin, lui, défait cette rotation
## et prend le dessin fabriqué au cap le plus proche, parce qu'une planche tournée
## se rééchantillonne.
##
## Rien n'y pâlit — une lame à demi transparente sur un sol sombre sort grise. Le
## croissant finit en se résorbant, l'entaille et l'impact en se dissolvant.
##
## Le delta n'est volontairement pas dé-scalé : pendant le hit-stop, la lame se
## fige avec le reste du jeu.

## Le dessin, que la forme de la compétence choisit. La hitbox, elle, est la même
## pour les trois : chaque dessin reste dans sa capsule.
enum Style { ARC, STRIKE, CROSS }

## Bord extérieur de la lame. À garder proche de la portée de la hitbox
## (capsule décalée de 20 px, rayon 8 → 28 px de portée).
@export var outer_radius: float = 28.0
## Épaisseur maximale du croissant, atteinte au milieu de la traîne.
@export var thickness: float = 10.0
## Ouverture totale du balayage, en degrés.
@export var arc_degrees: float = 120.0
## Longueur de la traîne, en fraction de l'ouverture.
@export_range(0.1, 1.0) var trail_ratio: float = 0.5
## Moment où la traîne commence à se résorber dans la tête, en fraction de la durée.
@export_range(0.0, 1.0) var fade_start: float = 0.55
## La trace vit un peu plus longtemps que la hitbox : 0.12 s de fenêtre de coup
## ne fait que 7 images, trop peu pour que l'œil lise le balayage.
@export var duration_scale: float = 1.5
@export var color: Color = Color(1.0, 0.98, 0.85)

## La frappe lourde : un croissant plus épais, plus ouvert, plus lent, qui finit sur
## un impact. Sa lenteur est celle du dessin seulement — la hitbox garde la durée
## du coup, sinon le coup lourd deviendrait aussi un coup plus long.
const STRIKE_RADIUS := 30.0
const STRIKE_THICKNESS := 15.0
const STRIKE_OPENING := 150.0
const STRIKE_SLOWNESS := 1.3
const STRIKE_COLOR := Color(1.0, 0.85, 0.6)
## Le croissant occupe le début de la trace, l'impact commence avant qu'il ne
## finisse : un blanc entre les deux se lirait comme deux coups.
const STRIKE_CRESCENT_END := 0.6
const STRIKE_IMPACT_START := 0.45
## L'impact tombe au centre de la capsule de la hitbox.
const IMPACT := Vector2(20.0, 0.0)
const CRACKS := 5
## Les temps de l'impact, fabriqués à chaque frappe puisque ses fissures sont
## neuves à chaque coup. Quatre suffisent : il ne vit qu'une dizaine d'images.
const IMPACT_FRAMES := 4
## Le cadre de l'impact, en pixels, centré sur son point : l'onde y tient à son
## plus large (12 px), écrasée en hauteur.
const IMPACT_SIZE := Vector2i(34, 24)
## L'impact est posé **au sol** : une ellipse écrasée en hauteur, qui ne tourne pas
## avec la visée. Un cercle parfait traversé de fissures droites se lisait comme une
## roue à rayons.
const FLATTENED := Vector2(1.0, 0.55)
## Claires : sur le sol sombre des zones, des fissures et une poussière foncées ne
## se voyaient pas du tout à la capture.
const WAVE := Color(1.0, 0.92, 0.70)
const FISSURE := Color(0.85, 0.78, 0.62)
const DUST := Color(0.72, 0.66, 0.56)

## Le coup en croix : deux entailles droites en coordonnées du pivot, qui couvrent la
## capsule — de 6 à 30 pixels devant, 14 de part et d'autre.
const CROSS := [[Vector2(6.0, -14.0), Vector2(30.0, 14.0)], [Vector2(6.0, 14.0), Vector2(30.0, -14.0)]]
const CROSS_COLOR := Color(0.92, 0.96, 1.0)
## La demi-largeur d'une entaille, en son milieu.
const CROSS_WIDTH := 3.0
## Chaque entaille vit sur une fenêtre de la moitié de la trace ; la seconde part
## quand la première s'achève.
const CROSS_WINDOW := 0.5
const CROSS_OFFSET := 0.42
## Le moment où la seconde entaille passe sur la première, et l'éclat qui le marque.
const CROSS_CROSSING := 0.53
const CROSS_FLASH := 0.08

var _t := 1.0          # progression 0 → 1, 1 = terminé
var _duration := 0.12
var _flip := false     # un coup sur deux balaie dans l'autre sens
var _style := Style.ARC
## Chaque fissure est une ligne brisée, tirée au départ du coup.
var _cracks: Array[PackedVector2Array] = []
## Les temps de l'impact de la frappe en cours, fabriqués au premier besoin.
var _impacts: Array[EffectForge.Piece] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	visible = false
	set_process(false)
	_rng.seed = int(get_instance_id())


func play(duration: float, style := Style.ARC) -> void:
	_style = style
	_duration = maxf(duration * duration_scale * (STRIKE_SLOWNESS if style == Style.STRIKE else 1.0), 0.01)
	_t = 0.0
	_flip = not _flip
	if style == Style.STRIKE:
		# Des fissures neuves à chaque coup : les mêmes à chaque fois se liraient
		# comme un autocollant.
		_cracks.clear()
		for i in CRACKS:
			var d := Vector2.from_angle(TAU * float(i) / float(CRACKS) + _rng.randf_range(-0.4, 0.4))
			var length := _rng.randf_range(6.0, 11.0)
			var elbow := d * length * 0.5 + d.orthogonal() * _rng.randf_range(-1.8, 1.8)
			_cracks.append(PackedVector2Array([d * 2.5, elbow, d * length]))
		_impacts.clear()
		_impacts.resize(IMPACT_FRAMES)
	visible = true
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta / _duration
	if _t >= 1.0:
		_t = 1.0
		visible = false
		set_process(false)
	queue_redraw()


## Tout se pose dans le repère du monde : la rotation du pivot est défaite, et
## chaque position de visée est tournée à la main.
func _draw() -> void:
	if _t >= 1.0:
		return
	draw_set_transform(Vector2.ZERO, -global_rotation)
	match _style:
		Style.STRIKE:
			_draw_strike()
		Style.CROSS:
			_draw_cross()
		_:
			_crescent(_t, outer_radius, thickness, arc_degrees, color, 2.0)
	draw_set_transform(Vector2.ZERO, 0.0)


func _draw_strike() -> void:
	var t_arc := _t / STRIKE_CRESCENT_END
	if t_arc < 1.0:
		_crescent(t_arc, STRIKE_RADIUS, STRIKE_THICKNESS, STRIKE_OPENING, STRIKE_COLOR, 3.0)

	var k := (_t - STRIKE_IMPACT_START) / (1.0 - STRIKE_IMPACT_START)
	if k <= 0.0:
		return
	var center := IMPACT.rotated(global_rotation)
	var frame := mini(int(k * float(IMPACT_FRAMES)), IMPACT_FRAMES - 1)
	if _impacts[frame] == null:
		_impacts[frame] = _impact(frame)
	_impacts[frame].put(self, center)
	# L'éclat du choc, au tout début : c'est lui qui dit « ça a porté ».
	var burst := EffectForge.flashes(WAVE)
	var step := int(k * 4.0 * float(burst.size()))
	if step < burst.size():
		var side := Vector2.ONE * float(EffectForge.FLASH_SIZE)
		draw_texture_rect(burst[step], Rect2(EffectForge.snap(self, center - side * 0.5), side), false)


## Un temps de l'impact, **posé au sol** : une onde écrasée en hauteur qui ne tourne
## pas avec la visée, des fissures qui se tracent en un tiers de l'impact, et la
## poussière. Un cercle parfait traversé de fissures droites se lisait comme une
## roue à rayons.
func _impact(frame: int) -> EffectForge.Piece:
	var k := (float(frame) + 0.5) / float(IMPACT_FRAMES)
	var wave := 1.0 - pow(1.0 - k, 2.0)
	var canvas := PixelCanvas.new(IMPACT_SIZE.x, IMPACT_SIZE.y)
	var middle := Vector2(IMPACT_SIZE) * 0.5
	# L'onde : un anneau d'un pixel sur l'ellipse, dans le repère du sol.
	var reach := 3.0 + 9.0 * wave
	for i in 40:
		var p := middle + Vector2.from_angle(TAU * float(i) / 40.0) * reach * FLATTENED
		canvas.dot_px(int(p.x), int(p.y), 0, 0.9)
	var trace := minf(k * 3.0, 1.0)
	for f in _cracks:
		var reached := PackedVector2Array([f[0], f[0].lerp(f[1], trace), f[1].lerp(f[2], trace)])
		for j in 2:
			var a: Vector2 = middle + reached[j] * FLATTENED
			var b: Vector2 = middle + reached[j + 1] * FLATTENED
			var steps := maxi(int(a.distance_to(b) * 2.0), 1)
			for n in steps + 1:
				var p := a.lerp(b, float(n) / float(steps))
				canvas.dot_px(int(p.x), int(p.y), 1, 0.8)
	for i in 6:
		var p := middle + Vector2.from_angle(TAU * float(i) / 6.0 + 0.4) * (6.0 + 9.0 * wave) * FLATTENED
		canvas.disc(p, 1.4, 2, 0.2)
	var img := canvas.to_image([ArtPalette.ramp(WAVE), ArtPalette.ramp(FISSURE), ArtPalette.ramp(DUST)])
	# Il ne pâlit pas, il se dissout : sa dernière moitié part en damier.
	EffectForge.dissolve(img, clampf((k - 0.5) * 2.0, 0.0, 0.9))
	return EffectForge.Piece.new(ImageTexture.create_from_image(img), -middle)


func _draw_cross() -> void:
	var turn := Slash.turn_of(global_rotation)
	for i in CROSS.size():
		var u := (_t - CROSS_OFFSET * float(i)) / CROSS_WINDOW
		if u <= 0.0 or u >= 1.0:
			continue
		# Au temps près : une entaille fabriquée à chaque image ne se retrouverait
		# jamais dans le cache.
		u = (floorf(u * float(Slash.FRAMES)) + 0.5) / float(Slash.FRAMES)
		var a: Vector2 = CROSS[i][0]
		var b: Vector2 = CROSS[i][1]
		var head := minf(u / 0.45, 1.0)
		var tail := clampf((u - 0.3) / 0.7, 0.0, 1.0) * head
		if head - tail < 0.02:
			continue
		Slash.stroke(
			CROSS_COLOR, a.lerp(b, tail), a.lerp(b, head), CROSS_WIDTH, turn,
			smoothstep(0.55, 1.0, u)
		).put(self, Vector2.ZERO)
	var flash := 1.0 - absf(_t - CROSS_CROSSING) / CROSS_FLASH
	if flash > 0.0:
		var center: Vector2 = ((CROSS[0][0] + CROSS[0][1]) * 0.5).rotated(global_rotation)
		var burst := EffectForge.flashes(CROSS_COLOR)
		var step := clampi(int((1.0 - flash) * float(burst.size())), 0, burst.size() - 1)
		var side := Vector2.ONE * float(EffectForge.FLASH_SIZE)
		draw_texture_rect(burst[step], Rect2(EffectForge.snap(self, center - side * 0.5), side), false)


## Le croissant du balayage, à ces proportions. `t` va de 0 à 1 sur sa propre durée ;
## `curve` règle l'amorti — plus fort, la lame part plus vite et finit plus lourd.
##
## Le temps est arrondi à l'un des `Slash.FRAMES` temps du coup, et le cap à l'un
## des `Slash.TURNS` caps : c'est à ce prix qu'un coup ne fabrique rien qu'un coup
## précédent n'ait déjà fabriqué.
func _crescent(t: float, radius: float, thick: float, opening: float, tint: Color, curve: float) -> void:
	t = (floorf(t * float(Slash.FRAMES)) + 0.5) / float(Slash.FRAMES)
	var eased := 1.0 - pow(1.0 - t, curve)
	var total := deg_to_rad(opening)
	var head := -total * 0.5 + eased * total
	# La lame pleine ne se trame pas en finissant : sa traîne **se résorbe dans la
	# tête**, et le coup s'achève sur sa pointe. Tramée, la fin du coup ressemblait
	# à la traîne en damier écartée sur planche.
	var trail := total * trail_ratio * (1.0 - smoothstep(fade_start, 1.0, t))
	var tail := maxf(head - trail, -total * 0.5)
	if head - tail < 0.05:
		return
	var dir := -1.0 if _flip else 1.0
	Slash.crescent(
		tint, radius, thick, Slash.turn_of(global_rotation), tail * dir, head * dir, 0.0
	).put(self, Vector2.ZERO)
