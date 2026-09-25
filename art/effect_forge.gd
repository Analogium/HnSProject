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

## Une langue de flamme, neuf pixels sur treize, en quatre temps. **Le pied ne
## bouge pas** d'un temps à l'autre — c'est la pointe qui lèche —, sinon la flamme
## saute au lieu d'onduler.
##
## Son dégradé est vertical et franc : presque noir au pied, blanc à la pointe.
## Choisi sur planche contre cinq autres langues (jalon 24) — c'est le pied sombre
## qui **pose** la flamme sur le sol, là où une langue claire de bout en bout
## flotte au-dessus.
##
## `1` à `5` montent la rampe de la teinte, `w` est le cœur : sa propre rampe,
## bâtie sur la couleur chaude, parce qu'un cœur pris en haut de la rampe du feu
## reste orange. Le contour, lui, n'est pas dessiné : `PixelCanvas` le pose autour
## de la silhouette entière.
const FLAME := [
	[
		"....5....",
		"...555...",
		"...5w5...",
		"..45w54..",
		"..4www4..",
		".44www44.",
		".34www43.",
		".334w433.",
		"233444332",
		"223333322",
		"122333221",
		"112222211",
		".1122211.",
	],
	[
		"..5......",
		"..555....",
		"..5w5....",
		"..45w54..",
		"..4www4..",
		".44www44.",
		".34www43.",
		".334w433.",
		"233444332",
		"223333322",
		"122333221",
		"112222211",
		".1122211.",
	],
	[
		".........",
		"....5....",
		"...555...",
		"..45w54..",
		"..4www4..",
		".44www44.",
		".34www43.",
		".334w433.",
		"233444332",
		"223333322",
		"122333221",
		"112222211",
		".1122211.",
	],
	[
		"......5..",
		"....555..",
		"....5w5..",
		"..45w54..",
		"..4www4..",
		".44www44.",
		".34www43.",
		".334w433.",
		"233444332",
		"223333322",
		"122333221",
		"112222211",
		".1122211.",
	],
]

## Images de langue par seconde. Au-delà d'une douzaine, le feu grésille ; en
## dessous de six, il saccade. La même pour tout ce qui brûle, sinon deux feux
## voisins battent à deux rythmes.
const FLAME_HZ := 9.0

const FLAME_WIDTH := 9
const FLAME_HEIGHT := 13

## Le rang de la teinte et celui du cœur dans la palette passée à `to_image()`.
const R_TINT := 0
const R_CORE := 1

const INK := {
	"1": [R_TINT, 0], "2": [R_TINT, 1], "3": [R_TINT, 2], "4": [R_TINT, 3],
	"5": [R_TINT, 4], "w": [R_CORE, 4],
}

static var _flames := {}


## Les quatre temps d'une langue de cette teinte, dans l'ordre.
static func flames(tint: Color) -> Array:
	return _sheet(_flames, FLAME, FLAME_WIDTH, FLAME_HEIGHT, tint, Fire.heart(tint))


## La matrice de Bayer 4×4, la façon dont le pixel art fait ses dégradés depuis
## toujours : un damier ordonné plutôt qu'une rampe continue.
const BAYER := [
	[0, 8, 2, 10],
	[12, 4, 14, 6],
	[3, 11, 1, 9],
	[15, 7, 13, 5],
]

## Les paliers du halo. Trois et pas plus : c'est le nombre de tons qu'un dégradé
## de pixel art se permet avant de redevenir un dégradé.
const SCORCH_STEPS := 3
const SCORCH_ALPHA := 0.20

static var _scorches := {}


