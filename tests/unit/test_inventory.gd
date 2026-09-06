extends GutTest

## Le sac. Un RefCounted sans nœud ni dessin — la seule partie du jeu qui se
## teste exactement comme un module web.

var _sac: Inventory
var _epee: ItemBase
var _plastron: ItemBase


func before_each() -> void:
	_sac = Inventory.new(10, 5)
	_epee = load("res://resources/items/epee.tres")
	_plastron = load("res://resources/items/plastron.tres")


func test_grille_vide_au_depart() -> void:
	assert_eq(_sac.cell_count(), 50)
	assert_eq(_sac.used_cells(), 0)
	assert_eq(_sac.index_at(Vector2i(0, 0)), Inventory.EMPTY)


func test_un_objet_occupe_son_rectangle() -> void:
	assert_true(_sac.place(Item.new(_plastron), Vector2i(0, 0)), "posé")
	# 2 colonnes sur 3 lignes
	assert_eq(_sac.used_cells(), 6)
	assert_ne(_sac.index_at(Vector2i(1, 2)), Inventory.EMPTY, "coin bas-droit occupé")
	assert_eq(_sac.index_at(Vector2i(2, 0)), Inventory.EMPTY, "la colonne suivante est libre")


func test_deux_objets_ne_se_chevauchent_pas() -> void:
	assert_true(_sac.place(Item.new(_plastron), Vector2i(0, 0)))
	assert_false(_sac.fits(Item.new(_epee), Vector2i(1, 1)), "recouvrement refusé")
	assert_false(_sac.place(Item.new(_epee), Vector2i(1, 1)))
	assert_eq(_sac.used_cells(), 6, "rien n'a été posé")


func test_un_objet_ne_deborde_pas_de_la_grille() -> void:
	# L'épée fait 1 x 3 : posée sur la dernière ligne, elle sortirait du sac.
	assert_false(_sac.fits(Item.new(_epee), Vector2i(0, 4)))
	assert_false(_sac.fits(Item.new(_epee), Vector2i(-1, 0)))


func test_retirer_libere_les_cases() -> void:
	_sac.place(Item.new(_plastron), Vector2i(3, 1))
	# Pris par n'importe laquelle de ses cases, pas seulement son coin.
	var pris := _sac.take_at(Vector2i(4, 3))
	assert_not_null(pris, "l'objet sort du sac")
	assert_eq(_sac.used_cells(), 0, "toutes ses cases sont rendues")
	assert_true(_sac.fits(Item.new(_plastron), Vector2i(3, 1)), "la place est reprenable")


func test_add_cherche_une_place_libre() -> void:
	var poses := 0
	while _sac.add(Item.new(_plastron)):
		poses += 1
	# 10 x 5 cases, un plastron en occupe 6 : cinq tiennent, le sixième non.
	assert_eq(poses, 5, "le sac se remplit puis refuse")
	assert_false(_sac.add(Item.new(_plastron)), "sac plein")


## Le sac plein ne doit jamais avaler un objet : il reste au sol.
func test_sac_plein_refuse_au_lieu_d_avaler() -> void:
	while _sac.add(Item.new(_plastron)):
		pass
	var avant := _sac.placed.size()
	assert_false(_sac.add(Item.new(_epee)))
	assert_eq(_sac.placed.size(), avant, "rien n'a disparu")
