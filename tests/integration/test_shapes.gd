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


## L'arbre d'un buff (jalon 34) : la ligne d'un nœud qui vise la fiche est une ligne du
## buff — elle compte allumée, plus éteinte —, et sa brûlure suit les nœuds.
func test_a_buff_node_gives_its_lines_while_lit() -> void:
	_learn_with("manual_fire", "ignition", [["move_speed", 50.0, true], ["self_burn", -100.0, true]])
	var speed := _p.stats.move_speed
	assert_true(_p.cast_slot(2))
	assert_true(_p.lit("ignition"))
	var lit_speed := _p.stats.move_speed
	_p._recharges[2] = 0.0
	assert_true(_p.cast_slot(2))
	var out_speed := _p.stats.move_speed
	assert_eq(out_speed, speed, "éteint, la fiche retrouve ses nombres")

	_learn("manual_fire", ["ignition"])
	_p._recharges[2] = 0.0
	assert_true(_p.cast_slot(2))
	var bare_speed := _p.stats.move_speed
	assert_gt(lit_speed, bare_speed, "le nœud s'ajoute au buff")


func test_a_buff_node_can_put_out_its_burn() -> void:
	_learn_with("manual_fire", "ignition", [["self_burn", -100.0, true]])
	assert_true(_p.cast_slot(2))
	await wait_physics_frames(5)
	assert_eq(_p.health, _p.stats.max_health, "sans brûlure, plus rien ne ronge")


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
	assert_true(_p.cast_slot(2))
	await wait_seconds(0.6)
	assert_eq(_hits(target), 1)
	assert_true(target.states.active(StatusEffects.Kind.DECAY), "décomposée")


func test_the_curse_marks_its_circle_without_striking() -> void:
	_learn("manual_necrotic", ["putrid_curse"])
	var aim := _p.global_position + Vector2(Player.PLACEMENT_RANGE, 0)
	var inside := _wearing_target(aim + Vector2(30, 0))
	var outside := _wearing_target(aim + Vector2(90, 0))
	await wait_physics_frames(2)
	assert_true(_p.cast_slot(2))
	await wait_physics_frames(2)
	assert_true(inside.states.active(StatusEffects.Kind.CURSED), "maudite")
	assert_false(outside.states.active(StatusEffects.Kind.CURSED), "hors du cercle, non")
	assert_eq(_hits(inside), 0, "une malédiction ne frappe pas")


func test_rise_raises_two_undead_then_refuses_a_third() -> void:
	_learn("manual_necrotic", ["rise"])
	assert_true(_p.cast_slot(2))
	await wait_physics_frames(1)
	assert_eq(Minion.count_of(_p, "rise"), 2)
	_p._recharges[2] = 0.0
	var mana := _p.mana
	assert_false(_p.cast_slot(2), "au complet : refusée")
	assert_eq(_p.mana, mana, "sans rien prendre")


## Un nœud atteint le lancer, donc le plafond : Légion d'os en lève un de plus.
func test_bone_legion_raises_a_third() -> void:
	_learn("manual_necrotic", ["rise", "rise", "rise", "rise_bone_legion"])
	assert_true(_p.cast_slot(2))
	await wait_physics_frames(1)
	assert_eq(Minion.count_of(_p, "rise"), 3)


func test_the_undead_strike_on_behalf_of_the_player() -> void:
	_learn("manual_necrotic", ["rise"])
	var target := _wearing_target(_p.global_position + Vector2(60, 0))
	_authors.clear()
	target.damaged.connect(_on_authored)
	assert_true(_p.cast_slot(2))
	await wait_seconds(1.5)
	assert_gt(_hits(target), 0, "ils vont frapper ce qui entre dans la zone")
	assert_eq(_authors[0], _p.states, "au nom du joueur : sa pourriture le soignera")


