extends GutTest

## Le critère de réussite du jalon 3, joué en entier : créer un personnage, le
## jouer, gagner des niveaux et un objet, fermer, relancer, tout retrouver.
##
## « Fermer et relancer » se joue ici en libérant la zone et en relisant le
## fichier depuis le disque, puis en le rechargeant dans un corps neuf. C'est ce
## que fait le jeu au démarrage, moins la fenêtre.

const GRAINE := 4242

var _zone: Node2D
var _id := ""


func before_each() -> void:
	Game.personnage = Sauvegarde.creer("Persistante", 1)
	_id = Game.personnage.id
	_zone = load("res://world/zone.tscn").instantiate()
	add_child_autofree(_zone)
	await wait_physics_frames(1)
	_zone.generate_zone(GRAINE)


func after_each() -> void:
	Sauvegarde.supprimer(_id)
	Game.personnage = null


## Recharge le personnage depuis le disque dans un corps neuf — l'équivalent
## d'avoir relancé le jeu.
func _relancer() -> Player:
	var relu := Sauvegarde.lire(_id)
	assert_not_null(relu, "le fichier se relit")
	var corps: Player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(corps)
	await wait_physics_frames(1)
	corps.charger(relu)
	return corps


func test_un_personnage_neuf_arrive_dans_la_zone() -> void:
	assert_eq(_zone.player.level, 1)
	assert_eq(_zone.player.sprite.current_variant(), 1, "sa silhouette, pas celle par défaut")
	assert_eq(_zone.player.inventory.placed.size(), 0, "les mains vides")


func test_le_critere_du_jalon() -> void:
	# Jouer : deux niveaux et un plastron.
	_zone.player.gain_xp(2000)
	_zone.player.pick_up(Item.new(ItemCatalog.by_id("plastron"), [
		StatMod.new("armor", StatMod.Mode.FLAT, 20.0),
	] as Array[StatMod]))
	var niveau: int = _zone.player.level
	assert_gt(niveau, 2, "on a bien progressé")

	_zone.sauvegarder()
	var repris := await _relancer()

	assert_eq(repris.level, niveau, "le niveau est là")
	assert_eq(repris.unspent_points, _zone.player.unspent_points, "et les points à placer")
	assert_eq(repris.inventory.placed.size(), 1, "le plastron est dans le sac")
	assert_eq(repris.inventory.placed[0].data.base.id, "plastron")
	assert_almost_eq(
		repris.inventory.placed[0].data.explicits[0].mod.value, 20.0, 0.0001, "avec son affixe"
	)


## Monter de niveau écrit tout seul : c'est le progrès qu'on serait le plus
## fâché de perdre. En différé, parce que la montée vient d'un rappel de
## physique — d'où l'attente d'une image avant de relire le fichier.
func test_monter_de_niveau_sauvegarde_tout_seul() -> void:
	assert_eq(Sauvegarde.lire(_id).niveau, 1, "au départ, le fichier dit niveau 1")
	_zone.player.gain_xp(2000)
	await wait_physics_frames(2)
	assert_eq(Sauvegarde.lire(_id).niveau, _zone.player.level, "le disque a suivi")


## La règle du jalon : mourir coûte la zone en cours, jamais le personnage.
func test_mourir_ne_coute_pas_le_personnage() -> void:
	_zone.player.gain_xp(2000)
	await wait_physics_frames(2)
	var niveau: int = _zone.player.level

	_zone.player._die()
	await wait_physics_frames(3)

	assert_eq(_zone.player.level, niveau, "le joueur revient avec son niveau")
	assert_false(_zone.player.is_dead, "et il est de nouveau jouable")
	assert_eq(Sauvegarde.lire(_id).niveau, niveau, "le fichier n'a rien perdu")


## Ce que le personnage ramasse **avant** la sauvegarde suivante n'est pas
## garanti, mais ce qui a été écrit ne doit jamais reculer : une sauvegarde qui
## repartirait des valeurs du chargement effacerait la session.
func test_la_sauvegarde_ecrit_l_etat_courant_et_non_celui_du_chargement() -> void:
	_zone.player.gain_xp(2000)
	await wait_physics_frames(2)
	_zone.player.pick_up(Item.new(ItemCatalog.by_id("epee")))
	_zone.player.pick_up(Item.new(ItemCatalog.by_id("baguette")))
	_zone.sauvegarder()

	var relu := Sauvegarde.lire(_id)
	assert_eq(relu.sac.placed.size(), 2, "les deux objets ramassés après la montée")


## Le signal de départ est le seul canal : fermeture de la fenêtre, retour au
## menu et sortie du jeu passent tous par lui.
func test_le_signal_de_depart_declenche_l_ecriture() -> void:
	_zone.player.pick_up(Item.new(ItemCatalog.by_id("epee")))
	assert_eq(Sauvegarde.lire(_id).sac.placed.size(), 0, "rien d'écrit pour l'instant")

	Game.sauvegarde_demandee.emit()
	assert_eq(Sauvegarde.lire(_id).sac.placed.size(), 1, "l'épée est sur le disque")


## Une zone lancée sans personnage — les scènes de réglage, l'éditeur — ne doit
## toucher à aucune sauvegarde. Sans ce garde-fou, ouvrir l'arène de test
## écraserait le dernier personnage joué.
func test_une_zone_sans_personnage_n_ecrit_rien() -> void:
	var avant := Sauvegarde.lire(_id).vers_dict()
	Game.personnage = null

	var libre: Node2D = load("res://world/zone.tscn").instantiate()
	add_child_autofree(libre)
	await wait_physics_frames(1)
	libre.player.gain_xp(5000)
	libre.sauvegarder()
	Game.sauvegarde_demandee.emit()
	await wait_physics_frames(2)

	# joue_le mis à part : il ne bouge qu'à l'écriture, justement.
	assert_eq(Sauvegarde.lire(_id).vers_dict(), avant, "le fichier est intact")


## Le manuel à l'étude traverse une vraie fermeture : joueur, personnage, JSON,
## disque, et retour dans un corps neuf. C'est la chaîne entière du jalon 6, et
## elle est debout avant qu'un seul panneau n'existe.
func test_un_manuel_a_l_etude_survit_a_la_fermeture() -> void:
	var livre := Item.new(ItemCatalog.by_id("manuel_foudre"), [], 30)
	livre.manuel.experience = 340
	livre.manuel.points["eclair_vif"] = 2
	assert_null(_zone.player.ratelier.poser(0, livre), "le râtelier était vide")
	_zone.player.barre.poser(2, "eclair_vif")
	_zone.player.manuel_offert = true

	_zone.sauvegarder()
	var repris := await _relancer()

	var etudie := repris.ratelier.a(0)
	assert_not_null(etudie, "le manuel est revenu au râtelier")
	if etudie == null:
		return
	assert_eq(etudie.manuel.points_de("eclair_vif"), 2, "avec ses points")
	assert_eq(etudie.manuel.experience, 340, "et son expérience")
	assert_eq(etudie.item_level, 30, "et son niveau d'objet")
	assert_eq(repris.barre.id_de(2), "eclair_vif", "la barre aussi")
	assert_true(repris.manuel_offert, "et le manuel de départ reste donné")
