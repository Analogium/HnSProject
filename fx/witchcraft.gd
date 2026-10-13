class_name Witchcraft
extends RefCounted

## La matière de la sorcière (jalon 41, reprise au jalon 49) : les Glyphes et le Mauvais œil.

## Les Glyphes, « cercle runique » choisi sur planche contre le cercle d'alchimie, la rune
## nordique, le pentacle, la craie et le losange : un anneau au rayon où il se déclenche, six
## crans qui tournent une fois armé ; non armé, un point sur deux, sombre. L'icône de l'état de
## son élément se pose au cœur (`StatusIcon`). Deux temps, qui alternent.
const STEPS := 2
const GLYPH_TICKS := 6
const GLYPH_TURN := 0.26
## L'anneau dessiné, en retrait du rayon de déclenchement : le cran qui dépasse tombe dessus.
const GLYPH_INSET := 3
## L'éclat : l'anneau blanchi qui s'ouvre, puis ses éclats qui se dissolvent, en part du rayon.
const SHATTER_GROWTH := [1.35, 2.1]
## Le fil de lumière (contre les pointillés, la trame seule, la chaîne de runes et l'arc
## crépitant) : quatre teintes d'un bout à l'autre, cerné. Le triangle qui frappe se trame à
## cette densité, chaque grain de la couleur du glyphe le plus proche.
const THREAD_SHADES := 4
const WEAVE_DENSITY := 0.3
## Le Sceau, « trois logements » (contre les anneaux, les tiers d'anneau et la cire) : son
## anneau, un cercle intérieur pointillé, un logement vide par élément, à cette distance du bord.
const SEAL_RING := 24
const SEAL_SOCKET := 4
const SEAL_SOCKET_INSET := 10
## Au-delà, les fils et les trames d'anciens glyphes partent : chaque pose en fabrique de neufs.
const PIECES_MOST := 256

static var _pieces := {}


## Le glyphe à ce rayon de déclenchement, armé ou non, à ce temps.
static func glyph(trigger: int, tint: Color, armed: bool, step: int) -> EffectForge.Piece:
	var key := "g%d@%s@%s@%d" % [trigger, tint.to_html(false), armed, step]
	if not _pieces.has(key):
		var r := float(trigger - GLYPH_INSET)
		var canvas := PixelCanvas.new(trigger * 2 + 7, trigger * 2 + 7)
		var mid := Vector2(canvas.width, canvas.height) * 0.5
		if armed:
			_ring(canvas, mid, r, 0.85 if step == 1 else 0.7, 1)
			for i in GLYPH_TICKS:
				var a := Vector2.from_angle(TAU * float(i) / float(GLYPH_TICKS) + GLYPH_TURN * float(step))
				canvas.line(mid + a * (r + 2.0), mid + a * (r + 3.0), 0, 1.0)
		else:
			_ring(canvas, mid, r, 0.25, 2)
		_pieces[key] = _piece(canvas, [tint], mid)
	return _pieces[key]


## L'éclat du glyphe, à ce temps : l'anneau blanchi qui s'ouvre, puis un grain sur deux.
static func shatter(trigger: int, tint: Color, step: int) -> EffectForge.Piece:
	var key := "s%d@%s@%d" % [trigger, tint.to_html(false), step]
	if not _pieces.has(key):
		var r := float(trigger - GLYPH_INSET) * float(SHATTER_GROWTH[step])
		var side := roundi(r) * 2 + 7
		var canvas := PixelCanvas.new(side, side)
		var mid := Vector2(side, side) * 0.5
		_ring(canvas, mid, r, 1.0 if step == 0 else 0.8, 1 if step == 0 else 2)
		_pieces[key] = _piece(canvas, [tint], mid)
	return _pieces[key]


## Un fil de lumière de l'origine à `span`, d'une teinte à l'autre, écarté de `gap` à chaque
## bout ; vif quand il frappe. Rastérisé à l'angle exact : les glyphes ne bougent pas.
static func thread(span: Vector2i, from: Color, to: Color, gap: float, lit: bool) -> EffectForge.Piece:
	var key := "t%s@%s@%s@%d@%s" % [span, from.to_html(false), to.to_html(false), roundi(gap), lit]
	if not _pieces.has(key):
		if _pieces.size() > PIECES_MOST:
			_pieces.clear()
		var pad := 3
		var canvas := PixelCanvas.new(absi(span.x) + pad * 2, absi(span.y) + pad * 2)
		var origin := Vector2(pad - mini(span.x, 0), pad - mini(span.y, 0))
		var dir := Vector2(span).normalized()
		var a := origin + dir * gap
		var b := origin + Vector2(span) - dir * gap
		var n := maxi(roundi(a.distance_to(b)), 1)
		for i in n + 1:
			var t := float(i) / float(n)
			var p := a.lerp(b, t).round()
			canvas.dot_px(int(p.x), int(p.y), mini(int(t * THREAD_SHADES), THREAD_SHADES - 1), 1.0 if lit else 0.55)
		var shades: Array[Color] = []
		for k in THREAD_SHADES:
			shades.append(from.lerp(to, float(k) / float(THREAD_SHADES - 1)))
		_pieces[key] = _piece(canvas, shades, origin)
	return _pieces[key]


