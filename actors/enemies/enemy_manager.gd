class_name EnemyManager
extends Node2D

## Pilote unique de tous les ennemis : aucun d'eux n'a de _physics_process.
## C'est le point structurant du jalon. Ça ne coûte rien aujourd'hui et ça donne
## gratuitement le culling par distance, le passage aux tableaux packés le jour
## où le profileur le demande, et le ralenti / pause / debug step sur les
## ennemis seuls.

const CULL_DISTANCE := 700.0   # au-delà, on ne tick pas

## Rayon du champ de flux, en cases. Dérivé de la distance de culling et non
## posé à part : au-delà, l'ennemi n'est plus tické, et lui calculer un chemin
## serait du travail pour quelqu'un de figé.
const FIELD_CELLS := int(CULL_DISTANCE / float(MapGenerator.TILE)) + 2
## Délai minimal entre deux recalculs. Le joueur immobile sur une frontière de
## cases bascule de l'une à l'autre à chaque image : sans ce délai, chaque image
## paierait un parcours complet de la carte.
const FIELD_PERIOD := 0.10

var enemies: Array[Enemy] = []
var target: Node2D

## Le niveau de la zone : celui des ennemis qui y naissent, et celui des objets
## qui y tombent. Posé par la zone depuis `Game.niveau_de_zone`.
##
## Ici et non lu sur l'autoload à chaque mort : le manager est le pilote unique,
## et un champ se règle depuis un test là où une variable globale se subit. Les
## scènes de réglage — l'arène, le banc de stress — le laissent à 1.
var niveau := 1

## Le chemin vers la cible, partagé par tous les ennemis. **Facultatif** : null
## dans les scènes sans carte — l'arène de réglage, le banc de stress, les tests
## d'intégration — où les ennemis foncent en ligne droite, ce qui est
## exactement ce qu'il faut faire dans une pièce sans mur.
var field: FlowField

var _field_cd := 0.0

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


## Pose un ennemi dans le monde et l'enregistre. Quatre appelants écrivaient les
## quatre mêmes lignes — la zone, l'arène, le banc de mesure et le peupleur — et
## le jour où poser un ennemi demandera une étape de plus, elle s'ajoutera ici.
func spawn(scene: PackedScene, at: Vector2) -> Enemy:
	if scene == null:
		return null
	var enemy: Enemy = scene.instantiate()
	enemy.position = at
	# Avant add_child : c'est _ready qui met la fiche à l'échelle, et il part
	# dès l'entrée dans l'arbre.
	enemy.niveau = niveau
	add_child(enemy)
	register(enemy)
	return enemy


## Tue tout le monde sans récompense : un vidage n'est pas une victoire.
##
## Sur une copie de la liste : die() émet died, que le manager traite en
## retirant l'ennemi — on ne parcourt pas une liste qu'on modifie.
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
		e.regen(delta)
		e.tick(delta)


## Recalcule le chemin quand la cible a changé de case, et pas plus souvent que
## FIELD_PERIOD. Un champ vieux de quelques centièmes de seconde ne trompe
## personne : il pointe vers l'endroit où le joueur était, à une case près.
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


## L'ennemi ne connaît pas le joueur, le manager si. C'est donc lui qui fait
## remonter la récompense, plutôt que de donner à chaque ennemi une référence
## vers le joueur dont il n'a besoin qu'à sa mort.
func report_kill(enemy: Enemy) -> void:
	var player := target as Player
	if player == null:
		return
	# L'expérience fond quand la zone dépasse le personnage de plus de cinq
	# niveaux. Le butin, lui, garde le niveau de la zone : c'est ce qui fait
	# qu'aller trop loin reste payant sans devenir le chemin le plus court.
	var gain := maxi(roundi(enemy.xp_value() * Enemy.facteur_d_experience(niveau, player.level)), 1)
	player.gain_xp(gain)
	# Au-dessus du corps et non au-dessus du joueur : c'est l'ennemi tombé qui
	# rapporte, et on doit pouvoir attribuer le gain à la cible qu'on a choisie.
	if HitFeedback.current != null:
		HitFeedback.current.xp_gain(enemy.global_position, gain)
	_drop_loot(enemy)


## Appelée uniquement depuis report_kill, donc jamais pour un vidage de zone ni
## pour le banc de mesure : ceux-là passent die(false).
func _drop_loot(enemy: Enemy) -> void:
	var item := LootTable.roll(enemy.affixes.size(), niveau)
	if item == null:
		return
	GroundItem.spawn(loot_parent, enemy.global_position, item)


func _on_enemy_died(enemy: Enemy) -> void:
	enemies.erase(enemy)