## Le halo de sol d'une aura, **tramé** : un dégradé radial lisse est la dernière
## chose qui trahit le vecteur au milieu d'un décor en pixels. Gardé par teinte et
## par rayon entier — un rayon ne change qu'en allumant l'aura ou en plaçant un
## point.
## `alpha` : l'opacité du palier le plus dense — la malédiction marque plus fort
## qu'une aura.
static func scorch(tint: Color, radius: int, alpha := SCORCH_ALPHA) -> Texture2D:
	var key := "%s@%d@%.2f" % [tint.to_html(false), radius, alpha]
	if _scorches.has(key):
		return _scorches[key]

	var side := radius * 2 + 1
	var img := Image.create(side, side, false, Image.FORMAT_RGBA8)
	var r := float(radius)
	for y in side:
		var dy := float(y) - r
		for x in side:
			var dx := float(x) - r
			var d := sqrt(dx * dx + dy * dy) / r
			if d > 1.0:
				continue
			# Le seuil du damier décale chaque pixel d'un seizième de palier : c'est
			# lui qui remplace la retombée continue.
			var v := pow(1.0 - d, 1.6) * float(SCORCH_STEPS)
			var step := int(floor(v + float(BAYER[y % 4][x % 4]) / 16.0))
			if step <= 0:
				continue
			img.set_pixel(x, y, Color(
				tint, float(mini(step, SCORCH_STEPS)) / float(SCORCH_STEPS) * alpha
			))
	var tex := ImageTexture.create_from_image(img)
	_scorches[key] = tex
	return tex


## Une petite langue, cinq pixels sur huit, en trois temps : celle qui tient sur
## le dos d'un serpent, où la grande — neuf sur treize — couvrait la bête.
const FLAME_SMALL := [
	[
		"..5..",
		".454.",
		".4w4.",
		".3w3.",
		"23w32",
		"23w32",
		"13443",
		".131.",
	],
	[
		".5...",
		"45...",
		".4w4.",
		".3w3.",
		"23w32",
		"23w32",
		"13443",
		".131.",
	],
	[
		".....",
		"..5..",
		".454.",
		".3w3.",
		"23w32",
		"23w32",
		"13443",
		".131.",
	],
]

const SMALL_WIDTH := 5
const SMALL_HEIGHT := 8

static var _small := {}


## Les trois temps d'une petite langue de cette teinte.
static func small_flames(tint: Color) -> Array:
	return _sheet(_small, FLAME_SMALL, SMALL_WIDTH, SMALL_HEIGHT, tint, Fire.heart(tint))


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
static func _bake(grids: Array, w: int, h: int, tint: Color, core: Color) -> Array:
	var palettes := [ArtPalette.ramp(tint), ArtPalette.ramp(core)]
	var out: Array[Texture2D] = []
	for grid: Array in grids:
		var canvas := PixelCanvas.new(w, h)
		canvas.stamp(grid, Vector2i.ZERO, INK)
		out.append(ImageTexture.create_from_image(canvas.to_image(palettes)))
	return out


## La boule de feu, **six temps dessinés image par image**, treize pixels de côté.
## Le cran au-dessus des planches précédentes : ce n'est plus une forme qu'on
## anime en la déplaçant, c'est un dessin qui change.
##
## Elle ne se redimensionne jamais — sa taille est une constante, pas une
## statistique —, et le nœud qui la porte **ne tourne pas** : une planche de pixel
## art pivotée se rééchantillonne, et une boule n'a pas d'orientation. C'est à ce
## prix qu'une planche remplace un tracé ; ce qui grandit avec un point de talent,
## comme le rayon d'une explosion, n'y a pas droit.
const BALL := [
	[
		".....3.......",
		"....3333.....",
		"...444443....",
		"..34555543...",
		".3455ww5543..",
		".345wwww543..",
		".3455www5432.",
		"..3455554432.",
		"..3344444332.",
		"...33444322..",
		"....333322...",
		".....2222....",
		".............",
	],
	[
		".......3.....",
		".....3333....",
		"...3444443...",
		"..345555543..",
		".34455ww543..",
		".3455wwww43..",
		"..345wwww432.",
		"..34555554432",
		"..3344444332.",
		"...33344322..",
		"....332222...",
		".....222.....",
		".............",
	],
	[
		".............",
		"....33332....",
		"...4444433...",
		"..34555443...",
		".345ww554432.",
		".34wwww554332",
		".345www55432.",
		".23455554432.",
		"..3444444332.",
		"...3344432...",
		"....333222...",
		".....2222....",
		".............",
	],
	[
		".............",
		".....3333....",
		"...44555443..",
		"..345wwww543.",
		".345wwwwww43.",
		".34wwwwwww43.",
		".345wwwwww43.",
		"..345wwww543.",
		"..3345555432.",
		"...33444332..",
		"....333322...",
		".....2222....",
		".............",
	],
	[
		".............",
		"....3333.....",
		"...4444433...",
		"..34555543...",
		".34wwwww5432.",
		".34wwwww5432.",
		".3455ww554432",
		"..3455555432.",
		"..33444443322",
		"...334443322.",
		"....333322...",
		".....222.....",
		".............",
	],
	[
		".............",
		"....33332....",
		"..3444443....",
		".345555443...",
		"3455ww554432.",
		"345wwww55432.",
		".345www55432.",
		"..3455554432.",
		"..3344444332.",
		"...33444322..",
		"....333322...",
		".....222.....",
		".............",
	],
]

