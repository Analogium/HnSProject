class_name StaticOrb
extends Node2D

## L'Orbe statique (jalon 35, transformation d'Éclair vif) : un orbe lent qui file droit
## et foudroie à chaque période ce qui passe dans son rayon. Il ne frappe pas à l'impact
## et traverse les ennemis ; un mur l'éteint.

const BOLT_LIFETIME := 0.14
## Les spores d'une nuée nécrotique.
const SWARM := 12

var _cast: SkillStats
var _author: StatusEffects
var _dir := Vector2.RIGHT
var _tint := Color.WHITE
var _age := 0.0
var _strikes := 0
var _bolts: Array[StormCloud.Bolt] = []
## Tirage local et jamais `Game.rng` (invariant 3).
var _flicker := RandomNumberGenerator.new()


static func send(
	parent: Node, from: Vector2, direction: Vector2, cast: SkillStats, author: StatusEffects
) -> StaticOrb:
	var orb := StaticOrb.new()
	orb._cast = cast
	orb._author = author
	orb._dir = direction.normalized()
	orb._tint = DamageType.COLORS[cast.nature]
	parent.add_child(orb)
	Settings.veil(orb, Settings.SPELLS)
	orb.global_position = from + orb._dir * Projectile.MUZZLE
	return orb


func _ready() -> void:
	z_index = 5
	_flicker.seed = int(get_instance_id())


## Les frappes se comptent par `strikes_due()`, comme le nuage : la fiche et l'orbe ne
## peuvent pas annoncer deux nombres.
func _physics_process(delta: float) -> void:
	_age += delta
	var step := _dir * _cast.projectile_speed * delta
	if not Targets.in_sight(get_world_2d(), global_position, global_position + step):
		queue_free()
		return
	global_position += step
	var due := _cast.strikes_due(_age)
	while _strikes < due:
		_strike()
		_strikes += 1
	for e in _bolts:
		e.age += delta
	_bolts = _bolts.filter(func(e: StormCloud.Bolt) -> bool: return e.age < BOLT_LIFETIME)
	queue_redraw()
	if _age >= _cast.duration:
		queue_free()


func _strike() -> void:
	for target in Targets.strike_circle(get_world_2d(), global_position, _cast.radius, _cast, _author):
		var e := StormCloud.Bolt.new()
		e.toward = to_local(target.global_position)
		_bolts.append(e)


func _draw() -> void:
	if _cast.nature == DamageType.Kind.NECROTIC:
		_swarm()
		return
	Lightning.orb(
		_tint, Lightning.hold(_age) + int(get_instance_id()), Lightning.gone(_age, _cast.duration)
	).put(self, Vector2.ZERO)
	for e in _bolts:
		var beat := Lightning.hold(e.age)
		if beat != e.shown:
			e.shown = beat
			_flicker.seed = int(get_instance_id()) ^ beat ^ int(e.toward.x)
			e.pieces = Lightning.chain(
				PackedVector2Array([Vector2.ZERO, e.toward]), _flicker, _tint, 1, true,
				Lightning.gone(e.age, BOLT_LIFETIME)
			)
		Lightning.put(self, e.pieces)


## La Nuée de la Peste (jalon 38), « spores en orbite » choisi sur planche contre un crâne
## cerné de mouches ou de volutes, une ronde de crânes et des traînées : des spores qui
## tournent chacune sur son orbite, dans les deux sens, dans le cercle qu'il mord.
func _swarm() -> void:
	var spore := EffectForge.spore(_tint)
	for i in SWARM:
		var orbit := _cast.radius * (0.2 + 0.4 * fmod(float(i) * 0.618034, 1.0))
		var angle := float(i) * 2.399963 + _age * (3.0 if i % 2 == 0 else -2.2)
		Necrotic.centered(self, spore, Vector2.from_angle(angle) * orbit)
