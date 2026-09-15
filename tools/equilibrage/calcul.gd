class_name CalculDuBanc

## La mesure sans simulation : un vrai `Player` chargé du profil, ce qu'il lance par
## `Player.resoudre()`, ce qu'il subit et ce qu'il inflige par une vraie `Hurtbox`.
## Rien n'y recopie une formule du jeu (hack-n-slash-jalon-13.md, §5).

enum Verdict { TRIVIAL, CONFORTABLE, TENDU, MUR }
const NOMS_DE_VERDICT := ["trivial", "confortable", "tendu", "mur"]
const PASTILLES := ["🟦", "🟩", "🟨", "🟥"]

## Les couloirs du §4, décidés le 15 septembre 2026. Bornes incluses du côté confortable.
const COUPS_TRIVIAL := 0.5
const COUPS_CONFORTABLE := 3.0
const COUPS_TENDU := 8.0
const SURVIE_CONFORTABLE := 10.0
const SURVIE_TENDUE := 4.0

const GRUNTS_AU_CONTACT := 3
const CASTERS_AU_CONTACT := 1


class Mesure:
	var zone := 0
	var niveau := 0
	## Celle qui tue un grunt en moins de coups.
	var competence := ""
	var coups_grunt := INF
	var coups_caster := INF
	var coups_colosse := INF
	## La meilleure compétence pour la durée, pas forcément celle des coups.
	var secondes_grunt := INF
	var secondes_colosse := INF
	var survie := INF
	var verdict := 0


var _joueur: Player
## Une hurtbox hors de l'arbre, qui prête sa mitigation aux fiches d'ennemis.
var _cible := Hurtbox.new()
var _grunt: CharacterStats
var _caster: CharacterStats
var _nature_du_caster := 0
var _colossal: Affix


## `joueur` doit être dans l'arbre : `charger()` touche son sprite et ses barres.
func _init(joueur: Player) -> void:
	_joueur = joueur
	_grunt = ProfilsDuBanc.fiche_de_base(ProfilsDuBanc.ZONE.GRUNT_SCENE)
	_caster = ProfilsDuBanc.fiche_de_base(ProfilsDuBanc.ZONE.CASTER_SCENE)
	var caster: Caster = ProfilsDuBanc.ZONE.CASTER_SCENE.instantiate()
	var tir: Projectile = caster.projectile_scene.instantiate()
	_nature_du_caster = tir.damage_type
	tir.free()
	caster.free()
	for a: Affix in AffixPool.ALL:
		if a.id == "colossal":
			_colossal = a


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and is_instance_valid(_cible):
		_cible.free()


func mesurer(personnage: Personnage, zone: int) -> Mesure:
	_joueur.charger(personnage)
	var m := Mesure.new()
	m.zone = zone
	m.niveau = _joueur.level
	var sans_affixe: Array[Affix] = []
	var grunt := Enemy.fiche_de(_grunt, zone, sans_affixe)
	var caster := Enemy.fiche_de(_caster, zone, sans_affixe)
	var colosse := Enemy.fiche_de(_grunt, zone, [_colossal] as Array[Affix])

	for i in BarreDeCompetences.EMPLACEMENTS:
		var competence := _joueur.barre.competence_de(i)
		if competence == null or _joueur.points_de_competence(competence.id) <= 0:
			continue
		var geste := _joueur.resoudre(competence, _joueur.points_de_competence(competence.id))
		var coups := _coups(geste, grunt)
		if coups < m.coups_grunt:
			m.competence = competence.nom
			m.coups_grunt = coups
			m.coups_caster = _coups(geste, caster)
			m.coups_colosse = _coups(geste, colosse)
		m.secondes_grunt = minf(m.secondes_grunt, _secondes(geste, grunt))
		m.secondes_colosse = minf(m.secondes_colosse, _secondes(geste, colosse))

	var subis := (
		GRUNTS_AU_CONTACT * _subi(grunt, DamageType.Kind.PHYSICAL)
		+ CASTERS_AU_CONTACT * _subi(caster, _nature_du_caster)
	)
	var net := subis - _joueur.stats.health_regen
	m.survie = _joueur.stats.max_health / net if net > 0.0 else INF
	m.verdict = verdict(m.coups_grunt, m.survie)
	return m


## Le pire des deux axes ; au-delà de dix secondes, la survie ne contraint plus rien.
static func verdict(coups: float, survie: float) -> Verdict:
	var par_coups := Verdict.MUR
	if coups < COUPS_TRIVIAL:
		par_coups = Verdict.TRIVIAL
	elif coups <= COUPS_CONFORTABLE:
		par_coups = Verdict.CONFORTABLE
	elif coups <= COUPS_TENDU:
		par_coups = Verdict.TENDU
	var par_survie := Verdict.TRIVIAL
	if survie < SURVIE_TENDUE:
		par_survie = Verdict.MUR
	elif survie <= SURVIE_CONFORTABLE:
		par_survie = Verdict.TENDU
	return maxi(par_coups, par_survie) as Verdict


## Le coup moyen d'un geste sur cette fiche : milieu des fourchettes, critique en
## moyenne, atténué par la vraie hurtbox.
func _coup(geste: StatsDeCompetence, fiche: CharacterStats) -> float:
	var parts := DamageType.parts_vides()
	for i in parts.size():
		parts[i] = (geste.degats_min[i] + geste.degats_max[i]) * 0.5
	var info := DamageInfo.en_parts(parts, Vector2.ZERO)
	var s := _joueur.stats
	info.multiplier(1.0 + s.crit_chance * (s.crit_multiplier - 1.0))
	_cible.stats = fiche
	_cible.mitiger(info)
	return info.amount


func _coups(geste: StatsDeCompetence, fiche: CharacterStats) -> float:
	var coup := _coup(geste, fiche)
	return fiche.max_health / coup if coup > 0.0 else INF


## Par `moyenne_par_seconde()`, **si tout touche** : les huit traits d'une nova comptent
## sur la même cible. La réserve n'y limite rien ; c'est à la simulation de le voir.
func _secondes(geste: StatsDeCompetence, fiche: CharacterStats) -> float:
	var brut := geste.moyenne_par_coup()
	var par_seconde := geste.moyenne_par_seconde()
	if brut <= 0.0 or par_seconde <= 0.0:
		return INF
	return fiche.max_health / (par_seconde * _coup(geste, fiche) / brut)


## Les dégâts par seconde d'un ennemi de cette fiche, après défenses et esquive.
func _subi(fiche: CharacterStats, nature: int) -> float:
	var info := DamageInfo.new(fiche.attack_damage, Vector2.ZERO, 0.0, false, nature)
	_joueur.hurtbox.mitiger(info)
	return info.amount * (1.0 - _joueur.stats.evade_chance()) / fiche.attack_interval()