const BALL_SIZE := 13
## Images par seconde de la boule. Plus lent, elle a l'air de clignoter ; plus
## vite, le dessin se perd et on ne voit qu'un scintillement.
const BALL_HZ := 14.0

## Les bouffées qu'elle laisse derrière elle, de la plus vive à la plus éteinte :
## une traînée est une file de dessins qui meurent, pas un dégradé.
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

static var _balls := {}
static var _puffs := {}


static func balls(tint: Color) -> Array:
	return _sheet(_balls, BALL, BALL_SIZE, BALL_SIZE, tint, Fire.heart(tint))


static func puffs(tint: Color) -> Array:
	return _sheet(_puffs, PUFF, PUFF_SIZE, PUFF_SIZE, tint, Fire.heart(tint))


## L'éclat d'un souffle, treize pixels, en trois temps : **une étoile et non un
## disque**. Un disque blanc est un trou dans l'image ; une étoile est un coup.
## Sa taille ne bouge pas — c'est l'éclat, pas la portée —, donc il a droit à une
## planche d'animation là où l'onde, dont le rayon est une statistique, n'y a pas
## droit.
const FLASH := [
	[
		"......5......",
		"......5......",
		"..2...5...2..",
		"...2..5..2...",
		"....45w54....",
		"..2.4www4.2..",
		"5555wwwww5555",
		"..2.4www4.2..",
		"....45w54....",
		"...2..5..2...",
		"..2...5...2..",
		"......5......",
		"......5......",
	],
	[
		".............",
		".............",
		"......5......",
		"...2..5..2...",
		"....45w54....",
		"..2.4www4.2..",
		".455wwwww554.",
		"..2.4www4.2..",
		"....45w54....",
		"...2..5..2...",
		"......5......",
		".............",
		".............",
	],
	[
		".............",
		".............",
		".............",
		".............",
		".....454.....",
		"....45w54....",
		"....4www4....",
		"....45w54....",
		".....454.....",
		".............",
		".............",
		".............",
		".............",
	],
]

const FLASH_SIZE := 13
## L'éclat brûle ses trois images en un huitième de seconde : il doit avoir disparu
## avant que l'œil ne le détaille.
const FLASH_HZ := 24.0

## Une brûlure au sol, sept sur cinq, en deux dessins. Posée à plat et **sombre** :
## c'est la seule chose du feu qui ne brille pas, et c'est elle qui dit qu'on est
## passé par là.
const BURN := [
	[
		".11111.",
		"1122211",
		"1223221",
		"1122211",
		".11111.",
	],
	[
		"..111..",
		".12221.",
		"1122211",
		".12321.",
		"..111..",
	],
]

