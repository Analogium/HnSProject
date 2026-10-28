class_name EffectForge
extends RefCounted

## Les images des effets, dessinées **pixel par pixel** comme les personnages, et
## non tracées en polygones comme le reste de `fx/`.
##
## La raison tient en deux mesures prises sur la même capture, dans deux carrés
## de même taille : un ennemi compte **29 couleurs et 12,5 % de pixels de
## contour** ; une langue de flamme dessinée en polygones en comptait **423 et
## aucun**. Les effets étaient peints dans une autre langue que le décor, et à
## une autre résolution — un polygone tombe entre deux pixels du jeu, qui en fait
## deux à l'écran. Rien ne rattrape ça au réglage.
##
## Une planche est donc **dessinée à la main**, comme les grilles d'acteurs du
## §10 : c'est *qui place les pixels* qui décide, pas la finesse du dégradé.

## Le rang de la teinte et celui du cœur dans la palette passée à `to_image()`.
const R_TINT := 0
const R_CORE := 1

## `1` à `5` montent la rampe de la teinte, `w` est le cœur.
const INK := {
	"1": [R_TINT, 0], "2": [R_TINT, 1], "3": [R_TINT, 2], "4": [R_TINT, 3],
	"5": [R_TINT, 4], "w": [R_CORE, 4],
}

## La matrice de Bayer 4×4, la façon dont le pixel art fait ses dégradés depuis
## toujours : un damier ordonné plutôt qu'une rampe continue.
const BAYER := [
	[0, 8, 2, 10],
	[12, 4, 14, 6],
	[3, 11, 1, 9],
	[15, 7, 13, 5],
]

## Une planche par teinte, bâtie une fois et gardée pour la session : une aura la
## redemande soixante fois par seconde, et sa teinte ne change qu'à la conversion.
static func _sheet(
	cache: Dictionary, grids: Array, w: int, h: int, tint: Color, core: Color
) -> Array:
	var key := tint.to_html(false)
	if not cache.has(key):
		cache[key] = _bake(grids, w, h, tint, core)
	return cache[key]


## `core` est la couleur du rang `R_CORE` : le blanc chaud du feu, le givre de la
## glace. Pris en haut de la rampe de la teinte, un cœur de feu reste orange et un
## cœur de glace reste cyan — c'est sa **propre** rampe qu'il lui faut.
static func _bake(
	grids: Array, w: int, h: int, tint: Color, core: Color, legend: Dictionary = INK
) -> Array:
	var palettes := [ArtPalette.ramp(tint), ArtPalette.ramp(core)]
	var out: Array[Texture2D] = []
	for grid: Array in grids:
		var canvas := PixelCanvas.new(w, h)
		canvas.stamp(grid, Vector2i.ZERO, legend)
		out.append(ImageTexture.create_from_image(canvas.to_image(palettes)))
	return out


## Les bouffées de l'éclat des rats, de la plus vive à la plus éteinte : une traînée est
## une file de dessins qui meurent, pas un dégradé.
const PUFF := [
	[
		".33..",
		"3444.",
		"34w43",
		".3443",
		"..33.",
	],
	[
		".....",
		".233.",
		".3w32",
		".233.",
		".....",
	],
	[
		".....",
		"..2..",
		".232.",
		"..2..",
		".....",
	],
]

const PUFF_SIZE := 5

static var _rot_puffs := {}


## Le cœur jaune maladif de la nécrose en 2D (jalon 26), où tirent les bouffées.
const ROT_CORE := Color(0.90, 0.96, 0.58)


## Les bouffées au cœur nécrotique : l'éclat des rats (jalon 53).
static func rot_puffs(tint: Color) -> Array:
	return _sheet(_rot_puffs, PUFF, PUFF_SIZE, PUFF_SIZE, tint, tint.lerp(ROT_CORE, 0.85))


## Huit orientations : quatre quarts de tour sur chacun des deux dessins, droit et en
## diagonale. En dessous, l'œil voit le dessin sauter d'une orientation à l'autre.
const CHIP_TURNS := 8



