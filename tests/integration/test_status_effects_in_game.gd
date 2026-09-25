extends GutTest

## Les états dans le jeu (jalon 12) : posés par la hurtbox, appliqués par ceux qui
## les portent — la vie, la cadence, la marche, les coups —, et montrés.

var _received := -1.0
var _fx: HitFeedback
var _taken_visible: bool
var _dealt_visible: bool
var _chill_duration: float


func before_each() -> void:
	_taken_visible = Settings.damage_taken_visible
	_dealt_visible = Settings.damage_dealt_visible
	_chill_duration = Game.hit_stop_duration
	Game.hit_stop_duration = 0.0
	_received = -1.0
	_fx = HitFeedback.new()
	add_child_autofree(_fx)


func after_each() -> void:
	Settings.damage_taken_visible = _taken_visible
	Settings.damage_dealt_visible = _dealt_visible
	Game.hit_stop_duration = _chill_duration
	Engine.time_scale = 1.0


func _zone(states: StatusEffects) -> Hurtbox:
	var hb := Hurtbox.new()
	hb.stats = CharacterStats.new()
	hb.states = states
	add_child_autofree(hb)
	hb.damaged.connect(func(info: DamageInfo) -> void: _received = info.amount)
	return hb


func _player() -> Player:
	var p: Player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(p)
	await wait_physics_frames(1)
	return p


func _grunt(where := Vector2.ZERO) -> Enemy:
	var e: Enemy = load("res://actors/enemies/grunt.tscn").instantiate()
	e.position = where
	add_child_autofree(e)
	return e


# --------------------------------------------------------------------------
# La hurtbox
# --------------------------------------------------------------------------

func test_the_numbed_take_ten_percent_more() -> void:
	var states := StatusEffects.new()
	var hb := _zone(states)
	hb.take_damage(DamageInfo.new(20.0, Vector2.ZERO))
	assert_almost_eq(_received, 20.0, 0.001)
	states.put(StatusEffects.Kind.NUMB, 1.0)
	hb.take_damage(DamageInfo.new(20.0, Vector2.ZERO))
	assert_almost_eq(_received, 22.0, 0.001)


func test_a_blessed_author_hits_less_hard() -> void:
	var hb := _zone(StatusEffects.new())
	var author := StatusEffects.new()
	author.put(StatusEffects.Kind.BLESSING, 1.0)
	var info := DamageInfo.new(20.0, Vector2.ZERO)
	info.author = author
	hb.take_damage(info)
	assert_almost_eq(_received, 16.0, 0.001)


## Le coup béni est un coup plus petit, et l'armure protège mieux des petits coups :
## appliquée après elle, la bénédiction affaiblirait moins qu'annoncé.
func test_blessing_applies_before_armor() -> void:
	var hb := _zone(StatusEffects.new())
	hb.stats.armor = 60.0
	var author := StatusEffects.new()
	author.put(StatusEffects.Kind.BLESSING, 1.0)
	var info := DamageInfo.new(15.0, Vector2.ZERO)
	info.author = author
	hb.take_damage(info)
	assert_almost_eq(_received, 12.0 * (1.0 - hb.stats.armor_reduction(12.0)), 0.001)


func test_an_elemental_hit_eventually_applies_its_state() -> void:
	var states := StatusEffects.new()
	var hb := _zone(states)
	Game.rng.seed = 3
	for i in 200:
		if states.active(StatusEffects.Kind.CHILL):
			break
		hb.take_damage(DamageInfo.new(10.0, Vector2.ZERO, 0.0, false, DamageType.Kind.COLD))
	assert_true(states.active(StatusEffects.Kind.CHILL), "un coup de froid finit par transir")
	assert_false(states.active(StatusEffects.Kind.IGNITE), "et ne pose que le sien")


## Le coup d'un grunt ou d'une épée. Une hurtbox sans états, elle, ne tire toujours
## rien — voir `test_hurtbox.gd`.
func test_a_physical_hit_eventually_causes_bleeding() -> void:
	var states := StatusEffects.new()
	var hb := _zone(states)
	Game.rng.seed = 5
	for i in 200:
		if states.active(StatusEffects.Kind.BLEED):
			break
		hb.take_damage(DamageInfo.new(10.0, Vector2.ZERO))
	assert_true(states.active(StatusEffects.Kind.BLEED))
	assert_gt(states.advance(1.0), 0.0, "et il saigne")


## Un sort de foudre qui porte un ajout de chaque nature : converti à moitié, les six
## états finissent par tomber ; converti en entier, seul celui de la nature d'arrivée.
func test_a_converted_hit_only_applies_what_it_carries() -> void:
	Settings.damage_dealt_visible = false
	for part in [0.5, 1.0]:
		var cast := SkillStats.new()
		cast.place_the_base(DamageType.Kind.LIGHTNING, 100.0)
		for nature in DamageType.Kind.size():
			cast.add_to(nature, 10.0, 10.0)
		cast.apply_conversion(DamageType.Kind.COLD, part)
		var states := StatusEffects.new()
		var hb := _zone(states)
		Game.rng.seed = 7
		for i in 3000:
			hb.take_damage(DamageInfo.as_parts(cast.roll(Game.rng), Vector2.ZERO))
		for kind: int in StatusEffects.ROLLED:
			var expected: bool = part < 1.0 or kind == StatusEffects.Kind.CHILL
			assert_eq(states.active(kind), expected, "%s, converti à %d %%" % [StatusEffects.NAMES[kind], roundi(part * 100.0)])


# --------------------------------------------------------------------------
# Les ennemis
# --------------------------------------------------------------------------

