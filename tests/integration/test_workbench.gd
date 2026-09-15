extends GutTest

## L'établi ne fabrique que des objets que le jeu pourrait produire. C'est toute
## sa valeur : un outil qui fabriquerait l'impossible ferait chasser des bugs qui
## n'existent pas.

var _workbench: WorkbenchPanel


func before_each() -> void:
	_workbench = WorkbenchPanel.new()
	_workbench.size = Vector2(384.0, 318.0)
	add_child_autofree(_workbench)
	await wait_process_frames(1)


## L'indice d'une base par son identifiant, pour que les tests nomment ce qu'ils
## choisissent au lieu de compter des lignes dans le catalogue.
func _index_of(id: String) -> int:
	var all_of := _workbench.bases()
	for i in all_of.size():
		if all_of[i].id == id:
			return i
	return -1


func test_every_game_base_is_offered() -> void:
	assert_eq(_workbench.bases().size(), ItemCatalog.ALL.size())
	assert_not_null(_workbench.current_base(), "et il y en a une de choisie d'emblée")


## Les affixes proposés sont ceux que la base accepte, et personne d'autre. Un
## manuel ne s'équipe nulle part, donc il ne reçoit rien.
func test_the_offered_affixes_are_those_of_the_base() -> void:
	_workbench.choose_base(_index_of("sword"))
	var offered := _workbench.compatibles()
	assert_gt(offered.size(), 0, "une épée accepte quelque chose")
	for affix: ItemAffix in offered:
		assert_true(
			affix.fits(_workbench.current_base()),
			"« %s » ne va pas sur une épée" % affix.id
		)

	_workbench.choose_base(_index_of("manual_lightning"))
	assert_eq(_workbench.compatibles().size(), 0, "un manuel ne reçoit aucun affixe")


## Le clic fait tourner l'affixe : absent, ses paliers du meilleur au pire, puis
## absent de nouveau. Un seul geste pour les trois questions.
func test_the_click_cycles_the_tiers() -> void:
	_workbench.choose_base(_index_of("sword"))
	_workbench.change_level(99)
	var affix: ItemAffix = _workbench.compatibles()[0]
	var unlocked_tiers := affix.unlocked_tiers(_workbench._level)
	assert_gt(unlocked_tiers.size(), 1, "plusieurs paliers ouverts à haut niveau")

	for expected in unlocked_tiers:
		_workbench.toggle_affix(affix.id)
		assert_eq(_workbench._selected_ones.get(affix.id), expected, "palier %d" % expected)
	_workbench.toggle_affix(affix.id)
	assert_false(_workbench._selected_ones.has(affix.id), "un tour complet le retire")


## Le compte est borné par la table des poids, pas par un nombre écrit dans le
## panneau : un objet à sept affixes n'existe pas dans le jeu.
func test_the_affix_count_is_bounded() -> void:
	_workbench.choose_base(_index_of("sword"))
	_workbench.change_level(99)
	for affix: ItemAffix in _workbench.compatibles():
		if not _workbench._selected_ones.has(affix.id):
			_workbench.toggle_affix(affix.id)
	assert_eq(
		_workbench._selected_ones.size(), WorkbenchPanel.max_affixes(),
		"on ne dépasse pas le maximum du tirage"
	)


## Descendre le niveau d'objet doit **retirer** les paliers devenus
## inatteignables. Sans cet élagage, l'établi sortirait un objet de niveau 1
## portant un palier réservé au niveau 60.
func test_lowering_the_level_prunes_tiers_too_high() -> void:
	_workbench.choose_base(_index_of("sword"))
	_workbench.change_level(99)
	for affix: ItemAffix in _workbench.compatibles():
		_workbench.toggle_affix(affix.id)
		break
	assert_eq(_workbench._selected_ones.size(), 1, "un affixe posé à haut niveau")

	_workbench.change_level(-98)
	for id in _workbench._selected_ones:
		var affix := ItemAffixPool.by_id(id)
		assert_true(
			affix.unlocked_tiers(_workbench._level).has(_workbench._selected_ones[id]),
			"« %s » garde un palier que le niveau 1 n'ouvre pas" % id
		)


## L'objet fabriqué porte exactement ce qui est réglé, provenance comprise.
func test_the_crafted_item_carries_what_was_set() -> void:
	_workbench.choose_base(_index_of("sword"))
	_workbench.change_level(39)
	var affix: ItemAffix = _workbench.compatibles()[0]
	_workbench.toggle_affix(affix.id)

	var item_data := _workbench.craft()
	assert_eq(item_data.base.id, "sword")
	assert_eq(item_data.item_level, 40, "le niveau réglé")
	assert_eq(item_data.explicits.size(), 1)
	var placed: RolledAffix = item_data.explicits[0]
	assert_eq(placed.affix_id, affix.id)
	assert_true(placed.known(), "avec sa provenance, comme un objet tombé")
	assert_eq(placed.mod.stat, affix.stat)


## Un affixe porté sort de l'établi avec sa portée, comme il sortirait du tirage :
## sans elle, le « +1 projectile » qu'on vient de poser deviendrait une ligne de
## fiche, et l'essai porterait sur un objet que le jeu ne produit pas.
func test_a_scoped_affix_rolls_with_its_scope() -> void:
	_workbench.choose_base(_index_of("wand"))
	_workbench.toggle_affix("forked")
	var placed: RolledAffix = _workbench.craft().explicits[0]
	assert_eq(placed.mod.scope, Keywords.PROJECTILE)


