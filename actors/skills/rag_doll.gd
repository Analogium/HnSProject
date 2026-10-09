class_name RagDoll
extends Node2D

## La Poupée de chiffon (jalon 41) : un fétiche posé au point visé, que les ennemis
## frappent à la place du joueur quand elle est plus près d'eux (`Enemy.foe()`). Elle
## éclate en tombant ou au bout de sa durée — son rayon, dans la nature de son tour —, et
## en reposer une fait éclater l'ancienne. Sa hurtbox est sur le calque du joueur, comme
## un mort-vivant : les tirs ennemis la touchent.

## La part des PV max du lanceur qu'elle reçoit, avant le Rembourrage. Premier réglage.
const LIFE := 0.6
const HURT_RADIUS := 8.0

## Toutes celles qui tiennent debout, pour les ennemis qui cherchent qui frapper.
static var standing: Array[RagDoll] = []

## Lue par les ennemis qui la frappent au contact, comme celle du joueur.
var hurtbox: Hurtbox
var health := 1.0
var max_health := 1.0
var _player: Player
var _cast: SkillStats
## L'Appeau, en px : de combien elle paraît plus proche aux ennemis qui choisissent.
var lure := 0.0
var _bar: HealthBar
var _age := 0.0
var _fallen := false
## Ce qu'elle a encaissé, coups et Transfert : la Rancune en rend une part à l'éclat.
var _absorbed := 0.0


## Fait éclater la plus ancienne de ce joueur quand elles sont au complet — une seule, sauf
## les Jumelles —, puis pose la nouvelle.
static func place(player: Player, point: Vector2, cast: SkillStats, parent: Node) -> RagDoll:
	var own := standing.filter(func(d: RagDoll) -> bool: return d._player == player and not d._fallen)
	for old in cast.crowded(own):
		(old as RagDoll)._fall()
	var doll := RagDoll.new()
	doll._player = player
	doll._cast = cast
	doll.lure = cast.lure
	doll.max_health = maxf(player.stats.max_health * life_part(cast), 1.0)
	doll.health = doll.max_health
	parent.add_child(doll)
	Settings.veil(doll, Settings.SPELLS)
	doll.global_position = point
	return doll


## La part des PV max du lanceur qu'elle reçoit : **le seul calcul**, que la fiche lit.
static func life_part(cast: SkillStats) -> float:
	return LIFE * (1.0 + cast.doll_life * 0.01)


## Le Transfert (jalon 41) : la première de ce joueur encore debout prend cette part de ce
## qu'il subit. Rend ce qu'elle a pris — pas plus que ses PV —, que le joueur n'a pas à subir.
static func shoulder(player: Player, amount: float) -> float:
	for doll in standing:
		if doll._player == player and not doll._fallen and doll._cast.transfer > 0.0:
			return doll._suffer(amount * minf(doll._cast.transfer * 0.01, 1.0))
	return 0.0


func _enter_tree() -> void:
	standing.append(self)


func _exit_tree() -> void:
	standing.erase(self)


func _ready() -> void:
	y_sort_enabled = true
	hurtbox = Hurtbox.new()
	hurtbox.collision_layer = Targets.PLAYER_SIDE
	hurtbox.collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = HURT_RADIUS
	shape.shape = circle
	hurtbox.add_child(shape)
	add_child(hurtbox)
	hurtbox.damaged.connect(_on_damaged)
	_bar = HealthBar.new()
	add_child(_bar)
	_bar.set_health(health, max_health)


## Un livre rangé ou un joueur tombé la font tomber, sans éclat : ce n'est pas un coup.
func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player) or _player.is_dead \
			or _player.skill_points(_cast.skill_id) <= 0:
		queue_free()
		return
	_age += delta
	if _age >= _cast.duration:
		_fall()
		return
	queue_redraw()


func _on_damaged(info: DamageInfo) -> void:
	_suffer(info.amount)


## Rend ce qu'elle a vraiment encaissé : ce qui dépasse ses PV ne s'absorbe pas.
func _suffer(amount: float) -> float:
	if _fallen:
		return 0.0
	var taken := minf(amount, health)
	_absorbed += taken
	health -= taken
	_bar.set_health(health, max_health)
	if health <= 0.0:
		_fall()
	return taken


## L'éclat, une fois : en différé, la blessure qui la fait tomber arrive d'un rappel de
## collision (`Explosion.put()` passe par `DeferredTree`).
func _fall() -> void:
	if _fallen:
		return
	_fallen = true
	var parts := _cast.roll(Game.rng)
	parts[_cast.nature] += _absorbed * _cast.grudge * 0.01
	Explosion.put(
		get_parent(), global_position, parts, _cast.radius, null,
		DamageType.COLORS[_cast.nature], _player.states, _cast
	)
	queue_free()


## La poupée (`EffectForge.doll()`), la robe à la teinte de son tour, les pieds sur sa place.
func _draw() -> void:
	var tex := EffectForge.doll(DamageType.COLORS[_cast.nature])
	EffectForge.put_centered(self, tex, Vector2(0.0, -tex.get_height() * 0.5 + 2.0))
