class_name Familiar
extends Node3D

## Le Familier (jalon 41) : un corbeau à l'épaule de la sorcière, entretenu à la seconde,
## qui **rejoue** chaque sort élémentaire posé à `ECHO_PART` de ses dégâts, `ECHO_DELAY` plus tard,
## depuis sa place et vers le point visé au lancer (`Player.echo()`). Ses lignes de buff
## sont versées par le joueur, comme celles d'un buff : ce nœud porte le prix.

## La part des dégâts d'un écho, avant son arbre (`echo_part()`), et son retard — celui
## de chaque écho en plus du Ressassement s'y ajoute. Premier réglage.
const ECHO_PART := 0.4
const ECHO_DELAY := 0.4
## Sa place au sol, à côté de la sorcière : ses échos en partent. Le corbeau vole au-dessus
## (`CrowFx.HEIGHT`) ; plus près, ses ailes passaient sur elle.
const SHOULDER := Vector3(14.0, 0.0, 2.0)
## La Becquée (jalon 49) : l'aller du piqué — le retour prend autant —, et de combien il
## plonge vers la proie.
const DIVE_TIME := 0.18
const DIVE_ARC := 14.0
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
	var aim: Vector3
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
var crow: CrowFx


static func summon(player: Player, skill: Skill) -> Familiar:
	var f := Familiar.new()
	f._player = player
	f._skill = skill
	f.states = player.states
	f.position = SHOULDER
	player.add_child(f)
	Settings.veil(f, Settings.SPELLS)
	f.crow = CrowFx.perch(f)
	return f


## Un sort vient de partir : il le rejouera, s'il se pose — une fois, et une de plus par
## écho du Ressassement, chacune `ECHO_DELAY` après la précédente.
## Les Rémiges (jalon 49) avancent chaque écho ; sous le Canon, chacun avance d'un élément
## sur le précédent ; le Sombre augure le fait frapper plus fort par état élémentaire porté.
func echo(skill: Skill, salvo: Array[SkillStats], aim: Vector3) -> void:
	_last = salvo[0]
	# Élémentaire seulement (décision de l'utilisateur, jalon 54) : le Contre-chant tournait la foudre
	# ajoutée aux Chaînes du jugement en feu, et un sort sacré posait l'embrasé.
	if not salvo[0].shape in ECHOED or not salvo[0].nature in DamageType.ELEMENTS:
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


## Le Contre-chant (jalon 41) : le lancer avance d'autant de crans dans le tour feu → froid
## → foudre **d'après son élément**, et tous ses dégâts y passent, ajoutés compris, comme sous
## l'Incarnation (décision de l'utilisateur, jalon 54 : décalés nature par nature, la foudre
## ajoutée à un sort sacré passait au feu). La Triade, déjà aux trois, ne change que de nature.
static func sing(cast: SkillStats, steps: int) -> void:
	var at := DamageType.ELEMENTS.find(cast.nature)
	if steps <= 0 or at < 0:
		return
	cast.nature = DamageType.ELEMENTS[(at + steps) % DamageType.ELEMENTS.size()]
	if cast.shape != Skill.Shape.TRIAD:
		cast.blend([cast.nature] as Array[int])


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
	position = SHOULDER
	crow.face(_player.facing)
	_dive(delta)
	# Le Ressassement mêle les retards : la file n'est plus dans l'ordre où ils tombent.
	var due: Array[Echo] = []
	for e in _pending:
		e.left -= delta
		if e.left <= 0.0:
			due.append(e)
	for e in due:
		_pending.erase(e)
		crow.cry()
		if e.evil_eye:
			_curse(e)
		else:
			_player.echo(e.skill, e.salvo, self, _aim_of(e))
	_peck(delta)


## Le Mauvais œil (jalon 49) : l'écho ne frappe plus, il pose l'état de chacun de ses
## éléments, à sa force et sans tirage, autour du point visé. La Jettatura y ajoute l'état
## de l'élément suivant, plus faible.
func _curse(e: Echo) -> void:
	var own := _player.resolve(_skill, _player.skill_points(_skill.id))
	var cast := e.salvo[0]
	var parts := cast.roll(Game.rng)
	var radius := SkillStats.EVIL_EYE_RADIUS * (1.0 + own.croak * 0.01)
	var point := _aim_of(e)
	EvilEye.open(_player._effects_parent(), point, radius, cast.nature)
	for target in Targets.in_circle(get_world_3d(), point, radius):
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
	var prey := Targets.nearest(get_world_3d(), _player.global_position, SkillStats.PECK_REACH)
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
		_goal = _player.to_local(_prey.global_position)
	if before < DIVE_TIME and _dive_age >= DIVE_TIME and is_instance_valid(_prey):
		Targets.strike(_prey, _peck_hit.roll(Game.rng), _prey.global_position, states, _peck_hit)
	if _dive_age >= DIVE_TIME * 2.0:
		_dive_age = -1.0
		_prey = null
		return
	var t := _dive_age / DIVE_TIME
	if t > 1.0:
		t = 2.0 - t
	position = SHOULDER.lerp(_goal, t) - Vector3.UP * sin(t * PI) * DIVE_ARC
	crow.face(_goal - SHOULDER)


## L'Œil du corbeau : l'ennemi le plus proche du point visé dans son rayon, ou le point.
func _aim_of(e: Echo) -> Vector3:
	if e.seek <= 0.0:
		return e.aim
	var prey := Targets.nearest(get_world_3d(), e.aim, e.seek)
	return prey.global_position if prey != null else e.aim

