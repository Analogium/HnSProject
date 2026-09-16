extends GutTest

## Le critère de réussite du jalon 6, joué en entier : un personnage neuf ramasse
## le manuel tombé à ses pieds, le pose au râtelier, tue jusqu'à ce qu'il monte,
## place ses points, assigne la compétence à une touche, la lance — puis sort le
## livre du râtelier, l'y remet, ferme le jeu, le relance, et retrouve tout.
##
## Chaque règle est vérifiée pièce par pièce ailleurs. Ce qui manquait est la
## **chaîne** : le livre part du sol, traverse le sac, le râtelier, la page, la
## barre, une touche, un projectile, le disque, et revient. Un maillon rompu au
## milieu laisserait vertes toutes les suites unitaires.

const SEED := 4242
## Trois points dans « Éclair vif », donc le manuel doit atteindre le niveau 3 :
## un point par niveau, le premier compris.
const TARGET_LEVEL := 3

var _zone: Node2D
var _id := ""


func before_each() -> void:
	Game.zone_level = 1
	Game.character = SaveStore.create("Foudroyante", 1)
	_id = Game.character.id
	_zone = load("res://world/zone.tscn").instantiate()
	add_child_autofree(_zone)
	await wait_physics_frames(1)
	_zone.generate_zone(SEED)
	# Le décor se pose avant qu'on regarde : la zone a déjà engendré sa carte
	# dans son `_ready`, et le butin de la première naît par `add_child` différé
	# tandis que celui d'avant meurt par `queue_free()`. Sans ces deux images,
	# on saisirait le livre déjà condamné plutôt que celui qui reste.
	await wait_process_frames(2)


func after_each() -> void:
	# Une image avant de démonter : la dernière génération a pu poser un livre
	# par `add_child` différé, et une zone libérée avant lui laisse un objet
	# instancié que plus personne n'attache — donc que plus personne ne libère.
	await wait_process_frames(1)
	SaveStore.delete(_id)
	Game.character = null


## L'équivalent d'avoir relancé le jeu : on relit le fichier du disque dans un
## corps neuf, comme le fait le démarrage, moins la fenêtre.
func _recast() -> Player:
	var reread := SaveStore.read(_id)
	assert_not_null(reread, "le fichier se relit")
	var body: Player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(body)
	await wait_physics_frames(1)
	body.load_character(reread)
	return body


## Le manuel tombé aux pieds d'un personnage neuf, et rien d'autre au sol : il ne
## doit pas falloir le chercher.
func test_a_new_character_finds_a_manual_at_its_feet() -> void:
	var books := 0
	for child in _zone.loot.get_children():
		if (child as GroundItem).data.manual != null:
			books += 1
	assert_eq(books, 1, "un manuel, un seul")
	assert_false(_zone.player.manual_given, "tant qu'il est au sol, rien n'est donné")

	# **À ses pieds**, et c'est tout l'objet de la règle : un livre posé ailleurs
	# sur la carte ne serait pas un cadeau mais une chasse. La position d'un objet
	# au sol est écrite en différé, d'où l'image d'attente.
	await wait_physics_frames(1)
	for child in _zone.loot.get_children():
		var on_ground := child as GroundItem
		if on_ground.data.manual == null:
			continue
		assert_lt(
			on_ground.global_position.distance_to(_zone.player.global_position), 24.0,
			"le manuel est à %.0f px du joueur" % on_ground.global_position.distance_to(
				_zone.player.global_position
			)
		)

	# Regénérer efface le butin au sol : le livre doit être **reposé**, sinon un
	# F5 dans les premières secondes détruirait le seul manuel du personnage.
	# Une image d'attente d'abord — `kill_all()` libère par `queue_free()`.
	_zone.generate_zone(SEED + 1)
	# Deux images de rendu : `queue_free()` ne libère qu'à la fin d'une image
	# d'inactivité, et le livre neuf arrive lui-même par `add_child` différé.
	await wait_process_frames(2)
	books = 0
	for child in _zone.loot.get_children():
		if (child as GroundItem).data.manual != null:
			books += 1
	assert_eq(books, 1, "il est de nouveau à ses pieds, pas perdu")

	# Une fois pris, on ne lui en donne pas un second.
	_zone.player.pick_up(Item.new(ItemCatalog.by_id(ItemCatalog.ID_STARTING_MANUAL)))
	assert_true(_zone.player.manual_given, "le ramassage pose le drapeau")
	_zone.generate_zone(SEED + 2)
	await wait_process_frames(2)
	for child in _zone.loot.get_children():
		assert_null((child as GroundItem).data.manual, "pas de second livre")


