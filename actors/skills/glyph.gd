class_name Glyph
extends Node3D

## Les Glyphes (jalon 49, à la place de la Catalyse) : un piège tracé au point visé, dans
## l'élément du tour. Armé après `arming`, il éclate sur le premier ennemi qui entre dans son
## cercle de déclenchement, frappe son cercle et y pose son état à coup sûr. Trois au plus
## par lanceur, le corbeau à part ; trois armés des trois éléments se relient, et le
## triangle frappe ce qui s'y tient. Sous le Sceau, un seul grand glyphe qui n'éclate qu'à
## la relance ou à sa fin, de tous les éléments versés.

## Tous ceux qui sont tracés : le lanceur compte les siens, le joueur verse ses sorts au Sceau.
static var traced: Array[Glyph] = []

## L'éclat, en deux temps.
const SHATTER_TIME := 0.2

## Pour `StatusEffects.of()` : ses coups frappent au nom du joueur.
var states: StatusEffects
var element := -1
var armed := false
var sealed := false
var _owner: Node3D
var _player: Player
var _cast: SkillStats
var _age := 0.0
var _since_link := 0.0
var _since_lure := 0.0
## Là où partent ses coups et ses réactions : le glyphe, lui, est posé sur le calque du sol.
var _effects: Node
## Depuis combien il éclate, -1 avant.
var _shatter_age := -1.0
## Déjà réécrit : la Réécriture ne vaut qu'une fois par glyphe.
var _rewritten := false
## Les éléments versés au Sceau, le sien compris.
var _poured := {}
var _out := false


## `owner` : le joueur, ou le corbeau qui rejoue — chacun sa limite.
static func place(
	player: Player, owner: Node3D, point: Vector3, cast: SkillStats, parent: Node,
	as_seal := cast.seal > 0.0, rewritten := false
) -> Glyph:
	var own := traced.filter(func(g: Glyph) -> bool: return g._owner == owner and not g._out)
	# Un seul Sceau : le relancer fait éclater l'ancien. Les glyphes ordinaires ne comptent pas
	# contre lui — le Contresceau en laisse trois.
	var leaving := own.filter(func(g: Glyph) -> bool: return g.sealed) if as_seal \
			else cast.crowded(own.filter(func(g: Glyph) -> bool: return not g.sealed))
	for old: Glyph in leaving:
		old._go(old.sealed)
	var g := Glyph.new()
	g._player = player
	g._owner = owner
	g._cast = cast
	g.states = player.states
	g.element = cast.nature
	g.sealed = as_seal
	g._rewritten = rewritten
	g._poured[cast.nature] = true
	g._effects = parent
	# Sous les corps, comme le Mauvais œil : debout, il passerait sur ceux qu'il piège.
	DashTrail.layer(parent).add_child(g)
	Settings.veil(g, Settings.SPELLS)
	g.global_position = point
	ElementFx.area(g, DamageType.COLORS[cast.nature], cast.radius)
	return g


## Un sort de ce joueur vient de partir : ses Sceaux en prennent l'élément.
static func pour_all(player: Player, nature: int) -> void:
	if not nature in DamageType.ELEMENTS:
		return
	for g in traced:
		if g._player == player and g.sealed and not g._out:
			g._poured[nature] = true


func _enter_tree() -> void:
	traced.append(self)


func _exit_tree() -> void:
	traced.erase(self)


## Le cercle qui frappe ; plus large sous le Sceau.
func reach() -> float:
	return _cast.radius * (SkillStats.SEAL_REACH if sealed else 1.0)


## Un livre rangé ou un joueur tombé l'effacent sans éclat ; le Sceau éclate à sa fin.
func _physics_process(delta: float) -> void:
	if _shatter_age >= 0.0:
		_shatter_age += delta
		if _shatter_age >= SHATTER_TIME:
			queue_free()
		return
	if not is_instance_valid(_player) or _player.is_dead \
			or _player.skill_points(_cast.skill_id) <= 0:
		_go(false)
		return
	_age += delta
	if _age >= _cast.duration:
		_go(sealed)
		return
	if not armed:
		armed = _age >= _cast.arming
		return
	if not sealed and not Targets.in_circle(get_world_3d(), global_position, _cast.trigger).is_empty():
		_burst()
		return
	if _cast.lure > 0.0 and not sealed:
		_since_lure += delta
		if _since_lure >= SkillStats.LURE_PERIOD:
			_since_lure -= SkillStats.LURE_PERIOD
			_tug()
	_since_link += delta
	if _since_link >= SkillStats.TRIANGLE_PERIOD:
		_since_link -= SkillStats.TRIANGLE_PERIOD
		_link()


