extends GutTest

const Weapons := preload("res://tests/weapons.gd")
const Gestures := preload("res://tests/gestures.gd")

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
	Weapons.arm(_p, points[0])
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


## Un pan de roche, sur le calque du décor : celui que l'atterrissage d'une ruée
## interroge, et le seul.
func _wall(center: Vector2, extents: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = Targets.DECOR
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = extents
	shape.shape = box
	body.add_child(shape)
	add_child_autofree(body)
	body.global_position = center
	return body


func _children_of(cls: Variant) -> Array:
	return _effects.get_children().filter(func(n: Node) -> bool: return is_instance_of(n, cls))


# --------------------------------------------------------------------------
# Chaîne d'éclairs
# --------------------------------------------------------------------------

func test_the_chain_hits_three_enemies_and_not_the_fourth() -> void:
	_learn("manual_lightning", ["chain_lightning"])
	var targets := [_target(Vector2(60, 0)), _target(Vector2(120, 0)), _target(Vector2(180, 0)), _target(Vector2(240, 0))]
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 2))
	for i in 3:
		assert_eq(_hits(targets[i]), 1, "la cible %d est touchée une fois" % (i + 1))
	assert_eq(_hits(targets[3]), 0, "la quatrième n'est pas touchée : trois cibles")


func test_the_chain_does_not_jump_beyond_its_range() -> void:
	_learn("manual_lightning", ["chain_lightning"])
	var near := _target(Vector2(60, 0))
	var too_far := _target(Vector2(60 + ChainLightning.JUMP + 20.0, 0))
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 2))
	assert_eq(_hits(near), 1)
	assert_eq(_hits(too_far), 0, "hors de portée d'un saut")


## L'auteur voyage avec les formes, qui ne naissent pas d'une collision : un lanceur
## béni frappe moins fort par sa chaîne comme par son épée.
func test_the_chain_strikes_on_behalf_of_its_caster() -> void:
	_learn("manual_lightning", ["chain_lightning"])
	var target := _target(Vector2(60, 0))
	# Le critique est retiré, comme pour les dégâts contre un état : il tire une
	# salve sur deux, doublerait l'une des deux et ferait dépendre le test de la
	# place de ce lancer dans le fil de `Game.rng`.
	_p.skill_mods.assign([StatMod.new("crit_chance", StatMod.Mode.PERCENT, -100.0)])
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 2))
	_p._recharges[2] = 0.0
	_p.states.put(StatusEffects.Kind.BLESSING, 1.0)
	assert_true(Gestures.cast(_p, 2))
	assert_eq(_hits(target), 2)
	assert_almost_eq(float(_received_all[target][1]), float(_received_all[target][0]) * (1.0 - StatusEffects.BLESSING), 0.001)


## Sans cible dans le cône, elle part quand même : un sort payé qui ne montre rien
## se lirait comme une touche morte.
func test_the_chain_fires_into_the_void_without_a_target_ahead() -> void:
	_learn("manual_lightning", ["chain_lightning"])
	var on_the_side := _target(Vector2(0, 60))
	await wait_physics_frames(2)

	var mana := _p.mana
	assert_true(Gestures.cast(_p, 2))
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
	_p.skill_mods.assign([
		StatMod.new(SkillStats.against_stat(StatusEffects.Kind.BLEED), StatMod.Mode.PERCENT, 100.0, scope),
		StatMod.new("crit_chance", StatMod.Mode.PERCENT, -100.0),
	])


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
	assert_true(Gestures.cast(_p, 2))
	_assert_doubled(bleeding, bare, "Targets.strike")


func test_a_ball_carries_it_by_its_bolt_and_its_explosion() -> void:
	_learn("manual_fire", ["fireball"])
	_against_bleeding(Keywords.SPELL)
	var bleeding := _bleeding_target(Vector2(40, 0))
	var bare := _target(Vector2(40, 16))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(0.5)
	_assert_doubled(bleeding, bare, "le tir sur l'une, l'explosion sur l'autre")


## Un sort critique par chacun de ses chemins de coup : la chaîne par `Targets.strike`,
## la boule par son tir et son explosion.
func test_a_spell_crits_on_every_path() -> void:
	var crits := []
	for at in [Vector2(60, 0), Vector2(40, 40), Vector2(40, 56)]:
		_target(at).damaged.connect(func(info: DamageInfo) -> void: crits.append(info.is_crit))
	await wait_physics_frames(2)
	_learn("manual_lightning", ["chain_lightning"])
	_p.skill_mods.assign([StatMod.new("crit_chance", StatMod.Mode.PERCENT, 10000.0)])
	assert_true(Gestures.cast(_p, 2), "la chaîne")
	_learn("manual_fire", ["fireball"])
	_p.skill_mods.assign([StatMod.new("crit_chance", StatMod.Mode.PERCENT, 10000.0)])
	_p.bar.put(1, "fireball")
	_p.facing = Vector2(1, 1).normalized()
	assert_true(Gestures.cast(_p, 1), "la boule, sur une case qui ne recharge pas")
	await wait_seconds(0.5)
	assert_gt(crits.size(), 2)
	assert_false(false in crits, "tous critiques")


func test_a_swing_carries_it() -> void:
	_learn("manual_weapons", ["heavy_strike"])
	_against_bleeding(Keywords.ATTACK)
	var bleeding := _bleeding_target(Vector2(20, -4))
	var bare := _target(Vector2(20, 4))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
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
	assert_true(Gestures.cast(_p, 2))
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
	assert_true(Gestures.cast(_p, 2))
	assert_true(_p.aura_lit())
	assert_lt(_p.mana, mana, "l'allumer coûte")
	await wait_physics_frames(3)
	assert_eq(_hits(near), 1, "l'ennemi du cercle brûle")
	assert_eq(_hits(far), 0)
	assert_lt(_p.health, _p.stats.max_health, "et le porteur aussi")

	_p._recharges[2] = 0.0
	mana = _p.mana
	assert_true(Gestures.cast(_p, 2))
	assert_false(_p.aura_lit(), "le second lancer éteint")
	assert_eq(_p.mana, mana, "sans coût")


## **Le piège de la touche tenue** : elle relance à chaque fin de recharge, et une
## aura qui s'allume et s'éteint en boucle serait inutilisable.
func test_the_aura_does_not_flicker_while_the_key_is_held() -> void:
	_learn("manual_fire", ["immolation"])
	# Un appui qui traverse l'arbre d'entrées : seul celui-là arme la case.
	var press := InputEventAction.new()
	press.action = "skill_3"
	press.pressed = true
	Input.parse_input_event(press)
	await wait_physics_frames(2)
	assert_true(_p.aura_lit(), "l'appui l'allume")
	await wait_seconds(_p.resolve(SkillCatalog.by_id("immolation"), 1).interval * 2.5)
	assert_true(_p.aura_lit(), "la touche tenue ne l'éteint pas")


## Le Tirage : chaque impulsion tire vers le porteur — un recul négatif.
func test_a_draught_pulls_what_the_aura_strikes() -> void:
	_learn_with("manual_fire", "immolation", [[SkillStats.PULL, 40.0]])
	var near := _target(Vector2(30, 0))
	var knocks := []
	near.damaged.connect(func(info: DamageInfo) -> void: knocks.append(info.knockback))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(3)
	assert_eq(knocks, [-40.0])


## Le Feu de camp monte tant qu'on ne bouge pas, et retombe au premier pas ; à pleine
## montée, la Veillée soigne plus que le brasier ne brûle.
func test_a_campfire_rises_while_still_and_keeps_vigil() -> void:
	_learn_with("manual_fire", "immolation", [[SkillStats.CAMPFIRE, 50.0], [SkillStats.VIGIL, 10.0]])
	var base := _p.resolve(SkillCatalog.by_id("immolation"), 1).radius
	assert_true(Gestures.cast(_p, 2))
	var aura: Immolation = _p._lit["immolation"]
	await wait_seconds(1.1)
	var risen := aura._cast.radius
	assert_gt(risen, base * 1.3, "monté")
	# Il remonte dès qu'on s'arrête : à l'impulsion suivante, il est reparti de zéro.
	_p.global_position += Vector2(10, 0)
	await wait_seconds(aura._cast.period + 0.05)
	assert_lt(aura._cast.radius, risen * 0.9, "retombé au premier pas")
	aura._still = SkillStats.CAMPFIRE_MOST
	_p._set_health(_p.stats.max_health * 0.5)
	var before := _p.health
	await wait_physics_frames(10)
	assert_gt(_p.health, before, "la Veillée soigne")


## Les Escarbilles : une étincelle vers l'ennemi hors du cercle, aucune sans lui.
func test_cinders_leap_to_an_enemy_outside_the_circle() -> void:
	_learn_with("manual_fire", "immolation", [[SkillStats.EMBERS, 2.0]])
	var radius := _p.resolve(SkillCatalog.by_id("immolation"), 1).radius
	_target(Vector2(radius * 0.5, 0))
	var outside := _target(Vector2(0, radius * 1.6))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	var aura: Immolation = _p._lit["immolation"]
	await wait_physics_frames(1)
	for spark: Fireball in _children_of(Fireball):
		spark.free()
	aura._strike()
	var sparks := _children_of(Fireball)
	assert_eq(sparks.size(), 1, "une par ennemi dehors, pas plus")
	assert_true((sparks[0] as Fireball).is_shard)
	await wait_seconds(0.3)
	assert_gt(_hits(outside), 0, "elle l'atteint")


## L'Œil du brasier : au cœur du cercle, le même tirage frappe plus fort.
func test_the_eye_of_the_blaze_strikes_harder_at_the_core() -> void:
	_learn_with("manual_fire", "immolation", [[SkillStats.EYE, 24.0]])
	var radius := _p.resolve(SkillCatalog.by_id("immolation"), 1).radius
	var core := _target(Vector2(radius * 0.2, 0))
	var edge := _target(Vector2(0, radius * 0.8))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(3)
	assert_almost_eq(_received_all[core][0] / _received_all[edge][0], 1.24, 0.001)


## La Renaissance retient un coup fatal, une fois par minute, et le brasier explose ; les
## Cendres du phénix suspendent sa brûlure.
func test_rebirth_holds_back_one_death_a_minute() -> void:
	_learn_with("manual_fire", "immolation", [[SkillStats.REBIRTH, 1.0], [SkillStats.PHOENIX_ASHES, 1.0]])
	assert_true(Gestures.cast(_p, 2))
	_p._set_health(0.0)
	_p._die()
	assert_false(_p.is_dead, "retenu")
	assert_almost_eq(_p.health, _p.stats.max_health * SkillStats.REBIRTH_HEALTH, 0.01)
	assert_eq(_p.phoenix_ashes, SkillStats.ASHES_TIME)
	var health := _p.health
	await wait_physics_frames(2)
	assert_eq(_children_of(Explosion).size(), 1, "le brasier explose")
	assert_gte(_p.health, health, "les cendres : il ne brûle plus")
	_p._set_health(0.0)
	_p._die()
	assert_true(_p.is_dead, "pas deux fois dans la minute")


## Les Âmes consumées : un tué du brasier rend une part des PV max.
func test_consumed_souls_heal_on_each_kill() -> void:
	var cast := _p.resolve(SkillCatalog.by_id("immolation"), 1)
	cast.soul_feast = 10.0
	_p._set_health(_p.stats.max_health * 0.5)
	_p.states.slew.emit(cast, Vector2.ZERO, null)
	assert_almost_eq(_p.health, _p.stats.max_health * 0.6, 0.01)


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
	assert_true(Gestures.cast(_p, 2))
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

	assert_true(Gestures.cast(_p, 2))
	var snake: HellSnake = _children_of(HellSnake)[0]
	await wait_physics_frames(3)
	assert_eq(_hits(below), 1, "la tête tombe sur elle")
	await wait_seconds(snake._cast.period * 0.5)
	assert_eq(_hits(below), 1, "pas deux fois dans la même période")


## Le roulement de peinture : seul, un serpent a son tour à chaque image ; trois fois trop
## nombreux, une image sur trois — et chacun la sienne.
func test_a_crowd_of_snakes_takes_turns_to_repaint() -> void:
	var before := HellSnake.crawling
	HellSnake.crawling = 1
	assert_true(HellSnake.on_turn(5, 0) and HellSnake.on_turn(5, 1), "seul, à chaque image")
	HellSnake.crawling = HellSnake.PAINTED_PER_IMAGE * 3
	var turns := 0
	for image in 3:
		turns += 1 if HellSnake.on_turn(5, image) else 0
	var painted := 0
	for slot in HellSnake.crawling:
		painted += 1 if HellSnake.on_turn(slot, 7) else 0
	HellSnake.crawling = before
	assert_eq(turns, 1, "une image sur trois")
	assert_eq(painted, HellSnake.PAINTED_PER_IMAGE, "pas plus par image")


## Un sol posé sur un sol vivant de la même compétence le ravive au lieu de s'ajouter.
func test_a_ground_laid_on_a_ground_renews_it() -> void:
	_learn("manual_fire", ["hell_snake"])
	var ground := _p.resolve(SkillCatalog.by_id("hell_snake"), 1).ground()
	ground.duration = 2.0
	# Dans la même case de `LAID_CELL` × 14 px, loin d'une frontière.
	var first := DashTrail.patch(_effects, Vector2(302, 302), ground, _p.states)
	await wait_physics_frames(3)
	first._age = 1.5
	var again := DashTrail.patch(_effects, Vector2(303, 303), ground, _p.states)
	assert_eq(again, first, "ravivé")
	assert_almost_eq(first._age, DashTrail.SPAWN, 1e-4)
	var aside := DashTrail.patch(_effects, Vector2(302 + ground.radius * 2.0, 302), ground, _p.states)
	assert_ne(aside, first, "plus loin, un autre sol")
	await wait_physics_frames(2)
	assert_eq(_children_of(DashTrail).size(), 2)


func test_the_snake_stays_near_its_landing_point() -> void:
	_learn("manual_fire", ["hell_snake"])
	assert_true(Gestures.cast(_p, 2))
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
		assert_true(Gestures.cast(_p, 2), "épée %d" % (i + 1))
	assert_eq(_p.orbiting_swords(), 3)

	_p._recharges[2] = 0.0
	var mana := _p.mana
	assert_false(Gestures.cast(_p, 2), "la quatrième est refusée")
	assert_eq(_p.mana, mana, "sans mana")
	assert_eq(_p.remaining_cooldown(2), 0.0, "ni recharge")


func test_the_sword_strikes_while_spinning_then_vanishes() -> void:
	_learn("manual_weapons", ["spiral_sword"])
	_p.skill_mods.assign([StatMod.new("duration", StatMod.Mode.PERCENT, -80.0, Keywords.ATTACK)])
	var on_the_circle := _target(Vector2(SkillCatalog.by_id("spiral_sword").radius, 0))
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 2))
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

	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(_p.swing_duration * 2.0 + 0.3)
	assert_eq(_hits(ahead), 2)


func test_the_ball_wounds_the_neighbor_and_the_target_once() -> void:
	_learn("manual_fire", ["fireball"])
	var direct := _target(Vector2(40, 0))
	var neighbor := _target(Vector2(40, 16))
	var far := _target(Vector2(40, 70))
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(0.5)
	assert_eq(_hits(direct), 1, "la touche directe, sans l'explosion en plus")
	assert_eq(_hits(neighbor), 1, "l'explosion atteint le voisin")
	assert_eq(_hits(far), 0)


# --------------------------------------------------------------------------
# Les ruées et les buffs (jalon 20)
# --------------------------------------------------------------------------

## La ruée porte le joueur au bout de sa visée — la portée de pose, la même que celle
## du nuage et du serpent.
func test_the_dash_carries_the_player_to_the_aim() -> void:
	_learn("manual_fire", ["flame_dash"])
	var from_value := _p.global_position
	assert_true(Gestures.cast(_p, 2))
	assert_almost_eq(
		_p.global_position.distance_to(from_value), Player.PLACEMENT_RANGE, 2.0,
		"au bout de la portée de pose"
	)
	assert_gt(_p.global_position.x, from_value.x, "dans la visée")


## Et sa trace frappe le couloir, pas ce qui est à côté, jusqu'à la fin de sa durée.
func test_the_trail_strikes_its_corridor_until_it_fades() -> void:
	_learn("manual_fire", ["flame_dash"])
	var on_the_way := _target(Vector2(60, 0))
	var aside := _target(Vector2(60, 60))
	await wait_physics_frames(2)

	var cast := _p.resolve(SkillCatalog.by_id("flame_dash"), 1)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(cast.duration + 0.2)
	assert_eq(_hits(on_the_way), cast.strikes_over_duration(), "une frappe par période")
	assert_eq(_hits(aside), 0, "et rien hors du couloir")
	assert_eq(Game.freezes, 0, "ce qui dure ne fige jamais le jeu")
	assert_eq(_children_of(DashTrail).size(), 0, "la trace s'est effacée")


## Le sillon de feu se dessine aussi large qu'il frappe (jalon 34) : l'ancienne file
## unique n'en montrait que le tiers, et Braises ne se voyait pas.
func test_the_fire_trail_is_drawn_as_wide_as_it_strikes() -> void:
	var widest: Array[float] = []
	for radius in [16.0, 25.6]:
		var cast := _p.resolve(SkillCatalog.by_id("flame_dash"), 1)
		cast.radius = radius
		var trail := DashTrail.new()
		trail._cast = cast
		trail._toward = Vector2(100.0, 0.0)
		trail._lay_out_the_bed()
		var reach := 0.0
		for t in trail._tongues:
			assert_lt(
				DashTrail._off_axis(t.foot.x, t.foot.y, 100.0), radius, "aucune langue hors du couloir"
			)
			reach = maxf(reach, absf(t.foot.y))
		widest.append(reach)
		trail.free()
	assert_gt(widest[0], 16.0 * 0.5, "les franges passent la moitié du rayon")
	assert_gt(widest[1], widest[0], "Braises élargit le dessin")


## Une traînée se couche **sous les corps**, sur la couche du sol : au-dessus d'eux, on
## marchait sous sa propre traînée.
func test_a_trail_lies_under_the_bodies() -> void:
	var layer := Node2D.new()
	layer.add_to_group(DashTrail.GROUND_LAYER)
	add_child_autofree(layer)
	var cast := _p.resolve(SkillCatalog.by_id("flame_dash"), 1)
	var trail := DashTrail.leave(self, Vector2.ZERO, Vector2(40.0, 0.0), cast, _p.states)
	assert_eq(trail.get_parent(), layer, "sur la couche du sol, pas parmi les tirs")
	assert_eq(trail.z_index, 0, "et pas relevée au-dessus des corps")


## Le sol d'une compétence convertie se voit autant que le sol brûlant (jalon 34) : un lit
## de givre ou de pourriture, des flocons ou des spores, et rien d'additif — il ne
## luisait qu'en deux taches à 0,3, invisibles sur la terre.
func test_a_converted_ground_is_drawn_like_the_fire() -> void:
	for nature in [DamageType.Kind.COLD, DamageType.Kind.NECROTIC]:
		var ground := _p.resolve(SkillCatalog.by_id("fireball"), 1).ground()
		ground.nature = nature
		var patch := DashTrail.new()
		patch._cast = ground
		add_child_autofree(patch)
		assert_null(patch.material, "%s : dessiné, pas en lumière ajoutée" % DamageType.name(nature))
		# Tiré au hasard, et moitié moins dense que la cendre : présent, pas compté.
		assert_gt(patch._bed_at.size(), 0, "un lit de taches")
		assert_gt(patch._tongues.size(), 0, "et ce qui en monte")
		for t in patch._tongues:
			assert_lt(t.foot.length(), ground.radius, "dans le cercle qui mord")


## La Ruée tranchante est une ruée dont la trace ne frappe **qu'une fois** : sa
## période est sa durée. Tout ce qui est sur la traversée prend le coup, une seule
## fois même sous plusieurs sondes, et rien à côté.
func test_the_slicing_dash_cuts_its_path_once() -> void:
	_learn("manual_weapons", ["slicing_dash"])
	var near := _target(Vector2(30, 0))
	var far := _target(Vector2(90, 0))
	var aside := _target(Vector2(60, 60))
	await wait_physics_frames(2)

	var cast := _p.resolve(SkillCatalog.by_id("slicing_dash"), 1)
	assert_eq(cast.strikes_over_duration(), 1, "un seul coup par traversée")
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(cast.duration + 0.2)
	assert_eq(_hits(near), 1, "au début du chemin")
	assert_eq(_hits(far), 1, "comme au bout")
	assert_eq(_hits(aside), 0, "et rien hors du couloir")
	assert_eq(_children_of(DashTrail).size(), 0, "la coupe s'est effacée")


## Un buff s'allume, verse ses lignes dans la fiche, ronge son porteur, et s'éteint au
## second lancer sans rien coûter. La Nécrose avancée, depuis que l'Ignition est partie
## (jalon 42) : le seul buff qui se payait en PV.
func test_the_buff_lights_gives_its_lines_and_goes_out_for_free() -> void:
	_learn("manual_necrotic", ["advanced_necrosis"])
	var rot := _p.stats.rot_chance
	assert_true(Gestures.cast(_p, 2))
	assert_true(_p.lit("advanced_necrosis"))
	assert_eq(_p.lit_ratio("advanced_necrosis"), 1.0, "entretenu, il n'a pas de compte à rebours")
	assert_gt(_p.stats.rot_chance, rot, "ses lignes sont dans la fiche")
	await wait_physics_frames(3)
	assert_lt(_p.health, _p.stats.max_health, "et il ronge son porteur")

	_p._recharges[2] = 0.0
	var mana := _p.mana
	assert_true(Gestures.cast(_p, 2))
	assert_false(_p.lit("advanced_necrosis"), "le second lancer éteint")
	assert_eq(_p.mana, mana, "sans coût")
	assert_eq(_p.stats.rot_chance, rot, "et la fiche retrouve ses nombres")


## L'arbre d'un buff (jalon 34) : la ligne d'un nœud qui vise la fiche est une ligne du
## buff — elle compte allumée, plus éteinte —, et sa brûlure suit les nœuds.
func test_a_buff_node_gives_its_lines_while_lit() -> void:
	_learn_with("manual_necrotic", "advanced_necrosis", [["rot_chance", 50.0], ["self_wither", -100.0, true]])
	var rot := _p.stats.rot_chance
	assert_true(Gestures.cast(_p, 2))
	assert_true(_p.lit("advanced_necrosis"))
	var lit_rot := _p.stats.rot_chance
	_p._recharges[2] = 0.0
	assert_true(Gestures.cast(_p, 2))
	var out_rot := _p.stats.rot_chance
	assert_eq(out_rot, rot, "éteint, la fiche retrouve ses nombres")

	_learn("manual_necrotic", ["advanced_necrosis"])
	_p._recharges[2] = 0.0
	assert_true(Gestures.cast(_p, 2))
	var bare_rot := _p.stats.rot_chance
	assert_gt(lit_rot, bare_rot, "le nœud s'ajoute au buff")


func test_a_buff_node_can_put_out_its_burn() -> void:
	_learn_with("manual_necrotic", "advanced_necrosis", [["self_wither", -100.0, true]])
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(5)
	assert_eq(_p.health, _p.stats.max_health, "sans brûlure, plus rien ne ronge")


## Le mana épuisé éteint ce qui le draine — là où les PV épuisés tuent.
func test_the_buff_goes_out_when_its_pool_is_empty() -> void:
	_learn("manual_lightning", ["static_electricity"])
	assert_true(Gestures.cast(_p, 2))
	assert_true(_p.lit("static_electricity"))

	_p.stats.mana_regen = 0.0
	_p._set_mana(0.0)
	await wait_physics_frames(2)
	assert_false(_p.lit("static_electricity"))


## La charge statique : un coup sur un engourdi la laisse, un coup sur un ennemi sain
## non. Le coup part par `Targets.strike()`, donc par la hurtbox, comme tous les coups.
func test_a_hit_on_a_numbed_enemy_leaves_a_static_charge() -> void:
	_learn("manual_lightning", ["static_electricity"])
	var numbed := _target(Vector2(30, 0))
	numbed.states = StatusEffects.new()
	numbed.states.put(StatusEffects.Kind.NUMB, 1.0)
	var healthy := _target(Vector2(60, 0))
	healthy.states = StatusEffects.new()
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 2))
	_p.stats.static_charge_chance = 100.0
	var parts := _all_in(DamageType.Kind.LIGHTNING)
	parts[DamageType.Kind.LIGHTNING] = 50.0

	Targets.strike(numbed, parts, Vector2.ZERO, _p.states, null)
	await wait_physics_frames(2)
	assert_eq(_children_of(StaticCharge).size(), 1, "une charge est restée sur l'engourdi")

	Targets.strike(healthy, parts, Vector2.ZERO, _p.states, null)
	await wait_physics_frames(2)
	assert_eq(_children_of(StaticCharge).size(), 1, "et rien sur un ennemi sain")


## Elle attend, mord **une fois par corps**, et reste : deux ennemis qui la traversent
## la paient tous les deux, le même deux fois non.
func test_the_static_charge_bites_once_per_body_and_stays() -> void:
	var walker := _target(Vector2(40, 0))
	var parts := _all_in(DamageType.Kind.LIGHTNING)
	parts[DamageType.Kind.LIGHTNING] = 50.0
	StaticCharge.put(_effects, Vector2(40, 0), Vector2.RIGHT, parts, _p.states)
	await wait_physics_frames(2)
	assert_eq(_hits(walker), 0, "elle ne frappe pas à la naissance")

	await wait_seconds(StaticCharge.CHECK * 2.0)
	assert_eq(_hits(walker), 1, "puis une fois")
	assert_almost_eq(
		(_received_all[walker] as Array)[0], 50.0 * StaticCharge.SHARE, 0.01,
		"un cinquième de ce que le coup a fait"
	)
	assert_eq(_children_of(StaticCharge).size(), 1, "et elle reste")

	# Un second corps, posé après coup, la paie aussi ; le premier, non.
	var second := _target(Vector2(44, 0))
	await wait_seconds(StaticCharge.CHECK * 3.0)
	assert_eq(_hits(walker), 1, "le même corps ne la paie pas deux fois")
	assert_eq(_hits(second), 1, "un autre, si")

	await wait_seconds(StaticCharge.LIFE)
	assert_eq(_children_of(StaticCharge).size(), 0, "sa vie passée, elle s'en va")


## Une ruée traverse ce qui est sur le chemin : c'est **l'arrivée** qui doit être libre.
func test_the_dash_goes_through_what_is_on_the_way() -> void:
	_learn("manual_fire", ["flame_dash"])
	_wall(Vector2(70, 0), Vector2(16, 120))
	await wait_physics_frames(2)

	var from_value := _p.global_position
	assert_true(Gestures.cast(_p, 2))
	assert_almost_eq(
		_p.global_position.distance_to(from_value), Player.PLACEMENT_RANGE, 2.0,
		"le mur du milieu ne l'arrête pas"
	)


## Et une arrivée prise recule jusqu'au premier point libre, plutôt que de refuser.
func test_a_taken_landing_backs_up_to_the_first_free_point() -> void:
	_learn("manual_fire", ["flame_dash"])
	_wall(Vector2(Player.PLACEMENT_RANGE, 0), Vector2(60, 120))
	await wait_physics_frames(2)

	var from_value := _p.global_position
	assert_true(Gestures.cast(_p, 2))
	var travelled := _p.global_position.x - from_value.x
	assert_gt(travelled, 0.0, "elle part quand même")
	assert_lt(travelled, Player.PLACEMENT_RANGE, "mais s'arrête devant le mur")


## La ruée d'orage ne laisse rien au sol : elle donne de la vitesse, et pour un temps.
func test_the_storm_dash_leaves_speed_and_no_trail() -> void:
	_learn("manual_lightning", ["storm_dash"])
	var speed := _p.stats.move_speed
	var cast := _p.resolve(SkillCatalog.by_id("storm_dash"), 1)

	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(2)
	assert_eq(_children_of(DashTrail).size(), 0, "rien au sol")
	assert_true(_p.lit("storm_dash"), "mais un buff sur le lanceur")
	assert_gt(_p.stats.move_speed, speed, "qui le presse")
	assert_lt(_p.lit_ratio("storm_dash"), 1.0, "et dont le compte à rebours descend")
	assert_eq(_p.lit_skills().size(), 1, "le bandeau a de quoi le montrer")

	await wait_seconds(cast.duration + 0.1)
	assert_false(_p.lit("storm_dash"), "le temps passé, il retombe")
	assert_eq(_p.stats.move_speed, speed, "et la fiche retrouve ses nombres")


# --------------------------------------------------------------------------
# Vague tranchante et cyclone (jalon 21)
# --------------------------------------------------------------------------

## La vague part de la lame et va chercher ce que le bras n'atteint pas — une fois,
## quelle que soit la durée qu'elle passe dessus.
func test_the_wave_travels_past_the_arm_and_bites_once() -> void:
	_learn("manual_weapons", ["wave_slash"])
	var cast := _p.resolve(SkillCatalog.by_id("wave_slash"), 1)
	# Devant le départ de la vague, et hors de portée de la hitbox.
	var ahead := _target(Vector2(SlashWave.START + cast.radius + 20.0, 0))
	var behind := _target(Vector2(-60, 0))
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 2))
	assert_eq(_children_of(SlashWave).size(), 1)
	await wait_seconds(cast.duration + 0.1)
	assert_eq(_hits(ahead), 1, "la vague l'a rattrapée, et une seule fois")
	assert_eq(_hits(behind), 0, "elle ne part que devant")
	assert_eq(_children_of(SlashWave).size(), 0, "et sa course finit avec sa durée")


## Le cyclone s'allume et s'éteint comme l'aura, mais se paie en mana : la réserve
## vide l'arrête, là où la brûlure d'Immolation tue.
func test_the_cyclone_spins_on_mana_until_the_pool_runs_dry() -> void:
	_learn("manual_weapons", ["cyclone"])
	var near := _target(Vector2(20, 0))
	var far := _target(Vector2(120, 0))
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 2))
	assert_true(_p.lit("cyclone"))
	await wait_physics_frames(3)
	assert_eq(_hits(near), 1, "ce qui est dans le cercle est fauché")
	assert_eq(_hits(far), 0)
	assert_lt(_p.mana, _p.stats.max_mana, "et le tour se paie")

	_p._set_mana(0.0)
	await wait_physics_frames(2)
	assert_false(_p.lit("cyclone"), "la réserve vide l'arrête")
	assert_false(_p.is_dead, "sans tuer personne")


# --------------------------------------------------------------------------
# Le manuel du froid (jalon 21)
# --------------------------------------------------------------------------

## Les pics frappent une fois au point visé, puis ne laissent rien.
func test_the_spikes_strike_once_and_leave_nothing() -> void:
	_learn("manual_cold", ["ice_spike"])
	var point := Vector2(Player.PLACEMENT_RANGE, 0)
	var below := _target(point)
	var beside := _target(point + Vector2(0, 80))
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 2))
	assert_eq(_children_of(IceSpikes)[0].global_position, point, "posés à la portée, devant")
	await wait_physics_frames(3)
	assert_eq(_hits(below), 1)
	assert_eq(_hits(beside), 0)

	await wait_seconds(IceSpikes.LIFETIME + 0.1)
	assert_eq(_hits(below), 1, "une seule fois : ils ne restent pas")
	assert_eq(_children_of(IceSpikes).size(), 0)


## La nova part de soi, et **transit mieux** qu'un coup de froid ordinaire : c'est le
## seul lancer qui porte sa propre chance d'état.
func test_the_nova_bursts_around_the_caster_and_chills_better() -> void:
	_learn("manual_cold", ["ice_nova"])
	var cast := _p.resolve(SkillCatalog.by_id("ice_nova"), 1)
	var near := _target(Vector2(30, 0))
	var far := _target(Vector2(cast.radius + 40.0, 0))
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(3)
	assert_eq(_hits(near), 1, "le cercle autour de soi")
	assert_eq(_hits(far), 0)
	assert_gt(cast.status_chance_increase, 0.0, "et elle transit mieux que le tout-venant")


## Le tombeau enferme : on ne bouge plus, rien d'autre ne part, et il se paie.
func test_the_tomb_binds_its_caster_and_only_lets_itself_end() -> void:
	_learn("manual_cold", ["frost_tomb"])
	# Une seconde case, pour vérifier qu'elle est refusée pendant l'enfermement.
	assert_true(_p.invest(0, "ice_spike"))
	_p.bar.put(3, "ice_spike")
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 2))
	assert_true(_p.lit("frost_tomb"))
	assert_false(Gestures.cast(_p, 3), "rien d'autre ne part")
	assert_lt(_p.stats.damage_taken, 0.0, "et les coups portent moins")

	_p._recharges[2] = 0.0
	assert_true(Gestures.cast(_p, 2), "seul le tombeau peut se rouvrir")
	assert_false(_p.lit("frost_tomb"))


## Il se referme tout seul à la fin de sa durée, et rend des PV en attendant.
func test_the_tomb_mends_then_thaws_on_its_own() -> void:
	_learn("manual_cold", ["frost_tomb"])
	var cast := _p.resolve(SkillCatalog.by_id("frost_tomb"), 1)
	_p._set_health(_p.stats.max_health * 0.5)
	var wounded := _p.health

	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(cast.duration * 0.5)
	assert_gt(_p.health, wounded, "la glace soigne")

	await wait_seconds(cast.duration * 0.6)
	assert_false(_p.lit("frost_tomb"), "puis elle fond")
	assert_eq(_p.stats.damage_taken, 0.0, "et la fiche retrouve ses nombres")


