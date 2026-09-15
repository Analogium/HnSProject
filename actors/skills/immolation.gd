class_name Immolation
extends Node2D

## Le brasier d'Immolation, porté par le joueur : il frappe les ennemis de son
## cercle à chaque période et brûle son porteur à chaque image.
##
## **Il se résout à chaque impulsion** par `Player.resolve()`, et relit les points
## à chaque image : un anneau retiré change la frappe suivante, et une compétence
## qu'on ne sait plus lancer — son livre a quitté le râtelier — s'éteint.

const FLAMES := 16
const BRAISES := 10
const IGNITION := 0.15
const RISE := 18.0
const LIGHT := Color(1.0, 0.95, 0.6)

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
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m
	var rng := RandomNumberGenerator.new()
	rng.seed = int(get_instance_id())
	for i in BRAISES:
		_braises.append(Vector2.from_angle(rng.randf_range(0.0, TAU)) * sqrt(rng.randf()) * 0.8)


func lit() -> bool:
	return not is_queued_for_deletion()


func extinguish() -> void:
	set_physics_process(false)
	queue_free()


func _physics_process(delta: float) -> void:
	var points := _player.skill_points(_skill.id)
	if points <= 0 or _player.is_dead:
		extinguish()
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
		Targets.strike(target, parts, global_position, _player.states)


func _draw() -> void:
	if _cast == null:
		return
	var r := _cast.radius * minf(_age / IGNITION, 1.0)
	var tint: Color = DamageType.COLORS[_cast.dominant_nature()]
	var light_color := tint.lerp(LIGHT, 0.6)
	draw_circle(Vector2.ZERO, r, Color(tint, 0.10))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(tint, 0.30), 1.5)

	for i in FLAMES:
		var foot := Vector2.from_angle(TAU * float(i) / float(FLAMES) + _age * 0.5) * r * 0.92
		var height := 7.0 + 3.0 * sin(_age * 9.0 + float(i) * 1.7) + 2.0 * sin(_age * 13.0 + float(i) * 0.6)
		_flame(foot, height, 2.6, Color(tint, 0.45))
		_flame(foot, height * 0.55, 1.3, Color(light_color, 0.55))

	for i in BRAISES:
		var rise := fmod(_age * 0.7 + float(i) * 0.137, 1.0)
		var p := _braises[i] * r + Vector2(sin(_age * 3.0 + float(i)) * 1.5, -rise * RISE)
		draw_rect(Rect2(p, Vector2.ONE), Color(light_color, 0.8 * (1.0 - rise)))


## Les flammes montent vers le haut de l'écran quel que soit leur angle : un
## brasier vu de dessus en vue plongeante brûle vers le ciel, pas vers l'extérieur.
func _flame(foot: Vector2, height: float, half_width: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		foot + Vector2(-half_width, 0.0),
		foot + Vector2(half_width, 0.0),
		foot + Vector2(sin(_age * 7.0 + foot.x) * 1.2, -height),
	]), color)
