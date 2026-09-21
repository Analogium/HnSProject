class_name Slash
extends RefCounted

## Le coup d'arme, posé en un seul endroit : les croissants de l'Attaque, de la
## Frappe lourde, de la Vague tranchante et du Cyclone, les entailles du Coup en
## croix et de la Ruée tranchante, l'épée d'Épée spirale.
##
## **Tout ce manuel pivote**, et une planche ne pivote pas — tournée, elle se
## rééchantillonne et ses blocs de deux pixels se brisent. Chaque forme est donc
## **fabriquée au cap où on la demande**, une fois, et gardée : les formes
## géométriques se rastérisent à ce cap, l'épée dessinée à la main s'y tourne.
## Le premier coup dans une direction paie la fabrication, les suivants rien.

## Trente-deux caps, un tous les 11,25° : à seize, un croissant de 120° tombait
## visiblement à côté de la visée.
const TURNS := 32
## Les temps d'un balayage. Le coup ne vit que dix images : au-delà, deux temps
## voisins seraient la même image fabriquée deux fois.
const FRAMES := 8
## Le blanc du fil de la lame.
const EDGE := Color(1.0, 1.0, 1.0)
const EDGE_MIX := 0.7

const R_TINT := EffectForge.R_TINT
const R_EDGE := EffectForge.R_CORE

const STEEL := Color(0.80, 0.84, 0.92)
const GOLD := Color(0.86, 0.68, 0.30)
const LEATHER := Color(0.40, 0.26, 0.16)
## L'acier sur trois tons, l'or, le cuir ; `s` pour la silhouette d'une image
## rémanente, qui n'a que la teinte du coup.
const SWORD_INK := {
	"b": [0, 2], "c": [0, 3], "d": [0, 4], "g": [1, 3], "G": [1, 4], "h": [2, 2],
}

static var _pieces := {}
## L'épée tournée, par cap : l'épée et ses deux silhouettes rémanentes partagent la
## même rotation, qui est ce qui coûte.
static var _swords := {}


## Le cap le plus proche d'un angle.
static func turn_of(angle: float) -> int:
	return posmod(int(round(angle / (TAU / float(TURNS)))), TURNS)


static func angle_of(turn: int) -> float:
	return TAU * float(turn) / float(TURNS)


## Un croissant de lame autour de l'origine, au cap `turn`. `tail` et `head` sont
## des angles relatifs au cap — la tête peut être d'un côté ou de l'autre, selon
## le sens du coup —, `gone` la part dissoute.
##
## **Lourd en tête, effilé en queue** quand il balaie : c'est ce qui dit dans quel
## sens la lame passe. Épaisse au milieu, la trace se lisait comme une feuille
## (planche, jalon 24). Celui qui **vole** — la Vague tranchante — est épais au
## milieu, parce qu'il avance tout d'un bloc et ne balaie rien.
static func crescent(
	tint: Color, radius: float, thickness: float, turn: int, tail: float, head: float,
	gone: float, sweeps := true
) -> EffectForge.Piece:
	var key := "c%s|%d|%d|%d|%d|%d|%d|%d" % [
		tint.to_html(false), int(radius), int(thickness), turn,
		int(round(tail * 100.0)), int(round(head * 100.0)), int(round(gone * 16.0)), int(sweeps),
	]
	if _pieces.has(key):
		return _pieces[key]

	var facing := angle_of(turn)
	var span := int(ceil(radius)) + 2
	var canvas := PixelCanvas.new(span * 2 + 1, span * 2 + 1)
	var low := minf(tail, head)
	var high := maxf(tail, head)
	for y in span * 2 + 1:
		var dy := float(y - span)
		for x in span * 2 + 1:
			var dx := float(x - span)
			var depth := radius - sqrt(dx * dx + dy * dy)
			if depth < 0.0 or depth > thickness:
				continue
			var a := wrapf(atan2(dy, dx) - facing, -PI, PI)
			if a < low or a > high:
				continue
			var u := (a - tail) / (head - tail)
			var width := thickness * pow(sin(PI * u), 0.6)
			if sweeps:
				width = thickness * pow(u, 0.8) * minf((1.0 - u) * 8.0, 1.0)
			width = maxf(width, 1.0)
			if depth > width:
				continue
			# Le fil blanc tient le bord extérieur, le corps s'assombrit vers le dedans.
			if depth < 1.2:
				canvas.dot_px(x, y, R_EDGE, 1.0)
			else:
				canvas.dot_px(x, y, R_TINT, 0.9 - 0.6 * depth / width)
	var piece := _bake(canvas, tint, gone, -Vector2(span, span))
	_pieces[key] = piece
	return piece


