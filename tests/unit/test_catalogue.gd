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
		# Le palier compris : chaque combinaison a sa propre entrée de cache, donc
		# un palier dont l'icône ne peindrait rien passerait entre les mailles.
		var tex := SpriteForge.inventory_icon(base.kind, Vector2i.ZERO, base.palier)
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
## mais ne récompense jamais rien.
##
## **Quatre au minimum, et dès le niveau d'objet 1** — le seuil était de deux
## jusqu'à l'étape 4 du jalon 5. Deux affixes ne font pas deux objets différents,
## ils font deux fois le même ; et mesuré au niveau 1, ce test attrape aussi
## l'échelle dont le dernier palier serait écrit trop haut, qui viderait les
## premières zones sans rien dire.
func test_chaque_famille_a_de_quoi_tirer_des_affixes() -> void:
	for base in ItemCatalog.ALL:
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
	for base in ItemCatalog.disponibles(1):
		assert_eq(base.palier, 1, "« %s » n\'est pas un premier palier" % base.display_name)
	for niveau in [1, 12, 30, 60]:
		for base in ItemCatalog.disponibles(niveau):
			assert_lte(
				base.niveau_requis, niveau,
				"« %s » tombe dans une zone de niveau %d" % [base.display_name, niveau]
			)


## Un niveau requis à zéro ou négatif rendrait une base disponible dans une zone
## qui n'existe pas, et surtout : il ne veut rien dire.
func test_aucune_base_n_a_un_niveau_requis_absurde() -> void:
	for base in ItemCatalog.ALL:
		assert_gte(base.niveau_requis, 1, "« %s »" % base.display_name)


# --------------------------------------------------------------------------
# Les lignées et leurs paliers (jalon 5, étape 5)
# --------------------------------------------------------------------------

## Une lignée, c\'est le même objet à trois âges. Un palier supérieur doit
## demander un niveau supérieur **et** donner un implicite supérieur : une lignée
## où le troisième palier vaut moins que le deuxième est un piège que personne ne
## remarque avant de comparer deux objets en jeu.
func test_chaque_lignee_est_monotone() -> void:
	var lignees := {}
	for base in ItemCatalog.ALL:
		assert_false(base.lignee.is_empty(), "« %s » n\'a pas de lignée" % base.display_name)
		if not lignees.has(base.lignee):
			lignees[base.lignee] = []
		lignees[base.lignee].append(base)

	for nom in lignees:
		var membres: Array = lignees[nom]
		membres.sort_custom(func(a: ItemBase, b: ItemBase) -> bool: return a.palier < b.palier)
		for i in membres.size():
			var base: ItemBase = membres[i]
			assert_eq(base.palier, i + 1, "lignée « %s » : les paliers se suivent depuis 1" % nom)
			if i == 0:
				continue
			var dessous: ItemBase = membres[i - 1]
			assert_gt(
				base.niveau_requis, dessous.niveau_requis,
				"« %s » doit se mériter plus que « %s »" % [base.display_name, dessous.display_name]
			)
			assert_eq(
				base.implicit_stat, dessous.implicit_stat,
				"lignée « %s » : deux paliers ne promettent pas la même chose" % nom
			)
			assert_gt(
				absf(base.implicit_value), absf(dessous.implicit_value),
				"« %s » donne moins que « %s »" % [base.display_name, dessous.display_name]
			)
		# Une lignée n\'a de sens qu\'à partir de deux paliers : à un seul, c\'est
		# une base isolée et le champ ment sur ce qu\'il décrit.
		assert_gte(membres.size(), 2, "lignée « %s » : un seul palier" % nom)


## Une lignée homogène : même famille, même dessin, mêmes étiquettes. Deux
## paliers qui ne vont pas au même emplacement ne sont pas deux âges du même
## objet, et la règle des paliers visibles ferait alors disparaître une base au
## profit d\'une autre qui ne la remplace pas.
func test_une_lignee_ne_melange_pas_deux_objets() -> void:
	var vus := {}
	for base in ItemCatalog.ALL:
		if not vus.has(base.lignee):
			vus[base.lignee] = base
			continue
		var premier: ItemBase = vus[base.lignee]
		assert_eq(base.family, premier.family, "lignée « %s »" % base.lignee)
		assert_eq(base.kind, premier.kind, "lignée « %s » : deux dessins" % base.lignee)
		assert_eq(
			", ".join(base.tags), ", ".join(premier.tags),
			"lignée « %s » : deux jeux d\'étiquettes" % base.lignee
		)


## La règle qui empêche la dilution. Elle n\'est plus écrite dans le code —
## chaque base déclare sa fenêtre, et la relève la ferme — donc c\'est ce test qui
## la tient : à aucun niveau une lignée ne doit lâcher plus de deux paliers.
##
## Vérifié à **chaque** niveau et non sur cinq d\'entre eux : le chevauchement
## dépend de l\'écart entre deux paliers voisins, et un troisième palier écrit
## trop près de son prédécesseur ouvrirait une fenêtre à trois quelque part au
## milieu de l\'échelle, là où personne ne penserait à regarder.
const PALIERS_SIMULTANES := 2


func test_une_lignee_ne_lache_jamais_plus_de_deux_paliers() -> void:
	for niveau in range(1, 61):
		var par_lignee := {}
		for base in ItemCatalog.disponibles(niveau):
			par_lignee[base.lignee] = int(par_lignee.get(base.lignee, 0)) + 1
		for lignee in par_lignee:
			assert_lte(
				par_lignee[lignee], PALIERS_SIMULTANES,
				"niveau %d : la lignée « %s » lâche %d paliers"
					% [niveau, lignee, par_lignee[lignee]]
			)


