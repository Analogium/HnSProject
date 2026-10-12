class_name Holy
extends RefCounted

## La lumière sacrée, **posée** en un seul endroit : les ondes de Pulsation, la colonne du
## Pilier et son sol consacré, le Marteau béni, les Chaînes du jugement et les grains de
## Lumière sacrée.
##
## Le blanc du sacré vivait dans trois fichiers à trois valeurs — 0,55, 0,60 et
## 0,80 vers le blanc —, exactement le désordre qu'avaient les quatre blancs
## chauds du feu. Il n'y en a plus qu'un, et il est **mesuré** : à 0,70 de blanc,
## le rose monte à 0,91 de luminance et passe le seuil de glow (0,9) ; en dessous
## il reste sous le seuil et la lumière n'éclaire rien.

## Le blanc du sacré : chaud et non bleu — une lumière d'or et de cierge, pas un
## néon. Le même que celui du feu, parce que c'est la même chose : de la lumière.
const GLORY := Color(1.0, 0.96, 0.92)
const HALO := 0.70

## De combien le trait est poussé en haut de sa rampe. **Une lumière n'a pas de
## dessous** : éclairé comme un objet, le trait sortait avec un flanc mauve sombre
## et se lisait comme un os. Poussé plus haut encore (0,6), il s'aplatit et perd
## son rose — c'est à 0,35 qu'il garde un peu de volume sans avoir d'ombre.
const LIT := 0.35

## Le marteau du Marteau béni : ses orientations, un huitième de tour chacune.
const HAMMER_TURNS := 8
## Le sol consacré, « dalles » choisies sur planche contre le halo actuel, une croix
## pattée, des rayons, deux cercles et des grains : le pas du carrelage de losanges, et ce
## qu'en garde chaque dalle tramée.
const TILE := 12.0
const GROUND_ALPHA := 0.55

## Les Chaînes du jugement, « maillons » choisis sur planche contre un chapelet, un ruban de
## lumière, du fer, des losanges et une chaîne lâche : un anneau de face et un maillon de
## chant en alternance, tous les `LINK_PITCH` px, posés un à un — une chaîne n'a pas de
## longueur à elle. Les sortes de pièce, et la demi-longueur et demi-largeur des anneaux.
const LINK_PITCH := 5.0
enum Link { RING, BAR, HEAD }
const RING_SIZE := Vector2(3.0, 1.8)
const HEAD_SIZE := Vector2(4.5, 3.0)

## Le souffle sacré (jalon 48), « rayons de gloire » choisis sur planche contre l'onde tracée
## d'avant, un sol tramé, une couronne de grains, une croix pattée, des éclats et une colonne
## brève : huit traits, longs et courts en alternance, qui filent du cœur au bord. Ses temps,
## et l'écart des rayons aux axes — sur un axe, un trait se lit comme une mire.
const GLORY_FRAMES := 6
const GLORY_TILT := 0.39

## Les marteaux par teinte et orientation ; les sols par teinte et rayon ; les pièces de
## chaîne par teinte, cap et sorte ; les rayons de gloire par teinte, rayon et temps.
static var _glories := {}
static var _hammers := {}
static var _grounds := {}
static var _links := {}


## Le cœur d'une lumière de cette teinte — le seul endroit où le sacré a le droit
## d'être presque blanc.
static func halo(tint: Color) -> Color:
	return tint.lerp(GLORY, HALO)


## Le marteau, la tête vers `angle`, à l'orientation la plus proche.
static func hammer(tint: Color, angle: float) -> Texture2D:
	var turn := posmod(roundi((angle + PI * 0.5) / (TAU / float(HAMMER_TURNS))), HAMMER_TURNS)
	var key := "%s|%d" % [tint.to_html(false), turn]
	if not _hammers.has(key):
		var grid := EffectForge.rotated(EffectForge.HAMMER, TAU * float(turn) / float(HAMMER_TURNS))
		var canvas := PixelCanvas.new((grid[0] as String).length(), grid.size())
		canvas.stamp(grid, Vector2i.ZERO, EffectForge.INK)
		_hammers[key] = ImageTexture.create_from_image(
			canvas.to_image([ArtPalette.ramp(tint), ArtPalette.ramp(halo(tint))])
		)
	return _hammers[key]


