extends GutTest

## Le coffre de la ville et la salle qui l'abrite : le modèle et la carte, sans
## moteur. Le disque est dans `test_save_disk.gd`, les gestes dans `test_town.gd`.


func test_five_tabs_of_twelve_by_twelve() -> void:
	var stash := Stash.new()
	assert_eq(stash.tabs.size(), Stash.TABS)
	for tab in stash.tabs:
		assert_eq(Vector2i(tab.cols, tab.rows), Vector2i(Stash.COLS, Stash.ROWS))


## Par le texte JSON, comme sur le disque : le JSON n'a qu'un type de nombre, et un
## aller-retour en mémoire ne le verrait pas.
func test_a_stash_comes_back_from_its_json() -> void:
	var stash := Stash.new()
	var sword := Item.new(ItemCatalog.by_id("sword"), [
		StatMod.ranged("damage_physical", 3.0, 7.0, Keywords.ATTACK),
	] as Array[StatMod])
	var coins := Item.new(ItemCatalog.by_id("coin_gold"))
	coins.count = 7
	assert_true(stash.tabs[1].place(sword, Vector2i(3, 4)))
	assert_true(stash.tabs[4].place(coins, Vector2i(11, 11)))

	var reread := Stash.from_dict(JSON.parse_string(JSON.stringify(stash.to_dict())))
	assert_not_null(reread)
	assert_eq(reread.tabs[1].placed.size(), 1, "l'épée dans son onglet")
	assert_eq(reread.tabs[1].placed[0].cell, Vector2i(3, 4), "à sa case")
	assert_eq(reread.tabs[1].placed[0].data.explicits.size(), 1, "avec son affixe")
	assert_eq(reread.tabs[4].placed[0].data.count, 7, "la pile entière")
	assert_eq(reread.tabs[0].placed.size(), 0, "les autres onglets restent vides")


func test_an_unknown_version_is_refused() -> void:
	assert_null(Stash.from_dict({"version": Stash.VERSION + 1, "tabs": []}))
	assert_null(Stash.from_dict({"tabs": []}), "sans version")


func test_a_missing_tab_stays_empty() -> void:
	var stash := Stash.from_dict({"version": Stash.VERSION, "tabs": [[]]})
	assert_eq(stash.tabs.size(), Stash.TABS)


## La ville est une salle close : la bordure de deux cases, du sol partout dedans.
func test_the_town_is_a_closed_room() -> void:
	var town := MapGenerator.town(24, 16)
	assert_eq(town.floor_cells.size(), 20 * 12)
	for x in 24:
		assert_false(town.is_walkable(Vector2i(x, 1)), "bord haut, colonne %d" % x)
		assert_false(town.is_walkable(Vector2i(x, 14)), "bord bas, colonne %d" % x)
	assert_true(town.is_walkable(town.get_spawn_cell()))


## Le fichier de référence, écrit à la main : il attrape ce qu'un aller-retour ne voit
## pas, le jour où un nom de champ change des deux côtés à la fois.
func test_the_reference_file_still_reads() -> void:
	var content: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/stash_v1.json"))
	var stash := Stash.from_dict(content)
	assert_not_null(stash)
	var ring: Item = stash.tabs[0].placed[0].data
	assert_eq(ring.base.id, "ring")
	assert_eq(stash.tabs[0].placed[0].cell, Vector2i(2, 3))
	assert_true(ring.rare)
	assert_eq(ring.explicits.size(), 2)
	assert_eq(stash.tabs[4].placed[0].data.count, 9, "la pile de pièces")
