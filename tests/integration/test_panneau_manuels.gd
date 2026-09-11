extends GutTest

## Le râtelier et la page : ce qu'on voit et ce qu'on clique doivent être au même
## endroit, et les quatre conditions de l'investissement doivent tenir même
## lorsqu'on clique là où il ne faut pas.

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


## Tout ce que la page dessine tient dans la fenêtre. Aucune assertion ne voit un
## carré qui déborde ; celle-ci le calcule avec **la même fonction** que le
## dessin, sinon elle validerait sa propre copie.
func test_les_cases_tiennent_dans_le_panneau() -> void:
	_joueur.etudier(_livre())
	for case in ItemCatalog.by_id("manuel_foudre").manuel.cases:
		var r: Rect2 = _panneau._case_rect(case.position)
		assert_gte(r.position.y, _panneau._page_top(), "la case déborde sur le râtelier")
		assert_lte(r.end.x, _panneau.size.x, "la case sort par la droite")
		assert_lte(r.end.y, _panneau._aide_top(), "la case couvre la ligne d'aide")


func test_le_clic_choisit_l_emplacement() -> void:
	_joueur.etudier(_livre(), 2)
	_panneau._track(_panneau._slot_rect(2).get_center())
	_panneau._survol_slot = 2
	_panneau._choisi = 2
	assert_not_null(_panneau._livre(), "la page est celle du livre choisi")
	_panneau._choisi = 0
	assert_null(_panneau._livre(), "et l'emplacement vide n'ouvre rien")


## Le clic sur une case place un point, et c'est `Manuel` qui décide — pas le
## panneau.
func test_le_clic_sur_une_case_place_un_point() -> void:
	var livre := _livre()
	_joueur.etudier(livre)
	_panneau._investir(0)
	assert_eq(livre.manuel.points_de("eclair_vif"), 1)

	# Le point du niveau 1 est dépensé : le second clic ne doit rien donner.
	_panneau._investir(0)
	assert_eq(livre.manuel.points_de("eclair_vif"), 1, "on ne place pas ce qu'on n'a pas")


func test_un_clic_dans_le_vide_ne_place_rien() -> void:
	var livre := _livre()
	_joueur.etudier(livre)
	_panneau._investir(-1)
	_panneau._investir(99)
	assert_eq(livre.manuel.points_places(), 0)


## Sans livre à l'emplacement ouvert, aucun clic ne peut rien faire.
func test_sans_livre_le_panneau_ne_fait_rien() -> void:
	_panneau._investir(0)
	assert_null(_panneau._livre())


## Ranger rend le livre au sac, avec ses points : c'est toute la promesse du
## jalon — un manuel emporte sa progression.
func test_ranger_rend_le_livre_au_sac_avec_ses_points() -> void:
	var livre := _livre()
	_joueur.etudier(livre)
	_panneau._investir(0)
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


## Les valeurs des lignes de la fiche qui portent cet intitulé, dans leur ordre.
func _valeurs(lignes: Array, libelle: String) -> PackedStringArray:
	var out := PackedStringArray()
	for ligne: ManuelPanel.LigneDeFiche in lignes:
		if ligne.libelle == libelle:
			out.append(ligne.valeur)
	return out


func _fiche_de(livre: Item, competence_id: String) -> Array:
	return _panneau._lignes_de_fiche(livre.manuel, CompetenceCatalog.by_id(competence_id))


## **La fiche passe par le même chemin que le lancer** (jalon 7, étape 5). Avec un
## « +1 projectile » porté, elle en annonce deux — et ce sont bien deux traits qui
## partent. Lue sur la compétence, elle en aurait annoncé un.
func test_la_fiche_annonce_ce_qui_part_vraiment() -> void:
	var livre := _livre()
	livre.manuel.gagner_experience(999999)
	livre.manuel.investir(livre.base.manuel, "eclair_vif")
	_joueur.etudier(livre)
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


## **Chaque ligne vient de la résolution du lancer** : un sort à trois natures et
## plusieurs projectiles, lu ligne à ligne contre `Player.resoudre()` au même
## nombre de points.
func test_chaque_ligne_vient_de_la_resolution_du_lancer() -> void:
	var livre := _livre()
	livre.manuel.gagner_experience(999999)
	for i in 2:
		livre.manuel.investir(livre.base.manuel, "salve_d_eclairs")
	_joueur.etudier(livre)
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
	for case in livre.base.manuel.cases:
		if haute == null or case.competence.niveau_de_manuel_requis > haute.niveau_de_manuel_requis:
			haute = case.competence
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


## La fiche reste dans le cadrage et au-dessus des jauges du HUD, **quelle que
## soit la case survolée**. Mesurée avec le cadre du dessin, sur la fiche la plus
## longue qu'on sache monter : les six natures ajoutées, un accroissement, un
## projectile de plus, et un livre neuf dont les cases hautes sont verrouillées.
func test_la_fiche_reste_dans_le_cadrage() -> void:
	var mods: Array[StatMod] = [
		ItemAffixPool.by_id("fourchu").modificateur(1.0),
		ItemAffixPool.by_id("orageux").modificateur(20.0),
	]
	for nature: String in DamageType.IDS:
		mods.append(ItemAffixPool.by_id("%s_aux_sorts" % nature).modificateur(20.0, 60.0))
	_joueur.equip(Item.new(ItemCatalog.by_id("baguette"), mods))

	var base := Vector2(Settings.taille_de_base())
	var cadrage := Rect2(0.0, 0.0, base.x, Hud.haut_des_jauges(base.y))
	var mesurees := 0
	for modele: ItemBase in ItemCatalog.ALL:
		if modele.manuel == null:
			continue
		var livre := Item.new(modele)
		for case: CaseDeManuel in modele.manuel.cases:
			var lignes := _panneau._lignes_de_fiche(livre.manuel, case.competence)
			var r: Rect2 = _panneau._fiche_rect(case, _panneau._hauteur_de_fiche(lignes))
			var a_l_ecran := Rect2(r.position + _panneau.global_position, r.size)
			assert_true(
				cadrage.encloses(a_l_ecran),
				"« %s » : la fiche %s sort de %s" % [case.competence.nom, a_l_ecran, cadrage]
			)
			mesurees += 1
	assert_gt(mesurees, 0, "encore faut-il qu'il y ait des cases")


## Le dessin traverse ses trois états sans se plaindre : un emplacement vide, un
## livre neuf, une case pleine. Ce que ça **donne à l'œil** est du ressort de la
## capture ; ce qu'on vérifie ici, c'est qu'aucun de ces chemins ne plante.
func test_le_dessin_traverse_ses_etats() -> void:
	_panneau.queue_redraw()
	await wait_process_frames(1)

	var livre := _livre()
	_joueur.etudier(livre)
	livre.manuel.gagner_experience(999999)
	for i in 9:
		livre.manuel.investir(livre.base.manuel, "eclair_vif")
	for case in livre.base.manuel.cases:
		_panneau._track(_panneau._case_rect(case.position).get_center())
		_panneau.queue_redraw()
		await wait_process_frames(1)
	_panneau._track(_panneau._case_rect(Vector2i.ZERO).get_center())

	assert_eq(
		livre.manuel.points_de("eclair_vif"), 5,
		"la case est pleine : c'est l'état qu'on vient de dessiner"
	)


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
