class_name Familiar
extends Node2D

## Le Familier (jalon 41) : un corbeau à l'épaule de la sorcière, entretenu à la seconde,
## qui **rejoue** chaque sort posé à `ECHO_PART` de ses dégâts, `ECHO_DELAY` plus tard,
## depuis sa place et vers le point visé au lancer (`Player.echo()`). Ses lignes de buff
## sont versées par le joueur, comme celles d'un buff : ce nœud porte le prix et le dessin.

## La part des dégâts d'un écho, avant son arbre (`echo_part()`), et son retard — celui
## de chaque écho en plus du Ressassement s'y ajoute. Premier réglage.
const ECHO_PART := 0.4
const ECHO_DELAY := 0.4
## Sa place, à droite du chapeau, sur le fond du sol : posé sur la sorcière, il se
## perdait dans le sombre de sa robe (capture du jalon 41). Et son vol sur place.
const SHOULDER := Vector2(15.0, -30.0)
const BOB := 1.5
## Battements d'ailes par seconde.
const FLAP_HZ := 6.0
## La Becquée (jalon 49) : l'aller du piqué — le retour prend autant —, la hauteur de son arc,
## où il vise sur la proie, et ce que dure l'éclat du bec.
const DIVE_TIME := 0.18
const DIVE_ARC := 14.0
const DIVE_AIM := Vector2(-4.0, -18.0)
const STRIKE_TIME := 0.08
## Ce qu'il rejoue : ce qui se pose et s'oublie (`Skill.TRANSFORMABLE`), **sans ce qui part
## du corps** — ruées, coups d'arme, l'orage porté, le nid.
const ECHOED: Array[Skill.Shape] = [
	Skill.Shape.BOLT, Skill.Shape.BALL, Skill.Shape.COMET, Skill.Shape.ORB, Skill.Shape.METEOR,
	Skill.Shape.CHAIN, Skill.Shape.WEB, Skill.Shape.CLOUD, Skill.Shape.SNAKE, Skill.Shape.SPIKES,
	Skill.Shape.FISSURE, Skill.Shape.NOVA, Skill.Shape.RING, Skill.Shape.VORTEX,
	Skill.Shape.IMPLOSION, Skill.Shape.PILLAR,
	Skill.Shape.DRIFT, Skill.Shape.GATE, Skill.Shape.CURSE, Skill.Shape.MARK, Skill.Shape.BREATH,
	Skill.Shape.GLYPH, Skill.Shape.TRIAD, Skill.Shape.FROST_ORB, Skill.Shape.HAMMER,
	Skill.Shape.CHAINS,
]


## Un sort à rejouer, quand, et dans quel rayon autour du point visé il cherche sa proie.
class Echo:
	var skill: Skill
	var salvo: Array[SkillStats] = []
	var aim: Vector2
	var left := ECHO_DELAY
	var seek := 0.0
	var evil_eye := false


## Ceux de son maître : ce qu'il rejoue frappe au nom du joueur (`StatusEffects.of()`).
var states: StatusEffects
var _player: Player
var _skill: Skill
var _age := 0.0
var _pending: Array[Echo] = []
## La Becquée (jalon 49) : le dernier sort lancé, dont elle frappe une part, et depuis quand
## elle n'a pas frappé.
var _last: SkillStats
var _since_peck := 0.0
## Le piqué en cours : sa proie, le coup qu'il porte, depuis quand il est parti (-1 : posé),
## et le dernier point visé, que le retour rejoint même si la proie est tombée.
var _prey: Hurtbox
var _peck_hit: SkillStats
var _dive_age := -1.0
var _goal := SHOULDER


static func summon(player: Player, skill: Skill) -> Familiar:
	var f := Familiar.new()
	f._player = player
	f._skill = skill
	f.states = player.states
	f.position = SHOULDER
	# Il vole : au-dessus du décor, qu'un rocher derrière la sorcière ne le couvre pas.
	f.z_index = 3
	player.add_child(f)
	Settings.veil(f, Settings.SPELLS)
	return f


