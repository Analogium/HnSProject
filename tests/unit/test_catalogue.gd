extends GutTest

## Le catalogue des bases d'objets. Ce qu'on vérifie ici n'a l'air de rien —
## des identifiants présents et distincts — mais c'est la condition pour qu'un
## objet sauvegardé se recharge. Un doublon ferait charger silencieusement la
## mauvaise base : on rangerait une épée, on reprendrait une baguette.


func test_chaque_base_a_un_identifiant() -> void:
	for base in ItemCatalog.ALL:
		assert_false(
			base.id.strip_edges().is_empty(),
			"« %s » n'a pas d'identifiant : ses exemplaires seraient perdus au chargement"
				% base.display_name
		)


func test_les_identifiants_sont_uniques() -> void:
	var vus := {}
	for base in ItemCatalog.ALL:
		assert_false(vus.has(base.id), "identifiant « %s » en double" % base.id)
		vus[base.id] = true
	assert_eq(vus.size(), ItemCatalog.ALL.size())


func test_on_retrouve_une_base_par_son_identifiant() -> void:
	for base in ItemCatalog.ALL:
		assert_eq(ItemCatalog.by_id(base.id), base, "aller-retour sur « %s »" % base.id)


## Le cas que la sauvegarde rencontrera pour de vrai : une base retirée du
## projet depuis. Un null, pas une erreur — c'est à l'appelant d'ignorer l'objet.
func test_une_base_disparue_rend_null() -> void:
	assert_null(ItemCatalog.by_id("hallebarde_de_2027"))
	assert_null(ItemCatalog.by_id(""))


## Deux listes de bases auraient fini par diverger, et un objet qui tombe sans
## pouvoir être rechargé est pire qu'un objet qui ne tombe pas.
func test_le_butin_tire_dans_le_catalogue() -> void:
	Game.rng.seed = 31337
	var bases_vues := {}
	for i in 400:
		var item := LootTable.roll(0)
		if item != null:
			bases_vues[item.base.id] = true
			assert_not_null(
				ItemCatalog.by_id(item.base.id), "une chute doit être rechargeable"
			)
	assert_gt(bases_vues.size(), 1, "plusieurs bases tirées, pas toujours la même")


# --------------------------------------------------------------------------
# Les dix familles (jalon 4)
# --------------------------------------------------------------------------

## Un emplacement sans base est un emplacement qui restera vide toute la partie,
## sans que rien ne le signale.
func test_chaque_emplacement_a_au_moins_une_base() -> void:
	var familles := {}
	for base in ItemCatalog.ALL:
		familles[base.family] = true
	for id in EquipmentSlots.ids():
		assert_true(
			familles.has(EquipmentSlots.family_of(id)),
			"aucune base ne va dans « %s »" % EquipmentSlots.label(id)
		)


## Une icône vide ne se découvre qu'en ramassant l'objet. La forge dessine soit
## une pièce d'équipement, soit une arme : un `kind` qui n'est ni l'un ni l'autre
## produit un dessin sans un seul pixel peint.
func test_chaque_base_a_une_icone_non_vide() -> void:
	for base in ItemCatalog.ALL:
		var tex := SpriteForge.inventory_icon(base.kind, Vector2i.ZERO)
		assert_not_null(tex, "« %s » n'a pas d'icône" % base.display_name)
		assert_gt(
			tex.get_size().x * tex.get_size().y, 0.0,
			"l'icône de « %s » (kind « %s ») ne peint rien" % [base.display_name, base.kind]
		)


## L'implicite d'une base vise un champ de la fiche. Une faute de frappe
## modifierait silencieusement une statistique qui n'existe pas.
func test_les_implicites_visent_des_statistiques_reelles() -> void:
	var fiche := CharacterStats.new()
	for base in ItemCatalog.ALL:
		if base.implicit_stat.is_empty():
			continue
		assert_true(
			fiche.get(base.implicit_stat) != null,
			"« %s » vise « %s », qui n'est pas dans la fiche"
				% [base.display_name, base.implicit_stat]
		)
		assert_true(
			StatMod.LABELS.has(base.implicit_stat),
			"« %s » n'a pas de nom lisible" % base.implicit_stat
		)


## Une famille sans affixe ne donne que des objets blancs : l'emplacement existe
## mais ne récompense jamais rien. Deux au minimum, sinon le tirage n'a pas de
## quoi faire deux objets différents.
func test_chaque_famille_a_de_quoi_tirer_des_affixes() -> void:
	for base in ItemCatalog.ALL:
		var possibles := ItemAffixPool.eligible(base).size()
		assert_gte(
			possibles, 2,
			"« %s » (famille %s) n'a que %d affixe(s) possible(s)"
				% [base.display_name, base.family, possibles]
		)