func test_an_enemy_dies_from_its_burn_and_rewards() -> void:
	var player := await _player()
	var m := EnemyManager.new()
	m.target = player
	add_child_autofree(m)
	var e := m.spawn(load("res://actors/enemies/grunt.tscn"), Vector2(300, 0))
	await wait_physics_frames(1)
	e._set_health(5.0)
	e.states.put(StatusEffects.Kind.IGNITE, 40.0)
	var xp := player.xp
	await wait_seconds(1.0)
	assert_false(is_instance_valid(e), "la brûlure l'a tué, par le pilote des ennemis")
	assert_gt(player.xp, xp, "et sa mort a rapporté")


func test_a_chilled_enemy_walks_and_recharges_slower() -> void:
	var e := _grunt()
	var speed := e.movement_speed()
	e._attack_cd = 1.0
	e.states.put(StatusEffects.Kind.CHILL, 1.0)
	assert_almost_eq(e.movement_speed(), speed * 0.75, 0.001)
	e._cool_down(0.4)
	assert_almost_eq(e._attack_cd, 0.7, 0.001, "la recharge en cours ralentit aussi")
	assert_almost_eq(e.sprite.speed_scale, 0.75, 0.001, "et son animation avec")


func test_a_player_rot_heals_them() -> void:
	var player := await _player()
	player._set_health(50.0)
	var e := _grunt(Vector2(300, 0))
	e.states.put(StatusEffects.Kind.ROT, 100.0, player.states)
	e.suffer_states(1.0)
	assert_almost_eq(
		player.health, 50.0 + 100.0 * StatusEffects.ROT_PER_SECOND * StatusEffects.ROT_HEAL, 0.01
	)


func test_an_enemy_burn_shows_in_white_behind_its_slot() -> void:
	var e := _grunt()
	e.states.put(StatusEffects.Kind.IGNITE, 40.0)
	e.suffer_states(0.3)
	assert_eq(_fx._numbers.size(), 0, "pas de chiffre par image")
	e.suffer_states(0.3)
	assert_eq(_fx._numbers.size(), 1)
	assert_eq(_fx._numbers[0].tint, HitFeedback.NUMBER)
	Settings.damage_dealt_visible = false
	e.suffer_states(0.6)
	assert_eq(_fx._numbers.size(), 1, "la case des dégâts infligés la coupe")


func test_a_state_shows_on_the_body_and_above() -> void:
	var e := _grunt()
	assert_false(e.health_bar.visible, "pleine vie : rien au-dessus")
	e.states.put(StatusEffects.Kind.IGNITE, 1.0)
	assert_true(e.health_bar.visible, "une icône, même à pleine vie")
	assert_eq(e.health_bar._kinds, [StatusEffects.Kind.IGNITE] as Array[int])
	assert_almost_eq(float(e.sprite.material.get_shader_parameter("tint_strength")), ActorSprite.STATE_TINT, 0.001)
	e.states.advance(10.0)
	assert_false(e.health_bar.visible, "l'état fini, la barre se recache")
	assert_eq(float(e.sprite.material.get_shader_parameter("tint_strength")), 0.0)


# --------------------------------------------------------------------------
# Le joueur
# --------------------------------------------------------------------------

func test_a_chilled_player_recharges_slower() -> void:
	var player := await _player()
	player.states.put(StatusEffects.Kind.CHILL, 1.0)
	# Un pas appelé à la main et non des images attendues : l'attente en compte une
	# de plus ou de moins selon la machine.
	player._recharges[0] = 1.0
	player._physics_process(0.4)
	assert_almost_eq(player._recharges[0], 1.0 - 0.4 * 0.75, 0.001)


func test_a_new_state_announces_itself_above_the_player() -> void:
	var player := await _player()
	player.states.put(StatusEffects.Kind.CHILL, 1.0)
	assert_eq(_fx._numbers.size(), 1)
	assert_eq(_fx._numbers[0].text, "transi")
	assert_eq(_fx._numbers[0].tint, StatusEffects.color(StatusEffects.Kind.CHILL))
	player.states.put(StatusEffects.Kind.CHILL, 1.0)
	assert_eq(_fx._numbers.size(), 1, "rafraîchi, il ne se réannonce pas")


## La brûlure d'Immolation est « reçue » comme le reste.
func test_numb_amplifies_immolation_burn() -> void:
	var player := await _player()
	player.stats.max_health = 100.0
	var fire := DamageType.empty_parts()
	fire[DamageType.Kind.FIRE] = 1.0
	player.stats.res_fire = 0.0
	player._set_health(100.0)
	player.burn(0.1, fire, 1.0)
	var without := 100.0 - player.health
	player._set_health(100.0)
	player.states.put(StatusEffects.Kind.NUMB, 1.0)
	player.burn(0.1, fire, 1.0)
	assert_almost_eq(100.0 - player.health, without * 1.10, 0.001)


func test_a_blessed_player_bolt_hits_less_hard() -> void:
	var player := await _player()
	player.states.put(StatusEffects.Kind.BLESSING, 1.0)
	var target := Hurtbox.new()
	target.collision_layer = Targets.ENEMIES
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	target.add_child(shape)
	add_child_autofree(target)
	target.global_position = Vector2(60, 0)
	target.damaged.connect(func(info: DamageInfo) -> void: _received = info.amount)
	var parts := DamageType.empty_parts()
	parts[DamageType.Kind.LIGHTNING] = 10.0
	Projectile.spawn(self, player.bolt_scene, Vector2.ZERO, Vector2.RIGHT, parts, player, 300.0)
	await wait_seconds(0.5)
	assert_almost_eq(_received, 8.0, 0.001, "l'auteur voyage avec le tir")


func test_death_clears_the_player_states() -> void:
	var player := await _player()
	player.states.put(StatusEffects.Kind.IGNITE, 10.0)
	player._die()
	assert_true(player.states.is_clear)
