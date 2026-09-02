class_name EnemyManager
extends Node2D

## Pilote unique de tous les ennemis : aucun d'eux n'a de _physics_process.
## C'est le point structurant du jalon. Ça ne coûte rien aujourd'hui et ça donne
## gratuitement le culling par distance, le passage aux tableaux packés le jour
## où le profileur le demande, et le ralenti / pause / debug step sur les
## ennemis seuls.

const CULL_DISTANCE := 700.0   # au-delà, on ne tick pas

var enemies: Array[Enemy] = []
var target: Node2D

## Où atterrissent les projectiles. Laissé à null, ils naissent sous le manager.
## L'arène lui donne un conteneur dédié pour pouvoir les balayer d'un coup.
var projectile_parent: Node2D


func _ready() -> void:
	if projectile_parent == null:
		projectile_parent = self


func register(enemy: Enemy) -> void:
	enemy.manager = self
	enemy.setup(target)
	enemy.died.connect(_on_enemy_died)
	enemies.append(enemy)


func _physics_process(delta: float) -> void:
	if target == null:
		return

	var origin := target.global_position
	var cull_sq := CULL_DISTANCE * CULL_DISTANCE

	# Parcours à l'envers : on peut retirer des éléments sans casser l'index.
	#
	# Mais range() est figé à l'entrée, alors qu'un tick peut retirer d'autres
	# ennemis que celui en cours : mort en chaîne, ou rechargement complet de
	# la zone déclenché par la mort du joueur. La liste rétrécit donc sous nos
	# pieds et les indices restants pointent dans le vide — d'où la revalidation.
	for i in range(enemies.size() - 1, -1, -1):
		if i >= enemies.size():
			continue
		var e := enemies[i]
		if not is_instance_valid(e) or e.is_dead:
			enemies.remove_at(i)
			continue
		if origin.distance_squared_to(e.global_position) > cull_sq:
			continue
		e.tick(delta)


func _on_enemy_died(enemy: Enemy) -> void:
	enemies.erase(enemy)
