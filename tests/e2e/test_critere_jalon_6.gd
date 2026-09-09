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

const GRAINE := 4242
## Trois points dans « Éclair vif », donc le manuel doit atteindre le niveau 3 :
## un point par niveau, le premier compris.
const NIVEAU_VISE := 3

var _zone: Node2D
var _id := ""


func before_each() -> void:
	Game.niveau_de_zone = 1
	Game.personnage = Sauvegarde.creer("Foudroyante", 1)
	_id = Game.personnage.id
	_zone = load("res://world/zone.tscn").instantiate()
	add_child_autofree(_zone)
	await wait_physics_frames(1)
	_zone.generate_zone(GRAINE)
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
	Sauvegarde.supprimer(_id)
	Game.personnage = null


## L'équivalent d'avoir relancé le jeu : on relit le fichier du disque dans un
## corps neuf, comme le fait le démarrage, moins la fenêtre.
func _relancer() -> Player:
	var relu := Sauvegarde.lire(_id)
	assert_not_null(relu, "le fichier se relit")
	var corps: Player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(corps)
	await wait_physics_frames(1)
	corps.charger(relu)
	return corps


## Le manuel tombé aux pieds d'un personnage neuf, et rien d'autre au sol : il ne
## doit pas falloir le chercher.
func test_un_personnage_neuf_trouve_un_manuel_a_ses_pieds() -> void:
	var livres := 0
	for enfant in _zone.loot.get_children():
		if (enfant as GroundItem).data.manuel != null:
			livres += 1
	assert_eq(livres, 1, "un manuel, un seul")
	assert_false(_zone.player.manuel_offert, "tant qu'il est au sol, rien n'est donné")

	# **À ses pieds**, et c'est tout l'objet de la règle : un livre posé ailleurs
	# sur la carte ne serait pas un cadeau mais une chasse. La position d'un objet
	# au sol est écrite en différé, d'où l'image d'attente.
	await wait_physics_frames(1)
	for enfant in _zone.loot.get_children():
		var au_sol := enfant as GroundItem
		if au_sol.data.manuel == null:
			continue
		assert_lt(
			au_sol.global_position.distance_to(_zone.player.global_position), 24.0,
			"le manuel est à %.0f px du joueur" % au_sol.global_position.distance_to(
				_zone.player.global_position
			)
		)

	# Regénérer efface le butin au sol : le livre doit être **reposé**, sinon un
	# F5 dans les premières secondes détruirait le seul manuel du personnage.
	# Une image d'attente d'abord — `kill_all()` libère par `queue_free()`.
	_zone.generate_zone(GRAINE + 1)
	# Deux images de rendu : `queue_free()` ne libère qu'à la fin d'une image
	# d'inactivité, et le livre neuf arrive lui-même par `add_child` différé.
	await wait_process_frames(2)
	livres = 0
	for enfant in _zone.loot.get_children():
		if (enfant as GroundItem).data.manuel != null:
			livres += 1
	assert_eq(livres, 1, "il est de nouveau à ses pieds, pas perdu")

	# Une fois pris, on ne lui en donne pas un second.
	_zone.player.pick_up(Item.new(ItemCatalog.by_id(ItemCatalog.ID_MANUEL_DE_DEPART)))
	assert_true(_zone.player.manuel_offert, "le ramassage pose le drapeau")
	_zone.generate_zone(GRAINE + 2)
	await wait_process_frames(2)
	for enfant in _zone.loot.get_children():
		assert_null((enfant as GroundItem).data.manuel, "pas de second livre")


