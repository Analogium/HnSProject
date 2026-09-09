extends GutTest

## Le râtelier et la page : ce qu'on voit et ce qu'on clique doivent être au même
## endroit, et les quatre conditions de l'investissement doivent tenir même
## lorsqu'on clique là où il ne faut pas.

const TAILLE := Vector2(210.0, 230.0)

var _panneau: ManuelPanel
var _joueur: Player


func before_each() -> void:
	_joueur = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_joueur)
	# Le panneau vit dans la scène de zone et n'a pas de scène propre : on lui
	# donne ici la taille que ses ancres lui donnent là-bas.
	_panneau = ManuelPanel.new()
	_panneau.size = TAILLE
	add_child_autofree(_panneau)
	await wait_process_frames(1)
	_panneau.bind(_joueur)
	_panneau.visible = true


func _livre() -> Item:
	return Item.new(ItemCatalog.by_id("manuel_foudre"))


## Le cœur d'un dos de livre retombe sur ce dos-là. Un décalage entre le dessin
## et le calcul ne se voit pas : on croit que le clic « n'a pas marché ».
func test_le_clic_retrouve_l_emplacement_dessine() -> void:
	for i in Ratelier.EMPLACEMENTS:
		_panneau._track(_panneau._slot_rect(i).get_center())
		assert_eq(_panneau._survol_slot, i, "emplacement %d" % i)


func test_hors_des_emplacements_rien_n_est_survole() -> void:
	_panneau._track(Vector2(TAILLE.x - 2.0, 2.0))
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
		assert_lte(r.end.x, TAILLE.x, "la case sort par la droite")
		# La ligne du bas décrit la case survolée : les carrés ne doivent pas
		# descendre dessus. Mesuré avec **la même fonction** que le dessin, sinon
		# ce test validerait sa propre copie du calcul.
		assert_lte(r.end.y, _panneau._fiche_top(), "la case couvre la fiche")


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
	_panneau._track(_panneau._case_rect(Vector2i.ZERO).get_center())
	_panneau.queue_redraw()
	await wait_process_frames(1)

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
		_panneau._possede_le_clic(Vector2(TAILLE.x + 30.0, TAILLE.y * 0.5)),
		"à droite, là où le sac est ouvert"
	)
