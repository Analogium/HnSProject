class_name Immolation
extends Node2D

## Le brasier d'Immolation, porté par le joueur : il frappe les ennemis de son
## cercle à chaque période et brûle son porteur à chaque image.
##
## **Il se résout à chaque impulsion** par `Player.resolve()`, et relit les points
## à chaque image : un anneau retiré change la frappe suivante, et une compétence
## qu'on ne sait plus lancer — son livre a quitté le râtelier — s'éteint.

const FLAMES := 9
const BRAISES := 10
const IGNITION := 0.15
const RISE := 18.0

## Les langues sont peintes dans un nœud à part, en mélange **normal** : leur
## contour doit cacher le sol, et en additif un contour sombre n'ajoute rien — il
## disparaît, et avec lui ce qui les rattache au décor.
class Flames:
	extends Node2D
	var aura: Immolation

	func _draw() -> void:
		aura.paint_flames(self)


var _player: Player
var _skill: Skill
var _cast: SkillStats
var _age := 0.0
var _next_threshold := 0.0
## Les points de départ des escarbilles, dans le disque unité : le rayon change
## avec les nœuds, pas leur répartition.
var _braises: Array[Vector2] = []
var _flames: Flames
## Le Feu de camp (jalon 42) : les secondes passées sans bouger, et où le porteur était.
var _still := 0.0
var _was_at := Vector2.INF


static func ignite(player: Player, skill: Skill) -> Immolation:
	var aura := Immolation.new()
	aura._player = player
	aura._skill = skill
	player.add_child(aura)
	Settings.veil(aura, Settings.SPELLS)
	return aura


func _ready() -> void:
	show_behind_parent = true
	material = ArtPalette.ADDITIVE
	_flames = Flames.new()
	_flames.aura = self
	add_child(_flames)
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
	_still = _still + delta if global_position == _was_at else 0.0
	_was_at = global_position
	if _cast == null or _age >= _next_threshold:
		_cast = _player.resolve(_skill, points)
		_cast.radius *= _rise()
		_next_threshold = _age + _cast.period
		_strike()
	queue_redraw()
	_flames.queue_redraw()
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
	var parts := _cast.roll(Game.rng)
	var factor := _rise()
	if _player.phoenix_ashes > 0.0:
		factor *= 1.0 + _cast.phoenix_ashes * SkillStats.ASHES_MORE * 0.01
	for i in parts.size():
		parts[i] *= factor
	var core := _cast.radius * SkillStats.EYE_PART
	var eyed := parts.duplicate()
	for i in eyed.size():
		eyed[i] *= 1.0 + _cast.eye * 0.01
	for target in Targets.in_circle(get_world_2d(), global_position, _cast.radius):
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
	for target in Targets.in_circle(get_world_2d(), global_position, reach):
		if left <= 0:
			return
		var toward := global_position.direction_to(target.global_position)
		if target.global_position.distance_to(global_position) > _cast.radius:
			Fireball.spark(
				_player._effects_parent(), global_position + toward * _cast.radius, toward, spark,
				_player.states
			)
			left -= 1


func _draw() -> void:
	if _cast == null:
		return
	var r := _cast.radius * minf(_age / IGNITION, 1.0)
	var tint: Color = DamageType.COLORS[_cast.nature]
	# Un halo **tramé** et calé sur la grille : un disque plein sortait brun avec
	# un bord net, et un dégradé lisse reste la seule chose de l'aura qui ne soit
	# pas du pixel art.
	EffectForge.put_scorch(self, tint, roundi(r))
	Glow.draw_ring(self, Vector2.ZERO, r, Color(tint, 0.34))

	for i in BRAISES:
		var rise := fmod(_age * 0.7 + float(i) * 0.137, 1.0)
		var p := _braises[i] * r + Vector2(sin(_age * 3.0 + float(i)) * 1.5, -rise * RISE)
		Fire.draw_ember(self, p, tint, 0.8 * (1.0 - rise))


## Les langues, planches de la forge posées sur la grille du jeu. Appelée par le
## nœud `Flames`, qui n'a pas le mélange additif de l'aura.
func paint_flames(ci: CanvasItem) -> void:
	if _cast == null:
		return
	var r := _cast.radius * minf(_age / IGNITION, 1.0)
	var frames := EffectForge.flames(DamageType.COLORS[_cast.nature])
	var size := Vector2(EffectForge.FLAME_WIDTH, EffectForge.FLAME_HEIGHT)
	for i in FLAMES:
		# Deux couronnes emboîtées : toutes les langues sur le bord font une palissade.
		var span := 0.95 if i % 2 == 0 else 0.62
		var foot := Vector2.from_angle(TAU * float(i) / float(FLAMES) + _age * 0.5) * r * span
		# Chaque langue avance à son propre temps : onze flammes au même battent
		# comme un métronome.
		var frame := int(_age * EffectForge.FLAME_HZ + float(i) * 1.7) % frames.size()
		var at := EffectForge.snap(ci, foot - Vector2(size.x * 0.5, size.y))
		ci.draw_texture_rect(frames[frame], Rect2(at, size), false)
