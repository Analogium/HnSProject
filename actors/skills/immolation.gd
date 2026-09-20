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


static func ignite(player: Player, skill: Skill) -> Immolation:
	var aura := Immolation.new()
	aura._player = player
	aura._skill = skill
	player.add_child(aura)
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
	if _cast == null or _age >= _next_threshold:
		_cast = _player.resolve(_skill, points)
		_next_threshold = _age + _cast.period
		_strike()
	queue_redraw()
	_flames.queue_redraw()
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
	# Un halo **tramé** et calé sur la grille : un disque plein sortait brun avec
	# un bord net, et un dégradé lisse reste la seule chose de l'aura qui ne soit
	# pas du pixel art.
	var span := int(round(r))
	var scorch := EffectForge.scorch(tint, span)
	var corner := EffectForge.snap(self, -Vector2(span, span))
	draw_texture_rect(scorch, Rect2(corner, Vector2(span * 2 + 1, span * 2 + 1)), false)
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
	var frames := EffectForge.flames(DamageType.COLORS[_cast.dominant_nature()])
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
