class_name StatusIcon

## L'icône d'un état au-dessus de la barre de vie : un masque dans la couleur de l'état,
## cerné de noir comme les sprites. C'est la forme qui sépare l'embrasement du
## saignement, deux rouges qui se confondent en quelques pixels.

const SIDE := 9
const OUTLINE := Color(0.02, 0.02, 0.03, 0.95)

## Dans l'ordre de `StatusEffects.Kind`, 7×7 : `#` la couleur, `o` son reflet, `x` un fond sombre.
const MASKS := [
	[  # embrasement : une flamme
		"...#...",
		"..##...",
		"..###..",
		".##o##.",
		".#ooo#.",
		".#ooo#.",
		"..###..",
	],
	[  # engourdissement : un éclair
		"....##.",
		"...##..",
		"..##...",
		".#####.",
		"...##..",
		"..##...",
		".##....",
	],
	[  # gel : un flocon
		"...#...",
		".#.#.#.",
		"..###..",
		"###o###",
		"..###..",
		".#.#.#.",
		"...#...",
	],
	[  # pourriture : un crâne, les trous cernés par le contour
		".#####.",
		"#######",
		"#..#..#",
		"#######",
		".##.##.",
		"..###..",
		"..#.#..",
	],
	[  # bénédiction : une croix
		"..###..",
		"..#o#..",
		"###o###",
		"#ooooo#",
		"###o###",
		"..#o#..",
		"..###..",
	],
	[  # saignement : une goutte
		"...#...",
		"...#...",
		"..###..",
		".##o##.",
		".#oo###",
		".#####.",
		"..###..",
	],
	[  # décomposition : des bulles qui crèvent
		"....##.",
		"....##.",
		".##....",
		"#o##...",
		"####.#.",
		".##.###",
		".....#.",
	],
	[  # flétrissement : une fleur fanée, la tige qui ploie
		"...#...",
		"..###..",
		".#o#o#.",
		"..###..",
		"...#...",
		"..#....",
		".#.....",
	],
	[  # malédiction : un œil
		".......",
		"..###..",
		".#...#.",
		"#..#..#",
		".#...#.",
		"..###..",
		".......",
	],
	[  # surchauffe : un soleil (jalon 42, choisi sur planche) — un thermomètre se lisait flamme
		"...#...",
		".#...#.",
		"..###..",
		"#.#o#.#",
		"..###..",
		".#...#.",
		"...#...",
	],
	[  # fêlé : un écu fendu, la fente cernée par le contour (jalon 46)
		".#####.",
		"#o.####",
		"#o#.###",
		"####.##",
		".##.##.",
		"..#.#..",
		"...#...",
	],
	[  # rongé : une tête de rat, les oreilles rondes (jalon 53, choisie sur planche)
		"###.###",
		"#o#.#o#",
		".#####.",
		".#x#x#.",
		"..###..",
		"...#...",
		".......",
	],
]

## Le compteur des rats, à gauche de leur icône (jalon 53) : des chiffres 3×5 clairs, cernés
## comme les icônes. Sous le seuil de glow : un blanc pur brillerait.
const DIGITS := [
	["###", "#.#", "#.#", "#.#", "###"], [".#.", "##.", ".#.", ".#.", "###"],
	["###", "..#", "###", "#..", "###"], ["###", "..#", "###", "..#", "###"],
	["#.#", "#.#", "###", "..#", "..#"], ["###", "#..", "###", "..#", "###"],
	["###", "#..", "###", "#.#", "###"], ["###", "..#", "..#", "..#", "..#"],
	["###", "#.#", "###", "#.#", "###"], ["###", "#.#", "###", "..#", "###"],
]
const COUNT_COLOR := Color(0.88, 0.86, 0.80)

## Une résistance entamée (jalon 49), « flèche sur disque sombre » choisie sur planche : la
## flèche qui descend, de la couleur de la nature, sur un fond `x` qui la sépare des états —
## pleine, elle se lisait comme une icône d'état de plus. Sa pointe a des ailes : sans elles,
## à neuf pixels, elle se lisait « + ».
const LOWERED := [
	".xxxxx.",
	"xxx#xxx",
	"xxx#xxx",
	"x#x#x#x",
	"xx###xx",
	".xx#xx.",
	"..xxx..",
]
const HOLLOW := Color(0.10, 0.08, 0.14)

static var _cache: Array[Texture2D] = []
static var _lowered := {}
static var _counts := {}


static func texture(kind: int) -> Texture2D:
	if _cache.is_empty():
		for s in MASKS.size():
			_cache.append(paint(MASKS[s], StatusEffects.color(s)))
	return _cache[kind]


static func lowered(nature: int) -> Texture2D:
	if not _lowered.has(nature):
		_lowered[nature] = paint(LOWERED, DamageType.COLORS[nature])
	return _lowered[nature]


## Ce nombre en chiffres cernés, d'un pixel de contour comme les icônes.
static func count(n: int) -> Texture2D:
	if not _counts.has(n):
		var mask: Array = []
		for y in 5:
			var row := ""
			for ch in str(n):
				if not row.is_empty():
					row += "."
				row += DIGITS[int(ch)][y]
			mask.append(row)
		_counts[n] = _painted(mask, Vector2i(mask[0].length() + 2, 7), COUNT_COLOR)
	return _counts[n]


## Publique : les icônes de l'arbre de passifs se peignent de la même main.
static func paint(mask: Array, color: Color) -> Texture2D:
	return _painted(mask, Vector2i(SIDE, SIDE), color)


static func _painted(mask: Array, size: Vector2i, color: Color) -> Texture2D:
	var img := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var glint := color.lightened(0.45)
	for y in size.y:
		for x in size.x:
			var c := _cell(mask, x - 1, y - 1)
			if c == "#":
				img.set_pixel(x, y, color)
			elif c == "x":
				img.set_pixel(x, y, HOLLOW)
			elif c == "o":
				img.set_pixel(x, y, glint)
			elif _touches(mask, x - 1, y - 1):
				img.set_pixel(x, y, OUTLINE)
	return ImageTexture.create_from_image(img)


static func _cell(mask: Array, x: int, y: int) -> String:
	if y < 0 or y >= mask.size() or x < 0 or x >= mask[y].length():
		return "."
	return mask[y][x]


## Le contour se pose autour de la silhouette entière, diagonales comprises : sans
## elles l'éclair se découpe en marches.
static func _touches(mask: Array, x: int, y: int) -> bool:
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if _cell(mask, x + dx, y + dy) != ".":
				return true
	return false