## Un sort vient de partir : il le rejouera, s'il se pose — une fois, et une de plus par
## écho du Ressassement, chacune `ECHO_DELAY` après la précédente.
## Les Rémiges (jalon 49) avancent chaque écho ; sous le Canon, chacun avance d'un élément
## sur le précédent ; le Sombre augure le fait frapper plus fort par état élémentaire porté.
func echo(skill: Skill, salvo: Array[SkillStats], aim: Vector2) -> void:
	_last = salvo[0]
	if not salvo[0].shape in ECHOED:
		return
	var own := _player.resolve(_skill, _player.skill_points(_skill.id))
	var delay := maxf(ECHO_DELAY - own.remiges, SkillStats.REMIGES_FLOOR)
	for k in 1 + int(own.echoes):
		var e := Echo.new()
		e.skill = skill
		e.aim = aim
		e.left = delay * float(k + 1)
		e.seek = own.seek_radius
		e.evil_eye = own.evil_eye > 0.0
		for cast in salvo:
			var copy := cast.echoed(echo_part(own))
			sing(copy, int(own.countersong) + (k if own.canon > 0.0 else 0))
			for kind: int in StatusEffects.ELEMENTAL:
				copy.against_increased[kind] += own.dark_omen
			e.salvo.append(copy)
		_pending.append(e)


## La part des dégâts d'un écho : **le seul calcul**, que la fiche lit.
static func echo_part(own: SkillStats) -> float:
	return maxf(ECHO_PART + (own.echo_power + own.canon) * 0.01, 0.0)


## Le Contre-chant (jalon 41) : chaque élément du lancer avance d'autant de crans dans le
## tour feu → froid → foudre, sa nature avec. Les autres natures restent.
static func sing(cast: SkillStats, steps: int) -> void:
	if steps <= 0:
		return
	var low := cast.damage_min.duplicate()
	var top := cast.damage_max.duplicate()
	var order := DamageType.ELEMENTS
	for i in order.size():
		var to := order[(i + steps) % order.size()]
		cast.damage_min[to] = low[order[i]]
		cast.damage_max[to] = top[order[i]]
	var at := order.find(cast.nature)
	if at >= 0:
		cast.nature = order[(at + steps) % order.size()]


## Appelée par `Player.extinguish()`, le seul chemin : ce qu'il n'a pas encore rejoué se perd.
func extinguish() -> void:
	set_physics_process(false)
	queue_free()


func _physics_process(delta: float) -> void:
	_age += delta
	var points := _player.skill_points(_skill.id)
	if points <= 0 or _player.is_dead:
		_player.extinguish(_skill.id)
		return
	if not _player.drain(_player.resolve(_skill, points).mana_per_second, delta):
		_player.extinguish(_skill.id)
		return
	position = SHOULDER + Vector2(0.0, sin(_age * 4.0) * BOB)
	_dive(delta)
	# Le Ressassement mêle les retards : la file n'est plus dans l'ordre où ils tombent.
	var due: Array[Echo] = []
	for e in _pending:
		e.left -= delta
		if e.left <= 0.0:
			due.append(e)
	for e in due:
		_pending.erase(e)
		if e.evil_eye:
			_curse(e)
		else:
			_player.echo(e.skill, e.salvo, self, _aim_of(e))
	_peck(delta)
	queue_redraw()


## Le Mauvais œil (jalon 49) : l'écho ne frappe plus, il pose l'état de chacun de ses
## éléments, à sa force et sans tirage, autour du point visé. La Jettatura y ajoute l'état
## de l'élément suivant, plus faible.
func _curse(e: Echo) -> void:
	var own := _player.resolve(_skill, _player.skill_points(_skill.id))
	var cast := e.salvo[0]
	var parts := cast.roll(Game.rng)
	var radius := SkillStats.EVIL_EYE_RADIUS * (1.0 + own.croak * 0.01)
	var point := _aim_of(e)
	EvilEye.open(_player._effects_parent(), point, radius, DamageType.COLORS[cast.nature])
	for target in Targets.in_circle(get_world_2d(), point, radius):
		if target.states == null:
			continue
		for kind: int in StatusEffects.ELEMENTAL:
			var part: float = parts[StatusEffects.NATURES[kind]]
			if part > 0.0:
				_mark(target.states, kind, part, cast.strength_of(kind), cast.skill_id)
				if own.jettatura > 0.0:
					var at := StatusEffects.ELEMENTAL.find(kind)
					var next: int = StatusEffects.ELEMENTAL[(at + 1) % StatusEffects.ELEMENTAL.size()]
					_mark(target.states, next, part, SkillStats.JETTATURA_STRENGTH, cast.skill_id)


