class_name Cauldron
extends Node2D

## Le Chaudron (jalon 49) : posé au point visé, il **bout dans l'élément du dernier sort** de
## sa maîtresse — à chaque période, il frappe son cercle dans cet élément et y pose son état.
## Ses sorts s'y versent (`pour()`) : quand il a reçu les trois éléments, il explose (le débordement, `_overflow()`) — les trois
## natures, plus large, les trois états à coup sûr — puis se remet à bouillir, vide. Un seul
## par joueur, sauf ce que `simultaneous` permet ; le plus ancien s'éteint.

const LIFT := Vector2(0.0, -9.0)
## La vapeur : jusqu'où elle monte au-dessus du bord, en tours par seconde.
const VAPOR_HEIGHT := 12.0
const VAPOR_RISE := 0.8

## Tous ceux qui bouillent : le joueur leur verse ses sorts.
static var boiling: Array[Cauldron] = []

## Pour `StatusEffects.of()` : ses coups frappent au nom du joueur.
var states: StatusEffects
## L'élément qui bout, et celui d'avant pour le Mélange.
var element := -1
var _previous := -1
var _player: Player
var _cast: SkillStats
var _age := 0.0
var _life_bonus := 0.0
var _since_bubble := 0.0
## Les éléments versés depuis la dernière explosion, et ce que la Décoction a bu.
var _poured := {}
var _drunk := 0.0
var _out := false


static func place(player: Player, point: Vector2, cast: SkillStats, parent: Node) -> Cauldron:
	var own := boiling.filter(func(c: Cauldron) -> bool: return c._player == player and not c._out)
	for old in cast.crowded(own):
		(old as Cauldron)._go_out(false)
	var c := Cauldron.new()
	c._player = player
	c._cast = cast
	c.states = player.states
	c.element = cast.nature
	c._poured[cast.nature] = true
	parent.add_child(c)
	Settings.veil(c, Settings.SPELLS)
	c.global_position = point
	return c


## Un sort de ce joueur vient de partir : chacun de ses chaudrons bout désormais dans son
## élément, et explose s'il a reçu les trois.
static func pour_all(player: Player, nature: int) -> void:
	if not nature in DamageType.ELEMENTS:
		return
	for c in boiling.duplicate():
		if c._player == player and not c._out:
			c._pour(nature)


func _pour(nature: int) -> void:
	if nature != element:
		_previous = element
		element = nature
	_poured[nature] = true
	if _poured.size() == DamageType.ELEMENTS.size() and _cast.emulsion <= 0.0:
		_overflow(1.0)
		_poured.clear()


func _enter_tree() -> void:
	boiling.append(self)


func _exit_tree() -> void:
	boiling.erase(self)


func lifetime() -> float:
	return _cast.duration + _life_bonus


## Un livre rangé ou un joueur tombé l'éteignent sans éclat.
func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player) or _player.is_dead \
			or _player.skill_points(_cast.skill_id) <= 0:
		_go_out(false)
		return
	_age += delta
	if _age >= lifetime():
		_go_out(true)
		return
	# Le Philtre : sa maîtresse, dans son cercle, y reprend du mana.
	if _cast.philtre > 0.0 and _player.global_position.distance_to(global_position) <= _cast.radius:
		_player.gain_mana(_cast.philtre * delta)
	_since_bubble += delta
	if _since_bubble >= _cast.period:
		_since_bubble -= _cast.period
		_bubble()
	queue_redraw()


## Un bouillon : son cercle frappé dans ce qu'il contient. Sous la Décoction, il boit
## au lieu de poser.
func _bubble() -> void:
	var bubble := _cast.echoed(1.0)
	bubble.blend(_contents())
	bubble.nature = element
	if _cast.decoction > 0.0:
		_drink()
		# Plus de chance d'état que n'en porte aucun lanceur : le bouillon ne pose rien.
		bubble.status_chance_increase -= SkillStats.SURE_STATE
	else:
		bubble.status_chance_increase += SkillStats.SURE_STATE
	Targets.strike_circle(get_world_2d(), global_position, _cast.radius, bubble, states)
	if _cast.froth > 0.0 and Game.rng.randf() * 100.0 < _cast.froth:
		_spit(bubble)


## Ce qui bout : l'élément seul, les deux derniers sous le Mélange, les trois sous l'Émulsion.
func _contents() -> Array[int]:
	if _cast.emulsion > 0.0:
		return DamageType.ELEMENTS.duplicate()
	if _cast.mix > 0.0 and _previous >= 0 and _previous != element:
		return [_previous, element] as Array[int]
	return [element] as Array[int]


