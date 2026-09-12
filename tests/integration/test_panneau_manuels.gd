extends GutTest

## Le râtelier et la page : ce qu'on voit et ce qu'on clique doivent être au même
## endroit, et les conditions de l'investissement doivent tenir même lorsqu'on
## clique là où il ne faut pas.
##
## Depuis le jalon 10, la page a deux vues — la grille des cases et l'arbre d'une
## compétence — et **ce qui tombe dans un test, c'est le passage de l'une à
## l'autre** : une vue qui reste ouverte sur un livre rangé dessine les nœuds
## d'un manuel qui n'est plus là.

var _panneau: ManuelPanel
var _joueur: Player


func before_each() -> void:
	_joueur = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_joueur)
	# Le panneau vit dans la scène de zone et n'a pas de scène propre : on lui
	# donne la place qu'il y occupe, lue dans la scène et non recopiée. La fiche se
	# borne à l'écran d'après cette place ; une place inventée validerait un
	# panneau qui n'est pas celui du jeu.
	_panneau = ManuelPanel.new()
	var cadre := _cadre_dans_la_zone()
	_panneau.position = cadre.position
	_panneau.size = cadre.size
	add_child_autofree(_panneau)
	await wait_process_frames(1)
	_panneau.bind(_joueur)
	_panneau.visible = true


func _cadre_dans_la_zone() -> Rect2:
	var etat := (load("res://world/zone.tscn") as PackedScene).get_state()
	for i in etat.get_node_count():
		if etat.get_node_name(i) != "Manuels":
			continue
		var bords := {}
		for j in etat.get_node_property_count(i):
			bords[etat.get_node_property_name(i, j)] = etat.get_node_property_value(i, j)
		return Rect2(
			bords["offset_left"], bords["offset_top"],
			bords["offset_right"] - bords["offset_left"], bords["offset_bottom"] - bords["offset_top"]
		)
	return Rect2()


func _livre() -> Item:
	return Item.new(ItemCatalog.by_id("manuel_foudre"))


## Un livre au râtelier, avec de quoi payer : la plupart de ces tests regardent
## des conditions, pas la courbe d'expérience.
func _livre_riche() -> Item:
	var livre := _livre()
	livre.manuel.gagner_experience(999999)
	_joueur.etudier(livre)
	return livre


## La case d'une compétence du manuel de la foudre, celle dont l'arbre sert de
## terrain d'essai.
func _case_d_eclair() -> CaseDeManuel:
	return ItemCatalog.by_id("manuel_foudre").manuel.case_de("eclair_vif")


func _clic_sur(point: Vector2, bouton := MOUSE_BUTTON_LEFT) -> void:
	_panneau._track(point)
	if bouton == MOUSE_BUTTON_LEFT:
		_panneau._clic_gauche()
	else:
		_panneau._clic_droit()


# --------------------------------------------------------------------------
# Le râtelier
# --------------------------------------------------------------------------

## Le cœur d'un dos de livre retombe sur ce dos-là. Un décalage entre le dessin
## et le calcul ne se voit pas : on croit que le clic « n'a pas marché ».
func test_le_clic_retrouve_l_emplacement_dessine() -> void:
	for i in Ratelier.EMPLACEMENTS:
		_panneau._track(_panneau._slot_rect(i).get_center())
		assert_eq(_panneau._survol_slot, i, "emplacement %d" % i)


func test_hors_des_emplacements_rien_n_est_survole() -> void:
	_panneau._track(Vector2(_panneau.size.x - 2.0, 2.0))
	assert_eq(_panneau._survol_slot, -1)
	assert_eq(_panneau._survol_case, -1)


func test_le_clic_choisit_l_emplacement() -> void:
	_joueur.etudier(_livre(), 2)
	_panneau._track(_panneau._slot_rect(2).get_center())
	_panneau._survol_slot = 2
	_panneau._choisi = 2
	assert_not_null(_panneau._livre(), "la page est celle du livre choisi")
	_panneau._choisi = 0
	assert_null(_panneau._livre(), "et l'emplacement vide n'ouvre rien")


