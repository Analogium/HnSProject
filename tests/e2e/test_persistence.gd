extends GutTest

## Le critère de réussite du jalon 3, joué en entier : créer un personnage, le
## jouer, gagner des niveaux et un objet, fermer, relancer, tout retrouver.
##
## « Fermer et relancer » se joue ici en libérant la zone et en relisant le
## fichier depuis le disque, puis en le rechargeant dans un corps neuf. C'est ce
## que fait le jeu au démarrage, moins la fenêtre.

const SEED := 4242

var _zone: Node2D
var _id := ""


func before_each() -> void:
	Game.character = SaveStore.create("Persistante", 1)
	_id = Game.character.id
	_zone = load("res://world/zone.tscn").instantiate()
	add_child_autofree(_zone)
	await wait_physics_frames(1)
	_zone.generate_zone(SEED)
	# Le manuel de départ tombe en différé : sans cette image, un test court finit
	# avec lui hors de l'arbre.
	await wait_process_frames(1)


func after_each() -> void:
	SaveStore.delete(_id)
	Game.character = null


## Recharge le personnage depuis le disque dans un corps neuf — l'équivalent
## d'avoir relancé le jeu.
func _recast() -> Player:
	var reread := SaveStore.read(_id)
	assert_not_null(reread, "le fichier se relit")
	var body: Player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(body)
	await wait_physics_frames(1)
	body.load_character(reread)
	return body


func test_a_new_character_arrives_in_the_zone() -> void:
	assert_eq(_zone.player.level, 1)
	assert_eq(_zone.player.sprite.current_variant(), 1, "sa silhouette, pas celle par défaut")
	assert_eq(_zone.player.weapon_kind(), "sword", "l'épée en main, pour l'attaque de départ")
	assert_eq(_zone.player.inventory.placed.size(), 1, "la baguette au sac, pour le tir")
	assert_eq(_zone.player.inventory.placed[0].data.base.id, ItemCatalog.ID_STARTING_WAND)


func test_the_milestone_criterion() -> void:
	# Jouer : deux niveaux et un plastron.
	_zone.player.gain_xp(2000)
	_zone.player.pick_up(Item.new(ItemCatalog.by_id("breastplate"), [
		StatMod.new("armor", StatMod.Mode.FLAT, 20.0),
	] as Array[StatMod]))
	var level: int = _zone.player.level
	assert_gt(level, 2, "on a bien progressé")

	_zone.save()
	var refunded := await _recast()

	assert_eq(refunded.level, level, "le niveau est là")
	assert_eq(refunded.remaining_passive_points(), _zone.player.remaining_passive_points(), "et les points d'arbre")
	assert_eq(refunded.weapon_kind(), "sword", "l'arme de départ en main")
	assert_eq(refunded.inventory.placed.size(), 2, "le plastron est dans le sac, avec la baguette")
	var breastplate: Item = refunded.inventory.placed[1].data
	assert_eq(breastplate.base.id, "breastplate")
	assert_almost_eq(breastplate.explicits[0].mod.value, 20.0, 0.0001, "avec son affixe")


## Monter de niveau écrit tout seul : c'est le progrès qu'on serait le plus
## fâché de perdre. En différé, parce que la montée vient d'un rappel de
## physique — d'où l'attente d'une image avant de relire le fichier.
func test_leveling_up_saves_automatically() -> void:
	assert_eq(SaveStore.read(_id).level, 1, "au départ, le fichier dit niveau 1")
	_zone.player.gain_xp(2000)
	await wait_physics_frames(2)
	assert_eq(SaveStore.read(_id).level, _zone.player.level, "le disque a suivi")


## La règle du jalon : mourir coûte la zone en cours, jamais le personnage.
func test_dying_does_not_cost_the_character() -> void:
	_zone.player.gain_xp(2000)
	await wait_physics_frames(2)
	var level: int = _zone.player.level

	_zone.player._die()
	await wait_physics_frames(3)

	assert_eq(_zone.player.level, level, "le joueur revient avec son niveau")
	assert_false(_zone.player.is_dead, "et il est de nouveau jouable")
	assert_eq(SaveStore.read(_id).level, level, "le fichier n'a rien perdu")


## Ce que le personnage ramasse **avant** la sauvegarde suivante n'est pas
## garanti, mais ce qui a été écrit ne doit jamais reculer : une sauvegarde qui
## repartirait des valeurs du chargement effacerait la session.
func test_saving_writes_the_current_state_not_the_loaded_one() -> void:
	_zone.player.gain_xp(2000)
	await wait_physics_frames(2)
	_zone.player.pick_up(Item.new(ItemCatalog.by_id("sword")))
	_zone.player.pick_up(Item.new(ItemCatalog.by_id("wand")))
	_zone.save()

	var reread := SaveStore.read(_id)
	assert_eq(reread.bag.placed.size(), 3, "la baguette de départ et les deux objets ramassés après la montée")


## Le signal de départ est le seul canal : fermeture de la fenêtre, retour au
## menu et sortie du jeu passent tous par lui.
func test_the_start_signal_triggers_writing() -> void:
	_zone.player.pick_up(Item.new(ItemCatalog.by_id("sword")))
	assert_eq(SaveStore.read(_id).bag.placed.size(), 1, "rien d'écrit pour l'instant que la baguette")

	Game.save_requested.emit()
	assert_eq(SaveStore.read(_id).bag.placed.size(), 2, "l'épée est sur le disque")


## Une zone lancée sans personnage — les scènes de réglage, l'éditeur — ne doit
## toucher à aucune sauvegarde. Sans ce garde-fou, ouvrir l'arène de test
## écraserait le dernier personnage joué.
func test_a_zone_without_character_writes_nothing() -> void:
	var before := SaveStore.read(_id).to_dict()
	Game.character = null

	var free: Node2D = load("res://world/zone.tscn").instantiate()
	add_child_autofree(free)
	await wait_physics_frames(1)
	free.player.gain_xp(5000)
	free.save()
	Game.save_requested.emit()
	await wait_physics_frames(2)

	# joue_le mis à part : il ne bouge qu'à l'écriture, justement.
	assert_eq(SaveStore.read(_id).to_dict(), before, "le fichier est intact")


## Le manuel à l'étude traverse une vraie fermeture : joueur, personnage, JSON,
## disque, et retour dans un corps neuf. C'est la chaîne entière du jalon 6, et
## elle est debout avant qu'un seul panneau n'existe.
func test_a_studied_manual_survives_closing() -> void:
	var book := Item.new(ItemCatalog.by_id("manual_lightning"), [], 30)
	book.manual.experience = 340
	book.manual.points["swift_bolt"] = 2
	assert_null(_zone.player.rack.put(0, book), "le râtelier était vide")
	_zone.player.bar.put(2, "swift_bolt")
	_zone.player.manual_given = true

	_zone.save()
	var refunded := await _recast()

	var studied := refunded.rack.at(0)
	assert_not_null(studied, "le manuel est revenu au râtelier")
	if studied == null:
		return
	assert_eq(studied.manual.points_of("swift_bolt"), 2, "avec ses points")
	assert_eq(studied.manual.experience, 340, "et son expérience")
	assert_eq(studied.item_level, 30, "et son niveau d'objet")
	assert_eq(refunded.bar.id_of(2), "swift_bolt", "la barre aussi")
	assert_true(refunded.manual_given, "et le manuel de départ reste donné")
