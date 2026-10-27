class_name SacredPillar
extends Node3D

## Le pilier de Pilier sacré : une colonne de lumière tombée du ciel sur le point
## visé, qui frappe son cercle à chaque période puis s'éteint. Comme le nuage
## d'orage, il ne fige jamais le jeu — une impulsion qui gèle toutes les demi-secondes
## hacherait l'image tant qu'il brûle.

## Le Pilier errant (jalon 40) : sa vitesse vers l'ennemi le plus proche, en pixels par
## seconde, et jusqu'où il le cherche. Premier réglage.
const DRIFT_SPEED := 40.0
const DRIFT_SIGHT := 160.0

## Ceux qui brûlent, pour la Communion et le Pilori (jalon 48).
static var _standing: Array[SacredPillar] = []

var _cast: SkillStats
var _author: StatusEffects
var _age := 0.0
var _strikes := 0
## Ce que suit le Pilier errant, choisi à chaque impulsion. Sans type : il peut mourir
## entre deux, et `is_instance_valid()` passe avant tout usage (invariant 4).
var _prey: Variant = null
## Le lanceur, que soigne la Consécration (jalon 48) ; null pour un pilier posé sans lui.
var _caster: Player
## L'Ascension : les secondes déjà gagnées. L'Apothéose : les ennemis frappés.
var _gained := 0.0
var _struck := 0
var _fx: SacredPillarFx


## `caster` : le joueur qui se tient dans la colonne, pour la Consécration.
static func fall(
	parent: Node, point: Vector3, cast: SkillStats, author: StatusEffects, caster: Player = null
) -> SacredPillar:
	var pillar := SacredPillar.new()
	# Une copie pour lui seul, quand il change son lancer : l'Ascension allonge sa durée, le
	# Sanctuaire bénit à coup sûr — et le Triptyque pose trois piliers d'un même lancer.
	if cast.ascension > 0.0 or cast.sanctuary > 0.0:
		cast = cast.echoed(1.0)
		if cast.sanctuary > 0.0:
			cast.status_chance_increase += SkillStats.SURE_STATE
	pillar._cast = cast
	pillar._author = author
	pillar._caster = caster
	if cast.ascension > 0.0 and author != null:
		author.slew.connect(pillar._on_slew)
	parent.add_child(pillar)
	Settings.veil(pillar, Settings.SPELLS)
	pillar.global_position = point
	pillar._fx = SacredPillarFx.raise(
		pillar, cast.nature, cast.radius, cast.consecration > 0.0, cast.end_burst > 0.0
	)
	_standing.assign(_standing.filter(
		func(p) -> bool: return is_instance_valid(p) and not p.is_queued_for_deletion()
	))
	_standing.append(pillar)
	return pillar


## Les piliers de ce lanceur qui brûlent encore.
static func standing_for(author: StatusEffects) -> Array[SacredPillar]:
	var out: Array[SacredPillar] = []
	for p in _standing:
		if is_instance_valid(p) and not p.is_queued_for_deletion() and p._author == author:
			out.append(p)
	return out


## Le cercle qu'il mord.
func reach() -> float:
	return _cast.radius


## Les impulsions se comptent par `strikes_over_duration()`, la fonction même de
## l'estimation : la fiche et le pilier ne peuvent pas annoncer deux nombres.
func _physics_process(delta: float) -> void:
	_age += delta
	var due := _cast.strikes_due(_age)
	while _strikes < due:
		_strike()
		_strikes += 1
	if is_instance_valid(_prey):
		global_position = global_position.move_toward(
			(_prey as Node3D).global_position, DRIFT_SPEED * (1.0 + _cast.procession * 0.01) * delta
		)
	# La Consécration (jalon 48) : son lanceur, debout dans le cercle, regagne des PV.
	if _cast.consecration > 0.0 and is_instance_valid(_caster) \
			and _caster.global_position.distance_to(global_position) <= reach():
		_caster.mend(_cast.consecration * 0.01, delta)
	if _age >= _cast.duration and _strikes >= _cast.strikes_over_duration():
		# L'Effondrement : en s'éteignant, la colonne éclate ; l'Apothéose, d'autant plus fort
		# qu'elle a frappé de monde.
		if _cast.end_burst > 0.0:
			var burst := _cast
			if _cast.apotheosis > 0.0:
				burst = _cast.echoed(
					1.0 + _cast.apotheosis * 0.01 * float(mini(_struck, SkillStats.APOTHEOSIS_MOST))
				)
			Explosion.of_cast(get_parent(), global_position, burst, _cast.end_burst, _author)
		queue_free()


## L'Appel céleste tire vers le cœur, par un recul négatif. Le Verdict (jalon 48) : la
## colonne tombe, et sa première impulsion frappe plus fort.
func _strike(factor := 1.0) -> void:
	if _strikes == 0:
		factor *= 1.0 + _cast.verdict * 0.01
	_struck += Targets.strike_circle(
		get_world_3d(), global_position, _cast.radius, _cast, _author, -_cast.pull, factor
	).size()
	_fx.strike()
	if _cast.shape == Skill.Shape.DRIFT:
		_prey = Targets.nearest(get_world_3d(), global_position, DRIFT_SIGHT)


## La Communion (jalon 48) : une onde de la Pulsation qui l'atteint la fait frapper sur-le-champ,
## une impulsion de plus à cette part de son coup.
func commune(part: float) -> void:
	_struck += Targets.strike_circle(
		get_world_3d(), global_position, _cast.radius, _cast, _author, -_cast.pull, part
	).size()
	_fx.strike()


## L'Ascension (jalon 48) : un ennemi tué par cette colonne la fait brûler plus longtemps.
func _on_slew(cast: SkillStats, _at: Vector3, _victim: StatusEffects) -> void:
	if cast != _cast or _gained >= SkillStats.ASCENSION_MOST:
		return
	var gain := minf(_cast.ascension, SkillStats.ASCENSION_MOST - _gained)
	_gained += gain
	_cast.duration += gain

