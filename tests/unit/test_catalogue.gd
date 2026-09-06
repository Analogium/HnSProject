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