## Son jumeau : ce qui reste hors de la zone du joueur n'est pas poursuivi.
func test_the_undead_leave_alone_what_stays_outside_the_zone() -> void:
	_learn("manual_necrotic", ["rise"])
	var target := _target(_p.global_position + Vector2(200, 0))
	assert_true(_p.cast_slot(2))
	await wait_seconds(1.5)
	assert_eq(_hits(target), 0)


func test_the_undead_fall_when_their_book_leaves_the_rack() -> void:
	_learn("manual_necrotic", ["rise"])
	assert_true(_p.cast_slot(2))
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
	assert_true(_p.cast_slot(2))
	await wait_physics_frames(1)
	assert_true(grunt.foe() is Minion, "le mort-vivant, plus proche")


func test_the_gate_spews_creatures_that_burst_on_an_enemy_in_sight() -> void:
	_learn("manual_necrotic", ["rotting_gate"])
	var aim := _p.global_position + Vector2(Player.PLACEMENT_RANGE, 0)
	var seen := _target(aim + Vector2(60, 0))
	var unseen := _target(aim + Vector2(0, 200))
	await wait_physics_frames(2)
	assert_true(_p.cast_slot(2))
	await wait_seconds(1.5)
	assert_gt(_hits(seen), 0, "elles vont exploser dessus")
	assert_eq(_hits(unseen), 0, "hors de vue, elles l'ignorent")


func test_necrosis_gnaws_current_health_and_raises_the_chance_to_rot() -> void:
	_learn("manual_necrotic", ["advanced_necrosis"])
	var before := _p.states.chance_factors[StatusEffects.Kind.ROT]
	assert_true(_p.cast_slot(2))
	await wait_physics_frames(1)
	assert_almost_eq(_p.states.chance_factors[StatusEffects.Kind.ROT], before + 0.10, 0.0001)
	_p.stats.health_regen = 0.0
	var health := _p.health
	await wait_seconds(1.0)
	assert_lt(_p.health, health, "il ronge")
	assert_gt(_p.health, health * 0.985, "un pour cent par seconde, pas davantage")


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
		assert_true(_p.cast_slot(2))
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
	assert_false(_p.cast_slot(2))
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

	assert_true(_p.cast_slot(2))
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
	assert_true(_p.cast_slot(2))
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
	assert_true(_p.cast_slot(3))
	assert_true(_p.lit("spell_amplification"))
	assert_lt(_p.mana, mana, "il se paie")
	assert_almost_eq(_p.resolve(projectile, 1).total_min(), before * 1.2, 1e-3, "20 % amplifiés")
	await wait_physics_frames(10)
	assert_lt(_p.lit_ratio("spell_amplification"), 1.0, "le temps passe")

	_p._recharges[3] = 0.0
	assert_true(_p.cast_slot(3))
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

	assert_true(_p.cast_slot(2))
	await wait_seconds(0.6)
	assert_eq(_hits(first), 1, "traversée")
	assert_eq(_hits(second), 1, "frappée, et le tir s'y arrête")
	assert_eq(_hits(third), 0)


func test_a_splitting_bolt_throws_its_shards_past_the_target_once() -> void:
	_learn_with("manual_lightning", "swift_bolt", [[SkillStats.SPLITS, 3.0]])
	var first := _target(Vector2(40, 0))
	var behind := _target(Vector2(90, 0))
	await wait_physics_frames(2)

	assert_true(_p.cast_slot(2))
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


func test_a_ball_leaves_burning_ground_where_it_bursts() -> void:
	_learn_with("manual_fire", "fireball", [[SkillStats.GROUND, 1.0]])
	var direct := _target(Vector2(40, 0))
	await wait_physics_frames(2)

	assert_true(_p.cast_slot(2))
	await wait_seconds(0.3)
	assert_eq(_children_of(DashTrail).size(), 1, "le sol brûle")
	await wait_seconds(1.2)
	assert_gt(_hits(direct), 1, "et mord ce qui y reste")
	assert_eq(_children_of(DashTrail).size(), 0, "puis s'éteint")