func _mark(on: StatusEffects, kind: int, part: float, strength: float, source: String) -> void:
	if StatusEffects.burn_per_second(kind) > 0.0:
		on.put(kind, part * strength, states, source)
	else:
		on.put(kind, part, states, source, strength)


## La Becquée (jalon 49) : à chaque période, il fond sur l'ennemi le plus proche de sa
## maîtresse, d'une part du dernier sort lancé, qui pose son état à coup sûr.
func _peck(delta: float) -> void:
	if _last == null:
		return
	_since_peck += delta
	if _since_peck < SkillStats.PECK_PERIOD or _dive_age >= 0.0:
		return
	_since_peck = 0.0
	var own := _player.resolve(_skill, _player.skill_points(_skill.id))
	if own.peck <= 0.0:
		return
	var prey := Targets.nearest(get_world_2d(), _player.global_position, SkillStats.PECK_REACH)
	if prey == null:
		return
	_peck_hit = _last.echoed(own.peck * 0.01)
	_peck_hit.status_chance_increase += SkillStats.SURE_STATE
	_prey = prey
	_dive_age = 0.0


## Le piqué : il fond en arc de l'épaule sur la proie, frappe en arrivant, puis revient.
func _dive(delta: float) -> void:
	if _dive_age < 0.0:
		return
	var before := _dive_age
	_dive_age += delta
	if is_instance_valid(_prey):
		_goal = _player.to_local(_prey.global_position) + DIVE_AIM
	if before < DIVE_TIME and _dive_age >= DIVE_TIME and is_instance_valid(_prey):
		Targets.strike(_prey, _peck_hit.roll(Game.rng), _prey.global_position, states, _peck_hit)
	if _dive_age >= DIVE_TIME * 2.0:
		_dive_age = -1.0
		_prey = null
		return
	var t := _dive_age / DIVE_TIME
	if t > 1.0:
		t = 2.0 - t
	position = SHOULDER.lerp(_goal, t) - Vector2(0.0, sin(t * PI) * DIVE_ARC)


## L'Œil du corbeau : l'ennemi le plus proche du point visé dans son rayon, ou le point.
func _aim_of(e: Echo) -> Vector2:
	if e.seek <= 0.0:
		return e.aim
	var prey := Targets.nearest(get_world_2d(), e.aim, e.seek)
	return prey.global_position if prey != null else e.aim


## Le corbeau (`EffectForge.crow()`), tourné comme sa maîtresse ; à l'aller d'un piqué, ailes
## repliées vers sa proie (`crow_dive()`), et l'éclat du bec à l'arrivée.
func _draw() -> void:
	if _dive_age >= 0.0 and _dive_age < DIVE_TIME:
		var toward := 1 if _goal.x < SHOULDER.x else 0
		EffectForge.put_centered(self, EffectForge.crow_dive()[toward], Vector2.ZERO)
		return
	var side: Array = EffectForge.crow()[1 if _player.facing.x < 0.0 else 0]
	EffectForge.put_centered(self, side[int(_age * FLAP_HZ) % side.size()], Vector2.ZERO)
	if _dive_age >= DIVE_TIME and _dive_age < DIVE_TIME + STRIKE_TIME and _peck_hit != null:
		EffectForge.put_centered(
			self, EffectForge.strike(DamageType.COLORS[_peck_hit.nature]), _goal - position + Vector2(3.0, 2.0)
		)
