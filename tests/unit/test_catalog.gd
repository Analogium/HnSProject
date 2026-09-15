extends GutTest

## Le catalogue des bases d'objets. Ce qu'on vérifie ici n'a l'air de rien —
## des identifiants présents et distincts — mais c'est la condition pour qu'un
## objet sauvegardé se recharge. Un doublon ferait charger silencieusement la
## mauvaise base : on rangerait une épée, on reprendrait une baguette.


func test_each_base_has_an_id() -> void:
	for base in ItemCatalog.ALL:
		assert_false(
			base.id.strip_edges().is_empty(),
			"« %s » n'a pas d'identifiant : ses exemplaires seraient perdus au chargement"
				% base.display_name
		)


func test_ids_are_unique() -> void:
	var seen_all := {}
	for base in ItemCatalog.ALL:
		assert_false(seen_all.has(base.id), "identifiant « %s » en double" % base.id)
		seen_all[base.id] = true
	assert_eq(seen_all.size(), ItemCatalog.ALL.size())


func test_a_base_is_found_by_its_id() -> void:
	for base in ItemCatalog.ALL:
		assert_eq(ItemCatalog.by_id(base.id), base, "aller-retour sur « %s »" % base.id)


## Le cas que la sauvegarde rencontrera pour de vrai : une base retirée du
## projet depuis. Un null, pas une erreur — c'est à l'appelant d'ignorer l'objet.
func test_a_vanished_base_returns_null() -> void:
	assert_null(ItemCatalog.by_id("halberd_from_2027"))
	assert_null(ItemCatalog.by_id(""))


## Deux listes de bases auraient fini par diverger, et un objet qui tombe sans
## pouvoir être rechargé est pire qu'un objet qui ne tombe pas.
func test_loot_rolls_from_the_catalog() -> void:
	Game.rng.seed = 31337
	var seen_bases := {}
	for i in 400:
		var item := LootTable.roll(0, 1)
		if item != null:
			seen_bases[item.base.id] = true
			assert_not_null(
				ItemCatalog.by_id(item.base.id), "une chute doit être rechargeable"
			)
	assert_gt(seen_bases.size(), 1, "plusieurs bases tirées, pas toujours la même")


# --------------------------------------------------------------------------
# Les dix familles (jalon 4)
# --------------------------------------------------------------------------

## Un emplacement sans base est un emplacement qui restera vide toute la partie,
## sans que rien ne le signale.
func test_each_slot_has_at_least_one_base() -> void:
	var families := {}
	for base in ItemCatalog.ALL:
		families[base.family] = true
	for id in EquipmentSlots.ids():
		assert_true(
			families.has(EquipmentSlots.family_of(id)),
			"aucune base ne va dans « %s »" % EquipmentSlots.label(id)
		)


## Une icône vide ne se découvre qu'en ramassant l'objet. La forge dessine soit
## une pièce d'équipement, soit une arme : un `kind` qui n'est ni l'un ni l'autre
## produit un dessin sans un seul pixel peint.
func test_each_base_has_a_non_empty_icon() -> void:
	for base in ItemCatalog.ALL:
		# Le palier compris : chaque combinaison a sa propre entrée de cache, donc
		# un palier dont l'icône ne peindrait rien passerait entre les mailles.
		var tex := SpriteForge.inventory_icon(base.kind, Vector2i.ZERO, base.tier)
		assert_not_null(tex, "« %s » n'a pas d'icône" % base.display_name)
		assert_gt(
			tex.get_size().x * tex.get_size().y, 0.0,
			"l'icône de « %s » (kind « %s ») ne peint rien" % [base.display_name, base.kind]
		)


## L'implicite d'une base vise un champ de la fiche. Une faute de frappe
## modifierait silencieusement une statistique qui n'existe pas.
func test_implicits_target_real_stats() -> void:
	var sheet := CharacterStats.new()
	for base in ItemCatalog.ALL:
		if base.implicit_stat.is_empty():
			continue
		# Un implicite porté vise un mot-clé et un nombre de lancer, comme un
		# affixe porté : l'épée ajoute des dégâts aux attaques.
		if not base.implicit_scope.is_empty():
			assert_true(Keywords.exists(base.implicit_scope), "« %s » : portée inconnue" % base.display_name)
			assert_true(
				SkillStats.modifiable(base.implicit_stat),
				"« %s » vise « %s », qu'un modificateur ne peut pas toucher"
					% [base.display_name, base.implicit_stat]
			)
			assert_gte(
				base.implicit_value_max, base.implicit_value,
				"« %s » : fourchette à l'envers" % base.display_name
			)
			continue
		assert_true(
			sheet.get(base.implicit_stat) != null,
			"« %s » vise « %s », qui n'est pas dans la fiche"
				% [base.display_name, base.implicit_stat]
		)
		assert_true(
			StatMod.LABELS.has(base.implicit_stat),
			"« %s » n'a pas de nom lisible" % base.implicit_stat
		)