## Le triangle qui frappe : sa surface tramée, chaque grain à la teinte du coin le plus proche,
## hors des glyphes. `corners` depuis le premier, qui est l'origine. Sans contour : une trame
## cernée tournerait en poussière noire. Par rangées, bornées aux côtés, et seulement sur les
## colonnes que la trame garde : tout le cadre coûtait 4,1 ms pour un triangle de 200 px,
## 1,2 ainsi (0,4 à 100 px), une fois par triangle (mesuré au jalon 49).
static func weave(corners: Array[Vector2i], tints: Array[Color], gap: float) -> EffectForge.Piece:
	var key := "w%s@%s@%d" % [corners, tints, roundi(gap)]
	if not _pieces.has(key):
		if _pieces.size() > PIECES_MOST:
			_pieces.clear()
		var box := Rect2i(corners[0], Vector2i.ZERO)
		for c in corners:
			box = box.expand(c)
		var w := box.size.x + 1
		var h := box.size.y + 1
		var data := PackedByteArray()
		data.resize(w * h * 4)
		var poly: Array[Vector2] = []
		var grains := PackedInt32Array()
		for i in corners.size():
			poly.append(Vector2(corners[i] - box.position))
			var c: Color = ArtPalette.ramp(tints[i])[2]
			grains.append(c.r8 | (c.g8 << 8) | (c.b8 << 16) | (255 << 24))
		var gap2 := gap * gap
		for y in h:
			var span := _row_span(poly, float(y))
			var from := maxi(ceili(span.x), 0)
			var to := mini(floori(span.y), w - 1)
			for column in 4:
				if float(EffectForge.BAYER[y % 4][column]) >= WEAVE_DENSITY * 16.0:
					continue
				for x in range(from + posmod(column - from, 4), to + 1, 4):
					var p := Vector2(x, y)
					var near := 0
					var best := p.distance_squared_to(poly[0])
					for i in range(1, poly.size()):
						var d := p.distance_squared_to(poly[i])
						if d < best:
							near = i
							best = d
					if best > gap2:
						data.encode_u32((y * w + x) * 4, grains[near])
		var img := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)
		_pieces[key] = EffectForge.Piece.new(ImageTexture.create_from_image(img), Vector2(box.position))
	return _pieces[key]


## Où cette rangée entre et sort du triangle : x de début et de fin, vide (début > fin) hors de lui.
static func _row_span(poly: Array[Vector2], y: float) -> Vector2:
	var from := INF
	var to := -INF
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		if (y < minf(a.y, b.y)) or (y > maxf(a.y, b.y)) or is_equal_approx(a.y, b.y):
			if is_equal_approx(a.y, b.y) and is_equal_approx(y, a.y):
				from = minf(from, minf(a.x, b.x))
				to = maxf(to, maxf(a.x, b.x))
			continue
		var x := a.x + (b.x - a.x) * (y - a.y) / (b.y - a.y)
		from = minf(from, x)
		to = maxf(to, x)
	return Vector2(from, to)


## Le Sceau à sa teinte : l'anneau, le cercle pointillé, trois logements vides. Ce qui est versé
## s'y pose par-dessus (`socket()`).
static func seal(tint: Color) -> EffectForge.Piece:
	var key := "c%s" % tint.to_html(false)
	if not _pieces.has(key):
		var side := SEAL_RING * 2 + 7
		var canvas := PixelCanvas.new(side, side)
		var mid := Vector2(side, side) * 0.5
		_ring(canvas, mid, float(SEAL_RING), 0.7, 1)
		_ring(canvas, mid, float(SEAL_RING - 3), 0.2, 2)
		for i in DamageType.ELEMENTS.size():
			_ring(canvas, mid + socket(i), float(SEAL_SOCKET), 0.2, 1)
		_pieces[key] = _piece(canvas, [tint], mid)
	return _pieces[key]


## Le logement de l'élément de ce rang (`DamageType.ELEMENTS`), depuis le centre du Sceau.
static func socket(index: int) -> Vector2:
	return Vector2.UP.rotated(TAU * float(index) / float(DamageType.ELEMENTS.size())) \
			* float(SEAL_RING - SEAL_SOCKET_INSET)


## L'éclat du Sceau : un anneau au rayon où il frappe, en arcs, un par élément versé. Posé
## pixel par pixel et sans contour, comme sur la planche : par `PixelCanvas`, le balayage
## de son grand cadre coûtait 4,2 ms au rayon 81.
static func seal_shatter(reach: int, natures: Array[int]) -> EffectForge.Piece:
	var key := "x%d@%s" % [reach, natures]
	if not _pieces.has(key):
		var side := reach * 2 + 3
		var img := Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
		var mid := Vector2(side, side) * 0.5
		# Deux anneaux, le vif au bord, un plus sombre dedans : seul, un pixel se perdait au sol.
		var rings := [[float(reach), ArtPalette.LEVELS - 1], [float(reach - 2), 2]]
		for ring: Array in rings:
			var tints: Array[Color] = []
			for nature in natures:
				tints.append(ArtPalette.ramp(DamageType.COLORS[nature])[ring[1]])
			var n := maxi(int(TAU * float(ring[0])), 12)
			for k in n:
				if k % 9 == 0:
					continue
				var a := Vector2.from_angle(-PI * 0.5 + TAU * float(k) / float(n)) * float(ring[0])
				var p := Vector2i((mid + a).round())
				img.set_pixelv(p.clamp(Vector2i.ZERO, Vector2i(side - 1, side - 1)), tints[k * natures.size() / n])
		_pieces[key] = EffectForge.Piece.new(ImageTexture.create_from_image(img), -mid)
	return _pieces[key]


