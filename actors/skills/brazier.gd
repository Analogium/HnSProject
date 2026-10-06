class_name Brazier
extends Node2D

## Le Brasero (jalon 42) : planté au point visé, il crache une boule vers l'ennemi le plus
## proche à chaque période, `simultaneous` à la fois par joueur — le plus ancien s'éteint.
## Sous le Phare, il a des PV et les ennemis s'en prennent à lui (`Enemy.foe()`), comme la
## Poupée de chiffon ; sous le Foyer du mage, il tire la Boule de feu du joueur.

const HURT_RADIUS := 7.0
## Le haut de la coupe, d'où partent les boules et où se posent les langues.
const MOUTH := Vector2(0.0, -9.0)
## La Triangulation : son trait ne s'éteint que par ses braseros (`_exit_tree()`) — une
## durée finie, que le compte des impulsions puisse lire.
const LINK_HOLD := 3600.0

## Tous ceux qui brûlent, et ceux qui servent d'appât sous le Phare.
static var lit: Array[Brazier] = []
static var beacons: Array[Brazier] = []

## Pour `StatusEffects.of()` : ses boules frappent au nom du joueur.
var states: StatusEffects
## Sous le Phare seulement : lue par les ennemis qui le frappent au contact.
var hurtbox: Hurtbox
var health := 1.0
var max_health := 1.0
var _player: Player
var _cast: SkillStats
## Sous le Foyer du mage : la Boule de feu du joueur, résolue sans sa transformation.
var _ball: SkillStats
var _age := 0.0
var _life_bonus := 0.0
var _since_shot := 0.0
## Le Brasier ravivé : un tir dû tout de suite, et l'attente avant le suivant.
var _quick := false
var _quick_wait := 0.0
var _out := false
var _bar: HealthBar
## Les traits de la Triangulation qui partent de lui ou y arrivent.
var _links: Array[DashTrail] = []


static func place(player: Player, point: Vector2, cast: SkillStats, parent: Node) -> Brazier:
	var own := lit.filter(func(b: Brazier) -> bool: return b._player == player and not b._out)
	for i in maxi(own.size() - cast.max_simultaneous() + 1, 0):
		(own[i] as Brazier)._go_out(false)
	var b := Brazier.new()
	b._player = player
	b._cast = cast
	b.states = player.states
	if cast.hearth > 0.0:
		var points := player.skill_points(SkillStats.HEARTH_SKILL)
		if points > 0:
			b._ball = player.resolve(SkillCatalog.by_id(SkillStats.HEARTH_SKILL), points, true)
			# La Salve et la Mitraille restent à lui : des boules en plus, un rebond.
			var extra := cast.projectile_count() - 1
			b._ball.projectiles += float(extra)
			b._ball.spread_in_degrees = maxf(
				b._ball.spread_in_degrees, SkillStats.MIN_SPREAD * (b._ball.projectiles - 1.0)
			)
			b._ball.bounces += cast.bounces
	if cast.rekindle > 0.0 or cast.quickfire > 0.0:
		player.states.slew.connect(b._on_slew)
	parent.add_child(b)
	Settings.veil(b, Settings.SPELLS)
	b.global_position = point
	# La Triangulation : un trait de feu jusqu'au plus jeune des autres, éteint avec le
	# premier des deux à partir.
	var others := own.filter(func(o: Brazier) -> bool: return not o._out)
	if cast.triangulation > 0.0 and not others.is_empty():
		var other: Brazier = others.back()
		var link := cast.echoed(1.0)
		link.duration = LINK_HOLD
		link.radius = SkillStats.LINK_RADIUS
		var trail := DashTrail.leave(parent, other.global_position, point, link, player.states)
		b._links.append(trail)
		other._links.append(trail)
	return b


## La Main d'appoint : chaque brasero de ce joueur qui la porte tire avec lui vers sa visée.
static func assist(player: Player, aim: Vector2) -> void:
	for b in lit:
		if b._player == player and not b._out and b._cast.helping_hand > 0.0 and b._ball != null:
			b._shoot(aim)


func lifetime() -> float:
	return _cast.duration + _life_bonus


func _enter_tree() -> void:
	lit.append(self)


func _exit_tree() -> void:
	lit.erase(self)
	beacons.erase(self)
	for trail in _links:
		if is_instance_valid(trail):
			trail.queue_free()


