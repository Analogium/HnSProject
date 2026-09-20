class_name Immolation
extends Node2D

## Le brasier d'Immolation, porté par le joueur : il frappe les ennemis de son
## cercle à chaque période et brûle son porteur à chaque image.
##
## **Il se résout à chaque impulsion** par `Player.resolve()`, et relit les points
## à chaque image : un anneau retiré change la frappe suivante, et une compétence
## qu'on ne sait plus lancer — son livre a quitté le râtelier — s'éteint.

const FLAMES := 11
const BRAISES := 10
const IGNITION := 0.15
const RISE := 18.0

var _player: Player
var _skill: Skill
var _cast: SkillStats
var _age := 0.0
var _next_threshold := 0.0
## Les points de départ des escarbilles, dans le disque unité : le rayon change
## avec les nœuds, pas leur répartition.
var _braises: Array[Vector2] = []


static func ignite(player: Player, skill: Skill) -> Immolation:
	var aura := Immolation.new()
	aura._player = player
	aura._skill = skill
	player.add_child(aura)
	return aura


func _ready() -> void:
	show_behind_parent = true
	material = ArtPalette.ADDITIVE
	var rng := RandomNumberGenerator.new()
	rng.seed = int(get_instance_id())
	for i in BRAISES:
		_braises.append(Vector2.from_angle(rng.randf_range(0.0, TAU)) * sqrt(rng.randf()) * 0.8)


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
	if _cast == null or _age >= _next_threshold:
		_cast = _player.resolve(_skill, points)
		_next_threshold = _age + _cast.period
		_strike()
	queue_redraw()
	# En dernier : la brûlure peut tuer le porteur, qui éteint alors l'aura.
	_player.burn(_cast.self_burn, _cast.distribution(), delta)


func _strike() -> void:
	var parts := _cast.roll(Game.rng)
	for target in Targets.in_circle(get_world_2d(), global_position, _cast.radius):
		Targets.strike(target, parts, global_position, _player.states, _cast)


func _draw() -> void:
	if _cast == null:
		return
	var r := _cast.radius * minf(_age / IGNITION, 1.0)
	var tint: Color = DamageType.COLORS[_cast.dominant_nature()]
	# Un disque plein sortait **brun**, avec un bord net : une flaque. Le cœur de
	# lumière a la même portée mais s'éteint vers le bord, et c'est l'anneau qui
	# dit où ça mord.
	Glow.draw_blob(self, Vector2.ZERO, r, Color(tint, 0.14))
	Glow.draw_ring(self, Vector2.ZERO, r, Color(tint, 0.34))

	for i in FLAMES:
		# Deux couronnes emboîtées : toutes les langues sur le bord font une palissade.
		var span := 0.92 if i % 2 == 0 else 0.66
		var foot := Vector2.from_angle(TAU * float(i) / float(FLAMES) + _age * 0.5) * r * span
		# Des hauteurs inégales, fixes par langue : onze flammes de même taille font
		# une couronne de dents, et l'œil compte les dents.
		var tall := 6.0 + 5.0 * float((i * 7) % 5) / 4.0
		Fire.draw_tongue(
			self, foot, Vector2.UP, tall + 3.0 * Fire.breath(_age, i), 2.4, tint, 1.0,
			1.6 * Fire.breath(_age * 0.7, i + 3)
		)

	for i in BRAISES:
		var rise := fmod(_age * 0.7 + float(i) * 0.137, 1.0)
		var p := _braises[i] * r + Vector2(sin(_age * 3.0 + float(i)) * 1.5, -rise * RISE)
		Fire.draw_ember(self, p, tint, 0.8 * (1.0 - rise))
