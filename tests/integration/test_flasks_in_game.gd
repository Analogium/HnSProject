extends GutTest

## Les flacons bus par un vrai joueur (jalon 32) : la gorgée, les charges, la fiche
## pendant l'effet.

var _p: Player


func before_each() -> void:
	_p = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_p)
	await wait_physics_frames(1)


func _wear(id: String, index := 0) -> Item:
	var flask := Item.new(ItemCatalog.by_id(id))
	_p.equip(flask, EquipmentSlots.flasks()[index])
	return flask


## Hors du temps du moteur : `_drink` avance d'un pas qu'on choisit.
func _flow(seconds: float) -> void:
	var step := 0.05
	var elapsed := 0.0
	while elapsed < seconds - 0.0001:
		_p._drink(step)
		elapsed += step


func test_a_life_flask_heals_over_its_duration() -> void:
	var flask := _wear("small_life_flask")
	_p._set_health(10.0)
	assert_true(_p.use_flask(0))
	assert_eq(flask.charges, float(flask.charges_max() - flask.charges_per_use()))
	_flow(flask.flask_duration() * 0.5)
	assert_almost_eq(_p.health, 10.0 + flask.flask_life() * 0.5, 0.5, "la moitié à mi-chemin")
	_flow(flask.flask_duration())
	assert_almost_eq(_p.health, 10.0 + flask.flask_life(), 0.5, "et pas plus")
	assert_false(_p.drinking(flask))


## Deux gorgées de vie se cumulent, comme dans PoE 1 ; un utilitaire ne se reboit pas.
func test_life_stacks_and_utility_waits() -> void:
	var life := _wear("small_life_flask", 0)
	var quick := _wear("quicksilver_flask", 1)
	assert_true(_p.use_flask(0))
	assert_true(_p.use_flask(0), "une seconde gorgée de vie")
	assert_true(_p.use_flask(1))
	assert_false(_p.use_flask(1), "le vif-argent coule encore")
	assert_true(_p.drinking(life))
	assert_true(_p.drinking(quick))


func test_no_charges_no_sip() -> void:
	var flask := _wear("small_life_flask")
	flask.charges = flask.charges_per_use() - 0.5
	assert_false(_p.use_flask(0))
	assert_false(_p.use_flask(4), "un emplacement vide")


## Porté, un flacon ne change rien : la fiche le reçoit bu, et le rend à la fin.
func test_a_utility_flask_counts_only_while_drunk() -> void:
	var before := _p.stats.move_speed
	var flask := _wear("quicksilver_flask")
	assert_eq(_p.stats.move_speed, before, "porté, il ne donne rien")
	_p.use_flask(0)
	assert_almost_eq(_p.stats.move_speed, before * 1.4, 0.01, "+40 % bu")
	_flow(flask.flask_duration() + 0.1)
	assert_eq(_p.stats.move_speed, before, "et rendu à la fin")


func test_kills_fill_and_town_refills() -> void:
	var flask := _wear("small_life_flask")
	flask.charges = 0.0
	_p.gain_flask_charges(2)
	assert_eq(flask.charges, Player.CHARGES_PER_KILL + 2.0 * Player.CHARGES_PER_AFFIX)
	for i in 100:
		_p.gain_flask_charges(0)
	assert_eq(flask.charges, float(flask.charges_max()), "jamais au-delà du plein")
	flask.charges = 0.0
	_p.refill_flasks()
	assert_eq(flask.charges, float(flask.charges_max()))


func test_the_key_drinks() -> void:
	var flask := _wear("small_life_flask", 2)
	var press := InputEventAction.new()
	press.action = "flask_3"
	press.pressed = true
	_p._unhandled_input(press)
	assert_true(_p.drinking(flask))


func test_death_ends_every_sip() -> void:
	_wear("quicksilver_flask")
	var before := _p.base_stats.move_speed
	_p.use_flask(0)
	_p._die()
	assert_false(_p.drinking(_p.flask_in(0)))
	assert_eq(_p.stats.move_speed, before)