## Une famille sans affixe ne donne que des objets blancs : l'emplacement existe
## mais ne récompense jamais rien.
##
## **Quatre au minimum, et dès le niveau d'objet 1** — le seuil était de deux
## jusqu'à l'étape 4 du jalon 5. Deux affixes ne font pas deux objets différents,
## ils font deux fois le même ; et mesuré au niveau 1, ce test attrape aussi
## l'échelle dont le dernier palier serait écrit trop haut, qui viderait les
## premières zones sans rien dire.
func test_each_family_has_affixes_to_roll() -> void:
	for base in ItemCatalog.ALL:
		# Une base qui ne se porte nulle part n'a pas d'affixes à recevoir, et ce
		# n'est pas un appauvrissement du butin : un manuel vaut par ce qu'on y
		# apprend. **Le seuil de quatre ne bouge pas pour autant** — l'abaisser
		# pour faire passer un manuel remplirait les premières zones de blanc.
		if not EquipmentSlots.equippable_family(base.family):
			continue
		var possibles := ItemAffixPool.eligible(base, 1).size()
		assert_gte(
			possibles, 4,
			"« %s » (famille %s) n'a que %d affixe(s) possible(s) au niveau 1"
				% [base.display_name, base.family, possibles]
		)


# --------------------------------------------------------------------------
# Les étiquettes (jalon 5)
# --------------------------------------------------------------------------

## La famille est la première étiquette de chaque base. C'est ce qui laisse un
## affixe viser « les bottes » sans vocabulaire supplémentaire — et c'est ce qui
## a rendu la migration du jalon 5 mécanique. L'oublier sur une base nouvelle la
## rendrait invisible à tous les affixes écrits sur sa famille, sans un mot.
func test_each_base_carries_its_family_as_a_tag() -> void:
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
func test_no_affix_tag_targets_nothing() -> void:
	var scopes := {}
	for base in ItemCatalog.ALL:
		for t in base.tags:
			scopes[t] = true
	for a in ItemAffixPool.ALL:
		for t in a.tags:
			assert_true(scopes.has(t), "l\'affixe « %s » vise « %s », que personne ne porte" % [a.id, t])
		for t in a.excludes:
			assert_true(scopes.has(t), "l\'affixe « %s » exclut « %s », que personne ne porte" % [a.id, t])


## Ce que le catalogue laisse tomber dépend du niveau de la zone. Toutes les
## bases du jalon 4 valent 1 : elles habillent la première zone, et ce sont les
## paliers de l'étape 5 qui creuseront cet écart.
func test_available_bases_follow_the_zone_level() -> void:
	assert_eq(ItemCatalog.available(0).size(), 0, "rien avant le niveau 1")
	for base in ItemCatalog.available(1):
		assert_eq(base.tier, 1, "« %s » n\'est pas un premier palier" % base.display_name)
	for level in [1, 12, 30, 60]:
		for base in ItemCatalog.available(level):
			assert_lte(
				base.required_level, level,
				"« %s » tombe dans une zone de niveau %d" % [base.display_name, level]
			)


## Un niveau requis à zéro ou négatif rendrait une base disponible dans une zone
## qui n'existe pas, et surtout : il ne veut rien dire.
func test_no_base_has_an_absurd_required_level() -> void:
	for base in ItemCatalog.ALL:
		assert_gte(base.required_level, 1, "« %s »" % base.display_name)


# --------------------------------------------------------------------------
# Les lignées et leurs paliers (jalon 5, étape 5)
# --------------------------------------------------------------------------

