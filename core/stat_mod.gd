class_name StatMod
extends RefCounted

## Une modification de statistique : « +6 dégâts », « +12 % de PV ».
##
## Une seule structure pour l'implicite d'une base d'objet et pour ses affixes
## tirés au hasard. Les deux disent la même chose — quel champ, de combien, à
## plat ou en pourcentage — et tout ce qui les lit (le calcul des stats du
## joueur, l'infobulle) n'a donc qu'une forme à connaître.
##
## Pas une Resource : un modificateur tiré au hasard n'existe que dans une
## partie, il n'a rien à faire sur le disque. Ce sont les *définitions*
## (ItemAffix) qui sont des `.tres`.

enum Mode { FLAT, PERCENT }

## Le nom lisible de chaque statistique, au même endroit pour toute l'interface.
## Les clés sont les champs de CharacterStats : une faute se voit à l'écran
## plutôt que de modifier silencieusement une statistique inexistante — et le
## test de la réserve d'affixes vérifie que chacune existe.
##
## L'unité fait partie du nom quand elle n'est pas évidente — « PV/s » plutôt
## que « régénération », qui laisserait croire à un pourcentage.
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


## Une valeur de statistique dans son unité. Statique et partagée : l'infobulle
## d'un affixe et la fiche de personnage doivent écrire « 110 % » de la même
## façon, sinon les deux finiront par diverger d'un arrondi.
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


## Une jauge « courant / maximum », telle qu'elle s'affiche. Le HUD et la fiche
## de personnage l'écrivaient chacun de leur côté, et le mana une troisième fois.
##
## La valeur courante est arrondie **vers le haut** : à 0,4 PV on est vivant, et
## annoncer 0 alors qu'on tient encore est un mensonge. Mais jamais au-delà du
## maximum affiché — sans ce plafond, un personnage à 215,4 PV sur 215,4 lisait
## « 216 / 215 », le même mensonge à l'autre bout de la barre. Les deux règles
## vont ensemble et n'ont qu'un seul endroit où être écrites.
static func gauge(current: float, maximum: float) -> String:
	var haut := roundi(maximum)
	return "%d / %d" % [mini(ceili(current), haut), haut]


func label() -> String:
	var nom: String = LABELS.get(stat, stat)
	# Un modificateur en pourcentage porte son unité du fait de son mode, quelle
	# que soit celle de la statistique visée : « +12 % PV » comme « +8 % vitesse
	# d'attaque ». C'est la valeur absolue qui a besoin de format().
	if mode == Mode.PERCENT:
		return "%+d %% %s" % [roundi(value), nom]
	return "%s %s" % [format(stat, value, true), nom]


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
