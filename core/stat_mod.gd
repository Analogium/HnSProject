class_name StatMod
extends RefCounted

## Une modification de statistique : « +6 dégâts », « +12 % de PV ». Une seule forme
## pour les implicites, les affixes, les passifs et les nœuds. Pas une Resource : ce
## sont les définitions (`ItemAffix`) qui sont des `.tres`.

enum Mode { FLAT, PERCENT }

## Le nom lisible de chaque champ de CharacterStats. L'unité fait partie du nom quand
## elle n'est pas évidente : « PV/s », pas « régénération ».
const LABELS := {
	"strength": "force",
	"dexterity": "dextérité",
	"intelligence": "intelligence",
	"max_health": "PV",
	"health_regen": "PV/s",
	"max_mana": "mana",
	"mana_regen": "mana/s",
	"armor": "armure",
	"evasion": "esquive",
	"res_cold": "rés. froid",
	"res_fire": "rés. feu",
	"res_lightning": "rés. foudre",
	"res_necrotic": "rés. nécrotique",
	"res_holy": "rés. sacré",
	"attack_cooldown": "temps de recharge",
	"attack_speed": "vitesse d'attaque",
	"cast_speed": "vitesse d'incantation",
	"attack_range": "allonge",
	"crit_chance": "chance critique",
	"crit_multiplier": "dégâts critiques",
	"move_speed": "vitesse",
}

## Rangées en fraction ou en multiplicateur, lues en pourcentage : 0.05 → « 5 % ».
const SCALED := [
	"crit_chance",
	"crit_multiplier",
	"attack_speed",
	"cast_speed",
]

## Déjà en points de pourcentage : 75 → « 75 % ». Confondue avec SCALED, on lirait
## « 7500 % ».
const PERCENT_POINTS := [
	"res_cold",
	"res_fire",
	"res_lightning",
	"res_necrotic",
	"res_holy",
]

var stat: String
var mode: Mode
var value: float
## Le mot-clé visé, ou vide. **Vide**, `stat` est un champ de `CharacterStats` ;
## **rempli**, un nombre de `StatsDeCompetence` qui n'agit que sur les compétences du
## mot-clé, sans jamais toucher la fiche.
var portee: String
## La borne haute d'une fourchette, `value` étant la basse ; égale à `value` sinon.
var value_max: float


func _init(p_stat: String, p_mode: Mode, p_value: float, p_portee := "") -> void:
	stat = p_stat
	mode = p_mode
	value = p_value
	value_max = p_value
	portee = p_portee


## « Ajoute `bas` à `haut` dégâts » d'une nature, à une famille de compétences.
static func fourchette(p_stat: String, bas: float, haut: float, p_portee: String) -> StatMod:
	var m := StatMod.new(p_stat, Mode.FLAT, bas, p_portee)
	m.value_max = haut
	return m


## Les dégâts ajoutés d'une nature se donnent en fourchette.
static func stat_en_fourchette(p_stat: String) -> bool:
	return StatsDeCompetence.nature_ajoutee(p_stat) >= 0


## La ligne d'un affixe ou d'un implicite : une fourchette s'ajoute toujours à plat,
## borne haute jamais sous la basse. Partagée pour que les deux s'écrivent pareil.
static func depuis_definition(
	p_stat: String, pourcentage: bool, valeur: float, valeur_max: float, p_portee: String
) -> StatMod:
	if stat_en_fourchette(p_stat):
		return fourchette(p_stat, valeur, maxf(valeur_max, valeur), p_portee)
	return StatMod.new(p_stat, Mode.PERCENT if pourcentage else Mode.FLAT, valeur, p_portee)


## **Le seul endroit qui écrit un pourcentage**, selon la typographie de la langue :
## « 20 % » en français, « 20% » en anglais.
static func pourcentage(valeur: int, signe := false) -> String:
	return Textes.t("{valeur} %").format({"valeur": ("%+d" if signe else "%d") % valeur})


## L'unité déduite du gabarit, pour qu'une plage ne la répète pas.
static func _unite_de_pourcentage() -> String:
	return pourcentage(0).trim_prefix("0")


## Une valeur dans son unité, pour l'infobulle comme pour la fiche.
static func format(stat_name: String, v: float, signed := false) -> String:
	if stat_name in SCALED:
		return pourcentage(roundi(v * 100.0), signed)
	if stat_name in PERCENT_POINTS:
		return pourcentage(roundi(v), signed)
	var fmt := "%+" if signed else "%"
	# Sans décimale quand il n'y en a pas : « 6 dégâts » et non « 6.0 ».
	if is_equal_approx(v, roundf(v)):
		return (fmt + "d") % roundi(v)
	return (fmt + ".1f") % v


