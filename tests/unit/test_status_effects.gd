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
	# Ceux qu'un coup tire ; les autres, un lancer les pose (jalon 26).
	var rolled_natures := StatusEffects.ROLLED.map(func(k: int) -> int: return StatusEffects.NATURES[k])
	for nature in DamageType.Kind.size():
		assert_eq(rolled_natures.count(nature), 1, DamageType.NAMES[nature])


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
		+ StatusEffects.DECAY_PER_SECOND + StatusEffects.WILTING_PER_SECOND
	) * (1.0 + StatusEffects.NUMB)
	assert_almost_eq(e.advance(0.5), per_second * 0.5, 0.0001, "les cinq brûlures ensemble, engourdissement compris")


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


## Le facteur de l'auteur multiplie la chance d'embraser, et elle seule : « accrue »
## veut dire qu'elle ne crée rien là où la nature ne pose rien (jalon 20).
func test_the_author_factor_multiplies_the_chance_to_ignite() -> void:
	assert_almost_eq(
		StatusEffects.chance(10.0, 10.0, 0.0, 1.5), StatusEffects.CHANCE * 1.5, 1e-6
	)
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	var author := StatusEffects.new()
	author.chance_factors[StatusEffects.Kind.IGNITE] = 1.5
	var ignited := 0
	var numbed := 0
	for i in 4000:
		var e := StatusEffects.new()
		e.suffer(_parts(DamageType.Kind.FIRE, 10.0), author, rng)
		ignited += int(e.active(StatusEffects.Kind.IGNITE))
		var f := StatusEffects.new()
		f.suffer(_parts(DamageType.Kind.LIGHTNING, 10.0), author, rng)
		numbed += int(f.active(StatusEffects.Kind.NUMB))
	assert_between(ignited, 1080, 1320, "une fois sur cinq, et demie")
	assert_between(numbed, 680, 920, "l'engourdissement garde sa chance")


## Les facteurs du porteur sont **par sorte** : une chance de transir ne fait pas
## embraser mieux (jalon 21).
func test_the_author_factors_do_not_cross_over() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var author := StatusEffects.new()
	author.chance_factors[StatusEffects.Kind.CHILL] = 2.0
	var chilled := 0
	var ignited := 0
	for i in 4000:
		var cold := StatusEffects.new()
		cold.suffer(_parts(DamageType.Kind.COLD, 10.0), author, rng)
		chilled += int(cold.active(StatusEffects.Kind.CHILL))
		var fire := StatusEffects.new()
		fire.suffer(_parts(DamageType.Kind.FIRE, 10.0), author, rng)
		ignited += int(fire.active(StatusEffects.Kind.IGNITE))
	assert_between(chilled, 1450, 1750, "deux fois la chance de base")
	assert_between(ignited, 680, 920, "l'embrasement garde la sienne")


## Ce que le **lancer** accroît à sa propre chance : la nova de glace transit mieux
## qu'un coup de froid ordinaire, sans rien devoir à celui qui la lance (jalon 21).
func test_the_cast_increase_raises_the_chance_of_its_state() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var chilled := 0
	for i in 4000:
		var e := StatusEffects.new()
		e.suffer(_parts(DamageType.Kind.COLD, 10.0), null, rng, 0.0, 100.0)
		chilled += int(e.active(StatusEffects.Kind.CHILL))
	assert_between(chilled, 1450, 1750, "deux fois la chance de base")


## **Les deux accrus s'additionnent**, comme tous les accrus du jeu : +50 porté et +50
## du lancer font 20 → 40 %, et non les 45 % de deux multiplications à la suite.
func test_the_two_increases_add_up_before_multiplying() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var author := StatusEffects.new()
	author.chance_factors[StatusEffects.Kind.CHILL] = 1.5
	var chilled := 0
	for i in 4000:
		var e := StatusEffects.new()
		e.suffer(_parts(DamageType.Kind.COLD, 10.0), author, rng, 0.0, 50.0)
		chilled += int(e.active(StatusEffects.Kind.CHILL))
	assert_between(chilled, 1480, 1720, "deux fois la chance de base, pas 2,25")


## La table des statistiques de chance est indexée par sorte, et chaque nom qu'elle
## donne est un champ réel de la fiche : c'est par elle que le porteur écrit ses
## facteurs et que la page du manuel trouve son libellé.
func test_each_chance_stat_is_a_real_field_with_a_label() -> void:
	assert_eq(StatusEffects.CHANCE_STATS.size(), StatusEffects.Kind.size())
	var sheet := CharacterStats.new()
	for kind in StatusEffects.CHANCE_STATS.size():
		var field: String = StatusEffects.CHANCE_STATS[kind]
		if field.is_empty():
			continue
		assert_true(field in sheet, "« %s » n'est pas un champ de la fiche" % field)
		assert_true(StatMod.LABELS.has(field), "« %s » n'a pas de libellé" % field)


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


