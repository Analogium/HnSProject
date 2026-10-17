class_name HamelinAir
extends Node3D

## L'Air de Hamelin (jalon 53) : une mélodie entretenue autour du joueur de flûte — au point
## visé sous la Sérénade. À chaque battement (`period`) elle frappe son cercle en nécrotique,
## y attire les ennemis et les ralentit ; sous le Roi des Rats, elle les fait fuir.
##
## Comme l'aura, **elle se résout à chaque battement** et relit les points à chaque image.
## Son dessin, la « ronde de notes » choisie sur planche, tourne sur le bord du cercle (`Piper`).

## Ceux qui jouent : la Marée y lit les Rats de cale.
static var playing: Array[HamelinAir] = []

var _player: Player
var _skill: Skill
var _cast: SkillStats
var _age := 0.0
var _next := 0.0
var _since_charm := 0.0
## La Mélopée : depuis quand chaque ennemi l'écoute, par identifiant de hurtbox.
var _heard := {}
## Le Requiem : ceux dont la mort est déjà guettée.
var _mourned := {}


static func play(player: Player, skill: Skill) -> HamelinAir:
	var air := HamelinAir.new()
	air._player = player
	air._skill = skill
	if player.resolve(skill, player.skill_points(skill.id)).serenade > 0.0:
		player._effects_parent().add_child(air)
		air.global_position = player._aim_point()
	else:
		player.add_child(air)
	Settings.veil(air, Settings.SPELLS)
	return air


## Ce point est-il sous un air qui joue ?
static func covers(point: Vector3) -> bool:
	for air in playing:
		if air._cast != null and air.global_position.distance_to(point) <= air._cast.radius:
			return true
	return false


func _enter_tree() -> void:
	playing.append(self)


func _exit_tree() -> void:
	playing.erase(self)


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
	if _cast == null or _age >= _next:
		_cast = _player.resolve(_skill, points)
		if _cast.serenade > 0.0:
			_cast.radius *= SkillStats.SERENADE_WIDTH
		_next = _age + _cast.period
		_beat()
	if _cast.carousel > 0.0 and not _player.reigns():
		_turn(delta)
	_since_charm += delta
	if _cast.charmed_rats > 0.0 and _since_charm >= SkillStats.CHARM_EVERY:
		_since_charm = 0.0
		_charm()
	if not _player.drain(_cast.mana_per_second, delta):
		_player.extinguish(_skill.id)


## Un battement : **un tirage** pour tout le cercle (invariant 3). Le Carrousel et le Roi ne
## tirent plus vers le joueur.
func _beat() -> void:
	var parts := _cast.roll(Game.rng)
	var reigning := _player.reigns()
	var pull := 0.0 if _cast.carousel > 0.0 or reigning else -_cast.pull
	var fear := SkillStats.AIR_FEAR + _player.lit_number(SkillStats.TERROR) if reigning else 0.0
	var targets := Targets.in_circle(get_world_3d(), global_position, _cast.radius)
	var heard := {}
	for target in targets:
		var id := target.get_instance_id()
		heard[id] = float(_heard.get(id, 0.0)) + _cast.period
		var body := target.get_parent() as Enemy
		# Guetté **avant** la frappe : celle-ci peut le tuer, et sa note se perdait.
		if body != null and _cast.requiem > 0.0 and not _mourned.has(id):
			_mourned[id] = true
			body.died.connect(_on_died)
		Targets.strike(target, parts, global_position, _player.states, _cast, pull)
		if target.states != null:
			target.states.hobble(SkillStats.AIR_SLOW + _cast.torpor, _cast.period * 2.0)
			if _cast.threnody > 0.0:
				var listened := minf(heard[id], SkillStats.THRENODY_MOST)
				target.states.open_up(_cast.threnody * listened, _cast.period * 2.0)
		if body == null:
			continue
		if reigning:
			body.frighten(fear, global_position)
	# Qui est sorti du cercle recommence la Mélopée à zéro.
	_heard = heard
	if _cast.farandole > 0.0 and _cast.carousel > 0.0 and not reigning:
		_jostle(targets, parts)


## Le Carrousel : ceux du cercle tournent autour du centre au lieu d'y tomber.
func _turn(delta: float) -> void:
	for target in Targets.in_circle(get_world_3d(), global_position, _cast.radius):
		var body := target.get_parent() as Enemy
		if body == null or body.is_dead:
			continue
		var arm := body.global_position - global_position
		body.tug(Flat.orthogonal(arm) * SkillStats.CAROUSEL_TURN * delta)


## La Farandole : chacun heurte son plus proche voisin du cercle.
func _jostle(targets: Array[Hurtbox], parts: Array[float]) -> void:
	var bump := DamageType.scaled(parts, _cast.farandole * 0.01)
	for target in targets:
		if not is_instance_valid(target):
			continue
		var closest: Hurtbox = null
		for other in targets:
			if other == target or not is_instance_valid(other):
				continue
			var d := target.global_position.distance_to(other.global_position)
			if d <= SkillStats.FARANDOLE_REACH and (closest == null \
					or d < target.global_position.distance_to(closest.global_position)):
				closest = other
		if closest != null:
			Targets.strike(closest, bump, target.global_position, _player.states, _cast)


## Les Rats charmés : un ennemi de son cercle en reçoit, au rongement d'un battement.
func _charm() -> void:
	var targets := Targets.in_circle(get_world_3d(), global_position, _cast.radius)
	if targets.is_empty():
		return
	var target: Hurtbox = targets[Game.rng.randi_range(0, targets.size() - 1)]
	if target.states != null:
		target.states.add_rats(
			int(_cast.charmed_rats), _cast.average_per_hit() * StatusEffects.GNAW_PART,
			_player.states, _skill.id
		)


## Le Requiem : un ennemi mort sous l'air y laisse une note qui frappe ses voisins. En différé :
## on meurt souvent dans un rappel de collision (invariant 4).
func _on_died(body: Enemy) -> void:
	if _cast != null and global_position.distance_to(body.global_position) <= _cast.radius:
		_note.call_deferred(body.global_position)


func _note(at: Vector3) -> void:
	if _cast == null:
		return
	var note := DamageType.scaled(_cast.roll(Game.rng), _cast.requiem * 0.01)
	for target in Targets.in_circle(get_world_3d(), at, SkillStats.REQUIEM_RADIUS):
		Targets.strike(target, note, at, _player.states, _cast)
