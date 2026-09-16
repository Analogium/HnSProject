extends GutTest

## Les formes du jalon 11, lancées pour de vrai par `Player.cast_slot()` sur des
## hurtbox posées à la main : qui elles touchent, combien de fois, et quand elles
## s'arrêtent.
##
## Des hurtbox nues et non des ennemis : un ennemi avance vers le joueur, et la
## cible qu'on voulait hors du nuage y entrerait pendant l'attente.

var _p: Player
var _effects: Node2D
## Les montants reçus par chaque cible. Un membre et non une locale : une lambda
## GDScript capture par valeur.
var _received_all := {}
var _chill_duration: float
var _chill_period: float


func before_each() -> void:
	_chill_duration = Game.hit_stop_duration
	_chill_period = Game.hit_stop_period
	# Sans gel : il ralentit le temps de jeu, et les attentes ci-dessous sont en
	# secondes de jeu.
	Game.hit_stop_duration = 0.0
	_received_all.clear()
	_p = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_p)
	_effects = Node2D.new()
	add_child_autofree(_effects)
	_p.projectile_parent = _effects
	# La visée à la manette : la souris d'un lancement sans fenêtre est n'importe où.
	_p._aim_with_mouse = false
	_p.facing = Vector2.RIGHT
	await wait_physics_frames(1)


func after_each() -> void:
	Game.hit_stop_duration = _chill_duration
	Game.hit_stop_period = _chill_period
	Engine.time_scale = 1.0
	Input.action_release("skill_3")


## Le livre au plafond, ces points placés par le seul chemin, la compétence sur la
## troisième case, et de quoi la lancer autant qu'on veut.
func _learn(base_id: String, points: Array) -> void:
	var book := Item.new(ItemCatalog.by_id(base_id))
	book.manual.gain_experience(999999)
	_p.study(book, 0)
	for id: String in points:
		assert_true(_p.invest(0, id), "« %s »" % id)
	_p.bar.put(2, points[0])
	_p.stats.max_mana = 9999.0
	_p._set_mana(9999.0)


func _target(position: Vector2) -> Hurtbox:
	var h := Hurtbox.new()
	h.collision_layer = Targets.ENEMIES
	h.collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	h.add_child(shape)
	add_child_autofree(h)
	h.global_position = position
	_received_all[h] = []
	h.damaged.connect(_on_hit.bind(h))
	return h


func _on_hit(info: DamageInfo, target: Hurtbox) -> void:
	_received_all[target].append(info.amount)


func _hits(target: Hurtbox) -> int:
	return (_received_all[target] as Array).size()


func _children_of(cls: Variant) -> Array:
	return _effects.get_children().filter(func(n: Node) -> bool: return is_instance_of(n, cls))


# --------------------------------------------------------------------------
# Chaîne d'éclairs
# --------------------------------------------------------------------------

func test_the_chain_hits_three_enemies_and_not_the_fourth() -> void:
	_learn("manual_lightning", ["chain_lightning"])
	var targets := [_target(Vector2(60, 0)), _target(Vector2(120, 0)), _target(Vector2(180, 0)), _target(Vector2(240, 0))]
	await wait_physics_frames(2)

	assert_true(_p.cast_slot(2))
	for i in 3:
		assert_eq(_hits(targets[i]), 1, "la cible %d est touchée une fois" % (i + 1))
	assert_eq(_hits(targets[3]), 0, "la quatrième n'est pas touchée : trois cibles")


func test_the_chain_does_not_jump_beyond_its_range() -> void:
	_learn("manual_lightning", ["chain_lightning"])
	var near := _target(Vector2(60, 0))
	var too_far := _target(Vector2(60 + ChainLightning.JUMP + 20.0, 0))
	await wait_physics_frames(2)

	assert_true(_p.cast_slot(2))
	assert_eq(_hits(near), 1)
	assert_eq(_hits(too_far), 0, "hors de portée d'un saut")


## L'auteur voyage avec les formes, qui ne naissent pas d'une collision : un lanceur
## béni frappe moins fort par sa chaîne comme par son épée.
func test_the_chain_strikes_on_behalf_of_its_caster() -> void:
	_learn("manual_lightning", ["chain_lightning"])
	var target := _target(Vector2(60, 0))
	await wait_physics_frames(2)

	assert_true(_p.cast_slot(2))
	_p._recharges[2] = 0.0
	_p.states.put(StatusEffects.Kind.BLESSING, 1.0)
	assert_true(_p.cast_slot(2))
	assert_eq(_hits(target), 2)
	assert_almost_eq(float(_received_all[target][1]), float(_received_all[target][0]) * (1.0 - StatusEffects.BLESSING), 0.001)


