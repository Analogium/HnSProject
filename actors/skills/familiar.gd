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
## Ce qu'il rejoue : ce qui se pose et s'oublie (`Skill.TRANSFORMABLE`), **sans ce qui part
## du corps** — ruées, coups d'arme, l'orage porté, le nid.
const ECHOED: Array[Skill.Shape] = [
	Skill.Shape.BOLT, Skill.Shape.BALL, Skill.Shape.COMET, Skill.Shape.ORB, Skill.Shape.METEOR,
	Skill.Shape.CHAIN, Skill.Shape.WEB, Skill.Shape.CLOUD, Skill.Shape.SNAKE, Skill.Shape.SPIKES,
	Skill.Shape.FISSURE, Skill.Shape.NOVA, Skill.Shape.RING, Skill.Shape.VORTEX,
	Skill.Shape.IMPLOSION, Skill.Shape.BEAM, Skill.Shape.HOLY_CROSS, Skill.Shape.PILLAR,
	Skill.Shape.DRIFT, Skill.Shape.GATE, Skill.Shape.CURSE, Skill.Shape.MARK, Skill.Shape.BREATH,
	Skill.Shape.CATALYSIS, Skill.Shape.TRIAD,
]


## Un sort à rejouer, quand, et dans quel rayon autour du point visé il cherche sa proie.
class Echo:
	var skill: Skill
	var salvo: Array[SkillStats] = []
	var aim: Vector2
	var left := ECHO_DELAY
	var seek := 0.0


## Ceux de son maître : ce qu'il rejoue frappe au nom du joueur (`StatusEffects.of()`).
var states: StatusEffects
var _player: Player
var _skill: Skill
var _age := 0.0
var _pending: Array[Echo] = []


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
func echo(skill: Skill, salvo: Array[SkillStats], aim: Vector2) -> void:
	if not salvo[0].shape in ECHOED:
		return
	var own := _player.resolve(_skill, _player.skill_points(_skill.id))
	for k in 1 + int(own.echoes):
		var e := Echo.new()
		e.skill = skill
		e.aim = aim
		e.left = ECHO_DELAY * float(k + 1)
		e.seek = own.seek_radius
		for cast in salvo:
			var copy := cast.echoed(echo_part(own))
			sing(copy, int(own.countersong))
			e.salvo.append(copy)
		_pending.append(e)


## La part des dégâts d'un écho : **le seul calcul**, que la fiche lit.
static func echo_part(own: SkillStats) -> float:
	return maxf(ECHO_PART + own.echo_power * 0.01, 0.0)


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
	# Le Ressassement mêle les retards : la file n'est plus dans l'ordre où ils tombent.
	var due: Array[Echo] = []
	for e in _pending:
		e.left -= delta
		if e.left <= 0.0:
			due.append(e)
	for e in due:
		_pending.erase(e)
		_player.echo(e.skill, e.salvo, self, _aim_of(e))
	queue_redraw()


## L'Œil du corbeau : l'ennemi le plus proche du point visé dans son rayon, ou le point.
func _aim_of(e: Echo) -> Vector2:
	if e.seek <= 0.0:
		return e.aim
	var prey := Targets.nearest(get_world_2d(), e.aim, e.seek)
	return prey.global_position if prey != null else e.aim


## Le corbeau (`EffectForge.crow()`), tourné comme sa maîtresse.
func _draw() -> void:
	var side: Array = EffectForge.crow()[1 if _player.facing.x < 0.0 else 0]
	EffectForge.put_centered(self, side[int(_age * FLAP_HZ) % side.size()], Vector2.ZERO)
