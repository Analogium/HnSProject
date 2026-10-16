class_name Vermin
extends RefCounted

## Les rats du joueur de flûte (jalon 53) hors du coup qui les accroche : ce qu'ils deviennent
## à la mort de leur porteur — la Contagion, la Disette — et leur éclat, que la Danse macabre
## déclenche. Rien ne vit ici : les rats sont un état (`StatusEffects.Kind.RATS`), leur nombre
## sa force.


## Un porteur de rats ou un maudit vient de tomber. En différé : on meurt souvent dans un
## rappel de collision (invariant 4). `own` : sa hurtbox, encore dans l'arbre.
static func on_death(world: World2D, at: Vector2, states: StatusEffects, own: int) -> void:
	var curse := states.cast_of(StatusEffects.Kind.CURSED)
	if curse != null and curse.skill_id == SkillStats.CONTAGION_SKILL:
		_contagion(world, at, states, own, curse)
		return
	var author := states.author_of(StatusEffects.Kind.RATS)
	if states.rats() > 0 and author != null and author.rat_rules != null and author.rat_rules.famine:
		var heirs := neighbours(world, at, own, SkillStats.FAMINE_REACH)
		if not heirs.is_empty():
			_hand(states, at, heirs.slice(0, 1), states.rats())


## La Contagion : le maudit éclate sur ses voisins, leur passe ses rats, et sous la Peste
## galopante sa malédiction, avec ce qu'il lui en restait.
static func _contagion(
	world: World2D, at: Vector2, states: StatusEffects, own: int, curse: SkillStats
) -> void:
	var author := states.author_of(StatusEffects.Kind.CURSED)
	var near := neighbours(world, at, own, SkillStats.CONTAGION_REACH)
	var burst := curse.echoed(1.0 + curse.ague * 0.01)
	# L'éclat ne maudit pas : seule la Peste galopante passe la malédiction.
	burst.inflicted_state = -1
	var parts := burst.roll(Game.rng)
	for target in near:
		Targets.strike(target, parts, at, author, burst)
	var heirs := near.slice(0, 1 + int(curse.propagation))
	_hand(states, at, heirs, states.rats())
	if curse.galloping <= 0.0:
		return
	var kind := StatusEffects.Kind.CURSED
	var left := states.remaining(kind) + curse.great_plague
	for heir in heirs:
		if is_instance_valid(heir) and not heir.states.active(kind):
			heir.states.put(kind, 0.0, author, curse.skill_id, curse.strength_of(kind), left)
			heir.states.attach(kind, curse)


## `count` rats de ce porteur, répartis entre ces héritiers, au rongement qu'ils avaient ; on
## les voit courir de `at` jusqu'à chacun.
static func _hand(states: StatusEffects, at: Vector2, heirs: Array[Hurtbox], count: int) -> void:
	if count <= 0 or heirs.is_empty():
		return
	var gnaw := states.gnaw_per_rat()
	var author := states.author_of(StatusEffects.Kind.RATS)
	var source := states.source_of(StatusEffects.Kind.RATS)
	for i in heirs.size():
		var share := count / heirs.size() + (1 if i < count % heirs.size() else 0)
		if is_instance_valid(heirs[i]):
			heirs[i].states.add_rats(share, gnaw, author, source)
			RatRun.send(at, heirs[i], share)


## Les vivants autour de ce point, du plus proche au plus loin, sauf `own`.
static func neighbours(world: World2D, at: Vector2, own: int, reach: float) -> Array[Hurtbox]:
	var out := Targets.in_circle(world, at, reach).filter(
		func(t: Hurtbox) -> bool:
			var body := t.get_parent() as Enemy
			return t.get_instance_id() != own and t.states != null and (body == null or not body.is_dead)
	)
	out.sort_custom(
		func(a: Hurtbox, b: Hurtbox) -> bool:
			return at.distance_squared_to(a.global_position) < at.distance_squared_to(b.global_position)
	)
	return out


## L'éclat de la Danse macabre sur un porteur : `count` de ses rats (tous à −1) éclatent, un
## coup nécrotique chacun à `BURST_PART` du coup de la danse, l'Ossuaire compris. Sous la Danse
## des morts ils restent accrochés, éperonnés par la Ritournelle ; sur un maudit des Rats
## pesteux, chacun en accroche au plus proche voisin. Rend combien ont éclaté.
static func burst(
	target: Hurtbox, cast: SkillStats, author: StatusEffects, parent: Node, count := -1
) -> int:
	if not is_instance_valid(target) or target.states == null:
		return 0
	var held := target.states.rats()
	var popped := held if count < 0 else mini(count, held)
	if popped <= 0:
		return 0
	var gnaw := target.states.gnaw_per_rat()
	var at := target.global_position
	var curse := target.states.cast_of(StatusEffects.Kind.CURSED)
	if curse != null and curse.plague_rats > 0.0:
		var heirs := neighbours(target.get_world_2d(), at, target.get_instance_id(), SkillStats.CONTAGION_REACH)
		if not heirs.is_empty():
			heirs[0].states.add_rats(popped * int(curse.plague_rats), gnaw, author, cast.skill_id)
	if cast.dead_dance > 0.0:
		target.states.spur_rats(1.0 + cast.ritornello * 0.01)
	else:
		target.states.take_rats(popped)
	var blow := necrotic(cast, SkillStats.BURST_PART * maxf(1.0 + cast.ossuary * 0.01, 0.0))
	# Un seul coup pour tous : dix chiffres d'un coup ne se liraient pas.
	Targets.strike(target, DamageType.scaled(blow.roll(Game.rng), float(popped)), at, author, blow)
	RatBurst.pop(parent, at, popped)
	# Le Charnier : un sol nécrotique où chaque rat a éclaté.
	if cast.charnel > 0.0 and is_instance_valid(parent):
		var ground := blow.echoed(cast.charnel * 0.01)
		ground.duration = SkillStats.CHARNEL_TIME
		ground.period = SkillStats.GROUND_PERIOD
		ground.radius = SkillStats.GROUND_RADIUS
		ground.rats = 0.0
		DashTrail.patch(parent, at, ground, author)
	return popped


## Ce lancer à cette part, tout entier nécrotique : l'éclat des rats.
static func necrotic(cast: SkillStats, part: float) -> SkillStats:
	var blow := cast.echoed(part)
	var kind := DamageType.Kind.NECROTIC
	blow.blend([kind] as Array[int])
	blow.nature = kind
	# Un rat éclaté n'en accroche pas d'autre.
	blow.rats = 0.0
	return blow