## Traversée, la boule éclate aussi : sur chaque ennemi traversé, en étoile tournée d'un
## demi-pas pour laisser l'axe au tir, qui continue et frappe seul l'ennemi suivant.
func test_a_piercing_bolt_also_splits_on_what_it_goes_through() -> void:
	_learn_with("manual_lightning", "swift_bolt", [[SkillStats.PIERCE, 1.0], [SkillStats.SPLITS, 3.0]])
	var first := _target(Vector2(40, 0))
	var second := _target(Vector2(160, 0))
	await wait_physics_frames(2)

	assert_true(_p.cast_slot(2))
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
	assert_true(_p.cast_slot(2))
	await wait_physics_frames(3)
	assert_eq(_children_of(Projectile).size(), 0, "aucun tir")
	assert_eq(_hits(beside), 1, "la nova frappe à côté")


## Le Météore : rien pendant la chute, puis l'éclatement de la boule au point visé.
func test_a_meteor_falls_then_bursts_on_the_aim() -> void:
	_learn_with("manual_fire", "fireball", [], Skill.Shape.METEOR)
	var below := _target(Vector2(Player.PLACEMENT_RANGE, 0))
	var aside := _target(Vector2(0, 60))
	await wait_physics_frames(2)

	assert_true(_p.cast_slot(2))
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
	assert_true(_p.cast_slot(2))
	var meteors := _children_of(Meteor)
	assert_eq(meteors.size(), 3)
	var gap: float = meteors[0].global_position.distance_to(meteors[1].global_position)
	var radius := _p.resolve(SkillCatalog.by_id("fireball"), 1).radius
	assert_almost_eq(gap, radius, 0.01, "à un rayon l'un de l'autre")


## Fragmentation sur un météore : l'étoile d'éclats jaillit du point d'impact.
func test_a_meteor_throws_its_shards_from_the_impact() -> void:
	_learn_with("manual_fire", "fireball", [[SkillStats.SPLITS, 3.0]], Skill.Shape.METEOR)
	await wait_physics_frames(2)
	assert_true(_p.cast_slot(2))
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
	assert_true(_p.cast_slot(2))
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
	assert_true(_p.cast_slot(2))
	await wait_physics_frames(14)
	var shards := _children_of(Fireball)
	assert_eq(shards.size(), 3)
	for shard: Fireball in shards:
		assert_true(shard.is_shard)


func test_a_brood_drops_two_snakes_fanned_on_the_aim() -> void:
	_learn_with("manual_fire", "hell_snake", [[SkillStats.BROOD, 1.0]])
	assert_true(_p.cast_slot(2))
	var snakes := _children_of(HellSnake)
	assert_eq(snakes.size(), 2)
	assert_ne((snakes[0] as HellSnake)._cap, (snakes[1] as HellSnake)._cap, "en éventail")


## Vif : sa vitesse à lui, accrue en points de pourcentage — pas celle d'un projectile.
func test_a_swift_snake_crawls_faster() -> void:
	_learn_with("manual_fire", "hell_snake", [[SkillStats.CRAWL_SPEED, 100.0]])
	assert_true(_p.cast_slot(2))
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
	assert_true(_p.cast_slot(2))
	await wait_physics_frames(2)
	var snake: HellSnake = _children_of(HellSnake)[0]
	assert_eq(snake._anchor, prey.global_position)


## Sa mort : l'explosion finale et les petits, qui n'en relâchent pas d'autres.
func test_a_dying_snake_bursts_and_hatches() -> void:
	_learn_with("manual_fire", "hell_snake", [
		[SkillStats.END_BURST, 30.0], [SkillStats.HATCHLINGS, 2.0], ["duration", -90.0, true],
	])
	assert_true(_p.cast_slot(2))
	var snake: HellSnake = _children_of(HellSnake)[0]
	while is_instance_valid(snake):
		await wait_physics_frames(1)
	await wait_physics_frames(1)
	assert_eq(_children_of(Explosion).size(), 1, "l'explosion finale")
	assert_eq(_children_of(HellSnake).size(), 2, "deux petits")
	var hatchling: HellSnake = _children_of(HellSnake)[0]
	assert_eq(hatchling._cast.hatchlings, 0.0, "qui ne se diviseront pas")
	assert_eq(hatchling._cast.duration, SkillStats.HATCHLING_LIFE)


