class_name Buff
extends Node2D

## Un geste entretenu qui ne frappe rien : il draine une réserve par seconde et, tant
## qu'il brûle, ses lignes sont dans la fiche du porteur — c'est `Player` qui les y
## verse, ce nœud ne porte que le prix et le dessin.
##
## Il relit les points à chaque image, comme l'aura : un livre qui quitte le râtelier
## éteint ce qu'il enseignait.

const HALO := 9.0
## Le demi-côté du bloc de glace, en pixels : il couvre le corps sans mordre sur ses
## voisins.
const BLOCK := 11.0
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
	if not _player.drain(_skill.mana_per_second, delta):
		_player.extinguish(_skill.id)
		return
	queue_redraw()
	_player.mend(_skill.self_heal, delta)
	# En dernier : la brûlure peut tuer le porteur, qui éteint alors le buff.
	_player.burn(_skill.self_burn, _distribution, delta)


## Discret : le buff dure des minutes, et ce qui clignote fort finit par fatiguer.
## Sauf celui qui enferme : on ne bouge plus, et rien d'autre ne le dirait.
func _draw() -> void:
	var tint: Color = DamageType.COLORS[_skill.nature]
	if _skill.binds_caster:
		_tomb(tint)
		return
	var pulse := 0.5 + 0.5 * sin(_age * 3.0)
	Glow.draw_ring(self, Vector2.ZERO, HALO, Color(tint, 0.12 + 0.12 * pulse))
	for i in MOTES:
		var rise := fmod(_age * 0.8 + float(i) * 0.163, 1.0)
		var angle := TAU * float(i) / float(MOTES) + _age * 0.6
		var p := Vector2.from_angle(angle) * HALO * 0.8 + Vector2(0.0, -rise * RISE)
		# Ce qui monte a la matière du geste : des braises pour une combustion, des
		# flocons pour un froid. Et rien d'autre — ce geste dure des minutes, et ce
		# qui clignote fort finit par fatiguer.
		match _skill.nature:
			DamageType.Kind.FIRE:
				Fire.draw_ember(self, p, tint, 0.7 * (1.0 - rise))
			DamageType.Kind.COLD:
				Frost.draw_flake(self, p, tint, 0.7 * (1.0 - rise))
			_:
				draw_rect(Rect2(p, Vector2.ONE), Color(tint.lerp(Color.WHITE, 0.4), 0.7 * (1.0 - rise)))


## Le bloc de glace : six pans autour du porteur, cerclés de givre. Un disque plein
## l'aurait caché ; les pans laissent voir qu'il y a quelqu'un dedans.
func _tomb(tint: Color) -> void:
	var pans := PackedVector2Array()
	for i in 6:
		pans.append(Vector2.from_angle(TAU * float(i) / 6.0 - PI * 0.5) * Vector2(BLOCK, BLOCK * 1.3))
	draw_colored_polygon(pans, Color(tint, 0.18))
	# La facette éclairée, une moitié du bloc : la règle du cristal, appliquée à
	# grande taille. Sans elle, le tombeau est un hexagone et non un volume.
	draw_colored_polygon(PackedVector2Array([pans[0], pans[1], pans[2], pans[3]]), Color(tint, 0.20))
	draw_polyline(pans + PackedVector2Array([pans[0]]), Color(Frost.rim(tint), 0.9), 1.0)
	# Trois flocons qui montent le long du bloc : trois secondes d'hexagone immobile
	# se lisent comme une image figée.
	for i in 3:
		var rise := fmod(_age * 0.5 + float(i) * 0.33, 1.0)
		Frost.draw_flake(
			self, Vector2((float(i) - 1.0) * 7.0, BLOCK - rise * BLOCK * 2.0),
			tint, 0.7 * (1.0 - rise)
		)
