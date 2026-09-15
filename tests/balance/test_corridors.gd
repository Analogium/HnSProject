extends GutTest

## Les couloirs du jalon 13 (§4), sur la mesure du calcul. **Ils ne se corrigent pas en
## changeant leurs chiffres** : un couloir qui casse après un réglage est l'alerte que le
## banc existe pour donner. Hors de la suite par défaut : `tests/run.sh equilibrage`.

var _calculation: BenchCalculation


func before_each() -> void:
	var player: Player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(player)
	_calculation = BenchCalculation.new(player)


func after_each() -> void:
	_calculation = null


func _measure(build: BenchProfiles.Build, profile: int, built_for: int, played: int) -> BenchCalculation.Measurement:
	return _calculation.measure(BenchProfiles.character(build, profile, built_for), played)


func _read(build: BenchProfiles.Build, profile: int, m: BenchCalculation.Measurement) -> String:
	return "%s %s en zone %d : %s (%.2f coups, survie %.1f s)" % [
		build.name, BenchProfiles.PROFILE_NAMES[profile], m.zone,
		BenchCalculation.VERDICT_NAMES[m.verdict], m.grunt_hits, m.survival,
	]


func test_a_beginner_is_comfortable_in_zone_1() -> void:
	for build in BenchProfiles.builds():
		var m := _measure(build, BenchProfiles.Profile.BEGINNER, 1, 1)
		assert_eq(m.verdict, BenchCalculation.Verdict.COMFORTABLE, _read(build, BenchProfiles.Profile.BEGINNER, m))


func test_an_equipped_character_is_neither_trivial_nor_walled_in_its_zone() -> void:
	var profile := BenchProfiles.Profile.EQUIPPED
	for build in BenchProfiles.builds():
		for zone in BenchProfiles.ZONES:
			var m := _measure(build, profile, zone, zone)
			assert_true(
				m.verdict in [BenchCalculation.Verdict.COMFORTABLE, BenchCalculation.Verdict.TIGHT],
				_read(build, profile, m)
			)


## Hors zone 1, où le Nu et le Débutant sont le même personnage.
func test_a_naked_character_is_tight_in_its_zone() -> void:
	var profile := BenchProfiles.Profile.BARE
	for build in BenchProfiles.builds():
		for zone in BenchProfiles.ZONES.slice(1):
			var m := _measure(build, profile, zone, zone)
			assert_eq(m.verdict, BenchCalculation.Verdict.TIGHT, _read(build, profile, m))


func test_an_over_equipped_character_meets_no_wall_in_its_zone() -> void:
	var profile := BenchProfiles.Profile.OVER_EQUIPPED
	for build in BenchProfiles.builds():
		for zone in BenchProfiles.ZONES:
			var m := _measure(build, profile, zone, zone)
			assert_ne(m.verdict, BenchCalculation.Verdict.WALL, _read(build, profile, m))


func test_twenty_levels_higher_nothing_is_trivial() -> void:
	for build in BenchProfiles.builds():
		for profile in BenchProfiles.Profile.values():
			for zone in BenchProfiles.ZONES:
				if zone + 20 > Game.MAX_LEVEL:
					continue
				var m := _measure(build, profile, zone, zone + 20)
				assert_ne(m.verdict, BenchCalculation.Verdict.TRIVIAL, _read(build, profile, m))
