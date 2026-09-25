class_name Minion
extends CharacterBody2D

## Un mort-vivant de la Relève : il garde une zone autour du joueur et frappe pour lui.
## **Ce qu'il inflige, c'est le joueur qui l'inflige** — ses coups portent les états et
## le lancer du joueur : sa pourriture soigne le joueur, le compteur de DPS le compte.
## Sa hurtbox est sur le calque du joueur : les tirs ennemis le touchent, et les
## ennemis le prennent pour cible quand il est le plus proche (`Enemy.foe()`).

const SCENE := "res://actors/skills/minion.tscn"
## La part des PV max du lanceur qu'il reçoit à la levée. Premier réglage.
const LIFE := 0.5
const SPEED := 95.0
const ACCEL := 0.2
## D'où il frappe, centre à centre.
const REACH := 16.0
## Hors combat, sa place autour du joueur.
const FORMATION := 22.0
## Au-delà, il rejoint le joueur d'un coup : une ruée le laisserait derrière.
const LEASH := 320.0
## Entre deux recherches de cible : une requête par image n'apprend rien de plus.
const SEARCH_PERIOD := 0.2

## Tous ceux qui marchent, pour les ennemis qui cherchent qui frapper.
static var living: Array[Minion] = []

@onready var sprite: ActorSprite = $Sprite
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health_bar: HealthBar = $HealthBar

var health := 1.0
var max_health := 1.0
var _player: Player
var _cast: SkillStats
## Sa place dans la formation, en angle autour du joueur.
var _angle := 0.0
var _foe: Hurtbox
var _search := 0.0
var _cooldown := 0.0


## Relève ce qui manque pour atteindre le maximum du lancer ; rend combien.
static func raise(player: Player, cast: SkillStats, parent: Node) -> int:
	var missing := cast.max_simultaneous() - count_of(player, cast.skill_id)
	for i in missing:
		var minion: Minion = (load(SCENE) as PackedScene).instantiate()
		minion._player = player
		minion._cast = cast
		minion._angle = TAU * float(i) / float(maxi(missing, 1)) + player.facing.angle()
		minion.max_health = maxf(player.stats.max_health * LIFE, 1.0)
		minion.health = minion.max_health
		parent.add_child(minion)
		minion.global_position = minion._post()
	return maxi(missing, 0)


## Ceux de ce joueur levés par cette compétence.
static func count_of(player: Player, skill_id: String) -> int:
	var n := 0
	for minion in living:
		if minion._player == player and minion._cast.skill_id == skill_id:
			n += 1
	return n


func _enter_tree() -> void:
	living.append(self)


func _exit_tree() -> void:
	living.erase(self)


func _ready() -> void:
	hurtbox.damaged.connect(_on_damaged)
	health_bar.set_health(health, max_health)


## Un livre rangé ou un joueur tombé les fait tomber, comme il éteint un buff.
func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player) or _player.is_dead \
			or _player.skill_points(_cast.skill_id) <= 0:
		queue_free()
		return
	if global_position.distance_to(_player.global_position) > LEASH:
		global_position = _post()
	_cooldown = maxf(_cooldown - delta, 0.0)
	_search -= delta
	if _search <= 0.0:
		_search = SEARCH_PERIOD
		_foe = _nearest_foe()

	var goal := _post()
	if is_instance_valid(_foe):
		goal = _foe.global_position
		var to_foe := goal - global_position
		if to_foe.length() <= REACH:
			velocity = Vector2.ZERO
			if _cooldown <= 0.0:
				_strike(to_foe)
			return
	var to_goal := goal - global_position
	var desired := to_goal.normalized() * SPEED if to_goal.length() > 4.0 else Vector2.ZERO
	velocity = velocity.lerp(desired, ACCEL)
	move_and_slide()
	sprite.set_state(velocity.length() > 8.0, velocity)


## Sa place derrière le joueur quand rien n'entre dans la zone.
func _post() -> Vector2:
	return _player.global_position + Vector2.from_angle(_angle) * FORMATION


## Le plus proche de lui parmi ce qui est **dans la zone du joueur** : il ne court pas
## après ce qui en sort.
func _nearest_foe() -> Hurtbox:
	var best: Hurtbox = null
	var best_d := INF
	for target in Targets.in_circle(get_world_2d(), _player.global_position, _cast.radius):
		var d := global_position.distance_squared_to(target.global_position)
		if d < best_d:
			best = target
			best_d = d
	return best


func _strike(toward: Vector2) -> void:
	_cooldown = _cast.period
	sprite.set_state(false, toward)
	sprite.attack()
	Targets.strike(_foe, _cast.roll(Game.rng), global_position, _player.states, _cast)


func _on_damaged(info: DamageInfo) -> void:
	health = maxf(health - info.amount, 0.0)
	health_bar.set_health(health, max_health)
	sprite.flash()
	if health <= 0.0:
		queue_free()