const BURN_WIDTH := 7
const BURN_HEIGHT := 5
## La cendre. Fixe et non teintée : une brûlure est de la cendre, quelle que soit
## la couleur de ce qui l'a faite. **Brune et non grise** : sur un sol déjà sombre,
## une cendre grise disparaît — c'est la braise qui couve dans la terre qu'on voit,
## pas le noir. Son ombre est chaude, pour la même raison que celle du serpent.
const ASH := Color(0.34, 0.16, 0.10)
const ASH_SHADOW := Color(0.14, 0.05, 0.04)

static var _flashes := {}
static var _burns: Array = []


static func flashes(tint: Color) -> Array:
	return _sheet(_flashes, FLASH, FLASH_SIZE, FLASH_SIZE, tint, Fire.heart(tint))


static func burns() -> Array:
	if _burns.is_empty():
		var palettes := [ArtPalette.ramp(ASH, ASH_SHADOW)]
		for grid: Array in BURN:
			var canvas := PixelCanvas.new(BURN_WIDTH, BURN_HEIGHT)
			canvas.stamp(grid, Vector2i.ZERO, INK)
			_burns.append(ImageTexture.create_from_image(canvas.to_image(palettes)))
	return _burns


## Le cristal du manuel de glace, neuf pixels sur quinze : deux flancs francs et
## l'arête de givre entre les deux. Choisi sur planche contre cinq autres
## silhouettes (jalon 24) — l'aiguille se lisait comme un pilier, le prisme à
## étages comme un sapin, et la dalle comme un caillou.
##
## **Il n'a pas de temps.** Une flamme bat parce qu'elle brûle ; un cristal est
## fixe, et ce qui l'anime est sa sortie de terre, découpée à la volée par
## `draw_texture_rect_region`. Une planche de quatre temps de glace clignoterait.
const SPIKE := [
	"....w....",
	"....w....",
	"...4w3...",
	"...4w3...",
	"...4w33..",
	"..44w33..",
	"..44w333.",
	".444w333.",
	".444w3332",
	".444w3332",
	"4444w3322",
	"4444w3322",
	"4444w3222",
	"444ww3222",
	"44443222.",
]

const SPIKE_WIDTH := 9
const SPIKE_HEIGHT := 15

## Le petit cristal, cinq sur neuf. Alterné avec le grand plutôt que tiré au sort :
## sept pics de la même taille font une palissade — la leçon de la Ruée ardente,
## où le défaut n'était pas le nombre mais la **régularité**.
const SPIKE_SMALL := [
	"..w..",
	"..w..",
	".4w3.",
	".4w3.",
	"44w33",
	"44w32",
	"44w22",
	"44w22",
	"44322",
]

const SMALL_SPIKE_WIDTH := 5
const SMALL_SPIKE_HEIGHT := 9

## L'éclat emporté par un tourbillon, cinq pixels de côté, **pointe à droite** :
## c'est le zéro des huit orientations. Un tourbillon dont les éclats pointent
## tous en haut n'est qu'une chute de neige.
const CHIP := [
	".....",
	"..5w.",
	"4455w",
	".332.",
	".....",
]

## Le même éclat en diagonale, pointe en bas à droite : la rotation d'un quart de
## tour ne donne jamais les diagonales, il faut les dessiner.
const CHIP_DIAG := [
	"ww4..",
	"454..",
	".554.",
	"..532",
	"...2.",
]

const CHIP_SIZE := 5
## Huit orientations : quatre quarts de tour sur chacun des deux dessins. En
## dessous, l'œil voit les éclats sauter d'une orientation à l'autre.
const CHIP_TURNS := 8

## Le flocon, trois pixels : une croix, pas un carré. Un carré est un confetti.
const FLAKE := [
	".w.",
	"w5w",
	".w.",
]

const FLAKE_SIZE := 3

static var _spikes := {}
static var _small_spikes := {}
static var _chips := {}
static var _flakes := {}


