extends GutTest

const Weapons := preload("res://tests/weapons.gd")

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
	# Le critique est retiré, comme pour les dégâts contre un état : il tire une
	# salve sur deux, doublerait l'une des deux et ferait dépendre le test de la
	# place de ce lancer dans le fil de `Game.rng`.
	_p.skill_mods.assign([StatMod.new("crit_chance", StatMod.Mode.PERCENT, -100.0)])
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


## Un sort critique par chacun de ses chemins de coup : la chaîne par `Targets.strike`,
## la boule par son tir et son explosion.
func test_a_spell_crits_on_every_path() -> void:
	var crits := []
	for at in [Vector2(60, 0), Vector2(40, 40), Vector2(40, 56)]:
		_target(at).damaged.connect(func(info: DamageInfo) -> void: crits.append(info.is_crit))
	await wait_physics_frames(2)
	_learn("manual_lightning", ["chain_lightning"])
	_p.skill_mods.assign([StatMod.new("crit_chance", StatMod.Mode.PERCENT, 10000.0)])
	assert_true(_p.cast_slot(2), "la chaîne")
	_learn("manual_fire", ["fireball"])
	_p.skill_mods.assign([StatMod.new("crit_chance", StatMod.Mode.PERCENT, 10000.0)])
	_p.bar.put(1, "fireball")
	_p.facing = Vector2(1, 1).normalized()
	assert_true(_p.cast_slot(1), "la boule, sur une case qui ne recharge pas")
	await wait_seconds(0.5)
	assert_gt(crits.size(), 2)
	assert_false(false in crits, "tous critiques")


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


# --------------------------------------------------------------------------
# Les ruées et les buffs (jalon 20)
# --------------------------------------------------------------------------

## La ruée porte le joueur au bout de sa visée — la portée de pose, la même que celle
## du nuage et du serpent.
func test_the_dash_carries_the_player_to_the_aim() -> void:
	_learn("manual_fire", ["flame_dash"])
	var from_value := _p.global_position
	assert_true(_p.cast_slot(2))
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
	assert_true(_p.cast_slot(2))
	await wait_seconds(cast.duration + 0.2)
	assert_eq(_hits(on_the_way), cast.strikes_over_duration(), "une frappe par période")
	assert_eq(_hits(aside), 0, "et rien hors du couloir")
	assert_eq(Game.freezes, 0, "ce qui dure ne fige jamais le jeu")
	assert_eq(_children_of(DashTrail).size(), 0, "la trace s'est effacée")


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
	assert_true(_p.cast_slot(2))
	await wait_seconds(cast.duration + 0.2)
	assert_eq(_hits(near), 1, "au début du chemin")
	assert_eq(_hits(far), 1, "comme au bout")
	assert_eq(_hits(aside), 0, "et rien hors du couloir")
	assert_eq(_children_of(DashTrail).size(), 0, "la coupe s'est effacée")


## Un buff s'allume, verse ses lignes dans la fiche, brûle son porteur, et s'éteint au
## second lancer sans rien coûter.
func test_the_buff_lights_gives_its_lines_and_goes_out_for_free() -> void:
	_learn("manual_fire", ["ignition"])
	var speed := _p.stats.move_speed
	assert_true(_p.cast_slot(2))
	assert_true(_p.lit("ignition"))
	assert_eq(_p.lit_ratio("ignition"), 1.0, "entretenu, il n'a pas de compte à rebours")
	assert_gt(_p.stats.move_speed, speed, "ses lignes sont dans la fiche")
	await wait_physics_frames(3)
	assert_lt(_p.health, _p.stats.max_health, "et elle brûle son porteur")

	_p._recharges[2] = 0.0
	var mana := _p.mana
	assert_true(_p.cast_slot(2))
	assert_false(_p.lit("ignition"), "le second lancer éteint")
	assert_eq(_p.mana, mana, "sans coût")
	assert_eq(_p.stats.move_speed, speed, "et la fiche retrouve ses nombres")


## Le mana épuisé éteint ce qui le draine — là où les PV épuisés tuent.
func test_the_buff_goes_out_when_its_pool_is_empty() -> void:
	_learn("manual_lightning", ["static_electricity"])
	assert_true(_p.cast_slot(2))
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

	assert_true(_p.cast_slot(2))
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
	assert_true(_p.cast_slot(2))
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
	assert_true(_p.cast_slot(2))
	var travelled := _p.global_position.x - from_value.x
	assert_gt(travelled, 0.0, "elle part quand même")
	assert_lt(travelled, Player.PLACEMENT_RANGE, "mais s'arrête devant le mur")


## La ruée d'orage ne laisse rien au sol : elle donne de la vitesse, et pour un temps.
func test_the_storm_dash_leaves_speed_and_no_trail() -> void:
	_learn("manual_lightning", ["storm_dash"])
	var speed := _p.stats.move_speed
	var cast := _p.resolve(SkillCatalog.by_id("storm_dash"), 1)

	assert_true(_p.cast_slot(2))
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

	assert_true(_p.cast_slot(2))
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

	assert_true(_p.cast_slot(2))
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

	assert_true(_p.cast_slot(2))
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

	assert_true(_p.cast_slot(2))
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

	assert_true(_p.cast_slot(2))
	assert_true(_p.lit("frost_tomb"))
	assert_false(_p.cast_slot(3), "rien d'autre ne part")
	assert_lt(_p.stats.damage_taken, 0.0, "et les coups portent moins")

	_p._recharges[2] = 0.0
	assert_true(_p.cast_slot(2), "seul le tombeau peut se rouvrir")
	assert_false(_p.lit("frost_tomb"))


## Il se referme tout seul à la fin de sa durée, et rend des PV en attendant.
func test_the_tomb_mends_then_thaws_on_its_own() -> void:
	_learn("manual_cold", ["frost_tomb"])
	var cast := _p.resolve(SkillCatalog.by_id("frost_tomb"), 1)
	_p._set_health(_p.stats.max_health * 0.5)
	var wounded := _p.health

	assert_true(_p.cast_slot(2))
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

	assert_true(_p.cast_slot(2))
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

	assert_true(_p.cast_slot(2))
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

	assert_true(_p.cast_slot(2))
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

	assert_true(_p.cast_slot(2))
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

	assert_true(_p.cast_slot(2))
	assert_true(_p.lit("holy_light"))
	assert_gt(_p.stats.res_holy, resistance, "la fiche résiste mieux au sacré")
	assert_gt(
		_p.states.chance_factors[StatusEffects.Kind.BLESSING], blessing,
		"et ses coups bénissent plus souvent"
	)

	_p._recharges[2] = 0.0
	assert_true(_p.cast_slot(2))
	assert_false(_p.lit("holy_light"))
	assert_eq(_p.stats.res_holy, resistance, "éteinte, la fiche retrouve ses nombres")
