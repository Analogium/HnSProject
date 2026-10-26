class_name Buff
extends Node3D

## Un geste entretenu qui ne frappe rien : il draine une réserve par seconde et, tant
## qu'il brûle, ses lignes sont dans la fiche du porteur — c'est `Player` qui les y
## verse, ce nœud ne porte que le prix.
##
## Il relit les points à chaque image, comme l'aura : un livre qui quitte le râtelier
## éteint ce qu'il enseignait.

## Un buff qui n'est pas une aura n'a pas de portée : ses étincelles l'entourent, à ce rayon.
const HALO_SPARKS := 12.0
## Rien sur le porteur (jalon 54, choisi sur planche) : le champ statique brûle tout le combat, et
## les charges qu'il sème disent assez qu'il est allumé.
const BARE := ["static_electricity"]

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
## Depuis la dernière fois que l'Auréole a béni.
var _since_blessing := 0.0
## L'Ionisation (jalon 43) : depuis quand le champ n'a pas engourdi autour de lui.
var _since_ion := 0.0
## Le Halo de givre (jalon 44) : depuis quand il n'a pas transi autour de lui.
var _since_halo := 0.0
## L'Incarnation (jalon 49) : l'élément que prennent les sorts tant qu'il brûle, -1 sans
## elle ; le dernier sort converti, que l'Aura reprend ; depuis quand l'Aura n'a pas frappé.
var incarnation := -1
var last_spell: SkillStats
var _since_aura := 0.0
## Ce que l'Aura frappe, en points de pourcentage, relu à chaque période ; -1 avant la première
## lecture.
var _aura := -1.0
## Le Triple éclat (jalon 49) : les éléments lancés tant qu'il brûle.
var natures_cast := {}
## Le Contrecoup (jalon 49) compte le temps brûlé depuis l'allumage, que la Résonance ne
## rembobine pas ; elle compte ses prolongations, qui s'amenuisent.
var lived := 0.0
var _resonated := 0


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
	# L'appel du tonnerre d'une ruée de foudre : des arcs aux pieds plutôt que le halo ; le Tombeau, sa gangue.
	if skill.shape == Skill.Shape.DASH and skill.nature == DamageType.Kind.LIGHTNING:
		BoltFx.feet(buff)
	elif skill.id == SkillStats.TOMB_SKILL:
		FrostTombFx.encase(buff, skill.nature)
	elif skill.id not in BARE:
		var reach := SkillStats.AURA_REACH if skill.shape == Skill.Shape.AURA else HALO_SPARKS
		ElementFx.area(buff, DamageType.COLORS[skill.nature], reach)
	return buff


## Depuis quand il brûle : la Dévotion (jalon 48) monte avec.
func age() -> float:
	return _age


## Les secondes qu'il lui reste ; zéro pour celui qui n'a pas de fin (le Brise-glace, jalon 44).
func remaining() -> float:
	return maxf(_lifetime - _age, 0.0) if _lifetime > 0.0 else 0.0


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


## Le Galop (jalon 43) : des charges posées d'un coup, sur un buff qui n'en porte pas
## d'ordinaire, et qui tiennent ce temps.
func hold_stacks(count: int, seconds: float) -> void:
	stacks = count
	_since_stack = 0.0
	_hold = seconds


## L'Ivresse du sang et la Patience (jalon 50) : les charges regagnent ces secondes, jamais
## au-delà de leur tenue entière.
func revive(seconds: float) -> void:
	_since_stack = maxf(_since_stack - seconds, 0.0)


## Le Coup de grâce (jalon 50) : retire ses charges et rend combien il en a pris. Le joueur
## refait sa fiche : les lignes comptaient par charge.
func spend(count: int) -> int:
	var spent := mini(count, stacks)
	stacks -= spent
	return spent


## Le plafond des charges et leur tenue : **le seul calcul**, que la fiche lit aussi.
static func cap_of(skill: Skill, own: SkillStats) -> int:
	if own == null:
		return skill.stacks_max
	return skill.stacks_max + int(own.dissonance) + int(own.bottomless) \
		+ (SkillStats.BERSERK_CHARGES if own.berserk > 0.0 else 0)


static func hold_of(skill: Skill, own: SkillStats) -> float:
	return skill.stack_duration + (own.stack_hold if own != null else 0.0)


