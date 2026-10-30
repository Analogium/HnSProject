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

