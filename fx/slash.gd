class_name Slash
extends RefCounted

## Les fuseaux et le couteau du Vive lame en 2D (jalons 46 et 50) ; le manuel du chevalier
## se dessine en 3D depuis le jalon 54 (`SteelFx`).
##
## **Tout ce manuel pivote**, et une planche ne pivote pas — tournée, elle se
## rééchantillonne et ses blocs de deux pixels se brisent. Chaque forme est donc
## **fabriquée au cap où on la demande**, une fois, et gardée : les formes
## géométriques se rastérisent à ce cap, l'épée dessinée à la main s'y tourne.
## Le premier coup dans une direction paie la fabrication, les suivants rien.

## Trente-deux caps, un tous les 11,25° : à seize, un croissant de 120° tombait
## visiblement à côté de la visée.
const TURNS := 32
## Le blanc du fil de la lame.
const EDGE := Color(1.0, 1.0, 1.0)
const EDGE_MIX := 0.7

const R_TINT := EffectForge.R_TINT
const R_EDGE := EffectForge.R_CORE

const STEEL := Color(0.80, 0.84, 0.92)
const GOLD := Color(0.86, 0.68, 0.30)
const LEATHER := Color(0.40, 0.26, 0.16)
## L'acier sur trois tons, l'or, le cuir.
const SWORD_INK := {
	"b": [0, 2], "c": [0, 3], "d": [0, 4], "g": [1, 3], "G": [1, 4], "h": [2, 2],
}

static var _pieces := {}


## Le cap le plus proche d'un angle.
static func turn_of(angle: float) -> int:
	return posmod(int(round(angle / (TAU / float(TURNS)))), TURNS)


static func angle_of(turn: int) -> float:
	return TAU * float(turn) / float(TURNS)


## Une entaille **à l'angle exact**, de l'origine à `to`, fabriquée pour un seul
## geste et **jamais gardée** : celle d'une Ruée tranchante court sur toute la
## traversée, et à cent pixels, arrondir son cap de 5° la ferait finir à dix
## pixels du joueur. Chaque ruée a la sienne, donc la garder ne ferait que remplir
## la mémoire.
static func cleave(tint: Color, to: Vector2, half_width: float) -> EffectForge.Piece:
	return _spindle(tint, Vector2.ZERO, to, half_width, 0.0)


static func _spindle(
	tint: Color, a: Vector2, b: Vector2, half_width: float, gone: float
) -> EffectForge.Piece:
	var margin := half_width + 2.0
	var corner := Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2(margin, margin)
	var size := (Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2(margin, margin) - corner).ceil()
	var canvas := PixelCanvas.new(int(size.x), int(size.y))
	_spindle_into(canvas, corner, a, b, half_width)
	return _bake(canvas, tint, gone, corner)


## Le fuseau de `a` à `b` peint sur `canvas`, dont le coin est en `corner` : l'étoile du
## Point final en pose huit sur une seule toile.
static func _spindle_into(
	canvas: PixelCanvas, corner: Vector2, a: Vector2, b: Vector2, half_width: float
) -> void:
	var along := b - a
	var length_sq := maxf(along.length_squared(), 0.0001)
	# Une entaille en biais n'occupe qu'une bande de son cadre : chaque rangée ne
	# balaie que l'étendue où le fuseau peut passer, pas le cadre entier — et seulement
	# les rangées et colonnes de son propre cadre, quand la toile en porte plusieurs.
	var reach := half_width / maxf(absf(along.normalized().y), 0.05) + 1.0
	var top := maxi(int(minf(a.y, b.y) - half_width - corner.y) - 1, 0)
	var bottom := mini(int(maxf(a.y, b.y) + half_width - corner.y) + 2, canvas.height)
	var left := maxi(int(minf(a.x, b.x) - half_width - corner.x) - 1, 0)
	var right := mini(int(maxf(a.x, b.x) + half_width - corner.x) + 2, canvas.width)
	for y in range(top, bottom):
		var row := float(y) + corner.y
		var lo := left
		var hi := right
		if absf(along.y) > 0.5:
			var at := a.x + along.x * (row - a.y) / along.y - corner.x
			lo = maxi(int(at - reach) - 1, left)
			hi = mini(int(at + reach) + 2, right)
		for x in range(lo, hi):
			var p := Vector2(x, y) + corner - a
			var s := clampf(p.dot(along) / length_sq, 0.0, 1.0)
			var off := (p - along * s).length()
			var width := half_width * sin(PI * s)
			if off > width:
				continue
			if off < 0.8:
				canvas.dot_px(x, y, R_EDGE, 1.0)
			else:
				canvas.dot_px(x, y, R_TINT, 0.85 - 0.4 * off / maxf(width, 0.1))


## L'éclat du Point final (jalon 50, « étoile de fuseaux » choisie sur planche) : huit
## fuseaux, longs et courts alternés, écartés des axes, qui jaillissent du cœur jusqu'au
## rayon en `BURST_STEPS` temps ; le dernier se dissout. Fabriqué par rayon et gardé.
const BURST_RAYS := 8
const BURST_STEPS := 4
const BURST_TILT := 0.2
const BURST_SHORT := 0.6
const BURST_WIDTH := 1.6


static func burst(tint: Color, radius: float, step: int) -> EffectForge.Piece:
	var key := "b%s|%d|%d" % [tint.to_html(false), int(radius), step]
	if _pieces.has(key):
		return _pieces[key]
	var reach := radius * (0.35 + 0.65 * float(step) / float(BURST_STEPS - 1))
	var side := int(ceil(radius + BURST_WIDTH + 2.0))
	var canvas := PixelCanvas.new(side * 2 + 1, side * 2 + 1)
	var corner := -Vector2(side, side)
	for k in BURST_RAYS:
		var d := Vector2.from_angle(TAU * float(k) / float(BURST_RAYS) + BURST_TILT)
		var length := reach * (1.0 if k % 2 == 0 else BURST_SHORT)
		_spindle_into(canvas, corner, d * 3.0, d * length, BURST_WIDTH)
	var piece := _bake(canvas, tint, 0.5 if step == BURST_STEPS - 1 else 0.0, corner)
	_pieces[key] = piece
	return piece


## Le couteau des Lames de jet (jalon 50, « couteau droit » choisi sur planche), au cap
## `turn` et centré : fabriqué à son cap comme l'épée, et gardé.
static func knife(turn: int) -> EffectForge.Piece:
	var key := "k%d" % turn
	if _pieces.has(key):
		return _pieces[key]
	var grid := EffectForge.rotated(EffectForge.KNIFE, angle_of(turn))
	var side: int = grid.size()
	var canvas := PixelCanvas.new((grid[0] as String).length(), side)
	canvas.stamp(grid, Vector2i.ZERO, SWORD_INK)
	var img := canvas.to_image([ArtPalette.ramp(STEEL), ArtPalette.ramp(GOLD), ArtPalette.ramp(LEATHER)])
	var piece := EffectForge.Piece.new(
		ImageTexture.create_from_image(img), -Vector2(img.get_width(), img.get_height()) * 0.5
	)
	_pieces[key] = piece
	return piece


static func _bake(canvas: PixelCanvas, tint: Color, gone: float, offset: Vector2) -> EffectForge.Piece:
	var img := canvas.to_image([ArtPalette.ramp(tint), ArtPalette.ramp(tint.lerp(EDGE, EDGE_MIX))])
	EffectForge.dissolve(img, gone)
	return EffectForge.Piece.new(ImageTexture.create_from_image(img), offset)
