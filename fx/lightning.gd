class_name Lightning
extends RefCounted

## La foudre du jeu, **dessinée** en un seul endroit : la chaîne, les éclairs du
## nuage, la charge statique, la traînée de la ruée et le projectile.
##
## Le **fil cerné**, choisi sur planche contre cinq autres (jalon 24) : un corps de
## trois pixels, un filament presque blanc au milieu, deux fourches courtes. Un
## éclair part dans n'importe quelle direction et change de forme dix-huit fois par
## seconde : il se **rastérise** à l'angle exact, une forme à la fois. Un saut, ses
## fourches et son éclat n'ont qu'une silhouette, donc un seul contour.

## Longueur d'un segment du trait brisé. Plus court, le trait devient une corde
## qui grésille ; plus long, une ligne droite qui a raté son virage.
const STEP := 9.0
const JITTER := 4.0

## Cadence du grésillement, en changements de forme par seconde. À 60 — une forme
## par image — l'œil ne voit plus un éclair mais du bruit.
const FLICKER_HZ := 18.0

## Le rayon du corps et celui d'une fourche : trois pixels, et un peu moins.
const BODY := 1.1
const FORK := 0.7
## Le filament, vers le blanc. Le violet plafonne à 0,63 de luminance : ce pixel
## est le seul de l'éclair qui passe le seuil de glow (0,9).
const CORE := 0.92
## Ce qu'un éclair perd de ses pixels sur son dernier tiers : il ne pâlit pas — un
## violet à demi transparent sort gris sur le sol —, il se défait.
const GONE := 0.5

## Le projectile, couché sur sa course : sa queue et sa tête, depuis le centre du tir.
const DART_TAIL := 13.0
const DART_HEAD := 7.0
## Les formes entre lesquelles un projectile grésille, fabriquées une fois par cap.
const DART_FORMS := 4

## Les bras de la charge statique. Chaque forme les tourne d'un sixième de leur
## écart : six formes bouclent sans saut.
const ARMS := 6
const CHARGE_FORMS := 6

const R_TINT := EffectForge.R_TINT
const R_CORE := EffectForge.R_CORE

static var _darts := {}
static var _charges := {}


## Un trait brisé à rastériser : ses sommets, son rayon, et s'il porte le filament.
class Stroke:
	var points: PackedVector2Array
	var radius: float
	var core: bool

	func _init(p_points: PackedVector2Array, p_radius: float, p_core: bool) -> void:
		points = p_points
		radius = p_radius
		core = p_core


## La graine qui tient une forme quelques images. Les appelants la combinent avec
## la leur : deux éclairs voisins ne doivent pas battre à l'unisson.
static func hold(age: float) -> int:
	return int(age * FLICKER_HZ)


## La part dissoute d'un éclair de cet âge : entier, puis défait sur son dernier tiers.
static func gone(age: float, life: float) -> float:
	return GONE if age > life * 2.0 / 3.0 else 0.0


## Un trait droit cassé en sommets déplacés au hasard.
static func path(
	a: Vector2, b: Vector2, rng: RandomNumberGenerator, jitter_amount := JITTER, step := STEP
) -> PackedVector2Array:
	var n := maxi(ceili(a.distance_to(b) / step), 2)
	var across := (b - a).orthogonal().normalized()
	var out := PackedVector2Array([a])
	for k in range(1, n):
		out.append(a.lerp(b, float(k) / float(n)) + across * rng.randf_range(-jitter_amount, jitter_amount))
	out.append(b)
	return out


## Une chaîne d'éclairs de sommet en sommet, en repère local, **une planche par
## saut** : d'une seule pièce, une chaîne en zigzag couvrait chaque rangée d'un bout
## à l'autre, et `to_image()` balayait le vide entre les sauts : 2,2 ms pour trois
## sauts, 1,3 découpée. `forks` compte les branches mortes de chaque saut, `struck` finit chaque saut
## par un éclat, `gone_part` est la part dissoute.
static func chain(
	points: PackedVector2Array, rng: RandomNumberGenerator, tint: Color,
	forks := 2, struck := true, gone_part := 0.0
) -> Array[EffectForge.Piece]:
	var out: Array[EffectForge.Piece] = []
	for i in points.size() - 1:
		var strokes: Array[Stroke] = []
		_bolt(strokes, points[i], points[i + 1], rng, forks)
		var end := PackedVector2Array([points[i + 1]]) if struck else PackedVector2Array()
		out.append(_bake(strokes, end, tint, gone_part))
	return out


