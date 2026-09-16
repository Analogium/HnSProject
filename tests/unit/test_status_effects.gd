extends GutTest

## Les états qu'un coup laisse derrière lui (jalon 12) : quand ils se posent, ce
## qu'ils changent, ce qu'ils brûlent et quand ils s'en vont. Unitaires : `StatusEffects` ne
## connaît ni nœud ni coup, seulement des parts, un auteur et un tirage.

## Des membres et non des locales : une lambda GDScript capture par valeur.
var _changes := 0
var _heals := 0.0


func _parts(nature: DamageType.Kind, amount: float) -> Array[float]:
	var p := DamageType.empty_parts()
	p[nature] = amount
	return p


func test_each_nature_applies_one_state_only() -> void:
	assert_eq(StatusEffects.NATURES.size(), StatusEffects.Kind.size())
	assert_eq(StatusEffects.NAMES.size(), StatusEffects.Kind.size())
	assert_eq(StatusEffects.DURATIONS.size(), StatusEffects.Kind.size())
	for nature in DamageType.Kind.size():
		assert_eq(StatusEffects.NATURES.count(nature), 1, DamageType.NAMES[nature])


## Une couleur qui ressemble à une autre ne dit plus lequel des deux on porte.
## Invariant 1 : un affixe nomme l'état par son identifiant.
func test_each_state_has_its_id_and_its_line() -> void:
	assert_eq(StatusEffects.IDS.size(), StatusEffects.Kind.size())
	assert_eq(StatusEffects.AGAINST.size(), StatusEffects.Kind.size())
	for kind in StatusEffects.Kind.values():
		assert_eq(SkillStats.against(SkillStats.against_stat(kind)), kind, StatusEffects.IDS[kind])


func test_each_state_has_its_color() -> void:
	for a in StatusEffects.Kind.size():
		for b in range(a + 1, StatusEffects.Kind.size()):
			assert_ne(StatusEffects.color(a), StatusEffects.color(b), "%s et %s" % [StatusEffects.NAMES[a], StatusEffects.NAMES[b]])
	assert_ne(StatusEffects.color(StatusEffects.Kind.BLEED), HealthBar.LOW, "le sang n'est pas une barre basse")


func test_each_state_has_its_icon() -> void:
	assert_eq(StatusIcon.MASKS.size(), StatusEffects.Kind.size(), "une icône par état")
	for kind in StatusEffects.Kind.size():
		var img := StatusIcon.texture(kind).get_image()
		assert_eq(img.get_size(), Vector2i(StatusIcon.SIDE, StatusIcon.SIDE), StatusEffects.NAMES[kind])
		assert_eq(img.get_pixel(4, 4).a, 1.0, "%s : le centre est peint" % StatusEffects.NAMES[kind])


## Tous les états se portent à la fois, et ce qui brûle s'additionne : seuls deux
## états de la même sorte ne se cumulent pas.
func test_all_states_can_be_carried_together() -> void:
	var e := StatusEffects.new()
	for kind in StatusEffects.Kind.size():
		e.put(kind, 40.0)
	for kind in StatusEffects.Kind.size():
		assert_true(e.active(kind), StatusEffects.NAMES[kind])
	assert_eq(e.colors().size(), StatusEffects.Kind.size())
	var per_second := 40.0 * (
		StatusEffects.IGNITE_PER_SECOND + StatusEffects.ROT_PER_SECOND + StatusEffects.BLEED_PER_SECOND
	) * (1.0 + StatusEffects.NUMB)
	assert_almost_eq(e.advance(0.5), per_second * 0.5, 0.0001, "les trois brûlures ensemble, engourdissement compris")


## **Invariant 3.** Un coup tire une fois par nature qu'il porte, physique compris,
## qu'il pose quelque chose ou non. Un coup nul ne tire rien.
func test_one_roll_per_present_nature_whatever_the_result() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var before := rng.state
	StatusEffects.new().suffer(DamageType.empty_parts(), null, rng)
	assert_eq(rng.state, before, "un coup nul ne tire rien")

	var melee_hit := DamageType.empty_parts()
	melee_hit[DamageType.Kind.PHYSICAL] = 10.0
	melee_hit[DamageType.Kind.FIRE] = 10.0
	melee_hit[DamageType.Kind.COLD] = 10.0
	var indicator := RandomNumberGenerator.new()
	indicator.seed = 42
	indicator.state = rng.state
	indicator.randf()
	indicator.randf()
	indicator.randf()
	# Un PV max : chaque chance dépasse 1, tout pose, et le compte ne bouge pas.
	StatusEffects.new().suffer(melee_hit, null, rng, 1.0)
	assert_eq(rng.state, indicator.state, "trois natures, trois tirages, même quand tout pose")


