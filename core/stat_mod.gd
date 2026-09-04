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
const LABELS := {
	"max_health": "PV",
	"move_speed": "vitesse",
	"attack_damage": "dégâts",
	"attack_cooldown": "temps de recharge",
	"attack_range": "allonge",
	"damage_reduction": "armure",
	"crit_chance": "chance critique",
	"crit_multiplier": "dégâts critiques",
}

## Statistiques rangées en fraction mais lues en pourcentage : +0.03 de chance
## critique s'affiche « +3 % », +0.4 de dégâts critiques « +40 % ». Sans cette
## liste, les deux affixes les plus intéressants du jeu annonceraient « +0 »
## une fois arrondis.
const FRACTIONS := ["crit_chance", "crit_multiplier"]

var stat: String
var mode: Mode
var value: float


func _init(p_stat: String, p_mode: Mode, p_value: float) -> void:
	stat = p_stat
	mode = p_mode
	value = p_value


func label() -> String:
	var nom: String = LABELS.get(stat, stat)
	if mode == Mode.PERCENT:
		return "%+d %% %s" % [roundi(value), nom]
	if stat in FRACTIONS:
		return "%+d %% %s" % [roundi(value * 100.0), nom]
	# Sans décimale quand il n'y en a pas : « +6 dégâts » et non « +6.0 ».
	if is_equal_approx(value, roundf(value)):
		return "%+d %s" % [roundi(value), nom]
	return "%+.1f %s" % [value, nom]


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