## Ranger rend le livre au sac, avec ses points : c'est toute la promesse du
## jalon 6 — un manuel emporte sa progression.
func test_ranger_rend_le_livre_au_sac_avec_ses_points() -> void:
	var livre := _livre_riche()
	_panneau._investir("eclair_vif")
	_panneau._ranger(0)

	assert_null(_joueur.ratelier.a(0), "le râtelier est libre")
	assert_eq(_joueur.inventory.placed.size(), 1, "et le livre est dans le sac")
	assert_eq(livre.manuel.points_de("eclair_vif"), 1, "avec ce qu'il a appris")


## Le sac plein, le livre tombe plutôt que de s'évaporer.
func test_un_livre_range_sans_place_est_jete() -> void:
	var livre := _livre()
	_joueur.etudier(livre)
	# Bouché avec des objets d'**une** case : cinquante anneaux remplissent la
	# grille exactement. Des plastrons n'y arriveraient pas — cinq y entrent et
	# laissent deux rangées libres, largement de quoi ranger un livre.
	for i in Inventory.DEFAULT_COLS * Inventory.DEFAULT_ROWS:
		assert_true(
			_joueur.inventory.add(Item.new(ItemCatalog.by_id("anneau"))),
			"le sac accepte les cinquante"
		)

	var jetes: Array[Item] = []
	_panneau.drop_requested.connect(func(item: Item) -> void: jetes.append(item))
	_panneau._ranger(0)

	assert_eq(jetes.size(), 1, "il est tombé au sol")
	assert_same(jetes[0], livre, "et c'est bien lui")


# --------------------------------------------------------------------------
# La grille
# --------------------------------------------------------------------------

## Tout ce que la page dessine tient dans la fenêtre. Aucune assertion ne voit un
## carré qui déborde ; celle-ci le calcule avec **les mêmes fonctions** que le
## dessin, sinon elle validerait sa propre copie.
func test_les_cases_et_les_noeuds_tiennent_dans_le_panneau() -> void:
	var cadre := Rect2(
		0.0, _panneau._page_top(), _panneau.size.x, _panneau._aide_top() - _panneau._page_top()
	)
	for base: ItemBase in ItemCatalog.ALL:
		if base.manuel == null:
			continue
		for case: CaseDeManuel in base.manuel.cases:
			assert_true(
				cadre.encloses(_panneau._case_rect(case.position)),
				"« %s » : la case %s sort de la page" % [case.identifiant(), case.position]
			)
			for noeud: NoeudDeTalent in case.talents:
				assert_true(
					cadre.encloses(_panneau._noeud_rect(noeud.position)),
					"« %s » : le nœud %s sort de la page" % [noeud.id, noeud.position]
				)
	assert_true(cadre.encloses(_panneau._racine_rect()), "et la racine d'un arbre y tient")


## Le clic sur une case de compétence **ouvre son arbre** : c'est là que se
## placent ses points depuis le jalon 10.
func test_le_clic_sur_une_competence_ouvre_son_arbre() -> void:
	_livre_riche()
	_clic_sur(_panneau._case_rect(_case_d_eclair().position).get_center())
	assert_not_null(_panneau._case_ouverte(), "l'arbre est ouvert")
	assert_eq(_panneau._case_ouverte().competence.id, "eclair_vif")


## Un passif n'a rien à orienter : le clic y place un point directement.
func test_le_clic_sur_un_passif_place_un_point() -> void:
	var livre := _livre_riche()
	var case := livre.base.manuel.cases[4]
	assert_not_null(case.passif, "la cinquième case du manuel de la foudre est son passif")

	_clic_sur(_panneau._case_rect(case.position).get_center())
	assert_null(_panneau._case_ouverte(), "un passif n'ouvre pas de vue")
	assert_eq(livre.manuel.points_de(case.passif.id), 1)


func test_un_clic_dans_le_vide_ne_place_rien() -> void:
	var livre := _livre_riche()
	_clic_sur(Vector2(_panneau.size.x - 3.0, _panneau._aide_top() - 2.0))
	_panneau._investir("sort_qui_n_existe_pas")
	assert_eq(livre.manuel.points_places(), 0)


## Sans livre à l'emplacement ouvert, aucun clic ne peut rien faire.
func test_sans_livre_le_panneau_ne_fait_rien() -> void:
	_panneau._investir("eclair_vif")
	assert_null(_panneau._livre())
	assert_null(_panneau._case_ouverte())


# --------------------------------------------------------------------------
# L'arbre
# --------------------------------------------------------------------------

