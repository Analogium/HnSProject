extends Node

## Durée du hit-stop, en secondes réelles. C'est LE réglage du game feel :
## teste entre 0.03 et 0.10, tu sentiras la différence immédiatement.
## Réglable à chaud depuis l'arène de test.
var hit_stop_duration := 0.05

var rng := RandomNumberGenerator.new()

## Scène d'où l'on vient, pour pouvoir ressortir d'un aperçu par la touche qui
## l'a ouvert. Passer par goto_scene() plutôt que par change_scene_to_file()
## directement, sinon l'historique se désynchronise.
var previous_scene_path := ""

## Vrai quand une fenêtre d'interface s'est emparée de la souris — le sac, pour
## l'instant. Un drapeau global parce que le joueur lit ses attaques par
## sondage (Input.is_action_just_pressed) dans _physics_process : ces lectures
## ne passent pas par l'arbre d'entrées, donc aucune fenêtre ne peut les
## intercepter en consommant l'événement.
var ui_grabs_input := false

var _hit_stop_active := false


func _ready() -> void:
	rng.randomize()


func goto_scene(path: String) -> void:
	var tree := get_tree()
	if tree.current_scene != null:
		previous_scene_path = tree.current_scene.scene_file_path
	tree.change_scene_to_file(path)


## Revient d'où l'on venait. Comme go_back() passe elle-même par goto_scene(),
## deux appels successifs font un aller-retour : la touche qui ouvre un aperçu
## peut donc aussi le refermer.
func go_back(fallback: String = "res://world/zone.tscn") -> void:
	goto_scene(previous_scene_path if previous_scene_path != "" else fallback)


## Fige le jeu très brièvement à l'impact.
func hit_stop(duration: float = -1.0) -> void:
	if _hit_stop_active:
		return
	var d := hit_stop_duration if duration < 0.0 else duration
	if d <= 0.0:
		return
	_hit_stop_active = true
	Engine.time_scale = 0.02
	# 4e paramètre = ignore_time_scale, sinon le timer est figé lui aussi
	await get_tree().create_timer(d, true, false, true).timeout
	Engine.time_scale = 1.0
	_hit_stop_active = false


func shake_camera(camera: Camera2D, amount: float = 3.0, duration: float = 0.15) -> void:
	var elapsed := 0.0
	while elapsed < duration:
		var falloff := 1.0 - (elapsed / duration)
		camera.offset = Vector2(
			rng.randf_range(-amount, amount),
			rng.randf_range(-amount, amount)
		) * falloff
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	camera.offset = Vector2.ZERO
