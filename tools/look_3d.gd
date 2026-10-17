extends Node

## Scénario de `tools/capture.sh` pour juger les modèles 3D (jalon 54) : posés côte à côte
## sur le sol du biome, sous `world/lighting.tscn`, chaque animation filmée par chaque
## caméra, `FPS` images par seconde d'animation : `<caméra>-<animation>-<n>.png`, que
## `tools/look_3d.py` monte en GIF.
##   tools/capture.sh tools/look_3d.gd modele-3d && tools/look_3d.py modele-3d

## Le modèle et l'arme qu'il montre.
const MODELS := {"swiftblade": "weapon_sword"}
const SPACING := 1.4
## De trois quarts : de face, la lame et le profil se lisent mal.
const YAW := -35.0
const FPS := 15.0
## Le repos dure dix secondes : au-delà, le délai de `capture.sh` coupe le film.
const LONGEST := 4.0
## [nom, perspective, champ vertical (degrés, ou mètres en orthographique), distance,
## inclinaison]. « jeu » est la caméra façon Torchlight choisie au jalon 54.
const CAMERAS := [["jeu", true, 30.0, 20.0, 45.0], ["gros-plan", true, 30.0, 6.0, 30.0]]
const AIM := Vector3(0, 0.8, 0)


func _ready() -> void:
	await get_tree().process_frame
	get_tree().current_scene.queue_free()
	get_viewport().msaa_3d = Viewport.MSAA_4X
	var world := Node3D.new()
	get_tree().root.add_child(world)
	world.add_child(load("res://world/lighting.tscn").instantiate())
	world.add_child(_ground())
	var players: Array[AnimationPlayer] = []
	var x := -SPACING * (MODELS.size() - 1) / 2.0
	for id in MODELS:
		var model: Node3D = load("res://art/models/%s.glb" % id).instantiate()
		model.position.x = x
		model.rotation_degrees.y = YAW
		x += SPACING
		world.add_child(model)
		for weapon in model.find_children("weapon_*", "", true, false):
			weapon.visible = weapon.name == MODELS[id]
		players.append(model.find_children("*", "AnimationPlayer", true, false)[0])
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.current = true
	for c in CAMERAS:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE if c[1] else Camera3D.PROJECTION_ORTHOGONAL
		camera.fov = c[2]
		camera.size = c[2]
		var pitch := deg_to_rad(c[4])
		camera.position = AIM + Vector3(0, sin(pitch), cos(pitch)) * c[3]
		camera.look_at(AIM)
		for anim in players[0].get_animation_list():
			var frames := int(minf(players[0].get_animation(anim).length, LONGEST) * FPS)
			for n in frames:
				for player in players:
					player.play(anim)
					player.seek(n / FPS, true)
					player.pause()
				for i in 2:
					await get_tree().process_frame
				get_viewport().get_texture().get_image().save_png("user://%s-%s-%03d.png" % [c[0], anim, n])
	get_tree().quit()


func _ground() -> MeshInstance3D:
	var plane := PlaneMesh.new()
	plane.size = Vector2(120, 120)
	var material := StandardMaterial3D.new()
	material.albedo_texture = load("res://art/tiles/ground_base.png")
	# Un pixel de la tuile pour 1/16 m, comme la carte 2D.
	material.uv1_triplanar = true
	material.uv1_scale = Vector3.ONE * 16.0 / 256.0
	var ground := MeshInstance3D.new()
	ground.mesh = plane
	ground.material_override = material
	return ground