func _ouvrir_l_arbre() -> Item:
	var livre := _livre_riche()
	_clic_sur(_panneau._case_rect(_case_d_eclair().position).get_center())
	return livre


## La racine **est** la case de la compétence : c'est le seul endroit où ses
## points se placent, et le clic doit y tomber comme sur la grille.
func test_le_clic_sur_la_racine_place_un_point_de_competence() -> void:
	var livre := _ouvrir_l_arbre()
	_clic_sur(_panneau._racine_rect().get_center())
	assert_eq(livre.manuel.points_de("eclair_vif"), 1)


func test_le_clic_retrouve_le_noeud_dessine() -> void:
	_ouvrir_l_arbre()
	var talents := _case_d_eclair().talents
	for i in talents.size():
		_panneau._track(_panneau._noeud_rect(talents[i].position).get_center())
		assert_eq(_panneau._survol_noeud, i, "« %s »" % talents[i].id)
		assert_false(_panneau._survol_racine, "et ce n'est pas la racine")


## Le clic dans un nœud place un point, et c'est `Manuel` qui décide : sans point
## dans la compétence, le nœud refuse.
func test_le_clic_sur_un_noeud_place_un_point_quand_l_arbre_le_permet() -> void:
	var livre := _ouvrir_l_arbre()
	var branche := _case_d_eclair().talents[0]

	_clic_sur(_panneau._noeud_rect(branche.position).get_center())
	assert_eq(livre.manuel.points_de(branche.id), 0, "aucun point dans la compétence")

	_clic_sur(_panneau._racine_rect().get_center())
	_clic_sur(_panneau._noeud_rect(branche.position).get_center())
	assert_eq(livre.manuel.points_de(branche.id), 1, "la compétence ouverte, le nœud accepte")


## Le clic droit reprend un point de nœud — et seulement d'un nœud.
func test_le_clic_droit_reprend_un_point_de_noeud() -> void:
	var livre := _ouvrir_l_arbre()
	var branche := _case_d_eclair().talents[0]
	_clic_sur(_panneau._racine_rect().get_center())
	_clic_sur(_panneau._noeud_rect(branche.position).get_center())
	var restants := livre.manuel.points_restants()

	_clic_sur(_panneau._noeud_rect(branche.position).get_center(), MOUSE_BUTTON_RIGHT)
	assert_eq(livre.manuel.points_de(branche.id), 0, "le point est reparti")
	assert_eq(livre.manuel.points_restants(), restants + 1, "et il est replaçable")

	_clic_sur(_panneau._racine_rect().get_center(), MOUSE_BUTTON_RIGHT)
	assert_eq(livre.manuel.points_de("eclair_vif"), 1, "la compétence, elle, ne se défait pas")


## Le clic droit à côté d'un nœud revient à la grille : le geste du retour est
## celui qui range, et il n'y a pas une touche de plus à connaître.
func test_le_clic_droit_a_cote_revient_a_la_grille() -> void:
	_ouvrir_l_arbre()
	_clic_sur(Vector2(_panneau.size.x - 3.0, _panneau._aide_top() - 2.0), MOUSE_BUTTON_RIGHT)
	assert_null(_panneau._case_ouverte(), "on est revenu sur la grille")


func test_echap_referme_l_arbre_avant_la_fenetre() -> void:
	_ouvrir_l_arbre()
	var touche := InputEventKey.new()
	touche.keycode = KEY_ESCAPE
	touche.pressed = true
	_panneau._input(touche)
	assert_null(_panneau._case_ouverte(), "l'arbre s'est refermé")
	assert_true(_panneau.visible, "et la fenêtre est restée ouverte")


## **Le piège du jalon.** Ranger le livre dont l'arbre est ouvert laisserait la
## vue dessiner les nœuds d'un manuel qui n'est plus au râtelier.
func test_ranger_le_livre_referme_son_arbre() -> void:
	_ouvrir_l_arbre()
	_panneau._ranger(0)
	assert_null(_panneau._case_ouverte())
	assert_null(_panneau._livre())


## Choisir un autre livre referme l'arbre : celui du premier ne veut rien dire
## sur la page du second.
func test_changer_de_livre_referme_l_arbre() -> void:
	_ouvrir_l_arbre()
	_joueur.etudier(Item.new(ItemCatalog.by_id("manuel_armes")), 1)
	_clic_sur(_panneau._slot_rect(1).get_center())
	assert_eq(_panneau._choisi, 1)
	assert_null(_panneau._case_ouverte())


