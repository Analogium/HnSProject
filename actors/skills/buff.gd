class_name Buff
extends Node2D

## Un geste entretenu qui ne frappe rien : il draine une réserve par seconde et, tant
## qu'il brûle, ses lignes sont dans la fiche du porteur — c'est `Player` qui les y
## verse, ce nœud ne porte que le prix et le dessin.
##
## Il relit les points à chaque image, comme l'aura : un livre qui quitte le râtelier
## éteint ce qu'il enseignait.

const HALO := 9.0
const MOTES := 6
const RISE := 14.0

var _player: Player
var _skill: Skill
## Tout dans la nature du buff : il n'inflige rien, donc sa brûlure n'a qu'une part.
var _distribution: Array[float] = []
var _age := 0.0
## Zéro : il brûle jusqu'à ce qu'on l'éteigne. Sinon c'est ce qu'une ruée laisse
## derrière elle, en secondes.
var _lifetime := 0.0


static func light(player: Player, skill: Skill, lifetime := 0.0) -> Buff:
	var buff := Buff.new()
	buff._player = player
	buff._skill = skill
	buff._lifetime = lifetime
	buff._distribution = DamageType.empty_parts()
	buff._distribution[skill.nature] = 1.0
	player.add_child(buff)
	return buff


func _ready() -> void:
	material = ArtPalette.ADDITIVE


## Ce qu'il reste de sa durée, entre 0 et 1 ; **1 pour celui qui n'en a pas**, et qui
## brûle tant qu'on le paie.
func remaining_ratio() -> float:
	if _lifetime <= 0.0:
		return 1.0
	return clampf(1.0 - _age / _lifetime, 0.0, 1.0)


## Appelée par `Player.extinguish()`, le seul chemin : le joueur reprend ses lignes à
## la fiche au même moment.
func extinguish() -> void:
	set_physics_process(false)
	queue_free()


func _physics_process(delta: float) -> void:
	_age += delta
	if _player.skill_points(_skill.id) <= 0 or _player.is_dead:
		_player.extinguish(_skill.id)
		return
	if _lifetime > 0.0 and _age >= _lifetime:
		_player.extinguish(_skill.id)
		return
	# Le mana épuisé éteint ; les PV épuisés tuent (`Player.burn()`, mortelle).
	if not _player.drain(_skill.self_mana_burn, delta):
		_player.extinguish(_skill.id)
		return
	queue_redraw()
	_player.burn(_skill.self_burn, _distribution, delta)


## Discret : le buff dure des minutes, et ce qui clignote fort finit par fatiguer.
func _draw() -> void:
	var tint: Color = DamageType.COLORS[_skill.nature]
	var pulse := 0.5 + 0.5 * sin(_age * 3.0)
	draw_arc(Vector2.ZERO, HALO, 0.0, TAU, 24, Color(tint, 0.10 + 0.10 * pulse), 1.0)
	for i in MOTES:
		var rise := fmod(_age * 0.8 + float(i) * 0.163, 1.0)
		var angle := TAU * float(i) / float(MOTES) + _age * 0.6
		var p := Vector2.from_angle(angle) * HALO * 0.8 + Vector2(0.0, -rise * RISE)
		draw_rect(Rect2(p, Vector2.ONE), Color(tint.lerp(Color.WHITE, 0.4), 0.7 * (1.0 - rise)))
