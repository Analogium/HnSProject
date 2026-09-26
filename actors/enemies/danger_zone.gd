class_name DangerZone
extends Node2D

## Le télégraphe des attaques ennemies (jalon 27) : une zone au sol où le plein monte
## du départ jusqu'au bord ; quand il l'atteint, elle frappe. **Un seul signal pour
## les quatre attaques**, choisi sur planche — la charge, l'obus, l'explosion, la
## frappe au sol ne diffèrent que par la forme.
##
## Elle frappe **elle-même** : l'obus tombe même si le mortier est mort entre-temps.
## Liée à son ennemi (`bound`), elle tombe avec lui : un coup de masse s'annule avec
## le colosse qui le portait.

enum Shape { DISC, LANE, CONE }

const MATERIAL := preload("res://fx/danger_zone.gdshader")
## Le rouge du danger, hors du feu : l'orange est la couleur des sorts du joueur.
const DARK := Color(0.42, 0.07, 0.08)
const MID := Color(0.86, 0.20, 0.16)
## La frappe se dissout en damier, elle ne pâlit pas.
const FADE := 0.18

var shape := Shape.DISC
var reach := 0.0
## Demi-largeur du couloir, demi-angle du cône.
var spread := 0.0
var facing := Vector2.RIGHT
var delay := 1.0

## Ce qu'elle inflige, par nature ; vide, elle ne frappe pas (le couloir de la charge).
var parts: Array[float] = []
var knockback := 0.0
var author: StatusEffects
var bound: Enemy

var _age := 0.0
var _struck := false


static func put(
	parent: Node, at: Vector2, p_shape: Shape, p_reach: float, p_delay: float,
	p_facing := Vector2.RIGHT, p_spread := 0.0
) -> DangerZone:
	var z := DangerZone.new()
	z.shape = p_shape
	z.reach = p_reach
	z.delay = p_delay
	z.facing = p_facing.normalized()
	z.spread = p_spread
	# En différé : le gonfle la pose en mourant, parfois depuis un rappel de collision
	# (invariant 4). Sur le pixel du monde : le shader compte depuis l'origine du nœud.
	DeferredTree.add_deferred(parent, z, at.round())
	return z


func _ready() -> void:
	var m := ShaderMaterial.new()
	m.shader = MATERIAL
	m.set_shader_parameter("shape", shape)
	m.set_shader_parameter("reach", reach)
	m.set_shader_parameter("spread", spread)
	m.set_shader_parameter("facing", facing)
	m.set_shader_parameter("dark", DARK)
	m.set_shader_parameter("mid", MID)
	material = m


func _physics_process(delta: float) -> void:
	if bound != null and (not is_instance_valid(bound) or bound.is_dead):
		queue_free()
		return
	_age += delta
	if not _struck and _age >= delay:
		_struck = true
		bound = null
		_strike()
	var m := material as ShaderMaterial
	m.set_shader_parameter("progress", minf(_age / delay, 1.0))
	m.set_shader_parameter("gone", maxf(_age - delay, 0.0) / FADE)
	if _age >= delay + FADE:
		queue_free()


## Le miroir de `depth()` dans le shader : ce qui est dessiné est ce qui est frappé.
func contains(point: Vector2) -> bool:
	var p := point - global_position
	match shape:
		Shape.DISC:
			return p.length() <= reach
		Shape.LANE:
			var along := p.dot(facing)
			return along >= 0.0 and along <= reach and absf(p.dot(facing.orthogonal())) <= spread
	return p.length() <= reach and p.dot(facing) > 0.0 and absf(facing.angle_to(p)) <= spread


func _strike() -> void:
	if parts.is_empty():
		return
	# Un disque est une explosion : son souffle dessiné, sa frappe unique.
	if shape == Shape.DISC:
		Explosion.put(
			get_parent(), global_position, parts, reach, null,
			DamageType.COLORS[DamageType.dominant(parts)], author, null, Targets.PLAYER_SIDE
		)
		return
	for hurtbox in Targets.in_circle(get_world_2d(), global_position, reach, Targets.PLAYER_SIDE):
		if contains(hurtbox.global_position):
			var info := DamageInfo.as_parts(parts, global_position, knockback)
			info.author = author
			hurtbox.take_damage(info)


func _draw() -> void:
	var r := reach + 1.0
	draw_rect(Rect2(-r, -r, r * 2.0, r * 2.0), Color.WHITE)
