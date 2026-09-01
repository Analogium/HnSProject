class_name TrainingDummy
extends CharacterBody2D

## Cible d'entraînement de l'étape 4. Elle ne meurt pas et ne rend pas les coups :
## elle sert uniquement à juger le hit-stop, le knockback et le flash.
##
## Écart assumé avec le document (qui décrit un StaticBody2D) : un CharacterBody2D
## permet de voir le knockback tout de suite, alors que c'est justement une des
## trois sensations à valider au jalon 1. Elle revient à sa place toute seule.

const FRICTION := 0.12
const RETURN_SPEED := 0.02   # rappel très lent vers la position d'origine

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var label: Label = $DamageLabel

var _home := Vector2.ZERO
var _total_damage := 0.0


func _ready() -> void:
	_home = global_position
	# Matériau unique par instance, sinon toutes les cibles flashent ensemble.
	sprite.material = sprite.material.duplicate()
	hurtbox.damaged.connect(_on_damaged)
	label.text = ""


func _physics_process(_delta: float) -> void:
	velocity = velocity.lerp(Vector2.ZERO, FRICTION)
	move_and_slide()
	global_position = global_position.lerp(_home, RETURN_SPEED)


func reset() -> void:
	global_position = _home
	velocity = Vector2.ZERO
	_total_damage = 0.0
	label.text = ""


func _on_damaged(info: DamageInfo) -> void:
	_total_damage += info.amount
	velocity += (global_position - info.source_position).normalized() * info.knockback
	label.text = "%d" % roundi(_total_damage)
	label.modulate = Color(1.0, 0.85, 0.3) if info.is_crit else Color(1, 1, 1)
	_flash()


func _flash() -> void:
	sprite.material.set_shader_parameter("flash_amount", 1.0)
	await get_tree().create_timer(0.08, true, false, true).timeout
	if is_instance_valid(self):
		sprite.material.set_shader_parameter("flash_amount", 0.0)
