class_name DangerZone
extends MeshInstance3D

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
## Le temps qu'elle reste après la frappe, le temps de s'effacer.
const FADE := 0.18
## Au-dessus du sol plat : à sa hauteur, elle s'y mêlerait par endroits.
const LIFT := 0.5

var shape := Shape.DISC
var reach := 0.0
## Demi-largeur du couloir, demi-angle du cône.
var spread := 0.0
var facing := Vector3.RIGHT
var delay := 1.0

## Ce qu'elle inflige, par nature ; vide, elle ne frappe pas (le couloir de la charge).
var parts: Array[float] = []
var knockback := 0.0
var author: StatusEffects
var bound: Enemy

var _age := 0.0
var _struck := false


static func put(
	parent: Node, at: Vector3, p_shape: Shape, p_reach: float, p_delay: float,
	p_facing := Vector3.RIGHT, p_spread := 0.0
) -> DangerZone:
	var z := DangerZone.new()
	z.shape = p_shape
	z.reach = p_reach
	z.delay = p_delay
	z.facing = p_facing.normalized()
	z.spread = p_spread
	# En différé : le gonfle la pose en mourant, parfois depuis un rappel de collision
	# (invariant 4). Sur le pixel du monde : la frappe compte depuis l'origine du nœud.
	Settings.veil(z, Settings.ENEMY_ATTACKS)
	DeferredTree.add_deferred(parent, z, at.round())
	return z


## Un plan juste à la taille de la forme, tourné vers son cap : le couloir de la charge
## couvrirait sinon un carré de 340 px, presque tout jeté par le shader.
func _ready() -> void:
	rotation.y = -Flat.angle(facing)
	var plane := PlaneMesh.new()
	var side := reach * sin(minf(spread, PI * 0.5)) if shape == Shape.CONE else spread
	if shape == Shape.DISC:
		plane.size = Vector2.ONE * reach * 2.0
	else:
		plane.size = Vector2(reach, side * 2.0)
		plane.center_offset.x = reach * 0.5
	plane.size += Vector2.ONE * 2.0
	plane.center_offset.y = LIFT
	mesh = plane
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := ShaderMaterial.new()
	m.shader = MATERIAL
	m.set_shader_parameter("shape", shape)
	m.set_shader_parameter("reach", reach)
	m.set_shader_parameter("spread", spread)
	material_override = m


func _physics_process(delta: float) -> void:
	if bound != null and (not is_instance_valid(bound) or bound.is_dead):
		queue_free()
		return
	_age += delta
	if not _struck and _age >= delay:
		_struck = true
		bound = null
		_strike()
	var m := material_override as ShaderMaterial
	m.set_shader_parameter("progress", minf(_age / delay, 1.0))
	m.set_shader_parameter("gone", maxf(_age - delay, 0.0) / FADE)
	if _age >= delay + FADE:
		queue_free()


## Le miroir de `measure()` dans le shader : ce qui est dessiné est ce qui est frappé.
func contains(point: Vector3) -> bool:
	var p := point - global_position
	match shape:
		Shape.DISC:
			return p.length() <= reach
		Shape.LANE:
			var along := p.dot(facing)
			return along >= 0.0 and along <= reach and absf(p.dot(Flat.orthogonal(facing))) <= spread
	return p.length() <= reach and p.dot(facing) > 0.0 and absf(Flat.angle_to(facing, p)) <= spread


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
	for hurtbox in Targets.in_circle(get_world_3d(), global_position, reach, Targets.PLAYER_SIDE):
		if contains(hurtbox.global_position):
			var info := DamageInfo.as_parts(parts, global_position, knockback)
			info.author = author
			hurtbox.take_damage(info)