# --------------------------------------------------------------------------
# Les fiches
# --------------------------------------------------------------------------

## Les valeurs des lignes de la fiche qui portent cet intitulé, dans leur ordre.
func _valeurs(lignes: Array, libelle: String) -> PackedStringArray:
	var out := PackedStringArray()
	for ligne: ManuelPanel.LigneDeFiche in lignes:
		if ligne.libelle == libelle:
			out.append(ligne.valeur)
	return out


func _fiche_de(livre: Item, competence_id: String) -> Array:
	return _panneau._fiche_de_competence(
		livre.manuel, CompetenceCatalog.by_id(competence_id)
	).lignes


## **La fiche passe par le même chemin que le lancer** (jalon 7, étape 5). Avec un
## « +1 projectile » porté, elle en annonce deux — et ce sont bien deux traits qui
## partent. Lue sur la compétence, elle en aurait annoncé un.
func test_la_fiche_annonce_ce_qui_part_vraiment() -> void:
	var livre := _livre_riche()
	livre.manuel.investir(livre.base.manuel, "eclair_vif")
	assert_eq(_valeurs(_fiche_de(livre, "eclair_vif"), "projectiles"), PackedStringArray(["1"]))

	_joueur.equip(Item.new(
		ItemCatalog.by_id("baguette"), [ItemAffixPool.by_id("fourchu").modificateur(1.0)]
	))
	assert_eq(
		_valeurs(_fiche_de(livre, "eclair_vif"), "projectiles"), PackedStringArray(["2"]),
		"la fiche en annonce deux"
	)

	var tirs := Node2D.new()
	add_child_autofree(tirs)
	_joueur.projectile_parent = tirs
	_joueur.barre.poser(2, "eclair_vif")
	assert_true(_joueur.lancer(2))
	assert_eq(tirs.get_child_count(), 2, "et deux partent")


## Et elle annonce aussi ce qu'un **nœud** change : c'est le même chemin, et un
## talent lu dans le dessin rouvrirait la faille que le jalon 7 a fermée.
func test_la_fiche_annonce_ce_qu_un_noeud_change() -> void:
	var livre := _livre_riche()
	# La fourche demande deux points dans la compétence et un dans sa branche :
	# l'ordre compte, et c'est `Manuel` qui refuserait le raccourci.
	for id in ["eclair_vif", "eclair_vif", "eclair_vif_surcharge", "eclair_vif_fourche"]:
		assert_true(livre.manuel.investir(livre.base.manuel, id), "« %s »" % id)

	var lignes := _fiche_de(livre, "eclair_vif")
	assert_eq(
		_valeurs(lignes, "projectiles"), PackedStringArray(["2"]),
		"le nœud de fourche en ajoute un"
	)
	assert_eq(
		_valeurs(lignes, "dégâts accrus"), PackedStringArray(["+12 %"]),
		"et la surcharge accroît les dégâts"
	)


## Un nœud de conversion dit ce qu'il déplace et où : c'est la ligne qui explique
## à quelle résistance le coup s'oppose désormais.
func test_la_fiche_annonce_la_conversion() -> void:
	var livre := _livre_riche()
	for id in ["eclair_vif", "eclair_vif", "eclair_vif", "eclair_vif_trait_de_glace"]:
		assert_true(livre.manuel.investir(livre.base.manuel, id), "« %s »" % id)

	assert_eq(
		_valeurs(_fiche_de(livre, "eclair_vif"), "converti"), PackedStringArray(["50 % en froid"])
	)


## La fiche d'un passif dit ce qu'il donne, **avec les mots de l'infobulle d'un
## objet** : « +20 armure » doit se lire pareil, qu'il vienne d'un plastron ou
## d'un livre.
func test_la_fiche_d_un_passif_dit_ce_qu_il_donne() -> void:
	var livre := Item.new(ItemCatalog.by_id("manuel_armes"))
	livre.manuel.gagner_experience(999999)
	_joueur.etudier(livre)
	var passif: Passif = livre.base.manuel.passifs()[0]
	for i in 2:
		assert_true(livre.manuel.investir(livre.base.manuel, passif.id))

	var fiche := _panneau._fiche_de_passif(livre.manuel, passif)
	assert_eq(fiche.titre, passif.nom_affiche())
	assert_eq(fiche.sous_titre, "toujours actif", "ce qu'il faut savoir de lui avant ses nombres")
	assert_eq(_valeurs(fiche.lignes, "points"), PackedStringArray(["2 / %d" % passif.points_max]))
	assert_eq(_valeurs(fiche.lignes, "armure"), PackedStringArray(["+24"]), "deux points de douze")