## Le rat de la Marée (jalon 53), vu de dessus, tourné vers l'est, en deux temps de course : le
## « tapis serré » choisi sur planche. Corps ovale, `p` le rose de la queue et des oreilles, `n`
## la truffe, `1` les yeux : un losange sans tête se lisait en poisson.
const RAT := [[
	"......2...2....",
	".....234443p...",
	"....2344444413.",
	"..pp3455554443n",
	"pp..2333333313.",
	".....222222p...",
	".......2...2...",
], [
	"....2....2.....",
	".....234443p...",
	"....2344444413.",
	"...p3455554443n",
	"ppp.2333333313.",
	".....222222p...",
	"........2..2...",
]]
## Le même en diagonale, museau en bas à droite.
const RAT_DIAG := [[
	"p............",
	".pp..........",
	"..p..........",
	"...p.2.2.....",
	"....3322.....",
	"....43332....",
	"...2454332...",
	"...2455433p2.",
	".....554433..",
	"......554413.",
	"......2p4413.",
	".........43n.",
	".............",
], [
	"p............",
	"p............",
	".pp..........",
	"...p..22.....",
	"....3322.....",
	"....43332....",
	"..24543322...",
	"...2455433p..",
	".....5544332.",
	"......554413.",
	".......p4413.",
	".........43n.",
	".............",
]]
const RAT_INK := {
	"1": [R_TINT, 0], "2": [R_TINT, 1], "3": [R_TINT, 2], "4": [R_TINT, 3], "5": [R_TINT, 4],
	"p": [R_CORE, 1], "n": [R_CORE, 3],
}
const RAT_PINK := Color(0.86, 0.58, 0.58)
## Les temps de course par seconde.
const RAT_HZ := 10.0
static var _rats := {}


## Huit caps dans l'ordre de `chip_turn()`, deux temps chacun : `rats(pelage)[cap][temps]`.
static func rats(fur: Color) -> Array:
	var key := fur.to_html(false)
	if not _rats.has(key):
		var palettes := [ArtPalette.ramp(fur), ArtPalette.ramp(RAT_PINK)]
		var headings: Array = []
		var straight: Array = RAT
		var diagonal: Array = RAT_DIAG
		for i in CHIP_TURNS / 2:
			headings.append(_rat_frames(straight, palettes))
			headings.append(_rat_frames(diagonal, palettes))
			straight = straight.map(func(g: Array) -> Array: return turned(g))
			diagonal = diagonal.map(func(g: Array) -> Array: return turned(g))
		_rats[key] = headings
	return _rats[key]


## Une marge d'un pixel autour de chaque grille, pour le contour.
static func _rat_frames(grids: Array, palettes: Array) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	for grid: Array in grids:
		var canvas := PixelCanvas.new((grid[0] as String).length() + 2, grid.size() + 2)
		canvas.stamp(grid, Vector2i.ONE, RAT_INK)
		out.append(ImageTexture.create_from_image(canvas.to_image(palettes)))
	return out


## Les notes de l'Air de Hamelin (jalon 53), la « ronde de notes » choisie sur planche : une
## croche et une double croche, dans le même cadre, marge du contour comprise. Sans cœur : le
## haut de la rampe nécrotique claire passerait le seuil de glow.
const NOTES := [[
	".............",
	"......5......",
	"......55.....",
	"......4.5....",
	"......4..5...",
	"......4.5....",
	"......4......",
	"....334......",
	"...34444.....",
	"..344443.....",
	"...3333......",
	".............",
], [
	".............",
	"....5555555..",
	"....5555555..",
	"....4.....4..",
	"....4.....4..",
	"....4.....4..",
	"...34....34..",
	"..3444..3444.",
	".34443.34443.",
	"..333...333..",
	".............",
	".............",
]]
const NOTE_WIDTH := 13
const NOTE_HEIGHT := 12
static var _notes := {}


## Les deux notes de cette teinte.
static func notes(tint: Color) -> Array:
	return _sheet(_notes, NOTES, NOTE_WIDTH, NOTE_HEIGHT, tint, tint)


## L'orientation la plus proche d'un cap, parmi les huit.
static func chip_turn(angle: float) -> int:
	return posmod(int(round(angle / (TAU / float(CHIP_TURNS)))), CHIP_TURNS)


## Cale un dessin sur le pixel du jeu : posé à une demi-unité, il se
## rééchantillonne et ses blocs de deux pixels se brisent. Le décalage se calcule
## en monde, parce que c'est là que la caméra tombe entre deux pixels.
static func snap(ci: CanvasItem, offset: Vector2) -> Vector2:
	var origin := ci.get_global_transform().origin
	return (origin + offset).round() - origin