## Une pièce de chaîne couchée au cap `turn` (`Slash.turn_of`). Un anneau est un tour de
## traits d'un pixel : son trou prend le contour, et c'est lui qui fait l'anneau.
static func link(tint: Color, turn: int, kind: Link) -> Texture2D:
	var key := "%s|%d|%d" % [tint.to_html(false), turn, kind]
	if _links.has(key):
		return _links[key]
	var d := Vector2.from_angle(Slash.angle_of(turn))
	var canvas := PixelCanvas.new(13, 13)
	var center := Vector2(6.0, 6.0)
	if kind == Link.BAR:
		canvas.line(center - d * 2.0, center + d * 2.0, EffectForge.R_TINT, 1.0)
	else:
		var size := RING_SIZE if kind == Link.RING else HEAD_SIZE
		var prev := center + d * size.x
		for i in range(1, 17):
			var t := TAU * float(i) / 16.0
			var p := center + d * cos(t) * size.x + d.orthogonal() * sin(t) * size.y
			canvas.line(prev, p, EffectForge.R_TINT, 0.85)
			prev = p
	var tex := ImageTexture.create_from_image(
		canvas.to_image([ArtPalette.ramp(tint), ArtPalette.ramp(halo(tint))])
	)
	_links[key] = tex
	return tex


## Les rayons de gloire d'un souffle de ce rayon, au temps `frame` de `GLORY_FRAMES` : ils
## s'ouvrent jusqu'au bord, puis leur pied rattrape leur pointe. Le rayon est une statistique :
## une planche par rayon, fabriquée au premier souffle.
static func glory(tint: Color, radius: int, frame: int) -> Texture2D:
	var key := "%s|%d|%d" % [tint.to_html(false), radius, frame]
	if _glories.has(key):
		return _glories[key]
	var k := (float(frame) + 0.5) / float(GLORY_FRAMES)
	var r := float(radius) * (1.0 - pow(1.0 - minf(k * 1.6, 1.0), 3.0))
	var side := radius * 2 + 7
	var center := Vector2(side, side) * 0.5
	var canvas := PixelCanvas.new(side, side)
	for i in 8:
		var d := Vector2.from_angle(TAU * float(i) / 8.0 + GLORY_TILT)
		var from := maxf(r * 0.2, r * k * 1.2)
		var to := r * (1.0 if i % 2 == 0 else 0.7)
		if to > from + 1.0:
			canvas.capsule(center + d * from, center + d * to, 1.3 if i % 2 == 0 else 0.9, EffectForge.R_TINT, LIT)
			canvas.line(center + d * from, center + d * to, EffectForge.R_CORE, 1.0)
	var tex := ImageTexture.create_from_image(
		canvas.to_image([ArtPalette.ramp(tint), ArtPalette.ramp(halo(tint))])
	)
	_glories[key] = tex
	return tex


## Le sol consacré de ce rayon : des losanges tramés, pleins au centre et clairsemés au
## bord, cernés d'un cercle du cœur — ce qui dit jusqu'où l'on est soigné. Un halo au sol,
## donc tramé : il a le droit de s'effacer.
static func consecrated(tint: Color, radius: int) -> Texture2D:
	var key := "%s|%d" % [tint.to_html(false), radius]
	if _grounds.has(key):
		return _grounds[key]
	var side := radius * 2 + 1
	var img := Image.create(side, side, false, Image.FORMAT_RGBA8)
	var r := float(radius)
	var rim := halo(tint)
	for y in side:
		for x in side:
			var d := Vector2(float(x) - r, float(y) - r)
			var length := d.length()
			if length > r:
				continue
			if length > r - 1.0:
				img.set_pixel(x, y, rim)
				continue
			var u := absf(fposmod(d.x + d.y, TILE) - TILE * 0.5) \
					+ absf(fposmod(d.x - d.y, TILE) - TILE * 0.5)
			var level := (1.0 if u < 4.0 else 0.0) * (1.0 - 0.5 * length / r)
			if level > float(EffectForge.BAYER[y % 4][x % 4]) / 16.0:
				img.set_pixel(x, y, Color(tint, GROUND_ALPHA))
	var tex := ImageTexture.create_from_image(img)
	_grounds[key] = tex
	return tex


## Un grain de lumière : trois pixels, le cœur au milieu. Le flocon de la glace a
## la forme inverse — ses branches brillent et son centre est de la teinte —,
## parce qu'un cristal accroche la lumière quand un grain **est** la lumière.
static func spark(ci: CanvasItem, at: Vector2, tint: Color, fade: float) -> void:
	EffectForge.put_centered(ci, EffectForge.spark(tint), at, fade)