## Le grand cristal de cette teinte.
static func spike(tint: Color) -> Texture2D:
	return _sheet(_spikes, [SPIKE], SPIKE_WIDTH, SPIKE_HEIGHT, tint, Frost.rim(tint))[0]


## Le petit cristal de cette teinte.
static func small_spike(tint: Color) -> Texture2D:
	return _sheet(
		_small_spikes, [SPIKE_SMALL], SMALL_SPIKE_WIDTH, SMALL_SPIKE_HEIGHT, tint, Frost.rim(tint)
	)[0]


## Les huit orientations de l'éclat, dans le sens des aiguilles à partir de la
## droite : `chips(t)[chip_turn(angle)]`. Les grilles ne se construisent qu'au
## premier appel — les faire tourner soixante fois par seconde pour retomber sur
## le cache serait payer la rotation sans jamais s'en servir.
static func chips(tint: Color) -> Array:
	var key := tint.to_html(false)
	if not _chips.has(key):
		var grids: Array = []
		var straight := CHIP
		var diagonal := CHIP_DIAG
		for i in CHIP_TURNS / 2:
			grids.append(straight)
			grids.append(diagonal)
			straight = turned(straight)
			diagonal = turned(diagonal)
		_chips[key] = _bake(grids, CHIP_SIZE, CHIP_SIZE, tint, Frost.rim(tint))
	return _chips[key]


## L'orientation d'éclat la plus proche d'un cap.
static func chip_turn(angle: float) -> int:
	return posmod(int(round(angle / (TAU / float(CHIP_TURNS)))), CHIP_TURNS)


## Le flocon de cette teinte.
static func flake(tint: Color) -> Texture2D:
	return _sheet(_flakes, [FLAKE], FLAKE_SIZE, FLAKE_SIZE, tint, Frost.rim(tint))[0]


## Cale un dessin sur le pixel du jeu : posé à une demi-unité, il se
## rééchantillonne et ses blocs de deux pixels se brisent. Le décalage se calcule
## en monde, parce que c'est là que la caméra tombe entre deux pixels.
static func snap(ci: CanvasItem, offset: Vector2) -> Vector2:
	var origin := ci.get_global_transform().origin
	return (origin + offset).round() - origin


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


## Le Tombeau de glace : vingt et un pixels sur vingt-neuf, le seul dessin du jeu
## qu'on regarde **à travers**. Il se pose donc à alpha partiel, et son intérieur
## est plein — un bloc évidé n'était que deux piliers.
##
## Trois fêlures de givre en travers : sans elles, les facettes font un volume
## propre, et un bloc de glace propre est une vitre.
const TOMB := [
	"........wwwww........",
	"......555555555......",
	"....5555555555555....",
	"..55555444333333334..",
	"ww5555544433333333444",
	"ww5555544433333333444",
	"ww5w55544433333333444",
	"ww55w5544433333333444",
	"ww555w544433333333444",
	"ww5555w44433333333444",
	"ww55555w4433333333444",
	"ww555554w433333333444",
	"ww5555544w33333333444",
	"ww55555444w333333w444",
	"ww555554443w3333w3444",
	"ww5555544433333w33444",
	"ww555554443333w333444",
	"ww55555444333w3333444",
	"ww555w544433w33333444",
	"ww5555w4443w333333444",
	"ww55555w4433333333444",
	"ww555554w433333333444",
	"ww5555544w33333333444",
	"ww55555444w3333333444",
	"..555554443w3333334..",
	"....5554443333333....",
	"......333333333......",
	"........33333........",
	".........333.........",
]

const TOMB_WIDTH := 21
const TOMB_HEIGHT := 29

static var _tombs := {}


## Le bloc de glace de cette teinte.
static func tomb(tint: Color) -> Texture2D:
	return _sheet(_tombs, [TOMB], TOMB_WIDTH, TOMB_HEIGHT, tint, Frost.rim(tint))[0]