## Le sens de la règle, vu du joueur : descendre plus bas fait **disparaître**
## les vieilles bases — toutes, pas seulement l\'avant-dernière. Dans une zone de
## niveau 60, la lignée de la lame ne lâche plus que la lame de guerre.
##
## C\'est ce qui a changé : l\'épée large tombait encore au niveau 60 à côté de la
## lame de guerre, qui la surclasse sur tous les points. Une base périmée qui
## continue de tomber n\'est pas une chance de plus, c\'est du bruit.
func test_les_vieux_paliers_disparaissent() -> void:
	var ids := {}
	for base in ItemCatalog.disponibles(60):
		ids[base.id] = true
	assert_false(ids.has("epee"), "l\'épée de départ ne tombe plus au niveau 60")
	assert_false(ids.has("epee_large"), "l\'épée large non plus")
	assert_true(ids.has("lame_de_guerre"), "il ne reste que la lame de guerre")


## La fenêtre s\'ouvre exactement au niveau requis de la base : c\'est la seule des
## deux bornes que le `.tres` écrit noir sur blanc.
func test_la_fenetre_s_ouvre_au_niveau_requis() -> void:
	for base in ItemCatalog.ALL:
		assert_eq(
			ItemCatalog.fenetre_de_chute(base).x, base.niveau_requis,
			"« %s » s\'ouvre au niveau %d" % [base.display_name, base.niveau_requis]
		)


## Toute base doit tomber quelque part. Une base injoignable est du contenu que
## personne ne verra jamais, et rien d\'autre ne le signalerait.
func test_toute_base_tombe_a_un_moment() -> void:
	for base in ItemCatalog.ALL:
		var vue := false
		for niveau in range(1, 61):
			if ItemCatalog.disponibles(niveau).has(base):
				vue = true
				break
		assert_true(vue, "« %s » tombe quelque part" % base.display_name)


## L\'exemple qui a défini la règle : la lame de guerre ouvre au niveau 34, donc
## l\'épée large cesse de tomber après la zone 40. Le chiffre est écrit ici parce
## que c\'est celui qu\'on a demandé — s\'il bouge, ce doit être une décision, pas
## un effet de bord d\'un palier déplacé ailleurs.
func test_l_epee_large_s_arrete_apres_la_zone_40() -> void:
	var large := ItemCatalog.by_id("epee_large")
	assert_eq(ItemCatalog.fenetre_de_chute(large), Vector2i(16, 40))
	assert_true(ItemCatalog.disponibles(40).has(large), "elle tombe encore en zone 40")
	assert_false(ItemCatalog.disponibles(41).has(large), "plus en zone 41")


## Le meilleur palier d\'une lignée n\'est chassé par rien : sa fenêtre n\'a pas de
## fin. Sans ça, une zone profonde finirait par n\'avoir plus rien à lâcher dans
## cet emplacement.
func test_le_meilleur_palier_ne_se_ferme_jamais() -> void:
	var meilleur := {}
	for base in ItemCatalog.ALL:
		if not meilleur.has(base.lignee) or base.palier > meilleur[base.lignee].palier:
			meilleur[base.lignee] = base

	for lignee in meilleur:
		var base: ItemBase = meilleur[lignee]
		assert_eq(
			ItemCatalog.fenetre_de_chute(base).y, 0,
			"« %s » tient jusqu\'au bout" % base.display_name
		)
		assert_null(ItemCatalog.releve_de(base), "et rien ne prend sa relève")


## Une fenêtre vide est une base que personne ne verra jamais : elle ouvrirait
## après avoir été chassée. Impossible aujourd\'hui, mais c\'est exactement ce
## qu\'un palier écrit trop près de son successeur produirait.
func test_aucune_base_n_a_une_fenetre_vide() -> void:
	for base in ItemCatalog.ALL:
		var fenetre := ItemCatalog.fenetre_de_chute(base)
		if fenetre.y <= 0:
			continue
		assert_lte(
			fenetre.x, fenetre.y,
			"« %s » ouvre en %d et ferme en %d" % [base.display_name, fenetre.x, fenetre.y]
		)


## Un emplacement sans base disponible est un emplacement qu\'on ne peut pas
## remplir dans cette zone-là. Vérifié à **chaque** niveau, pas seulement au
## premier : c\'est un palier écrit trop haut qui creuserait le trou, et il
## n\'apparaîtrait qu\'entre deux zones.
func test_chaque_emplacement_a_une_base_a_tous_les_niveaux() -> void:
	for niveau in range(1, 61):
		var familles := {}
		for base in ItemCatalog.disponibles(niveau):
			familles[base.family] = true
		for id in EquipmentSlots.ids():
			assert_true(
				familles.has(EquipmentSlots.family_of(id)),
				"niveau %d : rien à mettre dans « %s »" % [niveau, EquipmentSlots.label(id)]
			)


## Les dix identifiants du jalon 4 sont écrits dans les sauvegardes des
## personnages existants. En renommer un ferait disparaître l\'objet de tout le
## monde, et seulement au prochain chargement.
func test_les_identifiants_du_jalon_4_survivent() -> void:
	for id in [
		"epee", "baguette", "bouclier", "casque", "plastron",
		"gants", "bottes", "ceinture", "amulette", "anneau",
	]:
		assert_not_null(ItemCatalog.by_id(id), "« %s » a disparu du catalogue" % id)
		assert_eq(ItemCatalog.by_id(id).palier, 1, "« %s » reste le premier palier" % id)
