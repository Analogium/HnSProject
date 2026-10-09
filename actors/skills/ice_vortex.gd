class_name IceVortex
extends Node2D

## Le vortex de Désastre hivernal : posé sur le personnage, il **grandit pendant toute
## sa durée** et frappe son cercle à chaque période. C'est la croissance qui le sépare du
## nuage d'orage : on le pose tôt, il paie tard.
##
## Il ne fige jamais le jeu — une impulsion qui gèle toutes les demi-secondes hacherait
## l'image tant qu'il tourne.

## Le rayon de départ, en part du rayon final : sous un tiers, ses premières impulsions
## ne toucheraient que ce qui est déjà sur le personnage.
const SEED_PART := 0.35
## Les bras de la spirale, leur vitesse en tours par seconde, et ce qu'ils
## balaient d'angle du cœur au bord — c'est cet écart qui fait l'enroulement.
##
## **Douze et non quatre** (choisi sur planche, jalon 24) : au cœur ils se touchent
## et font une roue pleine, ce qui donne enfin un œil au tourbillon. À quatre, on
## voyait quatre traits qui tournaient.
const ARMS := 12
const SPIN := 1.6
const SWEEP := 2.2
## Ce qui sépare deux éclats d'un bras, au plus serré : plus espacés, les bras se
## lisent comme des colliers de perles — le défaut qu'avait le dos du serpent.
const CHIP_STEP := 3.0
## Les flocons aspirés vers le cœur, hors des bras.
const FLAKES := 8
const FADE := 0.4
## L'Implosion (jalon 36) : jusqu'où elle se resserre avant d'éclater de tout son rayon,
## et combien d'impulsions vaut l'éclatement — à 1, elle rendait ×0,43 du meilleur
## Désastre au paquet (banc des arbres, jalon 37).
const IMPLODED_PART := 0.15
const IMPLOSION_BURST := 4.0

## Ceux qui tournent, pour la Cristallisation (jalon 44).
static var _live: Array[IceVortex] = []

var _cast: SkillStats
var _author: StatusEffects
## Le temps de sa croissance : la durée de son lancer, que la Cristallisation allonge sans
## le faire rétrécir.
var _grow := 0.0
var _fed := false
var _tint := Color.WHITE
var _age := 0.0
var _strikes := 0
## La Boule de neige (jalon 44) : le rayon gagné, en part, `SNOWBALL_MOST` au plus.
var _swell := 0.0
## La Coulée : où il roule, et où l'Ornière a posé son dernier sol.
var _aim := Vector2.ZERO
var _rut_at := Vector2.ZERO
## Le Givrage : combien de fois chaque ennemi a vu son transi renforcé.
var _frosted := {}


static func open(
	parent: Node, point: Vector2, cast: SkillStats, author: StatusEffects, aim := point
) -> IceVortex:
	_live.assign(_live.filter(func(v) -> bool: return is_instance_valid(v) and not v.is_queued_for_deletion()))
	var vortex := IceVortex.new()
	_live.append(vortex)
	vortex._cast = cast
	vortex._grow = cast.duration
	vortex._author = author
	vortex._tint = DamageType.COLORS[cast.nature]
	parent.add_child(vortex)
	Settings.veil(vortex, Settings.SPELLS)
	vortex.global_position = point
	vortex._aim = aim
	vortex._rut_at = point
	return vortex


## Pas de lumière ajoutée : les éclats sont **dessinés**, et une planche cernée
## ne peut pas être additive — son contour sombre n'y ajoute rien.
func _ready() -> void:
	z_index = 3


## La Cristallisation (jalon 44) : des pics lancés dans un vortex du même lanceur lui rendent
## du temps, jusqu'à deux fois sa durée. Sa copie du lancer, à la première fois : le
## lancer posé n'est pas à lui seul.
static func feed(point: Vector2, author: StatusEffects, seconds: float) -> void:
	for v in _live:
		if is_instance_valid(v) and v._author == author \
				and point.distance_to(v.global_position) <= v.reach():
			if not v._fed:
				v._cast = v._cast.echoed(1.0)
				v._fed = true
			v._cast.duration = minf(v._cast.duration + seconds, v._grow * 2.0)


## L'Accalmie (jalon 44) : ce qu'elle retire aux dégâts subis de son lanceur, s'il se tient
## dans l'œil d'un de ses vortex — la part centrale de l'Œil du brasier.
static func calm_for(point: Vector2, author: StatusEffects) -> float:
	for v in _live:
		if is_instance_valid(v) and v._author == author and v._cast.lull > 0.0 \
				and point.distance_to(v.global_position) <= v.reach() * SkillStats.EYE_PART:
			return v._cast.lull
	return 0.0


## Ce qu'il couvre maintenant : de `SEED_PART` à son rayon plein, linéairement — et ce que
## la Boule de neige y ajoute.
func reach() -> float:
	var grown := clampf(_age / _grow, 0.0, 1.0) if _grow > 0.0 else 1.0
	if _cast.shape == Skill.Shape.IMPLOSION:
		return _cast.radius * lerpf(1.0, IMPLODED_PART, grown) * (1.0 + _swell)
	return _cast.radius * lerpf(SEED_PART, 1.0, grown) * (1.0 + _swell)


## Les impulsions se comptent par `strikes_over_duration()`, la fonction même de
## l'estimation : la fiche et le vortex ne peuvent pas annoncer deux nombres.
func _physics_process(delta: float) -> void:
	_age += delta
	if _cast.slide > 0.0:
		_roll(delta)
	var due := _cast.strikes_due(_age)
	while _strikes < due:
		_strike()
		_strikes += 1
	queue_redraw()
	if _age >= _cast.duration and _strikes >= _cast.strikes_over_duration():
		_end()
		queue_free()