## Sans cible dans le cône, elle part quand même : un sort payé qui ne montre rien
## se lirait comme une touche morte.
func test_the_chain_fires_into_the_void_without_a_target_ahead() -> void:
	_learn("manual_lightning", ["chain_lightning"])
	var on_the_side := _target(Vector2(0, 60))
	await wait_physics_frames(2)

	var mana := _p.mana
	assert_true(_p.cast_slot(2))
	assert_eq(_hits(on_the_side), 0, "hors du cône de la visée")
	assert_lt(_p.mana, mana, "le mana est dépensé")
	assert_eq(_children_of(ChainLightning).size(), 1, "et la décharge se voit")


# --------------------------------------------------------------------------
# Les dégâts contre un état voyagent avec le coup (jalon 14)
# --------------------------------------------------------------------------

## Une cible qui saigne déjà, et « +100 % contre les saignants » : elle doit prendre le
## double d'une cible nue touchée par le même geste. Le critique est retiré, qui
## tirerait une cible sur deux.
func _bleeding_target(position: Vector2) -> Hurtbox:
	var h := _target(position)
	h.states = StatusEffects.new()
	h.states.put(StatusEffects.Kind.BLEED, 0.0)
	return h


func _against_bleeding(scope: String) -> void:
	_p.stats.crit_chance = 0.0
	_p.skill_mods.assign([StatMod.new(
		SkillStats.against_stat(StatusEffects.Kind.BLEED), StatMod.Mode.PERCENT, 100.0, scope
	)])


func _assert_doubled(bleeding: Hurtbox, bare: Hurtbox, path: String) -> void:
	assert_eq(_hits(bleeding), 1, path)
	assert_eq(_hits(bare), 1, path)
	if _hits(bleeding) == 1 and _hits(bare) == 1:
		assert_almost_eq(
			float(_received_all[bleeding][0]), float(_received_all[bare][0]) * 2.0, 0.001, path
		)


func test_a_chain_carries_its_damage_against_a_state() -> void:
	_learn("manual_lightning", ["chain_lightning"])
	_against_bleeding(Keywords.SPELL)
	var bleeding := _bleeding_target(Vector2(60, 0))
	var bare := _target(Vector2(120, 0))
	await wait_physics_frames(2)
	assert_true(_p.cast_slot(2))
	_assert_doubled(bleeding, bare, "Targets.strike")


func test_a_ball_carries_it_by_its_bolt_and_its_explosion() -> void:
	_learn("manual_fire", ["fireball"])
	_against_bleeding(Keywords.SPELL)
	var bleeding := _bleeding_target(Vector2(40, 0))
	var bare := _target(Vector2(40, 16))
	await wait_physics_frames(2)
	assert_true(_p.cast_slot(2))
	await wait_seconds(0.5)
	_assert_doubled(bleeding, bare, "le tir sur l'une, l'explosion sur l'autre")


func test_a_swing_carries_it() -> void:
	_learn("manual_weapons", ["heavy_strike"])
	_against_bleeding(Keywords.ATTACK)
	var bleeding := _bleeding_target(Vector2(20, -4))
	var bare := _target(Vector2(20, 4))
	await wait_physics_frames(2)
	assert_true(_p.cast_slot(2))
	await wait_seconds(_p.swing_duration + 0.2)
	_assert_doubled(bleeding, bare, "le coup d'arc")


# --------------------------------------------------------------------------
# Nuage d'orage
# --------------------------------------------------------------------------

func test_the_cloud_strikes_below_not_beside_then_vanishes() -> void:
	_learn("manual_lightning", ["storm_cloud"])
	# Une durée raccourcie, pour ne pas attendre trois secondes.
	_p.skill_mods.assign([StatMod.new("duration", StatMod.Mode.PERCENT, -50.0, Keywords.SPELL)])
	var point := Vector2(Player.PLACEMENT_RANGE, 0)
	var below := _target(point)
	var beside := _target(point + Vector2(0, 80))
	await wait_physics_frames(2)

	Game.hit_stop_duration = 0.05
	Game.hit_stop_period = 0.0
	Game.freezes = 0
	assert_true(_p.cast_slot(2))
	var cloud: StormCloud = _children_of(StormCloud)[0]
	# Gardé avant l'attente : le nuage sera libéré à la fin.
	var cast := cloud._cast
	assert_eq(cloud.global_position, point, "posé à la portée, devant")
	await wait_physics_frames(3)
	assert_eq(_hits(below), 1, "la première impulsion part à la pose")
	assert_eq(_hits(beside), 0)

	await wait_seconds(cast.duration + 0.2)
	assert_eq(_hits(below), cast.strikes_over_duration(), "une frappe par période")
	assert_eq(Game.freezes, 0, "ce qui dure ne fige jamais le jeu")
	assert_eq(_children_of(StormCloud).size(), 0, "et il s'est dissipé")


