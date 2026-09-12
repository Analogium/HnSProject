extends GutTest

## Le manuel comme objet : une base du catalogue qui tombe et se ramasse comme le
## reste, un archétype partagé qui dit ce qu'on peut y apprendre, et un état
## **par exemplaire** qui retient ce que celui-ci a appris.
##
## C'est la séparation entre les trois que ces tests défendent. La confondre est
## la faute la plus chère du jalon : les points écrits sur l'archétype partagé
## seraient ceux de tous les manuels de la partie.


func _base() -> ItemBase:
	return ItemCatalog.by_id("manuel_foudre")


# --------------------------------------------------------------------------
# La base, dans le catalogue
# --------------------------------------------------------------------------

func test_le_manuel_est_une_base_du_catalogue() -> void:
	var base := _base()
	assert_not_null(base, "le manuel se retrouve par son identifiant")
	assert_not_null(base.manuel, "et il ouvre un archétype")
	assert_false(base.manuel.nom.is_empty(), "qui porte un nom lisible")


## L'invariant du §3.2, dans les deux sens. Le sens oublié est celui qui coûte :
## une base non équipable **sans** archétype serait une faute de frappe dans un
## `family`, et elle passerait pour un manuel auprès de toutes les règles qui
## exemptent les manuels.
func test_un_archetype_va_avec_la_famille_du_manuel() -> void:
	for base in ItemCatalog.ALL:
		var est_manuel: bool = base.family == ItemBase.FAMILLE_MANUEL
		assert_eq(
			base.manuel != null, est_manuel,
			"« %s » : famille « %s » et archétype ne disent pas la même chose"
				% [base.display_name, base.family]
		)
		if not est_manuel:
			assert_true(
				EquipmentSlots.famille_equipable(base.family),
				"« %s » ne se porte nulle part et n'est pas un manuel" % base.display_name
			)


## Un manuel dont on ne peut rien apprendre à lancer est un objet qui occupe
## quatre cases du sac pour rien. **Ce que porte chaque case** est l'affaire de
## `test_talents.gd`, à qui appartient la règle « une case, une chose ».
func test_chaque_manuel_enseigne_au_moins_une_competence() -> void:
	for base in ItemCatalog.ALL:
		if base.manuel == null:
			continue
		assert_gt(base.manuel.cases.size(), 0, "« %s » est vide" % base.display_name)
		assert_gt(
			base.manuel.competences().size(), 0,
			"« %s » n'enseigne aucune compétence" % base.manuel.nom
		)


func test_l_archetype_retrouve_sa_case_par_l_identifiant() -> void:
	var arch := _base().manuel
	var c := arch.case_de("eclair_vif")
	assert_not_null(c, "la case existe")
	assert_eq(c.competence.id, "eclair_vif")
	assert_null(arch.case_de("sort_qui_n_existe_pas"), "et l'inconnu ne rend rien")
	assert_eq(
		arch.competences().size(), arch.cases.size() - arch.passifs().size(),
		"toutes les cases comptent, moins celles des passifs"
	)


# --------------------------------------------------------------------------
# L'exemplaire et son état
# --------------------------------------------------------------------------

func test_un_manuel_ramasse_a_son_propre_etat() -> void:
	var item := Item.new(_base())
	assert_not_null(item.manuel, "un manuel naît avec son état")
	assert_eq(item.manuel.points_places(), 0, "vierge")
	assert_eq(item.manuel.experience, 0)


func test_ce_qui_n_est_pas_un_manuel_n_a_pas_d_etat() -> void:
	assert_null(Item.new(ItemCatalog.by_id("epee")).manuel)


