extends GutTest

## Le compteur de DPS : la fenêtre glissante et le tri. Le branchement sur les coups
## est dans `Hurtbox.take_damage()` et `Enemy.suffer_states()`.

var _before: Dictionary
var _meter: DpsMeter


func before_each() -> void:
	_before = Settings.to_dict()
	# Par la lecture : l'affectation écrirait le fichier de réglages.
	Settings.from_dict({"dps_meter": true})
	_meter = DpsMeter.new()
	add_child_autofree(_meter)


func after_each() -> void:
	Settings.from_dict(_before)


func test_it_sums_the_window_and_sorts_high_to_low() -> void:
	Game.damage_dealt.emit("fireball", Game.HIT, 100.0)
	Game.damage_dealt.emit("heavy_strike", Game.HIT, 300.0)
	Game.damage_dealt.emit("fireball", Game.HIT, 100.0)
	_meter._process(DpsMeter.SLICE)
	assert_almost_eq(_meter._total, 500.0 / DpsMeter.WINDOW, 0.001)
	assert_eq(_meter._sources, ["heavy_strike/-1", "fireball/-1"])
	assert_almost_eq(_meter._dps["fireball/-1"], 200.0 / DpsMeter.WINDOW, 0.001)


func test_a_hit_leaves_the_window_after_five_seconds() -> void:
	Game.damage_dealt.emit("heavy_strike", Game.HIT, 300.0)
	_meter._process(DpsMeter.SLICE)
	_meter._process(DpsMeter.WINDOW - DpsMeter.SLICE)
	assert_gt(_meter._total, 0.0, "encore dans les cinq secondes")
	_meter._process(DpsMeter.SLICE)
	assert_eq(_meter._total, 0.0)
	assert_true(_meter._sources.is_empty())


func test_hidden_it_counts_nothing() -> void:
	Settings.from_dict({"dps_meter": false})
	_meter._apply_settings()
	Game.damage_dealt.emit("heavy_strike", Game.HIT, 300.0)
	_meter._process(DpsMeter.SLICE)
	assert_eq(_meter._total, 0.0)


func test_it_stays_above_the_gauges() -> void:
	_meter._fit(Vector2(9999.0, 9999.0))
	var screen := _meter.get_viewport_rect().size
	assert_lte(_meter.position.x + _meter.size.x, screen.x)
	assert_lte(_meter.position.y + _meter.size.y, Hud.gauges_top(screen.y))


func test_the_position_survives_a_reread() -> void:
	Settings.from_dict({"dps_meter_position": [42, 17]})
	assert_eq(Settings.dps_meter_position, Vector2(42, 17))
	Settings.from_dict({"dps_meter_position": ["abîmé", 1]})
	assert_eq(Settings.dps_meter_position, Vector2(42, 17), "un fichier abîmé garde la place")


## Le coup d'un lancer porte l'identifiant de sa compétence : c'est lui qui retrouve
## l'icône et le nom.
func test_a_cast_carries_its_skill_id() -> void:
	var skill := SkillCatalog.by_id("fireball")
	assert_eq(skill.resolve(1, CharacterStats.new()).skill_id, "fireball")


## Ce qui brûle sur un ennemi s'annonce au nom de la compétence qui l'a posé, et
## devient sa propre ligne à côté du coup.
func test_a_burn_is_its_own_line_under_its_skill() -> void:
	var enemy := StatusEffects.new()
	enemy.reports_dealt = true
	enemy.put(StatusEffects.Kind.IGNITE, 40.0, null, "fireball")
	Game.damage_dealt.emit("fireball", Game.HIT, 100.0)
	for i in 10:
		enemy.advance(0.1)
	_meter._process(DpsMeter.SLICE)
	var ignite := "fireball/%d" % StatusEffects.Kind.IGNITE
	assert_eq(_meter._sources, ["fireball/-1", ignite])
	assert_almost_eq(
		_meter._dps[ignite], 40.0 * StatusEffects.IGNITE_PER_SECOND / DpsMeter.WINDOW, 0.001
	)
	assert_eq(_meter._named[ignite].label(), "Embrasement")


func test_a_death_reports_the_last_packet() -> void:
	var enemy := StatusEffects.new()
	enemy.reports_dealt = true
	enemy.put(StatusEffects.Kind.IGNITE, 40.0, null, "fireball")
	enemy.advance(0.1)
	_meter._process(DpsMeter.SLICE)
	assert_eq(_meter._total, 0.0, "le paquet n'est pas encore parti")
	enemy.report()
	_meter._process(DpsMeter.SLICE)
	assert_gt(_meter._total, 0.0)


## Le joueur ne s'inflige rien : ses propres états se taisent.
func test_the_player_burning_reports_nothing() -> void:
	var player := StatusEffects.new()
	player.put(StatusEffects.Kind.IGNITE, 40.0, null, "fireball")
	player.advance(1.0)
	_meter._process(DpsMeter.SLICE)
	assert_eq(_meter._total, 0.0)
