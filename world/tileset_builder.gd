class_name TilesetBuilder

## Construit un TileSet complet par code : atlas de tuiles peint pixel par pixel,
## plus la couche physique sur la seule tuile de mur.
##
## Deux chemins pour l'image, jamais les deux : **l'atlas de `art/tiles/`** quand
## il existe — six tuiles de 32 px produites par `tools/tiles.py`, qui prend la
## matière d'un rendu ComfyUI et la ramène aux valeurs du jeu — et sinon la
## peinture procédurale ci-dessous, qui reste la référence des couleurs. Le reste
## (régions, physique, variantes) ne dépend d'aucun des deux.

const TILE := 32
const HALF := 16.0

## Tuiles 0 à 3 = sol (0 neutre, 1-3 variantes).
## Tuile 4 = intérieur de mur, tuile 5 = mur dont le dessus est exposé.
##
## Deux tuiles de mur et pas une seule : si chaque tuile porte sa bande claire,
## une masse de murs se lit comme un empilement de briques. Seul le bord au
## contact du sol doit être éclairé, l'intérieur reste uni pour que les blocs
## fusionnent.
const FLOOR_VARIANTS := 4
const WALL_INDEX := 4
const WALL_EDGE_INDEX := 5
const TILE_COUNT := 6

## Décor sombre et désaturé, pour que le loot et les effets ressortent.
##
## Le sol était à 0,29 : la **même valeur** que 95 % des pixels d'un acteur
## (mesuré 0,316), donc un ennemi ne se détachait de son sol par rien. Il est
## descendu d'un cran entier, et tiré vers le violet des ombres pour que le
## décor soit d'une autre famille que ce qui marche dessus.
const FLOOR_BASE := Color(0.21, 0.19, 0.21)
const FLOOR_GRAIN := 0.035
## Les murs suivent le sol vers le bas : c'est leur **écart** avec lui qui les
## fait lire comme des trous, pas leur valeur absolue.
const WALL_BASE := Color(0.09, 0.08, 0.12)
const WALL_TOP := Color(0.17, 0.16, 0.22)


static func build() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)

	# Couche physique 0 -> layer de collision 1 (décor), sans masque : les murs
	# sont percutés, ils ne détectent rien eux-mêmes.
	ts.add_physics_layer(0)
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)

	var src := TileSetAtlasSource.new()
	src.texture = _texture()
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src, 0)

	for i in TILE_COUNT:
		src.create_tile(Vector2i(i, 0))

	# Seules les tuiles de mur portent une collision : le layer de sol peut donc
	# partager le même TileSet sans bloquer le joueur.
	for index in [WALL_INDEX, WALL_EDGE_INDEX]:
		var wall := src.get_tile_data(Vector2i(index, 0), 0)
		wall.add_collision_polygon(0)
		wall.set_collision_polygon_points(0, 0, PackedVector2Array([
			Vector2(-HALF, -HALF), Vector2(HALF, -HALF),
			Vector2(HALF, HALF), Vector2(-HALF, HALF),
		]))

	return ts


## L'atlas produit hors du jeu s'il est là, le dessin sinon. Même partage que les
## grilles de `SpriteForge.ART` : une image qu'on peut juger une fois est un
## fichier, ce qui s'anime reste du code.
const ATLAS_PATH := "res://art/tiles/atlas.png"


static func _texture() -> Texture2D:
	if ResourceLoader.exists(ATLAS_PATH):
		return load(ATLAS_PATH)
	return ImageTexture.create_from_image(_atlas())


## Atlas d'une seule rangée : 4 sols puis 1 mur.
static func _atlas() -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260901   # figé : l'atlas doit être identique à chaque lancement

	var img := Image.create_empty(TILE * TILE_COUNT, TILE, false, Image.FORMAT_RGB8)

	for variant in FLOOR_VARIANTS:
		_paint_floor(img, variant * TILE, variant, rng)
	_paint_wall(img, WALL_INDEX * TILE, false, rng)
	_paint_wall(img, WALL_EDGE_INDEX * TILE, true, rng)

	return img


static func _paint_floor(img: Image, ox: int, variant: int, rng: RandomNumberGenerator) -> void:
	for y in TILE:
		for x in TILE:
			var n := rng.randf_range(-FLOOR_GRAIN, FLOOR_GRAIN)
			img.set_pixel(ox + x, y, _shift(FLOOR_BASE, n))

	if variant == 0:
		return   # tuile neutre, celle qui domine

	# Variantes : quelques cailloux et fissures pour casser la répétition.
	var marks := 3 + variant * 2
	for i in marks:
		var mx := rng.randi_range(2, TILE - 4)
		var my := rng.randi_range(2, TILE - 4)
		var dark := _shift(FLOOR_BASE, -0.06 - rng.randf() * 0.04)
		var run := rng.randi_range(1, 3)
		for k in run:
			var px := mini(mx + k, TILE - 1)
			img.set_pixel(ox + px, my, dark)
			if variant == 3:
				img.set_pixel(ox + px, mini(my + 1, TILE - 1), dark)


## Pas de contour sur le pourtour : il redessinerait la grille de tuiles au
## milieu d'une masse de murs. La lisibilité vient du contraste avec le sol.
static func _paint_wall(img: Image, ox: int, lit_top: bool, rng: RandomNumberGenerator) -> void:
	for y in TILE:
		for x in TILE:
			var c := WALL_BASE
			if lit_top and y < 7:
				# Bande claire : c'est le dessus du bloc, vu de trois quarts.
				c = WALL_TOP
			elif lit_top and y == 7:
				c = _shift(WALL_TOP, -0.04)
			img.set_pixel(ox + x, y, _shift(c, rng.randf_range(-0.012, 0.012)))


static func _shift(c: Color, amount: float) -> Color:
	return Color(
		clampf(c.r + amount, 0.0, 1.0),
		clampf(c.g + amount, 0.0, 1.0),
		clampf(c.b + amount, 0.0, 1.0)
	)