# --------------------------------------------------------------------------
# Immolation
# --------------------------------------------------------------------------

func test_the_aura_lights_strikes_burns_and_goes_out_for_free() -> void:
	_learn("manual_fire", ["immolation"])
	var near := _target(Vector2(20, 0))
	var far := _target(Vector2(100, 0))
	await wait_physics_frames(2)

	var mana := _p.mana
	assert_true(_p.cast_slot(2))
	assert_true(_p.aura_lit())
	assert_lt(_p.mana, mana, "l'allumer coûte")
	await wait_physics_frames(3)
	assert_eq(_hits(near), 1, "l'ennemi du cercle brûle")
	assert_eq(_hits(far), 0)
	assert_lt(_p.health, _p.stats.max_health, "et le porteur aussi")

	_p._recharges[2] = 0.0
	mana = _p.mana
	assert_true(_p.cast_slot(2))
	assert_false(_p.aura_lit(), "le second lancer éteint")
	assert_eq(_p.mana, mana, "sans coût")


## **Le piège de la touche tenue** : elle relance à chaque fin de recharge, et une
## aura qui s'allume et s'éteint en boucle serait inutilisable.
func test_the_aura_does_not_flicker_while_the_key_is_held() -> void:
	_learn("manual_fire", ["immolation"])
	Input.action_press("skill_3")
	await wait_physics_frames(2)
	assert_true(_p.aura_lit(), "l'appui l'allume")
	await wait_seconds(_p.resolve(SkillCatalog.by_id("immolation"), 1).interval * 2.5)
	assert_true(_p.aura_lit(), "la touche tenue ne l'éteint pas")


func _all_in(nature: DamageType.Kind) -> Array[float]:
	var parts := DamageType.empty_parts()
	parts[nature] = 1.0
	return parts


func test_burn_follows_resistance_and_can_kill() -> void:
	_p.stats.max_health = 100.0
	_p._set_health(100.0)
	_p.stats.res_fire = 0.0
	_p.burn(0.5, _all_in(DamageType.Kind.FIRE), 1.0)
	assert_almost_eq(_p.health, 50.0, 0.001)

	_p._set_health(100.0)
	_p.stats.res_fire = 50.0
	_p.burn(0.5, _all_in(DamageType.Kind.FIRE), 1.0)
	assert_almost_eq(_p.health, 75.0, 0.001, "la moitié de la brûlure résistée")

	_p.burn(10.0, _all_in(DamageType.Kind.FIRE), 1.0)
	assert_true(_p.is_dead, "c'est le prix du sort")


## Convertie à moitié en nécrotique, elle n'est résistée qu'à moitié par le feu.
func test_each_burn_part_meets_its_own_defense() -> void:
	_p.stats.max_health = 100.0
	_p._set_health(100.0)
	_p.stats.res_fire = 50.0
	_p.stats.res_necrotic = 0.0
	var half := DamageType.empty_parts()
	half[DamageType.Kind.FIRE] = 0.5
	half[DamageType.Kind.NECROTIC] = 0.5
	_p.burn(0.5, half, 1.0)
	assert_almost_eq(_p.health, 100.0 - (12.5 + 25.0), 0.001)


## La résistance que donne un objet porté sert contre la brûlure comme contre un
## coup, plafond compris : elle passe par la fiche recalculée, et par la même règle.
func test_a_fire_resistance_item_reduces_burn() -> void:
	var without := _burn_loss()
	_p.equip(Item.new(ItemCatalog.by_id("ring"), [ItemAffixPool.by_id("fireproof").modifier(40.0)]))
	assert_almost_eq(_burn_loss(), without * (1.0 - _p.stats.resistance(DamageType.Kind.FIRE) * 0.01), 0.001)
	assert_lt(_burn_loss(), without)

	_p.stats.res_fire = 500.0
	assert_almost_eq(
		_burn_loss(), without * (1.0 - CharacterStats.MAX_RESISTANCE * 0.01), 0.001,
		"plafonnée comme contre un coup"
	)


