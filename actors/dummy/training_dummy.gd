class_name TrainingDummy
extends CharacterBody2D

## Cible d'entraînement de l'étape 4. Elle ne meurt pas et ne rend pas les coups :
## elle sert à juger le hit-stop et le flash, et à lire les dégâts cumulés.
##
## Le recul ne fait pas partie du jeu — il est à zéro partout, c'est un choix —
## mais elle reste un CharacterBody2D et non le StaticBody2D du document : c'est
## ce qui permet de le rallumer avec les touches 3/4 de l'arène et de le juger
## tout de suite. Elle revient à sa place toute seule.

const FRICTION := 0.12
const RETURN_SPEED := 0.02   # rappel très lent vers la position d'origine

@onready var sprite: ActorSprite = $Sprite
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var label: Label = $DamageLabel

var _home := Vector2.ZERO
var _total_damage := 0.0


func _ready() -> void:
	_home = global_position
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
	sprite.flash()