## Un grain de lumière sacrée, trois pixels : le cœur au milieu et quatre pointes
## de teinte. La croix de la glace a la forme inverse — branches de givre, centre
## teinté —, parce qu'un cristal *accroche* la lumière quand un grain **est** la
## lumière.
const SPECK := [
	".5.",
	"5w5",
	".5.",
]

const SPECK_SIZE := 3

## L'éclat d'un éclair à l'impact. Il est estampé **dans** la silhouette de l'éclair
## (`Lightning.chain`), pas posé par-dessus : l'éclair et ses éclats n'ont qu'un
## contour. Ses diagonales sont pointillées, sinon il couvre l'ennemi frappé.
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

## La tranche de colonne du Pilier sacré, dix-sept pixels sur douze, **qui se
## carrelle**. Sa grille est pleine bord à bord, donc `PixelCanvas` ne lui pose
## aucun contour — deux tranches posées l'une sur l'autre montreraient sinon une
## barre sombre tous les douze pixels. Le bord sombre de la colonne est donc
## dessiné *dans* la tranche.
##
## Son cœur blanc s'élargit et se resserre d'une rangée à l'autre : défilé vers le
## bas, c'est ce qui fait **couler** la lumière. Des rangées identiques ne
## feraient que glisser un motif.
const SHAFT := [
	"1234455www5544321",
	"123445wwwww544321",
	"12344wwwwwww44321",
	"123445wwwww544321",
	"1234455www5544321",
	"123445wwwww544321",
	"12344wwwwwww44321",
	"12344wwwwwww44321",
	"123445wwwww544321",
	"1234455www5544321",
	"123445wwwww544321",
	"12344wwwwwww44321",
]

## Le haut de la colonne, qui s'affine jusqu'à trois pixels. Sans lui, la colonne
## se termine par une coupe nette et se lit comme un tube posé là ; sa dernière
## rangée reprend exactement le profil de la tranche, donc le raccord ne se voit
## pas.
const SHAFT_TIP := [
	".......www.......",
	"......5www5......",
	".....45www54.....",
	"....345www543....",
	"...2345www5432...",
	"..12345www54321..",
	".112344www443211.",
	"1234455www5544321",
]

const SHAFT_WIDTH := 17
const SHAFT_HEIGHT := 12
const SHAFT_TIP_HEIGHT := 8

static var _specks := {}
static var _lightning_specks := {}
static var _shafts := {}
static var _tips := {}


## Le grain de lumière de cette teinte.
static func spark(tint: Color) -> Texture2D:
	return _sheet(_specks, [SPECK], SPECK_SIZE, SPECK_SIZE, tint, Holy.halo(tint))[0]


## Le même grain en foudre : son cœur est le filament de l'éclair, pas le blanc
## chaud du sacré.
static func lightning_speck(tint: Color) -> Texture2D:
	return _sheet(
		_lightning_specks, [SPECK], SPECK_SIZE, SPECK_SIZE, tint, tint.lerp(Color.WHITE, Lightning.CORE)
	)[0]


## La tranche de colonne de cette teinte.
static func shaft(tint: Color) -> Texture2D:
	return _sheet(_shafts, [SHAFT], SHAFT_WIDTH, SHAFT_HEIGHT, tint, Holy.halo(tint))[0]


## Le haut de la colonne de cette teinte.
static func shaft_tip(tint: Color) -> Texture2D:
	return _sheet(_tips, [SHAFT_TIP], SHAFT_WIDTH, SHAFT_TIP_HEIGHT, tint, Holy.halo(tint))[0]


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


## L'épée d'Épée spirale, **pointe à droite** — le cap zéro —, dessinée une seule
## fois : ses trente-deux caps sont tournés au premier besoin (`rotated()`). Acier
## sur trois tons, le fil blanc au milieu, la garde d'or, la poignée de cuir.
const SWORD := [
	"....g............",
	"....gccccccccc...",
	"hhhhGddddddddddd.",
	"....gbbbbbbbbbb..",
	"....g............",
]


