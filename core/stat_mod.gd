class_name StatMod
extends RefCounted

## Une modification de statistique : « +6 dégâts », « +12 % de PV ». Une seule forme
## pour les implicites, les affixes, les passifs et les nœuds. Pas une Resource : ce
## sont les définitions (`ItemAffix`) qui sont des `.tres`.

## `PERCENT` est l'**accru** : ceux d'un même champ s'additionnent. `MORE` multiplie
## seul, après eux. **Ajouter à la fin** : l'entier est écrit dans les sauvegardes.
enum Mode { FLAT, PERCENT, MORE }

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

## L'accord de chaque libellé, pour le terme qui le suit : « armure accrue », « dégâts
## accrus ». Les formes de `Glossary.AGREEMENTS` ; un test refuse un libellé oublié.
const AGREEMENT := {
	"strength": "fs",
	"dexterity": "fs",
	"intelligence": "fs",
	"max_health": "mp",
	"health_regen": "mp",
	"max_mana": "ms",
	"mana_regen": "ms",
	"armor": "fs",
	"evasion": "fs",
	"res_cold": "fs",
	"res_fire": "fs",
	"res_lightning": "fs",
	"res_necrotic": "fs",
	"res_holy": "fs",
	"attack_cooldown": "ms",
	"attack_speed": "fs",
	"cast_speed": "fs",
	"attack_range": "fs",
	"crit_chance": "fs",
	"crit_multiplier": "mp",
	"move_speed": "fs",
}

## « de » s'élide devant ces lettres : « d'armure », « d'esquive ».
const ELIDING := "aeiouhéèê"

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
## **rempli**, un nombre de `SkillStats` qui n'agit que sur les compétences du
## mot-clé, sans jamais toucher la fiche.
var scope: String
## La borne haute d'une fourchette, `value` étant la basse ; égale à `value` sinon.
var value_max: float


func _init(p_stat: String, p_mode: Mode, p_value: float, p_scope := "") -> void:
	stat = p_stat
	mode = p_mode
	value = p_value
	value_max = p_value
	scope = p_scope


## « Ajoute `low` à `top` dégâts » d'une nature, à une famille de compétences.
static func ranged(p_stat: String, low: float, top: float, p_scope: String) -> StatMod:
	var m := StatMod.new(p_stat, Mode.FLAT, low, p_scope)
	m.value_max = top
	return m


## Les dégâts ajoutés d'une nature se donnent en fourchette.
static func ranged_stat(p_stat: String) -> bool:
	return SkillStats.added_nature(p_stat) >= 0


## La ligne d'un affixe ou d'un implicite : une fourchette s'ajoute toujours à plat,
## borne haute jamais sous la basse. Partagée pour que les deux s'écrivent pareil.
static func from_definition(
	p_stat: String, percentage: bool, value: float, value_max: float, p_scope: String,
	more := false
) -> StatMod:
	if ranged_stat(p_stat):
		return ranged(p_stat, value, maxf(value_max, value), p_scope)
	var p_mode := Mode.FLAT
	if percentage:
		p_mode = Mode.MORE if more else Mode.PERCENT
	return StatMod.new(p_stat, p_mode, value, p_scope)


## **Le seul endroit qui écrit un pourcentage**, selon la typographie de la langue :
## « 20 % » en français, « 20% » en anglais.
static func percentage(value: int, with_sign := false) -> String:
	return Texts.t("{valeur} %").format({"valeur": ("%+d" if with_sign else "%d") % value})


## L'unité déduite du gabarit, pour qu'une plage ne la répète pas.
static func _percent_unit() -> String:
	return percentage(0).trim_prefix("0")


