extends GutTest

## La touche d'une compétence, tenue : elle relance dès que la recharge est
## passée, et pas avant.
##
## Le sondage de `Player._physics_process` est le seul endroit du jeu qui lit une
## touche de compétence, et aucun autre test ne le traverse — les autres appellent
## `lancer()` directement. Ici l'action est vraiment enfoncée, comme au clavier.

## La case du trait : la seule compétence de départ qui laisse une trace qu'on
## peut compter sans regarder l'écran — un projectile qui naît.
const CASE := 1
const ACTION := "competence_2"

var _p: Player
var _tirs: Node2D
## Le numéro d'image physique de chaque tir parti. Les écarts se lisent dedans,
## ce qui rend la mesure indifférente à l'image où le test a commencé à attendre.
var _images: Array[int] = []


func before_each() -> void:
	_p = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_p)
	_tirs = Node2D.new()
	add_child_autofree(_tirs)
	_p.projectile_parent = _tirs
	_tirs.child_entered_tree.connect(_noter)
	# GUT garde une seule instance du script pour tous ses tests : sans ce
	# vidage, chaque test compterait aussi les tirs du précédent.
	_images.clear()
	await wait_physics_frames(1)


## Une action laissée enfoncée vaut pour tout le reste de la campagne : le
## joueur du fichier suivant tirerait sans que rien ne le lui demande.
func after_each() -> void:
	Input.action_release(ACTION)
	Game.grab_ui_input(self, false)


func _noter(_tir: Node) -> void:
	_images.append(Engine.get_physics_frames())


## L'intervalle du trait, en images physiques. Demandé à la compétence et non
## recopié : un trait ralenti par un affixe reste testé au bon rythme.
func _recharge_en_images() -> int:
	var competence := _p.barre.competence_de(CASE)
	return int(round(competence.intervalle(_p.stats) * Engine.physics_ticks_per_second))


func test_la_touche_tenue_relance_au_rythme_de_la_recharge() -> void:
	var recharge := _recharge_en_images()
	Input.action_press(ACTION)
	await wait_physics_frames(recharge * 3 + 2)

	assert_gt(_images.size(), 2, "la touche tenue relance sans qu'on la relâche")
	for i in range(1, _images.size()):
		# Une image de battement : la recharge descend par pas de delta et la
		# dernière soustraction laisse un reste flottant, qui coûte un tour de
		# plus. Ce qui est vérifié est le rythme, pas l'arrondi.
		assert_between(
			_images[i] - _images[i - 1], recharge, recharge + 1,
			"le tir %d part une recharge après le précédent" % (i + 1)
		)


func test_la_touche_relachee_ne_relance_plus() -> void:
	Input.action_press(ACTION)
	await wait_physics_frames(2)
	Input.action_release(ACTION)
	await wait_physics_frames(_recharge_en_images() * 2 + 2)

	assert_eq(_images.size(), 1, "le seul tir de l'appui")


## Le menu de la barre se ferme sur l'appui, et le bouton reste baissé un dixième
## de seconde après : sans armement, la compétence qu'on vient de poser partirait
## toute seule dès que le panneau rend la souris.
func test_un_bouton_deja_baisse_quand_l_interface_rend_la_main_ne_lance_rien() -> void:
	Game.grab_ui_input(self, true)
	Input.action_press(ACTION)
	await wait_physics_frames(2)
	assert_eq(_images.size(), 0, "panneau ouvert, rien ne part")

	Game.grab_ui_input(self, false)
	await wait_physics_frames(_recharge_en_images() + 2)
	assert_eq(_images.size(), 0, "et le bouton encore baissé n'arme rien")

	Input.action_release(ACTION)
	await wait_physics_frames(1)
	Input.action_press(ACTION)
	await wait_physics_frames(1)
	assert_eq(_images.size(), 1, "il faut un nouvel appui, et celui-là part")
