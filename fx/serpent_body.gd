class_name SerpentBody
extends MeshInstance3D

## Le corps du Serpent infernal en 3D (jalon 54 ; un ruban de feu était « pas un serpent », des
## écailles dessinées « un dessin plat ») : museau, mâchoire, cou pincé, corps qui s'effile, une
## peau de serpent vraie aux joints qui rougeoient, yeux qui brûlent, et sa lueur portée au sol. La grille ne change jamais : le
## shader la courbe le long des anneaux, seuls `SPINE` points partent au GPU à chaque pas.

const SHADER := preload("res://fx/serpent.gdshader")
const SKIN := preload("res://fx/serpent_skin.png")
const SKIN_N := preload("res://fx/serpent_skin_n.png")
## Le museau et les anneaux de `HellSnake` ; écrit aussi dans `fx/serpent.gdshader`.
const SPINE := 21
const SAMPLES := 60
const SIDES := 14
## À taille 1 : le rayon du corps à son plus épais, le museau en avant du premier anneau,
## l'ondulation de part et d'autre de ses pas, la hauteur où se dresse sa tête.
const GIRTH := 2.7
const SNOUT := 3.5
const WAVE := 3.0
const REAR := 9.0
## Une écaille, en pixels du monde le long du corps.
const SCALE := 2.2
## Sa lueur, posée devant la tête et de côté : au-dessus, elle l'écrasait d'un rouge uniforme.
const LIGHT := 5.0
const LIGHT_REACH := 45.0

static var _grid: ArrayMesh

var _light: OmniLight3D


## Le corps de `snake`, à la rampe de `nature` ; `lay()` le pose à chaque pas.
static func dress(snake: Node3D, nature: int) -> SerpentBody:
	var body := SerpentBody.new()
	body.mesh = _grid_mesh()
	var m := ShaderMaterial.new()
	m.shader = SHADER
	var ramp := FlameFx.ramp(nature)
	for i in 3:
		var c: Color = ramp[i]
		m.set_shader_parameter([&"heart", &"tint", &"deep"][i], Vector3(c.r, c.g, c.b))
	m.set_shader_parameter(&"skin", SKIN)
	m.set_shader_parameter(&"skin_n", SKIN_N)
	# Le sien : ses anneaux ne sont qu'à lui.
	body.material_override = m
	snake.add_child(body)
	ElementFx.veil_like(body, snake)
	body._light = OmniLight3D.new()
	body._light.light_color = ramp[1]
	body._light.light_energy = LIGHT
	body._light.omni_range = LIGHT_REACH
	body._light.shadow_enabled = false
	body.add_child(body._light)
	return body


## Les anneaux du jeu, tête d'abord ; `size` celle du serpent, `fade` sa fin (0 → 1).
func lay(rings: Array[Vector3], size: float, fade: float) -> void:
	var spine := PackedVector3Array([rings[0] + (rings[0] - rings[1]).normalized() * SNOUT * size])
	spine.append_array(rings)
	var m := material_override as ShaderMaterial
	m.set_shader_parameter(&"spine", spine)
	m.set_shader_parameter(&"girth", GIRTH * size)
	m.set_shader_parameter(&"wave", WAVE * size)
	m.set_shader_parameter(&"rear", REAR * size)
	m.set_shader_parameter(&"scales", (SNOUT + (rings.size() - 1) * HellSnake.SPACING) * size / SCALE)
	set_instance_shader_parameter(&"fade", fade)
	var box := AABB(to_local(spine[0]), Vector3.ZERO)
	for point in spine:
		box = box.expand(to_local(point))
	custom_aabb = box.grow((GIRTH * 1.4 + WAVE + REAR) * size)
	var ahead := (rings[0] - rings[2]).normalized()
	_light.global_position = rings[0] + ahead * 10.0 + Vector3(-ahead.z, 0.0, ahead.x) * 12.0 + Vector3.UP * 7.0


## La grille : `SAMPLES` cercles de `SIDES` côtés, UV.x le long, UV.y le tour.
static func _grid_mesh() -> ArrayMesh:
	if _grid != null:
		return _grid
	var uvs := PackedVector2Array()
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	for i in SAMPLES:
		for k in SIDES + 1:
			uvs.append(Vector2(float(i) / (SAMPLES - 1), float(k) / SIDES))
			vertices.append(Vector3.ZERO)
	for i in SAMPLES - 1:
		for k in SIDES:
			var a := i * (SIDES + 1) + k
			var b := a + SIDES + 1
			# Vus de dehors : dans l'autre sens, la caméra voyait le dedans du fond du tube, et
			# aucune lumière ne lui donnait de volume.
			indices.append_array([a, b, a + 1, a + 1, b, b + 1])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	_grid = ArrayMesh.new()
	_grid.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return _grid