## Une lignée, c\'est le même objet à trois âges. Un palier supérieur doit
## demander un niveau supérieur **et** donner un implicite supérieur : une lignée
## où le troisième palier vaut moins que le deuxième est un piège que personne ne
## remarque avant de comparer deux objets en jeu.
func test_each_lineage_is_monotonic() -> void:
	var lineages := {}
	for base in ItemCatalog.ALL:
		assert_false(base.lineage.is_empty(), "« %s » n\'a pas de lignée" % base.display_name)
		# Les paliers d'une lignée sont la règle de relève de l'équipement : le
		# palier suivant chasse le précédent du butin. Les manuels n'en sont pas —
		# leurs versions rares devront tomber **en plus** de la commune, pas à sa
		# place — et leur palier ne sert qu'à dire leur rareté.
		if not EquipmentSlots.equippable_family(base.family):
			continue
		if not lineages.has(base.lineage):
			lineages[base.lineage] = []
		lineages[base.lineage].append(base)

	for name in lineages:
		var limbs: Array = lineages[name]
		limbs.sort_custom(func(a: ItemBase, b: ItemBase) -> bool: return a.tier < b.tier)
		for i in limbs.size():
			var base: ItemBase = limbs[i]
			assert_eq(base.tier, i + 1, "lignée « %s » : les paliers se suivent depuis 1" % name)
			if i == 0:
				continue
			var below: ItemBase = limbs[i - 1]
			assert_gt(
				base.required_level, below.required_level,
				"« %s » doit se mériter plus que « %s »" % [base.display_name, below.display_name]
			)
			assert_eq(
				base.implicit_stat, below.implicit_stat,
				"lignée « %s » : deux paliers ne promettent pas la même chose" % name
			)
			assert_gt(
				absf(base.implicit_value), absf(below.implicit_value),
				"« %s » donne moins que « %s »" % [base.display_name, below.display_name]
			)
			assert_gte(
				base.implicit_value_max, below.implicit_value_max,
				"« %s » monte moins haut que « %s »" % [base.display_name, below.display_name]
			)
		# Une lignée n\'a de sens qu\'à partir de deux paliers : à un seul, c\'est
		# une base isolée et le champ ment sur ce qu\'il décrit.
		assert_gte(limbs.size(), 2, "lignée « %s » : un seul palier" % name)


## Une lignée homogène : même famille, même dessin, mêmes étiquettes. Deux
## paliers qui ne vont pas au même emplacement ne sont pas deux âges du même
## objet, et la règle des paliers visibles ferait alors disparaître une base au
## profit d\'une autre qui ne la remplace pas.
func test_a_lineage_does_not_mix_two_items() -> void:
	var seen_all := {}
	for base in ItemCatalog.ALL:
		if not seen_all.has(base.lineage):
			seen_all[base.lineage] = base
			continue
		var first: ItemBase = seen_all[base.lineage]
		assert_eq(base.family, first.family, "lignée « %s »" % base.lineage)
		assert_eq(base.kind, first.kind, "lignée « %s » : deux dessins" % base.lineage)
		assert_eq(
			", ".join(base.tags), ", ".join(first.tags),
			"lignée « %s » : deux jeux d\'étiquettes" % base.lineage
		)


## La règle qui empêche la dilution. Elle n\'est plus écrite dans le code —
## chaque base déclare sa fenêtre, et la relève la ferme — donc c\'est ce test qui
## la tient : à aucun niveau une lignée ne doit lâcher plus de deux paliers.
##
## Vérifié à **chaque** niveau et non sur cinq d\'entre eux : le chevauchement
## dépend de l\'écart entre deux paliers voisins, et un troisième palier écrit
## trop près de son prédécesseur ouvrirait une fenêtre à trois quelque part au
## milieu de l\'échelle, là où personne ne penserait à regarder.
const SIMULTANEOUS_TIERS := 2


func test_a_lineage_never_drops_more_than_two_tiers() -> void:
	for level in range(1, 61):
		var by_lineage := {}
		for base in ItemCatalog.available(level):
			by_lineage[base.lineage] = int(by_lineage.get(base.lineage, 0)) + 1
		for lineage in by_lineage:
			assert_lte(
				by_lineage[lineage], SIMULTANEOUS_TIERS,
				"niveau %d : la lignée « %s » lâche %d paliers"
					% [level, lineage, by_lineage[lineage]]
			)


## Le sens de la règle, vu du joueur : descendre plus bas fait **disparaître**
## les vieilles bases — toutes, pas seulement l\'avant-dernière. Dans une zone de
## niveau 60, la lignée de la lame ne lâche plus que la lame de guerre.
##
## C\'est ce qui a changé : l\'épée large tombait encore au niveau 60 à côté de la
## lame de guerre, qui la surclasse sur tous les points. Une base périmée qui
## continue de tomber n\'est pas une chance de plus, c\'est du bruit.
func test_old_tiers_disappear() -> void:
	var ids := {}
	for base in ItemCatalog.available(60):
		ids[base.id] = true
	assert_false(ids.has("sword"), "l\'épée de départ ne tombe plus au niveau 60")
	assert_false(ids.has("broadsword"), "l\'épée large non plus")
	assert_true(ids.has("war_blade"), "il ne reste que la lame de guerre")