## Du dernier saut au premier : l'éclat qui finit un saut se pose sur le départ du
## suivant et cache la jointure de leurs contours.
static func put(ci: CanvasItem, pieces: Array[EffectForge.Piece]) -> void:
	for i in range(pieces.size() - 1, -1, -1):
		pieces[i].put(ci, Vector2.ZERO)


## Le projectile au cap `turn` (`Slash.turn_of`), dans sa forme `form`.
static func dart(tint: Color, turn: int, form: int) -> Array[EffectForge.Piece]:
	var key := "%s|%d|%d" % [tint.to_html(false), turn, posmod(form, DART_FORMS)]
	if not _darts.has(key):
		var rng := RandomNumberGenerator.new()
		rng.seed = posmod(form, DART_FORMS)
		var facing := Vector2.from_angle(Slash.angle_of(turn))
		_darts[key] = chain(
			PackedVector2Array([-facing * DART_TAIL, facing * DART_HEAD]), rng, tint, 1
		)
	return _darts[key]


## La charge statique dans sa forme `form` : six bras en éclair qui vont jusqu'au
## rayon qui mord — le dessin dit où elle frappe, sinon on marche dedans sans
## l'avoir vue.
static func charge(tint: Color, radius: float, form: int, gone_part: float) -> EffectForge.Piece:
	var turn := posmod(form, CHARGE_FORMS)
	var key := "%s|%d|%d|%d" % [tint.to_html(false), int(radius), turn, int(round(gone_part * 16.0))]
	if not _charges.has(key):
		var rng := RandomNumberGenerator.new()
		rng.seed = turn
		var strokes: Array[Stroke] = []
		for i in ARMS:
			var angle := TAU * (float(i) + float(turn) / float(CHARGE_FORMS)) / float(ARMS)
			var tip := Vector2.from_angle(angle) * radius * rng.randf_range(0.75, 1.1)
			strokes.append(Stroke.new(path(Vector2.ZERO, tip, rng, 1.2, 3.5), FORK, true))
		_charges[key] = _bake(strokes, PackedVector2Array(), tint, gone_part)
	return _charges[key]


static func _bolt(
	strokes: Array[Stroke], a: Vector2, b: Vector2, rng: RandomNumberGenerator, forks: int
) -> void:
	var main := path(a, b, rng)
	strokes.append(Stroke.new(main, BODY, true))
	var span := a.distance_to(b)
	var along := (b - a).normalized() if span > 0.01 else Vector2.RIGHT
	for i in forks:
		var from_value: Vector2 = main[rng.randi_range(1, maxi(main.size() - 2, 1))]
		# La fourche repart de biais, parfois vers l'arrière : une branche qui
		# suit la trajectoire principale ne se voit pas.
		var away := along.rotated(rng.randf_range(0.5, 1.3) * (1.0 if rng.randf() < 0.5 else -1.0))
		var to := from_value + away * span * rng.randf_range(0.16, 0.34)
		strokes.append(Stroke.new(path(from_value, to, rng, JITTER * 0.7), FORK, false))


## Tous les corps d'abord, les filaments ensuite : une fourche posée après le trait
## principal lui mangerait son filament là où elle en part.
static func _bake(
	strokes: Array[Stroke], struck: PackedVector2Array, tint: Color, gone_part: float
) -> EffectForge.Piece:
	var box := Rect2(strokes[0].points[0], Vector2.ZERO)
	for s in strokes:
		for p in s.points:
			box = box.expand(p)
	var margin := Vector2.ONE * (float(EffectForge.STRIKE_SIZE / 2) + 2.0)
	var corner := (box.position - margin).floor()
	var size := (box.end + margin - corner).ceil()
	var canvas := PixelCanvas.new(int(size.x), int(size.y))
	for s in strokes:
		for j in s.points.size() - 1:
			canvas.capsule(s.points[j] - corner, s.points[j + 1] - corner, s.radius, R_TINT, Holy.LIT)
	for s in strokes:
		if s.core:
			for j in s.points.size() - 1:
				canvas.line(s.points[j] - corner, s.points[j + 1] - corner, R_CORE, 1.0)
	var half := Vector2i.ONE * (EffectForge.STRIKE_SIZE / 2)
	for at in struck:
		canvas.stamp(EffectForge.STRIKE, Vector2i((at - corner).round()) - half, EffectForge.INK)

	var img := canvas.to_image([ArtPalette.ramp(tint), ArtPalette.ramp(tint.lerp(Color.WHITE, CORE))])
	EffectForge.dissolve(img, gone_part)
	return EffectForge.Piece.new(ImageTexture.create_from_image(img), corner)
