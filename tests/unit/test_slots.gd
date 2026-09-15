extends GutTest

## Les emplacements d'équipement et les familles d'objets. Du calcul pur : la
## table, ses règles, et rien d'autre.
##
## Ce que ces tests protègent est la confusion que le jalon 4 vient défaire — un
## emplacement n'est pas une famille. Son symptôme est silencieux : le second
## anneau équipé fait disparaître le premier, et rien ne le dit.


func _ring() -> Item:
	return Item.new(_base_of_family("ring"))


## Une base fabriquée sur mesure, sans passer par le disque : les bases des dix
## familles n'existent pas encore (c'est l'étape 2 du jalon), et ces règles-ci
## doivent tenir avant elles.
func _base_of_family(family: String) -> ItemBase:
	var base := ItemBase.new()
	base.id = "test_" + family
	base.family = family
	base.display_name = family
	return base


func test_the_table_is_complete() -> void:
	assert_eq(EquipmentSlots.count(), 10, "les dix emplacements du jalon 4")
	assert_eq(EquipmentSlots.ids().size(), EquipmentSlots.count())
	for id in EquipmentSlots.ids():
		assert_false(EquipmentSlots.family_of(id).is_empty(), "%s a une famille" % id)
		assert_false(EquipmentSlots.label(id).is_empty(), "%s a un nom lisible" % id)


## Ils sont écrits dans les sauvegardes des personnages déjà créés. Les renommer
## ferait disparaître leur plastron, au prochain chargement seulement.
func test_former_slots_keep_their_name() -> void:
	assert_true(EquipmentSlots.exists("weapon"))
	assert_true(EquipmentSlots.exists("chest"))


func test_two_slots_share_the_ring_family() -> void:
	var fingers := []
	for id in EquipmentSlots.ids():
		if EquipmentSlots.family_of(id) == "ring":
			fingers.append(id)
	assert_eq(fingers.size(), 2, "deux doigts, une seule famille")


func test_a_slot_only_accepts_its_family() -> void:
	assert_true(EquipmentSlots.accepts("ring_left", _ring()))
	assert_true(EquipmentSlots.accepts("ring_right", _ring()))
	assert_false(EquipmentSlots.accepts("amulet", _ring()), "un anneau n'est pas un pendentif")
	assert_false(EquipmentSlots.accepts("weapon", _ring()))


func test_an_unknown_slot_accepts_nothing() -> void:
	assert_false(EquipmentSlots.accepts("cape", _ring()))
	assert_eq(EquipmentSlots.family_of("cape"), "")
	assert_false(EquipmentSlots.exists("cape"))


func test_an_item_without_base_has_no_family() -> void:
	assert_eq(EquipmentSlots.family_of_item(null), "")
	assert_eq(EquipmentSlots.family_of_item(Item.new(null)), "")
	assert_false(EquipmentSlots.accepts("ring_left", Item.new(null)))


## La règle des anneaux, en une assertion : le second va au doigt libre.
func test_the_second_ring_goes_to_the_free_finger() -> void:
	var worn := {}
	var first := EquipmentSlots.free_for(_ring(), worn)
	assert_eq(first, "ring_left", "le premier libre dans l'ordre du panneau")

	worn[first] = _ring()
	var second := EquipmentSlots.free_for(_ring(), worn)
	assert_eq(second, "ring_right", "le second ne remplace pas le premier")
	assert_ne(second, first)


## Les deux doigts pris, il faut bien en désigner un : on remplace le premier de
## la famille plutôt que de refuser. L'interface, elle, peut viser l'autre.
func test_with_both_fingers_taken_the_first_is_replaced() -> void:
	var worn := {"ring_left": _ring(), "ring_right": _ring()}
	assert_eq(EquipmentSlots.free_for(_ring(), worn), "ring_left")


func test_an_item_without_family_goes_nowhere() -> void:
	assert_eq(EquipmentSlots.free_for(Item.new(_base_of_family("")), {}), "")
	assert_eq(EquipmentSlots.free_for(null, {}), "")


func test_each_family_has_at_least_one_slot() -> void:
	for id in EquipmentSlots.ids():
		var family := EquipmentSlots.family_of(id)
		assert_eq(
			EquipmentSlots.free_for(Item.new(_base_of_family(family)), {}) != "", true,
			"la famille « %s » trouve où se poser" % family
		)


## Les bases du catalogue visent des familles qui existent : une faute de frappe
## dans un `.tres` donnerait un objet qui tombe et ne s'équipe nulle part.
func test_catalog_bases_target_known_families() -> void:
	var families := {}
	for id in EquipmentSlots.ids():
		families[EquipmentSlots.family_of(id)] = true
	for base in ItemCatalog.ALL:
		if base.family.is_empty():
			continue
		# La famille des manuels est la seule qui n'a pas d'emplacement, et ce
		# n'est pas une porte ouverte aux fautes de frappe : c'est
		# `test_an_archetype_goes_with_the_manual_family` qui interdit une base
		# non équipable qui ne serait pas un manuel.
		if base.family == ItemBase.MANUAL_FAMILY:
			continue
		assert_true(
			families.has(base.family),
			"« %s » vise la famille « %s », qui n'a aucun emplacement"
				% [base.display_name, base.family]
		)


# --------------------------------------------------------------------------
# La disposition de la fenêtre de personnage
# --------------------------------------------------------------------------

## Un emplacement sans position ne se dessine nulle part et ne se clique pas :
## il existerait dans le modèle et pas à l'écran.
func test_each_slot_has_its_place_in_the_window() -> void:
	for id in EquipmentSlots.ids():
		assert_true(
			InventoryPanel.DOLL.has(id),
			"« %s » n'a pas de case dans la fenêtre de personnage" % id
		)
	assert_eq(InventoryPanel.DOLL.size(), EquipmentSlots.count(), "et pas de case en trop")


## Deux emplacements qui se recouvrent, c'est l'un des deux qu'on ne peut plus
## ni voir ni viser — et rien ne le dirait. Des rectangles de tailles
## différentes rendent le cas bien plus facile à créer qu'avec des cases égales.
func test_two_slots_do_not_overlap() -> void:
	var ids := InventoryPanel.DOLL.keys()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var a: Rect2i = InventoryPanel.DOLL[ids[i]]
			var b: Rect2i = InventoryPanel.DOLL[ids[j]]
			assert_false(
				a.intersects(b), "« %s » et « %s » se recouvrent" % [ids[i], ids[j]]
			)


## Le portrait occupe un coin. Un emplacement posé dessus serait recouvert.
func test_no_slot_lands_on_the_portrait() -> void:
	for id in InventoryPanel.DOLL:
		assert_false(
			(InventoryPanel.DOLL[id] as Rect2i).intersects(InventoryPanel.DOLL_AREA),
			"« %s » est posé sur le portrait" % id
		)


func test_the_grid_does_not_overflow_its_columns() -> void:
	var frame := Rect2i(0, 0, InventoryPanel.DOLL_COLS, InventoryPanel.DOLL_ROWS)
	for id in InventoryPanel.DOLL:
		assert_true(
			frame.encloses(InventoryPanel.DOLL[id]),
			"« %s » sort de la grille" % id
		)


## Un emplacement vide montre l'objet qu'il attend : sans base dans sa famille,
## il resterait un rectangle nu que rien n'explique.
func test_each_slot_has_a_ghost_silhouette() -> void:
	for id in EquipmentSlots.ids():
		assert_false(
			InventoryPanel._ghost_kind(id).is_empty(),
			"« %s » n'a aucune base à montrer quand il est vide" % id
		)