## La fenêtre s\'ouvre exactement au niveau requis de la base : c\'est la seule des
## deux bornes que le `.tres` écrit noir sur blanc.
func test_the_window_opens_at_the_required_level() -> void:
	for base in ItemCatalog.ALL:
		assert_eq(
			ItemCatalog.drop_window(base).x, base.required_level,
			"« %s » s\'ouvre au niveau %d" % [base.display_name, base.required_level]
		)


## Toute base doit tomber quelque part. Une base injoignable est du contenu que
## personne ne verra jamais, et rien d\'autre ne le signalerait.
func test_every_base_drops_at_some_point() -> void:
	for base in ItemCatalog.ALL:
		var view := false
		for level in range(1, 61):
			if ItemCatalog.available(level).has(base):
				view = true
				break
		assert_true(view, "« %s » tombe quelque part" % base.display_name)


## L\'exemple qui a défini la règle : la lame de guerre ouvre au niveau 34, donc
## l\'épée large cesse de tomber après la zone 40. Le chiffre est écrit ici parce
## que c\'est celui qu\'on a demandé — s\'il bouge, ce doit être une décision, pas
## un effet de bord d\'un palier déplacé ailleurs.
func test_the_broadsword_stops_after_zone_40() -> void:
	var large := ItemCatalog.by_id("broadsword")
	assert_eq(ItemCatalog.drop_window(large), Vector2i(16, 40))
	assert_true(ItemCatalog.available(40).has(large), "elle tombe encore en zone 40")
	assert_false(ItemCatalog.available(41).has(large), "plus en zone 41")


## Le meilleur palier d\'une lignée n\'est chassé par rien : sa fenêtre n\'a pas de
## fin. Sans ça, une zone profonde finirait par n\'avoir plus rien à lâcher dans
## cet emplacement.
func test_the_best_tier_never_closes() -> void:
	var best := {}
	for base in ItemCatalog.ALL:
		if not best.has(base.lineage) or base.tier > best[base.lineage].tier:
			best[base.lineage] = base

	for lineage in best:
		var base: ItemBase = best[lineage]
		assert_eq(
			ItemCatalog.drop_window(base).y, 0,
			"« %s » tient jusqu\'au bout" % base.display_name
		)
		assert_null(ItemCatalog.reading_of(base), "et rien ne prend sa relève")


## Une fenêtre vide est une base que personne ne verra jamais : elle ouvrirait
## après avoir été chassée. Impossible aujourd\'hui, mais c\'est exactement ce
## qu\'un palier écrit trop près de son successeur produirait.
func test_no_base_has_an_empty_window() -> void:
	for base in ItemCatalog.ALL:
		var window := ItemCatalog.drop_window(base)
		if window.y <= 0:
			continue
		assert_lte(
			window.x, window.y,
			"« %s » ouvre en %d et ferme en %d" % [base.display_name, window.x, window.y]
		)


## Un emplacement sans base disponible est un emplacement qu\'on ne peut pas
## remplir dans cette zone-là. Vérifié à **chaque** niveau, pas seulement au
## premier : c\'est un palier écrit trop haut qui creuserait le trou, et il
## n\'apparaîtrait qu\'entre deux zones.
func test_each_slot_has_a_base_at_every_level() -> void:
	for level in range(1, 61):
		var families := {}
		for base in ItemCatalog.available(level):
			families[base.family] = true
		for id in EquipmentSlots.ids():
			assert_true(
				families.has(EquipmentSlots.family_of(id)),
				"niveau %d : rien à mettre dans « %s »" % [level, EquipmentSlots.label(id)]
			)


## Les dix identifiants du jalon 4 sont écrits dans les sauvegardes des
## personnages existants. En renommer un ferait disparaître l\'objet de tout le
## monde, et seulement au prochain chargement.
func test_milestone_4_ids_survive() -> void:
	for id in [
		"sword", "wand", "shield", "helmet", "breastplate",
		"gloves", "boots", "belt", "amulet", "ring",
	]:
		assert_not_null(ItemCatalog.by_id(id), "« %s » a disparu du catalogue" % id)
		assert_eq(ItemCatalog.by_id(id).tier, 1, "« %s » reste le premier palier" % id)