# --------------------------------------------------------------------------
# Ce que pose un lancer (jalon 26)
# --------------------------------------------------------------------------

## La décomposition rejoue le coup nécrotique entier sur sa durée, comme l'embrasement
## le feu : elle suit donc le niveau du sort.
func test_a_cast_inflicts_its_state_from_the_hit_in_its_nature() -> void:
	var rng := RandomNumberGenerator.new()
	var e := StatusEffects.new()
	e.inflict(StatusEffects.Kind.DECAY, 1.0, _parts(DamageType.Kind.NECROTIC, 40.0), null, rng)
	assert_true(e.active(StatusEffects.Kind.DECAY))
	assert_almost_eq(
		e.advance(StatusEffects.DURATIONS[StatusEffects.Kind.DECAY]), 40.0, 0.001,
		"le coup rejoué sur quatre secondes"
	)


## Son jumeau : un sort converti n'a plus de part nécrotique, et une chance nulle ne
## pose rien — mais les deux tirent une fois (invariant 3).
func test_nothing_inflicted_without_the_nature_or_the_chance_but_one_roll_each() -> void:
	for attempt: Array in [
		[1.0, _parts(DamageType.Kind.FIRE, 40.0)], [0.0, _parts(DamageType.Kind.NECROTIC, 40.0)]
	]:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		var e := StatusEffects.new()
		e.inflict(StatusEffects.Kind.DECAY, attempt[0], attempt[1], null, rng)
		assert_false(e.active(StatusEffects.Kind.DECAY))
		var twin := RandomNumberGenerator.new()
		twin.seed = 7
		twin.randf()
		assert_eq(rng.state, twin.state, "un tirage, quel que soit le résultat")


## Un lancer ne pose que son état : la décomposition n'est pas tirée par la nature.
func test_a_necrotic_hit_never_rolls_decay() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var e := StatusEffects.new()
	for i in 50:
		e.suffer(_parts(DamageType.Kind.NECROTIC, 1000.0), null, rng)
	assert_true(e.active(StatusEffects.Kind.ROT), "la pourriture, oui")
	assert_false(e.active(StatusEffects.Kind.DECAY), "la décomposition, jamais")


func test_each_decay_tick_rolls_rot_on_behalf_of_its_author() -> void:
	var author := StatusEffects.new()
	author.chance_factors[StatusEffects.Kind.ROT] = 100.0
	_heals = 0.0
	author.heal.connect(func(amount: float) -> void: _heals += amount)
	var e := StatusEffects.new()
	e.put(StatusEffects.Kind.DECAY, 40.0, author)
	e.advance(StatusEffects.DOT_TICK * 0.5)
	assert_false(e.active(StatusEffects.Kind.ROT), "pas avant l'à-coup")
	e.advance(StatusEffects.DOT_TICK * 0.5)
	assert_true(e.active(StatusEffects.Kind.ROT), "à l'à-coup, à coup sûr ici")
	e.advance(0.5)
	assert_gt(_heals, 0.0, "et c'est l'auteur qu'elle soigne")


## Son jumeau : sans chance, les à-coups ne pourrissent jamais.
func test_decay_does_not_rot_without_a_chance() -> void:
	var author := StatusEffects.new()
	author.chance_factors[StatusEffects.Kind.ROT] = 0.0
	var e := StatusEffects.new()
	e.put(StatusEffects.Kind.DECAY, 40.0, author)
	for i in 8:
		e.advance(StatusEffects.DOT_TICK)
	assert_false(e.active(StatusEffects.Kind.ROT))


## Avant le plafond : un ennemi à 0 % passe à −20 %, donc prend 20 % de plus.
func test_the_curse_lowers_necrotic_resistance_only() -> void:
	var e := StatusEffects.new()
	assert_eq(e.resistance_lost(DamageType.Kind.NECROTIC), 0.0, "sans malédiction, rien")
	e.put(StatusEffects.Kind.CURSED, 0.0)
	assert_eq(e.resistance_lost(DamageType.Kind.NECROTIC), StatusEffects.CURSE)
	assert_eq(e.resistance_lost(DamageType.Kind.FIRE), 0.0, "le feu n'y perd rien")
	var sheet := CharacterStats.new()
	assert_almost_eq(
		sheet.mitigate(DamageType.Kind.NECROTIC, 100.0, e.resistance_lost(DamageType.Kind.NECROTIC)),
		120.0, 0.001
	)
	assert_eq(e.advance(1.0), 0.0, "et elle ne brûle rien")
