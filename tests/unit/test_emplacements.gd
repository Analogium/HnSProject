extends GutTest

## Les emplacements d'équipement et les familles d'objets. Du calcul pur : la
## table, ses règles, et rien d'autre.
##
## Ce que ces tests protègent est la confusion que le jalon 4 vient défaire — un
## emplacement n'est pas une famille. Son symptôme est silencieux : le second
## anneau équipé fait disparaître le premier, et rien ne le dit.


func _anneau() -> Item:
	return Item.new(_base_de_famille("ring"))


## Une base fabriquée sur mesure, sans passer par le disque : les bases des dix
## familles n'existent pas encore (c'est l'étape 2 du jalon), et ces règles-ci
## doivent tenir avant elles.
func _base_de_famille(famille: String) -> ItemBase:
	var base := ItemBase.new()
	base.id = "test_" + famille
	base.family = famille
	base.display_name = famille
	return base


func test_la_table_est_complete() -> void:
	assert_eq(EquipmentSlots.count(), 10, "les dix emplacements du jalon 4")
	assert_eq(EquipmentSlots.ids().size(), EquipmentSlots.count())
	for id in EquipmentSlots.ids():
		assert_false(EquipmentSlots.family_of(id).is_empty(), "%s a une famille" % id)
		assert_false(EquipmentSlots.label(id).is_empty(), "%s a un nom lisible" % id)


## Ils sont écrits dans les sauvegardes des personnages déjà créés. Les renommer
## ferait disparaître leur plastron, au prochain chargement seulement.
func test_les_emplacements_d_avant_gardent_leur_nom() -> void:
	assert_true(EquipmentSlots.exists("weapon"))
	assert_true(EquipmentSlots.exists("chest"))


func test_deux_emplacements_partagent_la_famille_anneau() -> void:
	var doigts := []
	for id in EquipmentSlots.ids():
		if EquipmentSlots.family_of(id) == "ring":
			doigts.append(id)
	assert_eq(doigts.size(), 2, "deux doigts, une seule famille")


func test_un_emplacement_n_accepte_que_sa_famille() -> void:
	assert_true(EquipmentSlots.accepts("ring_left", _anneau()))
	assert_true(EquipmentSlots.accepts("ring_right", _anneau()))
	assert_false(EquipmentSlots.accepts("amulet", _anneau()), "un anneau n'est pas un pendentif")
	assert_false(EquipmentSlots.accepts("weapon", _anneau()))


func test_un_emplacement_inconnu_n_accepte_rien() -> void:
	assert_false(EquipmentSlots.accepts("cape", _anneau()))
	assert_eq(EquipmentSlots.family_of("cape"), "")
	assert_false(EquipmentSlots.exists("cape"))


func test_un_objet_sans_base_n_a_pas_de_famille() -> void:
	assert_eq(EquipmentSlots.family_of_item(null), "")
	assert_eq(EquipmentSlots.family_of_item(Item.new(null)), "")
	assert_false(EquipmentSlots.accepts("ring_left", Item.new(null)))


## La règle des anneaux, en une assertion : le second va au doigt libre.
func test_le_second_anneau_va_au_doigt_libre() -> void:
	var porte := {}
	var premier := EquipmentSlots.free_for(_anneau(), porte)
	assert_eq(premier, "ring_left", "le premier libre dans l'ordre du panneau")

	porte[premier] = _anneau()
	var second := EquipmentSlots.free_for(_anneau(), porte)
	assert_eq(second, "ring_right", "le second ne remplace pas le premier")
	assert_ne(second, premier)


## Les deux doigts pris, il faut bien en désigner un : on remplace le premier de
## la famille plutôt que de refuser. L'interface, elle, peut viser l'autre.
func test_les_deux_doigts_pris_on_remplace_le_premier() -> void:
	var porte := {"ring_left": _anneau(), "ring_right": _anneau()}
	assert_eq(EquipmentSlots.free_for(_anneau(), porte), "ring_left")


func test_un_objet_sans_famille_ne_va_nulle_part() -> void:
	assert_eq(EquipmentSlots.free_for(Item.new(_base_de_famille("")), {}), "")
	assert_eq(EquipmentSlots.free_for(null, {}), "")


func test_chaque_famille_a_au_moins_un_emplacement() -> void:
	for id in EquipmentSlots.ids():
		var famille := EquipmentSlots.family_of(id)
		assert_eq(
			EquipmentSlots.free_for(Item.new(_base_de_famille(famille)), {}) != "", true,
			"la famille « %s » trouve où se poser" % famille
		)


## Les bases du catalogue visent des familles qui existent : une faute de frappe
## dans un `.tres` donnerait un objet qui tombe et ne s'équipe nulle part.
func test_les_bases_du_catalogue_visent_des_familles_connues() -> void:
	var familles := {}
	for id in EquipmentSlots.ids():
		familles[EquipmentSlots.family_of(id)] = true
	for base in ItemCatalog.ALL:
		if base.family.is_empty():
			continue
		assert_true(
			familles.has(base.family),
			"« %s » vise la famille « %s », qui n'a aucun emplacement"
				% [base.display_name, base.family]
		)