## L'éclat : son cercle frappé, son état posé à coup sûr. Sous le Palimpseste, chaque ennemi
## qui portait l'état d'un autre élément réagit d'abord — les états sont lus avant le coup.
func _burst() -> void:
	var world := get_world_3d()
	var reacted := false
	if _cast.palimpsest > 0.0:
		var own_kind := StatusEffects.rolled_by(element)
		for target in Targets.in_circle(world, global_position, reach()):
			var held := Reactions.held_by(target.states)
			var reacting := held.duplicate()
			if not own_kind in reacting:
				reacting.append(own_kind)
			if reacting.size() >= 2 and Reactions.react(
				_effects, target, held, reacting, _cast, states, _cast.palimpsest * 0.01
			):
				reacted = true
	var hit := _cast.echoed(1.0)
	hit.status_chance_increase += SkillStats.SURE_STATE
	Targets.strike_circle(world, global_position, reach(), hit, states)
	_go(true)
	# La Réécriture : le piège se retrace aussitôt, dans l'élément suivant. Après son départ,
	# pour ne pas compter contre la limite.
	if reacted and _cast.rewrite > 0.0 and not _rewritten:
		var next := _cast.echoed(1.0)
		Familiar.sing(next, 1)
		Glyph.place(_player, _owner, global_position, next, _effects, false, true)


## Les glyphes armés de son lanceur, hors Sceau, du plus ancien au plus jeune. Le plus ancien
## mène : il frappe le triangle et les fils pour tous, une fois par période.
func _kin() -> Array[Glyph]:
	var out: Array[Glyph] = []
	for g in traced:
		if g._owner == _owner and g.armed and not g.sealed and not g._out:
			out.append(g)
	return out


func _link() -> void:
	var kin := _kin()
	if kin.is_empty() or kin[0] != self:
		return
	if kin.size() == DamageType.ELEMENTS.size() and _all_elements(kin):
		_triangle(kin)
	if _cast.entwine > 0.0 and kin.size() >= 2:
		for i in kin.size():
			for j in range(i + 1, kin.size()):
				_thread(kin[i], kin[j])


static func _all_elements(kin: Array[Glyph]) -> bool:
	var seen := {}
	for g in kin:
		seen[g.element] = true
	return seen.size() == DamageType.ELEMENTS.size()


## Le triangle : ce qui se tient entre les trois, un tiers de chaque élément. Un tirage pour
## toute la surface (invariant 3).
func _triangle(kin: Array[Glyph]) -> void:
	var corners := PackedVector2Array()
	var middle := Vector3.ZERO
	for g in kin:
		corners.append(Flat.xz(g.global_position))
		middle += g.global_position / float(kin.size())
	var span := 0.0
	for g in kin:
		span = maxf(span, middle.distance_to(g.global_position))
	var strike := _cast.echoed(SkillStats.TRIANGLE_PART)
	strike.blend(DamageType.ELEMENTS)
	var parts := strike.roll(Game.rng)
	for target in Targets.in_circle(get_world_3d(), middle, span):
		if Geometry2D.is_point_in_polygon(Flat.xz(target.global_position), corners):
			Targets.strike(target, parts, middle, states, strike)


## Un fil de l'Entrelacs : ce qui le traverse, dans les éléments de ses deux bouts. La Trame y
## pose leurs états à coup sûr.
func _thread(a: Glyph, b: Glyph) -> void:
	var strike := _cast.echoed(_cast.entwine * 0.01)
	var natures: Array[int] = [a.element]
	if b.element != a.element:
		natures.append(b.element)
	strike.blend(natures)
	if _cast.weft > 0.0:
		strike.status_chance_increase += SkillStats.SURE_STATE
	var parts := strike.roll(Game.rng)
	for target in Targets.in_capsule(get_world_3d(), a.global_position, b.global_position, SkillStats.THREAD_WIDTH):
		Targets.strike(target, parts, a.global_position, states, strike)


## Le Leurre : les ennemis à sa portée sont tirés vers lui, par à-coups.
func _tug() -> void:
	for target in Targets.in_circle(get_world_3d(), global_position, _cast.lure):
		var body := target.get_parent() as Enemy
		if body != null:
			body.velocity += body.global_position.direction_to(global_position) * SkillStats.LURE_TUG


## Le Sceau éclate : un coup par élément versé, dans tous à la fois, plus large. Le
## Contresceau laisse à sa place un glyphe ordinaire de chacun.
func _seal_burst() -> void:
	var natures := _natures()
	var blast := _cast.echoed(SkillStats.SEAL_PART * float(natures.size()))
	blast.blend(natures)
	Targets.strike_circle(get_world_3d(), global_position, reach(), blast, states)
	if _cast.counterseal <= 0.0:
		return
	for i in natures.size():
		var cast := _cast.echoed(1.0)
		Familiar.sing(cast, posmod(
			DamageType.ELEMENTS.find(natures[i]) - DamageType.ELEMENTS.find(_cast.nature),
			DamageType.ELEMENTS.size()
		))
		var corner := Flat.rotated(Vector3.FORWARD, TAU * float(i) / float(natures.size()))
		Glyph.place(
			_player, _owner, global_position + corner * _cast.radius * SkillStats.COUNTERSEAL_SPREAD,
			cast, _effects, false
		)


## Les éléments versés au Sceau, dans l'ordre du tour.
func _natures() -> Array[int]:
	var out: Array[int] = []
	for nature in DamageType.ELEMENTS:
		if _poured.has(nature):
			out.append(nature)
	return out


## `burst` : il éclate en partant — le Sceau frappe alors —, et son éclat se tient encore un
## instant ; sinon il s'efface.
func _go(burst: bool) -> void:
	if _out:
		return
	_out = true
	if not burst:
		queue_free()
		return
	if sealed:
		_seal_burst()
	_shatter_age = 0.0