## Une valeur dans son unité, pour l'infobulle comme pour la fiche.
static func format(stat_name: String, v: float, signed := false) -> String:
	if stat_name in SCALED:
		return percentage(roundi(v * 100.0), signed)
	if stat_name in PERCENT_POINTS:
		return percentage(roundi(v), signed)
	var fmt := "%+" if signed else "%"
	# Sans décimale quand il n'y en a pas : « 6 dégâts » et non « 6.0 ».
	if is_equal_approx(v, roundf(v)):
		return (fmt + "d") % roundi(v)
	return (fmt + ".1f") % v


## Arrondie vers le haut — à 0,4 PV on est vivant —, mais jamais au-delà du maximum
## affiché.
static func gauge(current: float, maximum: float) -> String:
	var top := roundi(maximum)
	return "%d / %d" % [mini(ceili(current), top), top]


## La part remplie, entre 0 et 1, gardée contre un maximum nul (pas de mana).
static func ratio(current: float, maximum: float) -> float:
	return 0.0 if maximum <= 0.0 else clampf(current / maximum, 0.0, 1.0)


## Un pourcentage porte son unité par son mode ; une valeur absolue passe par format().
static func value_label(stat_name: String, p_mode: Mode, v: float, signed := true) -> String:
	if p_mode != Mode.FLAT:
		return percentage(roundi(v), signed)
	return format(stat_name, v, signed)


## « 45–58 », « 8–11 % » : sans signe, un « + » par borne se lirait comme deux valeurs.
static func range_label(stat_name: String, p_mode: Mode, lo: float, hi: float) -> String:
	var low := value_label(stat_name, p_mode, lo, false)
	var top := value_label(stat_name, p_mode, hi, false)
	# L'unité ne se répète pas : « 8 %–11 % » se lit deux fois.
	var unit := _percent_unit()
	if low.ends_with(unit) and top.ends_with(unit):
		low = low.trim_suffix(unit)
	return "%s–%s" % [low, top]


## Visée par un mot-clé, la statistique le dit entre parenthèses, avec le libellé de
## la fiche du manuel ; des dégâts ajoutés disent leur destinataire en toutes lettres
## (« dégâts de froid aux sorts »).
static func name(stat_name: String, p_scope := "") -> String:
	var nature := SkillStats.added_nature(stat_name)
	if nature >= 0:
		# Sans portée : la ligne d'un nœud, qui ne vise que sa compétence.
		if p_scope.is_empty():
			return DamageType.damage_label(nature)
		return "%s %s" % [DamageType.damage_label(nature), Keywords.recipient(p_scope)]
	return _noun(stat_name) + _complement(stat_name, p_scope)


## Le nom de ce qui change, sans ce qui le précise : « dégâts », « armure ».
static func _noun(stat_name: String) -> String:
	if LABELS.has(stat_name):
		return Texts.t(LABELS[stat_name])
	if SkillStats.against(stat_name) >= 0:
		return Texts.t(SkillStats.LABELS[SkillStats.DAMAGE])
	return Texts.t(SkillStats.LABELS.get(stat_name, stat_name))


## Ce qui suit le nom : « contre les embrasés », puis « (Sort) ».
static func _complement(stat_name: String, p_scope: String) -> String:
	var out := ""
	var kind := SkillStats.against(stat_name)
	if kind >= 0:
		out += " " + Texts.t(StatusEffects.AGAINST[kind])
	if not p_scope.is_empty():
		out += " (%s)" % Keywords.label_of(p_scope)
	return out


## L'accord du nom, pour le terme qui le suit.
static func agreement(stat_name: String) -> String:
	if AGREEMENT.has(stat_name):
		return AGREEMENT[stat_name]
	if SkillStats.against(stat_name) >= 0:
		return SkillStats.AGREEMENT[SkillStats.DAMAGE]
	return SkillStats.AGREEMENT.get(stat_name, "ms")


## « dégâts accrus contre les embrasés » : une ligne de fiche nommée par son terme.
static func term_label(stat_name: String, term_id: String, p_scope := "") -> String:
	return Texts.t("{stat} {terme}{complement}").format({
		"stat": _noun(stat_name),
		"terme": Glossary.term(term_id, agreement(stat_name)),
		"complement": _complement(stat_name, p_scope),
	})