## **Le test de l'étape.** Deux manuels ramassés partagent leur archétype — c'est
## le même fichier du disque — et rien d'autre. Écrire dans l'un ne doit toucher
## ni l'autre, ni le `.tres`, que l'éditeur pourrait graver.
func test_deux_manuels_ont_des_points_independants() -> void:
	var a := Item.new(_base())
	var b := Item.new(_base())

	assert_same(a.base.manuel, b.base.manuel, "le contenu du livre est partagé")
	assert_ne(a.manuel, b.manuel, "ce qu'on y a appris, non")

	a.manuel.points["eclair_vif"] = 3
	a.manuel.experience = 400

	assert_eq(a.manuel.points_de("eclair_vif"), 3, "le premier a ses points")
	assert_eq(b.manuel.points_de("eclair_vif"), 0, "le second n'a rien reçu")
	assert_eq(b.manuel.experience, 0, "ni son expérience")

	# L'archétype partagé ne porte aucun état : si la moindre ligne de points y
	# atterrissait un jour, c'est ici qu'on le verrait.
	var neuf := Item.new(_base())
	assert_eq(neuf.manuel.points_places(), 0, "un troisième exemplaire naît vierge")


# --------------------------------------------------------------------------
# Ce qu'un manuel n'est pas
# --------------------------------------------------------------------------

## Il se range, il ne se porte pas. `equip()` doit le rendre intact plutôt que de
## le faire disparaître : un objet refusé ne se perd jamais.
func test_un_manuel_ne_s_equipe_nulle_part() -> void:
	var item := Item.new(_base())
	assert_eq(EquipmentSlots.free_for(item, {}), "", "aucun emplacement ne l'accepte")
	assert_false(EquipmentSlots.famille_equipable(item.base.family))
	for id in EquipmentSlots.ids():
		assert_false(EquipmentSlots.accepts(id, item), "ni « %s »" % id)


## Pas même les affixes universels : un livre qui donnerait « +12 % résistance au
## froid » se lirait comme un bug, et c'est ce que la réserve fait par défaut à
## toute base qu'aucune étiquette n'exclut.
func test_un_manuel_ne_recoit_aucun_affixe() -> void:
	var base := _base()
	assert_eq(ItemAffixPool.compatibles(base).size(), 0, "aucun affixe compatible")
	assert_eq(ItemAffixPool.eligible(base, 60).size(), 0, "pas même au niveau 60")
	assert_eq(
		ItemAffixPool.roll(RandomNumberGenerator.new(), base, 60).size(), 0,
		"et le tirage n'en invente pas"
	)


## Sa rareté ne vient pas du nombre d'affixes — il n'en a aucun — mais de sa
## version. Le livre de départ est commun ; ses versions plus rares viendront
## au-dessus, et c'est le palier qui le dira.
func test_la_rarete_d_un_manuel_vient_de_sa_version() -> void:
	var item := Item.new(_base())
	assert_eq(item.base.palier, 1, "le manuel de départ est le premier palier")
	assert_eq(item.rarity(), Item.Rarity.COMMUN)


# --------------------------------------------------------------------------
# La chute
# --------------------------------------------------------------------------

## Il tombe comme le reste : c'est ce qui a fait choisir d'en faire un objet du
## sac plutôt qu'une collection à part, et donc de ne pas réécrire la chute, le
## ramassage et le rangement une deuxième fois.
func test_un_manuel_tombe_et_arrive_entier() -> void:
	Game.rng.seed = 90210
	var vu: Item = null
	for i in 4000:
		var item := LootTable.roll(0, 1)
		if item != null and item.manuel != null:
			vu = item
			break
	assert_not_null(vu, "un manuel finit par tomber en zone 1")
	if vu == null:
		return
	assert_eq(vu.item_level, 1, "avec le niveau de sa zone, comme tout le reste")
	assert_eq(vu.manuel.points_places(), 0, "et vierge")

	# 2 × 2 dans le sac : il prend de la place, comme un objet.
	var sac := Inventory.new(Inventory.DEFAULT_COLS, Inventory.DEFAULT_ROWS)
	assert_true(sac.add(vu), "il se range")
	assert_eq(sac.placed.size(), 1)


# --------------------------------------------------------------------------
# L'expérience et les points (étape 4)
# --------------------------------------------------------------------------

