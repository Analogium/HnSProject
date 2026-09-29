class_name TilesetBuilder

## Construit un TileSet complet par code : un sol, deux murs, la couche physique
## sur les seuls murs — et le matériau qui peint le sol du biome.
##
## Deux chemins pour l'image des tuiles, jamais les deux : **l'atlas de
## `art/tiles/`** quand il existe, produit par `tools/tiles.py`, et sinon la
## peinture procédurale ci-dessous. Le sol, lui, est peint par `ground.gdshader`
## sur les textures du même dossier : sa tuile ne dit que « ici on marche ».

const TILE := 32
const HALF := 16.0

## Deux tuiles de mur et pas une seule : si chaque tuile porte sa bande claire,
## une masse de murs se lit comme un empilement de briques. Seul le bord au
## contact du sol doit être éclairé, l'intérieur reste uni pour que les blocs
## fusionnent.
const FLOOR_INDEX := 0
const WALL_INDEX := 1
const WALL_EDGE_INDEX := 2
const TILE_COUNT := 3

## Le biome ocre (jalon 33). La tuile de sol n'est vue que sans `ground_material` ;
## les murs restent **sous** le sol, c'est leur écart qui les fait lire comme des trous.
const FLOOR_BASE := Color(0.27, 0.16, 0.10)
const WALL_BASE := Color(0.12, 0.07, 0.05)
const WALL_TOP := Color(0.22, 0.14, 0.09)


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
const GROUND_BASE_PATH := "res://art/tiles/ground_base.png"
const GROUND_PATCH_PATH := "res://art/tiles/ground_patch.png"
const GROUND_SHADER := preload("res://world/ground.gdshader")
## La route : un texel de masque pour MASK_CELL px du monde. Chaque case de route
## pose un disque qui décroît sur ROAD_RADIUS texels, et le bruit ronge le bord ;
## le shader coupe à mi-hauteur, soit une route d'environ ROAD_RADIUS texels de large.
const MASK_CELL := 16
const ROAD_RADIUS := 6
const ROAD_RAGGED := 0.45
const MASK_FREQUENCY := 0.08


## Le sol d'une carte de `size` cases et sa route : le bord de la route se tire de
## `seed`, donc une graine redonne le même. Null sans les textures — la tuile unie
## prend le relais.
static func ground_material(size: Vector2i, seed: int, road: Array[Vector2i]) -> ShaderMaterial:
	if not ResourceLoader.exists(GROUND_BASE_PATH):
		return null
	var texels := size * TILE / MASK_CELL
	var material := ShaderMaterial.new()
	material.shader = GROUND_SHADER
	material.set_shader_parameter("base_tex", load(GROUND_BASE_PATH))
	material.set_shader_parameter("patch_tex", load(GROUND_PATCH_PATH))
	material.set_shader_parameter("mask", ImageTexture.create_from_image(_road_mask(texels, seed, road)))
	material.set_shader_parameter("map_px", Vector2(size * TILE))
	return material


static func _road_mask(texels: Vector2i, seed: int, road: Array[Vector2i]) -> Image:
	var near := PackedFloat32Array()
	near.resize(texels.x * texels.y)
	var per_cell := TILE / MASK_CELL
	for cell in road:
		var c := cell * per_cell + Vector2i.ONE * (per_cell / 2)
		for y in range(maxi(c.y - ROAD_RADIUS, 0), mini(c.y + ROAD_RADIUS + 1, texels.y)):
			for x in range(maxi(c.x - ROAD_RADIUS, 0), mini(c.x + ROAD_RADIUS + 1, texels.x)):
				var i := y * texels.x + x
				near[i] = maxf(near[i], 1.0 - Vector2(x - c.x, y - c.y).length() / ROAD_RADIUS)

	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.frequency = MASK_FREQUENCY
	noise.fractal_octaves = 3
	var bytes := noise.get_image(texels.x, texels.y).get_data()
	for i in bytes.size():
		bytes[i] = int(clampf(near[i] + (bytes[i] / 255.0 - 0.5) * ROAD_RAGGED, 0.0, 1.0) * 255.0)
	return Image.create_from_data(texels.x, texels.y, false, Image.FORMAT_L8, bytes)


static func _texture() -> Texture2D:
	if ResourceLoader.exists(ATLAS_PATH):
		return load(ATLAS_PATH)
	return ImageTexture.create_from_image(_atlas())


## Atlas d'une seule rangée : le sol uni, puis les deux murs.
static func _atlas() -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260901   # figé : l'atlas doit être identique à chaque lancement

	var img := Image.create_empty(TILE * TILE_COUNT, TILE, false, Image.FORMAT_RGB8)
	img.fill_rect(Rect2i(FLOOR_INDEX * TILE, 0, TILE, TILE), FLOOR_BASE)
	_paint_wall(img, WALL_INDEX * TILE, false, rng)
	_paint_wall(img, WALL_EDGE_INDEX * TILE, true, rng)

	return img


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
