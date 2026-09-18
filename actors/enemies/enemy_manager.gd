class_name EnemyManager
extends Node2D

## **Le pilote unique de tous les ennemis** : aucun n'a de _physics_process. D'où le
## culling, et un ralenti propre aux ennemis.

const CULL_DISTANCE := 700.0   # au-delà, on ne tick pas

## Dérivé du culling : au-delà, personne n'est tické.
const FIELD_CELLS := int(CULL_DISTANCE / float(MapGenerator.TILE)) + 2
## Délai entre deux recalculs : un joueur immobile sur une frontière de cases
## rebâtirait le champ à chaque image.
const FIELD_PERIOD := 0.10

var enemies: Array[Enemy] = []
var target: Node2D

## Le niveau de la zone, posé par elle. Un champ et non l'autoload : un test le règle.
var level := 1

## Facultatif : null sans carte (arène, banc, tests), où la ligne droite suffit.
var field: FlowField

var _field_cd := 0.0

## Les ennemis tickés à la dernière image, culling déduit, pour le banc.
var ticked := 0

## Où atterrissent les projectiles. Laissé à null, ils naissent sous le manager.
## L'arène lui donne un conteneur dédié pour pouvoir les balayer d'un coup.
var projectile_parent: Node2D

## Où atterrit le butin. Même principe, et séparé des projectiles : on balaie
## les tirs au rechargement d'une zone, jamais les objets au sol.
var loot_parent: Node2D


func _ready() -> void:
	if projectile_parent == null:
		projectile_parent = self
	if loot_parent == null:
		loot_parent = self


## **Le seul chemin** pour poser un ennemi.
func spawn(scene: PackedScene, at: Vector2) -> Enemy:
	if scene == null:
		return null
	var enemy: Enemy = scene.instantiate()
	enemy.position = at
	# Avant add_child : c'est _ready qui met la fiche à l'échelle, et il part
	# dès l'entrée dans l'arbre.
	enemy.level = level
	add_child(enemy)
	register(enemy)
	return enemy


## Sans récompense ; sur une copie, puisque `die()` retire l'ennemi de la liste.
func clear() -> void:
	for e in enemies.duplicate():
		if is_instance_valid(e):
			e.die(false)


func register(enemy: Enemy) -> void:
	enemy.manager = self
	enemy.setup(target)
	enemy.died.connect(_on_enemy_died)
	enemies.append(enemy)


func _physics_process(delta: float) -> void:
	if target == null:
		return

	_update_field(delta)

	var origin := target.global_position
	var cull_sq := CULL_DISTANCE * CULL_DISTANCE
	ticked = 0

	# À l'envers, et revalidé : un tick peut retirer d'autres ennemis (mort en chaîne,
	# rechargement de la zone), la liste rétrécit sous nos pieds.
	for i in range(enemies.size() - 1, -1, -1):
		if i >= enemies.size():
			continue
		var e := enemies[i]
		if not is_instance_valid(e) or e.is_dead:
			enemies.remove_at(i)
			continue
		if origin.distance_squared_to(e.global_position) > cull_sq:
			continue
		ticked += 1
		if not e.states.is_clear:
			e.suffer_states(delta)
		e.regen(delta)
		e.tick(delta)


## Quand la cible a changé de case, au plus toutes les FIELD_PERIOD.
func _update_field(delta: float) -> void:
	if field == null:
		return
	_field_cd = maxf(_field_cd - delta, 0.0)
	if _field_cd > 0.0:
		return
	var cell := MapGenerator.cell_at(target.global_position)
	if cell == field.origin:
		return
	field.rebuild(cell, FIELD_CELLS)
	_field_cd = FIELD_PERIOD


## Le manager connaît le joueur, pas l'ennemi : c'est lui qui fait remonter la
## récompense.
func report_kill(enemy: Enemy) -> void:
	var player := target as Player
	if player == null:
		return
	# Au-dessus du corps : le gain s'attribue à la cible choisie.
	player.reward(float(enemy.xp_value()), level, enemy.global_position)
	_drop_loot(enemy, player)


## Seulement depuis report_kill : jamais pour un vidage ni pour le banc.
func _drop_loot(enemy: Enemy, player: Player) -> void:
	var item := LootTable.roll(enemy.affixes.size(), level)
	if item == null:
		return
	GroundItem.spawn(loot_parent, enemy.global_position, item, player)


func _on_enemy_died(enemy: Enemy) -> void:
	enemies.erase(enemy)
