class_name BenchCalculation

## La mesure sans simulation : un vrai `Player` chargé du profil, ce qu'il lance par
## `Player.resolve()`, ce qu'il subit et ce qu'il inflige par une vraie `Hurtbox`.
## Rien n'y recopie une formule du jeu (JALONS/hack-n-slash-jalon-13.md, §5).

enum Verdict { TRIVIAL, COMFORTABLE, TIGHT, WALL }
const VERDICT_NAMES := ["trivial", "comfortable", "tight", "wall"]
const PIPS := ["🟦", "🟩", "🟨", "🟥"]

## Les couloirs du §4, décidés le 15 septembre 2026. Bornes incluses du côté confortable.
const HITS_TRIVIAL := 0.5
const HITS_COMFORTABLE := 3.0
const HITS_TIGHT := 8.0
const SURVIVAL_COMFORTABLE := 10.0
const SURVIVAL_TIGHT := 4.0

## Un seul tirage d'objets divisait la survie par deux d'un réglage à l'autre
## (jalon 13, limites) : la case lit la médiane de plusieurs.
const ITEM_DRAWS := 9

const GRUNTS_IN_CONTACT := 3
const CASTERS_IN_CONTACT := 1


class Measurement:
	var zone := 0
	var level := 0
	## Celle qui tue un grunt en moins de coups.
	var skill := ""
	var grunt_hits := INF
	var caster_hits := INF
	var colossus_hits := INF
	## La meilleure compétence pour la durée, pas forcément celle des coups.
	var grunt_seconds := INF
	var colossus_seconds := INF
	var survival := INF
	var verdict := 0


var _player: Player
## Une hurtbox hors de l'arbre, qui prête sa mitigation aux fiches d'ennemis.
var _target := Hurtbox.new()
var _grunt: CharacterStats
var _caster: CharacterStats
var _caster_nature := 0
var _colossal: Affix


## `player` doit être dans l'arbre : `load_character()` touche son sprite et ses barres.
func _init(player: Player) -> void:
	_player = player
	_grunt = BenchProfiles.base_sheet(BenchProfiles.ZONE.GRUNT_SCENE)
	_caster = BenchProfiles.base_sheet(BenchProfiles.ZONE.CASTER_SCENE)
	var caster: Caster = BenchProfiles.ZONE.CASTER_SCENE.instantiate()
	var bolt: Projectile = caster.projectile_scene.instantiate()
	_caster_nature = bolt.damage_type
	bolt.free()
	caster.free()
	for a: Affix in AffixPool.ALL:
		if a.id == "colossal":
			_colossal = a


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and is_instance_valid(_target):
		_target.free()


## Coups et survie médians, chacun sur son axe ; le reste vient du tirage médian en coups.
## Un profil sans objet n'a qu'un tirage.
func measure_profile(
	build: BenchProfiles.Build, profile: BenchProfiles.Profile, built_for: int, played: int
) -> Measurement:
	var draws := ITEM_DRAWS if BenchProfiles.item_level_for(profile, built_for) > 0 else 1
	var all: Array[Measurement] = []
	for draw in draws:
		all.append(measure(BenchProfiles.character(build, profile, built_for, draw), played))
	var survivals := all.map(func(m: Measurement) -> float: return m.survival)
	survivals.sort()
	all.sort_custom(func(a: Measurement, b: Measurement) -> bool: return a.grunt_hits < b.grunt_hits)
	var m := all[draws / 2]
	m.survival = survivals[draws / 2]
	m.verdict = verdict(m.grunt_hits, m.survival)
	return m


func measure(character: Character, zone: int) -> Measurement:
	_player.load_character(character)
	var m := Measurement.new()
	m.zone = zone
	m.level = _player.level
	var without_affix: Array[Affix] = []
	var grunt := Enemy.sheet_of(_grunt, zone, without_affix)
	var caster := Enemy.sheet_of(_caster, zone, without_affix)
	var colossus := Enemy.sheet_of(_grunt, zone, [_colossal] as Array[Affix])

	for i in SkillBar.SLOT_COUNT:
		var skill := _player.bar.skill_of(i)
		if skill == null or _player.skill_points(skill.id) <= 0:
			continue
		var cast := _player.resolve(skill, _player.skill_points(skill.id))
		var hits := _hits(cast, grunt)
		if hits < m.grunt_hits:
			m.skill = skill.name
			m.grunt_hits = hits
			m.caster_hits = _hits(cast, caster)
			m.colossus_hits = _hits(cast, colossus)
		m.grunt_seconds = minf(m.grunt_seconds, _seconds(cast, grunt))
		m.colossus_seconds = minf(m.colossus_seconds, _seconds(cast, colossus))

	var taken := (
		GRUNTS_IN_CONTACT * _taken(grunt, DamageType.Kind.PHYSICAL)
		+ CASTERS_IN_CONTACT * _taken(caster, _caster_nature)
	)
	var net := taken - _player.stats.health_regen
	m.survival = _player.stats.max_health / net if net > 0.0 else INF
	m.verdict = verdict(m.grunt_hits, m.survival)
	return m


## Le pire des deux axes ; au-delà de dix secondes, la survie ne contraint plus rien.
static func verdict(hits: float, survival: float) -> Verdict:
	var by_hits := Verdict.WALL
	if hits < HITS_TRIVIAL:
		by_hits = Verdict.TRIVIAL
	elif hits <= HITS_COMFORTABLE:
		by_hits = Verdict.COMFORTABLE
	elif hits <= HITS_TIGHT:
		by_hits = Verdict.TIGHT
	var by_survival := Verdict.TRIVIAL
	if survival < SURVIVAL_TIGHT:
		by_survival = Verdict.WALL
	elif survival <= SURVIVAL_COMFORTABLE:
		by_survival = Verdict.TIGHT
	return maxi(by_hits, by_survival) as Verdict


## Le coup moyen d'un geste sur cette fiche : milieu des fourchettes, critique en
## moyenne, atténué par la vraie hurtbox.
func _hit(cast: SkillStats, sheet: CharacterStats) -> float:
	var parts := DamageType.empty_parts()
	for i in parts.size():
		parts[i] = (cast.damage_min[i] + cast.damage_max[i]) * 0.5
	var info := DamageInfo.as_parts(parts, Vector2.ZERO)
	info.multiplier(1.0 + cast.crit_chance * (cast.crit_multiplier - 1.0))
	_target.stats = sheet
	_target.mitigate_part(info)
	return info.amount


func _hits(cast: SkillStats, sheet: CharacterStats) -> float:
	var hit := _hit(cast, sheet)
	return sheet.max_health / hit if hit > 0.0 else INF


## Par `average_per_second()`, **si tout touche** : les huit traits d'une nova comptent
## sur la même cible. La réserve n'y limite rien ; c'est à la simulation de le voir.
func _seconds(cast: SkillStats, sheet: CharacterStats) -> float:
	var raw := cast.average_per_hit()
	var per_second := cast.average_per_second()
	if raw <= 0.0 or per_second <= 0.0:
		return INF
	return sheet.max_health / (per_second * _hit(cast, sheet) / raw)


## Les dégâts par seconde d'un ennemi de cette fiche, après défenses et esquive.
func _taken(sheet: CharacterStats, nature: int) -> float:
	var info := DamageInfo.new(sheet.attack_damage, Vector2.ZERO, 0.0, false, nature)
	_player.hurtbox.mitigate_part(info)
	return info.amount * (1.0 - _player.stats.evade_chance()) / sheet.attack_interval()
