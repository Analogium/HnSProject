class_name TilesetBuilder

## Construit un TileSet complet par code : atlas de tuiles peint pixel par pixel,
## plus la couche physique sur la seule tuile de mur.
##
## Le document suppose un TileSet fabriqué dans l'éditeur à partir d'un atlas
## dessiné. Comme le projet n'a aucun asset, on le génère — ça débloque l'étape 9
## sans rien inventer sur la direction artistique. Le jour où de vraies tuiles
## existent, il suffit de remplacer _atlas() par le chargement d'une texture :
## le reste (régions, physique, variantes) ne bouge pas.

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
const FLOOR_BASE := Color(0.29, 0.27, 0.25)
const FLOOR_GRAIN := 0.035
const WALL_BASE := Color(0.13, 0.12, 0.16)
const WALL_TOP := Color(0.24, 0.23, 0.29)


static func build() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)

	# Couche physique 0 -> layer de collision 1 (décor), sans masque : les murs
	# sont percutés, ils ne détectent rien eux-mêmes.
	ts.add_physics_layer(0)
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)

	var src := TileSetAtlasSource.new()
	src.texture = ImageTexture.create_from_image(_atlas())
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
