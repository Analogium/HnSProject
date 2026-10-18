class_name ActorPortrait
extends SubViewport

## Un personnage vu de face dans l'interface, la sélection et l'inventaire (jalon 54) : son
## modèle de portrait (`ActorModel.portrait`) au repos, dans un monde à lui, sous la lumière du
## jeu. Le panneau dessine `get_texture()` dans son cadre, et le tourne à la souris (`turn`).

const FOV := 30.0
## De trois quarts : de face pile, la silhouette se lit à plat.
const YAW := -0.35
## La part de cadre autour du corps, en hauteur.
const MARGIN := 1.12

var model: ActorModel
var _pivot := Node3D.new()
var _camera := Camera3D.new()


func _init() -> void:
	own_world_3d = true
	transparent_bg = true
	msaa_3d = Viewport.MSAA_4X
	render_target_update_mode = SubViewport.UPDATE_DISABLED


func _ready() -> void:
	var lighting := preload("res://world/lighting.tscn").instantiate()
	add_child(lighting)
	# Le fond du jeu deviendrait celui du cadre : il reste transparent.
	var sky := lighting.get_node("Environment") as WorldEnvironment
	sky.environment = sky.environment.duplicate()
	sky.environment.background_mode = Environment.BG_CLEAR_COLOR
	# La lumière du jeu tombe de haut, pour sa caméra plongeante : de face, le bord du chapeau
	# de la sorcière lui mangeait le visage. Un appoint rasant l'éclaire.
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25.0, 0.0, 0.0)
	add_child(fill)
	add_child(_pivot)
	add_child(_camera)
	_camera.fov = FOV
	_camera.current = true


## Ce personnage, son arme en main (vide : celle de l'archétype). À n'appeler que pour un
## archétype qui a son modèle (`ActorModel.has_model()`) : sans lui, le panneau garde sa planche.
func show_actor(archetype: String, weapon := "") -> void:
	var changed := model == null or model.archetype != archetype
	if model == null:
		model = ActorModel.new()
		model.portrait = true
		model.archetype = archetype
		_pivot.add_child(model)
	else:
		model.set_archetype(archetype)
	model.set_weapon(weapon)
	if changed:
		_pivot.rotation.y = YAW
		_frame()


func turn(radians: float) -> void:
	_pivot.rotation.y += radians


## Rendu seulement quand un panneau le montre.
func set_active(on: bool) -> void:
	render_target_update_mode = SubViewport.UPDATE_ALWAYS if on else SubViewport.UPDATE_DISABLED


## À la taille du cadre en pixels de l'écran : rendu à celle du canevas (640 × 360), il serait
## flou une fois étiré.
func fit(frame: Vector2) -> void:
	var window := get_window()
	var scale := 1.0
	if window != null and window.content_scale_size.x > 0:
		scale = minf(float(window.size.x) / window.content_scale_size.x,
			float(window.size.y) / window.content_scale_size.y)
	size = Vector2i((frame * scale).ceil())


## Le corps entier dans le cadre, quelle que soit sa taille : la caméra recule d'après sa
## hauteur (`ActorModel.height()`), les pieds au sol.
func _frame() -> void:
	var height := model.height()
	if height <= 0.0:
		return
	var middle := Vector3(0.0, height * 0.5, 0.0)
	_camera.position = middle + Vector3(0.0, 0.0, height * MARGIN * 0.5 / tan(deg_to_rad(FOV) * 0.5))
	_camera.look_at(middle)