func test_the_milestone_6_criterion() -> void:
	var player: Player = _zone.player
	# La paix, le temps de ramasser : à soixante-neuf ennemis, un personnage neuf
	# meurt avant la fin du délai de ramassage, et la zone se recharge sous ses
	# pieds — le livre au sol avec elle. On repeuple juste après, pour l'expérience.
	_zone.enemy_manager.clear()

	# --- « ramasser le manuel tombé à ses pieds » ---
	var on_ground: GroundItem = null
	for child in _zone.loot.get_children():
		if (child as GroundItem).data.manual != null:
			on_ground = child
	assert_not_null(on_ground, "le manuel est au sol")
	if on_ground == null:
		return
	var book: Item = on_ground.data

	# Le délai de ramassage passe d'abord. Le livre tombe à quatorze pixels des
	# pieds du joueur, donc il se ramasse **tout seul** dès la fin du délai : on
	# est déjà dessus. C'est ce qu'on veut en jouant — le premier manuel ne doit
	# pas se rater — et c'est au test de s'y adapter plutôt que l'inverse.
	await wait_physics_frames(int(GroundItem.DROP_DELAY * 60.0) + 6)
	if is_instance_valid(on_ground):
		player.global_position = on_ground.global_position
		await wait_physics_frames(4)
	assert_eq(player.inventory.placed.size(), 1, "il est dans le sac")

	# --- « le poser au râtelier » ---
	player.inventory.take_at(player.inventory.placed[0].cell)
	assert_null(player.study(book), "le râtelier était vide")
	assert_same(player.rack.at(0), book)

	# --- « tuer jusqu'à ce qu'il monte » ---
	# La zone se repeuple : le livre est au râtelier, plus rien au sol à perdre.
	_zone.generate_zone(SEED)
	var kills := 0
	for e in _zone.enemy_manager.enemies.duplicate():
		if book.manual.level() >= TARGET_LEVEL:
			break
		if is_instance_valid(e):
			e.die()
			kills += 1
	await wait_physics_frames(2)
	assert_gte(book.manual.level(), TARGET_LEVEL, "le livre a monté en %d morts" % kills)
	gut.p("  niveau %d du manuel en %d ennemis" % [book.manual.level(), kills])

	# --- « placer trois points dans Éclair vif » ---
	for i in TARGET_LEVEL:
		assert_true(book.manual.invest(book.base.manual, "swift_bolt"), "point %d" % (i + 1))
	assert_eq(book.manual.points_of("swift_bolt"), TARGET_LEVEL)
	assert_eq(book.manual.remaining_points(), 0, "tout est dépensé")

	# --- « l'assigner à la touche A » ---
	# La troisième case, celle que la carte d'entrées appelle competence_3.
	player.bar.put(2, "swift_bolt")
	# La **position** liée, et non la lettre : celle-ci dépend de la disposition
	# du clavier, et c'est justement ce que la barre traduit à l'écran. Sur un
	# clavier français, cette position-là porte le A.
	var touches := InputMap.action_get_events("skill_3")
	assert_gt(touches.size(), 0, "la troisième case a une touche")
	assert_eq(
		(touches[0] as InputEventKey).physical_keycode, KEY_Q,
		"la position du Q américain, c'est-à-dire le A d'un clavier français"
	)

	# --- « le lancer » ---
	var before: int = _zone.projectiles.get_child_count()
	assert_true(player.cast_slot(2), "l'éclair part")
	assert_eq(_zone.projectiles.get_child_count(), before + 1)

	# --- « placer un point d'intelligence et voir le nombre monter » : la réserve, depuis
	# que les compétences ne montent plus avec un attribut (15 septembre 2026), par un
	# nœud de l'arbre depuis le jalon 16 ---
	var pool_before := player.stats.max_mana
	player.level += 1
	assert_true(player.take_passive("int_1"))
	assert_gt(player.stats.max_mana, pool_before, "un nœud d'intelligence nourrit la réserve")

	# --- « sortir le manuel du râtelier, le remettre » ---
	var refunded := player.stop_studying(0)
	assert_same(refunded, book, "c'est bien lui qui sort")
	assert_eq(player.bar.id_of(2), "", "la case qui le désignait s'est vidée")
	assert_null(player.study(book))
	assert_eq(book.manual.points_of("swift_bolt"), TARGET_LEVEL, "il a gardé ses points")

	# --- « fermer le jeu, le relancer, tout retrouver » ---
	player.bar.put(2, "swift_bolt")
	_zone.save()
	var after := await _recast()

	var studied := after.rack.at(0)
	assert_not_null(studied, "le livre est revenu au râtelier")
	if studied == null:
		return
	assert_eq(studied.manual.points_of("swift_bolt"), TARGET_LEVEL, "avec ses trois points")
	assert_eq(after.bar.id_of(2), "swift_bolt", "et la touche A le lance encore")
	assert_true(after.manual_given, "on ne lui en redonnera pas un second")
	assert_eq(after.skill_points("swift_bolt"), TARGET_LEVEL, "il sait toujours le lancer")


## Le parcours réel d'un personnage neuf : l'écran de sélection pose le
## personnage, la zone naît, et **une seule** génération a lieu. C'est le cas que
## l'ordre d'avant servait mal — le livre tombait à l'endroit où le joueur se
## trouvait encore, c'est-à-dire au coin de la scène, avant que la carte neuve ne
## l'ait posé sur son point d'apparition.
##
## Ce test monte donc sa propre zone et ne la regénère pas : regénérer une
## seconde fois masque le défaut, puisque le joueur est alors déjà quelque part.
func test_the_manual_drops_at_the_feet_on_first_entry() -> void:
	var fresh_one: Node2D = load("res://world/zone.tscn").instantiate()
	add_child_autofree(fresh_one)
	# Deux images : la position d'un objet au sol est écrite en différé.
	await wait_process_frames(2)

	var found: GroundItem = null
	for child in fresh_one.loot.get_children():
		var on_ground := child as GroundItem
		if on_ground != null and on_ground.data.manual != null:
			found = on_ground
	assert_not_null(found, "un manuel est au sol dès l'entrée")
	if found == null:
		return

	var distance := found.global_position.distance_to(fresh_one.player.global_position)
	assert_lt(distance, 24.0, "il est à %.0f px du joueur" % distance)
	# Et sur du sol praticable : un livre tombé dans la pierre serait visible et
	# inatteignable, ce qui est pire que pas de livre du tout.
	assert_true(
		fresh_one.generator.floor_cells.has(MapGenerator.cell_at(found.global_position)),
		"il est posé sur une case praticable"
	)