## Pose une planche **par son centre**, calée, `fade` pour ce qui a le droit de
## s'effacer. Grains, flocons, éclats et boules écrivaient ce cadre à la main, dix fois.
static func put_centered(ci: CanvasItem, tex: Texture2D, at: Vector2, fade := 1.0) -> void:
	if fade <= 0.0:
		return
	var size := Vector2(tex.get_size())
	ci.draw_texture_rect(tex, Rect2(snap(ci, at - size * 0.5), size), false, Color(1.0, 1.0, 1.0, fade))


## Fait tourner une grille d'un quart de tour dans le sens des aiguilles : la
## seule rotation qu'un dessin en pixels supporte sans se rééchantillonner.
##
## La lumière tourne avec, ce qui serait faux sur un sprite posé — mais un éclat
## emporté par un tourbillon culbute, et une facette qui accroche la lumière d'un
## autre côté est justement ce qu'on veut voir.
static func turned(grid: Array) -> Array:
	var height: int = grid.size()
	var out: Array = []
	for x in (grid[0] as String).length():
		var line := ""
		for y in range(height - 1, -1, -1):
			line += (grid[y] as String)[x]
		out.append(line)
	return out


## L'éclat d'un coup porté. Ses diagonales sont pointillées, sinon il couvre l'ennemi frappé.
const STRIKE := [
	"3..4..3",
	".3.4.3.",
	"..4w4..",
	"44www44",
	"..4w4..",
	".3.4.3.",
	"3..4..3",
]
const STRIKE_SIZE := 7

static var _strikes := {}


## L'éclat d'un coup porté, seul : la Becquée (jalon 49) le pose où le bec frappe.
static func strike(tint: Color) -> Texture2D:
	return _sheet(_strikes, [STRIKE], STRIKE_SIZE, STRIKE_SIZE, tint, tint.lerp(Color.WHITE, 0.85))[0]


## Un dessin fabriqué à la demande et son point d'ancrage : ce qui se rastérise au
## cap où on le demande n'a pas de cadre fixe, donc il porte le sien.
class Piece:
	var texture: Texture2D
	## Du point d'ancrage au coin de la planche.
	var offset: Vector2

	func _init(p_texture: Texture2D, p_offset: Vector2) -> void:
		texture = p_texture
		offset = p_offset

	## Posé sur `at`, calé sur le pixel du jeu.
	func put(ci: CanvasItem, at: Vector2) -> void:
		var size := Vector2(texture.get_width(), texture.get_height())
		ci.draw_texture_rect(texture, Rect2(EffectForge.snap(ci, at + offset), size), false)


## Dissout une image **après** son contour, en damier ordonné : `gone` est la part
## qui disparaît. C'est ainsi qu'un dessin s'efface sans pâlir — une planche à
## demi-transparente sur un sol sombre sort grise. Avant le contour, chaque pixel
## restant serait cerné pour lui-même et le dessin tournerait en poussière noire.
##
## Par un masque natif et non pixel par pixel : un `set_pixel()` par pixel coûtait
## 1,1 ms sur l'anneau de 113 pixels du mur de gaz (jalon 26).
static func dissolve(img: Image, gone: float) -> void:
	if gone <= 0.0:
		return
	var size := img.get_size()
	var kept := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	kept.blit_rect_mask(
		img.duplicate() if img.get_format() == Image.FORMAT_RGBA8 else _rgba(img),
		_keep_mask(gone, size).get_region(Rect2i(Vector2i.ZERO, size)), Rect2i(Vector2i.ZERO, size),
		Vector2i.ZERO
	)
	img.copy_from(kept)


## La pièce et ses `steps` crans de dissolution, du plein au presque vide : ce qui naît à
## l'angle exact une fois par geste (la frappe vive, l'estoc de la Tierce) s'efface ainsi.
static func dissolving(piece: Piece, steps: int) -> Array[Piece]:
	var out: Array[Piece] = [piece]
	var img := piece.texture.get_image()
	for i in range(1, steps):
		var copy := img.duplicate() as Image
		dissolve(copy, float(i) / float(steps))
		out.append(Piece.new(ImageTexture.create_from_image(copy), piece.offset))
	return out


static func _rgba(img: Image) -> Image:
	var copy := img.duplicate()
	copy.convert(Image.FORMAT_RGBA8)
	return copy


## Le côté de départ des masques gardés ; ils grandissent si une pièce les dépasse.
const MASK_SIDE := 128
static var _masks := {}


