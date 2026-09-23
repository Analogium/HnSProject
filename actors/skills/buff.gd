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
## Ce qu'on voit du porteur à travers son tombeau. À 1 il disparaît dans la glace,
## à 0,6 le bloc n'est plus qu'un reflet : c'est le seul dessin du jeu qu'on
## regarde **à travers**, et il se pose donc à alpha partiel.
const TOMB_ALPHA := 0.8

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
	# Le tombeau, la clarté sacrée et l'électricité sont **dessinés**, et une planche
	# cernée ne peut pas être additive : son contour sombre n'y ajoute rien. Les
	# braises d'Ignition sont encore tracées et gardent la lumière ajoutée.
	if not _skill.nature in [DamageType.Kind.COLD, DamageType.Kind.HOLY, DamageType.Kind.LIGHTNING]:
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
	if _skill.nature in [DamageType.Kind.HOLY, DamageType.Kind.LIGHTNING]:
		# Tramé plutôt que tracé : ces deux buffs sont dessinés de bout en bout.
		var span := int(HALO)
		draw_texture_rect(
			EffectForge.scorch(tint, span),
			Rect2(
				EffectForge.snap(self, -Vector2(span, span)), Vector2.ONE * float(span * 2 + 1)
			),
			false, Color(1.0, 1.0, 1.0, 0.5 + 0.5 * pulse)
		)
	else:
		Glow.draw_ring(self, Vector2.ZERO, HALO, Color(tint, 0.12 + 0.12 * pulse))
	for i in MOTES:
		var rise := fmod(_age * 0.8 + float(i) * 0.163, 1.0)
		var angle := TAU * float(i) / float(MOTES) + _age * 0.6
		var p := Vector2.from_angle(angle) * HALO * 0.8 + Vector2(0.0, -rise * RISE)
		# Ce qui monte a la matière du geste : des braises pour une combustion, des
		# flocons pour un froid, des grains pour une clarté ou une charge. Et rien
		# d'autre — ce geste dure des minutes, et ce qui clignote fort finit par fatiguer.
		#
		# Les grains **dessinés** montent à pleine opacité et s'éteignent d'un coup en
		# haut de leur course : trois pixels qui s'effacent s'éteignent en gris bien
		# avant d'avoir disparu. Les braises, tracées, gardent leur fondu.
		match _skill.nature:
			DamageType.Kind.FIRE:
				Fire.draw_ember(self, p, tint, 0.7 * (1.0 - rise))
			DamageType.Kind.COLD:
				Frost.drift(self, p, tint, 1.0)
			DamageType.Kind.HOLY:
				Holy.spark(self, p, tint, 1.0)
			DamageType.Kind.LIGHTNING:
				var grain := EffectForge.lightning_speck(tint)
				draw_texture(grain, EffectForge.snap(self, p - Vector2(grain.get_size()) * 0.5))
			_:
				draw_rect(Rect2(p, Vector2.ONE), Color(tint.lerp(Color.WHITE, 0.4), 0.7 * (1.0 - rise)))


## Le bloc de glace, **dessiné** : vingt et un pixels sur vingt-sept, posé à
## alpha partiel pour qu'on voie qui est dedans. Les six pans tracés d'avant
## faisaient un hexagone, pas un volume — ce qui manquait, ce sont les facettes et
## les fêlures, et aucune des deux ne se trace.
##
## Trois flocons qui montent le long du bloc : trois secondes d'image fixe se
## lisent comme un jeu figé.
func _tomb(tint: Color) -> void:
	var block := EffectForge.tomb(tint)
	var size := Vector2(block.get_width(), block.get_height())
	draw_texture_rect(
		block, Rect2(EffectForge.snap(self, -size * 0.5), size), false,
		Color(1.0, 1.0, 1.0, TOMB_ALPHA)
	)
	for i in 3:
		var rise := fmod(_age * 0.5 + float(i) * 0.33, 1.0)
		Frost.drift(
			self, Vector2((float(i) - 1.0) * 7.0, size.y * 0.5 - rise * size.y), tint, 1.0
		)