## Une entaille droite de `from_value` à `to` — en coordonnées de visée, x devant —,
## au cap `turn`. Un fuseau : large au milieu, pointu aux deux bouts.
static func stroke(
	tint: Color, from_value: Vector2, to: Vector2, half_width: float, turn: int, gone: float
) -> EffectForge.Piece:
	var key := "s%s|%d|%d|%d|%d|%d|%d" % [
		tint.to_html(false), int(round(from_value.x)), int(round(from_value.y)),
		int(round(to.x)), int(round(to.y)), turn, int(round(gone * 16.0)),
	]
	if not _pieces.has(key):
		var facing := angle_of(turn)
		_pieces[key] = _spindle(tint, from_value.rotated(facing), to.rotated(facing), half_width, gone)
	return _pieces[key]


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
	var along := b - a
	var length_sq := maxf(along.length_squared(), 0.0001)
	# Une entaille en biais n'occupe qu'une bande de son cadre : chaque rangée ne
	# balaie que l'étendue où le fuseau peut passer, pas le cadre entier.
	var reach := half_width / maxf(absf(along.normalized().y), 0.05) + 1.0
	for y in int(size.y):
		var row := float(y) + corner.y
		var lo := 0
		var hi := int(size.x)
		if absf(along.y) > 0.5:
			var at := a.x + along.x * (row - a.y) / along.y - corner.x
			lo = maxi(int(at - reach) - 1, 0)
			hi = mini(int(at + reach) + 2, int(size.x))
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
	return _bake(canvas, tint, gone, corner)


## L'épée au cap `turn`, centrée sur son milieu. `ghost` la réduit à sa
## silhouette dans la teinte du coup — ce que montrent les images rémanentes.
static func sword(tint: Color, turn: int, ghost: bool, gone: float) -> EffectForge.Piece:
	var key := "w%s|%d|%d|%d" % [tint.to_html(false), turn, int(ghost), int(round(gone * 16.0))]
	if _pieces.has(key):
		return _pieces[key]

	if not _swords.has(turn):
		_swords[turn] = EffectForge.rotated(EffectForge.SWORD, angle_of(turn))
	var grid: Array = _swords[turn]
	var side: int = grid.size()
	var canvas := PixelCanvas.new(side, side)
	var palettes: Array
	if ghost:
		var legend := {}
		for ink: String in SWORD_INK:
			legend[ink] = [0, 3]
		canvas.stamp(grid, Vector2i.ZERO, legend)
		palettes = [ArtPalette.ramp(tint)]
	else:
		canvas.stamp(grid, Vector2i.ZERO, SWORD_INK)
		palettes = [ArtPalette.ramp(STEEL), ArtPalette.ramp(GOLD), ArtPalette.ramp(LEATHER)]
	var img := canvas.to_image(palettes)
	EffectForge.dissolve(img, gone)
	var piece := EffectForge.Piece.new(
		ImageTexture.create_from_image(img), -Vector2(side, side) * 0.5
	)
	_pieces[key] = piece
	return piece


static func _bake(canvas: PixelCanvas, tint: Color, gone: float, offset: Vector2) -> EffectForge.Piece:
	var img := canvas.to_image([ArtPalette.ramp(tint), ArtPalette.ramp(tint.lerp(EDGE, EDGE_MIX))])
	EffectForge.dissolve(img, gone)
	return EffectForge.Piece.new(ImageTexture.create_from_image(img), offset)
