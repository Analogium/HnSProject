class_name Projectile
extends Area2D

## Tir du caster. Le document ne le fournit pas, il n'en décrit que l'appel :
## setup(direction, dégâts, source).
##
## Contrairement aux ennemis, il garde son propre _physics_process : il n'est
## pas piloté par l'EnemyManager. Le jour où les projectiles se comptent par
## centaines, c'est le même chemin de migration — une boucle unique — mais ça
## ne se justifie pas au jalon 1.

@export var speed: float = 140.0
@export var knockback: float = 80.0
@export var lifetime: float = 3.0

var _dir := Vector2.RIGHT
var _damage := 0.0
var _source: Node2D
var _life := 0.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


## À appeler après add_child, sinon global_position ne veut rien dire.
func setup(dir: Vector2, damage: float, source: Node2D) -> void:
	_dir = dir.normalized()
	_damage = damage
	_source = source
	rotation = _dir.angle()


func _physics_process(delta: float) -> void:
	global_position += _dir * speed * delta
	_life += delta
	if _life >= lifetime:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if not area is Hurtbox:
		return
	(area as Hurtbox).take_damage(
		DamageInfo.new(_damage, global_position, knockback)
	)
	queue_free()


## Le masque ne retient que le décor pour les corps : le tir s'arrête au mur,
## et traverse les autres ennemis sans les toucher.
func _on_body_entered(_body: Node2D) -> void:
	queue_free()
