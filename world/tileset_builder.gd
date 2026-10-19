class_name TilesetBuilder

## La case de la carte, la palette du biome et le matériau du relief (`Terrain`,
## `terrain.gdshader`) : le sol sur les textures de `art/tiles/`, la roche des falaises.

const TILE := 32

## Le biome ocre (jalon 33) : le ton dominant du sol, et celui de la roche des falaises
## (jalon 54). `tools/terrain_textures.py` y recale la couleur de ses textures peintes.
const FLOOR_BASE := Color(0.27, 0.16, 0.10)
const ROCK_BASE := Color(0.30, 0.22, 0.17)

## Les textures peintes du relief (`tools/terrain_textures.py`), du nom de leur paramètre.
const TERRAIN_TEXTURES := ["ground", "grass", "road", "rock", "top"]
const TERRAIN_SHADER := preload("res://world/terrain.gdshader")
## La route : un texel de masque pour MASK_CELL px du monde. Chaque case de route
## pose un disque qui décroît sur ROAD_RADIUS texels, et le bruit ronge le bord ;
## le shader coupe à mi-hauteur, soit une route d'environ ROAD_RADIUS texels de large.
const MASK_CELL := 16
const ROAD_RADIUS := 6
const ROAD_RAGGED := 0.45
const MASK_FREQUENCY := 0.08


## Le relief d'une carte de `size` cases et sa route : le bord de la route se tire de
## `seed`, donc une graine redonne le même.
static func terrain_material(size: Vector2i, seed: int, road: Array[Vector2i]) -> ShaderMaterial:
	var texels := size * TILE / MASK_CELL
	var material := ShaderMaterial.new()
	material.shader = TERRAIN_SHADER
	for name: String in TERRAIN_TEXTURES:
		material.set_shader_parameter(name + "_tex", load("res://art/tiles/%s.png" % name))
		material.set_shader_parameter(name + "_nr", load("res://art/tiles/%s_nr.png" % name))
	material.set_shader_parameter("mask", ImageTexture.create_from_image(_road_mask(texels, seed, road)))
	material.set_shader_parameter("map_px", Vector2(size * TILE))
	material.set_shader_parameter("cliff", Terrain.CLIFF)
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

