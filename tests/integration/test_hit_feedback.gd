extends GutTest

## Le nombre qui s'envole : le total de toutes les parts du coup, après réduction,
## en blanc quelle que soit leur nature. La gerbe d'éclats, elle, dit encore la part
## la plus forte.

var _fx: HitFeedback


func before_each() -> void:
	_fx = HitFeedback.new()
	add_child_autofree(_fx)
	await wait_process_frames(1)


func _coup(froid: float, foudre: float, critique := false) -> DamageInfo:
	var parts := DamageType.parts_vides()
	parts[DamageType.Kind.COLD] = froid
	parts[DamageType.Kind.LIGHTNING] = foudre
	return DamageInfo.en_parts(parts, Vector2(-10.0, 0.0), 0.0, critique)


## Par la vraie `Hurtbox` : le nombre est ce que la vie perd, toutes les parts
## réduites puis additionnées — ni la part la plus forte, ni le coup d'avant les
## résistances.
func test_le_nombre_est_le_total_apres_reduction() -> void:
	var st := CharacterStats.new()
	st.res_cold = 50.0
	var hb := Hurtbox.new()
	hb.stats = st
	add_child_autofree(hb)
	hb.take_damage(_coup(20.0, 6.0))
	assert_eq(_fx._numbers.size(), 1, "un coup, un nombre")
	assert_eq(_fx._numbers[0].text, "16", "10 de froid après résistance, plus 6 de foudre")


func test_le_nombre_est_blanc_quelle_que_soit_la_nature() -> void:
	var coups := [
		_coup(9.0, 3.0),
		_coup(0.0, 5.0),
		DamageInfo.new(4.0, Vector2.ZERO),
		DamageInfo.new(4.0, Vector2.ZERO, 0.0, false, DamageType.Kind.FIRE),
	]
	for coup: DamageInfo in coups:
		_fx.hit(Vector2.ZERO, coup, false)
		assert_eq(
			_fx._numbers.back().tint, HitFeedback.NOMBRE,
			"un coup surtout %s" % DamageType.NAMES[coup.type]
		)


## Ni l'or du critique ni le rouge du joueur qui encaisse ne sont des natures.
func test_le_critique_et_le_joueur_gardent_leur_couleur() -> void:
	assert_eq(HitFeedback.couleur_du_nombre(_coup(9.0, 3.0, true), false), HitFeedback.CRIT)
	assert_eq(HitFeedback.couleur_du_nombre(_coup(9.0, 3.0), true), HitFeedback.PLAYER)


## La gerbe d'éclats dit encore contre quoi on frappe : la couleur de la part la
## plus forte.
func test_la_gerbe_prend_la_couleur_de_la_part_la_plus_forte() -> void:
	_fx.hit(Vector2.ZERO, _coup(9.0, 3.0), false)
	assert_gt(_fx._p.size(), 0, "des éclats sont partis")
	var froid: Color = DamageType.COLORS[DamageType.Kind.COLD]
	assert_almost_eq(_fx._p[7], froid.r, 0.001)
	assert_almost_eq(_fx._p[8], froid.g, 0.001)
	assert_almost_eq(_fx._p[9], froid.b, 0.001)