## Une case fabriquée pour le test : le contenu du jeu changera, la règle non.
func _archetype_d_essai(niveau_requis: int, points_max: int) -> ManuelArchetype:
	var c := Competence.new()
	c.id = "essai"
	c.nom = "Essai"
	c.niveau_de_manuel_requis = niveau_requis
	var table: Array[float] = []
	for i in points_max:
		table.append(float(i + 1))
	c.degats_par_point = table

	var case := CaseDeManuel.new()
	case.competence = c
	var arch := ManuelArchetype.new()
	arch.id = "essai"
	arch.nom = "Essai"
	arch.cases = [case] as Array[CaseDeManuel]
	return arch


## Un livre tout juste ramassé a de quoi ouvrir une case. Sans ce premier point,
## sa page ne ferait rien du tout à la première ouverture — ce qui se lit comme
## une panne, pas comme une attente.
func test_un_manuel_neuf_a_deja_un_point() -> void:
	var m := Manuel.new()
	assert_eq(m.niveau(), 1)
	assert_eq(m.points_gagnes(), 1)
	assert_eq(m.points_restants(), 1)


func test_le_niveau_et_les_points_montent_avec_l_experience() -> void:
	var m := Manuel.new()
	m.gagner_experience(Manuel.XP_BASE)
	assert_eq(m.niveau(), 2, "le premier palier est franchi")
	assert_eq(m.points_restants(), 2, "et il donne un point de plus")


func test_l_experience_ne_descend_pas() -> void:
	var m := Manuel.new()
	m.gagner_experience(100)
	m.gagner_experience(-500)
	assert_eq(m.experience, 100, "un gain négatif ne retire rien")


func test_investir_place_un_point() -> void:
	var arch := _archetype_d_essai(1, 5)
	var m := Manuel.new()
	assert_true(m.investir(arch, "essai"))
	assert_eq(m.points_de("essai"), 1)
	assert_eq(m.points_restants(), 0, "le point est dépensé")


## Le garde-fou qui compte : on ne place pas ce qu'on n'a pas gagné.
func test_on_ne_place_pas_plus_de_points_qu_on_en_a() -> void:
	var arch := _archetype_d_essai(1, 5)
	var m := Manuel.new()
	assert_true(m.investir(arch, "essai"), "le point du niveau 1")
	assert_false(m.peut_investir(arch, "essai"), "et plus rien après")
	assert_false(m.investir(arch, "essai"))
	assert_eq(m.points_de("essai"), 1, "la case n'a pas bougé")


func test_on_ne_depasse_pas_le_maximum_d_une_case() -> void:
	var arch := _archetype_d_essai(1, 2)
	var m := Manuel.new()
	m.gagner_experience(999999)   # de quoi payer bien plus que deux points
	assert_true(m.investir(arch, "essai"))
	assert_true(m.investir(arch, "essai"))
	assert_false(m.investir(arch, "essai"), "la case est pleine")
	assert_eq(m.points_de("essai"), 2)
	assert_gt(m.points_restants(), 0, "il reste des points, mais pas où les mettre")


## Une case qui demande un niveau que le livre n'a pas refuse le point, et le
## rend quand le niveau arrive.
func test_une_case_verrouillee_refuse_puis_accepte() -> void:
	var arch := _archetype_d_essai(3, 5)
	var m := Manuel.new()
	assert_false(m.peut_investir(arch, "essai"), "niveau 1, la case demande 3")

	while m.niveau() < 3:
		m.gagner_experience(50)
	assert_true(m.investir(arch, "essai"), "au niveau 3, elle s'ouvre")


## Un identifiant que ce livre-là n'enseigne pas : refusé, même s'il existe
## ailleurs dans le jeu. C'est l'archétype qui décide, pas le catalogue.
func test_on_n_investit_pas_dans_une_case_absente() -> void:
	var arch := _archetype_d_essai(1, 5)
	var m := Manuel.new()
	assert_false(m.investir(arch, "eclair_vif"), "pas dans ce livre")
	assert_false(m.investir(null, "essai"), "ni sans livre du tout")
	assert_eq(m.points_places(), 0)
