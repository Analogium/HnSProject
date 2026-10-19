class_name Immolation
extends Node3D

## Le brasier d'Immolation, porté par le joueur : il frappe les ennemis de son
## cercle à chaque période et brûle son porteur à chaque image.
##
## **Il se résout à chaque impulsion** par `Player.resolve()`, et relit les points
## à chaque image : un anneau retiré change la frappe suivante, et une compétence
## qu'on ne sait plus lancer — son livre a quitté le râtelier — s'éteint.


var _player: Player
var _skill: Skill
var _cast: SkillStats
var _age := 0.0
var _next_threshold := 0.0
## Le Feu de camp (jalon 42) : les secondes passées sans bouger, et où le porteur était.
var _still := 0.0
var _was_at := Vector3.INF
var _sparks: ElementFx


static func ignite(player: Player, skill: Skill) -> Immolation:
	var aura := Immolation.new()
	aura._player = player
	aura._skill = skill
	player.add_child(aura)
	Settings.veil(aura, Settings.SPELLS)
	return aura


func extinguish() -> void:
	set_physics_process(false)
	queue_free()


func _physics_process(delta: float) -> void:
	var points := _player.skill_points(_skill.id)
	if points <= 0 or _player.is_dead:
		# Par le joueur : c'est lui qui tient la liste des allumés (invariant 5).
		_player.extinguish(_skill.id)
		return
	_age += delta
	_still = _still + delta if global_position == _was_at else 0.0
	_was_at = global_position
	if _cast == null or _age >= _next_threshold:
		_cast = _player.resolve(_skill, points)
		_cast.radius *= _rise()
		_sparks = ElementFx.keep(_sparks, self, DamageType.COLORS[_cast.nature], _cast.radius)
		_next_threshold = _age + _cast.period
		_strike()
	# La Veillée : à pleine montée du feu de camp, le brasier soigne.
	if _still >= SkillStats.CAMPFIRE_MOST:
		_player.mend(_cast.vigil * 0.01, delta)
	# En dernier : la brûlure peut tuer le porteur, qui éteint alors l'aura. Les Cendres du
	# phénix l'en dispensent.
	if _player.phoenix_ashes <= 0.0:
		_player.burn(_cast.self_burn, _cast.distribution(), delta)


## Ce que le Feu de camp ajoute, en multiple : son « plus » par seconde immobile, au plus
## `CAMPFIRE_MOST` secondes. Au rayon comme aux dégâts.
func _rise() -> float:
	return 1.0 + _cast.campfire * 0.01 * minf(_still, SkillStats.CAMPFIRE_MOST)


## Une impulsion : **un tirage** pour tout le cercle (invariant 3), comme
## `Targets.strike_circle()` — écrit à la main pour l'Œil du brasier, qui frappe plus fort
## au cœur, et le Tirage, qui y ramène (un recul négatif).
func _strike() -> void:
	var factor := _rise()
	if _player.phoenix_ashes > 0.0:
		factor *= 1.0 + _cast.phoenix_ashes * SkillStats.ASHES_MORE * 0.01
	var parts := DamageType.scaled(_cast.roll(Game.rng), factor)
	var core := _cast.radius * SkillStats.EYE_PART
	var eyed := DamageType.scaled(parts, 1.0 + _cast.eye * 0.01)
	for target in Targets.in_circle(get_world_3d(), global_position, _cast.radius):
		var inside := target.global_position.distance_to(global_position) <= core
		Targets.strike(
			target, eyed if inside else parts, global_position, _player.states, _cast, -_cast.pull
		)
	if _cast.embers > 0.0:
		_scatter(factor)


## Les Escarbilles : une étincelle par point vers un ennemi **hors** du cercle, jusqu'à
## `EMBER_REACH` fois son rayon, partie de son bord — à la force de l'impulsion.
func _scatter(factor: float) -> void:
	var left := int(_cast.embers)
	var spark := _cast.spark(SkillStats.EMBER_PART * factor)
	var reach := _cast.radius * SkillStats.EMBER_REACH
	for target in Targets.in_circle(get_world_3d(), global_position, reach):
		if left <= 0:
			return
		var toward := global_position.direction_to(target.global_position)
		if target.global_position.distance_to(global_position) > _cast.radius:
			Fireball.spark(
				_player._effects_parent(), global_position + toward * _cast.radius, toward, spark,
				_player.states
			)
			left -= 1