## Le froid qu'un anneau met dans un éclair ne gèle pas aussi souvent qu'un sort de
## froid : la chance se partage selon les parts.
func test_chance_follows_the_nature_share() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var melee_hit := DamageType.empty_parts()
	melee_hit[DamageType.Kind.FIRE] = 10.0
	melee_hit[DamageType.Kind.PHYSICAL] = 10.0
	var pure := 0
	var half := 0
	for i in 4000:
		var a := StatusEffects.new()
		a.suffer(_parts(DamageType.Kind.FIRE, 10.0), null, rng)
		pure += int(a.active(StatusEffects.Kind.IGNITE))
		var b := StatusEffects.new()
		b.suffer(melee_hit, null, rng)
		half += int(b.active(StatusEffects.Kind.IGNITE))
	# Fenêtres larges : on vérifie la règle, pas la qualité du générateur.
	assert_between(pure, 680, 920, "un coup de feu pur embrase une fois sur cinq")
	assert_between(half, 320, 480, "à moitié de feu, une fois sur dix")


## Ce qu'un coup retire des PV max s'ajoute à sa chance : 10 de feu sur 50 PV, 40 %.
func test_chance_grows_with_the_share_of_hp_removed() -> void:
	assert_almost_eq(StatusEffects.chance(10.0, 10.0, 0.0), StatusEffects.CHANCE, 1e-6, "sans PV connus, la chance seule")
	assert_almost_eq(StatusEffects.chance(10.0, 10.0, 50.0), StatusEffects.CHANCE + 0.2 * StatusEffects.CHANCE_PER_HP_LOST, 1e-6)
	assert_almost_eq(
		StatusEffects.chance(10.0, 20.0, 1000.0), StatusEffects.CHANCE * 0.5 + 0.01 * StatusEffects.CHANCE_PER_HP_LOST, 1e-6,
		"un coup mêlé sur une grosse cible garde presque sa chance seule"
	)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var poses := 0
	for i in 4000:
		var e := StatusEffects.new()
		e.suffer(_parts(DamageType.Kind.FIRE, 10.0), null, rng, 50.0)
		poses += int(e.active(StatusEffects.Kind.IGNITE))
	assert_between(poses, 1450, 1750, "et le tirage la suit")


func test_what_the_three_non_burning_states_change() -> void:
	var e := StatusEffects.new()
	assert_eq(e.damage_taken_factor, 1.0)
	assert_eq(e.damage_dealt_factor, 1.0)
	assert_eq(e.speed_factor, 1.0)
	e.put(StatusEffects.Kind.NUMB, 5.0)
	e.put(StatusEffects.Kind.BLESSING, 5.0)
	e.put(StatusEffects.Kind.CHILL, 5.0)
	assert_almost_eq(e.damage_taken_factor, 1.10, 0.0001, "engourdi : +10 % de dégâts reçus")
	assert_almost_eq(e.damage_dealt_factor, 0.80, 0.0001, "béni : −20 % de dégâts infligés")
	assert_almost_eq(e.speed_factor, 0.75, 0.0001, "transi : −25 % de vitesse d'action")
	assert_eq(e.advance(1.0), 0.0, "aucun des trois ne brûle")


func test_a_state_refreshes_then_leaves() -> void:
	var e := StatusEffects.new()
	_changes = 0
	e.change.connect(func() -> void: _changes += 1)
	e.put(StatusEffects.Kind.CHILL, 1.0)
	assert_eq(_changes, 1, "il apparaît")
	e.advance(1.5)
	e.put(StatusEffects.Kind.CHILL, 1.0)
	assert_almost_eq(e.remaining(StatusEffects.Kind.CHILL), StatusEffects.DURATIONS[StatusEffects.Kind.CHILL], 0.0001, "un nouveau coup rend la durée")
	assert_eq(_changes, 1, "rafraîchir ne redessine rien")
	e.advance(StatusEffects.DURATIONS[StatusEffects.Kind.CHILL] + 0.01)
	assert_false(e.active(StatusEffects.Kind.CHILL))
	assert_eq(_changes, 2, "et sa fin se voit")


