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

## Les lames qui tournent, et leur vitesse en radians par seconde.
const BLADES := 3
const SPIN := 4.0
## Ce que chaque lame traîne derrière elle, en radians, et son épaisseur.
const TRAIL := 0.9
const THICKNESS := 7.0
## Ce qui vole autour : les éclats soulevés par le tour.
const MOTES := 8
const OPENING := 0.12

var _player: Player
var _skill: Skill
var _cast: SkillStats
var _age := 0.0
var _next_threshold := 0.0
## Les Derviches (jalon 46) : l'heure du prochain.
var _next_dervish := 0.0


static func spin(player: Player, skill: Skill) -> Cyclone:
	var node := Cyclone.new()
	node._player = player
	node._skill = skill
	player.add_child(node)
	Settings.veil(node, Settings.SPELLS)
	return node


## Pas de lumière ajoutée : les lames sont **dessinées**, et une planche cernée ne
## peut pas être additive — son contour sombre n'y ajoute rien.
func _ready() -> void:
	z_index = 2


## Appelée par `Player.extinguish()`, le seul chemin. Le Dénouement (jalon 46) : relâché,
## le tour frappe une dernière fois, d'autant plus fort qu'il a tourné longtemps.
func extinguish() -> void:
	if _cast != null and _cast.denouement > 0.0 and not _player.is_dead:
		var spun := minf(_age, SkillStats.DENOUEMENT_MOST)
		Targets.strike_circle(
			get_world_2d(), global_position, _cast.radius, _cast, _player.states,
			SkillStats.GUST_FORCE if _cast.gust > 0.0 else 0.0,
			1.0 + _cast.denouement * 0.01 * spun
		)
	set_physics_process(false)
	queue_free()


## La Ronde folle (jalon 46), que les épées de l'Épée spirale lisent tant qu'il tourne.
func madness() -> float:
	return _cast.mad_round if _cast != null else 0.0


func _physics_process(delta: float) -> void:
	var points := _player.skill_points(_skill.id)
	if points <= 0 or _player.is_dead:
		# Par le joueur : c'est lui qui tient la liste des allumés (invariant 5).
		_player.extinguish(_skill.id)
		return
	_age += delta
	if _cast == null or _age >= _next_threshold:
		_cast = _player.resolve(_skill, points)
		# Le Vertige (jalon 46) : chaque seconde tournée rapproche les frappes.
		var vertigo := 1.0 + _cast.vertigo * 0.01 * minf(_age, SkillStats.VERTIGO_MOST)
		_next_threshold = _age + _cast.period / vertigo
		_strike()
	if _cast.dervishes > 0.0 and _age >= _next_dervish:
		_next_dervish = _age + SkillStats.DERVISH_PERIOD
		_loose()
	queue_redraw()
	if not _player.drain(_cast.mana_per_second, delta):
		_player.extinguish(_skill.id)
		return
	# Les deux prix, comme un buff : une lame qui coûterait des PV se règle dans le
	# `.tres` et non ici. En dernier — la brûlure peut tuer le porteur.
	_player.burn(_cast.self_burn, _cast.distribution(), delta)


## Tourbillon (jalon 39) tire vers le cœur, comme le vortex ; Fauche vorace rend du mana
## par ennemi pris dans le tour.
func _strike() -> void:
	var struck := Targets.strike_circle(
		get_world_2d(), global_position, _cast.radius, _cast, _player.states, -_cast.pull
	)
	_player.gain_mana(_cast.mana_on_hit * float(struck.size()))


## Les Derviches (jalon 46) : de petits tours qui partent droit devant le porteur, en éventail
## sous le Sirocco.
func _loose() -> void:
	var count := 1 + int(_cast.sirocco)
	for i in count:
		var turn := (float(i) - float(count - 1) * 0.5) * SkillStats.DERVISH_FAN
		Dervish.send(
			_player._effects_parent(), global_position, _player.facing.rotated(turn), _cast,
			_player.states
		)


## Des lames en rotation plutôt qu'un disque : c'est le mouvement qui dit « ça tourne »,
## et un cercle plein au sol se lirait comme une aura de plus. Chaque lame est le
## croissant d'un coup, tête devant : trois coups qui se poursuivent.
##
## Pas d'anneau au sol : le bout des lames dit déjà jusqu'où il fauche.
func _draw() -> void:
	if _cast == null:
		return
	var r := floorf(_cast.radius * minf(_age / OPENING, 1.0))
	if r < THICKNESS:
		return
	var tint: Color = DamageType.COLORS[_cast.nature]
	for i in BLADES:
		var turn := Slash.turn_of(TAU * float(i) / float(BLADES) + _age * SPIN)
		Slash.crescent(tint, r, THICKNESS, turn, -TRAIL, 0.0, 0.0).put(self, Vector2.ZERO)

	var grain := EffectForge.spark(tint)
	for i in MOTES:
		var turn := _age * SPIN * 0.6 + TAU * float(i) / float(MOTES)
		var distance := r * (0.4 + 0.55 * fmod(_age * 0.9 + float(i) * 0.121, 1.0))
		EffectForge.put_centered(self, grain, Vector2.from_angle(turn) * distance)
