class_name IconeDEtat

## L'icône d'un état au-dessus de la barre de vie : un masque dans la couleur de l'état,
## cerné de noir comme les sprites. C'est la forme qui sépare l'embrasement du
## saignement, deux rouges qui se confondent en quelques pixels.

const COTE := 9
const CONTOUR := Color(0.02, 0.02, 0.03, 0.95)

## Dans l'ordre de `Etats.Sorte`, 7×7 : `#` la couleur, `o` son reflet.
const MASQUES := [
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
]

static var _cache: Array[Texture2D] = []


static func texture(sorte: int) -> Texture2D:
	if _cache.is_empty():
		for s in MASQUES.size():
			_cache.append(_dessiner(MASQUES[s], Etats.couleur(s)))
	return _cache[sorte]


static func _dessiner(masque: Array, couleur: Color) -> Texture2D:
	var img := Image.create_empty(COTE, COTE, false, Image.FORMAT_RGBA8)
	var reflet := couleur.lightened(0.45)
	for y in COTE:
		for x in COTE:
			var c := _case(masque, x - 1, y - 1)
			if c == "#":
				img.set_pixel(x, y, couleur)
			elif c == "o":
				img.set_pixel(x, y, reflet)
			elif _touche(masque, x - 1, y - 1):
				img.set_pixel(x, y, CONTOUR)
	return ImageTexture.create_from_image(img)


static func _case(masque: Array, x: int, y: int) -> String:
	if y < 0 or y >= masque.size() or x < 0 or x >= masque[y].length():
		return "."
	return masque[y][x]


## Le contour se pose autour de la silhouette entière, diagonales comprises : sans
## elles l'éclair se découpe en marches.
static func _touche(masque: Array, x: int, y: int) -> bool:
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if _case(masque, x + dx, y + dy) != ".":
				return true
	return false
