class_name TrainingDummy
extends CharacterBody2D

## Cible d'entraînement : elle ne rend pas les coups, elle sert à juger le hit-stop et
## le flash et à lire les dégâts cumulés. Elle porte les états comme un ennemi.
##
## Un CharacterBody2D et non un StaticBody2D : c'est ce qui permet de rallumer le
## recul avec les touches 3/4 de l'arène et de le juger tout de suite. Elle revient
## à sa place toute seule.

const FRICTION := 0.12
const RETURN_SPEED := 0.02   # rappel très lent vers la position d'origine
## Mortelle, elle se relève pleine au bout de ce délai, à sa place.
const RESPAWN := 2.0

## Posées avant l'entrée dans l'arbre. Sans fiche (l'arène), elle encaisse brut ; avec
## (la ville), armure, résistances, esquive et vie d'un ennemi.
var stats: CharacterStats
## Sa vie s'épuise, et la tuer d'un coup déclenche ce qu'un ennemi tué déclenche — ni
## expérience ni butin : ceux-là passent par l'EnemyManager.
var mortal := false

@onready var sprite: ActorSprite = $Sprite
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health_bar: HealthBar = $HealthBar
## Le cumul des dégâts encaissés. Sous les pieds : au-dessus de la tête passent
## les nombres flottants de chaque coup, et deux chiffres superposés se lisent
## comme un bug d'affichage.
@onready var label: Label = $DamageLabel

var states := StatusEffects.new()
var health := 0.0
var _home := Vector2.ZERO
var _total_damage := 0.0
var _hurt_layer := 0
## Le temps qui reste avant de se relever ; positif, elle est à terre.
var _down := 0.0


func _ready() -> void:
	_home = global_position
	_hurt_layer = hurtbox.collision_layer
	hurtbox.stats = stats
	hurtbox.states = states
	# Ce qu'elle brûle compte au compteur de dégâts, comme sur un ennemi.
	states.reports_dealt = true
	states.change.connect(_show_states)
	hurtbox.damaged.connect(_on_damaged)
	reset()


func _physics_process(delta: float) -> void:
	if _down > 0.0:
		_down -= delta
		if _down <= 0.0:
			reset()
		return
	velocity = velocity.lerp(Vector2.ZERO, FRICTION)
	move_and_slide()
	global_position = global_position.lerp(_home, RETURN_SPEED)
	if not states.is_clear:
		var loss := states.advance(delta)
		if loss > 0.0:
			HitFeedback.damage_without_hit(hurtbox.global_position, states.digit(), false)
			_lose(loss)


func reset() -> void:
	global_position = _home
	velocity = Vector2.ZERO
	_total_damage = 0.0
	label.text = ""
	_down = 0.0
	visible = true
	hurtbox.collision_layer = _hurt_layer
	states.clear()
	health = _max_health()
	health_bar.set_health(health, health)


func _max_health() -> float:
	return stats.max_health if stats != null else 1.0


func _on_damaged(info: DamageInfo) -> void:
	if _down > 0.0:
		return
	velocity += (global_position - info.source_position).normalized() * info.knockback
	label.modulate = Color(1.0, 0.85, 0.3) if info.is_crit else Color(1, 1, 1)
	sprite.flash()
	_lose(info.amount)
	if _down > 0.0 and info.author != null:
		info.author.slew.emit(info.cast, global_position, states)


func _lose(amount: float) -> void:
	_total_damage += amount
	label.text = "%d" % roundi(_total_damage)
	if not mortal:
		return
	health -= amount
	health_bar.set_health(health, _max_health())
	if health <= 0.0:
		_fall()


## Ses états restent posés jusqu'au relèvement : ce que déclenche la mise à mort les lit.
func _fall() -> void:
	states.report()
	_down = RESPAWN
	visible = false
	# Différé : on peut être dans un rappel de collision.
	hurtbox.set_deferred("collision_layer", 0)


func _show_states() -> void:
	sprite.show_states(states)
	health_bar.show_states(states)
