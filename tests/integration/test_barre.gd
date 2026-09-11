extends GutTest

## La barre des cinq cases : ce qu'on clique, ce qu'on y pose, et ce que les
## touches annoncent.

const TAILLE := Vector2(154.0, 40.0)

var _barre: BarrePanel
var _joueur: Player


func before_each() -> void:
	_joueur = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_joueur)
	_barre = BarrePanel.new()
	_barre.size = TAILLE
	add_child_autofree(_barre)
	await wait_process_frames(1)
	_barre.bind(_joueur)


func _livre_travaille() -> Item:
	var livre := Item.new(ItemCatalog.by_id("manuel_foudre"))
	livre.manuel.gagner_experience(999999)
	livre.manuel.investir(livre.base.manuel, "eclair_vif")
	livre.manuel.investir(livre.base.manuel, "salve_d_eclairs")
	return livre


func test_le_clic_retrouve_la_case_dessinee() -> void:
	for i in BarreDeCompetences.EMPLACEMENTS:
		_barre._track(_barre._slot_rect(i).get_center())
		assert_eq(_barre._survol, i, "case %d" % i)


## Les cinq cases tiennent dans la fenêtre qu'on leur donne : une sixième case
## dessinée hors du cadre ne se verrait pas, elle serait simplement incliquable.
func test_les_cases_tiennent_dans_la_barre() -> void:
	var derniere: Rect2 = _barre._slot_rect(BarreDeCompetences.EMPLACEMENTS - 1)
	assert_lte(derniere.end.x, TAILLE.x, "la dernière case sort par la droite")
	assert_lte(derniere.end.y + BarrePanel.TOUCHE_H, TAILLE.y, "le libellé de touche déborde")


## Le libellé vient de la carte d'entrées, jamais d'une liste réécrite ici :
## deux vérités sur une touche, et la barre annonce un geste qui ne marche plus.
func test_les_libelles_viennent_de_la_carte_d_entrees() -> void:
	assert_eq(BarrePanel.libelle_de_touche(0), "clic G")
	assert_eq(BarrePanel.libelle_de_touche(1), "clic D")
	for i in [2, 3, 4]:
		assert_false(
			BarrePanel.libelle_de_touche(i).is_empty(),
			"la case %d n'annonce aucune touche" % (i + 1)
		)


## Le menu propose de vider — l'entrée sans compétence —, puis ce qu'on peut poser.
func test_le_menu_propose_le_vidage_puis_les_competences() -> void:
	var entrees := _barre._entrees()
	assert_eq(entrees.size(), 3, "vider, le coup d'épée, le tir")
	assert_null(entrees[0], "la première entrée vide la case")
	assert_eq(entrees[1].id, CompetenceCatalog.ID_ATTAQUE)
	assert_eq(entrees[2].id, CompetenceCatalog.ID_TIR)

	_joueur.etudier(_livre_travaille())
	assert_eq(_barre._entrees().size(), 5, "et les deux cases apprises")


## Le clic retombe sur l'entrée dessinée, **icône comprise** : c'est sur l'image
## qu'on vise d'abord, et une icône qui déborderait sur la voisine poserait la
## compétence d'à côté.
func test_le_clic_du_menu_retombe_sur_l_entree_dessinee() -> void:
	_joueur.etudier(_livre_travaille())
	_barre._ouvrir(2)
	for i in _barre._entrees().size():
		var icone: Rect2 = _barre._icone_d_entree(i)
		assert_true(_barre._menu_rect(i).encloses(icone), "l'icône de l'entrée %d déborde" % i)
		for point in [
			_barre._menu_rect(i).get_center(), icone.get_center(),
			icone.position + Vector2.ONE, icone.end - Vector2.ONE,
		]:
			_barre._track(point)
			assert_eq(_barre._survol_menu, i, "entrée %d, point %s" % [i, point])


