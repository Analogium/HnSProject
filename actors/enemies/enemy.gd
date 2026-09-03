class_name Enemy
extends CharacterBody2D

signal died(enemy: Enemy)

@export var stats: CharacterStats

## Rayon auquel l'ennemi remarque sa cible.
##
## Avant, rien ne les freinait : le seul seuil était le culling de
## l'EnemyManager (700 px), donc ils fonçaient depuis bien au-delà de l'écran.
## 350 px, c'est la moitié — soit à peu près le bord de l'écran en 640 × 360.
##
## À ne pas confondre avec CULL_DISTANCE, qui reste un garde-fou de performance :
## entre 350 et 700 px l'ennemi est bien mis à jour, il ne t'a simplement pas
## encore repéré. Les deux valeurs confondues feraient geler à l'écran des
## ennemis parfaitement visibles.
@export var detection_radius: float = 350.0

@onready var sprite: ActorSprite = $Sprite
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health_bar: HealthBar = $HealthBar

var health: float
var target: Node2D
var is_dead := false
var is_aggro := false
## Posé par EnemyManager.register(). Sert aux archétypes qui doivent faire
## naître quelque chose dans la scène (le caster et ses projectiles).
var manager: EnemyManager


func _ready() -> void:
	if stats == null:
		stats = CharacterStats.new()
	health = stats.max_health
	health_bar.set_health(health, stats.max_health)
	hurtbox.damaged.connect(_on_damaged)
	# Volontairement désactivé : c'est l'EnemyManager qui pilote.
	set_physics_process(false)


func setup(p_target: Node2D) -> void:
	target = p_target


## Surchargée par chaque archétype. Appelée par l'EnemyManager.
func tick(_delta: float) -> void:
	pass


## À appeler en fin de tick(). Le sprite se pilote depuis la vitesse réelle et
## non depuis l'intention de déplacement : un ennemi qui pousse contre un mur ne
## doit pas continuer à marcher sur place.
func _animate() -> void:
	sprite.set_state(velocity.length() > 8.0, velocity)


## À appeler en tête de tick() par chaque archétype. Une fois alerté, l'ennemi
## le reste : sinon il ferait le yo-yo dès qu'on repasse la limite du rayon.
func _should_act() -> bool:
	if target == null or is_dead:
		return false
	if not is_aggro:
		var r := detection_radius
		if global_position.distance_squared_to(target.global_position) <= r * r:
			is_aggro = true
	return is_aggro


func _on_damaged(info: DamageInfo) -> void:
	if is_dead:
		return
	# Se faire tirer dessus de loin alerte, même hors du rayon de détection.
	is_aggro = true
	health -= info.amount
	health_bar.set_health(health, stats.max_health)
	velocity += (global_position - info.source_position).normalized() * info.knockback
	sprite.flash()
	if health <= 0.0:
		die()


func die() -> void:
	if is_dead:
		return
	is_dead = true
	died.emit(self)
	queue_free()