func test_le_critere_du_jalon_6() -> void:
	var joueur: Player = _zone.player
	# La paix, le temps de ramasser : à soixante-neuf ennemis, un personnage neuf
	# meurt avant la fin du délai de ramassage, et la zone se recharge sous ses
	# pieds — le livre au sol avec elle. On repeuple juste après, pour l'expérience.
	_zone.enemy_manager.clear()

	# --- « ramasser le manuel tombé à ses pieds » ---
	var au_sol: GroundItem = null
	for enfant in _zone.loot.get_children():
		if (enfant as GroundItem).data.manuel != null:
			au_sol = enfant
	assert_not_null(au_sol, "le manuel est au sol")
	if au_sol == null:
		return
	var livre: Item = au_sol.data

	# Le délai de ramassage passe d'abord. Le livre tombe à quatorze pixels des
	# pieds du joueur, donc il se ramasse **tout seul** dès la fin du délai : on
	# est déjà dessus. C'est ce qu'on veut en jouant — le premier manuel ne doit
	# pas se rater — et c'est au test de s'y adapter plutôt que l'inverse.
	await wait_physics_frames(int(GroundItem.DROP_DELAY * 60.0) + 6)
	if is_instance_valid(au_sol):
		joueur.global_position = au_sol.global_position
		await wait_physics_frames(4)
	assert_eq(joueur.inventory.placed.size(), 1, "il est dans le sac")

	# --- « le poser au râtelier » ---
	joueur.inventory.take_at(joueur.inventory.placed[0].cell)
	assert_null(joueur.etudier(livre), "le râtelier était vide")
	assert_same(joueur.ratelier.a(0), livre)

	# --- « tuer jusqu'à ce qu'il monte » ---
	# La zone se repeuple : le livre est au râtelier, plus rien au sol à perdre.
	_zone.generate_zone(GRAINE)
	var tues := 0
	for e in _zone.enemy_manager.enemies.duplicate():
		if livre.manuel.niveau() >= NIVEAU_VISE:
			break
		if is_instance_valid(e):
			e.die()
			tues += 1
	await wait_physics_frames(2)
	assert_gte(livre.manuel.niveau(), NIVEAU_VISE, "le livre a monté en %d morts" % tues)
	gut.p("  niveau %d du manuel en %d ennemis" % [livre.manuel.niveau(), tues])

	# --- « placer trois points dans Éclair vif » ---
	for i in NIVEAU_VISE:
		assert_true(livre.manuel.investir(livre.base.manuel, "eclair_vif"), "point %d" % (i + 1))
	assert_eq(livre.manuel.points_de("eclair_vif"), NIVEAU_VISE)
	assert_eq(livre.manuel.points_restants(), 0, "tout est dépensé")

	# --- « l'assigner à la touche A » ---
	# La troisième case, celle que la carte d'entrées appelle competence_3.
	joueur.barre.poser(2, "eclair_vif")
	# La **position** liée, et non la lettre : celle-ci dépend de la disposition
	# du clavier, et c'est justement ce que la barre traduit à l'écran. Sur un
	# clavier français, cette position-là porte le A.
	var touches := InputMap.action_get_events("competence_3")
	assert_gt(touches.size(), 0, "la troisième case a une touche")
	assert_eq(
		(touches[0] as InputEventKey).physical_keycode, KEY_Q,
		"la position du Q américain, c'est-à-dire le A d'un clavier français"
	)

	# --- « le lancer » ---
	var avant: int = _zone.projectiles.get_child_count()
	assert_true(joueur.lancer(2), "l'éclair part")
	assert_eq(_zone.projectiles.get_child_count(), avant + 1)

	# --- « placer un point d'intelligence et voir le nombre monter » ---
	var competence := CompetenceCatalog.by_id("eclair_vif")
	var degats_avant := competence.degats(NIVEAU_VISE, joueur.stats)
	joueur.unspent_points += 1
	assert_true(joueur.spend_point("intelligence"))
	assert_gt(
		competence.degats(NIVEAU_VISE, joueur.stats), degats_avant,
		"un point d'intelligence rend l'éclair plus fort"
	)

	# --- « sortir le manuel du râtelier, le remettre » ---
	var repris := joueur.cesser_d_etudier(0)
	assert_same(repris, livre, "c'est bien lui qui sort")
	assert_eq(joueur.barre.id_de(2), "", "la case qui le désignait s'est vidée")
	assert_null(joueur.etudier(livre))
	assert_eq(livre.manuel.points_de("eclair_vif"), NIVEAU_VISE, "il a gardé ses points")

	# --- « fermer le jeu, le relancer, tout retrouver » ---
	joueur.barre.poser(2, "eclair_vif")
	_zone.sauvegarder()
	var apres := await _relancer()

	var etudie := apres.ratelier.a(0)
	assert_not_null(etudie, "le livre est revenu au râtelier")
	if etudie == null:
		return
	assert_eq(etudie.manuel.points_de("eclair_vif"), NIVEAU_VISE, "avec ses trois points")
	assert_eq(apres.barre.id_de(2), "eclair_vif", "et la touche A le lance encore")
	assert_true(apres.manuel_offert, "on ne lui en redonnera pas un second")
	assert_eq(apres.points_de_competence("eclair_vif"), NIVEAU_VISE, "il sait toujours le lancer")


## Le parcours réel d'un personnage neuf : l'écran de sélection pose le
## personnage, la zone naît, et **une seule** génération a lieu. C'est le cas que
## l'ordre d'avant servait mal — le livre tombait à l'endroit où le joueur se
## trouvait encore, c'est-à-dire au coin de la scène, avant que la carte neuve ne
## l'ait posé sur son point d'apparition.
##
## Ce test monte donc sa propre zone et ne la regénère pas : regénérer une
## seconde fois masque le défaut, puisque le joueur est alors déjà quelque part.
func test_le_manuel_tombe_aux_pieds_des_la_premiere_entree() -> void:
	var neuve: Node2D = load("res://world/zone.tscn").instantiate()
	add_child_autofree(neuve)
	# Deux images : la position d'un objet au sol est écrite en différé.
	await wait_process_frames(2)

	var trouve: GroundItem = null
	for enfant in neuve.loot.get_children():
		var au_sol := enfant as GroundItem
		if au_sol != null and au_sol.data.manuel != null:
			trouve = au_sol
	assert_not_null(trouve, "un manuel est au sol dès l'entrée")
	if trouve == null:
		return

	var distance := trouve.global_position.distance_to(neuve.player.global_position)
	assert_lt(distance, 24.0, "il est à %.0f px du joueur" % distance)
	# Et sur du sol praticable : un livre tombé dans la pierre serait visible et
	# inatteignable, ce qui est pire que pas de livre du tout.
	assert_true(
		neuve.generator.floor_cells.has(MapGenerator.cell_at(trouve.global_position)),
		"il est posé sur une case praticable"
	)
