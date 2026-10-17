class_name JudgmentChains
extends Node3D

## Les Chaînes du jugement (jalon 48) : un trait de fer béni vole vers le point visé, et le
## premier ennemi touché est enchaîné à ses plus proches voisins. Tant que les chaînes
## tiennent, une part de chaque coup que prend un enchaîné frappe tous les autres, en sacré.
## Sous le Bouc émissaire, elles partent du lanceur, et c'est la part des coups **qu'il**
## prend qui passe à eux.
##
## Un ennemi ne porte qu'un faisceau : des chaînes neuves le prennent aux anciennes.

## La largeur du trait qui vole.
const WIDTH := 6.0

## Qui porte quel faisceau, par identifiant de hurtbox : la Passation saute ces ennemis-là.
static var _holding := {}
## Les faisceaux du Bouc émissaire, que lit le joueur quand il est frappé.
static var _scapegoats: Array[JudgmentChains] = []

var _cast: SkillStats
var _author: StatusEffects
var _tint := Color.WHITE
## Le lancer des coups partagés : reconnu, un coup ne se repartage pas.
var _shared: SkillStats
var _heading := Vector3.ZERO
var _flown := 0.0
var _flying := false
## Ce vers quoi tirent les chaînes : le premier touché, ou le joueur du Bouc émissaire.
var _anchor: Node3D
var _player: Player
var _members: Array[Hurtbox] = []
## Les rappels liés de chaque enchaîné, par identifiant : se délier demande les mêmes.
var _hooks := {}
var _age := 0.0
var _handovers := 0
## Le Carcan : ceux qu'il a déjà assommés.
var _shackled := {}


static func throw(
	parent: Node, at: Vector3, toward: Vector3, cast: SkillStats, author: StatusEffects
) -> JudgmentChains:
	var chains := _made(parent, at, cast, author)
	chains._heading = toward.normalized() if toward != Vector3.ZERO else Vector3.RIGHT
	chains._flying = true
	return chains


## Le Bouc émissaire : lié à soi, il remplace celui d'avant. Différé, comme tout ce qui
## interroge l'espace : le lancer peut venir d'un rappel de collision (invariant 4).
static func bind(
	parent: Node, player: Player, cast: SkillStats, author: StatusEffects
) -> JudgmentChains:
	for old in _scapegoats.duplicate():
		if is_instance_valid(old) and old._player == player:
			old._end()
	var chains := _made(parent, player.global_position, cast, author)
	chains._player = player
	chains._anchor = player
	_scapegoats.append(chains)
	chains._close_around.call_deferred(player.global_position)
	return chains


static func _made(
	parent: Node, at: Vector3, cast: SkillStats, author: StatusEffects
) -> JudgmentChains:
	var chains := JudgmentChains.new()
	chains._cast = cast
	chains._author = author
	chains._tint = DamageType.COLORS[cast.nature]
	chains._shared = SkillStats.new()
	chains._shared.skill_id = cast.skill_id
	chains._shared.nature = DamageType.Kind.HOLY
	chains._shared.status_chance_increase = cast.status_chance_increase
	parent.add_child(chains)
	Settings.veil(chains, Settings.SPELLS)
	chains.global_position = at
	return chains


## Ce que le joueur frappé garde de `lost` : sous le Bouc émissaire, la part partagée passe
## à ses enchaînés, et chaque coup détourné le soigne (les Stigmates).
static func divert(player: Player, lost: float) -> float:
	for chains in _scapegoats:
		if is_instance_valid(chains) and chains._player == player and not chains._members.is_empty():
			chains._share.call_deferred(null, lost * chains._part())
			if chains._cast.stigmata > 0.0:
				player.heal.call_deferred(player.stats.max_health * chains._cast.stigmata * 0.01)
			return lost * (1.0 - chains._part())
	return lost


func _physics_process(delta: float) -> void:
	if _flying:
		_fly(delta)
		return
	_age += delta
	if _age >= _cast.duration or not is_instance_valid(_anchor) \
			or (_player != null and _player.is_dead):
		_end()
		return
	global_position = _anchor.global_position
	if _purge():
		_settle()
	for member in _members.duplicate():
		if is_queued_for_deletion():
			return
		if member != _anchor and _snapped(member):
			_release(member)
		else:
			_drag(member, delta)


