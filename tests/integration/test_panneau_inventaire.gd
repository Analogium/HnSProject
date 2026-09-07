extends GutTest

## La géométrie du panneau : ce qu'on voit et ce qu'on clique doivent être au
## même endroit.
##
## Ces tests existent parce que la fenêtre a changé de largeur et que ses deux
## grilles sont maintenant centrées, chacune de son côté. Un décalage entre le
## dessin et le calcul de la case sous le curseur ne se voit pas — on croit
## simplement que le clic « n'a pas marché ».

var _panneau: InventoryPanel
var _joueur: Player


func before_each() -> void:
	_joueur = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_joueur)
	# Le panneau vit dans la scène de zone et n'a pas de scène propre : on monte
	# le Control et le Label de titre que son @onready attend.
	_panneau = InventoryPanel.new()
	var titre := Label.new()
	titre.name = "Title"
	_panneau.add_child(titre)
	add_child_autofree(_panneau)
	await wait_process_frames(1)
	_panneau.bind(_joueur)


## Le cœur d'une case du sac retombe sur cette case. Sans ça, prendre un objet
## en attraperait un autre — ou rien.
func test_le_clic_retrouve_la_case_dessinee() -> void:
	for cell in [Vector2i(0, 0), Vector2i(4, 2), Vector2i(9, 4), Vector2i(8, 2)]:
		var centre: Vector2 = _panneau._rect_of(cell, Vector2i.ONE).get_center()
		assert_eq(_panneau._cell_at(centre), cell, "case %s" % cell)


## Le sac est centré dans une fenêtre plus large que lui : un point à gauche de
## son bord n'est plus la colonne 0, c'est le dehors.
func test_hors_du_sac_ne_rend_pas_une_case_valide() -> void:
	var dedans := _panneau._rect_of(Vector2i(0, 0), Vector2i.ONE)
	assert_eq(_panneau._cell_at(dedans.position - Vector2(4.0, 0.0)).x, -1, "à gauche du sac")
	assert_lt(_panneau._cell_at(Vector2(0.0, 0.0)).y, 0, "au-dessus du sac")


func test_le_clic_retrouve_l_emplacement_dessine() -> void:
	for i in EquipmentSlots.count():
		var centre: Vector2 = _panneau._slot_rect(i).get_center()
		assert_eq(
			_panneau._slot_at(centre), i,
			"emplacement %d (%s)" % [i, EquipmentSlots.ids()[i]]
		)


## Le portrait n'est pas un emplacement : cliquer dessus ne doit rien attraper.
func test_le_portrait_n_est_pas_cliquable() -> void:
	assert_eq(_panneau._slot_at(_panneau._doll_area_rect().get_center()), -1)


## Les deux grilles tiennent dans le panneau, et le panneau dans le cadrage.
func test_le_panneau_tient_dans_le_cadrage() -> void:
	var taille: Vector2 = _panneau._panel_size()
	assert_lte(taille.x, 640.0, "largeur")
	assert_lte(taille.y, 360.0, "hauteur : la fenêtre déborderait de l'écran")
	assert_gte(taille.x, _panneau._equip_size().x, "la grille du personnage tient dedans")