# --------------------------------------------------------------------------
# La nécrose (jalon 26)
# --------------------------------------------------------------------------

## Le rang de la troisième rampe : l'ombre des orbites, la chair d'une faille. Le feu
## et la glace n'en ont pas besoin — une matière qui ronge a un dedans.
const R_SHADE := 2

## `INK`, plus la troisième rampe : `x` `y` `z` en bas, `c` `d` au milieu.
const INK_SHADE := {
	"1": [R_TINT, 0], "2": [R_TINT, 1], "3": [R_TINT, 2], "4": [R_TINT, 3],
	"5": [R_TINT, 4], "w": [R_CORE, 4],
	"x": [R_SHADE, 0], "y": [R_SHADE, 1], "z": [R_SHADE, 2], "c": [R_SHADE, 2], "d": [R_SHADE, 3],
}

## Le projectile de la Peste : un crâne de fumée, neuf pixels sur huit, en quatre
## temps. **Il ne bouge pas, ses orbites palpitent** — choisi sur planche contre une
## bulle, une nuée de spores, une glaire et un orbe noir (jalon 26) : c'est la seule
## forme qui dit « peste » avant la couleur.
const PLAGUE := [
	["..33333..", ".3444443.", "345555543", "341151143", "345515543", ".3455543.", "..3w5w3..", "..33333.."],
	["..33333..", ".3444443.", "345555543", "34yy5yy43", "345515543", ".3455543.", "..3w5w3..", "..33333.."],
	["..33333..", ".3444443.", "345555543", "34ww5ww43", "345515543", ".3455543.", "..3w5w3..", "..33333.."],
	["..33333..", ".3444443.", "345555543", "34yy5yy43", "345515543", ".3455543.", "..3w5w3..", "..33333.."],
]
const PLAGUE_WIDTH := 9
const PLAGUE_HEIGHT := 8
const PLAGUE_HZ := 8.0

## La fumée qu'il laisse, de la plus proche à la plus lointaine : trois volutes de
## tailles différentes, **dissoutes** de plus en plus — une traînée qui meurt n'est
## pas une traînée qui pâlit.
const FUMES := [["..33.", ".3443", "34443", ".333."], [".33.", "3443", ".33."], [".3.", "333"]]
## Laquelle, et combien dissoute, pour chaque rang de la traînée.
const FUME_TRAIL := [[0, 0.0], [0, 0.15], [1, 0.3], [1, 0.45], [2, 0.6]]

## La faille de la Porte pourrissante : une fente de chair debout, neuf pixels sur
## seize, où tourne le vert d'un autre monde. Les reflets `w` descendent d'un temps
## à l'autre.
const RIFT := [
	["...ccc...", "..cdddc..", ".cd343dc.", ".c34543c.", "cd35w53dc", "cd34543dc", "c3455543c", "c3455543c", "c3455543c", "c345w543c", "cd34543dc", "cd35553dc", ".c34543c.", ".cd343dc.", "..cdddc..", "...ccc..."],
	["...ccc...", "..cdddc..", ".cd343dc.", ".c34543c.", "cd35553dc", "cd34543dc", "c345w543c", "c3455543c", "c3455543c", "c3455543c", "cd34543dc", "cd35w53dc", ".c34543c.", ".cd343dc.", "..cdddc..", "...ccc..."],
	["...ccc...", "..cdddc..", ".cd343dc.", ".c34543c.", "cd35553dc", "cd34543dc", "c3455543c", "c3455543c", "c345w543c", "c3455543c", "cd34543dc", "cd35553dc", ".c34w43c.", ".cd343dc.", "..cdddc..", "...ccc..."],
]
const RIFT_WIDTH := 9
const RIFT_HEIGHT := 16
const RIFT_HZ := 6.0

