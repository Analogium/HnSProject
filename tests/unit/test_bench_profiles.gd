extends GutTest

## Les profils du banc d'équilibrage (jalon 13, étape 1). Reconstruits par les règles à
## chaque lancement, ils doivent redonner le même personnage, porter ce qui tombe à leur
## niveau et avoir placé tous leurs points — sinon le banc mesure un personnage que
## personne ne jouerait.


## Sans l'identifiant ni les dates, que `Character.create_new()` tire à chaque appel.
func _footprint(p: Character) -> String:
	var d := p.to_dict()
	for field in ["id", "created_on", "played_on"]:
		d.erase(field)
	return JSON.stringify(d)


func test_a_profile_is_reproducible() -> void:
	for build in BenchProfiles.builds():
		assert_eq(
			_footprint(BenchProfiles.character(build, BenchProfiles.Profile.EQUIPPED, 40)),
			_footprint(BenchProfiles.character(build, BenchProfiles.Profile.EQUIPPED, 40)),
			build.name
		)


## Le jumeau négatif : une graine qui ignorerait la zone passerait le test d'au-dessus.
func test_two_zones_do_not_give_the_same_items() -> void:
	var build := BenchProfiles.builds()[0]
	assert_ne(
		JSON.stringify(BenchProfiles.character(build, BenchProfiles.Profile.EQUIPPED, 40).to_dict()["equipment"]),
		JSON.stringify(BenchProfiles.character(build, BenchProfiles.Profile.EQUIPPED, 60).to_dict()["equipment"])
	)


func test_items_are_those_that_drop_at_their_level() -> void:
	for build in BenchProfiles.builds():
		for profile in BenchProfiles.Profile.values():
			var p := BenchProfiles.character(build, profile, 60)
			var level := BenchProfiles.item_level_for(profile, 60)
			var case_name := "%s %s" % [build.name, BenchProfiles.PROFILE_NAMES[profile]]
			if level == 0:
				assert_true(p.equipment.is_empty(), case_name)
				continue
			assert_eq(p.equipment.size(), EquipmentSlots.count(), "%s : tout est porté" % case_name)
			for slot in p.equipment:
				var item: Item = p.equipment[slot]
				assert_true(EquipmentSlots.accepts(slot, item), "%s : %s" % [case_name, slot])
				assert_eq(item.item_level, level, case_name)
				assert_has(ItemCatalog.available(level), item.base, "%s : %s tombe à %d" % [case_name, item.base.id, level])
				assert_false(item.base.tags.has(build.excluded_one), "%s : %s" % [case_name, item.base.id])


func test_all_points_are_placed() -> void:
	for build in BenchProfiles.builds():
		for zone in BenchProfiles.ZONES:
			for profile in BenchProfiles.Profile.values():
				var p := BenchProfiles.character(build, profile, zone)
				var case_name := "%s %s zone %d" % [build.name, BenchProfiles.PROFILE_NAMES[profile], zone]
				assert_eq(
					p.passives.size(), mini(PassiveTree.points_gained(p.level), build.path.size()),
					"%s : arbre" % case_name
				)
				assert_eq(p.rack.at(0).manual.remaining_points(), 0, "%s : manuel" % case_name)
				assert_false(p.bar.id_of(0).is_empty(), "%s : de quoi lancer" % case_name)


## Un nœud du chemin qui ne se prend pas serait sauté sans bruit.
func test_each_path_is_taken_in_full() -> void:
	for build in BenchProfiles.builds():
		assert_eq(PassiveTree.shared().legal(build.path, 1000).size(), build.path.size(), build.name)
		var taken := PackedStringArray()
		for id in build.path:
			assert_true(PassiveTree.shared().can_take(taken, id, 1000), "%s : « %s »" % [build.name, id])
			taken.append(id)


func test_the_expected_level_grows_with_the_zone() -> void:
	assert_eq(BenchProfiles.expected_level(1), Vector2i(1, 0), "rien de vidé avant la zone 1")
	var before := 1
	for zone in BenchProfiles.ZONES.slice(1):
		var level := BenchProfiles.expected_level(zone).x
		assert_gt(level, before, "zone %d" % zone)
		before = level