## Le vortex **grandit** : ce qui est au bord n'est pris que plus tard, et c'est ce
## qui le sépare du nuage d'orage.
func test_the_vortex_grows_and_reaches_the_edge_late() -> void:
	_learn("manual_cold", ["winter_disaster"])
	var cast := _p.resolve(SkillCatalog.by_id("winter_disaster"), 1)
	var on_the_edge := _target(Vector2(cast.radius * 0.9, 0))
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 2))
	var vortex: IceVortex = _children_of(IceVortex)[0]
	assert_lt(vortex.reach(), cast.radius, "il s'ouvre petit")
	await wait_physics_frames(3)
	assert_eq(_hits(on_the_edge), 0, "le bord n'est pas encore atteint")

	await wait_seconds(cast.duration + 0.2)
	assert_gt(_hits(on_the_edge), 0, "il a fini par l'engloutir")
	assert_eq(_children_of(IceVortex).size(), 0, "puis s'est refermé")


# --------------------------------------------------------------------------
# Le manuel sacré
# --------------------------------------------------------------------------

## Le trait perce : il frappe **tout ce qui est sur sa ligne**, une fois, et rien à
## côté. C'est ce qui le sépare d'un tir, qui s'arrête au premier corps.
func test_the_beam_pierces_its_line_and_spares_the_side() -> void:
	_learn("manual_holy", ["holy_strike"])
	var cast := _p.resolve(SkillCatalog.by_id("holy_strike"), 1)
	var near := _target(Vector2(cast.radius * 0.3, 0))
	var far_one := _target(Vector2(cast.radius * 0.9, 0))
	var beyond := _target(Vector2(cast.radius + 40.0, 0))
	var aside := _target(Vector2(cast.radius * 0.5, 40.0))
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(2)
	assert_eq(_hits(near), 1, "le premier corps ne l'arrête pas")
	assert_eq(_hits(far_one), 1)
	assert_eq(_hits(beyond), 0, "au-delà de sa longueur")
	assert_eq(_hits(aside), 0, "et rien hors de la ligne")

	await wait_seconds(HolyBeam.LIFETIME + 0.1)
	assert_eq(_hits(near), 1, "une seule fois : le trait ne dure pas")
	assert_eq(_children_of(HolyBeam).size(), 0)


## Le pilier tombe au point visé et frappe son cercle à chaque période, exactement
## autant de fois que la fiche l'annonce.
func test_the_pillar_strikes_its_circle_for_its_duration() -> void:
	_learn("manual_holy", ["sacred_pillar"])
	var cast := _p.resolve(SkillCatalog.by_id("sacred_pillar"), 1)
	var point := Vector2(Player.PLACEMENT_RANGE, 0)
	var below := _target(point)
	var beside := _target(point + Vector2(0, cast.radius + 40.0))
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 2))
	assert_eq(_children_of(SacredPillar)[0].global_position, point, "posé à la portée, devant")

	await wait_seconds(cast.duration + 0.2)
	assert_eq(_hits(below), cast.strikes_over_duration(), "une frappe par période")
	assert_eq(_hits(beside), 0)
	assert_eq(Game.freezes, 0, "ce qui dure ne fige jamais le jeu")
	assert_eq(_children_of(SacredPillar).size(), 0, "puis il s'éteint")


## L'émanation **suit son porteur** : une cible hors de portée au lancer est frappée
## dès que le porteur l'a rejointe. Puis elle finit seule — elle ne se paie pas à la
## seconde, donc elle ne s'éteint pas à la touche.
func test_the_pulse_follows_its_caster_then_ends_on_its_own() -> void:
	_learn("manual_holy", ["holy_pulse"])
	var cast := _p.resolve(SkillCatalog.by_id("holy_pulse"), 1)
	var away := Vector2(400, 0)
	var met := _target(away)
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(2)
	assert_eq(_hits(met), 0, "loin du lanceur, rien")

	_p.global_position = away
	await wait_seconds(cast.period + 0.1)
	assert_gt(_hits(met), 0, "l'émanation est allée avec lui")

	await wait_seconds(cast.duration)
	var still := _p.get_children().filter(
		func(n: Node) -> bool: return n is HolyPulse
	)
	assert_eq(still.size(), 0, "puis elle s'en est allée")


## La clarté verse ses deux lignes : la résistance sur la fiche, la chance de bénir
## dans les facteurs que la hurtbox de la cible lira.
func test_holy_light_raises_resistance_and_the_chance_to_bless() -> void:
	_learn("manual_holy", ["holy_light"])
	var resistance := _p.stats.res_holy
	var blessing := _p.states.chance_factors[StatusEffects.Kind.BLESSING]

	assert_true(Gestures.cast(_p, 2))
	assert_true(_p.lit("holy_light"))
	assert_gt(_p.stats.res_holy, resistance, "la fiche résiste mieux au sacré")
	assert_gt(
		_p.states.chance_factors[StatusEffects.Kind.BLESSING], blessing,
		"et ses coups bénissent plus souvent"
	)

	_p._recharges[2] = 0.0
	assert_true(Gestures.cast(_p, 2))
	assert_false(_p.lit("holy_light"))
	assert_eq(_p.stats.res_holy, resistance, "éteinte, la fiche retrouve ses nombres")


# --------------------------------------------------------------------------
# Manuel nécrotique (jalon 26)
# --------------------------------------------------------------------------

## Une cible qui porte des états : la Peste et la malédiction en posent.
func _wearing_target(position: Vector2) -> Hurtbox:
	var h := _target(position)
	h.states = StatusEffects.new()
	return h


var _authors: Array[StatusEffects] = []


func _on_authored(info: DamageInfo) -> void:
	_authors.append(info.author)


func test_plague_leaves_decay_on_what_it_strikes() -> void:
	_learn("manual_necrotic", ["plague"])
	var target := _wearing_target(_p.global_position + Vector2(60, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(0.6)
	assert_eq(_hits(target), 1)
	assert_true(target.states.active(StatusEffects.Kind.DECAY), "décomposée")


func test_the_curse_marks_its_circle_without_striking() -> void:
	_learn("manual_necrotic", ["putrid_curse"])
	var aim := _p.global_position + Vector2(Player.PLACEMENT_RANGE, 0)
	var inside := _wearing_target(aim + Vector2(30, 0))
	var outside := _wearing_target(aim + Vector2(90, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(2)
	assert_true(inside.states.active(StatusEffects.Kind.CURSED), "maudite")
	assert_false(outside.states.active(StatusEffects.Kind.CURSED), "hors du cercle, non")
	assert_eq(_hits(inside), 0, "une malédiction ne frappe pas")


func test_rise_raises_two_undead_then_refuses_a_third() -> void:
	_learn("manual_necrotic", ["rise"])
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(1)
	assert_eq(Minion.count_of(_p, "rise"), 2)
	_p._recharges[2] = 0.0
	var mana := _p.mana
	assert_false(Gestures.cast(_p, 2), "au complet : refusée")
	assert_eq(_p.mana, mana, "sans rien prendre")


## Un nœud atteint le lancer, donc le plafond : Légion d'os en lève un de plus.
func test_bone_legion_raises_a_third() -> void:
	_learn("manual_necrotic", ["rise", "rise", "rise", "rise_bone_legion"])
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(1)
	assert_eq(Minion.count_of(_p, "rise"), 3)


func test_the_undead_strike_on_behalf_of_the_player() -> void:
	_learn("manual_necrotic", ["rise"])
	var target := _wearing_target(_p.global_position + Vector2(60, 0))
	_authors.clear()
	target.damaged.connect(_on_authored)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(1.5)
	assert_gt(_hits(target), 0, "ils vont frapper ce qui entre dans la zone")
	assert_eq(_authors[0], _p.states, "au nom du joueur : sa pourriture le soignera")


## Son jumeau : ce qui reste hors de la zone du joueur n'est pas poursuivi.
func test_the_undead_leave_alone_what_stays_outside_the_zone() -> void:
	_learn("manual_necrotic", ["rise"])
	var target := _target(_p.global_position + Vector2(200, 0))
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(1.5)
	assert_eq(_hits(target), 0)


func test_the_undead_fall_when_their_book_leaves_the_rack() -> void:
	_learn("manual_necrotic", ["rise"])
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(1)
	_p.stop_studying(0)
	await wait_physics_frames(2)
	assert_eq(Minion.count_of(_p, "rise"), 0)


## Un ennemi frappe le plus proche : le mort-vivant entre lui et le joueur.
func test_an_enemy_turns_on_the_closer_undead() -> void:
	var grunt: Enemy = load("res://actors/enemies/grunt.tscn").instantiate()
	add_child_autofree(grunt)
	grunt.setup(_p)
	grunt.global_position = _p.global_position + Vector2(-100, 0)
	assert_eq(grunt.foe(), _p, "sans mort-vivant, le joueur")
	_learn("manual_necrotic", ["rise"])
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(1)
	assert_true(grunt.foe() is Minion, "le mort-vivant, plus proche")


func test_the_gate_spews_creatures_that_burst_on_an_enemy_in_sight() -> void:
	_learn("manual_necrotic", ["rotting_gate"])
	var aim := _p.global_position + Vector2(Player.PLACEMENT_RANGE, 0)
	var seen := _target(aim + Vector2(60, 0))
	var unseen := _target(aim + Vector2(0, 200))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(1.5)
	assert_gt(_hits(seen), 0, "elles vont exploser dessus")
	assert_eq(_hits(unseen), 0, "hors de vue, elles l'ignorent")


func test_necrosis_gnaws_current_health_and_raises_the_chance_to_rot() -> void:
	_learn("manual_necrotic", ["advanced_necrosis"])
	var before := _p.states.chance_factors[StatusEffects.Kind.ROT]
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(1)
	assert_almost_eq(_p.states.chance_factors[StatusEffects.Kind.ROT], before + 0.10, 0.0001)
	_p.stats.health_regen = 0.0
	var health := _p.health
	await wait_seconds(1.0)
	assert_lt(_p.health, health, "il ronge")
	# Cinq pour cent des PV actuels par seconde depuis le jalon 45, avant la résistance.
	assert_gt(_p.health, health * 0.94, "cinq pour cent par seconde, pas davantage")


# --------------------------------------------------------------------------
# Les manuels de classe (jalon 28)
# --------------------------------------------------------------------------

## Le manuel de la classe à sa place, au plafond, ces points placés, la première
## compétence sur la troisième case.
## Un lancer qui ne porte que ce mot-clé, pour annoncer une mort.
func _blow(keyword: String) -> SkillStats:
	var cast := SkillStats.new()
	cast.keywords = PackedStringArray([keyword])
	return cast


func _learn_class(class_id: String, points: Array) -> void:
	var book := Item.new(Character.CLASSES[class_id]["manual"])
	book.manual.gain_experience(999999)
	_p.rack.seat(book)
	for id: String in points:
		assert_true(_p.invest(Rack.CLASS_SLOT, id), "« %s »" % id)
	_p.bar.put(2, points[0])
	Weapons.arm(_p, points[0])
	_p.stats.max_mana = 9999.0
	_p._set_mana(9999.0)


func test_the_elemental_projectile_takes_each_element_in_turn() -> void:
	_learn_class(Character.WITCH, ["elemental_projectile"])
	var seen: Array[int] = []
	for i in 4:
		_p._recharges[2] = 0.0
		assert_true(Gestures.cast(_p, 2))
		var bolts := _children_of(Projectile)
		seen.append((bolts[-1] as Projectile).nature())
	assert_eq(seen, [
		DamageType.Kind.FIRE, DamageType.Kind.COLD, DamageType.Kind.LIGHTNING, DamageType.Kind.FIRE
	] as Array[int], "le quatrième reprend au feu")


## Personne à portée : refusée, et rien n'est payé.
func test_the_quick_strike_needs_a_prey_in_range() -> void:
	_learn_class(Character.SWIFTBLADE, ["quick_strike"])
	var cast := _p.resolve(SkillCatalog.by_id("quick_strike"), 1)
	var far := _target(Vector2(cast.radius + 40.0, 0))
	await wait_physics_frames(2)
	var mana := _p.mana
	assert_false(Gestures.cast(_p, 2))
	assert_eq(_p.mana, mana, "rien n'est payé")
	assert_eq(_p.remaining_cooldown(2), 0.0, "ni la recharge")
	assert_eq(_hits(far), 0)


## Deux à portée : la visée choisit. On arrive contre elle, et elle seule est frappée.
func test_the_quick_strike_lands_on_the_prey_nearest_the_aim() -> void:
	_learn_class(Character.SWIFTBLADE, ["quick_strike"])
	var above := _target(Vector2(80, -50))
	var below := _target(Vector2(80, 50))
	_p.facing = Vector2(1.0, 0.6).normalized()
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 2))
	assert_eq(_hits(below), 1, "celle que la visée désigne")
	assert_eq(_hits(above), 0, "pas sa voisine")
	assert_almost_eq(
		_p.global_position.distance_to(below.global_position), Player.LUNGE_REACH, 1.0,
		"contre elle"
	)
	assert_eq(_children_of(LungeTrail).size(), 1, "un fil et une entaille")
	await wait_seconds(LungeTrail.LIFETIME + 0.1)
	assert_eq(_children_of(LungeTrail).size(), 0, "qui s'effacent seuls")


## Une charge par ennemi tué **par une attaque**, cinq au plus, et toutes tombent
## ensemble après leur durée. Chacune donne sa part de vitesse d'attaque.
func test_bloodlust_stacks_frenzy_on_attack_kills() -> void:
	_learn_class(Character.SWIFTBLADE, ["bloodlust"])
	var skill := SkillCatalog.by_id("bloodlust")
	var base_speed := _p.stats.attack_speed
	assert_true(Gestures.cast(_p, 2))
	assert_true(_p.lit("bloodlust"))
	assert_eq(_p.lit_stacks("bloodlust"), 0)
	assert_eq(_p.stats.attack_speed, base_speed, "allumée sans charge, rien")

	_p.states.slew.emit(_blow(Keywords.SPELL), Vector2.ZERO, null)
	assert_eq(_p.lit_stacks("bloodlust"), 0, "un sort ne compte pas")
	_p.states.slew.emit(_blow(Keywords.ATTACK), Vector2.ZERO, null)
	assert_eq(_p.lit_stacks("bloodlust"), 1)
	var one := _p.stats.attack_speed
	assert_gt(one, base_speed, "une charge accélère")
	for i in skill.stacks_max + 2:
		_p.states.slew.emit(_blow(Keywords.ATTACK), Vector2.ZERO, null)
	assert_eq(_p.lit_stacks("bloodlust"), skill.stacks_max, "pas plus que le plafond")
	assert_almost_eq(
		_p.stats.attack_speed - base_speed, (one - base_speed) * skill.stacks_max, 1e-4,
		"autant de fois la part d'une charge"
	)

	(_p._lit["bloodlust"] as Buff)._since_stack = skill.stack_duration - 0.001
	await wait_physics_frames(2)
	assert_eq(_p.lit_stacks("bloodlust"), 0, "tombées ensemble")
	assert_eq(_p.stats.attack_speed, base_speed, "et la fiche retrouve ses nombres")
	assert_true(_p.lit("bloodlust"), "la Soif de sang, elle, reste allumée")


## Un buff lancé : il se paie, dure, et le relancer le **refait** au lieu de l'éteindre.
func test_spell_amplification_is_cast_and_refreshed() -> void:
	_learn_class(Character.WITCH, ["elemental_projectile", "spell_amplification"])
	_p.bar.put(3, "spell_amplification")
	var projectile := SkillCatalog.by_id("elemental_projectile")
	var before := _p.resolve(projectile, 1).total_min()

	var mana := _p.mana
	assert_true(Gestures.cast(_p, 3))
	assert_true(_p.lit("spell_amplification"))
	assert_lt(_p.mana, mana, "il se paie")
	assert_almost_eq(_p.resolve(projectile, 1).total_min(), before * 1.2, 1e-3, "20 % amplifiés")
	await wait_physics_frames(10)
	assert_lt(_p.lit_ratio("spell_amplification"), 1.0, "le temps passe")

	_p._recharges[3] = 0.0
	assert_true(Gestures.cast(_p, 3))
	assert_true(_p.lit("spell_amplification"), "relancé, il ne s'éteint pas")
	assert_almost_eq(_p.lit_ratio("spell_amplification"), 1.0, 1e-3, "il repart à zéro")


# --------------------------------------------------------------------------
# Les mécaniques des nœuds (jalon 34)
# --------------------------------------------------------------------------

## Le livre de `_learn()`, mais sur une **copie** de son archétype qui porte ce nœud
## d'essai sous la compétence : le contenu partagé ne bouge pas, et le lancer passe par
## le vrai chemin — investissement, résolution, `cast_slot()`.
func _learn_with(base_id: String, skill_id: String, lines: Array, transforms_to := -1) -> void:
	var base: ItemBase = ItemCatalog.by_id(base_id).duplicate()
	base.manual = base.manual.duplicate()
	var cells: Array[ManualCell] = []
	for cell in base.manual.cells:
		var copy: ManualCell = cell.duplicate()
		if cell.skill != null and cell.skill.id == skill_id:
			var node := TalentNode.new()
			node.id = "trial_node"
			node.name = "trial_node"
			node.points_max = 1
			for pair: Array in lines:
				var line := TalentLine.new()
				line.stat = pair[0]
				line.value_per_point = pair[1]
				line.percentage = pair.size() > 2
				node.lines.append(line)
			if transforms_to >= 0:
				node.transforms = true
				node.shape = transforms_to
			copy.talents = [node] as Array[TalentNode]
		cells.append(copy)
	base.manual.cells = cells
	var book := Item.new(base)
	book.manual.gain_experience(999999)
	_p.study(book, 0)
	assert_true(_p.invest(0, skill_id))
	assert_true(_p.invest(0, "trial_node"))
	_p.bar.put(2, skill_id)
	Weapons.arm(_p, skill_id)
	_p.stats.max_mana = 9999.0
	_p._set_mana(9999.0)


func test_a_piercing_bolt_goes_through_one_and_stops_on_the_next() -> void:
	_learn_with("manual_lightning", "swift_bolt", [[SkillStats.PIERCE, 1.0]])
	var first := _target(Vector2(40, 0))
	var second := _target(Vector2(80, 0))
	var third := _target(Vector2(120, 0))
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(0.6)
	assert_eq(_hits(first), 1, "traversée")
	assert_eq(_hits(second), 1, "frappée, et le tir s'y arrête")
	assert_eq(_hits(third), 0)


func test_a_splitting_bolt_throws_its_shards_past_the_target_once() -> void:
	_learn_with("manual_lightning", "swift_bolt", [[SkillStats.SPLITS, 3.0]])
	var first := _target(Vector2(40, 0))
	var behind := _target(Vector2(90, 0))
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(12)
	assert_eq(_children_of(Projectile).size(), 3, "trois éclats en étoile, le tir parti")
	await wait_seconds(0.5)
	assert_eq(_hits(first), 1, "un éclat ne revient pas sur la cible du tir")
	assert_eq(_hits(behind), 1, "l'éclat de l'axe va plus loin")
	var bolt := _p.resolve(SkillCatalog.by_id("swift_bolt"), 1)
	assert_lt(
		(_received_all[behind] as Array)[0], bolt.total_max() * SkillStats.SPLIT_PART + 0.01,
		"à la part d'un éclat"
	)
	for shard: Projectile in _children_of(Projectile):
		assert_eq(shard._cast.splits, 0.0, "un éclat ne se fend pas")


## La Prise d'air (jalon 42) : plus la boule a volé, plus son explosion est large.
func test_a_swelling_ball_bursts_wider_the_farther_it_flew() -> void:
	_learn_with("manual_fire", "fireball", [[SkillStats.SWELL, 100.0]])
	_target(Vector2(150, 0))
	await wait_physics_frames(2)
	var radius := _p.resolve(SkillCatalog.by_id("fireball"), 1).radius

	# Relevée à la naissance : une explosion ne dure que trois dixièmes de seconde.
	var seen: Array[float] = []
	_effects.child_entered_tree.connect(func(n: Node) -> void:
		if n is Explosion:
			seen.append((n as Explosion)._radius))
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(1.0)
	assert_eq(seen.size(), 1)
	assert_gt(seen[0], radius * 2.0, "plus de 100 px volés : plus du double")


## La Surchauffe : chaque coup pose une charge, et la suivante frappe plus fort par charge.
func test_an_overheating_ball_stacks_its_charges() -> void:
	_learn_with("manual_fire", "fireball", [[SkillStats.OVERHEAT, 10.0]])
	var target := _target(Vector2(40, 0))
	target.states = StatusEffects.new()
	await wait_physics_frames(2)
	var cast := _p.resolve(SkillCatalog.by_id("fireball"), 1)
	assert_eq(cast.against_factor(target.states), 1.0, "rien avant la première boule")

	for i in SkillStats.OVERHEAT_MOST + 1:
		assert_true(Gestures.cast(_p, 2))
		await wait_seconds(0.9)
	var charges := target.states.strength(StatusEffects.Kind.OVERHEAT)
	assert_eq(charges, float(SkillStats.OVERHEAT_MOST), "pas au-delà du plafond")
	assert_almost_eq(cast.against_factor(target.states), 1.3, 0.001, "10 % plus par charge")


## Le Feu nourri : sous un brasier allumé, la boule part plus forte et plus large.
func test_a_fed_ball_grows_only_under_a_lit_aura() -> void:
	_learn_with("manual_fire", "fireball", [[SkillStats.STOKED, 50.0]])
	var cast := _p.resolve(SkillCatalog.by_id("fireball"), 1)
	assert_eq(_p._stoke([cast] as Array[SkillStats])[0], cast, "sans brasier, le même lancer")

	var aura := Node2D.new()
	add_child_autofree(aura)
	_p._lit["immolation"] = aura
	var fed := _p._stoke([cast] as Array[SkillStats])[0]
	assert_almost_eq(fed.total_max(), cast.total_max() * 1.5, 0.01)
	assert_almost_eq(fed.radius, cast.radius * 1.5, 0.01)


## La Convergence : côte à côte au départ, toutes vers le point visé.
func test_converging_balls_meet_on_the_aim() -> void:
	_learn_with("manual_fire", "fireball", [["projectiles", 2.0], [SkillStats.CONVERGE, 1.0]])
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	var aim := _p.global_position + Vector2.RIGHT * Player.PLACEMENT_RANGE
	var balls := _children_of(Fireball)
	assert_eq(balls.size(), 3)
	for ball: Fireball in balls:
		var toward := ball.global_position.direction_to(aim)
		assert_almost_eq(ball._dir.dot(toward), 1.0, 0.001, "chacune vise le même point")
	assert_ne(balls[0].global_position, balls[2].global_position, "parties côte à côte")


## La Pluie de météorites : après l'impact, une couronne de mini-météorites qui tombent.
func test_a_meteor_rains_small_ones_around_its_impact() -> void:
	_learn_with("manual_fire", "fireball", [[SkillStats.METEOR_SHOWER, 3.0]], Skill.Shape.METEOR)
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(Meteor.FALL + 0.05)
	var rain := _children_of(Meteor)
	assert_eq(rain.size(), 3)
	for small: Meteor in rain:
		assert_true(small.small)
		assert_eq(small._cast.meteor_shower, 0.0, "une retombée n'en fait pas tomber d'autres")


## Lancé de l'épaule d'un Familier qui se dissout pendant la chute : le météore éclate une
## fois et s'en va. Avant, l'erreur sur la source libérée le faisait exploser à chaque image.
func test_a_meteor_whose_source_vanished_bursts_once() -> void:
	_learn_with("manual_fire", "fireball", [], Skill.Shape.METEOR)
	var cast := _p.resolve(SkillCatalog.by_id("fireball"), 1)
	var shoulder := Node2D.new()
	add_child(shoulder)
	Meteor.fall(_effects, _p.global_position + Vector2.RIGHT * 60.0, cast, _p.states, shoulder)
	shoulder.free()
	await wait_seconds(Meteor.FALL + 0.05)
	assert_eq(_children_of(Meteor).size(), 0, "le météore est parti")
	assert_eq(_children_of(Explosion).size(), 1, "une seule explosion")


## Le halo d'un souffle se cuit à son rayon final, pas à chaque rayon de son ouverture :
## une nova de 83 px cuisait un halo par image, 6 ms le plus grand.
func test_an_opening_blast_bakes_one_halo() -> void:
	var parts := DamageType.empty_parts()
	parts[DamageType.Kind.COLD] = 1.0
	# Une teinte à lui : le cache des halos est partagé par toute la campagne.
	var tint := Color(0.123, 0.456, 0.789)
	Explosion.put(_effects, _p.global_position, parts, 83.0, null, tint, null, null)
	await wait_seconds(Explosion.LIFETIME)
	var prefix := tint.to_html(false) + "@"
	var halos := EffectForge._scorches.keys().filter(func(k: String) -> bool: return k.begins_with(prefix))
	assert_eq(halos, [prefix + "83@0.20"])


## Le Noyau dense sur un Météore : un « moins », que les +200 % de la chute ne noient pas.
func test_a_dense_core_shrinks_even_a_meteor() -> void:
	_learn("manual_fire", ["fireball", "fireball_stoking", "fireball_stoking", "fireball_stoking", "fireball_meteor"])
	var skill := SkillCatalog.by_id("fireball")
	var meteor := _p.resolve(skill, 1)
	assert_true(_p.invest(0, "fireball_dense_core"))
	assert_almost_eq(_p.resolve(skill, 1).radius, meteor.radius * 0.25, 0.01)


## Le Météore coûte la moitié en plus, et la barre le sait.
func test_a_meteor_costs_half_again() -> void:
	_learn("manual_fire", ["fireball", "fireball_stoking", "fireball_stoking", "fireball_stoking"])
	var skill := SkillCatalog.by_id("fireball")
	var cost := _p.cost_of(skill)
	assert_true(_p.invest(0, "fireball_meteor"))
	assert_almost_eq(_p.resolve(skill, 1).mana_cost, cost * 1.5, 0.01)
	assert_almost_eq(_p.cost_of(skill), cost * 1.5, 0.01, "le cache de la barre est vidé")


## La Déflagration : le rayon de l'explosion suit ce qui vise la zone, ses dégâts non.
func test_a_deflagration_opens_the_radius_to_area_lines() -> void:
	var skill := SkillCatalog.by_id("fireball")
	_learn_with("manual_fire", "fireball", [[SkillStats.WIDE_BLAST, 1.0]])
	var plain := _p.resolve(skill, 1)
	_p.skill_mods.assign([
		StatMod.new("radius", StatMod.Mode.PERCENT, 100.0, Keywords.AREA),
		StatMod.new("damage", StatMod.Mode.PERCENT, 100.0, Keywords.AREA),
	])
	var wide := _p.resolve(skill, 1)
	assert_almost_eq(wide.radius, plain.radius * 2.0, 0.01)
	assert_almost_eq(wide.total_max(), plain.total_max(), 0.01, "les dégâts de zone restent dehors")
	assert_false(wide.keywords.has(Keywords.AREA), "et la boule ne devient pas une zone")


## Le Gonflement : la boule touche plus large en volant, sans toucher la forme de la scène.
func test_a_swelling_ball_grows_its_hit_shape() -> void:
	_learn_with("manual_fire", "fireball", [[SkillStats.GIRTH, 100.0]])
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(0.4)
	var ball: Fireball = _children_of(Fireball)[0]
	assert_gt(ball.size(), 1.5)
	assert_almost_eq(ball._hit_shape.radius, ball._hit_radius * ball.size(), 0.01)
	await wait_seconds(0.8)
	assert_eq(ball.size(), SkillStats.GIRTH_MOST, "plafonnée")
	var probe := (load("res://actors/projectiles/player_fireball.tscn") as PackedScene).instantiate()
	var scene_radius: float = (probe.get_node("CollisionShape2D").shape as CircleShape2D).radius
	probe.free()
	assert_eq(scene_radius, ball._hit_radius, "la forme de la scène n'a pas grandi")


## Les Éclats en cascade : un éclat se fend à son tour, une fois.
func test_cascading_shards_split_once_more() -> void:
	var cast := _p.resolve(SkillCatalog.by_id("fireball"), 1)
	cast.splits = 3.0
	assert_eq(cast.shard().splits, 0.0, "sans cascade, un éclat ne se fend pas")
	cast.split_cascade = 1.0
	assert_eq(cast.shard().splits, 3.0)
	assert_eq(cast.shard().shard().splits, 0.0, "une seule fois")


## La Poudrière : l'explosion d'un tué embrase à coup sûr ce qu'elle touche.
func test_a_powder_keg_burst_always_ignites() -> void:
	var cast := _p.resolve(SkillCatalog.by_id("fireball"), 1)
	cast.kill_burst = 30.0
	cast.powder_keg = 1.0
	var near := _target(Vector2(50, 0))
	near.states = StatusEffects.new()
	await wait_physics_frames(2)
	_p.states.slew.emit(cast, Vector2(40, 0), _ignited())
	await wait_physics_frames(3)
	assert_eq(_hits(near), 1)
	assert_true(near.states.active(StatusEffects.Kind.IGNITE), "embrasé, sans tirage perdu")


## Traversée, la boule éclate aussi : sur chaque ennemi traversé, en étoile tournée d'un
## demi-pas pour laisser l'axe au tir, qui continue et frappe seul l'ennemi suivant.
func test_a_piercing_bolt_also_splits_on_what_it_goes_through() -> void:
	_learn_with("manual_lightning", "swift_bolt", [[SkillStats.PIERCE, 1.0], [SkillStats.SPLITS, 3.0]])
	var first := _target(Vector2(40, 0))
	var second := _target(Vector2(160, 0))
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(12)
	assert_eq(_hits(first), 1)
	assert_eq(_children_of(Projectile).size(), 4, "le tir continue, trois éclats partis de la cible traversée")
	for bolt: Projectile in _children_of(Projectile):
		if bolt._cast.splits == 0.0:
			assert_gt(absf(bolt._dir.angle()), 0.1, "aucun éclat dans l'axe du tir")
	await wait_seconds(0.8)
	assert_eq(_hits(second), 1, "l'ennemi suivant, frappé par le tir seul")


## La transformation : le lancer se pose par sa forme, et ses mots-clés la suivent. Elle
## apporte les nombres de sa forme — un trait n'a pas de rayon.
func test_a_transformed_bolt_bursts_around_its_caster() -> void:
	_learn_with("manual_lightning", "swift_bolt", [["radius", 40.0]], Skill.Shape.NOVA)
	var cast := _p.resolve(SkillCatalog.by_id("swift_bolt"), 1)
	assert_eq(cast.shape, Skill.Shape.NOVA)
	assert_false(cast.keywords.has(Keywords.PROJECTILE), "plus un projectile")
	assert_true(cast.keywords.has(Keywords.AREA), "une surface")

	var beside := _target(Vector2(0, 20))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(3)
	assert_eq(_children_of(Projectile).size(), 0, "aucun tir")
	assert_eq(_hits(beside), 1, "la nova frappe à côté")


## Le Météore : rien pendant la chute, puis l'éclatement de la boule au point visé.
func test_a_meteor_falls_then_bursts_on_the_aim() -> void:
	_learn_with("manual_fire", "fireball", [], Skill.Shape.METEOR)
	var below := _target(Vector2(Player.PLACEMENT_RANGE, 0))
	var aside := _target(Vector2(0, 60))
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 2))
	assert_eq(_children_of(Meteor).size(), 1)
	assert_eq(_children_of(Projectile).size(), 0, "rien ne vole")
	await wait_seconds(Meteor.FALL * 0.5)
	assert_eq(_hits(below), 0, "pas pendant la chute")
	Game.hit_stop_duration = 0.05
	Game.hit_stop_period = 0.0
	var freezes := Game.freezes
	await wait_seconds(Meteor.FALL)
	assert_eq(_hits(below), 1, "l'éclatement, une fois")
	assert_gt(Game.freezes, freezes, "et l'impact se sent")
	assert_eq(_hits(aside), 0)
	assert_eq(_children_of(Meteor).size(), 0)


## Double langue sur un météore : une rangée en travers de la visée, pas un seul plus fort.
func test_extra_balls_fall_as_a_row_of_meteors() -> void:
	_learn_with("manual_fire", "fireball", [["projectiles", 2.0]], Skill.Shape.METEOR)
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	var meteors := _children_of(Meteor)
	assert_eq(meteors.size(), 3)
	var gap: float = meteors[0].global_position.distance_to(meteors[1].global_position)
	var radius := _p.resolve(SkillCatalog.by_id("fireball"), 1).radius
	assert_almost_eq(gap, radius, 0.01, "à un rayon l'un de l'autre")


## Fragmentation sur un météore : l'étoile d'éclats jaillit du point d'impact.
func test_a_meteor_throws_its_shards_from_the_impact() -> void:
	_learn_with("manual_fire", "fireball", [[SkillStats.SPLITS, 3.0]], Skill.Shape.METEOR)
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	var impact: Vector2 = _children_of(Meteor)[0].global_position
	await wait_seconds(Meteor.FALL + 0.05)
	var shards := _children_of(Fireball)
	assert_eq(shards.size(), 3)
	for shard: Fireball in shards:
		assert_true(shard.is_shard)
		assert_lt(shard.global_position.distance_to(impact), 40.0, "partis de l'impact")