## Une créature de la Porte : une bulle à deux yeux, qui sautille — assise, puis
## tassée. Sept pixels : elle doit se lire en amas de six autour de la faille.
const CRAWLER := [
	["..333..", ".34443.", "34w4w43", "34x4x43", "3455543", ".34443.", "..333.."],
	[".......", "..333..", ".3w4w3.", "34x4x43", "3455543", "3444443", ".33333."],
]
const CRAWLER_SIZE := 7
const CRAWLER_HZ := 6.0

## L'œil de la Malédiction putride, fermé, entrouvert puis ouvert : vingt et un
## pixels sur neuf, posé au-dessus de la zone qu'il maudit.
const EYE := [
	[".....................", ".....................", ".....................", ".....................", "333444444444444444333", ".....................", ".....................", ".....................", "....................."],
	[".....................", ".....................", ".....................", "...333444444444333...", "3344555xxxwxxx5554433", "...333444444444333...", ".....................", ".....................", "....................."],
	[".......3333333.......", "....3334444444333....", "..33445555555554433..", ".3445555xxxxx5555443.", "3445555xxxwxxx5555443", ".3445555xxxxx5555443.", "..33445555555554433..", "....3334444444333....", ".......3333333......."],
]
const EYE_WIDTH := 21
const EYE_HEIGHT := 9

## Une spore de la Nécrose avancée, qui monte autour de celui qu'elle ronge.
const SPORE := [".3.", "3w3", ".3."]
const SPORE_SIZE := 3

static var _plagues := {}
static var _fumes := {}
static var _rifts := {}
static var _crawlers := {}
static var _eyes := {}
static var _spores := {}


static func plagues(tint: Color) -> Array:
	return _shaded(_plagues, PLAGUE, PLAGUE_WIDTH, PLAGUE_HEIGHT, tint, Necrotic.SHADE)


## Les cinq volutes de la traînée, déjà dissoutes : `FUME_TRAIL` dans l'ordre.
static func fumes(tint: Color) -> Array:
	var key := tint.to_html(false)
	if not _fumes.has(key):
		var pieces: Array[Texture2D] = []
		for rank: Array in FUME_TRAIL:
			var grid: Array = FUMES[rank[0]]
			var canvas := PixelCanvas.new((grid[0] as String).length(), grid.size())
			canvas.stamp(grid, Vector2i.ZERO, INK)
			var img := canvas.to_image([ArtPalette.ramp(tint), ArtPalette.ramp(Necrotic.core(tint))])
			dissolve(img, rank[1])
			pieces.append(ImageTexture.create_from_image(img))
		_fumes[key] = pieces
	return _fumes[key]


static func rifts(tint: Color) -> Array:
	return _shaded(_rifts, RIFT, RIFT_WIDTH, RIFT_HEIGHT, tint, Necrotic.FLESH)


static func crawlers(tint: Color) -> Array:
	return _shaded(_crawlers, CRAWLER, CRAWLER_SIZE, CRAWLER_SIZE, tint, Necrotic.SHADE)


static func eyes(tint: Color) -> Array:
	return _shaded(_eyes, EYE, EYE_WIDTH, EYE_HEIGHT, tint, Necrotic.SHADE)


static func spore(tint: Color) -> Texture2D:
	return _shaded(_spores, [SPORE], SPORE_SIZE, SPORE_SIZE, tint, Necrotic.SHADE)[0]


## `_sheet()` à trois rampes : la teinte, son cœur maladif, et `shade`.
static func _shaded(
	cache: Dictionary, grids: Array, w: int, h: int, tint: Color, shade: Color
) -> Array:
	var key := tint.to_html(false)
	if not cache.has(key):
		var palettes := [
			ArtPalette.ramp(tint), ArtPalette.ramp(Necrotic.core(tint)), ArtPalette.ramp(shade)
		]
		var out: Array[Texture2D] = []
		for grid: Array in grids:
			var canvas := PixelCanvas.new(w, h)
			canvas.stamp(grid, Vector2i.ZERO, INK_SHADE)
			out.append(ImageTexture.create_from_image(canvas.to_image(palettes)))
		cache[key] = out
	return cache[key]