## Le trait avance ; le premier ennemi sur son pas le prend. Au bout de sa portée, il se perd.
func _fly(delta: float) -> void:
	var step := SkillStats.CHAINS_SPEED * delta
	var next := global_position + _heading * step
	var first: Hurtbox = null
	for target in Targets.in_capsule(get_world_3d(), global_position, next, WIDTH):
		if first == null or global_position.distance_squared_to(target.global_position) \
				< global_position.distance_squared_to(first.global_position):
			first = target
	if first != null:
		_flying = false
		_anchor = first
		global_position = first.global_position
		_close_around(first.global_position, first)
		return
	global_position = next
	_flown += step
	if _flown >= SkillStats.CHAINS_RANGE:
		queue_free()


## Frappe les plus proches de `at`, le premier touché en tête, d'un seul tirage (invariant 3),
## et enchaîne ceux qui sont des ennemis — le mannequin, frappé, ne meurt pas. Sous le Bouc
## émissaire, deux rayons : les chaînes partent de soi.
func _close_around(at: Vector3, first: Hurtbox = null) -> void:
	var count := int(_cast.links)
	var reach := _cast.radius * (SkillStats.CHAINS_SNAP if _player != null else 1.0)
	var near := Targets.in_circle(get_world_3d(), at, reach)
	near.erase(first)
	near.sort_custom(func(a: Hurtbox, b: Hurtbox) -> bool:
		return at.distance_squared_to(a.global_position) < at.distance_squared_to(b.global_position)
	)
	var caught: Array[Hurtbox] = []
	if first != null:
		caught.append(first)
	caught.assign(caught + near.slice(0, count))
	var parts := _cast.roll(Game.rng)
	for member in caught:
		Targets.strike(member, parts, at, _author, _cast)
	for member in caught:
		if is_instance_valid(member):
			_take(member)
	_settle()


## Un mort n'est pas pris : son signal de mort est passé, rien ne le délierait — la Passation
## trouvait parfois un voisin tué dans la même image, libéré ensuite sous ses chaînes.
func _take(member: Hurtbox) -> void:
	var enemy := member.get_parent() as Enemy
	if enemy == null or enemy.is_dead:
		return
	var id := member.get_instance_id()
	var other: Variant = _holding.get(id)
	if is_instance_valid(other) and other != self:
		(other as JudgmentChains)._release(member)
	_holding[id] = self
	_members.append(member)
	_hooks[id] = [_on_damaged.bind(member), _on_died.bind(member)]
	member.damaged.connect(_hooks[id][0])
	enemy.died.connect(_hooks[id][1])


## `settle` : le faisceau trop maigre se dénoue — sauf quand la Passation va le regarnir.
func _release(member: Hurtbox, settle := true) -> void:
	var id := member.get_instance_id()
	_members.erase(member)
	if _holding.get(id) == self:
		_holding.erase(id)
	var hooks: Array = _hooks.get(id, [])
	_hooks.erase(id)
	if is_instance_valid(member) and not hooks.is_empty():
		member.damaged.disconnect(hooks[0])
		(member.get_parent() as Enemy).died.disconnect(hooks[1])
	if member == _anchor and _player == null:
		_anchor = _members[0] if not _members.is_empty() else null
	if settle:
		_settle()


## Une chaîne seule ne partage rien ; le Bouc émissaire, lui, a toujours son lanceur.
func _settle() -> void:
	if _members.size() < (1 if _player != null else 2):
		_end()


## Oublie les corps libérés sans que leur mort ne soit passée par ici ; vrai s'il y en avait.
func _purge() -> bool:
	var alive := _members.filter(func(m: Variant) -> bool: return is_instance_valid(m))
	if alive.size() == _members.size():
		return false
	_members.assign(alive)
	return true


func _end() -> void:
	_purge()
	for member in _members.duplicate():
		_release(member, false)
	for id in _holding.keys():
		if _holding[id] == self:
			_holding.erase(id)
	_scapegoats.erase(self)
	set_physics_process(false)
	queue_free()


func _part() -> float:
	return _cast.solidarity * 0.01


