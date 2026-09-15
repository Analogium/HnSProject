extends GutTest

## Le sac. Un RefCounted sans nœud ni dessin — la seule partie du jeu qui se
## teste exactement comme un module web.

var _bag: Inventory
var _sword: ItemBase
var _breastplate: ItemBase


func before_each() -> void:
	_bag = Inventory.new(10, 5)
	_sword = load("res://resources/items/sword.tres")
	_breastplate = load("res://resources/items/breastplate.tres")


func test_grid_empty_at_start() -> void:
	assert_eq(_bag.cell_count(), 50)
	assert_eq(_bag.used_cells(), 0)
	assert_eq(_bag.index_at(Vector2i(0, 0)), Inventory.EMPTY)


func test_an_item_occupies_its_rectangle() -> void:
	assert_true(_bag.place(Item.new(_breastplate), Vector2i(0, 0)), "posé")
	# 2 colonnes sur 3 lignes
	assert_eq(_bag.used_cells(), 6)
	assert_ne(_bag.index_at(Vector2i(1, 2)), Inventory.EMPTY, "coin bas-droit occupé")
	assert_eq(_bag.index_at(Vector2i(2, 0)), Inventory.EMPTY, "la colonne suivante est libre")


func test_two_items_do_not_overlap() -> void:
	assert_true(_bag.place(Item.new(_breastplate), Vector2i(0, 0)))
	assert_false(_bag.fits(Item.new(_sword), Vector2i(1, 1)), "recouvrement refusé")
	assert_false(_bag.place(Item.new(_sword), Vector2i(1, 1)))
	assert_eq(_bag.used_cells(), 6, "rien n'a été posé")


func test_an_item_does_not_overflow_the_grid() -> void:
	# L'épée fait 1 x 3 : posée sur la dernière ligne, elle sortirait du sac.
	assert_false(_bag.fits(Item.new(_sword), Vector2i(0, 4)))
	assert_false(_bag.fits(Item.new(_sword), Vector2i(-1, 0)))


func test_remove_frees_the_cells() -> void:
	_bag.place(Item.new(_breastplate), Vector2i(3, 1))
	# Pris par n'importe laquelle de ses cases, pas seulement son coin.
	var taken := _bag.take_at(Vector2i(4, 3))
	assert_not_null(taken, "l'objet sort du sac")
	assert_eq(_bag.used_cells(), 0, "toutes ses cases sont rendues")
	assert_true(_bag.fits(Item.new(_breastplate), Vector2i(3, 1)), "la place est reprenable")


func test_add_looks_for_a_free_cell() -> void:
	var poses := 0
	while _bag.add(Item.new(_breastplate)):
		poses += 1
	# 10 x 5 cases, un plastron en occupe 6 : cinq tiennent, le sixième non.
	assert_eq(poses, 5, "le sac se remplit puis refuse")
	assert_false(_bag.add(Item.new(_breastplate)), "sac plein")


## Le sac plein ne doit jamais avaler un objet : il reste au sol.
func test_full_bag_refuses_instead_of_swallowing() -> void:
	while _bag.add(Item.new(_breastplate)):
		pass
	var before := _bag.placed.size()
	assert_false(_bag.add(Item.new(_sword)))
	assert_eq(_bag.placed.size(), before, "rien n'a disparu")
