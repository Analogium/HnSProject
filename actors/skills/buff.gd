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
## L'Auréole, « couronne de grains » choisie sur planche (jalon 40) : l'écart entre deux
## grains, gardé à tout rayon — à 20 px, trente-six grains feraient un anneau plein —,
## leur écart au cercle, qui casse la palissade, et la vitesse du tour en radians/s.
const CROWN_SPACING := 10.5
const CROWN_JITTER := [0.0, 2.0, -1.0, 1.0, -2.0, 0.5]
const CROWN_TURN := 0.3
const DRAWN := [
	DamageType.Kind.COLD, DamageType.Kind.HOLY, DamageType.Kind.LIGHTNING,
	DamageType.Kind.NECROTIC,
]

var _player: Player
var _skill: Skill
## Tout dans la nature du buff : il n'inflige rien, donc sa brûlure n'a qu'une part.
var _distribution: Array[float] = []
var _age := 0.0
## Zéro : il brûle jusqu'à ce qu'on l'éteigne. Sinon, en secondes, ce qu'une ruée
## laisse derrière elle ou ce que dure un buff lancé.
var _lifetime := 0.0
## Les charges d'un buff à charges (`Skill.stacks_max`), depuis quand la dernière, et ce
## qu'elles tiennent depuis elle.
var stacks := 0
var _since_stack := 0.0
var _hold := 0.0
## Enferme-t-il son porteur : celui du lancer, qu'un nœud affranchit (l'Armure de givre).
var binds := false
## Ce que la Nécrose a rongé depuis le dernier Fardeau partagé, en PV, et depuis quand.
var _burden := 0.0
var _since_burden := 0.0
## Depuis la dernière fois que l'Auréole a béni, et son rayon, pour le dessin.
var _since_blessing := 0.0
var _aureole := 0.0


static func light(player: Player, skill: Skill, lifetime := 0.0, binds := false) -> Buff:
	var buff := Buff.new()
	buff.binds = binds
	buff._player = player
	buff._skill = skill
	buff._lifetime = lifetime
	buff._distribution = DamageType.empty_parts()
	buff._distribution[skill.nature] = 1.0
	player.add_child(buff)
	Settings.veil(buff, Settings.SPELLS)
	return buff


func _ready() -> void:
	# Le tombeau, la clarté sacrée, l'électricité et la nécrose sont **dessinés**, et une
	# planche cernée ne peut pas être additive : son contour sombre n'y ajoute rien. Les
	# braises d'Ignition sont encore tracées et gardent la lumière ajoutée.
	if not _skill.nature in DRAWN:
		material = ArtPalette.ADDITIVE


## Ce qu'il reste de sa durée, entre 0 et 1 ; celle de ses charges s'il en porte ; **1
## pour celui qui n'en a pas**, et qui brûle tant qu'on le paie.
func remaining_ratio() -> float:
	if stacks > 0:
		return clampf(1.0 - _since_stack / _hold, 0.0, 1.0)
	if _lifetime <= 0.0:
		return 1.0
	return clampf(1.0 - _age / _lifetime, 0.0, 1.0)


## Une charge de plus, jusqu'au plafond, et **toutes** repartent pour leur durée. Faux
## pour un buff qui n'en porte pas, ou que ce déclencheur ne charge pas. `own` : son
## lancer résolu, dont l'arbre peut hausser le plafond et la tenue (jalon 41).
func stack(trigger: Skill.StackTrigger, own: SkillStats = null) -> bool:
	if _skill.stacks_max <= 0 or _skill.stack_trigger != trigger:
		return false
	stacks = mini(stacks + 1, cap_of(_skill, own))
	_since_stack = 0.0
	_hold = hold_of(_skill, own)
	return true


## Le plafond des charges et leur tenue : **le seul calcul**, que la fiche lit aussi.
static func cap_of(skill: Skill, own: SkillStats) -> int:
	return skill.stacks_max + (int(own.dissonance) if own != null else 0)


static func hold_of(skill: Skill, own: SkillStats) -> float:
	return skill.stack_duration + (own.stack_hold if own != null else 0.0)


## La Résonance (jalon 41) : un buff lancé regagne ces secondes, jamais au-delà de sa
## durée entière.
func prolong(seconds: float) -> void:
	if _lifetime > 0.0:
		_age = maxf(_age - seconds, 0.0)


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
	if stacks > 0:
		_since_stack += delta
		if _since_stack >= _hold:
			stacks = 0
			_player.after_buff_change()
	# Le lancer résolu et non la compétence : un nœud d'arbre change sa brûlure (jalon 34),
	# son drain (jalon 35), son soin (jalon 36) et ce qu'il ronge (jalon 38).
	var cast: SkillStats = null
	if _skill.self_burn + _skill.mana_per_second + _skill.self_heal + _skill.self_wither > 0.0:
		cast = _player.resolve(_skill, _player.skill_points(_skill.id))
	# Le mana épuisé éteint ; les PV épuisés tuent (`Player.burn()`, mortelle).
	if not _player.drain(cast.mana_per_second if cast != null else 0.0, delta):
		_player.extinguish(_skill.id)
		return
	queue_redraw()
	_player.mend(cast.self_heal if cast != null else 0.0, delta)
	# En dernier : la brûlure peut tuer le porteur, qui éteint alors le buff. Ce qu'il
	# ronge des PV **actuels** s'y ramène en part des PV max, et ne tue donc jamais.
	var withered := 0.0
	var burning := 0.0
	if cast != null:
		withered = cast.self_wither * _player.health / maxf(_player.stats.max_health, 1.0)
		burning = cast.self_burn
		_share_the_burden(cast, withered * _player.stats.max_health * delta, delta)
		_bless(cast, delta)
	_player.burn(burning + withered, _distribution, delta)