## Les pixels que la dissolution **garde** à ce degré, au moins de cette taille : le
## damier de Bayer, bâti une fois par seuil. Seize seuils possibles, pas plus.
static func _keep_mask(gone: float, at_least: Vector2i) -> Image:
	var threshold := ceili(gone * 16.0)
	var held: Image = _masks.get(threshold)
	if held == null or held.get_width() < at_least.x or held.get_height() < at_least.y:
		var side := maxi(MASK_SIDE, maxi(at_least.x, at_least.y) + 3) / 4 * 4 + 4
		var tile := Image.create_empty(4, 4, false, Image.FORMAT_RGBA8)
		for y in 4:
			for x in 4:
				if BAYER[y][x] >= threshold:
					tile.set_pixel(x, y, Color.WHITE)
		var mask := Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
		for y in range(0, side, 4):
			for x in range(0, side, 4):
				mask.blit_rect(tile, Rect2i(0, 0, 4, 4), Vector2i(x, y))
		_masks[threshold] = mask
	return _masks[threshold]


## Tourne une grille d'un angle quelconque. Chaque pixel d'arrivée échantillonne
## **neuf points** de la grille de départ et garde l'encre la plus fréquente : au
## plus proche voisin, un trait d'un pixel se casse en pointillés dès qu'il passe
## en biais. Comparé sur planche (jalon 24), c'est le vote qui garde la lame d'une
## épée d'un seul tenant.
##
## Rien de ce qu'il rend n'est cerné : le contour se pose ensuite, sur la
## silhouette tournée — tourner un contour le rendrait épais d'un côté.
static func rotated(grid: Array, angle: float) -> Array:
	var width: int = (grid[0] as String).length()
	var height: int = grid.size()
	var side := int(ceil(sqrt(float(width * width + height * height)))) + 2
	# Le cadre prend la parité de la grille : sinon chaque centre de pixel d'arrivée
	# tombe **sur une frontière** de la grille de départ, et le vote tranche au
	# hasard — un quart de tour de l'épée perdait cinq pixels sur trente-neuf.
	side += (side - width) % 2
	var from_center := Vector2(float(width), float(height)) * 0.5
	var to_center := Vector2(float(side), float(side)) * 0.5
	var out: Array = []
	for y in side:
		var line := ""
		for x in side:
			# Loin de la grille, le vote est joué d'avance : une épée n'occupe qu'un
			# cinquième de son cadre tourné, et voter partout coûtait trois fois plus.
			var middle := (Vector2(x, y) + Vector2(0.5, 0.5) - to_center).rotated(-angle) + from_center
			if middle.x < -1.0 or middle.y < -1.0 or middle.x > float(width) + 1.0 or middle.y > float(height) + 1.0:
				line += "."
				continue
			var votes := {}
			for sample in 9:
				var inside := Vector2(float(sample % 3) + 0.5, float(sample / 3) + 0.5) / 3.0
				var p := (Vector2(x, y) + inside - to_center).rotated(-angle) + from_center
				var ink := "."
				if p.x >= 0.0 and p.y >= 0.0 and p.x < float(width) and p.y < float(height):
					ink = (grid[int(p.y)] as String)[int(p.x)]
				votes[ink] = int(votes.get(ink, 0)) + 1
			var best := "."
			for ink: String in votes:
				if int(votes[ink]) > int(votes.get(best, 0)):
					best = ink
			line += best
		out.append(line)
	return out


# --------------------------------------------------------------------------
# Le chevalier (jalon 46)
# --------------------------------------------------------------------------

## Les étoiles de l'assommé : la grande devant la tête, la petite derrière (planche).
const STUN_STARS := [
	[".......", "...4...", "...4...", ".44w44.", "...4...", "...4...", "......."],
	[".......", ".......", "...3...", "..343..", "...3...", ".......", "......."],
]
const STAR_SIDE := 7
## L'or des étoiles de l'assommé : ni le jaune pâle du sacré, ni le violet de la foudre.
const STUN_GOLD := Color(1.0, 0.88, 0.45)

static var _stun_stars := {}


static func stun_stars() -> Array:
	return _sheet(_stun_stars, STUN_STARS, STAR_SIDE, STAR_SIDE, STUN_GOLD, STUN_GOLD.lerp(Color.WHITE, 0.7))


## Le couteau des Lames de jet (jalon 50), **pointe à droite** — le cap zéro —, tourné au premier
## besoin (`rotated()`) : la lame sur deux tons, la garde d'or, le manche de cuir. Il se plante aussi dans les ennemis.
const KNIFE := [
	"....g........",
	"hhh.Gcccccc..",
	"hhh.Gdddddddd",
	"....g........",
]