## Le coup arrive de `Hurtbox.take_damage()`, parfois d'un rappel de collision : le partage
## attend la fin de l'image (invariant 4).
func _on_damaged(info: DamageInfo, member: Hurtbox) -> void:
	if info.cast != _shared and info.amount > 0.0:
		_share.call_deferred(member, info.amount * _part())


## Frappe tous les enchaînés sauf `from` — null : le coup détourné du Bouc émissaire. Sous
## l'Unisson, les états que porte `from` passent avec.
func _share(from: Hurtbox, amount: float) -> void:
	var parts := DamageType.empty_parts()
	parts[DamageType.Kind.HOLY] = amount
	var at := from.global_position if is_instance_valid(from) else global_position
	for member in _members.duplicate():
		if member == from or not is_instance_valid(member):
			continue
		Targets.strike(member, parts, at, _author, _shared)
		if _cast.unison > 0.0 and is_instance_valid(from) and member.states != null:
			for kind in from.states.kinds():
				from.states.pass_on(kind, member.states)


## Mort, il quitte le faisceau ; la Rupture le fait éclater, la Passation donne ses chaînes
## à l'ennemi libre le plus proche. Différé : on est dans le coup qui tue.
func _on_died(_enemy: Enemy, member: Hurtbox) -> void:
	var at := member.global_position
	var handing := _handovers < int(_cast.handover)
	_release(member, not handing)
	if _cast.rupture > 0.0:
		var burst := _cast
		if _cast.absoute > 0.0:
			burst = _cast.echoed(1.0)
			burst.status_chance_increase += SkillStats.SURE_STATE
		Explosion.put.call_deferred(
			get_parent(), at, DamageType.scaled(_cast.roll(Game.rng), _cast.rupture * 0.01),
			SkillStats.RUPTURE_RADIUS, null, _tint, _author, burst
		)
	if handing:
		_handovers += 1
		_hand_over.call_deferred(at, member.get_instance_id())


## `dead` : le mort, encore dans l'espace physique le temps de cette image.
func _hand_over(at: Vector3, dead: int) -> void:
	if is_queued_for_deletion():
		return
	var skipped := _holding.duplicate()
	skipped[dead] = true
	var heir := Targets.nearest(get_world_3d(), at, _cast.radius, skipped)
	if heir != null:
		_take(heir)
		if _anchor == null and heir in _members:
			_anchor = heir
	_settle()


## Tiré trop loin du premier touché, le lien rompt.
func _snapped(member: Hurtbox) -> bool:
	var reach := _cast.radius * SkillStats.CHAINS_SNAP
	return member.global_position.distance_squared_to(_anchor.global_position) > reach * reach


## Le Resserrement tire vers le premier touché et le Carcan assomme qui y arrive ; le Pilori
## tire vers le Pilier sacré le plus proche.
func _drag(member: Hurtbox, delta: float) -> void:
	var enemy := member.get_parent() as Enemy
	if member != _anchor and _cast.constriction > 0.0:
		var gap := member.global_position.distance_to(_anchor.global_position)
		if gap > SkillStats.SHACKLE_CONTACT:
			enemy.tug(member.global_position.direction_to(_anchor.global_position) \
					* minf(_cast.constriction * delta, gap - SkillStats.SHACKLE_CONTACT))
		elif _cast.shackle > 0.0 and not _shackled.has(member.get_instance_id()):
			_shackled[member.get_instance_id()] = true
			enemy.stun(SkillStats.SHACKLE_TIME)
	if _cast.pillory > 0.0:
		var pillar := _nearest_pillar(member.global_position)
		if pillar != null:
			var gap := member.global_position.distance_to(pillar.global_position)
			if gap > SkillStats.SHACKLE_CONTACT:
				enemy.tug(member.global_position.direction_to(pillar.global_position) \
						* minf(_cast.pillory * delta, gap - SkillStats.SHACKLE_CONTACT))


func _nearest_pillar(at: Vector3) -> SacredPillar:
	var best: SacredPillar = null
	for pillar in SacredPillar.standing_for(_author):
		if best == null or at.distance_squared_to(pillar.global_position) \
				< at.distance_squared_to(best.global_position):
			best = pillar
	return best

