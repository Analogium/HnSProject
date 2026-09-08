class_name StatMod
extends RefCounted

## Une modification de statistique : « +6 dégâts », « +12 % de PV ».
##
## Une seule structure pour l'implicite d'une base et pour ses affixes tirés : les
## deux disent quel champ, de combien, à plat ou en pourcentage, et tout ce qui
## les lit n'a donc qu'une forme à connaître.
##
## Pas une Resource : un modificateur tiré au hasard n'existe que dans une partie.
## Ce sont les *définitions* (ItemAffix) qui sont des `.tres`.

enum Mode { FLAT, PERCENT }

## Le nom lisible de chaque statistique, au même endroit pour toute l'interface.
## Les clés sont les champs de CharacterStats, et le test de la réserve d'affixes
## vérifie que chacune existe.
##
## L'unité fait partie du nom quand elle n'est pas évidente — « PV/s » plutôt que
## « régénération », qui laisserait croire à un pourcentage.
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
	"attack_damage": "dégâts",
	"spell_damage": "dégâts de sort",
	"attack_cooldown": "temps de recharge",
	"attack_speed": "vitesse d'attaque",
	"cast_speed": "vitesse d'incantation",
	"attack_range": "allonge",
	"crit_chance": "chance critique",
	"crit_multiplier": "dégâts critiques",
	"move_speed": "vitesse",
}

## Statistiques rangées en fraction ou en multiplicateur, mais lues en
## pourcentage : 0.05 de chance critique s'affiche « 5 % », 1.10 de vitesse
## d'attaque « 110 % ». Sans cette liste, les statistiques les plus
## intéressantes du jeu annonceraient « 0 » une fois arrondies.
const SCALED := [
	"crit_chance",
	"crit_multiplier",
	"attack_speed",
	"cast_speed",
]

## Statistiques déjà comptées en points de pourcentage : 75 veut dire 75 %, il
## n'y a rien à multiplier, seulement un signe à afficher. Distincte de SCALED
## parce que confondre les deux donnerait « 7500 % de résistance au feu ».
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


func _init(p_stat: String, p_mode: Mode, p_value: float) -> void:
	stat = p_stat
	mode = p_mode
	value = p_value


## Une valeur de statistique dans son unité. L'infobulle d'un affixe et la fiche
## de personnage doivent écrire « 110 % » de la même façon, sinon les deux
## finiront par diverger d'un arrondi.
static func format(stat_name: String, v: float, signed := false) -> String:
	var fmt := "%+" if signed else "%"
	if stat_name in SCALED:
		return (fmt + "d %%") % roundi(v * 100.0)
	if stat_name in PERCENT_POINTS:
		return (fmt + "d %%") % roundi(v)
	# Sans décimale quand il n'y en a pas : « 6 dégâts » et non « 6.0 ».
	if is_equal_approx(v, roundf(v)):
		return (fmt + "d") % roundi(v)
	return (fmt + ".1f") % v


## Une jauge « courant / maximum », telle qu'elle s'affiche.
##
## La valeur courante est arrondie **vers le haut** : à 0,4 PV on est vivant, et
## annoncer 0 alors qu'on tient encore est un mensonge. Mais jamais au-delà du
## maximum affiché, sinon un personnage à 215,4 PV sur 215,4 lit « 216 / 215 » —
## le même mensonge à l'autre bout de la barre.
static func gauge(current: float, maximum: float) -> String:
	var haut := roundi(maximum)
	return "%d / %d" % [mini(ceili(current), haut), haut]


## La part qu'une jauge remplit, entre 0 et 1. Le pendant de gauge() : l'une donne
## la longueur de la barre, l'autre le compte à côté, et les deux doivent parler
## de la même fraction.
##
## La garde est le point important : un maximum nul existe vraiment — un
## personnage sans réserve de mana, un acteur dont la fiche n'est pas encore
## posée — et sans elle c'est une division par zéro, pas une barre vide.
static func ratio(current: float, maximum: float) -> float:
	return 0.0 if maximum <= 0.0 else clampf(current / maximum, 0.0, 1.0)


## La valeur d'un modificateur, sans le nom de la statistique. Un modificateur en
## pourcentage porte son unité du fait de son mode, quelle que soit celle de la
## statistique visée ; c'est la valeur absolue qui a besoin de format().
static func value_label(stat_name: String, p_mode: Mode, v: float, signed := true) -> String:
	if p_mode == Mode.PERCENT:
		return ("%+d %%" if signed else "%d %%") % roundi(v)
	return format(stat_name, v, signed)


## Une fourchette, telle que l'infobulle des paliers l'écrit : « 45–58 »,
## « 8–11 % ». Sans signe — une plage annonce ce qu'un affixe **peut** donner, et
## un « + » sur chaque borne se lit comme deux valeurs plutôt qu'un intervalle.
static func range_label(stat_name: String, p_mode: Mode, lo: float, hi: float) -> String:
	var bas := value_label(stat_name, p_mode, lo, false)
	var haut := value_label(stat_name, p_mode, hi, false)
	# L'unité ne se répète pas dans une plage : « 8 %–11 % » se lit deux fois.
	if bas.ends_with(" %") and haut.ends_with(" %"):
		bas = bas.trim_suffix(" %")
	return "%s–%s" % [bas, haut]


func label() -> String:
	return "%s %s" % [value_label(stat, mode, value), LABELS.get(stat, stat)]


## Applique une liste à des statistiques, **les plats d'abord**.
##
## En deux passes et non dans l'ordre d'arrivée : sinon un +10 plat appliqué
## après un +50 % vaut moins que le même +10 appliqué avant, et deux objets
## identiques ne donneraient pas le même résultat selon l'ordre d'équipement.
static func apply_all(stats: CharacterStats, mods: Array) -> void:
	for m in mods:
		if m.mode == Mode.FLAT:
			stats.set(m.stat, float(stats.get(m.stat)) + m.value)
	for m in mods:
		if m.mode == Mode.PERCENT:
			stats.set(m.stat, float(stats.get(m.stat)) * (1.0 + m.value * 0.01))