## Le terme d'un pourcentage : additif ou multiplicatif, gain ou perte.
static func term_of(p_mode: Mode, v: float) -> String:
	if p_mode == Mode.MORE:
		return "more" if v >= 0.0 else "less"
	return "increased" if v >= 0.0 else "reduced"


func is_a_range() -> bool:
	return ranged_stat(stat)


## La valeur seule : « +9 % », « 3–7 », « 6 ». Une fourchette aux bornes égales
## s'écrit comme un nombre — « 6–6 » se lit comme une faute.
func readable_value() -> String:
	if mode != Mode.FLAT:
		return "%s %s" % [
			value_label(stat, mode, value), Glossary.term(term_of(mode, value), agreement(stat))
		]
	if not is_a_range():
		return value_label(stat, mode, value)
	if is_equal_approx(value, value_max):
		return format(stat, value)
	return "%s–%s" % [format(stat, value), format(stat, value_max)]


## « +25 armure », « +10 % d'armure accrue », ou « ajoute 3 à 7 dégâts de froid aux
## sorts ».
func label() -> String:
	if mode != Mode.FLAT:
		var noun := _noun(stat)
		var fields := {
			"valeur": value_label(stat, mode, value),
			"stat": noun,
			"terme": Glossary.term(term_of(mode, value), agreement(stat)),
			"complement": _complement(stat, scope),
		}
		if ELIDING.contains(noun.left(1).to_lower()):
			return Texts.t("{valeur} d'{stat} {terme}{complement}").format(fields)
		return Texts.t("{valeur} de {stat} {terme}{complement}").format(fields)
	if stat == SkillStats.LEVELS:
		var levels := roundi(value)
		return "%s %s" % [
			Texts.tn("+{n} niveau de compétence", "+{n} niveaux de compétence", levels).format(
				{"n": levels}
			),
			Keywords.recipient(scope),
		]
	if not is_a_range():
		return "%s %s" % [value_label(stat, mode, value), name(stat, scope)]
	# La phrase entière, et pas des morceaux collés : l'ordre des mots n'est pas le
	# même dans les deux langues, et un traducteur ne peut rien faire d'un « à ».
	if is_equal_approx(value, value_max):
		return Texts.t("ajoute {valeur} {degats}").format({
			"valeur": format(stat, value), "degats": name(stat, scope)
		})
	return Texts.t("ajoute {bas} à {haut} {degats}").format({
		"bas": format(stat, value), "haut": format(stat, value_max), "degats": name(stat, scope)
	})


## **Le seul endroit qui écrit une liste sur la fiche** ; ce qui vise un mot-clé en est
## écarté, sinon compté deux fois.
static func apply_all(stats: CharacterStats, mods: Array) -> void:
	var on_the_sheet: Array[StatMod] = []
	for m: StatMod in mods:
		if m.scope.is_empty():
			on_the_sheet.append(m)
	apply(stats, on_the_sheet)


## Les plats, puis la somme des accrus de chaque champ, puis chaque « plus » : sinon le
## résultat dépendrait de l'ordre d'équipement.
static func apply(target: Object, mods: Array) -> void:
	var increased := {}
	for m: StatMod in mods:
		if m.mode == Mode.FLAT:
			target.set(m.stat, float(target.get(m.stat)) + m.value)
		elif m.mode == Mode.PERCENT:
			increased[m.stat] = float(increased.get(m.stat, 0.0)) + m.value
	for field: String in increased:
		target.set(field, float(target.get(field)) * (1.0 + float(increased[field]) * 0.01))
	for m: StatMod in mods:
		if m.mode == Mode.MORE:
			target.set(m.stat, float(target.get(m.stat)) * (1.0 + m.value * 0.01))
