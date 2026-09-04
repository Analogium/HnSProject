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

## Nombre d'ennemis réellement tickés à la dernière image, culling déduit. Lu
## par la scène de stress test : sans ce chiffre, on ne sait pas si trois cents
## ennemis coûtent peu parce que le code est bon ou parce que deux cent quatre
## vingts sont hors portée.
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
	ticked = 0

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
		ticked += 1
		e.tick(delta)


## L'ennemi ne connaît pas le joueur, le manager si. C'est donc lui qui fait
## remonter la récompense, plutôt que de donner à chaque ennemi une référence
## vers le joueur dont il n'a besoin qu'à sa mort.
func report_kill(enemy: Enemy) -> void:
	var player := target as Player
	if player == null:
		return
	var gain := enemy.xp_value()
	player.gain_xp(gain)
	# Au-dessus du corps et non au-dessus du joueur : c'est l'ennemi tombé qui
	# rapporte, et on doit pouvoir attribuer le gain à la cible qu'on a choisie.
	if HitFeedback.current != null:
		HitFeedback.current.xp_gain(enemy.global_position, gain)
	_drop_loot(enemy)


## Appelée uniquement depuis report_kill, donc jamais pour un vidage de zone ni
## pour le banc de mesure : ceux-là passent die(false).
func _drop_loot(enemy: Enemy) -> void:
	var item := LootTable.roll(enemy.affixes.size())
	if item == null:
		return
	GroundItem.spawn(loot_parent, enemy.global_position, item)


func _on_enemy_died(enemy: Enemy) -> void:
	enemies.erase(enemy)
