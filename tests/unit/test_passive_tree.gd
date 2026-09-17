extends GutTest

## L'arbre de passifs : les règles sur un petit graphe écrit ici, puis le contenu du
## jeu parcouru depuis `resources/passive_tree.tres`.


# --------------------------------------------------------------------------
# Un petit arbre
# --------------------------------------------------------------------------

func _line(stat: String, value: float, percentage := false, scope := "", more := false) -> TalentLine:
	var l := TalentLine.new()
	l.stat = stat
	l.value_per_point = value
	l.percentage = percentage
	l.scope = scope
	l.more = more
	return l


func _node(id: String, links: Array, kind := PassiveNode.Kind.SMALL, lines: Array[TalentLine] = []) -> PassiveNode:
	var n := PassiveNode.new()
	n.id = id
	n.kind = kind
	n.links = PackedStringArray(links)
	n.lines = lines
	return n


## start — a — b — e, et une boucle start — d — b. `c` pend sous `a`, lié depuis `a`.
func _tree() -> PassiveTree:
	var t := PassiveTree.new()
	t.nodes = [
		_node("start", [], PassiveNode.Kind.START),
		_node("a", ["start", "c"], PassiveNode.Kind.SMALL, [_line("strength", 10.0)] as Array[TalentLine]),
		_node("b", ["a"]),
		_node("c", []),
		_node("d", ["start", "b"]),
		_node("e", ["b"], PassiveNode.Kind.SMALL, [_line("armor", 10.0, true)] as Array[TalentLine]),
	] as Array[PassiveNode]
	return t


func _taken(ids: Array) -> PackedStringArray:
	return PackedStringArray(ids)


func test_points_come_from_the_level() -> void:
	assert_eq(PassiveTree.points_gained(1), 0, "aucun point au niveau 1")
	assert_eq(PassiveTree.points_gained(8), 7)
	assert_eq(PassiveTree.remaining_points(_taken(["a", "b"]), 8), 5)


func test_links_are_symmetric() -> void:
	var t := _tree()
	assert_true("c" in t.neighbors("a"), "écrit depuis a")
	assert_true("a" in t.neighbors("c"), "rendu depuis c")
	assert_eq(t.neighbors("b").size(), 3, "a, d et e, chacun une fois")


func test_only_a_neighbor_is_taken() -> void:
	var t := _tree()
	assert_true(t.can_take(_taken([]), "a", 5), "voisin du départ")
	assert_false(t.can_take(_taken([]), "b", 5), "rien de pris autour")
	assert_true(t.can_take(_taken(["a"]), "b", 5), "voisin d'un nœud pris")
	assert_false(t.can_take(_taken([]), "zzz", 5), "inconnu")


func test_never_the_start_nor_twice() -> void:
	var t := _tree()
	assert_false(t.can_take(_taken([]), "start", 5))
	assert_false(t.can_take(_taken(["a"]), "a", 5))


func test_not_without_a_point() -> void:
	var t := _tree()
	assert_false(t.can_take(_taken([]), "a", 1), "niveau 1 : aucun point")
	assert_false(t.can_take(_taken(["a", "b"]), "e", 3), "deux points, deux pris")
	assert_true(t.can_take(_taken(["a", "b"]), "e", 4))


func test_a_leaf_is_released() -> void:
	var t := _tree()
	assert_true(t.can_release(_taken(["a", "b", "e"]), "e"))
	assert_false(t.can_release(_taken(["a"]), "b"), "pas pris")


func test_a_node_that_cuts_is_refused() -> void:
	var t := _tree()
	assert_false(t.can_release(_taken(["a", "b", "e"]), "b"), "e serait coupé")
	assert_false(t.can_release(_taken(["a", "b"]), "a"), "b serait coupé")


func test_a_node_of_a_loop_is_released() -> void:
	var t := _tree()
	assert_true(t.can_release(_taken(["a", "b", "d"]), "a"), "b reste relié par d")


func test_mods_come_from_taken_nodes_only() -> void:
	var t := _tree()
	var mods := t.mods(_taken(["a", "b"]))
	assert_eq(mods.size(), 1, "b ne porte rien, e n'est pas pris")
	assert_eq(mods[0].stat, "strength")
	assert_eq(mods[0].value, 10.0)


func test_what_a_save_may_carry() -> void:
	var t := _tree()
	assert_eq(t.legal(_taken(["a", "zzz", "b"]), 10), _taken(["a", "b"]), "l'inconnu est écarté")
	assert_eq(t.legal(_taken(["b", "e"]), 10), _taken([]), "coupés du départ, avec leurs suivants")
	assert_eq(t.legal(_taken(["a", "b", "e"]), 3).size(), 2, "pas plus que les points")


