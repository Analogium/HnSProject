class_name Cyclone
extends Node2D

## Le cyclone : un geste d'arme entretenu. Tant qu'il tourne, il frappe son cercle à
## chaque période et draine le mana à chaque image ; la réserve vide l'arrête, là où la
## brûlure d'une aura tue.
##
## **Il se résout à chaque impulsion** par `Player.resolve()` et relit ses points à
## chaque image, comme l'aura : un livre qui quitte le râtelier éteint ce qu'il
## enseignait.
##
## Il ne ralentit pas son porteur : le tour d'épée est ce qu'on lance pour traverser un
## paquet, et l'arrêter sur place en ferait une seconde Immolation.

## Les lames qui tournent, et leur vitesse en tours par seconde.
const BLADES := 3
const SPIN := 4.0
## Ce qui vole autour : les éclats soulevés par le tour.
const MOTES := 8
const OPENING := 0.12

var _player: Player
var _skill: Skill
var _cast: SkillStats
var _age := 0.0
var _next_threshold := 0.0


static func spin(player: Player, skill: Skill) -> Cyclone:
	var node := Cyclone.new()
	node._player = player
	node._skill = skill
	player.add_child(node)
	return node


func _ready() -> void:
	z_index = 2
	material = ArtPalette.ADDITIVE


## Appelée par `Player.extinguish()`, le seul chemin.
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
	if not _player.drain(_cast.mana_per_second, delta):
		_player.extinguish(_skill.id)
		return
	# Les deux prix, comme un buff : une lame qui coûterait des PV se règle dans le
	# `.tres` et non ici. En dernier — la brûlure peut tuer le porteur.
	_player.burn(_cast.self_burn, _cast.distribution(), delta)


## Un tirage par impulsion, qu'elle touche ou non : c'est un geste du cyclone.
func _strike() -> void:
	var parts := _cast.roll(Game.rng)
	for target in Targets.in_circle(get_world_2d(), global_position, _cast.radius):
		Targets.strike(target, parts, global_position, _player.states, _cast)


## Des lames en rotation plutôt qu'un disque : c'est le mouvement qui dit « ça tourne »,
## et un cercle plein au sol se lirait comme une aura de plus.
func _draw() -> void:
	if _cast == null:
		return
	var r := _cast.radius * minf(_age / OPENING, 1.0)
	var tint: Color = DamageType.COLORS[_cast.dominant_nature()]
	var light_color := tint.lerp(Color.WHITE, 0.5)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(tint, 0.18), 1.0)

	for i in BLADES:
		var angle := TAU * float(i) / float(BLADES) + _age * SPIN
		var tip := Vector2.from_angle(angle) * r
		# La lame traîne derrière elle : sans cette seconde ligne, trois rayons figés.
		var trail := Vector2.from_angle(angle - 0.5) * r * 0.9
		draw_line(tip * 0.25, tip, Color(light_color, 0.85), 2.0)
		draw_line(trail * 0.3, trail, Color(tint, 0.35), 2.0)

	for i in MOTES:
		var turn := _age * SPIN * 0.6 + TAU * float(i) / float(MOTES)
		var distance := r * (0.4 + 0.55 * fmod(_age * 0.9 + float(i) * 0.121, 1.0))
		draw_rect(
			Rect2(Vector2.from_angle(turn) * distance, Vector2.ONE), Color(light_color, 0.7)
		)