## La Coulée (jalon 44) : il roule vers le point visé et s'y arrête ; un mur l'arrête aussi.
## L'Ornière pose un sol chaque fois qu'il a roulé deux rayons de sol.
func _roll(delta: float) -> void:
	var next := global_position.move_toward(_aim, SkillStats.SLIDE_SPEED * delta)
	if not Targets.in_sight(get_world_2d(), global_position, next):
		_aim = global_position
		return
	global_position = next
	if _cast.rut > 0.0 and global_position.distance_to(_rut_at) >= SkillStats.GROUND_RADIUS * 2.0:
		_rut_at = global_position
		var rut := _cast.ground()
		rut.duration = _cast.rut
		DashTrail.patch(get_parent(), global_position, rut, _author)


## L'Implosion éclate de tout son rayon, de deux sous la Singularité (jalon 44).
func _end() -> void:
	if _cast.shape != Skill.Shape.IMPLOSION:
		return
	var parts := DamageType.scaled(_cast.roll(Game.rng), IMPLOSION_BURST)
	var burst := _cast.radius * (SkillStats.SINGULARITY_REACH if _cast.singularity > 0.0 else 1.0)
	Explosion.put(get_parent(), global_position, parts, burst, null, _tint, _author, _cast)


## Un tirage par impulsion (invariant 3). L'Aspiration tire vers le cœur par un recul
## inversé, deux fois plus fort sur un engourdi sous la Supraconduction, qui le transit
## aussi ; la Meule mord plus fort au cœur ; le Givrage renforce un transi déjà posé ; la
## Boule de neige grossit de chaque ennemi frappé (jalon 44).
func _strike() -> void:
	var parts := _cast.roll(Game.rng)
	var milled := DamageType.scaled(parts, 1.0 + _cast.mill * 0.01)
	var targets := Targets.in_circle(get_world_2d(), global_position, reach())
	for target in targets:
		var numbed := _cast.superconduct > 0.0 and target.has_state(StatusEffects.Kind.NUMB)
		var at_core := target.global_position.distance_to(global_position) <= SkillStats.MILL_CORE
		Targets.strike(
			target, milled if at_core else parts, global_position, _author, _cast,
			-_cast.pull * (2.0 if numbed else 1.0)
		)
		if numbed:
			target.states.put(
				StatusEffects.Kind.CHILL, 0.0, _author, _cast.skill_id,
				_cast.strength_of(StatusEffects.Kind.CHILL)
			)
		if _cast.frosting > 0.0:
			_frost(target)
	_swell = minf(_swell + _cast.snowball * 0.01 * float(targets.size()), SkillStats.SNOWBALL_MOST)


## Le Givrage : un transi déjà posé gagne en force, `FROSTING_MOST` fois par ennemi.
func _frost(target: Hurtbox) -> void:
	if not target.has_state(StatusEffects.Kind.CHILL):
		return
	var id := target.get_instance_id()
	var times := mini(int(_frosted.get(id, 0)) + 1, SkillStats.FROSTING_MOST)
	_frosted[id] = times
	target.states.put(
		StatusEffects.Kind.CHILL, 0.0, _author, _cast.skill_id,
		_cast.strength_of(StatusEffects.Kind.CHILL) * (1.0 + _cast.frosting * 0.01 * float(times))
	)


## Un tourbillon, et non un cercle de pics : quatre bras d'éclats **couchés sur
## leur cap**, et des flocons aspirés vers le cœur. C'est l'orientation des éclats
## qui dit que ça tourne ; tous pointés en haut, ce ne serait qu'une chute de neige.
##
## Pas de givre au sol sous celui-ci, contrairement aux pics et à la nova : un
## tourbillon ne se pose pas, et son rayon change à chaque image — une trame par
## rayon entier se recalculerait cinquante fois par lancer.
func _draw() -> void:
	var r := reach()
	var fade := clampf((_cast.duration - _age) / (_cast.duration * FADE), 0.0, 1.0)
	var steps := maxi(int(r / CHIP_STEP), 2)
	for i in ARMS:
		var base := TAU * float(i) / float(ARMS) + _age * SPIN
		for step in steps:
			# Il ne pâlit pas, il se **vide**. Un éclat en moins se lit comme un éclat
			# en moins ; un éclat à demi transparent sur un sol sombre sort gris, le
			# même piège que l'orange peu opaque du feu. Le tirage ne dépend que du
			# bras et du rang : c'est une trame, pas un scintillement.
			if fmod(float(step) * 0.618 + float(i) * 0.37, 1.0) > fade:
				continue
			# La racine étire les rangs vers le bord : à pas constant, le bout du bras
			# — qui parcourt deux fois plus de chemin par rang — s'égrenait en collier.
			var along := pow((float(step) + 1.0) / float(steps), 0.6)
			var at := Vector2.from_angle(base + along * SWEEP) * r * along
			# Le cap d'un éclat est la tangente de la spirale, pas le rayon : c'est
			# la différence entre un tourbillon et une étoile.
			var ahead := Vector2.from_angle(base + (along + 0.04) * SWEEP) * r * (along + 0.04)
			Frost.chip(self, at, (ahead - at).angle(), _tint, 1.0)

	for i in FLAKES:
		var turn := _age * SPIN * 1.4 + TAU * float(i) / float(FLAKES)
		# Ils tombent vers le cœur : un vortex aspire, il ne rayonne pas.
		var away := 1.0 - fmod(_age * 0.6 + float(i) * 0.137, 1.0)
		Frost.drift(self, Vector2.from_angle(turn) * r * away, _tint, 0.8 * away * fade)