## La fiche d'un nœud fermé dit **ce qu'il demande**, et c'est le manuel qui le
## dit — la page ne porte aucune condition.
func test_la_fiche_d_un_noeud_dit_ce_qu_il_demande() -> void:
	var livre := _livre_riche()
	var case := _case_d_eclair()
	var branche := case.talents[0]
	var feuille := case.talents[1]

	assert_eq(
		_valeurs(_panneau._fiche_de_noeud(livre.manuel, case, branche).lignes, "demande"),
		PackedStringArray(["1 point dans la compétence"])
	)
	livre.manuel.investir(livre.base.manuel, "eclair_vif")
	livre.manuel.investir(livre.base.manuel, "eclair_vif")
	assert_eq(
		_valeurs(_panneau._fiche_de_noeud(livre.manuel, case, feuille).lignes, "demande"),
		PackedStringArray(["le talent « %s »" % branche.nom_affiche()]),
		"le parent d'abord : c'est la condition qu'on peut satisfaire tout de suite"
	)

	livre.manuel.investir(livre.base.manuel, branche.id)
	assert_eq(
		_valeurs(_panneau._fiche_de_noeud(livre.manuel, case, feuille).lignes, "demande").size(), 0,
		"ouverte, elle ne demande plus rien"
	)


## Un nœud qui donne un mot-clé le dit : c'est ce qui le distingue d'un nœud de
## conversion simple, et ça vaut un point de plus.
func test_la_fiche_d_un_noeud_annonce_le_mot_cle_qu_il_donne() -> void:
	var livre := _livre_riche()
	var case := ItemCatalog.by_id("manuel_foudre").manuel.case_de("fulguration")
	var embrasement := case.noeud_de("fulguration_embrasement")
	var lignes := _panneau._fiche_de_noeud(livre.manuel, case, embrasement).lignes

	assert_eq(_valeurs(lignes, "mot-clé"), PackedStringArray(["Feu"]))
	assert_eq(_valeurs(lignes, "converti"), PackedStringArray(["60 % en feu"]))


## **Chaque ligne vient de la résolution du lancer** : un sort à trois natures et
## plusieurs projectiles, lu ligne à ligne contre `Player.resoudre()` au même
## nombre de points.
func test_chaque_ligne_vient_de_la_resolution_du_lancer() -> void:
	var livre := _livre_riche()
	for i in 2:
		livre.manuel.investir(livre.base.manuel, "salve_d_eclairs")
	_joueur.equip(Item.new(ItemCatalog.by_id("baguette"), [
		ItemAffixPool.by_id("froid_aux_sorts").modificateur(3.0, 7.0),
		ItemAffixPool.by_id("feu_aux_sorts").modificateur(2.0, 5.0),
		ItemAffixPool.by_id("fourchu").modificateur(1.0),
		ItemAffixPool.by_id("orageux").modificateur(20.0),
	]))
	var salve := CompetenceCatalog.by_id("salve_d_eclairs")
	var geste := _joueur.resoudre(salve, 2)
	var lignes := _fiche_de(livre, "salve_d_eclairs")

	assert_eq(_valeurs(lignes, "points"), PackedStringArray(["2 / %d" % salve.points_max()]))
	assert_eq(_valeurs(lignes, "coût"), PackedStringArray(["%d mana" % roundi(geste.cout_en_mana)]))
	assert_eq(_valeurs(lignes, "recharge"), PackedStringArray(["%.2f s" % geste.intervalle]))
	assert_eq(
		_valeurs(lignes, "de base"), PackedStringArray(["%d foudre" % roundi(geste.degats_de_base)])
	)
	assert_eq(
		_valeurs(lignes, "ajoutés"), PackedStringArray(["3–7 froid", "2–5 feu"]),
		"une ligne par nature ajoutée, dans l'ordre des natures"
	)
	var attribut := PackedStringArray()
	if not is_equal_approx(geste.facteur_d_attribut, 1.0):
		attribut.append("%+d %%" % roundi((geste.facteur_d_attribut - 1.0) * 100.0))
	assert_eq(_valeurs(lignes, "intelligence"), attribut)
	assert_eq(_valeurs(lignes, "dégâts accrus"), PackedStringArray(["+20 %"]))
	assert_eq(_valeurs(lignes, "par projectile"), PackedStringArray([
		"%d–%d" % [roundi(geste.total_min()), roundi(geste.total_max())]
	]))
	assert_eq(
		_valeurs(lignes, "projectiles"), PackedStringArray([str(geste.nombre_de_projectiles())])
	)
	assert_eq(geste.nombre_de_projectiles(), salve.projectiles + 1, "la salve et son projectile de plus")
	assert_eq(
		_valeurs(lignes, "écart"), PackedStringArray(["%d°" % roundi(geste.dispersion_en_degres)])
	)
	assert_eq(
		_valeurs(lignes, "vitesse"),
		PackedStringArray(["%d px/s" % roundi(geste.vitesse_de_projectile)])
	)
	assert_eq(
		_valeurs(lignes, "moyenne par lancer"),
		PackedStringArray([str(roundi(geste.moyenne_par_lancer()))])
	)
	assert_eq(
		_valeurs(lignes, "par seconde"),
		PackedStringArray([str(roundi(geste.moyenne_par_seconde()))])
	)
	assert_eq(_valeurs(lignes, "si tout touche, avant défenses").size(), 1, "et ce qu'elle suppose")