func test_ignite_replays_the_fire_received_over_its_duration() -> void:
	var e := StatusEffects.new()
	e.put(StatusEffects.Kind.IGNITE, 20.0)
	var total := 0.0
	for i in 100:
		total += e.advance(0.05)
	assert_almost_eq(total, 20.0, 0.001, "le coup se rejoue en entier, et pas une braise de plus")
	assert_false(e.active(StatusEffects.Kind.IGNITE))


func test_a_weaker_ignite_does_not_replace_the_stronger() -> void:
	var e := StatusEffects.new()
	e.put(StatusEffects.Kind.IGNITE, 40.0)
	e.advance(2.0)
	e.put(StatusEffects.Kind.IGNITE, 4.0)
	assert_almost_eq(e.remaining(StatusEffects.Kind.IGNITE), 2.0, 0.0001, "la petite braise n'éteint pas la grosse")
	e.put(StatusEffects.Kind.IGNITE, 80.0)
	assert_almost_eq(e.remaining(StatusEffects.Kind.IGNITE), 4.0, 0.0001, "la plus forte la remplace")
	assert_almost_eq(e.advance(1.0), 80.0 * StatusEffects.IGNITE_PER_SECOND, 0.0001)


func test_numb_amplifies_what_burns() -> void:
	var e := StatusEffects.new()
	e.put(StatusEffects.Kind.IGNITE, 40.0)
	var without := e.advance(0.5)
	e.put(StatusEffects.Kind.NUMB, 1.0)
	assert_almost_eq(e.advance(0.5), without * 1.10, 0.0001)


func test_rot_heals_whoever_applied_it() -> void:
	var author := StatusEffects.new()
	_heals = 0.0
	author.heal.connect(func(amount: float) -> void: _heals += amount)
	var victim := StatusEffects.new()
	victim.put(StatusEffects.Kind.ROT, 50.0, author)
	var lost := 0.0
	for i in 10:
		lost += victim.advance(0.1)
	assert_almost_eq(lost, 50.0 * StatusEffects.ROT_PER_SECOND, 0.0001, "une petite brûlure")
	assert_almost_eq(_heals, lost * StatusEffects.ROT_HEAL, 0.0001, "dont la moitié revient à son auteur")


func test_a_vanished_author_heals_nobody() -> void:
	var victim := StatusEffects.new()
	var author := StatusEffects.new()
	victim.put(StatusEffects.Kind.ROT, 50.0, author)
	author = null
	assert_gt(victim.advance(0.5), 0.0, "la pourriture lui survit, sans erreur")


## La raison de la référence faible : deux RefCounted qui se tiennent ne sont jamais
## libérés, et un joueur et un ennemi qui se pourrissent l'un l'autre fuiraient.
func test_two_crossed_rots_do_not_keep_each_other_alive() -> void:
	var a := StatusEffects.new()
	var b := StatusEffects.new()
	a.put(StatusEffects.Kind.ROT, 1.0, b)
	b.put(StatusEffects.Kind.ROT, 1.0, a)
	var indicator: WeakRef = weakref(a)
	a = null
	b = null
	assert_null(indicator.get_ref())


func test_a_burn_number_floats_up_every_half_second() -> void:
	var e := StatusEffects.new()
	e.put(StatusEffects.Kind.IGNITE, 40.0)   # dix par seconde
	e.advance(0.3)
	assert_eq(e.digit(), 0.0, "pas de chiffre par image")
	e.advance(0.3)
	assert_almost_eq(e.digit(), 6.0, 0.0001, "ce qu'ont brûlé les deux pas")
	assert_eq(e.digit(), 0.0, "et il ne se lit qu'une fois")
	var shows := 0.0
	for i in 40:
		e.advance(0.1)
		shows += e.digit()
	assert_almost_eq(shows, 34.0, 0.001, "la dernière demi-seconde ne disparaît pas de l'écran")


func test_clear_erases_everything_and_says_so() -> void:
	var e := StatusEffects.new()
	e.put(StatusEffects.Kind.IGNITE, 40.0)
	e.put(StatusEffects.Kind.CHILL, 1.0)
	_changes = 0
	e.change.connect(func() -> void: _changes += 1)
	e.clear()
	assert_true(e.is_clear)
	assert_eq(_changes, 1)
	assert_eq(e.advance(1.0), 0.0)
