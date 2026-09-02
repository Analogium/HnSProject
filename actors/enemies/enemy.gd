class_name Enemy
extends CharacterBody2D

signal died(enemy: Enemy)

@export var stats: CharacterStats

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: Hurtbox = $Hurtbox

var health: float
var target: Node2D
var is_dead := false
## Posé par EnemyManager.register(). Sert aux archétypes qui doivent faire
## naître quelque chose dans la scène (le caster et ses projectiles).
var manager: EnemyManager


func _ready() -> void:
	if stats == null:
		stats = CharacterStats.new()
	health = stats.max_health
	hurtbox.damaged.connect(_on_damaged)
	# Volontairement désactivé : c'est l'EnemyManager qui pilote.
	set_physics_process(false)


func setup(p_target: Node2D) -> void:
	target = p_target


## Surchargée par chaque archétype. Appelée par l'EnemyManager.
func tick(_delta: float) -> void:
	pass


func _on_damaged(info: DamageInfo) -> void:
	if is_dead:
		return
	health -= info.amount
	velocity += (global_position - info.source_position).normalized() * info.knockback
	_flash()
	if health <= 0.0:
		die()


func die() -> void:
	if is_dead:
		return
	is_dead = true
	died.emit(self)
	queue_free()


func _flash() -> void:
	sprite.material.set_shader_parameter("flash_amount", 1.0)
	# ignore_time_scale : sans ça le hit-stop étire le flash d'un facteur 50.
	await get_tree().create_timer(0.08, true, false, true).timeout
	if is_instance_valid(self):
		sprite.material.set_shader_parameter("flash_amount", 0.0)
