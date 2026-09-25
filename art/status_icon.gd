class_name StatusIcon

## L'icône d'un état au-dessus de la barre de vie : un masque dans la couleur de l'état,
## cerné de noir comme les sprites. C'est la forme qui sépare l'embrasement du
## saignement, deux rouges qui se confondent en quelques pixels.

const SIDE := 9
const OUTLINE := Color(0.02, 0.02, 0.03, 0.95)

## Dans l'ordre de `StatusEffects.Kind`, 7×7 : `#` la couleur, `o` son reflet.
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
]

static var _cache: Array[Texture2D] = []


static func texture(kind: int) -> Texture2D:
	if _cache.is_empty():
		for s in MASKS.size():
			_cache.append(paint(MASKS[s], StatusEffects.color(s)))
	return _cache[kind]


## Publique : les icônes de l'arbre de passifs se peignent de la même main.
static func paint(mask: Array, color: Color) -> Texture2D:
	var img := Image.create_empty(SIDE, SIDE, false, Image.FORMAT_RGBA8)
	var glint := color.lightened(0.45)
	for y in SIDE:
		for x in SIDE:
			var c := _cell(mask, x - 1, y - 1)
			if c == "#":
				img.set_pixel(x, y, color)
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
