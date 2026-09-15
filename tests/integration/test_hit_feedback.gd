extends GutTest

## Le nombre qui s'envole : le total de toutes les parts du coup, après réduction,
## en blanc quelle que soit leur nature. La gerbe d'éclats, elle, dit encore la part
## la plus forte.

var _fx: HitFeedback
## Les réglages d'avant le test : l'autoload survit d'un fichier à l'autre, et une
## case laissée décochée ferait disparaître les chiffres des tests suivants.
var _settings: Dictionary


func before_each() -> void:
	_settings = Settings.to_dict()
	_fx = HitFeedback.new()
	add_child_autofree(_fx)
	await wait_process_frames(1)


func after_each() -> void:
	Settings.from_dict(_settings)


func _hit(cold: float, lightning: float, crit := false) -> DamageInfo:
	var parts := DamageType.empty_parts()
	parts[DamageType.Kind.COLD] = cold
	parts[DamageType.Kind.LIGHTNING] = lightning
	return DamageInfo.as_parts(parts, Vector2(-10.0, 0.0), 0.0, crit)


## Par la vraie `Hurtbox` : le nombre est ce que la vie perd, toutes les parts
## réduites puis additionnées — ni la part la plus forte, ni le coup d'avant les
## résistances.
func test_the_number_is_the_total_after_reduction() -> void:
	var st := CharacterStats.new()
	st.res_cold = 50.0
	var hb := Hurtbox.new()
	hb.stats = st
	add_child_autofree(hb)
	hb.take_damage(_hit(20.0, 6.0))
	assert_eq(_fx._numbers.size(), 1, "un coup, un nombre")
	assert_eq(_fx._numbers[0].text, "16", "10 de froid après résistance, plus 6 de foudre")


func test_the_number_is_white_whatever_the_nature() -> void:
	var hits := [
		_hit(9.0, 3.0),
		_hit(0.0, 5.0),
		DamageInfo.new(4.0, Vector2.ZERO),
		DamageInfo.new(4.0, Vector2.ZERO, 0.0, false, DamageType.Kind.FIRE),
	]
	for hit: DamageInfo in hits:
		_fx.hit(Vector2.ZERO, hit, false)
		assert_eq(
			_fx._numbers.back().tint, HitFeedback.NUMBER,
			"un coup surtout %s" % DamageType.NAMES[hit.type]
		)


## Ni l'or du critique ni le rouge du joueur qui encaisse ne sont des natures.
func test_crit_and_player_keep_their_color() -> void:
	assert_eq(HitFeedback.number_color(_hit(9.0, 3.0, true), false), HitFeedback.CRIT)
	assert_eq(HitFeedback.number_color(_hit(9.0, 3.0), true), HitFeedback.PLAYER)


## La gerbe d'éclats dit encore contre quoi on frappe : la couleur de la part la
## plus forte.
func test_the_spray_takes_the_color_of_the_strongest_part() -> void:
	_fx.hit(Vector2.ZERO, _hit(9.0, 3.0), false)
	assert_gt(_fx._p.size(), 0, "des éclats sont partis")
	var cold: Color = DamageType.COLORS[DamageType.Kind.COLD]
	assert_almost_eq(_fx._p[7], cold.r, 0.001)
	assert_almost_eq(_fx._p[8], cold.g, 0.001)
	assert_almost_eq(_fx._p[9], cold.b, 0.001)


# --------------------------------------------------------------------------
# Les deux cases
# --------------------------------------------------------------------------

## Chaque case ne coupe que son côté, et seulement le chiffre : la gerbe d'éclats
## reste, c'est elle qui dit qu'un coup a porté.
func test_each_slot_only_cuts_its_side() -> void:
	Settings.damage_taken_visible = false
	_fx.hit(Vector2.ZERO, _hit(5.0, 0.0), true)
	assert_eq(_fx._numbers.size(), 0, "rien au-dessus du joueur")
	assert_gt(_fx._p.size(), 0, "mais la gerbe part")
	_fx.hit(Vector2.ZERO, _hit(5.0, 0.0), false)
	assert_eq(_fx._numbers.size(), 1, "les ennemis gardent leur chiffre")

	Settings.damage_taken_visible = true
	Settings.damage_dealt_visible = false
	_fx.hit(Vector2.ZERO, _hit(5.0, 0.0), false)
	assert_eq(_fx._numbers.size(), 1, "plus rien au-dessus des ennemis")
	_fx.hit(Vector2.ZERO, _hit(5.0, 0.0), true)
	assert_eq(_fx._numbers.size(), 2, "le joueur a retrouvé le sien")


## « Esquive » et « raté » tiennent la place d'un chiffre : ils suivent sa case.
func test_evasion_follows_its_side_slot() -> void:
	Settings.damage_dealt_visible = false
	_fx.miss(Vector2.ZERO, false)
	assert_eq(_fx._numbers.size(), 0)
	_fx.miss(Vector2.ZERO, true)
	assert_eq(_fx._numbers.size(), 1)


## La brûlure d'une aura ne passe pas par la `Hurtbox` : elle s'affiche par paquets
## d'une demi-seconde, en rouge, et suit la case des dégâts subis.
func test_burn_is_displayed_in_packs() -> void:
	var player: Player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(player)
	await wait_physics_frames(1)
	player.stats.max_health = 100.0
	player._set_health(100.0)
	player.stats.res_fire = 0.0
	var fire := DamageType.empty_parts()
	fire[DamageType.Kind.FIRE] = 1.0

	player.burn(0.05, fire, 0.3)
	assert_eq(_fx._numbers.size(), 0, "pas de chiffre par image")
	player.burn(0.05, fire, 0.3)
	assert_eq(_fx._numbers.size(), 1, "un chiffre par demi-seconde")
	assert_eq(_fx._numbers[0].text, "3", "ce qu'ont pris les deux images")
	assert_eq(_fx._numbers[0].tint, HitFeedback.PLAYER)

	Settings.damage_taken_visible = false
	player.burn(0.05, fire, 0.6)
	assert_eq(_fx._numbers.size(), 1, "la case des dégâts subis la coupe aussi")