## À l'échéance, toutes ensemble — ou une à une sous le Rubato (jalon 49), chacune
## `RUBATO_STEP` après la précédente.
func _drop_stacks() -> void:
	var own := _player.resolve(_skill, _player.skill_points(_skill.id))
	if own.rubato > 0.0:
		stacks -= 1
		_since_stack = _hold - SkillStats.RUBATO_STEP
	# Le Dernier carré (jalon 50) : la moitié reste, et repart pour une tenue.
	elif own.last_stand > 0.0 and stacks > 1:
		stacks /= 2
		_since_stack = 0.0
	else:
		stacks = 0
	_player.after_buff_change()


## La Résonance (jalon 41) : un buff lancé regagne ces secondes, jamais au-delà de sa
## durée entière.
func prolong(seconds: float) -> void:
	if _lifetime > 0.0:
		_age = maxf(_age - seconds, 0.0)


## La Couronne de queues du Roi des Rats (jalon 53) : sa durée s'allonge, au-delà de la première.
func lengthen(seconds: float) -> void:
	if _lifetime > 0.0:
		_lifetime += seconds


## La Résonance : chaque prolongation vaut `RESONANCE_DECAY` de la précédente (jalon 49).
func resonate(seconds: float) -> void:
	prolong(seconds * pow(SkillStats.RESONANCE_DECAY, _resonated))
	_resonated += 1


## Appelée par `Player.extinguish()`, le seul chemin : le joueur reprend ses lignes à
## la fiche au même moment.
func extinguish() -> void:
	set_physics_process(false)
	queue_free()


func _physics_process(delta: float) -> void:
	_age += delta
	lived += delta
	if _player.skill_points(_skill.id) <= 0 or _player.is_dead:
		_player.extinguish(_skill.id)
		return
	if _lifetime > 0.0 and _age >= _lifetime:
		_player.extinguish(_skill.id)
		return
	if stacks > 0:
		_since_stack += delta
		if _since_stack >= _hold:
			_drop_stacks()
	_radiate(delta)
	# Le lancer résolu et non la compétence : un nœud d'arbre change sa brûlure (jalon 34),
	# son drain (jalon 35), son soin (jalon 36) et ce qu'il ronge (jalon 38).
	var cast: SkillStats = null
	if _skill.self_burn + _skill.mana_per_second + _skill.self_heal + _skill.self_wither > 0.0:
		cast = _player.resolve(_skill, _player.skill_points(_skill.id))
	# Le mana épuisé éteint ; les PV épuisés tuent (`Player.burn()`, mortelle).
	if not _player.drain(cast.mana_per_second if cast != null else 0.0, delta):
		_player.extinguish(_skill.id)
		return
	_player.mend(cast.self_heal if cast != null else 0.0, delta)
	# En dernier : la brûlure peut tuer le porteur, qui éteint alors le buff. Ce qu'il
	# ronge des PV **actuels** s'y ramène en part des PV max, et ne tue donc jamais.
	var withered := 0.0
	var burning := 0.0
	if cast != null:
		withered = cast.self_wither * _player.health / maxf(_player.stats.max_health, 1.0)
		# Le Moribond (jalon 45) : à bout de vie, elle ne ronge plus.
		if cast.moribund > 0.0 and _player.health < _player.stats.max_health * SkillStats.MORIBUND_LIFE:
			withered = 0.0
		burning = cast.self_burn
		_share_the_burden(cast, withered * _player.stats.max_health * delta, delta)
		_bless(cast, delta)
		_ionize(cast, delta)
		_halo(cast, delta)
		# L'Hibernation (jalon 44) : les recharges des autres courent plus vite tant qu'il tient.
		_player._hasten(delta * cast.hibernation * 0.01)
	_player.burn(burning + withered, _distribution, delta)