## La taille que la zone donne à l'établi, lue dans sa scène et non recopiée : une
## taille écrite ici validerait un panneau qui n'est pas celui du jeu.
func _size_in_zone() -> Vector2:
	var state := (load("res://world/zone.tscn") as PackedScene).get_state()
	for i in state.get_node_count():
		if state.get_node_name(i) != "Workbench":
			continue
		var edges := {}
		for j in state.get_node_property_count(i):
			edges[state.get_node_property_name(i, j)] = state.get_node_property_value(i, j)
		return Vector2(
			edges["offset_right"] - edges["offset_left"],
			edges["offset_bottom"] - edges["offset_top"]
		)
	return Vector2.ZERO


## Chaque affixe qu'une base accepte a sa ligne, sur l'une des pages, et aucune
## ligne ne passe sous les boutons du bas. Un affixe qu'on ne peut pas voir ne
## peut jamais être posé, et on le croirait absent de la réserve.
func test_each_accepted_affix_has_its_line() -> void:
	_workbench.size = _size_in_zone()
	assert_gt(_workbench.size.y, 0.0, "la zone donne une taille à l'établi")
	for i in _workbench.bases().size():
		_workbench.choose_base(i)
		var name := _workbench.current_base().display_name
		var lines := 0
		for page in _workbench.affix_pages():
			_workbench._apply("affixes:1" if page > 0 else "")
			_workbench._arrange()
			for line in _workbench._lines:
				if not String(line["action"]).begins_with("affixe:"):
					continue
				lines += 1
				assert_lte(
					(line["rect"] as Rect2).end.y, _workbench.size.y - WorkbenchPanel.LINE - WorkbenchPanel.PAD,
					"« %s » : une ligne passe sous les boutons" % name
				)
		assert_eq(lines, _workbench.compatibles().size(), "« %s » : des affixes introuvables" % name)


## Changer de base ramène à la première page : la seconde page d'un anneau n'a
## rien à voir avec celle d'une épée.
func test_changing_base_returns_to_the_first_affix_page() -> void:
	_workbench.size = _size_in_zone()
	_workbench.choose_base(_index_of("ring"))
	assert_gt(_workbench.affix_pages(), 1, "un anneau accepte plus d'une page d'affixes")
	_workbench._apply("affixes:1")
	assert_eq(_workbench._page_affixes, 1)
	_workbench.choose_base(_index_of("sword"))
	assert_eq(_workbench._page_affixes, 0)


## Aucun tirage : deux fabrications du même réglage donnent la même valeur, et
## surtout `Game.rng` n'avance pas — il est le fil des graines de zone.
func test_the_workbench_rolls_nothing_at_random() -> void:
	_workbench.choose_base(_index_of("sword"))
	_workbench.change_level(39)
	_workbench.toggle_affix((_workbench.compatibles()[0] as ItemAffix).id)

	var before := Game.rng.state
	var a := _workbench.craft()
	var b := _workbench.craft()
	assert_eq(Game.rng.state, before, "l'établi n'a pas consommé de tirage")
	assert_eq(a.explicits[0].mod.value, b.explicits[0].mod.value, "et il est reproductible")


## Changer de base jette les affixes de l'ancienne : « allonge » n'a rien à faire
## sur une paire de bottes, et c'est exactement ce que l'établi refuse.
func test_changing_base_clears_the_affixes() -> void:
	_workbench.choose_base(_index_of("sword"))
	_workbench.change_level(99)
	_workbench.toggle_affix((_workbench.compatibles()[0] as ItemAffix).id)
	assert_gt(_workbench._selected_ones.size(), 0)

	_workbench.choose_base(_index_of("boots"))
	assert_eq(_workbench._selected_ones.size(), 0)


func test_reset_puts_everything_back_to_zero() -> void:
	_workbench.choose_base(_index_of("boots"))
	_workbench.change_level(50)
	_workbench.toggle_affix((_workbench.compatibles()[0] as ItemAffix).id)

	_workbench.reset_all()
	assert_eq(_workbench._level, 1)
	assert_eq(_workbench._selected_ones.size(), 0)
	assert_eq(_workbench.current_base(), ItemCatalog.ALL[0])


## Le bouton pose l'objet par le signal, jamais lui-même : c'est la zone qui sait
## faire tomber quelque chose, et il n'y a qu'un chemin pour ça.
func test_the_button_requests_the_drop() -> void:
	_workbench.choose_base(_index_of("sword"))
	watch_signals(_workbench)
	_workbench._apply("drop")
	assert_signal_emitted(_workbench, "drop_requested")
	var received: Item = get_signal_parameters(_workbench, "drop_requested", 0)[0]
	assert_eq(received.base.id, "sword")


## Le dessin traverse ses états sans se plaindre : une base sans affixe, une base
## chargée, et un manuel qui n'en accepte aucun.
func test_drawing_does_not_crash() -> void:
	for id in ["sword", "manual_lightning", "boots"]:
		_workbench.choose_base(_index_of(id))
		_workbench.change_level(40)
		for affix: ItemAffix in _workbench.compatibles():
			_workbench.toggle_affix(affix.id)
		_workbench.visible = true
		_workbench.queue_redraw()
		await wait_process_frames(2)
	assert_true(true, "aucun plantage au dessin")


## Le bouton ne pose rien lui-même : la zone seule connaît le niveau qui fait la
## valeur d'une boule.
func test_the_button_requests_experience_orbs() -> void:
	watch_signals(_workbench)
	_workbench._apply("orbs:10")
	assert_signal_emitted_with_parameters(_workbench, "requested_orbs", [10])
