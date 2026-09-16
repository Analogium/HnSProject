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
	if p_mode == Mode.MORE:
		return Texts.t("{valeur} en plus").format({"valeur": percentage(roundi(v))})
	if p_mode == Mode.PERCENT:
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
	if p_scope.is_empty():
		if LABELS.has(stat_name):
			return Texts.t(LABELS[stat_name])
		# Sans portée et hors de la fiche : la ligne d'un nœud, qui ne vise que sa
		# compétence. On nomme le nombre visé.
		var unscoped_nature := SkillStats.added_nature(stat_name)
		if unscoped_nature >= 0:
			return DamageType.damage_label(unscoped_nature)
		return Texts.t(SkillStats.LABELS.get(stat_name, stat_name))
	var nature := SkillStats.added_nature(stat_name)
	if nature >= 0:
		return "%s %s" % [
			DamageType.damage_label(nature), Keywords.recipient(p_scope)
		]
	return "%s (%s)" % [
		Texts.t(SkillStats.LABELS.get(stat_name, stat_name)), Keywords.label_of(p_scope)
	]


func is_a_range() -> bool:
	return ranged_stat(stat)


## La valeur seule : « +9 % », « 3–7 », « 6 ». Une fourchette aux bornes égales
## s'écrit comme un nombre — « 6–6 » se lit comme une faute.
func readable_value() -> String:
	if not is_a_range():
		return value_label(stat, mode, value)
	if is_equal_approx(value, value_max):
		return format(stat, value)
	return "%s–%s" % [format(stat, value), format(stat, value_max)]


## « +25 armure », ou « ajoute 3 à 7 dégâts de froid aux sorts ».
func label() -> String:
	if mode == Mode.MORE:
		var stat_name := name(stat, scope)
		# L'élision : « 20 % d'armure en plus », pas « de armure ».
		if "aeiouhéè".contains(stat_name.left(1)):
			return Texts.t("{valeur} d'{stat} en plus").format({
				"valeur": percentage(roundi(value)), "stat": stat_name
			})
		return Texts.t("{valeur} de {stat} en plus").format({
			"valeur": percentage(roundi(value)), "stat": stat_name
		})
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
