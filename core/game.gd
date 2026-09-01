extends Node

## Durée du hit-stop, en secondes réelles. C'est LE réglage du game feel :
## teste entre 0.03 et 0.10, tu sentiras la différence immédiatement.
## Réglable à chaud depuis l'arène de test.
var hit_stop_duration := 0.05

var rng := RandomNumberGenerator.new()

var _hit_stop_active := false


func _ready() -> void:
	rng.randomize()


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