## Arrondie vers le haut — à 0,4 PV on est vivant —, mais jamais au-delà du maximum
## affiché.
static func gauge(current: float, maximum: float) -> String:
	var haut := roundi(maximum)
	return "%d / %d" % [mini(ceili(current), haut), haut]


## La part remplie, entre 0 et 1, gardée contre un maximum nul (pas de mana).
static func ratio(current: float, maximum: float) -> float:
	return 0.0 if maximum <= 0.0 else clampf(current / maximum, 0.0, 1.0)


## Un pourcentage porte son unité par son mode ; une valeur absolue passe par format().
static func value_label(stat_name: String, p_mode: Mode, v: float, signed := true) -> String:
	if p_mode == Mode.PERCENT:
		return pourcentage(roundi(v), signed)
	return format(stat_name, v, signed)


## « 45–58 », « 8–11 % » : sans signe, un « + » par borne se lirait comme deux valeurs.
static func range_label(stat_name: String, p_mode: Mode, lo: float, hi: float) -> String:
	var bas := value_label(stat_name, p_mode, lo, false)
	var haut := value_label(stat_name, p_mode, hi, false)
	# L'unité ne se répète pas : « 8 %–11 % » se lit deux fois.
	var unite := _unite_de_pourcentage()
	if bas.ends_with(unite) and haut.ends_with(unite):
		bas = bas.trim_suffix(unite)
	return "%s–%s" % [bas, haut]


## Visée par un mot-clé, la statistique le dit entre parenthèses, avec le libellé de
## la fiche du manuel ; des dégâts ajoutés disent leur destinataire en toutes lettres
## (« dégâts de froid aux sorts »).
static func nom(stat_name: String, p_portee := "") -> String:
	if p_portee.is_empty():
		if LABELS.has(stat_name):
			return Textes.t(LABELS[stat_name])
		# Sans portée et hors de la fiche : la ligne d'un nœud, qui ne vise que sa
		# compétence. On nomme le nombre visé.
		var nature_sans_portee := StatsDeCompetence.nature_ajoutee(stat_name)
		if nature_sans_portee >= 0:
			return DamageType.libelle_de_degats(nature_sans_portee)
		return Textes.t(StatsDeCompetence.LABELS.get(stat_name, stat_name))
	var nature := StatsDeCompetence.nature_ajoutee(stat_name)
	if nature >= 0:
		return "%s %s" % [
			DamageType.libelle_de_degats(nature), MotsCles.destinataire(p_portee)
		]
	return "%s (%s)" % [
		Textes.t(StatsDeCompetence.LABELS.get(stat_name, stat_name)), MotsCles.libelle(p_portee)
	]


func est_une_fourchette() -> bool:
	return stat_en_fourchette(stat)


## La valeur seule : « +9 % », « 3–7 », « 6 ». Une fourchette aux bornes égales
## s'écrit comme un nombre — « 6–6 » se lit comme une faute.
func valeur_lisible() -> String:
	if not est_une_fourchette():
		return value_label(stat, mode, value)
	if is_equal_approx(value, value_max):
		return format(stat, value)
	return "%s–%s" % [format(stat, value), format(stat, value_max)]


## « +25 armure », ou « ajoute 3 à 7 dégâts de froid aux sorts ».
func label() -> String:
	if not est_une_fourchette():
		return "%s %s" % [value_label(stat, mode, value), nom(stat, portee)]
	# La phrase entière, et pas des morceaux collés : l'ordre des mots n'est pas le
	# même dans les deux langues, et un traducteur ne peut rien faire d'un « à ».
	if is_equal_approx(value, value_max):
		return Textes.t("ajoute {valeur} {degats}").format({
			"valeur": format(stat, value), "degats": nom(stat, portee)
		})
	return Textes.t("ajoute {bas} à {haut} {degats}").format({
		"bas": format(stat, value), "haut": format(stat, value_max), "degats": nom(stat, portee)
	})


## **Le seul endroit qui écrit une liste sur la fiche** ; ce qui vise un mot-clé en est
## écarté, sinon compté deux fois.
static func apply_all(stats: CharacterStats, mods: Array) -> void:
	var sur_la_fiche: Array[StatMod] = []
	for m: StatMod in mods:
		if m.portee.is_empty():
			sur_la_fiche.append(m)
	appliquer(stats, sur_la_fiche)


## Les plats d'abord, puis les pourcentages : sinon le résultat dépendrait de l'ordre
## d'équipement.
static func appliquer(cible: Object, mods: Array) -> void:
	for m: StatMod in mods:
		if m.mode == Mode.FLAT:
			cible.set(m.stat, float(cible.get(m.stat)) + m.value)
	for m: StatMod in mods:
		if m.mode == Mode.PERCENT:
			cible.set(m.stat, float(cible.get(m.stat)) * (1.0 + m.value * 0.01))