## Le Bond : ni traînée ni coup en chemin, l'arc et l'explosion à l'arrivée.
func test_a_leap_leaves_no_trail_and_bursts_where_it_lands() -> void:
	_learn_with("manual_fire", "flame_dash", [[SkillStats.END_BURST, 30.0]], Skill.Shape.LEAP)
	var on_the_way := _target(Vector2(40, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(2)
	assert_eq(_children_of(DashTrail).size(), 0, "pas de traînée")
	assert_eq(_children_of(LeapArc).size(), 1)
	assert_eq(_children_of(Explosion).size(), 1)
	await wait_seconds(0.5)
	assert_eq(_hits(on_the_way), 0, "rien ne frappe en chemin")


## Les éclats de la boule sont des mini-boules, pas des boules entières.
func test_the_shards_of_a_ball_are_drawn_small() -> void:
	_learn_with("manual_fire", "fireball", [[SkillStats.SPLITS, 3.0]])
	_target(Vector2(40, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(14)
	var shards := _children_of(Fireball)
	assert_eq(shards.size(), 3)
	for shard: Fireball in shards:
		assert_true(shard.is_shard)


func test_a_brood_drops_two_snakes_fanned_on_the_aim() -> void:
	_learn_with("manual_fire", "hell_snake", [[SkillStats.BROOD, 1.0]])
	assert_true(Gestures.cast(_p, 2))
	var snakes := _children_of(HellSnake)
	assert_eq(snakes.size(), 2)
	assert_ne((snakes[0] as HellSnake)._cap, (snakes[1] as HellSnake)._cap, "en éventail")


## Vif : sa vitesse à lui, accrue en points de pourcentage — pas celle d'un projectile.
func test_a_swift_snake_crawls_faster() -> void:
	_learn_with("manual_fire", "hell_snake", [[SkillStats.CRAWL_SPEED, 100.0]])
	assert_true(Gestures.cast(_p, 2))
	var snake: HellSnake = _children_of(HellSnake)[0]
	var travelled := 0.0
	var last := snake._head
	var from_frame := Engine.get_physics_frames()
	for i in 10:
		await wait_physics_frames(1)
		travelled += snake._head.distance_to(last)
		last = snake._head
	var frames := Engine.get_physics_frames() - from_frame
	var expected := HellSnake.SPEED * 2.0 * float(frames) / float(Engine.physics_ticks_per_second)
	assert_almost_eq(travelled, expected, expected * 0.05, "deux fois la vitesse")


func test_a_hunting_snake_takes_the_nearest_enemy_for_anchor() -> void:
	_learn_with("manual_fire", "hell_snake", [[SkillStats.SEEK, 200.0]])
	var prey := _target(Vector2(Player.PLACEMENT_RANGE, 90))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(2)
	var snake: HellSnake = _children_of(HellSnake)[0]
	assert_eq(snake._anchor, prey.global_position)


## Sa mort : les petits, qui n'en relâchent pas d'autres. L'explosion finale est partie à la
## Ruée ardente avec la Mue explosive (jalon 42).
func test_a_dying_snake_hatches() -> void:
	_learn_with("manual_fire", "hell_snake", [
		[SkillStats.HATCHLINGS, 2.0], ["duration", -90.0, true],
	])
	assert_true(Gestures.cast(_p, 2))
	var snake: HellSnake = _children_of(HellSnake)[0]
	while is_instance_valid(snake):
		await wait_physics_frames(1)
	await wait_physics_frames(1)
	assert_eq(_children_of(Explosion).size(), 0, "plus d'explosion finale")
	assert_eq(_children_of(HellSnake).size(), 2, "deux petits")
	var hatchling: HellSnake = _children_of(HellSnake)[0]
	assert_eq(hatchling._cast.hatchlings, 0.0, "qui ne se diviseront pas")
	assert_eq(hatchling._cast.duration, SkillStats.HATCHLING_LIFE)
	assert_eq(hatchling._size, HellSnake.HATCHLING_SIZE, "plus petits que leur parent")


## Le Venin d'hydre : des petits qui vivent et mordent plus.
func test_hydra_venom_feeds_the_young() -> void:
	_learn_with("manual_fire", "hell_snake", [
		[SkillStats.HATCHLINGS, 2.0], [SkillStats.HATCHLING_TIME, 1.0], [SkillStats.HATCHLING_BITE, 50.0],
	])
	var cast := _p.resolve(SkillCatalog.by_id("hell_snake"), 1)
	var young := cast.hatchling()
	assert_eq(young.duration, SkillStats.HATCHLING_LIFE + 1.0)
	assert_almost_eq(young.total_max(), cast.total_max() * SkillStats.SPLIT_PART * 1.5, 1e-3)
	assert_eq(young.hatchling_bite, 0.0, "le venin ne passe pas aux petits des petits")


## La Gloutonnerie : chaque proie de **ce** serpent le grossit, cinq au plus — les tués d'un
## autre lancer ne comptent pas, fût-ce son frère de couvée.
func test_a_gluttonous_snake_grows_on_its_own_prey() -> void:
	_learn_with("manual_fire", "hell_snake", [[SkillStats.GLUTTONY, 10.0], [SkillStats.BROOD, 1.0]])
	assert_true(Gestures.cast(_p, 2))
	var snakes := _children_of(HellSnake)
	var fed: HellSnake = snakes[0]
	var other: HellSnake = snakes[1]
	assert_ne(fed._cast, other._cast, "chacun son lancer")
	var life := fed.lifetime()
	for i in SkillStats.GLUTTONY_MOST + 2:
		_p.states.slew.emit(fed._cast, Vector2.ZERO, null)
	assert_eq(fed._preys, SkillStats.GLUTTONY_MOST, "cinq proies au plus")
	assert_eq(other._preys, 0)
	assert_almost_eq(fed.lifetime(), life + SkillStats.GLUTTONY_LIFE * SkillStats.GLUTTONY_MOST, 1e-4)
	assert_gt(fed._size, 1.0, "il grossit")
	var before := Game.rng.state
	var plain := fed._cast.roll(Game.rng)
	Game.rng.state = before
	assert_almost_eq(fed._bite_parts()[DamageType.Kind.FIRE], plain[DamageType.Kind.FIRE] * 1.5, 1e-3, "et mord plus fort")


## La Mue de croissance : à la cinquième proie, une gerbe, et tout recommence.
func test_a_sated_snake_molts() -> void:
	_learn_with("manual_fire", "hell_snake", [[SkillStats.GLUTTONY, 10.0], [SkillStats.GROWTH_MOLT, 1.0]])
	assert_true(Gestures.cast(_p, 2))
	var snake: HellSnake = _children_of(HellSnake)[0]
	await wait_physics_frames(10)
	for i in SkillStats.GLUTTONY_MOST:
		_p.states.slew.emit(snake._cast, Vector2.ZERO, null)
	await wait_physics_frames(1)
	assert_eq(_children_of(Explosion).size(), 1, "la gerbe")
	assert_eq(snake._preys, 0, "il recommence à grossir")
	assert_eq(snake._size, 1.0)
	assert_lt(snake._age, 0.1, "sa vie entière")


## La Constriction : il s'enroule autour de sa première proie et y mord deux fois plus
## vite ; sous l'Étau, elle ne bouge plus — jusqu'à ce qu'il la lâche.
func test_a_constricting_snake_coils_and_holds_its_prey() -> void:
	_learn_with("manual_fire", "hell_snake", [[SkillStats.CONSTRICT, 1.0], [SkillStats.VISE, 1.0]])
	var prey := _target(Vector2(Player.PLACEMENT_RANGE, 0))
	prey.states = StatusEffects.new()
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	var snake: HellSnake = _children_of(HellSnake)[0]
	await wait_physics_frames(3)
	assert_eq(snake._coiled, prey, "la première mordue")
	assert_eq(prey.states.speed_factor, 0.0, "tenue")
	await wait_seconds(1.0)
	assert_almost_eq(snake._head.distance_to(prey.global_position), HellSnake.COIL, 0.5, "enroulé")
	assert_almost_eq(float(_hits(prey)), 1.0 + 1.0 / (snake._cast.period * 0.5), 1.0, "deux fois plus vite")
	snake.free()
	assert_eq(prey.states.speed_factor, 1.0, "lâchée")


## L'Ouroboros tourne autour du point visé ; la Spirale resserre l'anneau.
func test_an_ouroboros_circles_the_aim_and_a_spiral_tightens() -> void:
	_learn_with("manual_fire", "hell_snake", [[SkillStats.OUROBOROS, 1.0], [SkillStats.SEEK, 300.0]])
	_target(Vector2(Player.PLACEMENT_RANGE + 150, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	var snake: HellSnake = _children_of(HellSnake)[0]
	var aim := snake._anchor
	for i in 10:
		await wait_physics_frames(6)
		assert_almost_eq(snake._head.distance_to(aim), HellSnake.OUROBOROS_RING, 0.5, "sur l'anneau, sans chasser")
	snake._cast.spiral = 1.0
	snake._age = snake.lifetime() * 0.5
	await wait_physics_frames(1)
	assert_lt(snake._head.distance_to(aim), HellSnake.OUROBOROS_RING * 0.7, "resserré")


## Le Crachat : une petite boule vers la proie à portée, en éventail sous la Gerbe — et rien
## sans proie.
func test_a_spitting_snake_fires_at_the_nearest_prey() -> void:
	_learn_with("manual_fire", "hell_snake", [[SkillStats.SPIT, 30.0], [SkillStats.SPIT_FAN, 2.0]])
	assert_true(Gestures.cast(_p, 2))
	var snake: HellSnake = _children_of(HellSnake)[0]
	await wait_seconds(SkillStats.SPIT_PERIOD + 0.1)
	assert_eq(_children_of(Fireball).size(), 0, "personne à portée")
	_target(snake._head + Vector2(0, SkillStats.SPIT_REACH * 0.8))
	await wait_physics_frames(3)
	var balls := _children_of(Fireball)
	assert_eq(balls.size(), 3, "une boule et deux de Gerbe")
	var ball: Fireball = balls[0]
	assert_true(ball.is_shard, "la petite boule")
	assert_between(ball._parts[DamageType.Kind.FIRE], snake._cast.total_min() * 0.3, snake._cast.total_max() * 0.3, "30 % d'une morsure")


## Trois serpents par lanceur : relancer dissout les plus anciens, sans éclat ni petits.
func test_a_fourth_snake_dissolves_the_oldest() -> void:
	_learn("manual_fire", [
		"hell_snake", "hell_snake_molting", "hell_snake_molting", "hell_snake_brood",
		"hell_snake_brood", "hell_snake_hydra",
	])
	assert_true(Gestures.cast(_p, 2))
	assert_eq(_crawling().size(), 3, "la Couvée remplit la limite d'un coup")
	var first: Array = _crawling()
	_p._recharges[2] = 0.0
	assert_true(Gestures.cast(_p, 2))
	assert_eq(_crawling().size(), 3)
	for old: HellSnake in first:
		assert_true(old._vanishing, "les trois plus anciens")
	await wait_seconds(HellSnake.DISSIPATION + 0.1)
	assert_eq(_children_of(HellSnake).size(), 3, "dissous, sans petits")
	assert_eq(_children_of(Explosion).size(), 0)


## Le corbeau qui rejoue le Serpent a sa propre limite : six en tout.
func test_the_familiar_has_its_own_three_snakes() -> void:
	_learn_class(Character.WITCH, ["elemental_projectile", "familiar"])
	_p.bar.put(3, "familiar")
	assert_true(Gestures.cast(_p, 3))
	_learn("manual_fire", ["hell_snake", "hell_snake_molting", "hell_snake_molting", "hell_snake_brood", "hell_snake_brood"])
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(Familiar.ECHO_DELAY + 0.05)
	assert_eq(_crawling().size(), 6, "trois à vous, trois au corbeau")
	_p._recharges[2] = 0.0
	assert_true(Gestures.cast(_p, 2))
	assert_eq(_crawling().size(), 6, "les vôtres seuls se renouvellent")


func _crawling() -> Array:
	return _children_of(HellSnake).filter(func(s: HellSnake) -> bool: return not s._vanishing)


func test_a_dash_bursts_where_it_lands() -> void:
	_learn_with("manual_fire", "flame_dash", [[SkillStats.END_BURST, 30.0]])
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(2)
	var burst: Array = _children_of(Explosion)
	assert_eq(burst.size(), 1)
	assert_eq((burst[0] as Explosion).global_position, _p.global_position, "à l'arrivée")


## Le Départ en trombe : la même explosion, aussi d'où l'on part, à une part de sa force.
func test_a_flying_start_bursts_at_both_ends() -> void:
	_learn_with("manual_fire", "flame_dash", [[SkillStats.END_BURST, 30.0], [SkillStats.FLYING_START, 50.0]])
	var from_value := _p.global_position
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(2)
	var at := _children_of(Explosion).map(func(e: Explosion) -> Vector2: return e.global_position)
	assert_eq(at.size(), 2)
	assert_true(at.has(from_value), "au départ")
	assert_true(at.has(_p.global_position), "et à l'arrivée")


## La Mèche : la traînée éteinte, ses plaques explosent l'une après l'autre, du départ à
## l'arrivée ; la Mèche courte l'allume tout de suite, et la traînée part avec elle.
func test_a_wick_runs_along_the_spent_trail() -> void:
	_learn_with("manual_fire", "flame_dash", [[SkillStats.WICK, 50.0]])
	var cast := _p.resolve(SkillCatalog.by_id("flame_dash"), 1)
	var from_value := _p.global_position
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(cast.duration - 0.1)
	assert_eq(_children_of(Explosion).size(), 0, "pas avant l'extinction")
	for i in 30:
		if not _children_of(Explosion).is_empty():
			break
		await wait_physics_frames(1)
	var first: Array = _children_of(Explosion)
	assert_eq(first.size(), 1, "la première plaque")
	assert_eq((first[0] as Explosion).global_position, from_value, "au départ")
	await wait_seconds(0.5)
	assert_eq(_children_of(DashTrail).size(), 0, "la traînée finit avec sa mèche")

	var trail := DashTrail.leave(_effects, Vector2.ZERO, Vector2(100, 0), cast, _p.states)
	cast.short_fuse = 1.0
	await wait_physics_frames(2)
	assert_gt(_children_of(Explosion).size(), 0, "la mèche courte, tout de suite")
	await wait_seconds(0.5)
	assert_false(is_instance_valid(trail), "et la traînée part avec elle")


## La Seconde foulée : relancer dans la fenêtre est gratuit et ne relance pas la recharge,
## une fois ; la Foulée de feu la rend plus forte.
func test_a_second_stride_is_free_once() -> void:
	_learn_with("manual_fire", "flame_dash", [[SkillStats.SECOND_STRIDE, 1.0], [SkillStats.STRIDE_FIRE, 50.0]])
	assert_true(Gestures.cast(_p, 2))
	var mana := _p.mana
	var left := _p.remaining_cooldown(2)
	assert_gt(left, 0.0)
	assert_true(Gestures.cast(_p, 2), "relancée pendant la recharge")
	assert_eq(_p.mana, mana, "sans coût")
	assert_almost_eq(_p.remaining_cooldown(2), left, 0.001, "sans relancer la recharge")
	assert_false(Gestures.cast(_p, 2), "une fois")


## La touche tenue relance à chaque image où elle le peut : elle dépensait la seconde ruée
## juste après la première, au même point. Il faut un nouvel appui.
func test_a_held_key_keeps_the_second_stride_for_a_new_press() -> void:
	_learn_with("manual_fire", "flame_dash", [[SkillStats.SECOND_STRIDE, 1.0]])
	var press := InputEventAction.new()
	press.action = "skill_3"
	press.pressed = true
	Input.parse_input_event(press)
	await wait_physics_frames(5)
	assert_gt(_p.remaining_cooldown(2), 0.0, "la première ruée est partie")
	assert_true(_p._strides.has(2), "la seconde attend un nouvel appui")
	Input.action_release("skill_3")
	await wait_physics_frames(1)
	Input.parse_input_event(press)
	await wait_physics_frames(2)
	assert_false(_p._strides.has(2), "le nouvel appui la lance")


## Le Charmeur : un serpent surgit à l'arrivée si l'on sait le lancer ; la Danse du
## charmeur rappelle ceux qui sont déjà en jeu.
func test_a_charmer_raises_a_snake_where_it_lands() -> void:
	_learn_with("manual_fire", "flame_dash", [[SkillStats.CHARMER, 1.0], [SkillStats.SNAKE_DANCE, 1.0]])
	assert_true(Gestures.cast(_p, 2))
	assert_eq(_children_of(HellSnake).size(), 0, "sans Serpent infernal appris, rien")
	assert_true(_p.invest(0, "hell_snake"))
	var old := HellSnake.drop(_effects, Vector2(-200, 0), _p.resolve(SkillCatalog.by_id("hell_snake"), 1), Vector2.RIGHT, _p.states, _p)
	_p._recharges[2] = 0.0
	assert_true(Gestures.cast(_p, 2))
	assert_eq(_children_of(HellSnake).size(), 2, "un de plus, à l'arrivée")
	assert_eq(old._anchor, _p.global_position, "l'ancien rappelé")


## L'Onde brûlante : l'atterrissage du bond projette l'anneau de feu, à deux rayons.
func test_a_burning_wave_spreads_from_the_leap() -> void:
	_learn_with("manual_fire", "flame_dash", [[SkillStats.END_BURST, 30.0], [SkillStats.BURNING_WAVE, 40.0]], Skill.Shape.LEAP)
	assert_true(Gestures.cast(_p, 2))
	var rings := _children_of(FrostRing)
	assert_eq(rings.size(), 1)
	var ring: FrostRing = rings[0]
	await wait_seconds(FrostRing.LIFETIME - 0.05)
	assert_almost_eq(ring.reach(), 30.0 * SkillStats.BURNING_WAVE_REACH, 1.0)


func _ignited() -> StatusEffects:
	var victim := StatusEffects.new()
	victim.put(StatusEffects.Kind.IGNITE, 1.0)
	return victim


## L'explosion d'un tué : seulement sous un embrasé, à la part d'un coup.
func test_an_ignited_kill_bursts() -> void:
	var cast := _p.resolve(SkillCatalog.by_id("fireball"), 1)
	cast.kill_burst = 30.0
	var near := _target(Vector2(50, 0))
	await wait_physics_frames(2)

	_p.states.slew.emit(cast, Vector2(40, 0), StatusEffects.new())
	await wait_physics_frames(3)
	assert_eq(_hits(near), 0, "un tué qui ne brûlait pas n'explose pas")
	_p.states.slew.emit(cast, Vector2(40, 0), _ignited())
	await wait_physics_frames(3)
	assert_eq(_hits(near), 1)
	assert_lt(
		(_received_all[near] as Array)[0],
		cast.total_max() * SkillStats.KILL_BURST_PART * cast.crit_multiplier + 0.01
	)


## Converti, le lancer fait exploser les tués qui portent **l'état de sa nature** : un
## brasier devenu nécrotique, les pourrissants — plus les embrasés (jalon 34).
func test_a_converted_kill_burst_follows_the_nature() -> void:
	var cast := _p.resolve(SkillCatalog.by_id("immolation"), 1)
	cast.kill_burst = 30.0
	cast.nature = DamageType.Kind.NECROTIC
	var near := _target(Vector2(50, 0))
	await wait_physics_frames(2)

	_p.states.slew.emit(cast, Vector2(40, 0), _ignited())
	await wait_physics_frames(3)
	assert_eq(_hits(near), 0, "un embrasé n'explose plus")
	var rotting := StatusEffects.new()
	rotting.put(StatusEffects.Kind.ROT, 1.0)
	_p.states.slew.emit(cast, Vector2(40, 0), rotting)
	await wait_physics_frames(3)
	assert_eq(_hits(near), 1, "un pourrissant, si")



# --------------------------------------------------------------------------
# Les arbres de la foudre (jalon 35)
# --------------------------------------------------------------------------

## Rebond : le tir repart de l'ennemi touché vers le plus proche qu'il n'a pas frappé.
func test_a_bouncing_bolt_leaps_to_the_nearest_unstruck_enemy() -> void:
	_learn_with("manual_lightning", "swift_bolt", [[SkillStats.BOUNCES, 1.0]])
	var first := _target(Vector2(40, 0))
	var off_axis := _target(Vector2(60, 60))
	var behind := _target(Vector2(200, 0))
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(0.8)
	assert_eq(_hits(first), 1)
	assert_eq(_hits(off_axis), 1, "le rebond, hors de l'axe du tir")
	assert_eq(_hits(behind), 0, "un seul rebond, et le tir s'y arrête")


## Ni portée de saut : le rebond va plus loin que les 90 px d'un saut de chaîne, tant que
## la course du tir l'y porte.
func test_a_bolt_bounces_beyond_a_chain_jump() -> void:
	_learn_with("manual_lightning", "swift_bolt", [[SkillStats.BOUNCES, 1.0]])
	var first := _target(Vector2(60, 0))
	var far_aside := _target(Vector2(60, ChainLightning.JUMP + 60.0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(1.2)
	assert_eq(_hits(first), 1)
	assert_eq(_hits(far_aside), 1)


## Sans cône : le rebond repart aussi vers l'arrière, à plus de 90°.
func test_a_bolt_bounces_backward() -> void:
	_learn_with("manual_lightning", "swift_bolt", [[SkillStats.BOUNCES, 1.0]])
	var first := _target(Vector2(60, 0))
	var behind_it := _target(Vector2(20, 45))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(0.8)
	assert_eq(_hits(first), 1)
	assert_eq(_hits(behind_it), 1, "à 132° de l'axe du tir")


## Le Trait de glace est dessiné — ni pivoté, ni additif ; le tir de froid d'un caster
## reste tracé, pour qu'on le distingue du sien (jalon 35).
func test_the_glacial_bolt_is_drawn_and_the_enemy_bolt_is_not() -> void:
	_learn("manual_lightning", [
		"swift_bolt", "swift_bolt_overload", "swift_bolt_overload", "swift_bolt_glacial_bolt",
	])
	_p.facing = Vector2(1.0, 1.0).normalized()
	assert_true(Gestures.cast(_p, 2))
	var bolt: Projectile = _children_of(Projectile)[0]
	assert_eq(bolt.nature(), DamageType.Kind.COLD)
	assert_eq(bolt.rotation, 0.0, "une planche ne pivote pas")
	assert_null(bolt.material, "ni lumière ajoutée")

	var enemy := Projectile.spawn_of_nature(
		_effects, load("res://actors/projectiles/enemy_bolt.tscn"), Vector2(0, 80), Vector2(1, 1), 5.0, null
	)
	assert_eq(enemy.nature(), DamageType.Kind.COLD)
	assert_ne(enemy.rotation, 0.0, "le tir ennemi reste un tracé qui pivote")


func test_a_taut_arc_jumps_farther() -> void:
	_learn_with("manual_lightning", "chain_lightning", [[SkillStats.JUMP_REACH, 40.0]])
	var near := _target(Vector2(60, 0))
	var far := _target(Vector2(60 + ChainLightning.JUMP + 20.0, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	assert_eq(_hits(near), 1)
	assert_eq(_hits(far), 1, "au-delà d'un saut ordinaire")


## Crescendo : le même tirage, plus fort à chaque saut.
func test_each_jump_of_a_crescendo_hits_harder() -> void:
	_learn_with("manual_lightning", "chain_lightning", [[SkillStats.JUMP_GAIN, 50.0]])
	_p.skill_mods.assign([StatMod.new("crit_chance", StatMod.Mode.PERCENT, -100.0)])
	var targets := [_target(Vector2(60, 0)), _target(Vector2(120, 0)), _target(Vector2(180, 0))]
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	var first := float(_received_all[targets[0]][0])
	assert_almost_eq(float(_received_all[targets[1]][0]), first * 1.5, 0.001)
	assert_almost_eq(float(_received_all[targets[2]][0]), first * 2.0, 0.001)


## La Toile d'arcs : pas de cône ni de saut, les plus proches autour du lanceur.
func test_an_arc_web_strikes_the_nearest_all_around() -> void:
	_learn_with("manual_lightning", "chain_lightning", [], Skill.Shape.WEB)
	var ahead := _target(Vector2(60, 0))
	var behind := _target(Vector2(-60, 0))
	var far_from_all := _target(Vector2(0, ChainLightning.SCOPE + 30.0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	assert_eq(_hits(ahead), 1)
	assert_eq(_hits(behind), 1, "derrière, hors du cône d'une chaîne")
	assert_eq(_hits(far_from_all), 0)
	assert_eq(_children_of(ChainLightning).size(), 2, "un arc par cible")


func test_a_wandering_cloud_drifts_toward_the_nearest_enemy() -> void:
	_learn_with("manual_lightning", "storm_cloud", [[SkillStats.SEEK, 200.0]])
	var prey := _target(Vector2(Player.PLACEMENT_RANGE, 100))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	var cloud: StormCloud = _children_of(StormCloud)[0]
	var before := cloud.global_position.distance_to(prey.global_position)
	await wait_seconds(0.5)
	assert_lt(cloud.global_position.distance_to(prey.global_position), before - 10.0)


## L'Orage portatif se forme sur le lanceur et le suit.
func test_a_portable_storm_follows_its_caster() -> void:
	_learn_with("manual_lightning", "storm_cloud", [], Skill.Shape.TEMPEST)
	assert_true(Gestures.cast(_p, 2))
	var cloud: StormCloud = _children_of(StormCloud)[0]
	assert_eq(cloud.global_position, _p.global_position)
	_p.global_position += Vector2(50, 20)
	await wait_physics_frames(2)
	assert_eq(cloud.global_position, _p.global_position)


## L'Orbe statique : rien ne vole en tir, et l'orbe frappe en passant sans s'arrêter.
## Ses nombres viennent de sa forme (`Skill.SHAPE_NUMBERS`) : un trait n'en a pas.
func test_a_static_orb_shocks_what_it_passes_by() -> void:
	_learn_with("manual_lightning", "swift_bolt", [["projectile_speed", -60.0, true]], Skill.Shape.ORB)
	var cast := _p.resolve(SkillCatalog.by_id("swift_bolt"), 1)
	assert_gt(cast.duration, 0.0)
	assert_gt(cast.period, 0.0)
	assert_true(cast.keywords.has(Keywords.PROJECTILE))
	var on_the_way := _target(Vector2(80, 10))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	assert_eq(_children_of(Projectile).size(), 0, "pas de tir")
	var orb: StaticOrb = _children_of(StaticOrb)[0]
	await wait_seconds(1.4)
	assert_gt(_hits(on_the_way), 1, "plusieurs décharges en passant")
	assert_true(is_instance_valid(orb), "et l'orbe continue")
	assert_gt(orb.global_position.x, 110.0)


func test_a_storm_dash_scatters_static_charges_on_its_path() -> void:
	_learn_with("manual_lightning", "storm_dash", [[SkillStats.TRAIL_CHARGES, 4.0]])
	var from_value := _p.global_position
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(2)
	var charges := _children_of(StaticCharge)
	assert_eq(charges.size(), 4)
	for charge: StaticCharge in charges:
		assert_lt(charge.global_position.x, _p.global_position.x, "sur le trajet")
		assert_gt(charge.global_position.x, from_value.x)


## Le drain d'un buff se lit sur le lancer résolu : un nœud le change.
func test_a_buff_drains_what_its_tree_leaves() -> void:
	_learn_with("manual_lightning", "static_electricity", [["mana_per_second", -50.0, true]])
	assert_true(Gestures.cast(_p, 2))
	# Après l'allumage, qui refait la fiche et sa régénération.
	_p.stats.mana_regen = 0.0
	var mana := _p.mana
	await wait_seconds(1.0)
	var drained := mana - _p.mana
	var full := SkillCatalog.by_id("static_electricity").mana_per_second
	assert_almost_eq(drained, full * 0.5, full * 0.1)


# --------------------------------------------------------------------------
# Les arbres du froid (jalon 36)
# --------------------------------------------------------------------------

## Éclats : en retombant, l'étoile part du cercle et épargne ce qu'il a mordu.
func test_sinking_spikes_throw_shards_that_spare_the_bitten() -> void:
	_learn_with("manual_cold", "ice_spike", [[SkillStats.SPLITS, 3.0]])
	var bitten := _target(Vector2(Player.PLACEMENT_RANGE, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(IceSpikes.LIFETIME + 0.05)
	assert_eq(_children_of(Projectile).size(), 3)
	await wait_seconds(0.3)
	assert_eq(_hits(bitten), 1, "les éclats l'épargnent")


func test_spikes_leave_frozen_ground() -> void:
	_learn_with("manual_cold", "ice_spike", [[SkillStats.GROUND, 1.0]])
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(2)
	assert_eq(_children_of(DashTrail).size(), 1)


func test_a_frozen_nova_leaves_ground_under_its_caster() -> void:
	_learn_with("manual_cold", "ice_nova", [[SkillStats.GROUND, 1.0]])
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(3)
	var ground: Array = _children_of(DashTrail)
	assert_eq(ground.size(), 1)
	assert_eq((ground[0] as Node2D).global_position, _p.global_position)
	var cast := _p.resolve(SkillCatalog.by_id("ice_nova"), 1)
	assert_eq((ground[0] as DashTrail)._cast.radius, cast.radius, "de la taille de la nova")


## Le Sillon : des cercles en ligne jusqu'au point visé, chacun mord une fois.
func test_an_ice_furrow_raises_spikes_in_a_line_to_the_aim() -> void:
	_learn_with("manual_cold", "ice_spike", [], Skill.Shape.FISSURE)
	var near := _target(Vector2(30, 0))
	var far := _target(Vector2(Player.PLACEMENT_RANGE - 20.0, 0))
	var aside := _target(Vector2(80, 60))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	assert_gt(_children_of(IceSpikes).size(), 2)
	await wait_seconds(0.6)
	assert_eq(_hits(near), 1)
	assert_eq(_hits(far), 1)
	assert_eq(_hits(aside), 0, "hors de la ligne")


## Avec Éclats, chaque cercle du Sillon projette les siens en retombant.
func test_each_circle_of_a_furrow_throws_its_shards() -> void:
	_learn_with("manual_cold", "ice_spike", [[SkillStats.SPLITS, 2.0]], Skill.Shape.FISSURE)
	assert_true(Gestures.cast(_p, 2))
	var circles := _children_of(IceSpikes).size()
	assert_gt(circles, 1)
	await wait_seconds(IceSpikes.FISSURE_STEP * float(circles) + IceSpikes.LIFETIME + 0.05)
	assert_eq(_children_of(Projectile).size(), circles * 2)


## L'Onde de givre : plus loin qu'une nova, une fois chacun.
func test_a_frost_wave_reaches_three_radii_once_each() -> void:
	_learn_with("manual_cold", "ice_nova", [], Skill.Shape.RING)
	var cast := _p.resolve(SkillCatalog.by_id("ice_nova"), 1)
	var close := _target(Vector2(20, 0))
	var far := _target(Vector2(-cast.radius * 2.5, 0))
	var beyond := _target(Vector2(0, cast.radius * FrostRing.REACH + 30.0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(FrostRing.LIFETIME + 0.1)
	assert_eq(_hits(close), 1)
	assert_eq(_hits(far), 1, "au-delà du rayon d'une nova")
	assert_eq(_hits(beyond), 0)


## L'Aspiration : chaque impulsion tire vers le cœur, par un recul négatif.
func test_a_sucking_vortex_pulls_toward_its_heart() -> void:
	_learn_with("manual_cold", "winter_disaster", [[SkillStats.PULL, 120.0]])
	var prey := _target(Vector2(15, 0))
	var pulls := []
	prey.damaged.connect(func(info: DamageInfo) -> void: pulls.append(info.knockback))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(3)
	assert_eq(pulls, [-120.0])


## L'Implosion se resserre, puis éclate de tout son rayon.
func test_an_implosion_closes_in_then_bursts_whole() -> void:
	_learn_with("manual_cold", "winter_disaster", [["duration", -80.0, true]], Skill.Shape.IMPLOSION)
	var cast := _p.resolve(SkillCatalog.by_id("winter_disaster"), 1)
	assert_true(Gestures.cast(_p, 2))
	var vortex: IceVortex = _children_of(IceVortex)[0]
	assert_almost_eq(vortex.reach(), cast.radius, 0.01, "il part à pleine taille")
	await wait_seconds(cast.duration * 0.5)
	assert_lt(vortex.reach(), cast.radius * 0.7, "et se resserre")
	var edge := _target(Vector2(cast.radius * 0.9, 0))
	while is_instance_valid(vortex):
		await wait_physics_frames(1)
	await wait_physics_frames(2)
	assert_eq(_hits(edge), 1, "l'éclatement final prend tout le rayon")


## Éclatement : en sortant du tombeau, de soi-même, il éclate.
func test_leaving_the_tomb_shatters_it() -> void:
	_learn_with("manual_cold", "frost_tomb", [["damage_cold", 10.0], [SkillStats.END_BURST, 30.0]])
	var near := _target(Vector2(20, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	_p._recharges[2] = 0.0
	assert_true(Gestures.cast(_p, 2))
	assert_false(_p.lit("frost_tomb"))
	await wait_physics_frames(2)
	assert_eq(_hits(near), 1)


## Un buff de ruée ne rééclate pas en finissant : il a éclaté à l'arrivée.
func test_only_a_cast_buff_shatters() -> void:
	_learn_with("manual_lightning", "storm_dash", [["damage_lightning", 10.0], [SkillStats.END_BURST, 30.0]])
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(2)
	var bursts := _children_of(Explosion).size()
	_p.extinguish("storm_dash")
	await wait_physics_frames(2)
	assert_eq(_children_of(Explosion).size(), bursts)


## L'Armure de givre : le tombeau protège sans enfermer.
func test_frost_armor_protects_without_binding() -> void:
	_learn("manual_cold", [
		"frost_tomb", "frost_tomb_thaw", "frost_tomb_thaw", "frost_tomb_frost_armor",
	])
	assert_true(_p.invest(0, "ice_spike"))
	_p.bar.put(3, "ice_spike")
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	assert_true(_p.lit("frost_tomb"))
	assert_lt(_p.stats.damage_taken, 0.0, "il protège")
	assert_true(Gestures.cast(_p, 3), "et les autres sorts partent")


## Dégel : le soin du tombeau se lit sur le lancer résolu.
func test_the_tomb_mends_what_its_tree_gives() -> void:
	_learn_with("manual_cold", "frost_tomb", [["self_heal", 100.0, true]])
	var tomb := SkillCatalog.by_id("frost_tomb")
	_p._set_health(_p.stats.max_health * 0.2)
	var wounded := _p.health
	assert_true(Gestures.cast(_p, 2))
	_p.stats.health_regen = 0.0
	await wait_seconds(1.0)
	var mended := _p.health - wounded
	var full := _p.stats.max_health * tomb.self_heal
	assert_almost_eq(mended, full * 2.0, full * 0.2)


## Un sol ne cumule pas (jalon 37) : deux plaques de la même compétence sous une cible ne
## la frappent qu'une fois par impulsion ; une autre compétence frappe pour son compte.
func test_grounds_of_one_skill_do_not_stack() -> void:
	var target := _target(Vector2(40, 0))
	await wait_physics_frames(2)
	var ball := _p.resolve(SkillCatalog.by_id("fireball"), 1)
	ball.ground_duration = 0.4
	for i in 3:
		DashTrail.patch(_effects, Vector2(40, 0), ball.ground(), _p.states)
	await wait_seconds(0.3)
	assert_eq(_hits(target), 1, "trois plaques, une seule frappe")

	var nova := _p.resolve(SkillCatalog.by_id("ice_nova"), 1)
	nova.ground_duration = 0.4
	DashTrail.patch(_effects, Vector2(40, 0), nova.ground(), _p.states)
	await wait_seconds(0.3)
	assert_eq(_hits(target), 2, "une autre compétence frappe aussi")


# --------------------------------------------------------------------------
# Les arbres de la nécromancie (jalon 38)
# --------------------------------------------------------------------------

## Contagion : la décomposition de la cible gagne son voisin, qui n'est pas frappé.
func test_contagion_spreads_decay_without_striking() -> void:
	_learn_with("manual_necrotic", "plague", [[SkillStats.CONTAGION, 30.0]])
	var struck := _wearing_target(Vector2(60, 0))
	var beside := _wearing_target(Vector2(60, 24))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(0.6)
	assert_eq(_hits(struck), 1)
	assert_eq(_hits(beside), 0, "le voisin n'est pas frappé")
	assert_true(beside.states.active(StatusEffects.Kind.DECAY), "mais il se décompose")


## La Nuée : un essaim lent qui mord en passant et décompose ce qu'il mord.
func test_a_plague_swarm_decays_what_it_passes_by() -> void:
	_learn_with("manual_necrotic", "plague", [], Skill.Shape.ORB)
	var on_the_way := _wearing_target(Vector2(80, 10))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(1.4)
	assert_gt(_hits(on_the_way), 1, "plusieurs morsures en passant")
	assert_true(on_the_way.states.active(StatusEffects.Kind.DECAY))


func _undead() -> Minion:
	for minion in Minion.living:
		if minion._player == _p:
			return minion
	return null


## Ossature : des PV accrus à la levée.
func test_ossature_raises_sturdier_undead() -> void:
	_learn_with("manual_necrotic", "rise", [[SkillStats.MINION_LIFE, 100.0]])
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(1)
	assert_almost_eq(_undead().max_health, _p.stats.max_health * Minion.LIFE * 2.0, 0.01)


## Le Colosse d'os : un seul, plus solide, qui frappe tout un cercle.
func test_a_bone_colossus_stands_alone_and_strikes_a_circle() -> void:
	_learn_with("manual_necrotic", "rise", [[SkillStats.COLOSSUS, 24.0]])
	var first := _target(Vector2(40, 0))
	var next := _target(Vector2(40, 18))
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(1)
	assert_eq(Minion.count_of(_p, "rise"), 1)
	assert_almost_eq(
		_undead().max_health, _p.stats.max_health * Minion.LIFE * SkillStats.COLOSSUS_LIFE, 0.01
	)
	_p._recharges[2] = 0.0
	assert_false(Gestures.cast(_p, 2), "un colosse, pas deux")
	await wait_seconds(1.5)
	assert_gt(_hits(first), 0)
	assert_gt(_hits(next), 0, "son coup prend aussi le voisin")


## Dernier souffle : un mort-vivant qui tombe éclate.
func test_a_falling_undead_bursts() -> void:
	_learn_with("manual_necrotic", "rise", [[SkillStats.END_BURST, 30.0]])
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(1)
	var minion := _undead()
	var blow := DamageType.empty_parts()
	blow[DamageType.Kind.PHYSICAL] = minion.max_health * 10.0
	minion.hurtbox.take_damage(DamageInfo.roll(null, minion.global_position, blow))
	minion.hurtbox.take_damage(DamageInfo.roll(null, minion.global_position, blow))
	await wait_physics_frames(2)
	assert_eq(_children_of(Explosion).size(), 1, "une fois, même frappé deux fois en tombant")


## Rempart d'os : chaque mort-vivant debout retire ses points aux dégâts subis.
func test_a_bone_rampart_shields_by_the_head() -> void:
	_learn_with("manual_necrotic", "rise", [[SkillStats.BONE_WALL, 5.0]])
	var bare := _p.stats.damage_taken
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(1)
	assert_almost_eq(_p.stats.damage_taken, bare - 10.0, 0.001, "deux debout")
	_undead().queue_free()
	await wait_physics_frames(1)
	assert_almost_eq(_p.stats.damage_taken, bare - 5.0, 0.001, "un tombé")


## L'Haleine : un cône devant, plus long que la nova, rien derrière ni de côté.
func test_a_toxic_breath_strikes_its_cone_only() -> void:
	_learn_with("manual_necrotic", "toxic_unleash", [], Skill.Shape.BREATH)
	var cast := _p.resolve(SkillCatalog.by_id("toxic_unleash"), 1)
	var far_ahead := _target(Vector2(cast.radius * 2.2, 0))
	var behind := _target(Vector2(-20, 0))
	var aside := _target(Vector2(0, 40))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(ToxicBreath.LIFETIME + 0.1)
	assert_eq(_hits(far_ahead), 1, "au-delà du rayon d'une nova, une fois")
	assert_eq(_hits(behind), 0)
	assert_eq(_hits(aside), 0)


## Progéniture : une créature qui éclate lâche des petits.
func test_a_bursting_creature_releases_young() -> void:
	_learn_with("manual_necrotic", "rotting_gate", [[SkillStats.HATCHLINGS, 2.0]])
	var aim := _p.global_position + Vector2(Player.PLACEMENT_RANGE, 0)
	var prey := _target(aim + Vector2(50, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	var gate: RottingGate = _children_of(RottingGate)[0]
	var waited := 0.0
	while _hits(prey) == 0 and waited < 2.0:
		await wait_physics_frames(1)
		waited += 1.0 / Engine.physics_ticks_per_second
	assert_gt(_hits(prey), 0)
	var young := gate._crawlers.filter(func(c: RottingGate.Crawler) -> bool: return c.small)
	assert_eq(young.size(), 2)


## Le Nid porté : le portail suit le joueur.
func test_a_carried_nest_follows_its_caster() -> void:
	_learn_with("manual_necrotic", "rotting_gate", [], Skill.Shape.NEST)
	assert_true(Gestures.cast(_p, 2))
	var gate: RottingGate = _children_of(RottingGate)[0]
	_p.global_position += Vector2(60, 0)
	await wait_physics_frames(2)
	assert_almost_eq(gate.global_position, _p.global_position + RottingGate.NEST_OFFSET, Vector2.ONE)


## Malédiction profonde, Longue malédiction et Tribut, d'un même sceau.
func test_a_deep_long_curse_pays_its_tribute() -> void:
	_learn_with("manual_necrotic", "putrid_curse", [
		[SkillStats.CURSE_EFFECT, 50.0], [SkillStats.TRIBUTE, 3.0], ["duration", 100.0, true],
	])
	var cast := _p.resolve(SkillCatalog.by_id("putrid_curse"), 1)
	var aim := _p.global_position + Vector2(Player.PLACEMENT_RANGE, 0)
	var one := _wearing_target(aim + Vector2(10, 0))
	var two := _wearing_target(aim + Vector2(-10, 0))
	await wait_physics_frames(2)
	_p._set_mana(100.0)
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(2)
	assert_almost_eq(_p.mana, 100.0 - cast.mana_cost + 6.0, 0.5, "trois de mana par maudit")
	assert_almost_eq(one.states.resistance_lost(DamageType.Kind.NECROTIC), StatusEffects.CURSE * 1.5, 0.001)
	assert_gt(two.states.remaining(StatusEffects.Kind.CURSED), StatusEffects.DURATIONS[StatusEffects.Kind.CURSED])


## La Marque de mort : un seul ennemi, deux fois plus fort, et elle passe à sa mort.
func test_a_death_mark_takes_one_then_moves_on() -> void:
	_learn_with("manual_necrotic", "putrid_curse", [], Skill.Shape.MARK)
	var aim := _p.global_position + Vector2(Player.PLACEMENT_RANGE, 0)
	var marked := _wearing_target(aim + Vector2(10, 0))
	var next := _wearing_target(aim + Vector2(50, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(2)
	assert_almost_eq(
		marked.states.resistance_lost(DamageType.Kind.NECROTIC),
		StatusEffects.CURSE * SkillStats.MARK_FACTOR, 0.001
	)
	assert_false(next.states.active(StatusEffects.Kind.CURSED), "un seul")
	marked.states.clear()
	await wait_physics_frames(2)
	assert_true(next.states.active(StatusEffects.Kind.CURSED), "elle passe au plus proche")
	assert_false(marked.states.active(StatusEffects.Kind.CURSED), "et ne revient pas")
	assert_eq(_hits(next), 0)


## Endurcissement : la vie rongée se lit sur le lancer.
func test_hardening_gnaws_less() -> void:
	_learn_with("manual_necrotic", "advanced_necrosis", [["self_wither", -50.0, true]])
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(1)
	_p.stats.health_regen = 0.0
	var health := _p.health
	await wait_seconds(1.0)
	var gnawed := health - _p.health
	var full := health * SkillCatalog.by_id("advanced_necrosis").self_wither
	assert_almost_eq(gnawed, full * 0.5, full * 0.15)


## Le Fardeau partagé : ce que la Nécrose ronge frappe autour.
func test_a_shared_burden_strikes_around() -> void:
	_learn_with("manual_necrotic", "advanced_necrosis", [[SkillStats.SHARED_BURDEN, 48.0]])
	var near := _target(Vector2(20, 0))
	var far := _target(Vector2(90, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(SkillStats.BURDEN_PERIOD + 0.2)
	assert_eq(_hits(near), 1)
	assert_eq(_hits(far), 0)


# --------------------------------------------------------------------------
# Le chevalier (jalon 39)
# --------------------------------------------------------------------------

func _knockbacks_on(target: Hurtbox) -> Array:
	var seen := []
	target.damaged.connect(func(info: DamageInfo) -> void: seen.append(info.knockback))
	return seen


## Le Brise-sol : tout le cercle autour de l'impact, une fois, rien derrière soi.
func test_a_groundbreaker_strikes_the_circle_of_its_impact() -> void:
	_learn_with("manual_weapons", "heavy_strike", [["radius", 28.0]], Skill.Shape.SLAM)
	var beyond := _target(Vector2(_p.strike_reach() + 20.0, 0))
	var aside := _target(Vector2(_p.strike_reach(), 24))
	var behind := _target(Vector2(-30, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(0.3)
	assert_eq(_hits(beyond), 1)
	assert_eq(_hits(aside), 1, "de côté de l'impact aussi")
	assert_eq(_hits(behind), 0)


## Coup de bélier et Hargne : le recul voyage avec le coup, et chaque touché rend des PV.
func test_a_ramming_furious_strike_pushes_and_heals() -> void:
	_learn_with("manual_weapons", "heavy_strike", [[SkillStats.KNOCKBACK, 120.0], [SkillStats.LIFE_ON_HIT, 5.0]])
	var one := _target(Vector2(20, -4))
	var two := _target(Vector2(20, 4))
	var pushes := _knockbacks_on(one)
	await wait_physics_frames(2)
	_p.stats.health_regen = 0.0
	_p._set_health(_p.stats.max_health - 50.0)
	var health := _p.health
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(_p.swing_duration + 0.2)
	assert_eq(_hits(two), 1)
	assert_eq(pushes, [120.0])
	assert_almost_eq(_p.health, health + 10.0, 0.5, "cinq PV par touché")


## Bouclier de lames : l'abri suit les épées qui tournent.
func test_a_blade_shield_lasts_while_the_swords_spin() -> void:
	# La durée par le nœud : l'abri refait la fiche, et avec elle les modificateurs de mot-clé.
	_learn_with("manual_weapons", "spiral_sword", [[SkillStats.BLADE_WARD, 5.0], ["duration", -80.0, true]])
	var bare := _p.stats.damage_taken
	assert_true(Gestures.cast(_p, 2))
	_p._recharges[2] = 0.0
	assert_true(Gestures.cast(_p, 2))
	assert_almost_eq(_p.stats.damage_taken, bare - 10.0, 0.001, "deux épées")
	await wait_seconds(1.3)
	assert_eq(_p.orbiting_swords(), 0)
	assert_almost_eq(_p.stats.damage_taken, bare, 0.001, "parties, plus d'abri")


## La Volée d'épées : à sa fin, l'épée file sur l'ennemi que la ronde n'atteint pas.
func test_a_sword_volley_flies_to_the_nearest_enemy() -> void:
	_learn_with("manual_weapons", "spiral_sword", [[SkillStats.SWORD_VOLLEY, 160.0]])
	_p.skill_mods.assign([StatMod.new("duration", StatMod.Mode.PERCENT, -80.0, Keywords.ATTACK)])
	var far := _target(Vector2(120, 30))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(1.6)
	assert_eq(_hits(far), 1)
	assert_eq(_children_of(FlyingSword).size(), 0, "et sa course finit à la portée")


## Orbite large : les épées tournent au rayon du lancer.
func test_a_wide_orbit_reaches_farther() -> void:
	_learn_with("manual_weapons", "spiral_sword", [["radius", 100.0, true]])
	var radius := SkillCatalog.by_id("spiral_sword").radius * 2.0
	var on_the_circle := _target(Vector2(radius, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(1.5)
	assert_gt(_hits(on_the_circle), 0)


## Vagues jumelles : un éventail ; le Ressac : la vague revient et remord.
func test_twin_waves_fan_out_and_a_backwash_bites_twice() -> void:
	_learn_with("manual_weapons", "wave_slash", [[SkillStats.WAVES, 1.0]], Skill.Shape.BOOMERANG)
	var cast := _p.resolve(SkillCatalog.by_id("wave_slash"), 1)
	var ahead := _target(Vector2(SlashWave.START + cast.radius + 20.0, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	assert_eq(_children_of(SlashWave).size(), 2)
	await wait_seconds(cast.duration * 2.0 + 0.2)
	assert_eq(_hits(ahead), 4, "deux vagues, aller et retour")
	assert_eq(_children_of(SlashWave).size(), 0)


## Le Sillon d'acier : au bout de sa course, la vague laisse un couloir qui frappe.
func test_a_steel_furrow_cuts_behind_the_wave() -> void:
	_learn_with("manual_weapons", "wave_slash", [[SkillStats.GROUND, 1.0]])
	var cast := _p.resolve(SkillCatalog.by_id("wave_slash"), 1)
	var on_the_way := _target(Vector2(SlashWave.START + 20.0, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(cast.duration + 0.1)
	var after_the_wave := _hits(on_the_way)
	assert_eq(_children_of(DashTrail).size(), 1)
	await wait_seconds(0.6)
	assert_gt(_hits(on_the_way), after_the_wave, "le couloir frappe après la vague")


## Sous le Ressac, le retour est un passage comme l'aller : il pose son propre sillon.
func test_a_backwash_lays_a_furrow_on_each_pass() -> void:
	_learn_with("manual_weapons", "wave_slash", [[SkillStats.GROUND, 2.0]], Skill.Shape.BOOMERANG)
	var cast := _p.resolve(SkillCatalog.by_id("wave_slash"), 1)
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(cast.duration + 0.1)
	assert_eq(_children_of(DashTrail).size(), 1, "au bout de l'aller")
	await wait_seconds(cast.duration + 0.1)
	assert_eq(_children_of(DashTrail).size(), 2, "et au bout du retour")


## Tourbillon et Fauche vorace : le tour attire, et rend du mana par fauché.
func test_a_hungry_whirlpool_pulls_and_feeds() -> void:
	_learn_with("manual_weapons", "cyclone", [
		[SkillStats.PULL, 50.0], [SkillStats.MANA_ON_HIT, 5.0], ["mana_per_second", -100.0, true],
	])
	var one := _target(Vector2(20, 0))
	_target(Vector2(-20, 0))
	var pulls := _knockbacks_on(one)
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	# Après l'allumage, qui refait la fiche ; avant la première frappe.
	_p.stats.max_mana = 9999.0
	_p._set_mana(100.0)
	await wait_physics_frames(1)
	assert_eq(pulls, [-50.0], "vers le cœur")
	assert_almost_eq(_p.mana, 110.0, 1.0, "cinq de mana par fauché")


## Arsenal : un lancer fait naître ses épées en plus d'un coup, sans dépasser la ronde.
func test_an_arsenal_summons_its_swords_at_once_within_the_round() -> void:
	_learn_with("manual_weapons", "spiral_sword", [[SkillStats.EXTRA_SWORDS, 1.0]])
	assert_true(Gestures.cast(_p, 2))
	assert_eq(_p.orbiting_swords(), 2)
	_p._recharges[2] = 0.0
	assert_true(Gestures.cast(_p, 2))
	assert_eq(_p.orbiting_swords(), SkillCatalog.by_id("spiral_sword").simultaneous, "pas au-delà")


# --------------------------------------------------------------------------
# Le sacré (jalon 40)
# --------------------------------------------------------------------------

## La Croix de lumière : les quatre axes, sans viser ; rien en diagonale.
func test_a_holy_cross_strikes_the_four_axes() -> void:
	_learn_with("manual_holy", "holy_strike", [], Skill.Shape.HOLY_CROSS)
	var arms := [
		_target(Vector2(40, 0)), _target(Vector2(0, 40)), _target(Vector2(-40, 0)), _target(Vector2(0, -40))
	]
	var aslant := _target(Vector2(40, 40))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(3)
	for arm: Hurtbox in arms:
		assert_eq(_hits(arm), 1)
	assert_eq(_hits(aslant), 0)


## La Réfraction : du bout du trait vers l'ennemi non frappé le plus proche, une fois.
func test_a_refracted_beam_leaps_to_the_nearest_unstruck_enemy() -> void:
	_learn_with("manual_holy", "holy_strike", [[SkillStats.BOUNCES, 1.0]])
	var first := _target(Vector2(40, 0))
	var off_axis := _target(Vector2(90, 40))
	var after := _target(Vector2(99, 140))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(4)
	assert_eq(_hits(first), 1)
	assert_eq(_hits(off_axis), 1, "le rebond, hors de l'axe")
	assert_eq(_hits(after), 0, "un seul rebond")


func test_a_drifting_pillar_follows_the_nearest_enemy() -> void:
	_learn_with("manual_holy", "sacred_pillar", [], Skill.Shape.DRIFT)
	var prey := _target(Vector2(Player.PLACEMENT_RANGE, 80))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	var pillar: SacredPillar = _children_of(SacredPillar)[0]
	var before := pillar.global_position.distance_to(prey.global_position)
	await wait_seconds(0.5)
	assert_lt(pillar.global_position.distance_to(prey.global_position), before - 10.0)


## Appel céleste et Effondrement : chaque impulsion tire vers le cœur, la fin éclate.
func test_a_calling_pillar_pulls_then_collapses() -> void:
	_learn_with("manual_holy", "sacred_pillar", [
		[SkillStats.PULL, 40.0], [SkillStats.END_BURST, 30.0], ["duration", -70.0, true]
	])
	var prey := _target(Vector2(Player.PLACEMENT_RANGE + 15.0, 0))
	var pulls := _knockbacks_on(prey)
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	var pillar: SacredPillar = _children_of(SacredPillar)[0]
	await wait_physics_frames(2)
	assert_eq(pulls, [-40.0])
	while is_instance_valid(pillar):
		await wait_physics_frames(1)
	await wait_physics_frames(1)
	assert_eq(_children_of(Explosion).size(), 1)


## Exaltation et Absolution : la seconde onde porte le gain de la première, et chaque
## touché rend ses PV.
func test_an_exalted_pulse_swells_and_absolves() -> void:
	_learn_with("manual_holy", "holy_pulse", [[SkillStats.WAVE_GAIN, 50.0], [SkillStats.LIFE_ON_HIT, 5.0]])
	_p.skill_mods.assign([StatMod.new("crit_chance", StatMod.Mode.PERCENT, -100.0)])
	var cast := _p.resolve(SkillCatalog.by_id("holy_pulse"), 1)
	var near := _target(Vector2(20, 0))
	await wait_physics_frames(2)
	_p.stats.health_regen = 0.0
	_p._set_health(_p.stats.max_health - 50.0)
	var health := _p.health
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(cast.period + 0.1)
	var received: Array = _received_all[near]
	assert_eq(received.size(), 2)
	assert_almost_eq(float(received[1]), float(received[0]) * 1.5, 0.001)
	assert_almost_eq(_p.health, health + 10.0, 0.5, "cinq PV par touché, deux ondes")


## L'Auréole bénit ce qui s'approche, sans le frapper.
func test_an_aureole_blesses_what_comes_near() -> void:
	_learn_with("manual_holy", "holy_light", [[SkillStats.AUREOLE, 40.0]])
	var near := _wearing_target(Vector2(20, 0))
	var far := _wearing_target(Vector2(90, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(SkillStats.AUREOLE_PERIOD + 0.1)
	assert_true(near.states.active(StatusEffects.Kind.BLESSING))
	assert_eq(_hits(near), 0, "béni, pas frappé")
	assert_false(far.states.active(StatusEffects.Kind.BLESSING))


# --------------------------------------------------------------------------
# La sorcière (jalon 41)
# --------------------------------------------------------------------------

## Le point visé à la manette : droit devant, à la portée de pose.
func _aim() -> Vector2:
	return _p.global_position + _p.facing * Player.PLACEMENT_RANGE


## Aucun état tiré par les coups du joueur : ce que la Catalyse retire ne revient pas
## par sa propre frappe.
func _no_rolled_states() -> void:
	_p.states.chance_factors.fill(0.0)


func _cast_again(slot: int) -> void:
	_p._recharges[slot] = 0.0
	assert_true(Gestures.cast(_p, slot))


## Trinité : une charge par sort d'une autre nature que le précédent. Le premier n'a pas
## de précédent ; la Catalyse, qui part au feu comme le Projectile, n'en donne pas.
func test_trinity_stacks_harmony_on_each_change_of_element() -> void:
	_learn_class(Character.WITCH, ["elemental_projectile", "trinity", "catalysis"])
	_p.bar.put(3, "trinity")
	_p.bar.put(4, "catalysis")
	var projectile := SkillCatalog.by_id("elemental_projectile")
	assert_true(Gestures.cast(_p, 3))
	var before := _p.resolve(projectile, 1).total_min()

	_cast_again(2)
	assert_eq(_p.lit_stacks("trinity"), 0, "le premier sort")
	_cast_again(4)
	assert_eq(_p.lit_stacks("trinity"), 0, "feu après feu")
	_cast_again(2)
	assert_eq(_p.lit_stacks("trinity"), 1, "froid après feu")
	_p.states.slew.emit(_blow(Keywords.ATTACK), Vector2.ZERO, null)
	assert_eq(_p.lit_stacks("trinity"), 1, "une mise à mort ne la charge pas")
	_cast_again(2)
	assert_eq(_p.lit_stacks("trinity"), 2)
	assert_almost_eq(_p.resolve(projectile, 1).total_min(), before * 1.10, 1e-3, "5 % par charge")


## Embrasé et transi : les deux s'en vont, la Vapeur souffle. Un état seul ne réagit pas.
func test_catalysis_consumes_a_pair_of_states_into_vapor() -> void:
	_learn_class(Character.WITCH, ["elemental_projectile", "catalysis"])
	_p.bar.put(3, "catalysis")
	_no_rolled_states()
	var steamy := _wearing_target(_aim())
	steamy.states.put(StatusEffects.Kind.IGNITE, 5.0)
	steamy.states.put(StatusEffects.Kind.CHILL, 1.0)
	var lone := _wearing_target(_aim() + Vector2(0, 30))
	lone.states.put(StatusEffects.Kind.IGNITE, 5.0)
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 3))
	assert_false(steamy.states.active(StatusEffects.Kind.IGNITE), "consommé")
	assert_false(steamy.states.active(StatusEffects.Kind.CHILL), "consommé")
	assert_true(lone.states.active(StatusEffects.Kind.IGNITE), "seul, il reste")
	await wait_physics_frames(2)
	assert_eq(_children_of(Explosion).size(), 1, "une Vapeur")
	assert_eq(_hits(steamy), 2, "la frappe du cercle, puis la Vapeur")


## Embrasé et engourdi : l'Arc ardent frappe l'ennemi et gagne ses voisins à sa portée.
func test_catalysis_arcs_from_fire_and_lightning() -> void:
	_learn_class(Character.WITCH, ["elemental_projectile", "catalysis"])
	_p.bar.put(3, "catalysis")
	_no_rolled_states()
	var charged := _wearing_target(_aim())
	charged.states.put(StatusEffects.Kind.IGNITE, 5.0)
	charged.states.put(StatusEffects.Kind.NUMB, 1.0)
	var neighbor := _target(_aim() + Vector2(50, 0))
	var far := _target(_aim() + Vector2(0, Catalysis.ARC_REACH + 20.0))
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 3))
	assert_eq(_hits(charged), 2, "la frappe du cercle, puis l'arc")
	assert_eq(_hits(neighbor), 1, "hors du cercle, l'arc l'atteint")
	assert_eq(_hits(far), 0)


## Transi et engourdi : le transi gagne les voisins avant de quitter l'ennemi.
func test_catalysis_conducts_the_chill_to_the_neighbors() -> void:
	_learn_class(Character.WITCH, ["elemental_projectile", "catalysis"])
	_p.bar.put(3, "catalysis")
	_no_rolled_states()
	var frozen := _wearing_target(_aim())
	frozen.states.put(StatusEffects.Kind.CHILL, 1.0)
	frozen.states.put(StatusEffects.Kind.NUMB, 1.0)
	var neighbor := _wearing_target(_aim() + Vector2(Catalysis.SPREAD_REACH - 4.0, 0))
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 3))
	assert_false(frozen.states.active(StatusEffects.Kind.CHILL))
	assert_true(neighbor.states.active(StatusEffects.Kind.CHILL), "le transi a gagné")
	assert_eq(_hits(frozen), 2)


## La poupée se pose au point visé ; un ennemi plus près d'elle que du joueur la frappe.
## Sa fin la fait éclater, et en poser une autre fait éclater l'ancienne.
func test_the_rag_doll_draws_the_blows_and_bursts() -> void:
	_learn_class(Character.WITCH, ["elemental_projectile", "rag_doll"])
	_p.bar.put(3, "rag_doll")
	var grunt: Enemy = load("res://actors/enemies/grunt.tscn").instantiate()
	add_child_autofree(grunt)
	grunt.setup(_p)
	# Hors du souffle de la poupée : il doit survivre à ses deux éclats.
	grunt.global_position = _aim() + Vector2(80, 0)
	assert_true(Gestures.cast(_p, 3))
	var dolls := _children_of(RagDoll)
	assert_eq(dolls.size(), 1)
	assert_eq((dolls[0] as RagDoll).global_position, _aim())
	await wait_physics_frames(1)
	assert_true(grunt.foe() is RagDoll, "la poupée, plus proche")

	_cast_again(3)
	await wait_physics_frames(2)
	assert_eq(_children_of(RagDoll).size(), 1, "une seule debout")
	assert_eq(_children_of(Explosion).size(), 1, "l'ancienne a éclaté")

	var doll: RagDoll = _children_of(RagDoll)[0]
	doll._age = _p.resolve(SkillCatalog.by_id("rag_doll"), 1).duration
	await wait_physics_frames(3)
	assert_eq(_children_of(RagDoll).size(), 0, "à sa fin")
	assert_eq(_children_of(Explosion).size(), 2, "elle éclate")
	assert_eq(grunt.foe(), _p, "et le joueur redevient la cible")


## Le Familier rejoue un sort posé, à sa part des dégâts, après son retard ; un écho ne se
## paie pas et ne compte pas de tour. Il s'éteint à la touche.
func test_the_familiar_echoes_a_posed_spell_weaker_and_later() -> void:
	_learn_class(Character.WITCH, ["elemental_projectile", "familiar"])
	_p.bar.put(3, "familiar")
	assert_true(Gestures.cast(_p, 3))
	assert_true(_p.lit("familiar"))
	_cast_again(2)
	var first: Projectile = _children_of(Projectile)[0]
	var mana := _p.mana
	await wait_seconds(Familiar.ECHO_DELAY + 0.05)

	var bolts := _children_of(Projectile)
	assert_eq(bolts.size(), 2, "l'écho est parti")
	var echo: Projectile = bolts[1]
	assert_almost_eq(echo._cast.total_min(), first._cast.total_min() * Familiar.ECHO_PART, 1e-3)
	assert_eq(echo.nature(), first.nature(), "le même tour")
	assert_eq(int(_p._turns["elemental_projectile"]), 1, "l'écho n'avance pas le tour")
	assert_lte(mana - _p.mana, 1.0, "ni ne se paie, au drain près")

	_cast_again(3)
	assert_false(_p.lit("familiar"), "éteint à la touche")


## Prisme : la salve répartit le tour, un élément par trait.
func test_a_prism_volley_spreads_the_turn_across_its_bolts() -> void:
	_learn_class(Character.WITCH, [
		"elemental_projectile", "elemental_projectile_celerity", "elemental_projectile_ricochet",
		"elemental_projectile_prism", "elemental_projectile_prism",
	])
	assert_true(Gestures.cast(_p, 2))
	var natures := {}
	for bolt: Projectile in _children_of(Projectile):
		natures[bolt.nature()] = true
	assert_eq(natures.size(), 3, "feu, froid, foudre")


## Triade : pas de tir ; trois comètes qui se rejoignent, un seul coup aux trois natures.
func test_the_triad_bursts_once_with_the_three_elements() -> void:
	_learn_class(Character.WITCH, [
		"elemental_projectile", "elemental_projectile_arcana", "elemental_projectile_arcana",
		"elemental_projectile_triad",
	])
	var cast := _p.resolve(SkillCatalog.by_id("elemental_projectile"), 1)
	assert_eq(cast.shape, Skill.Shape.TRIAD)
	var shares := cast.distribution()
	for nature in [DamageType.Kind.FIRE, DamageType.Kind.COLD, DamageType.Kind.LIGHTNING]:
		assert_almost_eq(shares[nature], 1.0 / 3.0, 1e-4)
	var target := _target(_aim())
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 2))
	assert_eq(_children_of(Triad).size(), 1)
	assert_eq(_children_of(Projectile).size(), 0, "pas de tir")
	await wait_seconds(Triad.TRAVEL + 0.1)
	assert_eq(_hits(target), 1, "au point visé, l'éclat seul")


## En route, chaque comète perce ce qu'elle traverse, une fois, de son seul élément. Les
## trois trajectoires convergent : sur l'axe, un ennemi est traversé par les trois. Hors
## d'elles et du cercle, rien.
func test_the_triad_comets_pierce_what_they_cross() -> void:
	_learn_class(Character.WITCH, [
		"elemental_projectile", "elemental_projectile_arcana", "elemental_projectile_arcana",
		"elemental_projectile_triad",
	])
	_p.skill_mods.assign([StatMod.new("crit_chance", StatMod.Mode.PERCENT, -100.0)])
	var cast := _p.resolve(SkillCatalog.by_id("elemental_projectile"), 1)
	# Sur l'axe de la visée, que les trois trajectoires longent.
	var crossed := _target(_p.global_position + _p.facing * 60.0)
	var aside := _target(_p.global_position + Vector2(60, 70))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(Triad.TRAVEL + 0.1)
	assert_eq(_hits(crossed), 3, "une fois par comète")
	assert_eq(_hits(aside), 0)
	for amount in _received_all[crossed]:
		assert_lt(float(amount), cast.total_max() * 0.5, "une seule part, pas tout le coup")


## Résonance : un sort qui frappe rend du temps à l'amplification. Siphon : un ennemi tué
## d'un sort rend du mana. Contrecoup : à sa fin, elle éclate.
func test_the_amplification_tree_resonates_siphons_and_backlashes() -> void:
	_learn_class(Character.WITCH, [
		"elemental_projectile", "spell_amplification", "spell_amplification_volubility",
		"spell_amplification_resonance", "spell_amplification_overpower",
		"spell_amplification_siphon", "spell_amplification_remanence",
		"spell_amplification_backlash",
	])
	_p.bar.put(3, "spell_amplification")
	assert_true(Gestures.cast(_p, 3))
	var buff: Buff = _p._lit["spell_amplification"]
	buff._age = 5.0
	_cast_again(2)
	assert_almost_eq(buff._age, 5.0 - 0.3, 1e-4, "un point de Résonance")

	_p._set_mana(10.0)
	_p.states.slew.emit(_blow(Keywords.SPELL), Vector2.ZERO, null)
	assert_almost_eq(_p.mana, 12.0, 1e-3, "un point de Siphon")
	_p.states.slew.emit(_blow(Keywords.ATTACK), Vector2.ZERO, null)
	assert_almost_eq(_p.mana, 12.0, 1e-3, "pas sur une attaque")

	buff._age = buff._lifetime
	await wait_physics_frames(3)
	assert_false(_p.lit("spell_amplification"))
	assert_eq(_children_of(Explosion).size(), 1, "le Contrecoup")


## Le Projectile élémentaire avance d'un élément par lancer : `n` lancers, `n` tours.
func _cast_projectile(times: int) -> void:
	for i in times:
		_cast_again(2)


## Dissonance : une charge de plus au plafond, toutes perdues sur un élément répété. Point
## d'orgue : elles tiennent plus longtemps. Gamme : chaque charge accroît la chance d'état.
func test_trinity_dissonance_holds_one_more_and_loses_all_on_a_repeat() -> void:
	_learn_class(Character.WITCH, [
		"elemental_projectile", "trinity", "catalysis", "trinity_scale", "trinity_dissonance",
		"trinity_fermata",
	])
	_p.bar.put(3, "trinity")
	_p.bar.put(4, "catalysis")
	var projectile := SkillCatalog.by_id("elemental_projectile")
	assert_true(Gestures.cast(_p, 3))
	var bare := _p.resolve(projectile, 1).status_chance_increase
	_cast_projectile(6)
	var buff: Buff = _p._lit["trinity"]
	assert_eq(buff.stacks, 4, "trois, plus une")
	assert_almost_eq(buff._hold, SkillCatalog.by_id("trinity").stack_duration + 0.5, 1e-4)
	assert_almost_eq(
		_p.resolve(projectile, 1).status_chance_increase, bare + 4.0 * 4.0, 1e-3, "la Gamme, par charge"
	)
	# Le Projectile repart au feu ; la Catalyse aussi, à son premier tour.
	_cast_projectile(1)
	_cast_again(4)
	assert_eq(buff.stacks, 0, "le feu répété")


## Tempo : un sort qui charge l'Harmonie rend du temps aux recharges, pas aux simples gestes.
func test_trinity_tempo_shortens_the_running_cooldowns() -> void:
	_learn_class(Character.WITCH, [
		"elemental_projectile", "trinity", "rag_doll", "trinity_fermata", "trinity_tempo",
		"trinity_tempo",
	])
	_p.bar.put(3, "trinity")
	_p.bar.put(4, "rag_doll")
	assert_true(Gestures.cast(_p, 3))
	assert_true(Gestures.cast(_p, 4))
	_cast_projectile(1)
	var doll := _p.remaining_cooldown(4)
	_cast_projectile(1)
	assert_almost_eq(_p.remaining_cooldown(4), doll - 0.2, 1e-4, "deux points de Tempo")
	assert_gt(_p.remaining_cooldown(2), 0.0, "le geste du Projectile n'en perd rien")


## Accord parfait : à pleines charges, le sort suivant les consomme et part dans les trois
## éléments, plus fort.
func test_trinity_perfect_chord_spends_full_charges_on_a_three_element_spell() -> void:
	_learn_class(Character.WITCH, [
		"elemental_projectile", "trinity", "trinity_scale", "trinity_dissonance",
		"trinity_perfect_chord",
	])
	_p.bar.put(3, "trinity")
	assert_true(Gestures.cast(_p, 3))
	_cast_projectile(5)
	var buff: Buff = _p._lit["trinity"]
	assert_eq(buff.stacks, 4, "pleines")
	var full := _p.resolve(SkillCatalog.by_id("elemental_projectile"), 1).total_min()
	_cast_projectile(1)
	var bolts := _children_of(Projectile)
	var chord: Projectile = bolts[bolts.size() - 1]
	var shares := chord._cast.distribution()
	for nature in DamageType.ELEMENTS:
		assert_almost_eq(shares[nature], 1.0 / 3.0, 1e-4)
	assert_almost_eq(chord._cast.total_min(), full * 1.3, 1e-3)
	assert_eq(buff.stacks, 1, "consommées, puis la charge de ce sort")


## Amorce : un état seul réagit avec l'élément du tour, et il est seul consommé. Un état
## du même élément que le tour ne réagit pas.
func test_a_primed_catalysis_reacts_with_a_single_state() -> void:
	_learn_class(Character.WITCH, [
		"elemental_projectile", "catalysis", "catalysis_concentrate", "catalysis_concentrate",
		"catalysis_primer",
	])
	_p.bar.put(3, "catalysis")
	_no_rolled_states()
	var chilled := _wearing_target(_aim())
	chilled.states.put(StatusEffects.Kind.CHILL, 1.0)
	var burning := _wearing_target(_aim() + Vector2(0, 30))
	burning.states.put(StatusEffects.Kind.IGNITE, 5.0)
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 3))
	assert_false(chilled.states.active(StatusEffects.Kind.CHILL), "consommé")
	assert_true(burning.states.active(StatusEffects.Kind.IGNITE), "feu sur feu, rien")
	await wait_physics_frames(2)
	assert_eq(_children_of(Explosion).size(), 1, "la Vapeur, du feu prêté")


## Nappe brûlante : la Vapeur laisse un sol. Exothermie, Arc fourchu, Conductivité : les
## réactions plus fortes, un arc de plus, un transi qui va plus loin.
func test_the_catalysis_tree_strengthens_each_reaction() -> void:
	_learn_class(Character.WITCH, [
		"elemental_projectile", "catalysis", "catalysis_exothermy", "catalysis_scalding_mist",
		"catalysis_forked_arc", "catalysis_conductivity",
	])
	_p.bar.put(3, "catalysis")
	var cast := _p.resolve(SkillCatalog.by_id("catalysis"), 1)
	assert_almost_eq(Catalysis.reaction_part(cast), Catalysis.REACTION_PART * 1.25, 1e-4)
	assert_eq(Catalysis.arcs(cast), Catalysis.ARCS + 1)
	assert_almost_eq(Catalysis.spread_reach(cast), Catalysis.SPREAD_REACH + 16.0, 1e-4)
	_no_rolled_states()
	var steamy := _wearing_target(_aim())
	steamy.states.put(StatusEffects.Kind.IGNITE, 5.0)
	steamy.states.put(StatusEffects.Kind.CHILL, 1.0)
	await wait_physics_frames(2)

	assert_true(Gestures.cast(_p, 3))
	await wait_physics_frames(2)
	assert_eq(_children_of(DashTrail).size(), 1, "la nappe")


## Jumelles : deux poupées debout ; la troisième fait éclater la plus ancienne.
func test_twin_dolls_stand_together() -> void:
	_learn_class(Character.WITCH, [
		"elemental_projectile", "rag_doll", "rag_doll_decoy", "rag_doll_decoy", "rag_doll_twins",
	])
	_p.bar.put(3, "rag_doll")
	assert_true(Gestures.cast(_p, 3))
	_cast_again(3)
	await wait_physics_frames(2)
	assert_eq(_children_of(RagDoll).size(), 2)
	assert_eq(_children_of(Explosion).size(), 0)
	var oldest: RagDoll = RagDoll.standing[0]
	_cast_again(3)
	await wait_physics_frames(2)
	assert_eq(_children_of(RagDoll).size(), 2)
	assert_eq(_children_of(Explosion).size(), 1)
	assert_false(is_instance_valid(oldest), "la plus ancienne")


## Transfert : la poupée prend une part de ce que subit le joueur. Rancune : ce qu'elle a
## encaissé grossit son éclat.
func test_the_doll_shoulders_your_blows_and_returns_them() -> void:
	_learn_class(Character.WITCH, [
		"elemental_projectile", "rag_doll", "rag_doll_stuffing", "rag_doll_transfer",
		"rag_doll_gunpowder", "rag_doll_grudge",
	])
	_p.bar.put(3, "rag_doll")
	assert_true(Gestures.cast(_p, 3))
	var doll: RagDoll = _children_of(RagDoll)[0]
	var health := _p.health
	_p._on_damaged(DamageInfo.new(50.0, _p.global_position))
	assert_almost_eq(_p.health, health - 45.0, 1e-3, "dix pour cent détournés")
	assert_almost_eq(doll.health, doll.max_health - 5.0, 1e-3)
	assert_almost_eq(doll._absorbed, 5.0, 1e-3)


## Appeau : un ennemi un peu plus près du joueur choisit quand même la poupée.
func test_a_decoy_doll_draws_from_farther() -> void:
	_learn_class(Character.WITCH, ["elemental_projectile", "rag_doll", "rag_doll_decoy"])
	_p.bar.put(3, "rag_doll")
	var grunt: Enemy = load("res://actors/enemies/grunt.tscn").instantiate()
	add_child_autofree(grunt)
	grunt.setup(_p)
	grunt.global_position = _p.global_position + (_aim() - _p.global_position) * 0.45
	assert_true(Gestures.cast(_p, 3))
	await wait_physics_frames(1)
	assert_true(grunt.foe() is RagDoll, "plus loin que vous, mais à portée d'appeau")


## Ressassement : deux échos, un retard l'un après l'autre. Contre-chant : l'élément
## suivant. Écho fidèle : leur part.
func test_the_familiar_ruminates_in_the_next_element() -> void:
	_learn_class(Character.WITCH, [
		"elemental_projectile", "familiar", "familiar_faithful_echo", "familiar_faithful_echo",
		"familiar_rumination", "familiar_frugality", "familiar_frugality", "familiar_countersong",
	])
	_p.bar.put(3, "familiar")
	assert_true(Gestures.cast(_p, 3))
	var own := _p.resolve(SkillCatalog.by_id("familiar"), 1)
	assert_almost_eq(Familiar.echo_part(own), Familiar.ECHO_PART + 0.12 - 0.10, 1e-4)
	assert_almost_eq(own.mana_per_second, 4.0 * 0.8, 1e-4, "Frugalité")
	_cast_again(2)
	var first: Projectile = _children_of(Projectile)[0]
	var raven: Familiar = _p._lit["familiar"]
	assert_eq(raven._pending.size(), 2, "deux échos attendus")
	await wait_seconds(Familiar.ECHO_DELAY + 0.05)
	var bolts := _children_of(Projectile)
	var echo: Projectile = bolts[bolts.size() - 1]
	assert_ne(echo, first, "le premier écho")
	assert_eq(echo.nature(), DamageType.Kind.COLD, "le feu revient en froid")
	assert_almost_eq(echo._cast.total_min(), first._cast.total_min() * Familiar.echo_part(own), 1e-3)
	assert_eq(raven._pending.size(), 1, "le second attend encore")
	await wait_seconds(Familiar.ECHO_DELAY)
	assert_eq(raven._pending.size(), 0, "rejoué à son tour")


## Le Contre-chant ne demande pas un sort qui tourne : une Boule de feu revient en froid.
func test_the_countersong_shifts_a_spell_without_a_turn() -> void:
	_learn_class(Character.WITCH, [
		"elemental_projectile", "familiar", "familiar_frugality", "familiar_frugality",
		"familiar_countersong",
	])
	_p.bar.put(3, "familiar")
	assert_true(Gestures.cast(_p, 3))
	_learn("manual_fire", ["fireball"])
	assert_true(SkillCatalog.by_id("fireball").nature_cycle.is_empty())
	_cast_again(2)
	var first: Projectile = _children_of(Projectile)[0]
	assert_eq(first.nature(), DamageType.Kind.FIRE)
	await wait_seconds(Familiar.ECHO_DELAY + 0.05)
	var bolts := _children_of(Projectile)
	var echo: Projectile = bolts[bolts.size() - 1]
	assert_ne(echo, first)
	assert_eq(echo.nature(), DamageType.Kind.COLD, "le feu revient en froid")
	assert_almost_eq(echo._cast.distribution()[DamageType.Kind.COLD], 1.0, 1e-4, "tout en froid")


## Œil du corbeau : l'écho part vers l'ennemi le plus proche du point visé.
func test_the_raven_eye_aims_the_echo_at_the_prey() -> void:
	_learn_class(Character.WITCH, [
		"elemental_projectile", "catalysis", "familiar", "familiar_faithful_echo",
		"familiar_raven_eye", "familiar_raven_eye", "familiar_raven_eye",
	])
	_p.bar.put(3, "familiar")
	_p.bar.put(4, "catalysis")
	var prey := _target(_aim() + Vector2(0, 30))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 3))
	assert_true(Gestures.cast(_p, 4))
	await wait_seconds(Familiar.ECHO_DELAY + 0.05)
	var echoed := _children_of(Catalysis).filter(
		func(c: Catalysis) -> bool: return c.global_position == prey.global_position
	)
	assert_eq(echoed.size(), 1, "sur la proie, pas sur le point visé")


## Ailes noires : tant que le corbeau vole, le joueur va plus vite.
func test_black_wings_quicken_while_the_raven_flies() -> void:
	_learn_class(Character.WITCH, ["elemental_projectile", "familiar", "familiar_black_wings"])
	_p.bar.put(3, "familiar")
	var speed := _p.stats.move_speed
	assert_true(Gestures.cast(_p, 3))
	assert_gt(_p.stats.move_speed, speed)


## Le manuel de classe ne quitte jamais le râtelier : c'est le point repris qui fait
## tomber le corbeau et la poupée — elle sans éclat, ce n'est pas un coup.
func test_the_familiar_and_the_doll_leave_with_their_points() -> void:
	_learn_class(Character.WITCH, ["elemental_projectile", "familiar", "rag_doll"])
	_p.bar.put(3, "familiar")
	_p.bar.put(4, "rag_doll")
	assert_true(Gestures.cast(_p, 3))
	assert_true(Gestures.cast(_p, 4))
	await wait_physics_frames(1)
	assert_true(_p.refund(Rack.CLASS_SLOT, "familiar"))
	assert_true(_p.refund(Rack.CLASS_SLOT, "rag_doll"))
	await wait_physics_frames(3)
	assert_false(_p.lit("familiar"))
	assert_eq(_children_of(RagDoll).size(), 0)
	assert_eq(_children_of(Explosion).size(), 0, "sans éclat")


# --------------------------------------------------------------------------
# Brasero (jalon 42)
# --------------------------------------------------------------------------

func _brazier() -> Brazier:
	var lit := _children_of(Brazier)
	return lit.back() if not lit.is_empty() else null


## Planté au point visé, il crache une boule vers l'ennemi le plus proche à portée, à chaque
## période ; personne à portée, il attend.
func test_the_brazier_spits_at_the_nearest_enemy() -> void:
	_learn("manual_fire", ["brazier"])
	assert_true(Gestures.cast(_p, 2))
	var b := _brazier()
	assert_eq(b.global_position, _aim())
	var cast := _p.resolve(SkillCatalog.by_id("brazier"), 1)
	await wait_seconds(cast.period + 0.1)
	assert_eq(_children_of(Fireball).size(), 0, "personne à portée")
	var prey := _target(_aim() + Vector2(0, 60))
	await wait_physics_frames(2)
	var balls := _children_of(Fireball)
	assert_eq(balls.size(), 1, "une boule, aussitôt")
	assert_true((balls[0] as Fireball).is_shard, "la petite boule")
	await wait_seconds(0.6)
	assert_gt(_hits(prey), 0, "elle l'atteint")
	assert_eq(_children_of(Explosion).size(), 0, "sans dégâts de zone : la touche directe seule")


## Deux à la fois : un troisième éteint le plus ancien, sans dernières braises.
func test_a_third_brazier_puts_out_the_oldest() -> void:
	_learn_with("manual_fire", "brazier", [[SkillStats.LAST_BREATH, 60.0]])
	assert_true(Gestures.cast(_p, 2))
	var first := _brazier()
	_cast_again(2)
	_cast_again(2)
	await wait_physics_frames(1)
	assert_false(is_instance_valid(first), "le plus ancien s'éteint")
	assert_eq(_children_of(Brazier).size(), 2)
	assert_eq(_children_of(Fireball).size(), 0, "remplacé, il ne crache rien")


## Le Foyer du mage : il tire la Boule de feu du joueur, son arbre compris, mais jamais le
## Météore ; la Main d'appoint la fait partir avec la vôtre.
func test_the_hearth_fires_your_fireball_without_its_meteor() -> void:
	_learn_with("manual_fire", "brazier", [[SkillStats.HEARTH, 1.0], [SkillStats.HELPING_HAND, 1.0]])
	for id in ["fireball", "fireball_stoking", "fireball_stoking", "fireball_stoking", "fireball_meteor"]:
		assert_true(_p.invest(0, id), id)
	var fireball := SkillCatalog.by_id("fireball")
	assert_eq(_p.resolve(fireball, 1).shape, Skill.Shape.METEOR)
	assert_eq(_p.resolve(fireball, 1, true).shape, Skill.Shape.BALL, "sans sa transformation")
	assert_true(Gestures.cast(_p, 2))
	var b := _brazier()
	assert_eq(b._ball.shape, Skill.Shape.BALL)
	assert_almost_eq(b._ball.total_max(), _p.resolve(fireball, 1, true).total_max(), 0.01, "vos points, votre arbre")
	_p.bar.put(3, "fireball")
	var mana := _p.mana
	Brazier.assist(_p, _aim() + Vector2(100, 0))
	assert_almost_eq(_p.mana, mana - b._ball.mana_cost, 0.01, "le tir paie la Boule de feu")
	await wait_physics_frames(1)
	assert_eq(_children_of(Fireball).size(), 1, "la Main d'appoint : une boule, pas un météore")
	_p._set_mana(b._ball.mana_cost * 0.5)
	assert_false(b._shoot(_aim() + Vector2(100, 0)), "à court de mana, rien ne part")


## Sous le Foyer du mage, la Salve et la Mitraille restent au brasero : des boules en plus,
## et un rebond.
func test_the_hearth_keeps_the_volley_and_the_grapeshot() -> void:
	_learn_with("manual_fire", "brazier", [
		[SkillStats.HEARTH, 1.0], ["projectiles", 1.0], [SkillStats.BOUNCES, 1.0],
	])
	assert_true(_p.invest(0, "fireball"))
	assert_true(Gestures.cast(_p, 2))
	var b := _brazier()
	assert_eq(b._ball.projectile_count(), 2, "la Salve")
	assert_eq(b._ball.bounces, 1.0, "la Mitraille")
	assert_gt(b._ball.spread_in_degrees, 0.0, "en éventail")


## Le Phare : des PV, une hurtbox du côté du joueur, et les ennemis s'en prennent à lui ;
## abattu, il crache ses dernières braises.
func test_a_beacon_draws_the_blows_and_falls_in_embers() -> void:
	_learn_with("manual_fire", "brazier", [[SkillStats.BEACON, 1.0], [SkillStats.LAST_BREATH, 60.0]])
	var grunt: Enemy = load("res://actors/enemies/grunt.tscn").instantiate()
	add_child_autofree(grunt)
	grunt.setup(_p)
	grunt.global_position = _aim() + Vector2(30, 0)
	assert_true(Gestures.cast(_p, 2))
	var b := _brazier()
	await wait_physics_frames(1)
	assert_almost_eq(b.max_health, _p.stats.max_health * SkillStats.BEACON_LIFE, 0.01)
	assert_eq(grunt.foe(), b, "le brasero, plus proche")
	b._on_damaged(DamageInfo.new(b.max_health + 1.0, grunt.global_position))
	await wait_physics_frames(2)
	assert_false(is_instance_valid(b), "abattu")
	assert_eq(_children_of(Fireball).size(), SkillStats.LAST_BREATH_BALLS, "ses dernières braises")
	assert_eq(grunt.foe(), _p, "et le joueur redevient la cible")


## Le Feu sacré et le Brasier ravivé : un tué de ses boules lui rend du temps et le fait
## tirer aussitôt — pas un tué d'un autre lancer.
func test_a_kill_rekindles_the_brazier() -> void:
	_learn_with("manual_fire", "brazier", [[SkillStats.REKINDLE, 1.0], [SkillStats.QUICKFIRE, 1.0]])
	assert_true(Gestures.cast(_p, 2))
	var b := _brazier()
	var life := b.lifetime()
	_p.states.slew.emit(_p.resolve(SkillCatalog.by_id("brazier"), 1), Vector2.ZERO, null)
	assert_eq(b.lifetime(), life, "le tué d'un autre lancer")
	_p.states.slew.emit(b._cast, Vector2.ZERO, null)
	assert_eq(b.lifetime(), life + 1.0)
	assert_true(b._quick, "un tir dû tout de suite")


## La Triangulation : le second brasero relie ses flammes au premier.
func test_triangulated_braziers_burn_the_line_between_them() -> void:
	_learn_with("manual_fire", "brazier", [[SkillStats.TRIANGULATION, 1.0]])
	assert_true(Gestures.cast(_p, 2))
	assert_eq(_children_of(DashTrail).size(), 0, "seul, rien à relier")
	var first := _brazier()
	_p.global_position += Vector2(0, 60)
	_cast_again(2)
	var trails := _children_of(DashTrail)
	assert_eq(trails.size(), 1)
	var trail: DashTrail = trails[0]
	assert_eq(trail.global_position, first.global_position, "du premier")
	first._go_out(false)
	await wait_physics_frames(1)
	assert_false(is_instance_valid(trail), "l'un des deux parti, le trait s'éteint")


# --------------------------------------------------------------------------
# Éclair vif (jalon 43)
# --------------------------------------------------------------------------

## L'Emballement : chaque lancer rapproché raccourcit le geste, cinq cumuls au plus, et
## une pause les fait retomber.
func test_a_runaway_bolt_casts_faster_while_held() -> void:
	_learn_with("manual_lightning", "swift_bolt", [[SkillStats.RAMP, 10.0]])
	assert_true(Gestures.cast(_p, 2))
	var first: float = _p._recharge_totals[2]
	for i in SkillStats.RAMP_MOST + 1:
		await wait_seconds(_p.remaining_cooldown(2) + 0.02)
		assert_true(Gestures.cast(_p, 2))
	assert_eq(_p._ramps, SkillStats.RAMP_MOST, "pas au-delà du plafond")
	assert_almost_eq(
		_p._recharge_totals[2], first / (1.0 + 0.1 * SkillStats.RAMP_MOST), 0.001, "10 % par cumul"
	)
	await wait_seconds(SkillStats.RAMP_HOLD + 0.1)
	assert_true(Gestures.cast(_p, 2))
	assert_eq(_p._ramps, 0, "une pause les fait retomber")


## Le Plein régime : à pleins cumuls, un tir sur quatre part double.
func test_a_full_throttle_bolt_fires_twice_every_fourth_shot() -> void:
	_learn_with("manual_lightning", "swift_bolt", [[SkillStats.RAMP, 10.0], [SkillStats.FULL_THROTTLE, 1.0]])
	_p._ramps = SkillStats.RAMP_MOST
	_p._ramp_idle = 0.0
	_p._throttle = SkillStats.THROTTLE_EVERY - 1
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(SkillStats.THROTTLE_GAP + 0.05)
	assert_eq(_children_of(Projectile).size(), 2, "un second éclair suit le premier")



## Devenu orbe, le Plein régime double l'orbe.
func test_a_full_throttle_orb_comes_twice() -> void:
	_learn_with(
		"manual_lightning", "swift_bolt", [[SkillStats.RAMP, 10.0], [SkillStats.FULL_THROTTLE, 1.0]],
		Skill.Shape.ORB
	)
	_p._ramps = SkillStats.RAMP_MOST
	_p._ramp_idle = 0.0
	_p._throttle = SkillStats.THROTTLE_EVERY - 1
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(SkillStats.THROTTLE_GAP + 0.05)
	assert_eq(_children_of(StaticOrb).size(), 2)


## Le Paratonnerre : la cible touchée est marquée, et l'éclair suivant s'incurve vers elle.
func test_a_lightning_rod_draws_the_next_bolts() -> void:
	_learn_with("manual_lightning", "swift_bolt", [[SkillStats.LIGHTNING_ROD, 1.0]])
	var marked := _target(Vector2(60, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(0.4)
	assert_eq(LightningRod.target_of(_p.states), marked)
	# Hors de l'axe : un tir droit la manquerait.
	marked.global_position = Vector2(80, 45)
	await wait_seconds(_p.remaining_cooldown(2) + 0.02)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(0.6)
	assert_eq(_hits(marked), 2, "le second s'est incurvé vers elle")


## La Foudre héritée : la marque survit à sa cible et passe à la plus proche.
func test_an_inherited_rod_passes_to_the_nearest_enemy() -> void:
	var cast := SkillStats.new()
	cast.rod_heir = 1.0
	var first := _target(Vector2(60, 0))
	var heir := _target(Vector2(100, 0))
	await wait_physics_frames(2)
	LightningRod.mark(_effects, first, _p.states, cast)
	await wait_physics_frames(2)
	first.queue_free()
	await wait_physics_frames(3)
	assert_eq(LightningRod.target_of(_p.states), heir)


## La Cible de l'orage : le nuage frappe aussi le paratonnerre, hors de son cercle.
func test_the_storm_strikes_the_lightning_rod() -> void:
	var rod_cast := SkillStats.new()
	rod_cast.storm_target = 1.0
	var marked := _target(Vector2(200, 0))
	var beside := _target(Vector2(100, 120))
	await wait_physics_frames(2)
	LightningRod.mark(_effects, marked, _p.states, rod_cast)
	await wait_physics_frames(2)
	StormCloud.put(_effects, Vector2(100, 0), _p.resolve(SkillCatalog.by_id("storm_cloud"), 1), _p.states)
	await wait_physics_frames(3)
	assert_eq(_hits(marked), 1, "à 100 px, hors du cercle")
	assert_eq(_hits(beside), 0)


## L'Électrocution : un critique engourdit à coup sûr. Vingt coups faibles, dont la
## chance ordinaire n'engourdirait qu'une poignée.
func test_an_electrocuting_crit_always_numbs() -> void:
	var cast := SkillStats.new()
	cast.electrocute = 1.0
	cast.crit_chance = 1.0
	for i in 20:
		var h := _target(Vector2(300 + i * 20, 300))
		h.states = StatusEffects.new()
		var parts := DamageType.empty_parts()
		parts[DamageType.Kind.LIGHTNING] = 1.0
		h.take_damage(DamageInfo.roll(cast, Vector2.ZERO, parts))
		assert_true(h.states.active(StatusEffects.Kind.NUMB))


## Le Carambolage : l'éclair repart du mur au lieu de s'y éteindre.
func test_a_caroming_bolt_bounces_off_a_wall() -> void:
	_learn_with("manual_lightning", "swift_bolt", [[SkillStats.CAROMS, 1.0]])
	_wall(Vector2(60, 0), Vector2(10, 200))
	var behind := _target(Vector2(-60, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(1.0)
	assert_eq(_hits(behind), 1, "revenu du mur")


## Le Satellite : l'orbe tourne autour de son lanceur, et le suit.
func test_a_satellite_orb_circles_its_caster() -> void:
	_learn_with("manual_lightning", "swift_bolt", [[SkillStats.SATELLITE, 1.0]], Skill.Shape.ORB)
	assert_true(Gestures.cast(_p, 2))
	var orb: StaticOrb = _children_of(StaticOrb)[0]
	await wait_seconds(0.3)
	var start := orb.global_position
	_p.global_position += Vector2(40, 30)
	await wait_seconds(0.3)
	assert_almost_eq(orb.global_position.distance_to(_p.global_position), SkillStats.SATELLITE_RADIUS, 0.5)
	assert_ne(orb.global_position, start)


## Une limite par lanceur : un orbe de trop dissout le plus ancien, et le Familier compte à part.
func test_one_orb_too_many_dissolves_the_oldest() -> void:
	var cast := _p.resolve(SkillCatalog.by_id("swift_bolt"), 1)
	cast.simultaneous = 6.0
	var orbs: Array[StaticOrb] = []
	for i in 7:
		orbs.append(StaticOrb.send(_effects, Vector2(0, i * 40), Vector2.RIGHT, cast, _p.states, _p))
	assert_true(orbs[0].is_queued_for_deletion(), "le plus ancien")
	for i in range(1, 7):
		assert_false(orbs[i].is_queued_for_deletion())
	var crow := Node2D.new()
	autofree(crow)
	StaticOrb.send(_effects, Vector2(0, 300), Vector2.RIGHT, cast, _p.states, crow)
	assert_false(orbs[1].is_queued_for_deletion(), "l'écho n'en chasse aucun")


## Une frappe dans une meute ne dessine que quelques arcs : les dégâts, tous.
func test_an_orb_strike_draws_only_a_few_arcs() -> void:
	var cast := _p.resolve(SkillCatalog.by_id("swift_bolt"), 1)
	cast.radius = 40.0
	var pack: Array[Hurtbox] = []
	for i in Lightning.ARCS_MOST + 3:
		pack.append(_target(Vector2(200 + i * 4, 200)))
	await wait_physics_frames(2)
	var orb := StaticOrb.send(_effects, Vector2(200, 180), Vector2.RIGHT, cast, _p.states)
	orb._strike()
	assert_eq(orb._bolts.size(), Lightning.ARCS_MOST)
	for target in pack:
		assert_eq(_hits(target), 1)


## Plusieurs satellites se répartissent autour du lanceur : deux, de part et d'autre.
func test_satellites_spread_evenly_around_their_caster() -> void:
	_learn_with(
		"manual_lightning", "swift_bolt", [[SkillStats.SATELLITE, 1.0], ["projectiles", 1.0]], Skill.Shape.ORB
	)
	assert_true(Gestures.cast(_p, 2))
	var orbs := _children_of(StaticOrb)
	assert_eq(orbs.size(), 2)
	assert_almost_eq(
		orbs[0].global_position.distance_to(orbs[1].global_position), SkillStats.SATELLITE_RADIUS * 2.0, 0.5
	)


## L'Orbe chargé : chaque ennemi frappé élargit ses décharges, cinq au plus.
func test_a_charged_orb_reaches_farther_per_enemy_met() -> void:
	var cast := _p.resolve(SkillCatalog.by_id("swift_bolt"), 1)
	cast.radius = 28.0
	cast.charged_orb = 10.0
	var orb := StaticOrb.send(_effects, Vector2.ZERO, Vector2.RIGHT, cast, _p.states)
	for i in SkillStats.CHARGED_ORB_MOST + 2:
		orb._met[i] = true
	assert_almost_eq(orb.reach(), 28.0 * 1.5, 0.001)


## La Glace vive : sur un transi, le trait ajoute une part de foudre.
func test_live_ice_adds_lightning_against_the_chilled() -> void:
	var bolt: Projectile = _p.bolt_scene.instantiate()
	autofree(bolt)
	bolt._cast = SkillStats.new()
	bolt._cast.live_ice = 50.0
	bolt._parts = DamageType.empty_parts()
	bolt._parts[DamageType.Kind.COLD] = 10.0
	var target := _target(Vector2(300, 300))
	target.states = StatusEffects.new()
	assert_eq(bolt._conducted(target)[DamageType.Kind.LIGHTNING], 0.0, "rien sur un ennemi sain")
	target.states.put(StatusEffects.Kind.CHILL, 1.0)
	assert_eq(bolt._conducted(target)[DamageType.Kind.LIGHTNING], 5.0)


# --------------------------------------------------------------------------
# Nuage d'orage (jalon 43)
# --------------------------------------------------------------------------

## Trois nuages par lanceur : le quatrième dissipe le plus ancien, et le Familier compte à part.
func test_a_fourth_cloud_dissipates_the_oldest() -> void:
	var cast := _p.resolve(SkillCatalog.by_id("storm_cloud"), 1)
	var clouds: Array[StormCloud] = []
	for i in 4:
		clouds.append(StormCloud.put(_effects, Vector2(i * 80, 0), cast, _p.states, null, _p))
	assert_true(clouds[0].is_queued_for_deletion(), "le plus ancien")
	for i in range(1, 4):
		assert_false(clouds[i].is_queued_for_deletion())
	var crow := Node2D.new()
	autofree(crow)
	var echo := StormCloud.put(_effects, Vector2(0, 80), cast, _p.states, null, crow)
	assert_false(clouds[1].is_queued_for_deletion(), "l'écho n'en chasse aucun")
	assert_false(echo.is_queued_for_deletion())


# --------------------------------------------------------------------------
# Chaîne d'éclairs (jalon 43)
# --------------------------------------------------------------------------

func _numbed(position: Vector2) -> Hurtbox:
	var h := _target(position)
	h.states = StatusEffects.new()
	h.states.put(StatusEffects.Kind.NUMB, 1.0)
	return h


## La Conductance : les engourdis ne comptent pas, la décharge va plus loin.
func test_a_conductive_chain_runs_through_the_numbed() -> void:
	_learn_with("manual_lightning", "chain_lightning", [[SkillStats.CONDUCTANCE, 1.0]])
	var line: Array[Hurtbox] = [_numbed(Vector2(60, 0)), _numbed(Vector2(120, 0))]
	for i in 4:
		line.append(_target(Vector2(180 + i * 60, 0)))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	for i in 5:
		assert_eq(_hits(line[i]), 1, "deux engourdis gratuits, puis trois cibles")
	assert_eq(_hits(line[5]), 0)


## La Bifurcation, à coup sûr : une branche part du point d'avant vers un autre ennemi.
func test_a_bifurcating_chain_sends_a_branch() -> void:
	_learn_with("manual_lightning", "chain_lightning", [[SkillStats.BIFURCATION, 100.0]])
	for x in [60, 120, 180]:
		_target(Vector2(x, 0))
	var aside := _target(Vector2(120, 60))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	assert_eq(_hits(aside), 1, "pris par la branche, partie de la première cible")
	assert_eq(_children_of(ChainLightning).size(), 2, "le tronc et sa branche")


## Le Retour par la masse : du mana par ennemi touché.
func test_a_grounded_chain_gives_back_mana() -> void:
	_learn_with("manual_lightning", "chain_lightning", [[SkillStats.GROUNDING, 2.0]])
	_target(Vector2(60, 0))
	_target(Vector2(120, 0))
	await wait_physics_frames(2)
	_p._set_mana(100.0)
	var cost := _p.resolve(SkillCatalog.by_id("chain_lightning"), 1).mana_cost
	assert_true(Gestures.cast(_p, 2))
	assert_almost_eq(_p.mana, 100.0 - cost + 4.0, 0.001)


func _charge_at(position: Vector2) -> StaticCharge:
	var parts := DamageType.empty_parts()
	var charge := StaticCharge.put(_effects, position, Vector2.RIGHT, parts, _p.states)
	charge._toward = Vector2.ZERO
	return charge


## Le Relais : la décharge passe par une charge pour atteindre un ennemi hors de saut.
## Le Réamorçage : la charge rend son saut.
func test_a_relayed_chain_jumps_through_a_static_charge() -> void:
	_learn_with("manual_lightning", "chain_lightning", [["targets", -1.0], [SkillStats.RELAY, 1.0]])
	var first := _target(Vector2(60, 0))
	var charge := _charge_at(Vector2(110, 0))
	var beyond := _target(Vector2(160, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	assert_eq(_hits(first), 1)
	assert_true(charge.is_queued_for_deletion(), "la charge prise éclate")
	assert_eq(_hits(beyond), 0, "deux sauts : la cible et la charge")


func test_a_reprimed_relay_gives_its_jump_back() -> void:
	_learn_with(
		"manual_lightning", "chain_lightning",
		[["targets", -1.0], [SkillStats.RELAY, 1.0], [SkillStats.RELAY_REFUND, 1.0]]
	)
	_target(Vector2(60, 0))
	_charge_at(Vector2(110, 0))
	var beyond := _target(Vector2(160, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	assert_eq(_hits(beyond), 1, "la charge n'a pas usé de saut")


## La Ramure : chaque arc de la toile saute encore une fois, à une part du coup.
func test_each_arc_of_an_antlered_web_leaps_once_more() -> void:
	_learn_with("manual_lightning", "chain_lightning", [[SkillStats.WEB_BRANCH, 50.0]], Skill.Shape.WEB)
	_p.skill_mods.assign([StatMod.new("crit_chance", StatMod.Mode.PERCENT, -100.0)])
	var ahead := _target(Vector2(60, 0))
	_target(Vector2(-60, 0))
	_target(Vector2(0, 60))
	var past := _target(Vector2(110, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	assert_eq(_hits(past), 1)
	assert_almost_eq(float(_received_all[past][0]), float(_received_all[ahead][0]) * 0.5, 0.001)


## Le Survoltage : l'explosion d'un engourdi tué relance une chaîne depuis lui.
func test_an_overvolted_kill_relaunches_a_chain() -> void:
	var cast := _p.resolve(SkillCatalog.by_id("chain_lightning"), 1)
	cast.kill_burst = 20.0
	cast.overvolt = 30.0
	var near := _target(Vector2(110, 0))
	await wait_physics_frames(2)
	var victim := StatusEffects.new()
	victim.put(StatusEffects.Kind.NUMB, 1.0)
	_p.states.slew.emit(cast, Vector2(40, 0), victim)
	await wait_physics_frames(3)
	assert_eq(_hits(near), 1, "hors de l'explosion, pris par la chaîne relancée")
	assert_eq(_children_of(ChainLightning).size(), 1)


# --------------------------------------------------------------------------
# Nuage d'orage (jalon 43), ses nœuds
# --------------------------------------------------------------------------

## Un nuage rapide, sans critique, aux dégâts fixes : ce qu'il inflige se calcule.
func _storm(changes: Dictionary) -> SkillStats:
	var cast := _p.resolve(SkillCatalog.by_id("storm_cloud"), 1)
	cast.period = 0.1
	cast.crit_chance = 0.0
	for n in cast.damage_min.size():
		cast.damage_min[n] = cast.damage_max[n]
	for key: String in changes:
		cast.set(key, changes[key])
	return cast


## L'Accumulation : les frappes à vide chargent, la suivante qui touche les dépense.
func test_an_accumulating_cloud_charges_on_empty_strikes() -> void:
	var cast := _storm({SkillStats.ACCUMULATION: 20.0})
	var cloud := StormCloud.put(_effects, Vector2(300, 300), cast, _p.states)
	await wait_seconds(0.15)
	assert_eq(cloud._charges, 2, "deux frappes à vide")
	var under := _target(Vector2(300, 300))
	await wait_seconds(0.12)
	assert_almost_eq(float(_received_all[under][0]), cast.total_max() * 1.4, 0.01)
	assert_eq(cloud._charges, 0, "dépensées")


## Le Point de rupture : à pleines charges, la frappe va au double du rayon.
func test_a_breaking_cloud_strikes_wide_at_full_charges() -> void:
	var cast := _storm({SkillStats.ACCUMULATION: 20.0, SkillStats.BREAKING_POINT: 1.0})
	var aside := _target(Vector2(300 + cast.radius * 1.5, 300))
	await wait_physics_frames(2)
	var cloud := StormCloud.put(_effects, Vector2(300, 300), cast, _p.states)
	cloud._charges = SkillStats.ACCUMULATION_MOST
	await wait_physics_frames(2)
	assert_eq(_hits(aside), 1)


## Le Débordement : un arc vers l'ennemi hors du cercle, à une part de la frappe.
func test_an_overflowing_cloud_arcs_beyond_its_circle() -> void:
	var cast := _storm({SkillStats.OVERFLOW: 40.0})
	var aside := _target(Vector2(300 + cast.radius * 1.5, 300))
	await wait_physics_frames(2)
	StormCloud.put(_effects, Vector2(300, 300), cast, _p.states)
	await wait_physics_frames(2)
	assert_eq(_hits(aside), 1)
	assert_almost_eq(float(_received_all[aside][0]), cast.total_max() * 0.4, 0.01)


## La Foudre jumelle, à coup sûr : chaque frappe tombe deux fois.
func test_a_twin_strike_lands_twice() -> void:
	var cast := _storm({SkillStats.TWIN_STRIKE: 100.0})
	cast.period = 0.5
	var under := _target(Vector2(300, 300))
	await wait_physics_frames(2)
	StormCloud.put(_effects, Vector2(300, 300), cast, _p.states)
	await wait_seconds(SkillStats.TWIN_DELAY + 0.08)
	assert_eq(_hits(under), 2)


## L'Appel d'air : la frappe tire vers le centre — un recul négatif.
func test_an_updraft_pulls_toward_the_center() -> void:
	var cast := _storm({SkillStats.PULL: 60.0})
	var under := _target(Vector2(310, 300))
	var pulls: Array[float] = []
	under.damaged.connect(func(info: DamageInfo) -> void: pulls.append(info.knockback))
	await wait_physics_frames(2)
	StormCloud.put(_effects, Vector2(300, 300), cast, _p.states)
	await wait_physics_frames(2)
	assert_eq(pulls[0], -60.0)


## La Traque : le nuage garde sa proie, même quand une autre passe plus près.
func test_a_hunting_cloud_keeps_its_prey() -> void:
	var cast := _storm({SkillStats.SEEK: 200.0, SkillStats.HUNT: 1.0})
	var prey := _target(Vector2(380, 300))
	var other := _target(Vector2(500, 300))
	await wait_physics_frames(2)
	var cloud := StormCloud.put(_effects, Vector2(300, 300), cast, _p.states)
	await wait_physics_frames(2)
	assert_eq(cloud._quarry, prey)
	other.global_position = cloud.global_position + Vector2(5, 0)
	await wait_seconds(0.25)
	assert_eq(cloud._quarry, prey, "elle ne la lâche pas")


## Le Front mobile : porté par quelqu'un qui marche, il frappe plus que sa durée ne compte.
func test_a_moving_front_strikes_more_while_walking() -> void:
	var cast := _storm({SkillStats.MOVING_FRONT: 100.0})
	cast.duration = 0.5
	var walker := Node2D.new()
	add_child_autofree(walker)
	var cloud := StormCloud.put(_effects, Vector2.ZERO, cast, _p.states, walker)
	var strikes := 0
	while is_instance_valid(cloud) and not cloud.is_queued_for_deletion():
		walker.position.x += 2.0
		strikes = cloud._strikes
		await wait_physics_frames(1)
	assert_gt(strikes, cast.strikes_over_duration() + 2)



# --------------------------------------------------------------------------
# Ruée d'orage (jalon 43)
# --------------------------------------------------------------------------

## Le Trait d'éclair : ce qui est sur le trajet est frappé, ce qui est à côté non.
func test_a_lightning_streak_strikes_along_the_dash() -> void:
	_learn_with("manual_lightning", "storm_dash", [[SkillStats.BOLT_DASH, 1.0]])
	var on_the_way := _target(Vector2(Player.PLACEMENT_RANGE * 0.5, 0))
	var aside := _target(Vector2(Player.PLACEMENT_RANGE * 0.5, 60))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	assert_eq(_hits(on_the_way), 1)
	assert_eq(_hits(aside), 0)


## L'Aller-retour : on revient au départ, et l'éclair refrappe le trajet.
func test_a_round_trip_brings_back_to_the_start() -> void:
	_learn_with("manual_lightning", "storm_dash", [[SkillStats.BOLT_DASH, 1.0], [SkillStats.ROUND_TRIP, 1.0]])
	var on_the_way := _target(Vector2(Player.PLACEMENT_RANGE * 0.5, 0))
	await wait_physics_frames(2)
	var start := _p.global_position
	assert_true(Gestures.cast(_p, 2))
	assert_ne(_p.global_position, start)
	await wait_seconds(SkillStats.ROUND_TRIP_DELAY + 0.1)
	assert_almost_eq(_p.global_position.distance_to(start), 0.0, 1.0)
	assert_eq(_hits(on_the_way), 2)


## Le Tonnerre roulant : l'arrivée frappe encore deux fois.
func test_rolling_thunder_rumbles_twice_more() -> void:
	_learn_with(
		"manual_lightning", "storm_dash", [[SkillStats.END_BURST, 30.0], [SkillStats.ROLLING_THUNDER, 30.0]]
	)
	var landing := _target(Vector2(Player.PLACEMENT_RANGE, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(SkillStats.ROLLING_GAP * SkillStats.ROLLING_COUNT + 0.15)
	assert_eq(_hits(landing), 1 + SkillStats.ROLLING_COUNT)


## La Tension accumulée : la course charge le prochain sort de foudre, qui la dépense.
func test_built_up_tension_charges_the_next_lightning_spell() -> void:
	_learn_with("manual_lightning", "storm_dash", [[SkillStats.CHARGED_RUN, 10.0]])
	_p.invest(0, "swift_bolt")
	_p.bar.put(3, "swift_bolt")
	assert_true(Gestures.cast(_p, 2))
	var run := minf(Player.PLACEMENT_RANGE, SkillStats.CHARGED_RUN_MOST)
	assert_almost_eq(_p._tension, 10.0 * run / SkillStats.CHARGED_RUN_STEP, 0.5)
	assert_gt(_p._tension_left, 0.0)
	assert_true(Gestures.cast(_p, 3))
	assert_eq(_p._tension_left, 0.0, "dépensée")


## Le Réarmement : chaque engourdi dans l'explosion d'arrivée raccourcit la recharge.
func test_rearming_shortens_the_cooldown_per_numbed() -> void:
	_learn_with("manual_lightning", "storm_dash", [[SkillStats.END_BURST, 40.0], [SkillStats.REARM, 0.5]])
	for dy in [-10, 10]:
		var h := _target(Vector2(Player.PLACEMENT_RANGE, dy))
		h.states = StatusEffects.new()
		h.states.put(StatusEffects.Kind.NUMB, 1.0)
	await wait_physics_frames(2)
	var interval := _p.resolve(SkillCatalog.by_id("storm_dash"), 1).interval
	assert_true(Gestures.cast(_p, 2))
	assert_almost_eq(_p.remaining_cooldown(2), interval - 1.0, 0.001)


## Les Mines statiques : plus larges, plus fortes, et une seule morsure.
func test_a_static_mine_bites_once_then_goes_out() -> void:
	var parts := DamageType.empty_parts()
	parts[DamageType.Kind.LIGHTNING] = 10.0
	var mine := StaticCharge.put(_effects, Vector2(300, 300), Vector2.RIGHT, parts, _p.states, 0.5, true)
	mine._toward = Vector2.ZERO
	var first := _target(Vector2(300 + StaticCharge.RADIUS * 1.5, 300))
	await wait_seconds(0.3)
	assert_eq(_hits(first), 1, "hors du rayon d'une charge, dans celui d'une mine")
	assert_almost_eq(float(_received_all[first][0]), 10.0 * 0.5 * SkillStats.MINE_FACTOR, 0.01)
	assert_false(is_instance_valid(mine) and not mine.is_queued_for_deletion(), "éteinte")


## Le Galop : chaque ruée ajoute une charge à l'appel du tonnerre, trois au plus.
func test_gallop_stacks_thunder_call() -> void:
	_learn_with("manual_lightning", "storm_dash", [[SkillStats.GALLOP, 1.0]])
	var speed := _p.stats.move_speed
	assert_true(Gestures.cast(_p, 2))
	var once := _p.stats.move_speed - speed
	for i in SkillStats.GALLOP_MOST:
		_p._recharges[2] = 0.0
		await wait_physics_frames(1)
		assert_true(Gestures.cast(_p, 2))
	assert_eq(_p.lit_stacks("storm_dash"), SkillStats.GALLOP_MOST)
	assert_almost_eq(_p.stats.move_speed - speed, once * SkillStats.GALLOP_MOST, 0.01)


# --------------------------------------------------------------------------
# Électricité statique (jalon 43)
# --------------------------------------------------------------------------

## L'Ionisation : chaque seconde, le champ engourdit ce qui est près de vous.
func test_an_ionizing_field_numbs_around_you() -> void:
	_learn_with("manual_lightning", "static_electricity", [[SkillStats.IONIZE, 100.0]])
	var near := _target(Vector2(30, 0))
	near.states = StatusEffects.new()
	var far := _target(Vector2(SkillStats.IONIZE_RADIUS + 40, 0))
	far.states = StatusEffects.new()
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(SkillStats.IONIZE_PERIOD + 0.1)
	assert_true(near.states.active(StatusEffects.Kind.NUMB))
	assert_false(far.states.active(StatusEffects.Kind.NUMB))


## La Capacité : sous le champ, une charge laissée vit plus longtemps.
func test_capacitance_lengthens_the_static_charges() -> void:
	_learn_with("manual_lightning", "static_electricity", [[SkillStats.CAPACITY, 1.5]])
	assert_true(Gestures.cast(_p, 2))
	_p.stats.static_charge_chance = 100.0
	var victim := StatusEffects.new()
	victim.put(StatusEffects.Kind.NUMB, 1.0)
	_p._on_struck(Vector2(40, 0), DamageType.empty_parts(), victim)
	await wait_physics_frames(2)
	var charge: StaticCharge = _children_of(StaticCharge)[0]
	assert_almost_eq(charge._life, StaticCharge.LIFE + 1.5, 0.001)


func _grunt(position: Vector2) -> Enemy:
	var grunt: Enemy = load("res://actors/enemies/grunt.tscn").instantiate()
	add_child_autofree(grunt)
	grunt.global_position = position
	return grunt


## Le Choc en retour : un coup au contact revient en arc ; la Cage de Faraday s'ensuit, une
## fois, puis se lève.
func test_a_backlash_answers_a_melee_blow_then_the_cage_closes() -> void:
	_learn_with(
		"manual_lightning", "static_electricity", [[SkillStats.BACKLASH, 50.0], [SkillStats.FARADAY, 1.0]]
	)
	assert_true(Gestures.cast(_p, 2))
	var grunt := _grunt(Vector2(20, 0))
	await wait_physics_frames(2)
	var full := grunt.health
	_p.melee_blow(grunt, 20.0)
	assert_lt(grunt.health, full, "l'arc l'a frappé")
	assert_true(_p.hurtbox.invulnerable, "la cage")
	await wait_seconds(SkillStats.FARADAY_TIME + 0.1)
	assert_false(_p.hurtbox.invulnerable, "levée")
	_p.melee_blow(grunt, 20.0)
	assert_false(_p.hurtbox.invulnerable, "pas avant son attente")


## Le Condensateur : dix morsures chargent le sort de foudre suivant, qui les dépense.
func test_a_full_capacitor_charges_the_next_lightning_spell() -> void:
	_learn_with("manual_lightning", "static_electricity", [[SkillStats.CONDENSER, 50.0]])
	_p.invest(0, "swift_bolt")
	_p.bar.put(3, "swift_bolt")
	assert_true(Gestures.cast(_p, 2))
	for i in SkillStats.CONDENSER_MOST:
		_p._charge_bit(1.0)
	assert_eq(_p._condensed, SkillStats.CONDENSER_MOST)
	assert_true(Gestures.cast(_p, 3))
	assert_eq(_p._condensed, 0, "dépensé")


## La Décharge totale : à pleins cumuls, une nova part d'elle-même, de ce que les charges
## ont mordu.
func test_a_total_discharge_bursts_by_itself() -> void:
	_learn_with("manual_lightning", "static_electricity", [[SkillStats.TOTAL_DISCHARGE, 1.0]])
	assert_true(Gestures.cast(_p, 2))
	var near := _target(Vector2(20, 0))
	await wait_physics_frames(2)
	for i in SkillStats.CONDENSER_MOST:
		_p._charge_bit(3.0)
	await wait_physics_frames(3)
	assert_eq(_hits(near), 1)
	assert_almost_eq(float(_received_all[near][0]), 30.0, 0.01)
	assert_eq(_p._condensed, 0)


# --------------------------------------------------------------------------
# Pics de glace (jalon 44)
# --------------------------------------------------------------------------

## Le Plein centre : au cœur du cercle, le même tirage frappe plus fort.
func test_the_bullseye_bites_harder_at_the_heart() -> void:
	_learn_with("manual_cold", "ice_spike", [[SkillStats.EYE, 50.0]])
	_p.stats.crit_chance = 0.0
	var point := _aim()
	var heart := _target(point)
	var rim := _target(point + Vector2(0, 20))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(3)
	assert_almost_eq(float(_received_all[heart][0]), float(_received_all[rim][0]) * 1.5, 0.01)


## La Réplique, et les Secousses qui la répètent : le même cœur, plus tard.
func test_an_aftershock_strikes_again_and_tremors_repeat_it() -> void:
	_learn_with("manual_cold", "ice_spike", [[SkillStats.AFTERSHOCK, 50.0], [SkillStats.TREMORS, 2.0]])
	var below := _target(_aim())
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(SkillStats.AFTERSHOCK_GAP * 3.0 + 0.1)
	assert_eq(_hits(below), 4, "le coup, la réplique et deux secousses")
	await wait_seconds(SkillStats.AFTERSHOCK_GAP * 2.0)
	assert_eq(_hits(below), 4, "une réplique ne réplique pas")


## La réplique reste un pic : sous les Éclats, elle projette les siens.
func test_an_aftershock_is_a_whole_spike_with_its_shards() -> void:
	_learn_with("manual_cold", "ice_spike", [[SkillStats.AFTERSHOCK, 50.0], [SkillStats.SPLITS, 2.0]])
	var thrown := [0]
	_effects.child_entered_tree.connect(
		func(n: Node) -> void: thrown[0] += 1 if n is Projectile else 0
	)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(SkillStats.AFTERSHOCK_GAP + IceSpikes.LIFETIME + 0.15)
	assert_eq(thrown[0], 4, "deux éclats du pic, deux de sa réplique")


## Le Bosquet : un cercle de plus, contre le premier, sur le côté de la visée.
func test_a_grove_raises_a_circle_beside_the_first() -> void:
	_learn_with("manual_cold", "ice_spike", [[SkillStats.GROVE, 1.0]])
	var radius := _p.resolve(SkillCatalog.by_id("ice_spike"), 1).radius
	var beside := _target(_aim() + _p.facing.rotated(PI * 0.5) * radius * 2.0)
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	assert_eq(_children_of(IceSpikes).size(), 2)
	await wait_physics_frames(3)
	assert_eq(_hits(beside), 1)


## Le Glacier perce un lancer sur trois, plus large.
func test_a_glacier_comes_every_third_cast() -> void:
	_learn_with("manual_cold", "ice_spike", [[SkillStats.GLACIER, 1.0]])
	var radius := _p.resolve(SkillCatalog.by_id("ice_spike"), 1).radius
	_p._glacier = SkillStats.GLACIER_EVERY - 2
	assert_true(Gestures.cast(_p, 2))
	assert_almost_eq((_children_of(IceSpikes)[0] as IceSpikes)._cast.radius, radius, 0.01)
	_p._recharges[2] = 0.0
	assert_true(Gestures.cast(_p, 2))
	assert_almost_eq(
		(_children_of(IceSpikes)[1] as IceSpikes)._cast.radius, radius * SkillStats.GLACIER_RADIUS, 0.01
	)


## Sous le Sérac, un lancer sur deux.
func test_a_serac_glacier_comes_every_second_cast() -> void:
	_learn_with("manual_cold", "ice_spike", [[SkillStats.GLACIER, 1.0], [SkillStats.SERAC, 1.0]])
	var radius := _p.resolve(SkillCatalog.by_id("ice_spike"), 1).radius
	_p._glacier = SkillStats.SERAC_EVERY - 1
	assert_true(Gestures.cast(_p, 2))
	assert_almost_eq(
		(_children_of(IceSpikes)[-1] as IceSpikes)._cast.radius, radius * SkillStats.GLACIER_RADIUS, 0.01
	)


## La Cristallisation : des pics lancés dans le vortex lui rendent du temps, jusqu'à deux
## fois sa durée.
func test_spikes_cast_in_the_vortex_feed_it() -> void:
	_learn_with("manual_cold", "ice_spike", [[SkillStats.CRYSTALLIZE, 1.0]])
	assert_true(_p.invest(0, "winter_disaster"))
	_p.bar.put(3, "winter_disaster")
	assert_true(Gestures.cast(_p, 3))
	var vortex: IceVortex = _children_of(IceVortex)[0]
	var base := vortex._cast.duration
	vortex.global_position = _aim()
	assert_true(Gestures.cast(_p, 2))
	assert_almost_eq(vortex._cast.duration, base + SkillStats.CRYSTALLIZE_TIME, 0.001)
	for i in 30:
		IceVortex.feed(vortex.global_position, _p.states, SkillStats.CRYSTALLIZE_TIME)
	assert_almost_eq(vortex._cast.duration, base * 2.0, 0.001, "pas au-delà du double")


## La Crevasse : au bout du sillon, un cercle deux fois plus large, sur le point visé.
func test_a_crevasse_opens_at_the_end_of_the_furrow() -> void:
	_learn_with("manual_cold", "ice_spike", [[SkillStats.CREVASSE, 1.0]], Skill.Shape.FISSURE)
	var radius := _p.resolve(SkillCatalog.by_id("ice_spike"), 1).radius
	assert_true(Gestures.cast(_p, 2))
	var last: IceSpikes = _children_of(IceSpikes)[-1]
	assert_eq(last.global_position, _aim())
	assert_almost_eq(last._cast.radius, radius * SkillStats.CREVASSE_RADIUS, 0.01)


## Le Grésil : un éclat qui partirait à côté s'incurve vers l'ennemi.
func test_sleet_shards_curve_toward_an_enemy() -> void:
	_learn_with("manual_cold", "ice_spike", [[SkillStats.SPLITS, 1.0], [SkillStats.SEEK, 200.0]])
	var aside := _target(_aim() + Vector2(60, 30))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(IceSpikes.LIFETIME + 0.6)
	assert_eq(_hits(aside), 1)


# --------------------------------------------------------------------------
# Nova de glace (jalon 44)
# --------------------------------------------------------------------------

## Le Grand froid : la nova frappe plus fort par transi dans son cercle, sain compris.
func test_deep_cold_bites_harder_in_a_chilled_crowd() -> void:
	for at in [Vector2(20, 0), Vector2(-20, 0)]:
		var chilled := _target(at)
		chilled.states = StatusEffects.new()
		chilled.states.put(StatusEffects.Kind.CHILL, 1.0)
	var healthy := _target(Vector2(0, 20))
	await wait_physics_frames(2)
	var parts := DamageType.empty_parts()
	parts[DamageType.Kind.COLD] = 10.0
	var nova := Explosion.put(_effects, _p.global_position, parts, 46.0, null, Color.WHITE, _p.states, SkillStats.new())
	nova.crowd = 10.0
	await wait_physics_frames(3)
	assert_almost_eq(float(_received_all[healthy][0]), 12.0, 0.01, "deux transis, +10 % chacun")


## La nova pose ses deux nombres sur son explosion : le Grand froid et le Repoussoir.
func test_the_nova_carries_its_crowd_and_its_push() -> void:
	_learn_with("manual_cold", "ice_nova", [[SkillStats.DEEP_COLD, 4.0], [SkillStats.KNOCKBACK, 30.0]])
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(1)
	var nova: Explosion = _children_of(Explosion)[0]
	assert_eq(nova.crowd, 4.0)
	assert_eq(nova.knockback, 30.0)


## Le Frimas : le transi de la nova dure davantage.
func test_rime_makes_the_nova_chill_last() -> void:
	_learn_with("manual_cold", "ice_nova", [[SkillStats.RIME, 1.5], ["status_chance_increase", 500.0]])
	var target := _target(Vector2(20, 0))
	target.states = StatusEffects.new()
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(3)
	assert_gt(
		target.states._state(StatusEffects.Kind.CHILL).remaining,
		StatusEffects.DURATIONS[StatusEffects.Kind.CHILL] + 1.0
	)


## Le Sursaut : un gros coup fait partir la nova, un petit non ; puis il attend.
func test_a_heavy_blow_startles_a_nova_out() -> void:
	_learn_with("manual_cold", "ice_nova", [[SkillStats.STARTLE, 1.0]])
	var full := _p.stats.max_health
	_p._on_damaged(DamageInfo.new(full * 0.07, Vector2(10, 0)))
	await wait_physics_frames(2)
	assert_eq(_children_of(Explosion).size(), 0, "un petit coup ne suffit pas")
	_p._on_damaged(DamageInfo.new(full * 0.2, Vector2(10, 0)))
	await wait_physics_frames(2)
	assert_eq(_children_of(Explosion).size(), 1)
	_p._on_damaged(DamageInfo.new(full * 0.2, Vector2(10, 0)))
	await wait_physics_frames(2)
	assert_eq(_children_of(Explosion).size(), 1, "pas avant son attente")


## Le Qui-vive : un coup plus petit suffit.
func test_on_alert_a_smaller_blow_startles() -> void:
	_learn_with("manual_cold", "ice_nova", [[SkillStats.STARTLE, 1.0], [SkillStats.ALERT, 1.0]])
	_p._on_damaged(DamageInfo.new(_p.stats.max_health * 0.07, Vector2(10, 0)))
	await wait_physics_frames(2)
	assert_eq(_children_of(Explosion).size(), 1)
	assert_almost_eq(_p._startle_wait, SkillStats.ALERT_PERIOD, 0.1, "et revient plus vite")


## Le Reflux : l'anneau se referme et refrappe une fois ce qu'il croise.
func test_an_ebbing_wave_strikes_again_on_its_way_back() -> void:
	_learn_with("manual_cold", "ice_nova", [[SkillStats.EBB, 1.0]], Skill.Shape.RING)
	var target := _target(Vector2(60, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(FrostRing.LIFETIME * 2.0 + 0.1)
	assert_eq(_hits(target), 2)
	assert_eq(_children_of(FrostRing).size(), 0, "puis il s'efface")


## La Glace noire : le sol gelé de la nova retient où le joueur glisse.
func test_black_ice_remembers_the_frozen_ground() -> void:
	_learn_with("manual_cold", "ice_nova", [[SkillStats.GROUND, 2.0], [SkillStats.BLACK_ICE, 50.0]])
	assert_true(Gestures.cast(_p, 2))
	assert_eq(_p._black_ice_at, _p.global_position)
	assert_eq(_p._black_ice, 50.0)
	assert_almost_eq(_p._black_ice_left, 2.0, 0.001)


# --------------------------------------------------------------------------
# Tombeau de glace (jalon 44)
# --------------------------------------------------------------------------

## La Peau de givre : qui frappe au contact est transi, à la force du nœud.
func test_frost_skin_chills_a_melee_attacker() -> void:
	_learn_with("manual_cold", "frost_tomb", [[SkillStats.FROST_SKIN, 60.0]])
	assert_true(Gestures.cast(_p, 2))
	var grunt := _grunt(Vector2(20, 0))
	await wait_physics_frames(2)
	_p.melee_blow(grunt, 10.0)
	var chill: StatusEffects.State = grunt.hurtbox.states._state(StatusEffects.Kind.CHILL)
	assert_not_null(chill)
	assert_almost_eq(chill.strength, 0.6, 0.001)


## L'Hibernation : enfermé, les recharges des autres courent plus vite.
func test_hibernation_hastens_the_other_recharges() -> void:
	_learn_with("manual_cold", "frost_tomb", [[SkillStats.HIBERNATION, 100.0]])
	assert_true(_p.invest(0, "winter_disaster"))
	_p.bar.put(3, "winter_disaster")
	assert_true(Gestures.cast(_p, 2))
	_p._recharges[3] = 2.0
	await wait_seconds(0.5)
	assert_almost_eq(_p._recharges[3], 1.0, 0.06, "deux fois plus vite")


## Le Refuge : entrer dans la glace éteint ce que l'on porte.
func test_the_refuge_puts_out_the_wearer_states() -> void:
	_learn_with("manual_cold", "frost_tomb", [[SkillStats.REFUGE, 1.0]])
	_p.states.put(StatusEffects.Kind.IGNITE, 5.0)
	assert_true(Gestures.cast(_p, 2))
	assert_false(_p.states.active(StatusEffects.Kind.IGNITE))


## Le Halo de givre : ce qui passe autour du porteur est transi.
func test_a_rime_halo_chills_around_its_wearer() -> void:
	_learn_with("manual_cold", "frost_tomb", [[SkillStats.RIME_HALO, 100.0]])
	var near := _target(Vector2(20, 0))
	near.states = StatusEffects.new()
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(SkillStats.HALO_PERIOD + 0.1)
	assert_true(near.states.active(StatusEffects.Kind.CHILL))


## L'Hiver sans fin : chaque tué rend du temps au tombeau.
func test_endless_winter_gives_time_back_on_each_kill() -> void:
	_learn_with("manual_cold", "frost_tomb", [[SkillStats.ENDLESS_WINTER, 1.0]])
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(1.0)
	var tomb: Buff = _p._lit["frost_tomb"]
	var before := tomb.remaining()
	_p._on_slew(SkillStats.new(), Vector2.ZERO, null)
	assert_almost_eq(tomb.remaining(), before + SkillStats.ENDLESS_TIME, 0.001)


## Le Cœur de glace : l'éclatement transit à coup sûr, à double force.
func test_an_ice_heart_burst_chills_twice_as_hard() -> void:
	_learn_with(
		"manual_cold", "frost_tomb",
		[["damage_cold", 10.0], [SkillStats.END_BURST, 30.0], [SkillStats.ICE_HEART, 1.0]]
	)
	var near := _target(Vector2(20, 0))
	near.states = StatusEffects.new()
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	_p._recharges[2] = 0.0
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(3)
	var chill: StatusEffects.State = near.states._state(StatusEffects.Kind.CHILL)
	assert_not_null(chill)
	assert_almost_eq(chill.strength, 2.0, 0.001)


## Le Brise-glace : sortir tôt, c'est éclater de toutes les secondes qui restaient.
func test_an_icebreaker_burst_pays_for_the_time_left() -> void:
	_learn_with(
		"manual_cold", "frost_tomb",
		[["damage_cold", 10.0], [SkillStats.END_BURST, 30.0], [SkillStats.ICEBREAKER, 100.0]]
	)
	var near := _target(Vector2(20, 0))
	# Sans le critique : allumer le tombeau refait la fiche, et sa chance avec (5 %).
	var bursts := []
	near.damaged.connect(
		func(info: DamageInfo) -> void:
			bursts.append(info.amount / (info.cast.crit_multiplier if info.is_crit else 1.0))
	)
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	var left := (_p._lit["frost_tomb"] as Buff).remaining()
	_p._recharges[2] = 0.0
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(3)
	assert_almost_eq(float(bursts[0]), 10.0 * (1.0 + left), 0.5)


# --------------------------------------------------------------------------
# Désastre hivernal (jalon 44)
# --------------------------------------------------------------------------

## La Boule de neige : le vortex grossit de chaque ennemi frappé.
func test_a_snowball_vortex_grows_from_what_it_hits() -> void:
	_learn_with("manual_cold", "winter_disaster", [[SkillStats.SNOWBALL, 10.0]])
	_target(Vector2(10, 0))
	_target(Vector2(-10, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(2)
	var vortex: IceVortex = _children_of(IceVortex)[0]
	assert_almost_eq(vortex._swell, 0.2, 0.001, "deux ennemis, 10 % chacun")


## La Coulée roule vers le point visé ; l'Ornière y laisse son sol.
func test_a_sliding_vortex_rolls_toward_the_aim_and_leaves_a_rut() -> void:
	_learn_with("manual_cold", "winter_disaster", [[SkillStats.SLIDE, 1.0], [SkillStats.RUT, 1.0]])
	assert_true(Gestures.cast(_p, 2))
	var vortex: IceVortex = _children_of(IceVortex)[0]
	await wait_seconds(1.0)
	assert_almost_eq(vortex.global_position.distance_to(_p.global_position), SkillStats.SLIDE_SPEED, 3.0)
	assert_gt(_children_of(DashTrail).size(), 0, "l'ornière")


## L'Accalmie : dans l'œil, le lanceur subit moins.
func test_the_lull_shelters_its_caster_in_the_eye() -> void:
	_learn_with("manual_cold", "winter_disaster", [[SkillStats.LULL, 30.0]])
	var before := _p.stats.damage_taken
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(2)
	assert_almost_eq(_p.stats.damage_taken, before - 30.0, 0.001)


## Le Givrage : un transi déjà posé se renforce à chaque impulsion.
func test_frosting_strengthens_a_chill_each_pulse() -> void:
	_learn_with("manual_cold", "winter_disaster", [[SkillStats.FROSTING, 50.0]])
	var target := _target(Vector2(10, 0))
	target.states = StatusEffects.new()
	target.states.put(StatusEffects.Kind.CHILL, 0.0)
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(2)
	assert_almost_eq(target.states._state(StatusEffects.Kind.CHILL).strength, 1.5, 0.001)


## La Supraconduction : un engourdi est transi à coup sûr et aspiré deux fois plus fort.
func test_superconduction_chills_and_pulls_the_numbed_harder() -> void:
	_learn_with("manual_cold", "winter_disaster", [[SkillStats.PULL, 60.0], [SkillStats.SUPERCONDUCT, 1.0]])
	var numbed := _target(Vector2(10, 0))
	numbed.states = StatusEffects.new()
	numbed.states.put(StatusEffects.Kind.NUMB, 0.0)
	var pulls := []
	numbed.damaged.connect(func(info: DamageInfo) -> void: pulls.append(info.knockback))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(2)
	assert_eq(pulls, [-120.0])
	assert_true(numbed.states.active(StatusEffects.Kind.CHILL))


## La Meule : au cœur, le même tirage mord plus fort.
func test_the_mill_bites_harder_at_the_core() -> void:
	_learn_with("manual_cold", "winter_disaster", [[SkillStats.MILL, 50.0]])
	_p.stats.crit_chance = 0.0
	var core := _target(Vector2(5, 0))
	var rim := _target(Vector2(22, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(2)
	assert_almost_eq(float(_received_all[core][0]), float(_received_all[rim][0]) * 1.5, 0.01)


## La Singularité : l'implosion éclate à deux fois son rayon.
func test_a_singularity_bursts_twice_as_wide() -> void:
	_learn_with(
		"manual_cold", "winter_disaster", [["duration", -80.0, true], [SkillStats.SINGULARITY, 1.0]],
		Skill.Shape.IMPLOSION
	)
	var cast := _p.resolve(SkillCatalog.by_id("winter_disaster"), 1)
	var far := _target(Vector2(cast.radius * 1.7, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	var vortex: IceVortex = _children_of(IceVortex)[0]
	while is_instance_valid(vortex):
		await wait_physics_frames(1)
	await wait_physics_frames(2)
	assert_eq(_hits(far), 1, "l'éclatement seul")


# --------------------------------------------------------------------------
# Orbe gelée (jalon 44)
# --------------------------------------------------------------------------

func _count_shards() -> Array:
	var thrown := [0]
	_effects.child_entered_tree.connect(
		func(n: Node) -> void: thrown[0] += 1 if n is Projectile else 0
	)
	return thrown


## L'orbe file, crache un éclat par période, puis éclate en couronne et s'efface.
func test_a_frozen_orb_spits_shards_then_bursts() -> void:
	_learn("manual_cold", ["frozen_orb"])
	var cast := _p.resolve(SkillCatalog.by_id("frozen_orb"), 1)
	var thrown := _count_shards()
	assert_true(Gestures.cast(_p, 2))
	var orb: FrozenOrb = _children_of(FrozenOrb)[0]
	await wait_seconds(0.5)
	assert_gt(orb.global_position.distance_to(_p.global_position), 40.0, "elle file")
	assert_almost_eq(thrown[0], int(0.5 / cast.period), 1, "un éclat par période")
	await wait_seconds(cast.duration - 0.4)
	assert_eq(_children_of(FrozenOrb).size(), 0)
	assert_almost_eq(
		thrown[0], int(cast.duration / cast.period) + SkillStats.FROST_ORB_BURST, 1, "et sa couronne"
	)


## Pas plus que sa limite par lanceur : la plus ancienne se dissout.
func test_frozen_orbs_are_capped_per_caster() -> void:
	_learn("manual_cold", ["frozen_orb"])
	var cast := _p.resolve(SkillCatalog.by_id("frozen_orb"), 1)
	for i in cast.max_simultaneous() + 2:
		_p._recharges[2] = 0.0
		assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(1)
	assert_eq(_children_of(FrozenOrb).size(), cast.max_simultaneous())


## La Toupie crache plus vite ; la Pluie d'éclats grossit la couronne.
func test_a_spinning_top_spits_faster_and_rain_widens_the_burst() -> void:
	_learn_with("manual_cold", "frozen_orb", [[SkillStats.TOP, 100.0], [SkillStats.SHARD_RAIN, 4.0]])
	var cast := _p.resolve(SkillCatalog.by_id("frozen_orb"), 1)
	var thrown := _count_shards()
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(cast.duration + 0.1)
	assert_almost_eq(
		thrown[0], int(cast.duration / cast.period * 2.0) + SkillStats.FROST_ORB_BURST + 4, 2
	)


## L'Orbe mordante frappe ce qu'elle traverse, une fois.
func test_a_biting_orb_strikes_what_it_passes() -> void:
	_learn_with("manual_cold", "frozen_orb", [[SkillStats.ORB_BITE, 30.0]])
	var on_path := _target(_p.global_position + _p.facing * 40.0)
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	var orb: FrozenOrb = _children_of(FrozenOrb)[0]
	await wait_seconds(0.6)
	assert_true(orb._bitten.has(on_path.get_instance_id()))


## La Fracture : un éclat sur un transi se brise en deux morceaux, qui ne se brisent plus ;
## sous le Kaléidoscope, une fois de plus.
func test_fracture_breaks_a_shard_on_a_chilled_enemy() -> void:
	_learn_with("manual_cold", "frozen_orb", [[SkillStats.FRACTURE, 100.0]])
	var chilled := _target(_p.global_position + _p.facing * 50.0)
	chilled.states = StatusEffects.new()
	chilled.states.put(StatusEffects.Kind.CHILL, 0.0)
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(0.8)
	var pieces := _children_of(Projectile).filter(
		func(b: Projectile) -> bool: return is_zero_approx(b._cast.fracture)
	)
	assert_gt(pieces.size(), 1, "des morceaux")

	var shard := _p.resolve(SkillCatalog.by_id("frozen_orb"), 1)
	shard.fracture = 100.0
	assert_eq(shard.fragment().fracture, 0.0, "un morceau ne se brise plus")
	assert_same(shard.fragment(), shard.fragment(), "fabriqué une fois par lancer")
	var kaleidoscope := _p.resolve(SkillCatalog.by_id("frozen_orb"), 1)
	kaleidoscope.fracture = 100.0
	kaleidoscope.kaleidoscope = 1.0
	assert_eq(kaleidoscope.fragment().fracture, 100.0, "sauf sous le Kaléidoscope")
	assert_eq(kaleidoscope.fragment().fragment().fracture, 0.0, "une fois")


## Le Guidage : l'orbe s'incurve vers le curseur.
func test_a_guided_orb_curves_toward_the_cursor() -> void:
	_learn_with("manual_cold", "frozen_orb", [[SkillStats.GUIDED, 1.0]])
	_p.facing = Vector2.RIGHT
	assert_true(Gestures.cast(_p, 2))
	var orb: FrozenOrb = _children_of(FrozenOrb)[0]
	_p.facing = Vector2.DOWN
	await wait_seconds(0.4)
	assert_gt(orb._dir.y, 0.5, "elle a tourné vers le bas")


## La Stase : l'orbe s'arrête au point visé ; le Cristallin y grossit ses éclats.
func test_a_stasis_orb_stops_at_the_aim_and_swells() -> void:
	_learn_with("manual_cold", "frozen_orb", [[SkillStats.STASIS, 1.0], [SkillStats.CRYSTALLINE, 50.0]])
	var aim := _aim()
	assert_true(Gestures.cast(_p, 2))
	var orb: FrozenOrb = _children_of(FrozenOrb)[0]
	await wait_seconds(1.5)
	assert_eq(orb.global_position, aim)
	assert_gt(orb._stopped, 0.0)
	assert_gt(orb._shard_cast().total_max(), orb._cast.total_max(), "plus fort à l'arrêt")


## Son lanceur parti — le corbeau éteint —, l'orbe se dissout sans cracher au nom d'un mort.
func test_a_frozen_orb_dissolves_with_its_caster() -> void:
	_learn("manual_cold", ["frozen_orb"])
	var shoulder := Node2D.new()
	_effects.add_child(shoulder)
	var cast := _p.resolve(SkillCatalog.by_id("frozen_orb"), 1)
	FrozenOrb.send(_effects, Vector2.ZERO, Vector2.RIGHT, cast, _p.states, shoulder, _p.bolt_scene, Vector2.ZERO, _p)
	shoulder.free()
	await wait_physics_frames(2)
	assert_eq(_children_of(FrozenOrb).size(), 0)


## La Constellation : une orbe de plus par point.
func test_a_constellation_casts_more_orbs() -> void:
	_learn_with("manual_cold", "frozen_orb", [["projectiles", 2.0]])
	assert_true(Gestures.cast(_p, 2))
	assert_eq(_children_of(FrozenOrb).size(), 3)


# --------------------------------------------------------------------------
# Peste (jalon 45)
# --------------------------------------------------------------------------

## L'Épidémie se lit sur la décomposition posée, qui garde son lancer : le décomposé meurt
## souvent de ses à-coups, sans lancer derrière.
func test_a_plague_bolt_marks_its_decay_as_epidemic() -> void:
	_learn_with("manual_necrotic", "plague", [[SkillStats.EPIDEMIC, 40.0]])
	var struck := _wearing_target(Vector2(60, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(0.6)
	assert_almost_eq(struck.states.epidemic(StatusEffects.Kind.DECAY), 40.0, 0.001)
	assert_eq(struck.states.heirs(StatusEffects.Kind.DECAY), 1)


## À la mort, la décomposition passe au plus proche qui ne la porte pas — sous la Pandémie,
## aux deux plus proches.
func test_an_epidemic_changes_host_at_death() -> void:
	for heirs in [1, 2]:
		var dying := _grunt(Vector2(200, 0))
		var nearest := _grunt(Vector2(225, 0))
		var next := _grunt(Vector2(200, 30))
		var already := _grunt(Vector2(185, 0))
		var far := _grunt(Vector2(320, 0))
		await wait_physics_frames(2)
		already.states.put(StatusEffects.Kind.DECAY, 1.0, _p.states, "plague")
		var plague := SkillStats.new()
		plague.epidemic = 40.0
		plague.pandemic = 1.0 if heirs == 2 else 0.0
		dying.states.put(StatusEffects.Kind.DECAY, 1.0, _p.states, "plague")
		dying.states.attach(StatusEffects.Kind.DECAY, plague)
		dying.die(false)
		await wait_physics_frames(2)
		assert_true(nearest.states.active(StatusEffects.Kind.DECAY), "le plus proche des sains")
		assert_eq(next.states.active(StatusEffects.Kind.DECAY), heirs == 2, "le second, sous la Pandémie")
		assert_false(far.states.active(StatusEffects.Kind.DECAY), "hors de portée")
		assert_almost_eq(nearest.states.epidemic(StatusEffects.Kind.DECAY), 40.0, 0.001, "et elle passera encore")
		for grunt in [nearest, next, already, far]:
			grunt.free()


## Le Vecteur : le trait laisse le décomposé devant lui et s'incurve vers le sain.
func test_a_vector_bolt_seeks_the_healthy() -> void:
	_learn_with("manual_necrotic", "plague", [[SkillStats.VECTOR, 120.0]])
	var rotten := _wearing_target(Vector2(150, 0))
	rotten.states.put(StatusEffects.Kind.DECAY, 1.0)
	var healthy := _wearing_target(Vector2(90, 40))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(1.2)
	assert_eq(_hits(healthy), 1)
	assert_eq(_hits(rotten), 0)


## Le Germe : un trait arrêté par un mur sans rien toucher crève en nuage qui décompose.
func test_a_missed_bolt_bursts_into_a_germ_cloud() -> void:
	_learn_with("manual_necrotic", "plague", [[SkillStats.GERM, 1.0]])
	_wall(Vector2(60, 0), Vector2(10, 200))
	var beside := _wearing_target(Vector2(42, 22))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(0.6)
	assert_eq(_hits(beside), 1)
	assert_true(beside.states.active(StatusEffects.Kind.DECAY))


## Les Pustules : les Bubons font éclater un tué décomposé, qui ne pourrissait pas.
func test_pustules_burst_a_decaying_kill() -> void:
	var cast := _p.resolve(SkillCatalog.by_id("plague"), 1)
	cast.kill_burst = 30.0
	var near := _target(Vector2(50, 0))
	var decaying := StatusEffects.new()
	decaying.put(StatusEffects.Kind.DECAY, 1.0)
	await wait_physics_frames(2)
	_p.states.slew.emit(cast, Vector2(40, 0), decaying)
	await wait_physics_frames(3)
	assert_eq(_hits(near), 0, "sans les Pustules")
	cast.pustules = 1.0
	_p.states.slew.emit(cast, Vector2(40, 0), decaying)
	await wait_physics_frames(3)
	assert_eq(_hits(near), 1)


## La Dispersion : au bout de sa course, la nuée se divise en petits essaims.
func test_a_swarm_disperses_at_the_end_of_its_flight() -> void:
	_learn_with("manual_necrotic", "plague", [[SkillStats.DISPERSAL, 2.0]], Skill.Shape.ORB)
	assert_true(Gestures.cast(_p, 2))
	var swarm: StaticOrb = _children_of(StaticOrb)[0]
	var radius := swarm._cast.radius
	var duration := swarm._cast.duration
	await wait_seconds(duration + 0.1)
	var small := _children_of(StaticOrb)
	assert_eq(small.size(), 2)
	assert_almost_eq((small[0] as StaticOrb)._cast.radius, radius * SkillStats.DISPERSAL_SIZE, 0.01)
	await wait_seconds(duration * SkillStats.DISPERSAL_SIZE + 0.1)
	assert_eq(_children_of(StaticOrb).size(), 0, "les petits ne se divisent plus")


# --------------------------------------------------------------------------
# Relève (jalon 45)
# --------------------------------------------------------------------------

func _wound(minion: Minion, part: float) -> void:
	var blow := DamageType.empty_parts()
	blow[DamageType.Kind.PHYSICAL] = minion.max_health * part
	minion.hurtbox.take_damage(DamageInfo.roll(null, minion.global_position, blow))


## Les Os rapiécés : un coup porté rend des PV au mort-vivant.
func test_patched_bones_mend_on_each_blow() -> void:
	_learn_with("manual_necrotic", "rise", [[SkillStats.MEND, 10.0]])
	_target(Vector2(30, 0))
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(1)
	var minion := _undead()
	minion.health = minion.max_health * 0.5
	await wait_seconds(1.5)
	assert_gt(minion.health, minion.max_health * 0.5)


## La Curée : plus fort quand un autre frappe la même proie.
func test_the_quarry_bites_harder_together() -> void:
	_learn_with("manual_necrotic", "rise", [[SkillStats.PACK, 10.0]])
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(1)
	var pair := Minion.living.filter(func(m: Minion) -> bool: return m._player == _p)
	var prey := _target(Vector2(300, 0))
	pair[0]._foe = prey
	pair[1]._foe = null
	assert_almost_eq(pair[0]._more(), 1.0, 0.001, "seul sur sa proie")
	pair[1]._foe = prey
	assert_almost_eq(pair[0]._more(), 1.1, 0.001)


## Le Rappel : tous debout, relancer les remet sur pied et les fait frapper plus fort.
func test_a_recall_mends_and_rallies_those_standing() -> void:
	_learn_with("manual_necrotic", "rise", [[SkillStats.RECALL, 1.0]])
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(1)
	var minion := _undead()
	minion.health = 1.0
	_p._recharges[2] = 0.0
	assert_true(Gestures.cast(_p, 2), "relancer n'est plus refusé")
	assert_eq(Minion.count_of(_p, "rise"), 2, "personne de plus")
	assert_eq(minion.health, minion.max_health)
	assert_almost_eq(minion._more(), 1.0 + SkillStats.RECALL_MORE, 0.001)


## Les Lanceurs d'os : ils restent à leur place et jettent un os à ce qui approche.
func test_bone_throwers_throw_from_their_post() -> void:
	_learn_with("manual_necrotic", "rise", [[SkillStats.BONE_THROW, 1.0]])
	var prey := _target(Vector2(80, 0))
	var bones := [0]
	# En différé : le tir entre dans l'arbre avant d'être marqué comme os.
	var count := func(n: Node) -> void:
		if is_instance_valid(n) and (n as Projectile).bone:
			bones[0] += 1
	_effects.child_entered_tree.connect(
		func(n: Node) -> void:
			if n is Projectile:
				count.call_deferred(n)
	)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(1.2)
	assert_gt(_hits(prey), 0)
	assert_gt(bones[0], 0, "ce sont des os qui volent")
	for minion in Minion.living:
		assert_lt(minion.global_position.distance_to(_p.global_position), Minion.FORMATION + 8.0, "à sa place")


## L'Éboulis d'os : le colosse tombé se brise en trois, qui ne comptent pas dans la limite et
## s'en vont.
func test_a_fallen_colossus_crumbles_into_rubble() -> void:
	_learn_with("manual_necrotic", "rise", [[SkillStats.COLOSSUS, 24.0], [SkillStats.RUBBLE, 1.0]])
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(1)
	_wound(_undead(), 10.0)
	await wait_physics_frames(2)
	var rubble := Minion.living.filter(func(m: Minion) -> bool: return m._player == _p)
	assert_eq(rubble.size(), SkillStats.RUBBLE_COUNT)
	assert_eq(Minion.count_of(_p, "rise"), 0, "hors de la limite")
	assert_eq((rubble[0] as Minion)._cast.colossus, 0.0, "des ordinaires")
	_p._recharges[2] = 0.0
	assert_true(Gestures.cast(_p, 2), "le colosse se relève")


## Le Martyr : à bout, il fonce exploser sur l'ennemi le plus proche.
func test_a_martyr_rushes_to_explode() -> void:
	_learn_with("manual_necrotic", "rise", [[SkillStats.END_BURST, 30.0], [SkillStats.MARTYR, 50.0]])
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(1)
	var minion := _undead()
	_wound(minion, 0.8)
	assert_true(minion._martyr)
	var prey := _target(Vector2(60, 0))
	await wait_seconds(1.5)
	assert_false(is_instance_valid(minion), "tombé en explosant")
	assert_gt(_hits(prey), 0)


# --------------------------------------------------------------------------
# Déferlante toxique (jalon 45)
# --------------------------------------------------------------------------

## La Langueur : le flétrissement de la Déferlante dure davantage.
func test_languor_lengthens_the_wilting() -> void:
	_learn_with("manual_necrotic", "toxic_unleash", [[SkillStats.LANGUOR, 2.0], ["inflict_chance", 100.0, true]])
	var near := _wearing_target(Vector2(20, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(2)
	assert_gt(
		near.states.remaining(StatusEffects.Kind.WILTING),
		StatusEffects.DURATIONS[StatusEffects.Kind.WILTING] + 1.9
	)


## L'Apnée : le premier souffle compte au plein, celui qui le suit aussitôt presque rien.
func test_apnea_rewards_the_held_breath() -> void:
	_learn_with("manual_necrotic", "toxic_unleash", [[SkillStats.APNEA, 10.0]])
	assert_true(Gestures.cast(_p, 2))
	_p._recharges[2] = 0.0
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(1)
	var novas := _children_of(Explosion)
	var ratio: float = (novas[0] as Explosion)._cast.total_max() / (novas[1] as Explosion)._cast.total_max()
	assert_almost_eq(ratio, 1.0 + 0.1 * SkillStats.APNEA_MOST, 0.01)


## La Succion : chaque flétri frappé rend des PV.
func test_suction_drinks_from_the_wilting() -> void:
	_learn_with("manual_necrotic", "toxic_unleash", [[SkillStats.SUCTION, 10.0]])
	var wilting := _wearing_target(Vector2(20, 0))
	wilting.states.put(StatusEffects.Kind.WILTING, 1.0)
	_wearing_target(Vector2(-20, 0))
	_p._set_health(_p.stats.max_health * 0.5)
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(3)
	assert_almost_eq(_p.health, _p.stats.max_health * 0.6, 0.5, "un flétri sur deux")


## La Détonation : la nova fait éclater les créatures de la porte qu'elle atteint.
func test_the_breath_detonates_the_gate_crawlers() -> void:
	_learn_with("manual_necrotic", "toxic_unleash", [[SkillStats.DETONATION, 50.0]])
	assert_true(_p.invest(0, "rotting_gate"))
	var gate_cast := _p.resolve(SkillCatalog.by_id("rotting_gate"), 1)
	var gate := RottingGate.open(_effects, Vector2(20, 0), gate_cast, _p.states)
	await wait_seconds(gate_cast.period * 2.0 + 0.05)
	var crawling := gate._crawlers.size()
	assert_gt(crawling, 0)
	assert_true(Gestures.cast(_p, 2))
	assert_eq(gate._crawlers.size(), 0, "toutes éclatées")
	await wait_physics_frames(1)
	assert_eq(_children_of(Explosion).size(), crawling + 1, "les leurs, et la nova")


## Le Râle : chaque coup que porte le flétri lui rend du flétrissement, jamais au-delà de la
## pose.
func test_a_rattling_wilt_wears_with_each_blow() -> void:
	var wilted := StatusEffects.new()
	var breath := SkillStats.new()
	breath.rattle = 1.0
	wilted.put(StatusEffects.Kind.WILTING, 1.0)
	wilted.attach(StatusEffects.Kind.WILTING, breath)
	wilted.advance(2.0)
	var left := wilted.remaining(StatusEffects.Kind.WILTING)
	var victim := _target(Vector2(300, 0))
	await wait_physics_frames(2)
	var info := DamageInfo.roll(null, Vector2.ZERO, DamageType.empty_parts())
	info.author = wilted
	victim.take_damage(info)
	assert_almost_eq(wilted.remaining(StatusEffects.Kind.WILTING), left + SkillStats.RATTLE_TIME, 0.001)
	for i in 10:
		wilted.landed(1.0)
	assert_almost_eq(
		wilted.remaining(StatusEffects.Kind.WILTING), StatusEffects.DURATIONS[StatusEffects.Kind.WILTING], 0.001
	)


## La Quinte : le cône repart deux fois.
func test_a_coughing_fit_breathes_again() -> void:
	_learn_with("manual_necrotic", "toxic_unleash", [[SkillStats.FIT, 1.0]], Skill.Shape.BREATH)
	var breaths := [0]
	_effects.child_entered_tree.connect(
		func(n: Node) -> void: breaths[0] += 1 if n is ToxicBreath else 0
	)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(SkillStats.FIT_GAP * float(SkillStats.FIT_COUNT) + 0.1)
	assert_eq(breaths[0], 1 + SkillStats.FIT_COUNT)


# --------------------------------------------------------------------------
# Porte pourrissante (jalon 45)
# --------------------------------------------------------------------------

## Un portail à la main, au lancer sans tirage : ses éclats se comparent.
func _gate(changes: Dictionary, at := Vector2(20, 0), follow: Node2D = null) -> RottingGate:
	var cast := _p.resolve(SkillCatalog.by_id("rotting_gate"), 1)
	cast.damage_min = cast.damage_max.duplicate()
	for field: String in changes:
		cast.set(field, changes[field])
	return RottingGate.open(_effects, at, cast, _p.states, follow, _p)


## La Fécondité se lit en période : la porte crache plus souvent, et davantage.
func test_fertility_shortens_the_laying_period() -> void:
	_learn_with("manual_necrotic", "rotting_gate", [[SkillStats.FERTILITY, 50.0]])
	var base := SkillCatalog.by_id("rotting_gate").period
	assert_almost_eq(_p.resolve(SkillCatalog.by_id("rotting_gate"), 1).period, base / 1.5, 0.001)


## La Gestation : une créature qui a attendu éclate plus fort.
func test_gestation_swells_the_waiting() -> void:
	var gate := _gate({SkillStats.GESTATION: 10.0})
	var fresh := RottingGate.Crawler.new()
	var ripe := RottingGate.Crawler.new()
	ripe.waited = SkillStats.GESTATION_MOST + 5.0
	gate._crawlers.append_array([fresh, ripe])
	gate._burst(fresh)
	gate._burst(ripe)
	await wait_physics_frames(1)
	var blasts := _children_of(Explosion)
	assert_almost_eq(
		DamageType.total((blasts[1] as Explosion)._parts) / DamageType.total((blasts[0] as Explosion)._parts),
		1.0 + 0.1 * SkillStats.GESTATION_MOST, 0.001
	)
	assert_almost_eq(gate._swell(ripe), 1.0 + 0.1 * SkillStats.GESTATION_MOST, 0.001, "et le dessin grossit d'autant")
	# Par paliers impairs : 7 × 1,3 → 9 ; l'amalgame part de 13.
	assert_eq(gate._side(fresh), EffectForge.CRAWLER_SIZE)
	assert_eq(gate._side(ripe), 9)
	ripe.big = true
	assert_eq(gate._side(ripe), 17, "13 × 1,3")


## La Laisse : la créature prend l'ennemi le plus proche de la visée, pas d'elle.
func test_leashed_crawlers_go_for_the_aim() -> void:
	var gate := _gate({SkillStats.LEASH: 1.0})
	_target(Vector2(30, 0))
	var aimed := _target(_aim() + Vector2(0, 10))
	gate._spawn()
	await wait_physics_frames(2)
	gate._hunt()
	assert_eq(gate._crawlers[0].prey, aimed)


## L'Amalgame : trois qui attendent n'en font qu'une, plus forte et plus large.
func test_three_idle_crawlers_fuse() -> void:
	var gate := _gate({SkillStats.AMALGAM: 1.0})
	for i in SkillStats.AMALGAM_SIZE:
		gate._spawn()
	await wait_physics_frames(2)
	var bigs := gate._crawlers.filter(func(c: RottingGate.Crawler) -> bool: return c.big)
	assert_eq(bigs.size(), 1, "trois fondues, la porte en a pondu une autre")
	var big: RottingGate.Crawler = bigs[0]
	gate._burst(big)
	await wait_physics_frames(1)
	var blast: Explosion = _children_of(Explosion)[0]
	assert_almost_eq(blast._radius, gate._cast.radius * SkillStats.AMALGAM_RADIUS, 0.01)
	assert_almost_eq(
		DamageType.total(blast._parts), DamageType.total(gate._cast.roll(Game.rng)) * SkillStats.AMALGAM_MORE, 0.01
	)


## La Masse critique : l'amalgame relâche en éclatant les trois qui le formaient, qui ne
## refusionnent pas.
func test_critical_mass_releases_the_amalgam() -> void:
	var gate := _gate({SkillStats.AMALGAM: 1.0, SkillStats.CRITICAL_MASS: 1.0})
	var big := RottingGate.Crawler.new()
	big.big = true
	gate._crawlers.append(big)
	gate._burst(big)
	assert_eq(gate._crawlers.size(), SkillStats.AMALGAM_SIZE)
	gate._fuse()
	assert_eq(gate._crawlers.size(), SkillStats.AMALGAM_SIZE, "relâchées, elles ne fusionnent plus")


## La Lignée : les petits en lâchent d'autres, qui sont les derniers.
func test_lineage_hatches_once_more() -> void:
	var gate := _gate({SkillStats.HATCHLINGS: 2.0, SkillStats.LINEAGE: 1.0})
	var parent := RottingGate.Crawler.new()
	gate._crawlers.append(parent)
	gate._burst(parent)
	assert_eq(gate._crawlers.size(), 2)
	gate._burst(gate._crawlers[0])
	var last := gate._crawlers.filter(func(c: RottingGate.Crawler) -> bool: return c.last)
	assert_eq(last.size(), 2)
	gate._burst(last[0])
	assert_eq(gate._crawlers.size(), 2, "les derniers ne lâchent rien")


## Le Grouillement : un coup reçu fait cracher le nid, une fois par période.
func test_a_carried_nest_teems_when_struck() -> void:
	var gate := _gate({SkillStats.SWARMING: 2.0}, _p.global_position, _p)
	var before := gate._crawlers.size()
	RottingGate.provoke(_p)
	assert_eq(gate._crawlers.size(), before + 2)
	RottingGate.provoke(_p)
	assert_eq(gate._crawlers.size(), before + 2, "pas avant la fin de l'attente")


# --------------------------------------------------------------------------
# Malédiction putride (jalon 45)
# --------------------------------------------------------------------------

## Un grunt maudit par le joueur, d'un lancer qui porte ces nombres.
func _cursed_grunt(position: Vector2, changes: Dictionary) -> Enemy:
	var grunt := _grunt(position)
	var curse := _p.resolve(SkillCatalog.by_id("putrid_curse"), 1)
	for field: String in changes:
		curse.set(field, changes[field])
	grunt.states.put(StatusEffects.Kind.CURSED, 0.0, _p.states, "putrid_curse")
	grunt.states.attach(StatusEffects.Kind.CURSED, curse)
	return grunt


## Les Ronces : les coups du maudit lui reviennent en partie.
func test_thorns_turn_the_blows_on_the_cursed() -> void:
	var grunt := _cursed_grunt(Vector2(300, 0), {SkillStats.THORNS: 50.0})
	var victim := _target(Vector2(-300, 0))
	await wait_physics_frames(2)
	var full := grunt.health
	var blow := DamageType.empty_parts()
	blow[DamageType.Kind.PHYSICAL] = 10.0
	var info := DamageInfo.roll(null, Vector2.ZERO, blow)
	info.author = grunt.states
	victim.take_damage(info)
	assert_almost_eq(grunt.health, full - info.amount * 0.5, 0.01)


## Le Présage : le sceau tombe plus tard, et plus fort.
func test_an_omen_delays_a_deeper_curse() -> void:
	_learn_with("manual_necrotic", "putrid_curse", [[SkillStats.OMEN, 1.0], [SkillStats.CURSE_EFFECT, 50.0]])
	var under := _wearing_target(_p.global_position + Vector2(Player.PLACEMENT_RANGE, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(0.6)
	assert_false(under.states.active(StatusEffects.Kind.CURSED), "pas encore")
	await wait_seconds(0.6)
	assert_almost_eq(under.states.strength(StatusEffects.Kind.CURSED), 1.5, 0.001)


## La Sentence achève le maudit sous son seuil ; l'Exécuteur passe la malédiction aux voisins.
func test_the_sentence_executes_and_the_executioner_spreads() -> void:
	var doomed := _cursed_grunt(Vector2(200, 0), {SkillStats.SENTENCE: 10.0, SkillStats.EXECUTIONER: 1.0})
	var neighbour := _grunt(Vector2(230, 0))
	var far := _grunt(Vector2(330, 0))
	await wait_physics_frames(2)
	# Les coups passent l'armure : on ne compte que sur un petit coup, au-dessus du plancher.
	var blow := DamageType.empty_parts()
	blow[DamageType.Kind.PHYSICAL] = doomed.stats.max_health * 0.05
	doomed._set_health(doomed.stats.max_health * 0.5)
	doomed.hurtbox.take_damage(DamageInfo.roll(null, Vector2.ZERO, blow))
	assert_false(doomed.is_dead, "au-dessus du seuil")
	doomed._set_health(doomed.stats.max_health * 0.11)
	doomed.hurtbox.take_damage(DamageInfo.roll(null, Vector2.ZERO, blow))
	assert_true(doomed.is_dead, "achevé")
	await wait_physics_frames(2)
	assert_true(neighbour.states.active(StatusEffects.Kind.CURSED))
	assert_false(far.states.active(StatusEffects.Kind.CURSED))


## La Dîme et l'Exhumation : un maudit qui tombe rend du mana et se relève, trois au plus.
func test_a_fallen_cursed_pays_a_tithe_and_rises() -> void:
	_learn("manual_necrotic", ["rise"])
	_p._set_mana(0.0)
	for i in SkillStats.EXHUMED_MOST + 1:
		var grunt := _cursed_grunt(Vector2(200, 30 * i), {SkillStats.TITHE: 3.0, SkillStats.EXHUME: 1.0})
		await wait_physics_frames(1)
		var before := _p.mana
		grunt.die(false)
		assert_almost_eq(_p.mana, before + 3.0, 0.001, "la Dîme")
		await wait_physics_frames(2)
	var exhumed := Minion.living.filter(
		func(m: Minion) -> bool: return m._kin == "exhumed" and not m.is_queued_for_deletion()
	)
	assert_eq(exhumed.size(), SkillStats.EXHUMED_MOST, "les plus anciens s'en vont")
	assert_eq(Minion.count_of(_p, "rise"), 0, "hors de la limite de la Relève")


## L'exhumé est un mort-vivant de la Relève, tout son arbre compris : un colosse sous le Colosse.
func test_the_exhumed_follow_the_rise_tree() -> void:
	_learn_with("manual_necrotic", "rise", [[SkillStats.COLOSSUS, 24.0]])
	var grunt := _cursed_grunt(Vector2(200, 0), {SkillStats.EXHUME: 1.0})
	await wait_physics_frames(1)
	grunt.die(false)
	await wait_physics_frames(2)
	var exhumed: Array = Minion.living.filter(func(m: Minion) -> bool: return m._kin == "exhumed")
	assert_eq(exhumed.size(), 1)
	assert_gt((exhumed[0] as Minion)._cast.colossus, 0.0)
	assert_almost_eq(
		(exhumed[0] as Minion).max_health, _p.stats.max_health * Minion.LIFE * SkillStats.COLOSSUS_LIFE, 0.01
	)


## L'Héritage : la marque passe plus forte.
func test_a_legacy_mark_grows_as_it_passes() -> void:
	_learn_with("manual_necrotic", "putrid_curse", [[SkillStats.LEGACY, 50.0]], Skill.Shape.MARK)
	var aim := _p.global_position + Vector2(Player.PLACEMENT_RANGE, 0)
	var first := _grunt(aim)
	var second := _grunt(aim + Vector2(30, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(2)
	var base := first.states.strength(StatusEffects.Kind.CURSED)
	assert_gt(base, 0.0)
	first.die(false)
	await wait_physics_frames(3)
	assert_almost_eq(second.states.strength(StatusEffects.Kind.CURSED), base * 1.5, 0.001)


# --------------------------------------------------------------------------
# Nécrose avancée (jalon 45)
# --------------------------------------------------------------------------

## La Nécrose allumée sous ces nombres, et la Peste apprise sur la quatrième case.
func _necrosis_lit(lines: Array) -> void:
	_learn_with("manual_necrotic", "advanced_necrosis", lines)
	assert_true(_p.invest(0, "plague"))
	_p.bar.put(3, "plague")
	assert_true(Gestures.cast(_p, 2))
	assert_true(_p.lit(SkillStats.NECROSIS_SKILL))


## Un coup reçu, sans passer par la hurtbox : le joueur pourrait l'esquiver.
func _blow_on_player(part: float) -> void:
	var blow := DamageType.empty_parts()
	blow[DamageType.Kind.PHYSICAL] = _p.stats.max_health * part
	_p._on_damaged(DamageInfo.roll(null, Vector2.ZERO, blow))


func _lethal_blow() -> void:
	_blow_on_player(10.0)


## Le Charognard : une mort proche rend des PV, une lointaine non.
func test_carrion_feeds_on_nearby_deaths() -> void:
	_necrosis_lit([[SkillStats.CARRION, 10.0]])
	_p._set_health(_p.stats.max_health * 0.5)
	_p.feast(_p.global_position + Vector2(SkillStats.CARRION_REACH + 20.0, 0))
	assert_almost_eq(_p.health, _p.stats.max_health * 0.5, 0.01, "trop loin")
	_p.feast(_p.global_position + Vector2(40, 0))
	assert_almost_eq(_p.health, _p.stats.max_health * 0.6, 0.01)


## Le Moribond : à bout de vie, la Nécrose ne ronge plus et les sorts nécrotiques frappent
## plus fort.
func test_the_moribund_stop_gnawing_and_strike_harder() -> void:
	_necrosis_lit([[SkillStats.MORIBUND, 50.0]])
	var plain := _p.resolve(SkillCatalog.by_id("plague"), 1).total_max()
	_p._set_health(_p.stats.max_health * 0.4)
	await wait_seconds(0.5)
	assert_gte(_p.health, _p.stats.max_health * 0.4, "elle ne ronge plus")
	assert_true(Gestures.cast(_p, 3))
	var bolt: Projectile = _children_of(Projectile)[0]
	assert_almost_eq(bolt._cast.total_max(), plain * 1.5, 0.01)


## Le Sursis : un coup mortel laisse à 1 PV et éteint la Nécrose, une fois par attente.
func test_a_reprieve_spares_once() -> void:
	_necrosis_lit([[SkillStats.REPRIEVE, 1.0]])
	_lethal_blow()
	assert_false(_p.is_dead)
	assert_eq(_p.health, 1.0)
	assert_false(_p.lit(SkillStats.NECROSIS_SKILL), "éteinte")
	_p._recharges[2] = 0.0
	assert_true(Gestures.cast(_p, 2))
	_lethal_blow()
	assert_true(_p.is_dead, "pas deux fois dans l'attente")


## Le Revenant : le Sursis laisse davantage.
func test_a_revenant_is_spared_with_more_life() -> void:
	_necrosis_lit([[SkillStats.REPRIEVE, 1.0], [SkillStats.REVENANT, 1.0]])
	_lethal_blow()
	assert_almost_eq(_p.health, _p.stats.max_health * SkillStats.REVENANT_HEALTH, 0.01)
	assert_almost_eq(_p._reprieve_wait, SkillStats.REVENANT_PERIOD, 0.01)


## La Faucheuse : sous la Nécrose, la Peste coûte moitié moins.
func test_the_reaper_halves_necrotic_costs() -> void:
	_necrosis_lit([[SkillStats.REAPER, 1.0]])
	var cost := _p.resolve(SkillCatalog.by_id("plague"), 1).mana_cost
	_p._set_mana(cost * 0.6)
	assert_true(Gestures.cast(_p, 3), "lancée sans tout le mana qu'elle demande")
	assert_almost_eq(_p.mana, cost * 0.6 - cost * SkillStats.REAPER_COST, 0.01)


## Sang noir : sous la Nécrose, une part des PV max par seconde.
func test_black_blood_mends_while_necrosis_burns() -> void:
	_necrosis_lit([["self_heal", 0.5]])
	_p._set_health(_p.stats.max_health * 0.5)
	await wait_seconds(0.5)
	assert_gt(_p.health, _p.stats.max_health * 0.6, "plus que la Nécrose ne ronge")


## L'Exutoire : un gros coup reçu libère le Fardeau sur-le-champ.
func test_an_outlet_releases_the_burden_on_a_heavy_blow() -> void:
	_necrosis_lit([[SkillStats.SHARED_BURDEN, 48.0], [SkillStats.OUTLET, 1.0]])
	var buff: Buff = _p._lit[SkillStats.NECROSIS_SKILL]
	buff._burden = 5.0
	_blow_on_player(0.3)
	assert_eq(buff._burden, 0.0)
	await wait_physics_frames(1)
	assert_eq(_children_of(Explosion).size(), 1)


## La Lente agonie : sous la Nécrose, le sort nécrotique et l'état qu'il pose durent plus.
func test_slow_agony_lengthens_necrotic_spells_and_their_states() -> void:
	_necrosis_lit([[SkillStats.SLOW_AGONY, 50.0]])
	assert_true(Gestures.cast(_p, 3))
	var bolt: Projectile = _children_of(Projectile)[0]
	assert_almost_eq(bolt._cast.languor, StatusEffects.DURATIONS[StatusEffects.Kind.DECAY] * 0.5, 0.001)


# --------------------------------------------------------------------------
# Frappe lourde (jalon 46)
# --------------------------------------------------------------------------

func _crits_on(target: Hurtbox) -> Array:
	var seen := []
	target.damaged.connect(func(info: DamageInfo) -> void: seen.append(info.is_crit))
	return seen


## Une hurtbox qui porte des états, comme un ennemi : la Brèche et le Fer rouge s'y posent.
func _worn_target(position: Vector2) -> Hurtbox:
	var h := _target(position)
	h.states = StatusEffects.new()
	return h


func _strike_again() -> void:
	_p._recharges[2] = 0.0
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(_p.swing_duration + 0.1)


## Le Coup sûr : le troisième lancer est critique, quoi que tire le hasard.
func test_a_sure_blow_lands_every_third_strike() -> void:
	_learn_with("manual_weapons", "heavy_strike", [[SkillStats.SURE_STRIKE, 1.0]])
	var target := _target(Vector2(20, 0))
	var crits := _crits_on(target)
	await wait_physics_frames(2)
	for i in 6:
		await _strike_again()
	assert_eq(crits.size(), 6)
	assert_true(crits[2] and crits[5], "le troisième et le sixième")


## Le Coup de massue : le coup sûr frappe aussi autour de sa cible, hors de portée de l'arme.
func test_a_bludgeon_strikes_around_the_sure_target() -> void:
	_learn_with("manual_weapons", "heavy_strike", [[SkillStats.SURE_STRIKE, 1.0], [SkillStats.MAUL, 1.0]])
	var struck := _target(Vector2(24, 0))
	var beside := _target(Vector2(52, 0))
	await wait_physics_frames(2)
	await _strike_again()
	assert_eq(_hits(beside), 0, "hors de portée, sans coup sûr")
	_p._sure = SkillStats.SURE_EVERY - 1
	await _strike_again()
	assert_eq(_hits(struck), 2)
	assert_eq(_hits(beside), 1, "le cercle de la massue")


## La Brèche : le frappé est fêlé, à la force du nœud, et tout coup d'arme y frappe plus fort
## — pas un sort.
func test_a_breach_cracks_for_every_weapon_attack() -> void:
	_learn_with("manual_weapons", "heavy_strike", [[SkillStats.BREACH, 20.0]])
	var target := _worn_target(Vector2(20, 0))
	await wait_physics_frames(2)
	await _strike_again()
	var cracked := StatusEffects.Kind.BREACH
	assert_true(target.states.active(cracked))
	assert_almost_eq(target.states.strength(cracked), 1.2, 0.001)
	var attack := _p.resolve(SkillCatalog.by_id("cross_slash"), 1)
	assert_almost_eq(attack.against_factor(target.states), 1.2, 0.001, "une autre attaque")
	var spell := _p.resolve(SkillCatalog.by_id("fireball"), 1)
	assert_almost_eq(spell.against_factor(target.states), 1.0, 0.001, "pas un sort")


## Le Fer rouge : l'embrasement déjà là reprend du temps, jusqu'à sa pleine durée.
func test_red_iron_gives_time_back_to_an_ignite() -> void:
	_learn_with("manual_weapons", "heavy_strike", [[SkillStats.RED_IRON, 2.0]])
	var target := _worn_target(Vector2(20, 0))
	var ignite := StatusEffects.Kind.IGNITE
	target.states.put(ignite, 10.0)
	target.states.advance(2.5)
	await wait_physics_frames(2)
	await _strike_again()
	assert_gt(target.states.remaining(ignite), 3.0, "1,5 s, plus 2")


## Le Tremblement : un second anneau au double du rayon, après le premier, sans repasser
## sur ce que le premier a frappé.
func test_a_tremor_strikes_a_second_ring() -> void:
	_learn_with(
		"manual_weapons", "heavy_strike", [["radius", 28.0], [SkillStats.TREMOR, 50.0]],
		Skill.Shape.SLAM
	)
	var inner := _target(Vector2(_p.strike_reach() + 10.0, 0))
	var outer := _target(Vector2(_p.strike_reach() + 44.0, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(0.1)
	assert_eq(_hits(inner), 1)
	assert_eq(_hits(outer), 0, "pas encore")
	await wait_seconds(SkillStats.TREMOR_GAP + 0.1)
	assert_eq(_hits(inner), 1, "l'anneau seul")
	assert_eq(_hits(outer), 1)


## La Collision et les Quilles : le repoussé blesse celui qu'il heurte, qui part à son tour
## sur un troisième. De vrais ennemis, menés par leur pilote : c'est lui qui voit le heurt.
func test_a_collision_hurts_whom_it_slams_and_skittles_carry_on() -> void:
	_learn_with(
		"manual_weapons", "heavy_strike",
		[[SkillStats.KNOCKBACK, 400.0], [SkillStats.COLLISION, 50.0], [SkillStats.SKITTLES, 1.0]]
	)
	var manager := EnemyManager.new()
	manager.target = _p
	add_child_autofree(manager)
	var grunt: PackedScene = load("res://actors/enemies/grunt.tscn")
	var first := manager.spawn(grunt, Vector2(24, 0))
	var second := manager.spawn(grunt, Vector2(46, 0))
	var third := manager.spawn(grunt, Vector2(68, 0))
	# Assez de vie pour que personne ne tombe : un mort ne heurte plus rien.
	var hits := [[], [], []]
	for i in 3:
		var body: Enemy = [first, second, third][i]
		body.stats = body.stats.duplicate()
		body.stats.max_health = 9999.0
		body._set_health(9999.0)
		body.hurtbox.damaged.connect(func(info: DamageInfo) -> void: hits[i].append(info.amount))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(0.5)
	assert_eq(hits[0].size(), 2, "frappé, puis heurtant")
	assert_eq(hits[1].size(), 2, "heurté, puis heurtant à son tour")
	assert_eq(hits[2].size(), 1, "heurté, sans aller plus loin")


# --------------------------------------------------------------------------
# Coup en croix (jalon 46)
# --------------------------------------------------------------------------

## La Lacération : le saignement déjà là reprend du temps.
func test_a_laceration_gives_time_back_to_a_bleed() -> void:
	_learn_with("manual_weapons", "cross_slash", [[SkillStats.LACERATION, 2.0]])
	var target := _worn_target(Vector2(20, 0))
	var bleed := StatusEffects.Kind.BLEED
	# Plus fort que ce que la croix pose : son propre saignement ne le remplace pas.
	target.states.put(bleed, 1000.0)
	target.states.advance(3.0)
	await wait_physics_frames(2)
	await _strike_again()
	assert_gt(target.states.remaining(bleed), 2.5, "1 s, plus 2 à chaque coup")


## La Riposte : un coup reçu, et la croix suivante frappe plus fort — une fois.
func test_a_riposte_answers_a_blow_once() -> void:
	_learn_with("manual_weapons", "cross_slash", [[SkillStats.RIPOSTE, 50.0]])
	var plain := _p.resolve(SkillCatalog.by_id("cross_slash"), 1).total_max()
	_blow_on_player(0.1)
	await _strike_again()
	assert_almost_eq(_p._hit_cast.total_max(), plain * 1.5, 0.01)
	await _strike_again()
	assert_almost_eq(_p._hit_cast.total_max(), plain, 0.01, "dépensée")


## La Tierce frappe le plus proche sur sa ligne, au-delà de l'arme ; la Quarte traverse.
func test_a_tierce_thrusts_the_nearest_and_a_quarte_pierces() -> void:
	_learn_with("manual_weapons", "cross_slash", [[SkillStats.TIERCE, 1.0]])
	# Au-delà de l'allonge de l'épée (32 px), en deçà de l'estoc (44 px).
	var near := _target(Vector2(48, 0))
	var far := _target(Vector2(80, 0))
	var trails := []
	_effects.child_entered_tree.connect(
		func(n: Node) -> void:
			if n is ThrustTrail:
				trails.append(n)
	)
	await wait_physics_frames(2)
	await _strike_again()
	await wait_seconds(SkillStats.TIERCE_GAP + 0.1)
	assert_eq(_hits(near), 1, "hors de portée de la croix, pas de l'estoc")
	assert_eq(_hits(far), 0)
	assert_eq(trails.size(), 1, "son fuseau et son étoile")


func test_a_quarte_thrust_goes_through_its_line() -> void:
	_learn_with("manual_weapons", "cross_slash", [[SkillStats.TIERCE, 1.0], [SkillStats.QUARTE, 1.0]])
	# Au-delà de l'allonge de l'épée (32 px), en deçà de l'estoc (44 px).
	var near := _target(Vector2(48, 0))
	var far := _target(Vector2(80, 0))
	await wait_physics_frames(2)
	await _strike_again()
	await wait_seconds(SkillStats.TIERCE_GAP + 0.1)
	assert_eq(_hits(near), 1)
	assert_eq(_hits(far), 1)


## La Saignée : le second coup vide le saignement d'un coup, plus fort ; la Transfusion en
## rend une part. 1000 de physique : 125 par seconde pendant 4 s, 500 à vider.
func test_bloodletting_drains_the_bleed_and_transfusion_heals() -> void:
	_learn_with(
		"manual_weapons", "cross_slash",
		[[SkillStats.BLOODLETTING, 100.0], [SkillStats.TRANSFUSION, 10.0]]
	)
	var target := _worn_target(Vector2(20, 0))
	target.states.put(StatusEffects.Kind.BLEED, 1000.0)
	await wait_physics_frames(2)
	_p.stats.health_regen = 0.0
	_p._set_health(_p.stats.max_health - 50.0)
	var health := _p.health
	await _strike_again()
	assert_true((_received_all[target] as Array).any(func(a: float) -> bool: return a >= 990.0), "vidé, doublé")
	assert_gte(_p.health, health + 49.9, "un dixième rendu, plus que ce qui manquait")


## L'Ordalie : sous la Lame sainte, le second coup bénit à coup sûr.
func test_an_ordeal_blesses_for_sure() -> void:
	_learn("manual_weapons", [
		"cross_slash", "cross_slash_edge", "cross_slash_edge", "cross_slash_holy_blade",
		"cross_slash_ordeal",
	])
	var target := _worn_target(Vector2(20, 0))
	await wait_physics_frames(2)
	await _strike_again()
	assert_true(target.states.active(StatusEffects.Kind.BLESSING))


# --------------------------------------------------------------------------
# Épée spirale (jalon 46)
# --------------------------------------------------------------------------

func _turned_in(seconds: float) -> float:
	var crown := _p._crown
	var before := crown._rotation
	await wait_seconds(seconds)
	return fposmod(crown._rotation - before, TAU)


## La Valse : la ronde tourne plus vite.
func test_a_waltz_spins_the_swords_faster() -> void:
	_learn_with("manual_weapons", "spiral_sword", [[SkillStats.WALTZ, 100.0]])
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(2)
	var turned: float = await _turned_in(0.25)
	assert_almost_eq(turned, BladeCrown.ROTATION * 2.0 * 0.25, 0.25)


## L'Affûtage : chaque coupé compte, jusqu'au plafond.
func test_honing_counts_what_a_sword_cuts() -> void:
	_learn_with("manual_weapons", "spiral_sword", [[SkillStats.HONING, 10.0]])
	_target(Vector2(SkillCatalog.by_id("spiral_sword").radius, 0))
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(3.2)
	assert_gt(_p._crown._blades[0].honed, 1)
	assert_lte(_p._crown._blades[0].honed, SkillStats.HONING_MOST)


## La Parade : une épée qui croise un trait ennemi le brise.
func test_a_parry_breaks_an_enemy_bolt() -> void:
	_learn_with("manual_weapons", "spiral_sword", [[SkillStats.PARRY, 1.0]])
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(0.3)
	var crown := _p._crown
	var blade: BladeCrown.Blade = crown._blades[0]
	var at := crown.to_global(crown._center(blade, crown._rotation + blade.place))
	var shooter := Node2D.new()
	add_child_autofree(shooter)
	var toward := Vector2.RIGHT
	var bolt := Projectile.spawn_of_nature(
		_effects, load("res://actors/projectiles/enemy_bolt.tscn"), at - toward * Projectile.MUZZLE,
		toward, 5.0, shooter
	)
	await wait_physics_frames(3)
	assert_false(is_instance_valid(bolt) and not bolt.is_queued_for_deletion(), "brisé")
	assert_gt(blade.parry_wait, 0.0, "et l'épée attend")


## Le Brise-lames et la Grenaille : une épée prend le coup et éclate ; pas deux dans l'attente.
func test_a_breakwater_sword_takes_the_blow_and_bursts() -> void:
	_learn_with("manual_weapons", "spiral_sword", [[SkillStats.BREAKWATER, 1.0], [SkillStats.GRAPESHOT, 100.0]])
	assert_true(Gestures.cast(_p, 2))
	_p._recharges[2] = 0.0
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(2)
	_p.stats.health_regen = 0.0
	var health := _p.health
	_blow_on_player(0.2)
	assert_eq(_p.health, health, "rien")
	assert_eq(_p.orbiting_swords(), 1)
	await wait_physics_frames(1)
	assert_eq(_children_of(Explosion).size(), 1, "elle éclate")
	_blow_on_player(0.2)
	assert_lt(_p.health, health, "l'attente")


## L'Escorte : la Frappe lourde qui touche envoie une épée de la ronde sur sa cible.
func test_an_escort_sends_a_sword_after_a_heavy_strike() -> void:
	_learn_with("manual_weapons", "spiral_sword", [[SkillStats.ESCORT, 50.0]])
	assert_true(_p.invest(0, "heavy_strike"))
	_p.bar.put(3, "heavy_strike")
	var sent := []
	_effects.child_entered_tree.connect(
		func(n: Node) -> void:
			if n is FlyingSword:
				sent.append(n)
	)
	_target(Vector2(20, 0))
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 3))
	await wait_seconds(_p.swing_duration + 0.1)
	assert_eq(sent.size(), 1)
	assert_eq(_p.orbiting_swords(), 1, "l'épée continue de tourner")


## Le Ralliement : l'épée de la volée revient tourner, puis s'en va.
func test_a_rally_brings_the_volley_back() -> void:
	_learn_with("manual_weapons", "spiral_sword", [[SkillStats.SWORD_VOLLEY, 40.0], [SkillStats.RALLY, 1.0]])
	_p.skill_mods.assign([StatMod.new("duration", StatMod.Mode.PERCENT, -80.0, Keywords.ATTACK)])
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(1.35)
	assert_eq(_p.orbiting_swords(), 1, "revenue")
	await wait_seconds(SkillStats.RALLY_LIFE)
	assert_eq(_p.orbiting_swords(), 0)
	assert_eq(_children_of(FlyingSword).size(), 0, "sans repartir")


# --------------------------------------------------------------------------
# Vague tranchante (jalon 46)
# --------------------------------------------------------------------------

## La Houle : grossie en fin de course, la vague atteint ce qu'elle frôlait.
func test_a_swell_reaches_wider_at_the_end_of_the_run() -> void:
	_learn_with("manual_weapons", "wave_slash", [[SkillStats.BILLOW, 100.0]])
	var aside := _target(Vector2(62, 32))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(0.7)
	assert_eq(_hits(aside), 1)


## La Proue : le premier mordu prend davantage, du même tirage.
func test_a_prow_hits_the_first_bitten_harder() -> void:
	_learn_with("manual_weapons", "wave_slash", [[SkillStats.PROW, 100.0]])
	# Hors de portée du coup d'arme qui lance la vague.
	var first := _target(Vector2(42, 0))
	var second := _target(Vector2(66, 0))
	# Sans le critique, qui se tire coup par coup.
	var bites := []
	for t: Hurtbox in [first, second]:
		t.damaged.connect(
			func(info: DamageInfo) -> void:
				bites.append(info.amount / (info.cast.crit_multiplier if info.is_crit else 1.0))
		)
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(0.7)
	assert_eq(bites.size(), 2)
	assert_almost_eq(float(bites[0]), float(bites[1]) * 2.0, 0.01)


## La Lame de fond et les Brisants : le mordu est emporté, puis jeté.
func test_an_undertow_carries_then_breakers_throw() -> void:
	_learn_with("manual_weapons", "wave_slash", [[SkillStats.UNDERTOW, 1.0], [SkillStats.BREAKERS, 50.0]])
	var grunt := _grunt(Vector2(46, 0))
	grunt.stats = grunt.stats.duplicate()
	grunt.stats.max_health = 9999.0
	grunt._set_health(9999.0)
	var hits := []
	grunt.hurtbox.damaged.connect(func(info: DamageInfo) -> void: hits.append(info.amount))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(0.7)
	assert_gt(grunt.global_position.x, 70.0, "emporté")
	assert_eq(hits.size(), 2, "mordu, puis jeté")


## Le Va-et-vient : sous le Ressac, l'aller, le retour, et un troisième passage.
func test_to_and_fro_sends_the_backwash_a_third_time() -> void:
	_learn_with("manual_weapons", "wave_slash", [[SkillStats.TO_AND_FRO, 1.0]], Skill.Shape.BOOMERANG)
	var ahead := _target(Vector2(50, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(2.0)
	assert_eq(_hits(ahead), 3)


# --------------------------------------------------------------------------
# Cyclone (jalon 46)
# --------------------------------------------------------------------------

## Le Pied ferme : des lignes du geste entretenu, tant qu'il tourne.
func test_steadfast_holds_while_the_cyclone_spins() -> void:
	_learn_with("manual_weapons", "cyclone", [["damage_taken", -5.0], ["move_speed", -10.0, true]])
	var taken := _p.stats.damage_taken
	var speed := _p.stats.move_speed
	assert_true(Gestures.cast(_p, 2))
	assert_almost_eq(_p.stats.damage_taken, taken - 5.0, 0.001)
	assert_almost_eq(_p.stats.move_speed, speed * 0.9, 0.01)
	_p._recharges[2] = 0.0
	assert_true(Gestures.cast(_p, 2), "éteint")
	assert_almost_eq(_p.stats.damage_taken, taken, 0.001)


## Le Vertige : après deux secondes de tour, les frappes se rapprochent.
func test_vertigo_brings_the_strikes_closer() -> void:
	_learn_with("manual_weapons", "cyclone", [[SkillStats.VERTIGO, 50.0]])
	var target := _target(Vector2(20, 0))
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(2.0)
	var before := _hits(target)
	await wait_seconds(1.0)
	assert_gte(_hits(target) - before, 5, "0,35 s ramenées à 0,175")


## Les Derviches et le Sirocco : deux petits tours qui partent devant ; la Trombe les mène
## à ce qu'ils auraient manqué.
func test_dervishes_set_out_and_a_waterspout_steers_them() -> void:
	_learn_with(
		"manual_weapons", "cyclone",
		[[SkillStats.DERVISHES, 1.0], [SkillStats.SIROCCO, 1.0], [SkillStats.WATERSPOUT, 1.0]]
	)
	var aside := _target(Vector2(70, 55))
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(3)
	assert_eq(_children_of(Dervish).size(), 2)
	await wait_seconds(1.2)
	assert_gte(_hits(aside), 1)


## Le Dénouement et le Coup de vent : relâché, le tour frappe une dernière fois, et repousse.
func test_an_unwinding_strikes_once_more_and_a_gust_pushes() -> void:
	_learn_with("manual_weapons", "cyclone", [[SkillStats.DENOUEMENT, 20.0], [SkillStats.GUST, 1.0]])
	var target := _target(Vector2(20, 0))
	var pushes := _knockbacks_on(target)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(1.0)
	var before := pushes.size()
	_p._recharges[2] = 0.0
	assert_true(Gestures.cast(_p, 2))
	assert_eq(pushes.size(), before + 1)
	assert_eq(pushes[-1], SkillStats.GUST_FORCE)


## La Ronde folle : sous le Cyclone, les épées de l'Épée spirale tournent deux fois plus vite.
func test_a_mad_round_spins_the_swords_under_the_cyclone() -> void:
	_learn_with("manual_weapons", "cyclone", [[SkillStats.MAD_ROUND, 15.0]])
	assert_true(_p.invest(0, "spiral_sword"))
	_p.bar.put(3, "spiral_sword")
	assert_true(Gestures.cast(_p, 3))
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(2)
	assert_almost_eq(_p.spin_madness(), 15.0, 0.001)
	var turned: float = await _turned_in(0.25)
	assert_almost_eq(turned, BladeCrown.ROTATION * SkillStats.MAD_SPIN * 0.25, 0.25)


# --------------------------------------------------------------------------
# Ruée tranchante (jalon 46)
# --------------------------------------------------------------------------

func _frail_grunt(position: Vector2) -> Enemy:
	var grunt := _grunt(position)
	grunt._set_health(1.0)
	return grunt


## La Voltige : invulnérable à l'arrivée, un temps.
func test_a_vault_shelters_on_landing() -> void:
	_learn_with("manual_weapons", "slicing_dash", [[SkillStats.VAULT, 1.0]])
	assert_true(Gestures.cast(_p, 2))
	assert_true(_p.hurtbox.invulnerable)
	await wait_seconds(SkillStats.VAULT_TIME + 0.1)
	assert_false(_p.hurtbox.invulnerable)


## La Relance et l'Hallali : un tué rend la ruée, et la suivante compte la relance.
func test_a_relaunch_refunds_the_dash_and_the_hallali_counts() -> void:
	_learn_with("manual_weapons", "slicing_dash", [[SkillStats.RELAUNCH, 1.0], [SkillStats.HALLALI, 50.0]])
	_frail_grunt(Vector2(60, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	await wait_seconds(0.4)
	assert_eq(_p._recharges[2], 0.0, "rendue")
	assert_eq(_p._hallali, 1)
	assert_true(Gestures.cast(_p, 2), "la ruée suivante, plus forte, ne tue rien")
	await wait_seconds(0.4)
	assert_gt(_p._recharges[2], 0.0, "pas rendue")
	_p._recharges[2] = 0.0
	assert_true(Gestures.cast(_p, 2))
	assert_eq(_p._hallali, 0, "lancée sans relance, le compte retombe")


## La Trouée : chaque ennemi traversé renforce le choc d'arrivée.
func test_a_breakthrough_feeds_the_arrival_shock() -> void:
	_learn_with("manual_weapons", "slicing_dash", [[SkillStats.END_BURST, 20.0], [SkillStats.BREAKTHROUGH, 50.0]])
	_target(Vector2(40, 0))
	_target(Vector2(80, 0))
	await wait_physics_frames(2)
	var plain := _p.resolve(SkillCatalog.by_id("slicing_dash"), 1).total_max()
	assert_true(Gestures.cast(_p, 2))
	await wait_physics_frames(1)
	var blast: Explosion = _children_of(Explosion)[0]
	assert_almost_eq(blast._cast.total_max(), plain * 2.0, 0.01, "deux traversés, +50 % chacun")


## La Retombée : la réception du bond assomme, la moitié pour une élite, puis lâche.
func test_a_fallout_stuns_on_landing() -> void:
	_learn_with(
		"manual_weapons", "slicing_dash", [[SkillStats.END_BURST, 32.0], [SkillStats.FALLOUT, 1.0]],
		Skill.Shape.LEAP
	)
	var grunt := _grunt(Vector2(Player.PLACEMENT_RANGE + 10.0, 0))
	await wait_physics_frames(2)
	assert_true(Gestures.cast(_p, 2))
	assert_eq(grunt.states.speed_factor, 0.0, "assommé")
	assert_eq(grunt.get_children().filter(func(n: Node) -> bool: return n is StunMark).size(), 1, "ses étoiles")
	await wait_seconds(SkillStats.FALLOUT_TIME + 0.1)
	assert_eq(grunt.states.speed_factor, 1.0)
	assert_eq(grunt.get_children().filter(func(n: Node) -> bool: return n is StunMark and not n.is_queued_for_deletion()).size(), 0, "parties avec lui")


## Le Pas chassé : les ruées enchaînées se comptent, une pause remet à zéro.
func test_a_chasse_counts_chained_dashes() -> void:
	_learn_with("manual_weapons", "slicing_dash", [[SkillStats.CHASSE, 10.0]])
	for i in 3:
		_p._recharges[2] = 0.0
		assert_true(Gestures.cast(_p, 2))
		await wait_physics_frames(2)
	assert_eq(_p._chasse, 2)
	await wait_seconds(SkillStats.CHASSE_WINDOW + 0.1)
	_p._recharges[2] = 0.0
	assert_true(Gestures.cast(_p, 2))
	assert_eq(_p._chasse, 0)


## L'allonge de la fiche pousse la hitbox (jalon 46) : un affixe ou un passif d'allonge
## n'y changeait rien, la capsule était fixe dans la scène.
func test_the_reach_of_the_sheet_moves_the_blade() -> void:
	_learn("manual_weapons", ["heavy_strike"])
	var far := _target(Vector2(46, 0))
	await wait_physics_frames(2)
	await _strike_again()
	assert_eq(_hits(far), 0, "hors de l'allonge de base")
	_p.base_stats = _p.base_stats.duplicate()
	_p.base_stats.attack_range = 50.0
	_p.recompute_stats()
	await _strike_again()
	assert_eq(_hits(far), 1, "à portée de la lame allongée")
	assert_almost_eq(_p.strike_reach(), 50.0 - 8.0, 0.01, "le Brise-sol et l'impact suivent")


## Le Coupe-jarret est dans le lancer résolu : la fenêtre des déclenchements le lit.
func test_a_hamstring_is_in_the_resolved_dash() -> void:
	var bare := _p.resolve(SkillCatalog.by_id("slicing_dash"), 1).status_chance_increase
	_learn_with("manual_weapons", "slicing_dash", [[SkillStats.HAMSTRING, 50.0]])
	var cast := _p.resolve(SkillCatalog.by_id("slicing_dash"), 1)
	assert_almost_eq(cast.status_chance_increase, bare + 50.0, 0.001)


# --------------------------------------------------------------------------
# Le geste (jalon 47)
# --------------------------------------------------------------------------

## Le coup tombe à l'impact du geste, pas à l'appui.
func test_an_attack_lands_at_its_impact_not_on_the_press() -> void:
	_learn("manual_weapons", ["heavy_strike"])
	var ahead := _target(Vector2(20, 0))
	await wait_physics_frames(2)
	assert_true(_p.cast_slot(2))
	var impact := _p._gesture.left * _p.sprite.impact_of(Skill.GESTURE[Skill.Shape.STRIKE])
	await wait_seconds(impact * 0.5)
	assert_eq(_hits(ahead), 0, "le bras est encore levé")
	await wait_seconds(impact * 0.5 + _p.swing_duration + 0.1)
	assert_eq(_hits(ahead), 1)


## Un geste à la fois : sans ça, deux cases alternées doublent la cadence.
func test_a_second_slot_waits_for_the_gesture() -> void:
	_learn("manual_weapons", ["heavy_strike", "cross_slash"])
	_p.bar.put(3, "cross_slash")
	await wait_physics_frames(2)
	assert_true(_p.cast_slot(2))
	assert_false(_p.cast_slot(3), "le corps est pris")
	await wait_seconds(_p._gesture.left + 0.05)
	assert_true(_p.cast_slot(3), "libre à la fin du geste")


## Le corps joue son geste sur toute sa durée, vitesse d'attaque comprise.
func test_the_body_plays_the_gesture_over_its_length() -> void:
	_learn("manual_weapons", ["heavy_strike"])
	_p.stats.attack_speed = 2.0
	await wait_physics_frames(2)
	assert_true(_p.cast_slot(2))
	var sprite := _p.sprite
	var frames := sprite.sprite_frames
	var played := frames.get_frame_count(sprite.animation) \
			/ frames.get_animation_speed(sprite.animation) / sprite.speed_scale
	assert_almost_eq(played, _p._gesture.left, 1e-4)
	assert_almost_eq(
		_p._gesture.left, SkillCatalog.by_id("heavy_strike").use_time(_p.stats), 1e-4,
		"la vitesse d'attaque raccourcit le geste"
	)
