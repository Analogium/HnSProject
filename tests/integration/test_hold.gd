extends GutTest

## La touche d'une compétence, tenue : elle relance dès que la recharge est
## passée, et pas avant.
##
## Le sondage de `Player._physics_process` est le seul endroit du jeu qui lit une
## touche de compétence, et aucun autre test ne le traverse — les autres appellent
## `cast_slot()` directement. Ici l'action est vraiment enfoncée, comme au clavier.

## La case du trait : la seule compétence de départ qui laisse une trace qu'on
## peut compter sans regarder l'écran — un projectile qui naît.
const CELL := 1
const ACTION := "skill_2"

var _p: Player
var _bolts_fired: Node2D
## Le numéro d'image physique de chaque tir parti. Les écarts se lisent dedans,
## ce qui rend la mesure indifférente à l'image où le test a commencé à attendre.
var _frames: Array[int] = []


func before_each() -> void:
	_p = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_p)
	_bolts_fired = Node2D.new()
	add_child_autofree(_bolts_fired)
	_p.projectile_parent = _bolts_fired
	_bolts_fired.child_entered_tree.connect(_record)
	# GUT garde une seule instance du script pour tous ses tests : sans ce
	# vidage, chaque test compterait aussi les tirs du précédent.
	_frames.clear()
	await wait_physics_frames(1)


## Une action laissée enfoncée vaut pour tout le reste de la campagne : le
## joueur du fichier suivant tirerait sans que rien ne le lui demande.
func after_each() -> void:
	Input.action_release(ACTION)
	Game.grab_ui_input(self, false)


func _record(_bolt: Node) -> void:
	_frames.append(Engine.get_physics_frames())


## L'intervalle du trait, en images physiques. Demandé à la compétence et non
## recopié : un trait ralenti par un affixe reste testé au bon rythme.
func _cooldown_in_frames() -> int:
	var skill := _p.bar.skill_of(CELL)
	return int(round(skill.interval(_p.stats) * Engine.physics_ticks_per_second))


func test_the_held_key_recasts_at_cooldown_pace() -> void:
	var cooldown := _cooldown_in_frames()
	Input.action_press(ACTION)
	await wait_physics_frames(cooldown * 3 + 2)

	assert_gt(_frames.size(), 2, "la touche tenue relance sans qu'on la relâche")
	for i in range(1, _frames.size()):
		# Une image de battement : la recharge descend par pas de delta et la
		# dernière soustraction laisse un reste flottant, qui coûte un tour de
		# plus. Ce qui est vérifié est le rythme, pas l'arrondi.
		assert_between(
			_frames[i] - _frames[i - 1], cooldown, cooldown + 1,
			"le tir %d part une recharge après le précédent" % (i + 1)
		)


func test_the_released_key_no_longer_recasts() -> void:
	Input.action_press(ACTION)
	await wait_physics_frames(2)
	Input.action_release(ACTION)
	await wait_physics_frames(_cooldown_in_frames() * 2 + 2)

	assert_eq(_frames.size(), 1, "le seul tir de l'appui")


## Le menu de la barre se ferme sur l'appui, et le bouton reste baissé un dixième
## de seconde après : sans armement, la compétence qu'on vient de poser partirait
## toute seule dès que le panneau rend la souris.
func test_a_button_already_down_when_the_ui_releases_casts_nothing() -> void:
	Game.grab_ui_input(self, true)
	Input.action_press(ACTION)
	await wait_physics_frames(2)
	assert_eq(_frames.size(), 0, "panneau ouvert, rien ne part")

	Game.grab_ui_input(self, false)
	await wait_physics_frames(_cooldown_in_frames() + 2)
	assert_eq(_frames.size(), 0, "et le bouton encore baissé n'arme rien")

	Input.action_release(ACTION)
	await wait_physics_frames(1)
	Input.action_press(ACTION)
	await wait_physics_frames(1)
	assert_eq(_frames.size(), 1, "il faut un nouvel appui, et celui-là part")
