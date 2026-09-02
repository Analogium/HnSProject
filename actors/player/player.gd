class_name Player
extends CharacterBody2D

signal died

const ACCEL := 0.25          # réactivité au démarrage
const FRICTION := 0.35       # freinage à l'arrêt
const ATTACK_MOVE_MULT := 0.4  # on ralentit pendant le coup, on ne fige pas

@export var stats: CharacterStats

## Durée pendant laquelle la hitbox est active. Réglable à chaud (étape 5).
@export var swing_duration: float = 0.12

@export_group("Tir")
## Attaque à distance. Moins de dégâts que le corps à corps, mais elle
## n'oblige pas à entrer dans la mêlée : c'est le compromis à régler.
@export var bolt_scene: PackedScene
@export var bolt_damage: float = 7.0
@export var bolt_cooldown: float = 0.30
## Secousse de caméra à l'impact. 0 pour la couper.
@export var shake_amount: float = 2.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var attack_pivot: Node2D = $AttackPivot
@onready var hitbox: Area2D = $AttackPivot/Hitbox
@onready var swing_arc: SwingArc = $AttackPivot/SwingArc
@onready var camera: Camera2D = $Camera2D

## Où atterrissent les tirs du joueur. Posé par la scène (zone ou arène) ;
## à défaut, ils naissent à côté du joueur.
var projectile_parent: Node2D

var health: float
var is_dead := false
var facing := Vector2.RIGHT
var _attack_cd := 0.0
var _bolt_cd := 0.0
var _is_swinging := false
var _already_hit: Array[Node] = []
## Souris = visée au curseur, manette = visée dans la direction du stick.
var _aim_with_mouse := true


func _ready() -> void:
	# Sans .tres assigné on part sur des valeurs par défaut plutôt que de planter.
	if stats == null:
		stats = CharacterStats.new()
	health = stats.max_health
	hitbox.monitoring = false
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	hurtbox.damaged.connect(_on_damaged)


## Purement observationnel : on retient quel périphérique sert à viser.
## À ne pas tester via get_global_mouse_position(), qui bouge aussi quand la
## caméra suit le joueur — la souris paraîtrait alors constamment en mouvement.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_aim_with_mouse = true
	elif event is InputEventJoypadButton:
		_aim_with_mouse = false
	elif event is InputEventJoypadMotion:
		# Seuil large : sinon la dérive du stick au repos rebascule la visée.
		if absf((event as InputEventJoypadMotion).axis_value) > 0.5:
			_aim_with_mouse = false


func _physics_process(delta: float) -> void:
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_bolt_cd = maxf(_bolt_cd - delta, 0.0)

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if _aim_with_mouse:
		var to_mouse := get_global_mouse_position() - global_position
		if to_mouse.length() > 4.0:
			facing = to_mouse.normalized()
	elif input != Vector2.ZERO:
		facing = input.normalized()

	attack_pivot.rotation = facing.angle()
	sprite.flip_h = facing.x < 0.0

	var speed := stats.move_speed * (ATTACK_MOVE_MULT if _is_swinging else 1.0)
	if input != Vector2.ZERO:
		velocity = velocity.lerp(input.normalized() * speed, ACCEL)
	else:
		velocity = velocity.lerp(Vector2.ZERO, FRICTION)

	move_and_slide()

	if Input.is_action_just_pressed("attack") and _attack_cd <= 0.0:
		_swing()

	if Input.is_action_just_pressed("attack_ranged") and _bolt_cd <= 0.0:
		_shoot()


func _swing() -> void:
	_attack_cd = stats.attack_cooldown
	_is_swinging = true
	_already_hit.clear()
	swing_arc.play(swing_duration)

	# set_deferred : on est dans un callback physique, on ne peut pas
	# modifier l'état de monitoring en direct.
	hitbox.set_deferred("monitoring", true)

	# ignore_time_scale : sinon le hit-stop étire la fenêtre de swing.
	await get_tree().create_timer(swing_duration, true, false, true).timeout

	hitbox.set_deferred("monitoring", false)
	_is_swinging = false


func _shoot() -> void:
	if bolt_scene == null:
		return
	_bolt_cd = bolt_cooldown

	var parent := projectile_parent if projectile_parent != null else get_parent()
	var bolt: Projectile = bolt_scene.instantiate()
	# add_child d'abord : global_position n'a de sens qu'une fois dans l'arbre.
	parent.add_child(bolt)
	bolt.global_position = global_position + facing * 12.0
	bolt.setup(facing, bolt_damage, self)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if not area is Hurtbox or area in _already_hit:
		return
	_already_hit.append(area)   # un swing ne touche une cible qu'une fois

	var info := DamageInfo.roll(stats, global_position)
	(area as Hurtbox).take_damage(info)
	Game.hit_stop()
	if shake_amount > 0.0:
		Game.shake_camera(camera, shake_amount)


func _on_damaged(info: DamageInfo) -> void:
	if is_dead:
		return
	health -= info.amount
	velocity += (global_position - info.source_position).normalized() * info.knockback
	_flash()
	if health <= 0.0:
		_die()


func _flash() -> void:
	sprite.material.set_shader_parameter("flash_amount", 1.0)
	await get_tree().create_timer(0.08, true, false, true).timeout
	sprite.material.set_shader_parameter("flash_amount", 0.0)


## Le drapeau évite d'émettre died plusieurs fois : plusieurs grunts peuvent
## frapper dans la même image, et chaque coup relancerait sinon un rechargement
## complet de la zone.
func _die() -> void:
	if is_dead:
		return
	is_dead = true
	set_physics_process(false)
	velocity = Vector2.ZERO
	died.emit()   # l'écran de fin de run se branchera ici


func revive() -> void:
	is_dead = false
	health = stats.max_health
	velocity = Vector2.ZERO
	set_physics_process(true)