## Le haut de la barre à l'écran, lu dans la scène de zone : elle est ancrée en bas
## à droite, et c'est de là que le menu monte.
func _haut_de_la_barre_dans_la_zone() -> float:
	var etat := (load("res://world/zone.tscn") as PackedScene).get_state()
	for i in etat.get_node_count():
		if etat.get_node_name(i) != "Barre":
			continue
		var proprietes := {}
		for j in etat.get_node_property_count(i):
			proprietes[etat.get_node_property_name(i, j)] = etat.get_node_property_value(i, j)
		return (
			float(proprietes.get("anchor_top", 0.0)) * float(Settings.taille_de_base().y)
			+ float(proprietes["offset_top"])
		)
	return -INF


## Le menu monte au-dessus de la barre et tient dans le cadrage, livre entier
## appris : une entrée coupée par le haut de l'écran serait une compétence qu'on
## ne pose jamais.
func test_le_menu_tient_dans_le_cadrage() -> void:
	var livre := Item.new(ItemCatalog.by_id("manuel_foudre"))
	livre.manuel.gagner_experience(999999)
	for competence in livre.base.manuel.competences():
		livre.manuel.investir(livre.base.manuel, competence.id)
	_joueur.etudier(livre)
	var entrees := _barre._entrees().size()
	assert_eq(entrees, 3 + livre.base.manuel.competences().size(), "tout le livre est proposé")

	var haut := _haut_de_la_barre_dans_la_zone() + _barre._menu_cadre(entrees).position.y
	assert_gte(haut, 0.0, "le menu sort par le haut de l'écran")


func test_ouvrir_et_fermer_le_menu_prend_et_rend_la_souris() -> void:
	_barre._ouvrir(2)
	assert_eq(_barre._menu, 2)
	assert_true(Game.ui_grabs_input, "le menu prend la souris")
	_barre._fermer()
	assert_eq(_barre._menu, -1)
	assert_false(Game.ui_grabs_input, "et la rend en se refermant")


func test_assigner_pose_la_competence_choisie() -> void:
	_barre._ouvrir(4)
	# Entrée 0 : vider. Entrée 1 : la première compétence disponible.
	_barre._assigner(1)
	assert_eq(_joueur.barre.id_de(4), CompetenceCatalog.ID_ATTAQUE)


## Une compétence déjà posée ailleurs se **déplace** : deux cases qui lancent la
## même chose sont deux touches perdues.
func test_une_competence_deja_posee_se_deplace() -> void:
	assert_eq(_joueur.barre.id_de(0), CompetenceCatalog.ID_ATTAQUE, "la barre de départ")
	_barre._ouvrir(3)
	_barre._assigner(1)   # le coup d'épée, déjà en case 0
	assert_eq(_joueur.barre.id_de(3), CompetenceCatalog.ID_ATTAQUE, "il est arrivé ici")
	assert_eq(_joueur.barre.id_de(0), "", "et il a quitté sa case d'avant")


func test_la_premiere_entree_vide_la_case() -> void:
	_barre._ouvrir(0)
	_barre._assigner(0)
	assert_eq(_joueur.barre.id_de(0), "", "la case est vide")


## Le dessin traverse ses états sans se plaindre : une case vide, une case
## chargée, une recharge en cours et un menu ouvert.
func test_le_dessin_traverse_ses_etats() -> void:
	_joueur.etudier(_livre_travaille())
	_joueur.barre.poser(2, "eclair_vif")
	_joueur.lancer(1)
	_barre._ouvrir(2)
	_barre._track(_barre._menu_rect(1).get_center())
	_barre.queue_redraw()
	await wait_process_frames(1)
	assert_gt(_joueur._recharges[1], 0.0, "une recharge est bien en cours")


## La barre ne répond que des clics tombés sur elle — sauf le menu ouvert, qui
## est modal et se referme par un clic au-dehors.
func test_la_barre_ne_prend_que_ses_clics() -> void:
	assert_true(_barre._possede_le_clic(_barre._slot_rect(0).get_center()))
	assert_false(_barre._possede_le_clic(Vector2(-40.0, 10.0)), "à gauche de la barre")

	_barre._ouvrir(0)
	assert_true(_barre._possede_le_clic(Vector2(-40.0, 10.0)), "le menu ouvert prend l'écran")