func _burn_loss() -> float:
	_p._set_health(_p.stats.max_health)
	var before := _p.health
	_p.burn(0.1, _all_in(DamageType.Kind.FIRE), 1.0)
	return before - _p.health


func test_the_aura_goes_out_when_its_book_leaves_the_rack() -> void:
	_learn("manual_fire", ["immolation"])
	assert_true(_p.cast_slot(2))
	_p.stop_studying(0)
	await wait_physics_frames(2)
	assert_false(_p.aura_lit())


# --------------------------------------------------------------------------
# Serpent infernal
# --------------------------------------------------------------------------

func test_the_snake_burns_what_it_touches_once_per_period() -> void:
	_learn("manual_fire", ["hell_snake"])
	var point := Vector2(Player.PLACEMENT_RANGE, 0)
	var below := _target(point)
	await wait_physics_frames(2)

	assert_true(_p.cast_slot(2))
	var snake: HellSnake = _children_of(HellSnake)[0]
	await wait_physics_frames(3)
	assert_eq(_hits(below), 1, "la tête tombe sur elle")
	await wait_seconds(snake._cast.period * 0.5)
	assert_eq(_hits(below), 1, "pas deux fois dans la même période")


func test_the_snake_stays_near_its_landing_point() -> void:
	_learn("manual_fire", ["hell_snake"])
	assert_true(_p.cast_slot(2))
	var snake: HellSnake = _children_of(HellSnake)[0]
	var farthest := 0.0
	for i in 30:
		await wait_physics_frames(6)
		if not is_instance_valid(snake):
			break
		farthest = maxf(farthest, snake._head.distance_to(snake._anchor))
	assert_lt(farthest, HellSnake.LEASH * 1.5, "la laisse le ramène")


# --------------------------------------------------------------------------
# Épée spirale
# --------------------------------------------------------------------------

func test_spiral_sword_refuses_the_fourth_without_taking_anything() -> void:
	_learn("manual_weapons", ["spiral_sword"])
	for i in 3:
		_p._recharges[2] = 0.0
		assert_true(_p.cast_slot(2), "épée %d" % (i + 1))
	assert_eq(_p.orbiting_swords(), 3)

	_p._recharges[2] = 0.0
	var mana := _p.mana
	assert_false(_p.cast_slot(2), "la quatrième est refusée")
	assert_eq(_p.mana, mana, "sans mana")
	assert_eq(_p.remaining_cooldown(2), 0.0, "ni recharge")


func test_the_sword_strikes_while_spinning_then_vanishes() -> void:
	_learn("manual_weapons", ["spiral_sword"])
	_p.skill_mods.assign([StatMod.new("duration", StatMod.Mode.PERCENT, -80.0, Keywords.ATTACK)])
	var on_the_circle := _target(Vector2(BladeCrown.RADIUS, 0))
	await wait_physics_frames(2)

	assert_true(_p.cast_slot(2))
	await wait_seconds(0.5)
	assert_gt(_hits(on_the_circle), 0, "elle passe sur la cible")
	await wait_seconds(0.8)
	assert_eq(_p.orbiting_swords(), 0, "et elle a fini de tourner")


# --------------------------------------------------------------------------
# Coup en croix et boule de feu
# --------------------------------------------------------------------------

## Deux coups, la hitbox rouverte entre les deux : c'est ce qui le distingue d'un
## arc plus large.
func test_the_cross_hits_the_same_target_twice() -> void:
	_learn("manual_weapons", ["cross_slash"])
	var ahead := _target(Vector2(20, 0))
	await wait_physics_frames(2)

	assert_true(_p.cast_slot(2))
	await wait_seconds(_p.swing_duration * 2.0 + 0.3)
	assert_eq(_hits(ahead), 2)


func test_the_ball_wounds_the_neighbor_and_the_target_once() -> void:
	_learn("manual_fire", ["fireball"])
	var direct := _target(Vector2(40, 0))
	var neighbor := _target(Vector2(40, 16))
	var far := _target(Vector2(40, 70))
	await wait_physics_frames(2)

	assert_true(_p.cast_slot(2))
	await wait_seconds(0.5)
	assert_eq(_hits(direct), 1, "la touche directe, sans l'explosion en plus")
	assert_eq(_hits(neighbor), 1, "l'explosion atteint le voisin")
	assert_eq(_hits(far), 0)