# --------------------------------------------------------------------------
# Le contenu
# --------------------------------------------------------------------------

func _game_tree() -> PassiveTree:
	return PassiveTree.shared()


func test_the_content_ids_are_unique_and_one_start() -> void:
	var seen := {}
	var starts := 0
	for n in _game_tree().nodes:
		assert_false(n.id.is_empty(), "un nœud sans identifiant")
		assert_false(seen.has(n.id), "« %s » deux fois" % n.id)
		seen[n.id] = true
		if n.kind == PassiveNode.Kind.START:
			starts += 1
	assert_eq(starts, 1, "un seul départ")


func test_each_link_targets_an_existing_node() -> void:
	var t := _game_tree()
	for n in t.nodes:
		for other in n.links:
			assert_not_null(t.node(other), "« %s » est lié à « %s », qui n'existe pas" % [n.id, other])


func test_each_node_is_reachable_from_the_start() -> void:
	var t := _game_tree()
	var everything := PackedStringArray()
	for n in t.nodes:
		if n.kind != PassiveNode.Kind.START:
			everything.append(n.id)
	var reached := t.connected(everything)
	for id in everything:
		assert_true(id in reached, "« %s » ne se relie pas au départ" % id)


func test_two_nodes_never_share_a_place() -> void:
	var places := {}
	for n in _game_tree().nodes:
		assert_false(places.has(n.position), "« %s » sur « %s »" % [n.id, places.get(n.position)])
		places[n.position] = n.id


## Deux liens qui se croisent donnent un carrefour qui n'existe pas : l'œil suit la
## mauvaise branche et croit pouvoir passer. Seuls comptent les liens sans nœud commun
## — deux liens d'un même nœud s'y rejoignent, c'est leur travail.
func test_no_two_links_cross() -> void:
	var segments := _game_segments()
	for i in segments.size():
		for j in range(i + 1, segments.size()):
			var a: Array = segments[i]
			var b: Array = segments[j]
			if a[0] == b[0] or a[0] == b[1] or a[1] == b[0] or a[1] == b[1]:
				continue
			assert_false(
				Geometry2D.segment_intersects_segment(a[2], a[3], b[2], b[3]) != null,
				"« %s—%s » croise « %s—%s »" % [a[0], a[1], b[0], b[1]]
			)


## Chaque lien une fois : identifiants et positions, prêts à se croiser.
func _game_segments() -> Array:
	var tree := _game_tree()
	var places := {}
	for n in tree.nodes:
		places[n.id] = Vector2(n.position)
	var seen := {}
	var out := []
	for n in tree.nodes:
		for other in n.links:
			var key := "%s|%s" % ([n.id, other] if n.id < other else [other, n.id])
			if seen.has(key) or not places.has(other):
				continue
			seen[key] = true
			out.append([n.id, other, places[n.id], places[other]])
	return out


## Les mêmes exigences qu'une ligne de passif de manuel (`test_talents.gd`).
func test_each_line_targets_the_sheet_or_a_cast_number() -> void:
	var sheet := CharacterStats.new()
	for n in _game_tree().nodes:
		if n.kind != PassiveNode.Kind.START:
			assert_gt(n.lines.size(), 0, "« %s » ne donne rien" % n.id)
		for l in n.lines:
			if l.scope.is_empty():
				assert_true(
					sheet.get(l.stat) != null and StatMod.LABELS.has(l.stat),
					"« %s » vise « %s », qui n'est pas sur la fiche" % [n.id, l.stat]
				)
				continue
			assert_true(Keywords.exists(l.scope), "« %s » : mot-clé « %s »" % [n.id, l.scope])
			assert_true(SkillStats.modifiable(l.stat), "« %s » vise « %s »" % [n.id, l.stat])


func test_each_notable_and_keystone_is_named() -> void:
	for n in _game_tree().nodes:
		if n.kind in [PassiveNode.Kind.NOTABLE, PassiveNode.Kind.KEYSTONE]:
			assert_false(n.name.is_empty(), "« %s » n'a pas de nom" % n.id)


## La seule assertion qui dit « il faut choisir » : un personnage de zone 120 ne prend
## pas tout l'arbre.
func test_the_tree_offers_more_nodes_than_points() -> void:
	var points := PassiveTree.points_gained(BenchProfiles.expected_level(120).x)
	assert_gt(_game_tree().nodes.size() - 1, points)


## Un nœud sans icône se dessine en rond gris : on ne voit plus ce qu'il fait.
func test_each_node_has_its_icon() -> void:
	for n in _game_tree().nodes:
		if n.kind != PassiveNode.Kind.START:
			assert_not_null(PassiveIcon.texture(n), "« %s » : « %s » n'a pas d'icône" % [n.id, n.lines[0].stat])