func test_a_dash_bursts_where_it_lands() -> void:
	_learn_with("manual_fire", "flame_dash", [[SkillStats.END_BURST, 30.0]])
	assert_true(_p.cast_slot(2))
	await wait_physics_frames(2)
	var burst: Array = _children_of(Explosion)
	assert_eq(burst.size(), 1)
	assert_eq((burst[0] as Explosion).global_position, _p.global_position, "à l'arrivée")


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


func test_an_aura_leaves_burning_ground_under_what_it_kills() -> void:
	var cast := _p.resolve(SkillCatalog.by_id("immolation"), 1)
	cast.ground_duration = 1.0
	_p.states.slew.emit(cast, Vector2(40, 0), null)
	await wait_physics_frames(2)
	assert_eq(_children_of(DashTrail).size(), 1)

	var ball := _p.resolve(SkillCatalog.by_id("fireball"), 1)
	ball.ground_duration = 1.0
	_p.states.slew.emit(ball, Vector2(40, 0), null)
	await wait_physics_frames(2)
	assert_eq(_children_of(DashTrail).size(), 1, "la boule pose le sien en éclatant, pas au tué")



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

	assert_true(_p.cast_slot(2))
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
	assert_true(_p.cast_slot(2))
	await wait_seconds(1.2)
	assert_eq(_hits(first), 1)
	assert_eq(_hits(far_aside), 1)


## Sans cône : le rebond repart aussi vers l'arrière, à plus de 90°.
func test_a_bolt_bounces_backward() -> void:
	_learn_with("manual_lightning", "swift_bolt", [[SkillStats.BOUNCES, 1.0]])
	var first := _target(Vector2(60, 0))
	var behind_it := _target(Vector2(20, 45))
	await wait_physics_frames(2)
	assert_true(_p.cast_slot(2))
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
	assert_true(_p.cast_slot(2))
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
	assert_true(_p.cast_slot(2))
	assert_eq(_hits(near), 1)
	assert_eq(_hits(far), 1, "au-delà d'un saut ordinaire")


## Crescendo : le même tirage, plus fort à chaque saut.
func test_each_jump_of_a_crescendo_hits_harder() -> void:
	_learn_with("manual_lightning", "chain_lightning", [[SkillStats.JUMP_GAIN, 50.0]])
	_p.skill_mods.assign([StatMod.new("crit_chance", StatMod.Mode.PERCENT, -100.0)])
	var targets := [_target(Vector2(60, 0)), _target(Vector2(120, 0)), _target(Vector2(180, 0))]
	await wait_physics_frames(2)
	assert_true(_p.cast_slot(2))
	var first := float(_received_all[targets[0]][0])
	assert_almost_eq(float(_received_all[targets[1]][0]), first * 1.5, 0.001)
	assert_almost_eq(float(_received_all[targets[2]][0]), first * 2.0, 0.001)


## Deux cibles : avec trois, la voisine de la dernière serait la troisième.
func test_the_last_target_of_the_chain_bursts() -> void:
	_learn_with("manual_lightning", "chain_lightning", [["targets", -1.0], [SkillStats.END_BURST, 30.0]])
	var first := _target(Vector2(60, 0))
	var last := _target(Vector2(120, 0))
	var beside_the_last := _target(Vector2(120, 25))
	await wait_physics_frames(2)
	assert_true(_p.cast_slot(2))
	await wait_physics_frames(3)
	assert_eq(_hits(first), 1)
	assert_eq(_hits(last), 1, "l'éclatement épargne la cible qui éclate")
	assert_eq(_hits(beside_the_last), 1, "l'éclatement seul")


