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
## Le mot-clé visé, ou vide pour la fiche du personnage.
##
## **Vide, `stat` est un champ de `CharacterStats`** et le modificateur agit sur
## toutes les compétences à travers la fiche. **Rempli, c'est un champ de
## `StatsDeCompetence`**, et il n'agit que sur les compétences qui portent ce
## mot-clé — sans jamais toucher la fiche, sinon le bonus compterait deux fois.
##
## Un champ ici plutôt qu'une seconde classe : un affixe est un affixe, que sa
## ligne vise la fiche ou un mot-clé, et le tirage, l'infobulle et la sauvegarde
## n'ont ainsi qu'une forme à connaître.
var portee: String
## La borne haute d'une fourchette — « ajoute 3 à **7** dégâts de froid » — et
## `value` en est alors la basse. Égale à `value` pour tout le reste : un
## modificateur ordinaire est une fourchette dont les deux bornes se confondent.
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


## Vrai pour une statistique qui se donne en fourchette plutôt qu'en un nombre :
## les dégâts ajoutés d'une nature. Le tirage d'un affixe, l'implicite d'une base,
## la ligne affichée et la sauvegarde — qui écrit ou non la borne haute — le
## demandaient chacun de leur côté.
static func stat_en_fourchette(p_stat: String) -> bool:
	return StatsDeCompetence.nature_ajoutee(p_stat) >= 0


## La ligne qu'une **définition** donne à ces valeurs : un affixe d'objet, ou
## l'implicite d'une base. Une fourchette s'ajoute toujours à plat, et sa borne
## haute ne descend jamais sous la basse.
##
## Les deux la construisaient chacun de son côté : une forme de ligne ajoutée à
## l'affixe seul aurait donné un implicite qui s'affiche et se sauvegarde
## autrement que l'affixe de la même statistique.
static func depuis_definition(
	p_stat: String, pourcentage: bool, valeur: float, valeur_max: float, p_portee: String
) -> StatMod:
	if stat_en_fourchette(p_stat):
		return fourchette(p_stat, valeur, maxf(valeur_max, valeur), p_portee)
	return StatMod.new(p_stat, Mode.PERCENT if pourcentage else Mode.FLAT, valeur, p_portee)


## Un pourcentage, écrit comme la langue l'écrit : « 20 % » en français, « 20% »
## en anglais. L'espace devant le signe est une règle typographique française, et
## le gabarit est donc un texte traduit comme un autre.
##
## **Le seul endroit qui écrit un pourcentage.** Les trois qui l'écrivaient à la
## main donneraient sinon trois typographies dans la même infobulle.
static func pourcentage(valeur: int, signe := false) -> String:
	return Textes.t("{valeur} %").format({"valeur": ("%+d" if signe else "%d") % valeur})


## L'unité telle que la langue courante l'accole au nombre : « % » et son espace
## en français, « % » seul en anglais. Déduite du gabarit lui-même, et non écrite
## une seconde fois : c'est ce qui permet à une plage de ne pas la répéter.
static func _unite_de_pourcentage() -> String:
	return pourcentage(0).trim_prefix("0")


## Une valeur de statistique dans son unité. L'infobulle d'un affixe et la fiche
## de personnage doivent écrire « 110 % » de la même façon, sinon les deux
## finiront par diverger d'un arrondi.
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
		return pourcentage(roundi(v), signed)
	return format(stat_name, v, signed)


## Une fourchette, telle que l'infobulle des paliers l'écrit : « 45–58 »,
## « 8–11 % ». Sans signe — une plage annonce ce qu'un affixe **peut** donner, et
## un « + » sur chaque borne se lit comme deux valeurs plutôt qu'un intervalle.
static func range_label(stat_name: String, p_mode: Mode, lo: float, hi: float) -> String:
	var bas := value_label(stat_name, p_mode, lo, false)
	var haut := value_label(stat_name, p_mode, hi, false)
	# L'unité ne se répète pas dans une plage : « 8 %–11 % » se lit deux fois. Elle
	# est demandée au gabarit plutôt qu'écrite ici, parce qu'elle change avec la
	# langue — « 8 % » en français, « 8% » en anglais.
	var unite := _unite_de_pourcentage()
	if bas.ends_with(unite) and haut.ends_with(unite):
		bas = bas.trim_suffix(unite)
	return "%s–%s" % [bas, haut]


## Le nom d'une statistique à l'écran. Visée par un mot-clé, elle le dit entre
## parenthèses : « +20 % dégâts » tout court se lirait comme la ligne de fiche du
## même nom, qui touche toutes les compétences.
##
## Le libellé du mot-clé est **celui de la fiche du manuel** : le joueur doit
## pouvoir rapprocher « (Projectile) » sur un objet de « Projectile » sur un sort
## sans traduire.
##
## Des dégâts ajoutés disent leur destinataire en toutes lettres — « dégâts de
## froid aux sorts » — plutôt que « (Sort) » : c'est la phrase du genre, et la
## portée y est déjà.
static func nom(stat_name: String, p_portee := "") -> String:
	if p_portee.is_empty():
		if LABELS.has(stat_name):
			return Textes.t(LABELS[stat_name])
		# Sans portée et hors de la fiche, c'est la ligne d'un nœud d'arbre : il ne
		# vise que sa propre compétence, et n'a donc pas de mot-clé à écrire. Le
		# nom reste celui du nombre visé, sinon la fiche du nœud afficherait
		# « degats » tel quel.
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


## Applique une liste à la fiche d'un personnage.
##
## **Ce qui vise un mot-clé est écarté ici**, et c'est le seul endroit qui écrit
## une liste sur la fiche : un affixe porté qui l'atteindrait quand même donnerait
## son bonus deux fois, et seulement à certaines compétences.
static func apply_all(stats: CharacterStats, mods: Array) -> void:
	var sur_la_fiche: Array[StatMod] = []
	for m: StatMod in mods:
		if m.portee.is_empty():
			sur_la_fiche.append(m)
	appliquer(stats, sur_la_fiche)


## Applique une liste aux champs d'un objet — une fiche, ou le résultat d'un
## lancer — **les plats d'abord**.
##
## En deux passes et non dans l'ordre d'arrivée : sinon un +10 plat appliqué
## après un +50 % vaut moins que le même +10 appliqué avant, et deux objets
## identiques ne donneraient pas le même résultat selon l'ordre d'équipement.
static func appliquer(cible: Object, mods: Array) -> void:
	for m: StatMod in mods:
		if m.mode == Mode.FLAT:
			cible.set(m.stat, float(cible.get(m.stat)) + m.value)
	for m: StatMod in mods:
		if m.mode == Mode.PERCENT:
			cible.set(m.stat, float(cible.get(m.stat)) * (1.0 + m.value * 0.01))