## Une nature sans dégâts n'a pas de ligne : rien d'équipé, rien d'ajouté ; un
## anneau de feu, et seule la ligne du feu apparaît.
func test_une_nature_sans_degats_n_a_pas_de_ligne() -> void:
	var livre := _livre()
	_joueur.etudier(livre)
	var nue := _fiche_de(livre, "eclair_vif")
	assert_eq(_valeurs(nue, "ajoutés").size(), 0, "rien d'équipé, rien d'ajouté")
	assert_eq(_valeurs(nue, "dégâts accrus").size(), 0)
	assert_eq(_valeurs(nue, "écart").size(), 0, "un trait droit n'a pas d'écart")
	assert_eq(_valeurs(nue, "converti").size(), 0, "et rien n'est converti")

	_joueur.equip(Item.new(
		ItemCatalog.by_id("anneau"), [ItemAffixPool.by_id("feu_aux_sorts").modificateur(2.0, 5.0)]
	))
	assert_eq(_valeurs(_fiche_de(livre, "eclair_vif"), "ajoutés"), PackedStringArray(["2–5 feu"]))


## Une case verrouillée dit ce qu'elle demande, et montre les nombres du premier
## point plutôt que zéro.
func test_une_case_verrouillee_dit_ce_qu_elle_demande() -> void:
	var livre := _livre()
	_joueur.etudier(livre)
	var haute: Competence = null
	for competence in livre.base.manuel.competences():
		if haute == null or competence.niveau_de_manuel_requis > haute.niveau_de_manuel_requis:
			haute = competence
	assert_lt(livre.manuel.niveau(), haute.niveau_de_manuel_requis, "un livre neuf ne l'ouvre pas")

	var lignes := _fiche_de(livre, haute.id)
	assert_eq(
		_valeurs(lignes, "verrouillée"),
		PackedStringArray(["niveau %d du manuel" % haute.niveau_de_manuel_requis])
	)
	assert_eq(_valeurs(lignes, "points"), PackedStringArray(["0 / %d" % haute.points_max()]))
	assert_eq(
		_valeurs(lignes, "de base"),
		PackedStringArray(["%d foudre" % roundi(haute.degats_par_point[0])]), "le premier point"
	)
	assert_eq(
		_valeurs(_fiche_de(livre, "eclair_vif"), "verrouillée").size(), 0,
		"une case ouverte ne se dit pas verrouillée"
	)


