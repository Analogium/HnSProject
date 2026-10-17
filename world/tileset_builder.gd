class_name TilesetBuilder

## La case de la carte, la palette du biome et le matériau qui peint le sol
## (`ground.gdshader`, sur les textures de `art/tiles/`). Les murs sont des blocs posés
## par `Zone._paint()`.

const TILE := 32

## Le biome ocre (jalon 33). Le sol uni n'est vu que sans `ground_material` ; les murs
## restent plus sombres que le sol, c'est leur écart qui les fait lire.
const FLOOR_BASE := Color(0.27, 0.16, 0.10)
const WALL_BASE := Color(0.12, 0.07, 0.05)

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
## `seed`, donc une graine redonne le même. Null sans les textures — le sol uni
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
	material.set_shader_parameter("beyond", WALL_BASE)
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