func _ready() -> void:
	if _cast.beacon <= 0.0:
		return
	beacons.append(self)
	max_health = maxf(_player.stats.max_health * SkillStats.BEACON_LIFE, 1.0)
	health = max_health
	hurtbox = Hurtbox.new()
	hurtbox.collision_layer = Targets.PLAYER_SIDE
	hurtbox.collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = HURT_RADIUS
	shape.shape = circle
	hurtbox.add_child(shape)
	add_child(hurtbox)
	hurtbox.damaged.connect(_on_damaged)
	_bar = HealthBar.new()
	add_child(_bar)
	_bar.set_health(health, max_health)


## Un livre rangé ou un joueur tombé l'éteignent, sans dernières braises.
func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player) or _player.is_dead \
			or _player.skill_points(_cast.skill_id) <= 0:
		_go_out(false)
		return
	_age += delta
	_since_shot += delta
	_quick_wait = maxf(_quick_wait - delta, 0.0)
	if _age >= lifetime():
		_go_out(true)
		return
	if _since_shot >= _cast.period or _quick:
		var reach := SkillStats.TURRET_SIGHT + _cast.sight
		var prey := Targets.nearest(get_world_2d(), global_position, reach)
		if prey != null and _shoot(prey.global_position):
			_since_shot = 0.0
			_quick = false
	queue_redraw()


## Ses boules, ou la Boule de feu du joueur sous le Foyer du mage — posée par le chemin
## du joueur, depuis la coupe, comme le Familier rejoue un sort de son épaule. Faux quand
## rien n'est parti.
func _shoot(at: Vector2) -> bool:
	var from := global_position + MOUTH
	var toward := from.direction_to(at)
	if _ball != null:
		# Le prix du Foyer : chaque tir paie la Boule de feu ; à court de mana, rien.
		if not _player.spend_mana(_ball.mana_cost):
			return false
		var skill := SkillCatalog.by_id(SkillStats.HEARTH_SKILL)
		_player._pose(skill, [_ball] as Array[SkillStats], self, toward, at)
		return true
	# Ses propres boules n'explosent pas : la touche directe seule.
	for direction in _player._spread(_cast, toward):
		Fireball.spark(_player._effects_parent(), from, direction, _cast, states, false)
	return true


## Un tué de ses boules : le Feu sacré lui rend du temps, le Brasier ravivé le fait tirer
## aussitôt. **Depuis un rappel de collision** : le tir attend le pas suivant.
func _on_slew(cast: SkillStats, _at: Vector2, _victim: StatusEffects) -> void:
	if _out or (cast != _cast and cast != _ball):
		return
	_life_bonus += _cast.rekindle
	if _cast.quickfire > 0.0 and _quick_wait <= 0.0:
		_quick = true
		_quick_wait = 1.0 / _cast.quickfire


func _on_damaged(info: DamageInfo) -> void:
	if _out:
		return
	health -= info.amount
	_bar.set_health(health, max_health)
	if health <= 0.0:
		# Depuis un rappel de collision : les dernières braises crachent des boules.
		_go_out.call_deferred(true)


## Éteint, avec ses Dernières braises s'il s'éteint de lui-même ou tombe : une couronne de
## boules, chacune à cette part d'un tir.
func _go_out(spent: bool) -> void:
	if _out:
		return
	_out = true
	if spent and _cast.last_breath > 0.0:
		var crown := _cast.echoed(_cast.last_breath * 0.01)
		for i in SkillStats.LAST_BREATH_BALLS:
			var toward := Vector2.from_angle(TAU * float(i) / float(SkillStats.LAST_BREATH_BALLS))
			Fireball.spark(
				_player._effects_parent(), global_position + MOUTH, toward, crown, states, false
			)
	queue_free()


## Le trépied (`EffectForge.brazier()`), les pieds sur sa place ; trois langues dans la coupe,
## la grande au milieu, chacune à son temps.
func _draw() -> void:
	var tint: Color = DamageType.COLORS[_cast.nature]
	var tex := EffectForge.brazier(tint)
	EffectForge.put_centered(self, tex, Vector2(0.0, -tex.get_height() * 0.5 + 1.0))
	var big := EffectForge.flames(tint)
	var small := EffectForge.small_flames(tint)
	var frame := int(_age * EffectForge.FLAME_HZ)
	for i in 2:
		_put_foot(small[(frame + i * 2 + 1) % small.size()], MOUTH + Vector2(8.0 * i - 4.0, 1.0))
	_put_foot(big[frame % big.size()], MOUTH)


func _put_foot(tex: Texture2D, foot: Vector2) -> void:
	var size := Vector2(tex.get_width(), tex.get_height())
	draw_texture_rect(tex, Rect2(EffectForge.snap(self, foot - Vector2(size.x * 0.5, size.y)), size), false)