## La Décoction : chaque bouillon retire du temps aux états élémentaires de son cercle, et ce
## qu'il boit grossit l'explosion — la Lie prolonge le chaudron d'autant.
func _drink() -> void:
	var sip := 0.0
	for target in Targets.in_circle(get_world_2d(), global_position, _cast.radius):
		if target.states == null:
			continue
		for kind: int in StatusEffects.ELEMENTAL:
			var left := target.states.remaining(kind)
			if left > 0.0:
				sip += minf(left, SkillStats.DECOCTION_SIP)
				target.states.extend(kind, -SkillStats.DECOCTION_SIP)
	_drunk += sip
	_life_bonus += sip * _cast.lees


## L'Écume : une goutte vers l'ennemi le plus proche hors du cercle — qui éclate sous les Bulles.
func _spit(bubble: SkillStats) -> void:
	var prey := Targets.nearest(get_world_2d(), global_position, SkillStats.FROTH_REACH, _inside())
	if prey == null:
		return
	var drop := bubble.echoed(SkillStats.FROTH_PART)
	drop.status_chance_increase = _cast.status_chance_increase
	var scene := _player.orb_scene if _cast.bubbles > 0.0 else _player.comet_scene
	var from := global_position + LIFT
	var bolt := Projectile.spawn(
		get_parent(), scene, from, from.direction_to(prey.global_position), drop.roll(Game.rng),
		self, SkillStats.FROTH_SPEED, element, drop
	)
	if bolt is Fireball:
		(bolt as Fireball).explosion_radius = _cast.bubbles


## Ce qui est déjà dans son cercle, que la goutte ne vise pas.
func _inside() -> Dictionary:
	var out := {}
	for target in Targets.in_circle(get_world_2d(), global_position, _cast.radius):
		out[target.get_instance_id()] = true
	return out


## L'explosion : les trois natures, plus large, les trois états à coup sûr. `part` : sa
## part d'une explosion entière — le Couvercle n'en verse que ce qui a été versé.
func _overflow(part: float) -> void:
	var gain := SkillStats.SPILL_PART * part * (1.0 + _cast.brim * 0.01) \
			* (1.0 + _drunk * SkillStats.DECOCTION_GAIN)
	var spill := _cast.echoed(gain)
	var natures: Array[int] = []
	for nature: int in _poured:
		natures.append(nature)
	spill.blend(natures if part < 1.0 else DamageType.ELEMENTS)
	spill.status_chance_increase += SkillStats.SURE_STATE
	_drunk = 0.0
	Explosion.put(
		get_parent(), global_position, spill.roll(Game.rng),
		_cast.radius * SkillStats.SPILL_REACH, null, _tint(), states, spill
	)


## Le Couvercle : à sa fin, il explose dans ce qui a été versé, à sa part.
func _go_out(ended: bool) -> void:
	if _out:
		return
	_out = true
	if ended and _cast.lid > 0.0 and not _poured.is_empty():
		_overflow(float(_poured.size()) / float(DamageType.ELEMENTS.size()) * SkillStats.LID_PART)
	queue_free()


func _tint() -> Color:
	return DamageType.COLORS[element]


## La marmite (`EffectForge.cauldron()`) sur la brûlure de son cercle, bordé de bulles là où il
## frappe, à la teinte de ce qui bout, et deux grains de vapeur qui montent : sans eux, entre deux
## bulles, elle se lit éteinte.
func _draw() -> void:
	var tint := _tint()
	EffectForge.put_scorch(self, tint, roundi(_cast.radius), 0.35)
	var frames := EffectForge.cauldron(tint)
	var frame := int(_age * EffectForge.CAULDRON_HZ) % frames.size()
	EffectForge.cauldron_rim(tint, roundi(_cast.radius), frame).put(self, Vector2.ZERO)
	var tex := frames[frame]
	EffectForge.put_centered(self, tex, Vector2(0.0, -tex.get_height() * 0.5 + 1.0))
	for i in 2:
		var rise := fmod(_age * VAPOR_RISE + float(i) * 0.5, 1.0)
		var at := Vector2(-3.0 + 6.0 * float(i), -EffectForge.CAULDRON_HEIGHT - 2.0 - rise * VAPOR_HEIGHT)
		draw_rect(Rect2(EffectForge.snap(self, at), Vector2.ONE), tint.lerp(Color.WHITE, 0.5))