## Le Fardeau partagé (jalon 38) : ce que la Nécrose a rongé, rendu aux ennemis proches
## par le souffle d'une explosion — qui frappe et se dessine déjà dans la nature du buff.
func _share_the_burden(cast: SkillStats, gnawed: float, delta: float) -> void:
	if cast.shared_burden <= 0.0:
		return
	_burden += gnawed
	_since_burden += delta
	if _since_burden < SkillStats.BURDEN_PERIOD:
		return
	var parts := DamageType.empty_parts()
	parts[cast.nature] = _burden * SkillStats.BURDEN_FACTOR
	_burden = 0.0
	_since_burden = 0.0
	Explosion.put(
		_player._effects_parent(), _player.global_position, parts, cast.shared_burden, null,
		DamageType.COLORS[cast.nature], _player.states, cast
	)


## L'Auréole (jalon 40) : ce qui entre dans son cercle est béni, pour la durée de l'état.
## Elle ne frappe pas — comme la malédiction, elle pose l'état elle-même.
func _bless(cast: SkillStats, delta: float) -> void:
	_aureole = cast.aureole
	if _aureole <= 0.0:
		return
	_since_blessing += delta
	if _since_blessing < SkillStats.AUREOLE_PERIOD:
		return
	_since_blessing = 0.0
	var strength := cast.strength_of(StatusEffects.Kind.BLESSING)
	for target in Targets.in_circle(get_world_2d(), _player.global_position, _aureole):
		if target.states != null:
			target.states.put(StatusEffects.Kind.BLESSING, 0.0, _player.states, cast.skill_id, strength)


## Discret : le buff dure des minutes, et ce qui clignote fort finit par fatiguer.
## Sauf celui qui enferme : on ne bouge plus, et rien d'autre ne le dirait.
func _draw() -> void:
	var tint: Color = DamageType.COLORS[_skill.nature]
	if binds:
		_tomb(tint)
		return
	var pulse := 0.5 + 0.5 * sin(_age * 3.0)
	if _skill.nature in [DamageType.Kind.HOLY, DamageType.Kind.LIGHTNING]:
		# Tramé plutôt que tracé : ces deux buffs sont dessinés de bout en bout.
		EffectForge.put_scorch(self, tint, int(HALO), 0.5 + 0.5 * pulse)
	# La nécrose n'a pas de halo : elle ne rayonne pas, elle ronge — ses spores suffisent.
	elif _skill.nature != DamageType.Kind.NECROTIC:
		Glow.draw_ring(self, Vector2.ZERO, HALO, Color(tint, 0.12 + 0.12 * pulse))
	for i in MOTES:
		var rise := fmod(_age * 0.8 + float(i) * 0.163, 1.0)
		var angle := TAU * float(i) / float(MOTES) + _age * 0.6
		var p := Vector2.from_angle(angle) * HALO * 0.8 + Vector2(0.0, -rise * RISE)
		# Ce qui monte a la matière du geste : des braises pour une combustion, des
		# flocons pour un froid, des grains pour une clarté ou une charge, des spores
		# pour ce qui ronge. Et rien
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
				EffectForge.put_centered(self, EffectForge.lightning_speck(tint), p)
			DamageType.Kind.NECROTIC:
				Necrotic.centered(self, EffectForge.spore(tint), p)
			_:
				draw_rect(Rect2(p, Vector2.ONE), Color(tint.lerp(Color.WHITE, 0.4), 0.7 * (1.0 - rise)))
	if _aureole > 0.0:
		_crown(tint)


## Un grain de lumière sur deux, un pixel de son cœur entre eux : grand et petit en
## alternance, qui tournent lentement sur le cercle où l'Auréole bénit.
func _crown(tint: Color) -> void:
	var count := maxi(roundi(TAU * _aureole / CROWN_SPACING), 6)
	for i in count:
		var p := Vector2.from_angle(TAU * float(i) / float(count) + _age * CROWN_TURN) \
			* (_aureole + float(CROWN_JITTER[i % CROWN_JITTER.size()]))
		if i % 2 == 0:
			Holy.spark(self, p, tint, 1.0)
		else:
			draw_rect(Rect2(EffectForge.snap(self, p), Vector2.ONE), Holy.halo(tint))


## Le bloc de glace, **dessiné** : vingt et un pixels sur vingt-sept, posé à
## alpha partiel pour qu'on voie qui est dedans. Les six pans tracés d'avant
## faisaient un hexagone, pas un volume — ce qui manquait, ce sont les facettes et
## les fêlures, et aucune des deux ne se trace.
##
## Trois flocons qui montent le long du bloc : trois secondes d'image fixe se
## lisent comme un jeu figé.
func _tomb(tint: Color) -> void:
	var block := EffectForge.tomb(tint)
	var size := Vector2(block.get_size())
	EffectForge.put_centered(self, block, Vector2.ZERO, TOMB_ALPHA)
	for i in 3:
		var rise := fmod(_age * 0.5 + float(i) * 0.33, 1.0)
		Frost.drift(
			self, Vector2((float(i) - 1.0) * 7.0, size.y * 0.5 - rise * size.y), tint, 1.0
		)
