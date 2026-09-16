class_name BladeCrown
extends Node2D

## Les épées d'Épée spirale, qui tournent autour du joueur. Un seul nœud pour
## toutes : elles partagent un cercle et une rotation, et se répartissent dessus.

const RADIUS := 26.0
## Radians par seconde : un tour en un peu moins d'une seconde et demie.
const ROTATION := 4.2
const LENGTH := 15.0
## Du centre d'une épée au centre d'une hurtbox ennemie.
const CONTACT := 14.0
## Le temps que met une épée lancée à rejoindre le cercle.
const OUTPUT := 0.15
## Sans glissement, les survivantes sautent d'un tiers de tour quand une épée part.
const SLIDE := 8.0
const VANISH := 0.5
const STEEL := Color(0.80, 0.84, 0.92)
const THREAD := Color(1.0, 1.0, 1.0)
const GUARD := Color(0.86, 0.68, 0.30)
const HANDLE := Color(0.40, 0.26, 0.16)
## Les images rémanentes : leur retard sur l'épée en radians, et leur opacité.
const AFTERIMAGES := [[0.22, 0.30], [0.44, 0.14]]


class Blade:
	var cast: SkillStats
	var contacts: Targets.Contacts
	var age := 0.0
	var place := 0.0


var _blades: Array[Blade] = []
var _rotation := 0.0
## Celui qui les a lancées, pour ce que ses états changent à leurs coups. Posé une
## fois : la couronne ne change pas de porteur.
var author: StatusEffects


func _ready() -> void:
	z_index = 1


func count() -> int:
	return _blades.size()


## Zéro : sans limite.
func full(maximum: int) -> bool:
	return maximum > 0 and _blades.size() >= maximum


func add_to(cast: SkillStats) -> void:
	var blade := Blade.new()
	blade.cast = cast
	blade.contacts = Targets.Contacts.new(cast.period)
	# Elle naît à la place qui l'attend : ce sont les autres qui glissent.
	blade.place = TAU * float(_blades.size()) / float(_blades.size() + 1)
	_blades.append(blade)


func clear() -> void:
	_blades.clear()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _blades.is_empty():
		return
	_rotation = fmod(_rotation + ROTATION * delta, TAU)
	var alive_ones: Array[Blade] = []
	for blade in _blades:
		blade.age += delta
		blade.contacts.advance(delta)
		if blade.age < blade.cast.duration:
			alive_ones.append(blade)
	_blades = alive_ones
	var slides := 1.0 - exp(-SLIDE * delta)
	for i in _blades.size():
		_blades[i].place = lerp_angle(_blades[i].place, TAU * float(i) / float(_blades.size()), slides)
	_slice()
	queue_redraw()


func _slice() -> void:
	if _blades.is_empty():
		return
	var targets := Targets.in_circle(get_world_2d(), global_position, RADIUS + CONTACT)
	for blade in _blades:
		var center := to_global(_center(blade, _rotation + blade.place))
		for target in targets:
			if center.distance_to(target.global_position) <= CONTACT and blade.contacts.accepts(target):
				Targets.strike(target, blade.cast.roll(Game.rng), center, author, blade.cast)


func _center(blade: Blade, angle: float) -> Vector2:
	return Vector2.from_angle(angle) * RADIUS * smoothstep(0.0, OUTPUT, blade.age)


func _draw() -> void:
	for blade in _blades:
		var angle := _rotation + blade.place
		var fade := clampf((blade.cast.duration - blade.age) / VANISH, 0.0, 1.0)
		var tint: Color = DamageType.COLORS[blade.cast.dominant_nature()]
		for r: Array in AFTERIMAGES:
			var delay := angle - float(r[0])
			_blade(_center(blade, delay), delay, Color(tint, float(r[1]) * fade))
		_sword(_center(blade, angle), angle, fade)


## La lame seule, en silhouette : ce que montrent les images rémanentes.
func _blade(center: Vector2, angle: float, color: Color) -> void:
	var along := Vector2.from_angle(angle + PI * 0.5)
	var across := Vector2.from_angle(angle)
	var tip := center + along * LENGTH * 0.55
	var talon := center - along * LENGTH * 0.2
	var shoulder := tip - along * 3.0
	draw_colored_polygon(PackedVector2Array([
		talon + across * 1.3, shoulder + across * 1.3, tip,
		shoulder - across * 1.3, talon - across * 1.3,
	]), color)


## Tangente au cercle, pointe en avant : l'épée file dans le sens où elle tourne.
## Pointée vers l'extérieur, elle se lisait comme une lame de scie.
func _sword(center: Vector2, angle: float, fade: float) -> void:
	var along := Vector2.from_angle(angle + PI * 0.5)
	var across := Vector2.from_angle(angle)
	var tip := center + along * LENGTH * 0.55
	var talon := center - along * LENGTH * 0.2
	_blade(center, angle, Color(STEEL, fade))
	draw_line(talon + across * 0.5, tip, Color(THREAD, 0.8 * fade), 1.0)
	draw_line(talon + across * 3.2, talon - across * 3.2, Color(GUARD, fade), 1.6)
	draw_line(talon, talon - along * 4.0, Color(HANDLE, fade), 1.4)
	draw_circle(talon - along * 4.6, 1.0, Color(GUARD, fade))
