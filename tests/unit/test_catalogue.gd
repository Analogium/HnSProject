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
		var item := LootTable.roll(0, 1)
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


# --------------------------------------------------------------------------
# Les étiquettes (jalon 5)
# --------------------------------------------------------------------------

## La famille est la première étiquette de chaque base. C'est ce qui laisse un
## affixe viser « les bottes » sans vocabulaire supplémentaire — et c'est ce qui
## a rendu la migration du jalon 5 mécanique. L'oublier sur une base nouvelle la
## rendrait invisible à tous les affixes écrits sur sa famille, sans un mot.
func test_chaque_base_porte_sa_famille_en_etiquette() -> void:
	for base in ItemCatalog.ALL:
		assert_false(
			base.tags.is_empty(),
			"« %s » n\'a aucune étiquette : elle ne recevra que les affixes universels"
				% base.display_name
		)
		assert_true(
			base.tags.has(base.family),
			"« %s » ne porte pas sa famille « %s » en étiquette"
				% [base.display_name, base.family]
		)


## Une étiquette écrite sur un affixe et sur aucune base est une règle qui ne
## s\'applique jamais : l\'affixe paraît ciblé et sort partout, ou ne sort nulle
## part. Les deux se découvrent en jouant, jamais en lisant.
func test_aucune_etiquette_d_affixe_ne_vise_le_vide() -> void:
	var portees := {}
	for base in ItemCatalog.ALL:
		for t in base.tags:
			portees[t] = true
	for a in ItemAffixPool.ALL:
		for t in a.tags:
			assert_true(portees.has(t), "l\'affixe « %s » vise « %s », que personne ne porte" % [a.id, t])
		for t in a.exclut:
			assert_true(portees.has(t), "l\'affixe « %s » exclut « %s », que personne ne porte" % [a.id, t])


## Ce que le catalogue laisse tomber dépend du niveau de la zone. Toutes les
## bases du jalon 4 valent 1 : elles habillent la première zone, et ce sont les
## paliers de l'étape 5 qui creuseront cet écart.
func test_les_bases_disponibles_suivent_le_niveau_de_la_zone() -> void:
	assert_eq(ItemCatalog.disponibles(0).size(), 0, "rien avant le niveau 1")
	assert_eq(
		ItemCatalog.disponibles(1).size(), ItemCatalog.ALL.size(),
		"tout est disponible dès la première zone"
	)
	for base in ItemCatalog.disponibles(60):
		assert_lte(base.niveau_requis, 60, "« %s » ne devrait pas être là" % base.display_name)


## Un niveau requis à zéro ou négatif rendrait une base disponible dans une zone
## qui n'existe pas, et surtout : il ne veut rien dire.
func test_aucune_base_n_a_un_niveau_requis_absurde() -> void:
	for base in ItemCatalog.ALL:
		assert_gte(base.niveau_requis, 1, "« %s »" % base.display_name)