## La fiche reste dans le cadrage et au-dessus des jauges du HUD, **quoi que l'on
## survole** : une case, un passif, un nœud. Mesurée avec le cadre du dessin, sur
## les fiches les plus longues qu'on sache monter — les six natures ajoutées, un
## accroissement, un projectile de plus, et un livre neuf dont les cases hautes
## sont verrouillées.
func test_la_fiche_reste_dans_le_cadrage() -> void:
	var mods: Array[StatMod] = [
		ItemAffixPool.by_id("fourchu").modificateur(1.0),
		ItemAffixPool.by_id("orageux").modificateur(20.0),
	]
	for nature: String in DamageType.IDS:
		mods.append(ItemAffixPool.by_id("%s_aux_sorts" % nature).modificateur(20.0, 60.0))
	_joueur.equip(Item.new(ItemCatalog.by_id("baguette"), mods))

	var base_ecran := Vector2(Settings.taille_de_base())
	var cadrage := Rect2(0.0, 0.0, base_ecran.x, Hud.haut_des_jauges(base_ecran.y))
	var mesurees := 0
	for modele: ItemBase in ItemCatalog.ALL:
		if modele.manuel == null:
			continue
		var livre := Item.new(modele)
		_joueur.ratelier.retirer(0)
		_joueur.etudier(livre, 0)
		for case: CaseDeManuel in modele.manuel.cases:
			_mesure(
				_panneau._fiche_de_case(livre.manuel, case),
				_panneau._case_rect(case.position), cadrage, case.identifiant()
			)
			mesurees += 1
			for noeud: NoeudDeTalent in case.talents:
				_mesure(
					_panneau._fiche_de_noeud(livre.manuel, case, noeud),
					_panneau._noeud_rect(noeud.position), cadrage, noeud.id
				)
				mesurees += 1
	assert_gt(mesurees, 0, "encore faut-il qu'il y ait des cases")


func _mesure(fiche: ManuelPanel.Fiche, ancre: Rect2, cadrage: Rect2, quoi: String) -> void:
	var r: Rect2 = _panneau._fiche_rect(ancre, _panneau._hauteur_de_fiche(fiche.lignes))
	var a_l_ecran := Rect2(r.position + _panneau.global_position, r.size)
	assert_true(
		cadrage.encloses(a_l_ecran), "« %s » : la fiche %s sort de %s" % [quoi, a_l_ecran, cadrage]
	)


# --------------------------------------------------------------------------
# Le dessin
# --------------------------------------------------------------------------

## Le dessin traverse ses états sans se plaindre : un emplacement vide, une
## grille, un passif, un arbre à moitié rempli. Ce que ça **donne à l'œil** est du
## ressort de la capture ; ce qu'on vérifie ici, c'est qu'aucun de ces chemins ne
## plante.
func test_le_dessin_traverse_ses_etats() -> void:
	_panneau.queue_redraw()
	await wait_process_frames(1)

	var livre := _livre_riche()
	for i in 9:
		livre.manuel.investir(livre.base.manuel, "eclair_vif")
	for case in livre.base.manuel.cases:
		_panneau._track(_panneau._case_rect(case.position).get_center())
		_panneau.queue_redraw()
		await wait_process_frames(1)

	_clic_sur(_panneau._case_rect(_case_d_eclair().position).get_center())
	for noeud in _case_d_eclair().talents:
		livre.manuel.investir(livre.base.manuel, noeud.id)
		_panneau._track(_panneau._noeud_rect(noeud.position).get_center())
		_panneau.queue_redraw()
		await wait_process_frames(1)
	_panneau._track(_panneau._racine_rect().get_center())
	_panneau.queue_redraw()
	await wait_process_frames(1)

	assert_eq(
		livre.manuel.points_de("eclair_vif"), 5,
		"la case est pleine : c'est l'état qu'on vient de dessiner"
	)
	assert_gt(livre.manuel.points_de("eclair_vif_surcharge"), 0, "et l'arbre est entamé")


## **Plusieurs fenêtres ouvertes doivent toutes répondre.** Un panneau qui
## consomme les clics tombés au-dehors rend sourds tous les autres : c'était le
## cas du sac, qui prenait tout dès qu'il était ouvert.
func test_un_clic_au_dehors_est_laisse_aux_autres_panneaux() -> void:
	assert_true(_panneau._possede_le_clic(_panneau._slot_rect(1).get_center()), "sur un dos")
	assert_false(_panneau._possede_le_clic(Vector2(-30.0, 40.0)), "à gauche de la fenêtre")
	assert_false(
		_panneau._possede_le_clic(Vector2(_panneau.size.x + 30.0, _panneau.size.y * 0.5)),
		"à droite, là où le sac est ouvert"
	)