## Un anneau de pixels, un sur `every`.
static func _ring(canvas: PixelCanvas, mid: Vector2, r: float, level: float, every: int) -> void:
	var n := maxi(int(TAU * r), 12)
	for k in n:
		if k % every != 0:
			continue
		var p := (mid + Vector2.from_angle(TAU * float(k) / float(n)) * r).round()
		canvas.dot_px(int(p.x), int(p.y), 0, level)


static func _piece(canvas: PixelCanvas, tints: Array, anchor: Vector2) -> EffectForge.Piece:
	var ramps := []
	for tint: Color in tints:
		ramps.append(ArtPalette.ramp(tint))
	return EffectForge.Piece.new(ImageTexture.create_from_image(canvas.to_image(ramps)), -anchor)


## Le Mauvais œil (jalon 49), « l'œil au sol » choisi sur planche contre une couronne de petits
## yeux, un œil sur chaque tête, un nazar et le regard du corbeau : une amande aussi large que
## son cercle, la sclère sourde — pleine, elle sortait blanche sur le sol —, l'iris à la teinte
## de l'élément. Quatre temps : il s'entrouvre, s'ouvre, puis se referme à moitié.
## Le premier temps n'est pas fermé : un trait de cent pixels se lisait comme un rayon (capture).
const EYE_OPENINGS := [0.3, 0.6, 1.0, 0.45]
## La hauteur de l'amande, l'iris et la pupille, en part de sa demi-largeur.
const EYE_HEIGHT := 0.47
const EYE_IRIS := 0.3
const EYE_PUPIL := 0.1
const EYE_DARK := Color(0.12, 0.10, 0.16)
## La sclère, d'un blanc pâle que `_level()` assourdit.
const PALE := Color(0.95, 0.92, 1.0)

static var _eyes := {}


static func eye(radius: float, step: int, tint: Color) -> EffectForge.Piece:
	var key := "%d@%d@%s" % [roundi(radius), step, tint.to_html(false)]
	if not _eyes.has(key):
		_eyes[key] = _eye_at(float(roundi(radius)), EYE_OPENINGS[step], tint)
	return _eyes[key]


## Par rangées et non pixel par pixel : un `dot_px()` par pixel coûtait 1,7 ms par temps au
## rayon 50, 2,8 au rayon 65 (mesuré au jalon 49). Sa paupière sombre lui sert de contour.
static func _eye_at(w: float, opening: float, tint: Color) -> EffectForge.Piece:
	var h := w * EYE_HEIGHT * opening
	var size := Vector2i(int(w) * 2 + 5, int(w * EYE_HEIGHT) * 2 + 5)
	var mid := Vector2i(size.x / 2, size.y / 2)
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var lid := _level(EYE_DARK, 0.5)
	if h < 1.0:
		img.fill_rect(Rect2i(mid.x - int(w), mid.y, int(w) * 2 + 1, 1), lid)
	else:
		var sclera := _level(PALE, 0.3)
		var iris := _level(tint, 0.6)
		var pupil := _level(EYE_DARK, 0.2)
		var r_iris := w * EYE_IRIS * opening + 0.5
		var r_pupil := w * EYE_PUPIL * opening + 0.5
		for dy in range(-int(h), int(h) + 1):
			var out := _span(w, h, absf(float(dy)))
			var inside := _span(w, h - 1.2, absf(float(dy)))
			var y := mid.y + dy
			img.fill_rect(Rect2i(mid.x - out, y, out * 2 + 1, 1), lid)
			if inside < 0:
				continue
			img.fill_rect(Rect2i(mid.x - inside, y, inside * 2 + 1, 1), sclera)
			for disc: Array in [[r_iris, iris], [r_pupil, pupil]]:
				var r: float = disc[0]
				if absf(float(dy)) < r:
					var half := mini(int(sqrt(r * r - float(dy * dy))), inside)
					img.fill_rect(Rect2i(mid.x - half, y, half * 2 + 1, 1), disc[1])
	return EffectForge.Piece.new(ImageTexture.create_from_image(img), -Vector2(mid))


## La demi-largeur de l'amande à cette hauteur, -1 au-delà.
static func _span(w: float, h: float, dy: float) -> int:
	if h <= 0.0 or dy > h:
		return -1
	return int(w * sqrt(1.0 - dy / h))


static func _level(base: Color, level: float) -> Color:
	var ramp := ArtPalette.ramp(base)
	return ramp[roundi(level * float(ramp.size() - 1))]