## La Toile d'arcs : pas de cône ni de saut, les plus proches autour du lanceur.
func test_an_arc_web_strikes_the_nearest_all_around() -> void:
	_learn_with("manual_lightning", "chain_lightning", [], Skill.Shape.WEB)
	var ahead := _target(Vector2(60, 0))
	var behind := _target(Vector2(-60, 0))
	var far_from_all := _target(Vector2(0, ChainLightning.SCOPE + 30.0))
	await wait_physics_frames(2)
	assert_true(_p.cast_slot(2))
	assert_eq(_hits(ahead), 1)
	assert_eq(_hits(behind), 1, "derrière, hors du cône d'une chaîne")
	assert_eq(_hits(far_from_all), 0)
	assert_eq(_children_of(ChainLightning).size(), 2, "un arc par cible")


func test_a_wandering_cloud_drifts_toward_the_nearest_enemy() -> void:
	_learn_with("manual_lightning", "storm_cloud", [[SkillStats.SEEK, 200.0]])
	var prey := _target(Vector2(Player.PLACEMENT_RANGE, 100))
	await wait_physics_frames(2)
	assert_true(_p.cast_slot(2))
	var cloud: StormCloud = _children_of(StormCloud)[0]
	var before := cloud.global_position.distance_to(prey.global_position)
	await wait_seconds(0.5)
	assert_lt(cloud.global_position.distance_to(prey.global_position), before - 10.0)


func test_a_dissipating_cloud_bursts() -> void:
	_learn_with("manual_lightning", "storm_cloud", [[SkillStats.END_BURST, 30.0], ["duration", -80.0, true]])
	assert_true(_p.cast_slot(2))
	var cloud: StormCloud = _children_of(StormCloud)[0]
	while is_instance_valid(cloud):
		await wait_physics_frames(1)
	await wait_physics_frames(1)
	assert_eq(_children_of(Explosion).size(), 1)


## L'Orage portatif se forme sur le lanceur et le suit.
func test_a_portable_storm_follows_its_caster() -> void:
	_learn_with("manual_lightning", "storm_cloud", [], Skill.Shape.TEMPEST)
	assert_true(_p.cast_slot(2))
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
	assert_true(_p.cast_slot(2))
	assert_eq(_children_of(Projectile).size(), 0, "pas de tir")
	var orb: StaticOrb = _children_of(StaticOrb)[0]
	await wait_seconds(1.4)
	assert_gt(_hits(on_the_way), 1, "plusieurs décharges en passant")
	assert_true(is_instance_valid(orb), "et l'orbe continue")
	assert_gt(orb.global_position.x, 110.0)


func test_a_storm_dash_scatters_static_charges_on_its_path() -> void:
	_learn_with("manual_lightning", "storm_dash", [[SkillStats.TRAIL_CHARGES, 4.0]])
	var from_value := _p.global_position
	assert_true(_p.cast_slot(2))
	await wait_physics_frames(2)
	var charges := _children_of(StaticCharge)
	assert_eq(charges.size(), 4)
	for charge: StaticCharge in charges:
		assert_lt(charge.global_position.x, _p.global_position.x, "sur le trajet")
		assert_gt(charge.global_position.x, from_value.x)


## Le drain d'un buff se lit sur le lancer résolu : un nœud le change.
func test_a_buff_drains_what_its_tree_leaves() -> void:
	_learn_with("manual_lightning", "static_electricity", [["mana_per_second", -50.0, true]])
	assert_true(_p.cast_slot(2))
	# Après l'allumage, qui refait la fiche et sa régénération.
	_p.stats.mana_regen = 0.0
	var mana := _p.mana
	await wait_seconds(1.0)
	var drained := mana - _p.mana
	var full := SkillCatalog.by_id("static_electricity").mana_per_second
	assert_almost_eq(drained, full * 0.5, full * 0.1)