## L'Aura (jalon 49) : sous l'Incarnation, chaque période, ce qui entoure le porteur prend un
## coup de son élément, une part du dernier sort converti, qui pose son état à coup sûr.
func _radiate(delta: float) -> void:
	if incarnation < 0 or last_spell == null:
		return
	if _aura < 0.0:
		_aura = _player.resolve(_skill, _player.skill_points(_skill.id)).aura
	_since_aura += delta
	if _since_aura < SkillStats.AURA_PERIOD:
		return
	_since_aura = 0.0
	_aura = _player.resolve(_skill, _player.skill_points(_skill.id)).aura
	if _aura <= 0.0:
		return
	var hit := last_spell.echoed(_aura * 0.01)
	hit.status_chance_increase += SkillStats.SURE_STATE
	for target in Targets.in_circle(get_world_3d(), _player.global_position, SkillStats.AURA_REACH):
		Targets.strike(target, hit.roll(Game.rng), _player.global_position, _player.states, hit)


## L'Ionisation (jalon 43) : à chaque période, chaque ennemi proche a sa chance d'être
## engourdi — un tirage par ennemi, de quoi semer des charges sans autre sort.
func _ionize(cast: SkillStats, delta: float) -> void:
	if cast.ionize <= 0.0:
		return
	_since_ion += delta
	if _since_ion < SkillStats.IONIZE_PERIOD:
		return
	_since_ion = 0.0
	BoltFx.pulse(self, SkillStats.IONIZE_RADIUS)
	for target in Targets.in_circle(get_world_3d(), _player.global_position, SkillStats.IONIZE_RADIUS):
		if target.states != null and Game.rng.randf() * 100.0 < cast.ionize:
			target.states.put(
				StatusEffects.Kind.NUMB, 1.0, _player.states, _skill.id,
				cast.strength_of(StatusEffects.Kind.NUMB)
			)


## Le Halo de givre (jalon 44) : à chaque période, ce qui est autour du porteur est transi,
## sans coup, à la force du nœud ; une onde de givre le montre (`FrostTombFx.pulse()`).
func _halo(cast: SkillStats, delta: float) -> void:
	if cast.rime_halo <= 0.0:
		return
	_since_halo += delta
	if _since_halo < SkillStats.HALO_PERIOD:
		return
	_since_halo = 0.0
	for target in Targets.in_circle(get_world_3d(), _player.global_position, SkillStats.HALO_RADIUS):
		if target.states != null:
			target.states.put(StatusEffects.Kind.CHILL, 0.0, _player.states, _skill.id, cast.rime_halo * 0.01)
	FrostTombFx.pulse(self, SkillStats.HALO_RADIUS, _skill.nature)


## Le Fardeau partagé (jalon 38) : ce que la Nécrose a rongé, rendu aux ennemis proches
## par le souffle d'une explosion — qui frappe et se dessine déjà dans la nature du buff.
func _share_the_burden(cast: SkillStats, gnawed: float, delta: float) -> void:
	if cast.shared_burden <= 0.0:
		return
	_burden += gnawed
	_since_burden += delta
	if _since_burden >= SkillStats.BURDEN_PERIOD:
		unburden(cast)


## Le Fardeau part maintenant : à sa période, ou sur un gros coup reçu (l'Exutoire, jalon 45).
## L'explosion naît en différé : un coup reçu arrive d'un rappel de collision.
func unburden(cast: SkillStats) -> void:
	if cast.shared_burden <= 0.0 or _burden <= 0.0:
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
## Elle ne frappe pas — comme la malédiction, elle pose l'état elle-même. Sauf sous la Gloire
## (jalon 48), qui frappe ce qu'elle bénit d'une part des PV max ; l'Humilité y fond la
## résistance au sacré.
func _bless(cast: SkillStats, delta: float) -> void:
	if cast.aureole <= 0.0:
		return
	_since_blessing += delta
	if _since_blessing < SkillStats.AUREOLE_PERIOD:
		return
	_since_blessing = 0.0
	var strength := cast.strength_of(StatusEffects.Kind.BLESSING)
	var glory := DamageType.empty_parts()
	glory[cast.nature] = _player.stats.max_health * cast.glory * 0.01
	for target in Targets.in_circle(get_world_3d(), _player.global_position, cast.aureole):
		if target.states != null:
			target.states.put(StatusEffects.Kind.BLESSING, 0.0, _player.states, cast.skill_id, strength)
			if cast.humility > 0.0:
				target.states.melt(cast.humility, StatusEffects.Kind.BLESSING)
		if cast.glory > 0.0:
			Targets.strike(target, glory, _player.global_position, _player.states, cast)

