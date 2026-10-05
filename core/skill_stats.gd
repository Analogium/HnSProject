class_name SkillStats
extends RefCounted

## Ce qu'un lancer fait vraiment : les nombres de la compétence après modificateurs.
## Le résultat d'un lancer, jamais gardé, donc jamais périmé. Hors de
## `CharacterStats` : c'est la propriété d'un geste, pas d'un corps.

## Ce qu'un modificateur peut viser, et son nom à l'écran — en plus des dégâts
## ajoutés `damage_<nature>`. `damage` ne se vise qu'en pourcentage et multiplie
## toutes les parts. Pas de coût. **`use_time` et `recharge` y sont depuis le
## jalon 23** : la cadence et la récupération du porteur les tiennent déjà, mais un
## nœud change ce que la compétence demande — « plus de recharge » se dit par −100 %
## de `recharge`. `interval` n'y est pas : il se déduit des deux. Depuis le jalon 34,
## les **nombres de mécanique** — zéro sur la compétence, un nœud les allume, la forme
## les lit — et `period`, `self_burn`, `status_chance_increase`, que ses échanges visent ;
## `mana_per_second` depuis le jalon 35, `self_heal` depuis le 36, que le buff draine et
## rend depuis son lancer résolu ; `self_wither` et `inflict_chance` depuis le 38.
const LABELS := {
	DAMAGE: "dégâts",
	LEVELS: "niveaux de compétence",
	"projectiles": "nombre de projectiles",
	"projectile_speed": "vitesse de projectile",
	"targets": "nombre de cibles",
	"duration": "durée",
	"radius": "rayon",
	"simultaneous": "maximum simultané",
	CRIT_CHANCE: "chance critique de base",
	# La page du manuel dit « temps d'attaque » ou « temps d'incantation » : elle
	# connaît la cadence de la compétence, une ligne de modificateur non.
	"use_time": "temps du geste",
	"recharge": "recharge",
	"period": "intervalle des frappes",
	"self_burn": "brûlure subie",
	"status_chance_increase": "chance d'état",
	"mana_per_second": "mana drainé",
	"self_heal": "soin",
	"self_wither": "vie rongée",
	"inflict_chance": "chance de l'état posé",
	CHILL_EFFECT: "effet du transi",
	PIERCE: "nombre d'ennemis traversés",
	SPLITS: "nombre d'éclats",
	GROUND: "secondes de sol laissé",
	END_BURST: "rayon de l'explosion finale",
	KILL_BURST: "rayon de l'explosion des tués",
	SEEK: "rayon de chasse",
	BROOD: "nombre de serpents",
	CRAWL_SPEED: "vitesse de reptation",
	HATCHLINGS: "nombre de petits",
	BOUNCES: "nombre de rebonds",
	JUMP_REACH: "portée des sauts",
	JUMP_GAIN: "dégâts en plus par saut",
	TRAIL_CHARGES: "charges statiques semées",
	PULL: "force d'aspiration",
	DECAY_EFFECT: "effet de la décomposition",
	WILTING_WEAKNESS: "affaiblissement du flétri",
	CURSE_EFFECT: "effet de la malédiction",
	CONTAGION: "rayon de contagion",
	MINION_LIFE: "PV des morts-vivants",
	BONE_WALL: "dégâts subis retirés par mort-vivant",
	COLOSSUS: "rayon de frappe du colosse",
	TRIBUTE: "mana par ennemi maudit",
	SHARED_BURDEN: "rayon du fardeau partagé",
	BLEED_EFFECT: "effet du saignement",
	KNOCKBACK: "recul",
	LIFE_ON_HIT: "PV par ennemi touché",
	MANA_ON_HIT: "mana par ennemi touché",
	BLADE_WARD: "dégâts subis retirés par épée",
	SWORD_VOLLEY: "portée de la volée d'épées",
	WAVES: "nombre de vagues",
	EXTRA_SWORDS: "nombre d'épées en plus par lancer",
	BLESSING_EFFECT: "effet de la bénédiction",
	WAVE_GAIN: "dégâts en plus par onde",
	AUREOLE: "rayon de l'auréole",
	NUMB_EFFECT: "effet de l'engourdi",
	RESONANCE: "secondes gagnées par sort",
	SIPHON: "mana par ennemi tué",
	STACK_HOLD: "secondes de tenue des charges",
	DISSONANCE: "nombre de charges",
	TEMPO: "secondes de recharge rendues",
	PERFECT_CHORD: "dégâts en plus de l'accord",
	REACTION_POWER: "puissance des réactions",
	PRIMER: "état prêté",
	DOLL_LIFE: "PV de la poupée",
	GRUDGE: "dégâts encaissés rendus",
	TRANSFER: "dégâts subis détournés",
	LURE: "portée de l'appeau",
	ECHO_POWER: "dégâts rejoués",
	ECHOES: "nombre d'échos",
	COUNTERSONG: "élément d'avance de l'écho",
}

## L'accord de chaque libellé, comme `StatMod.AGREEMENT`.
const AGREEMENT := {
	DAMAGE: "mp",
	LEVELS: "mp",
	"projectiles": "ms",
	"projectile_speed": "fs",
	"targets": "ms",
	"duration": "fs",
	"radius": "ms",
	"simultaneous": "ms",
	CRIT_CHANCE: "fs",
	"use_time": "ms",
	"recharge": "fs",
	"period": "ms",
	"self_burn": "fs",
	"status_chance_increase": "fs",
	"mana_per_second": "ms",
	"self_heal": "ms",
	"self_wither": "fs",
	"inflict_chance": "fs",
	CHILL_EFFECT: "ms",
	PIERCE: "ms",
	SPLITS: "ms",
	GROUND: "fp",
	END_BURST: "ms",
	KILL_BURST: "ms",
	SEEK: "ms",
	BROOD: "ms",
	CRAWL_SPEED: "fs",
	HATCHLINGS: "ms",
	BOUNCES: "ms",
	JUMP_REACH: "fs",
	JUMP_GAIN: "mp",
	TRAIL_CHARGES: "fp",
	PULL: "fs",
	DECAY_EFFECT: "ms",
	WILTING_WEAKNESS: "ms",
	CURSE_EFFECT: "ms",
	CONTAGION: "ms",
	MINION_LIFE: "mp",
	BONE_WALL: "mp",
	COLOSSUS: "ms",
	TRIBUTE: "ms",
	SHARED_BURDEN: "ms",
	BLEED_EFFECT: "ms",
	KNOCKBACK: "ms",
	LIFE_ON_HIT: "mp",
	MANA_ON_HIT: "ms",
	BLADE_WARD: "mp",
	SWORD_VOLLEY: "fs",
	WAVES: "ms",
	EXTRA_SWORDS: "ms",
	BLESSING_EFFECT: "ms",
	WAVE_GAIN: "mp",
	AUREOLE: "ms",
	NUMB_EFFECT: "ms",
	RESONANCE: "fp",
	SIPHON: "ms",
	STACK_HOLD: "fp",
	DISSONANCE: "ms",
	TEMPO: "fp",
	PERFECT_CHORD: "mp",
	REACTION_POWER: "fs",
	PRIMER: "ms",
	DOLL_LIFE: "mp",
	GRUDGE: "mp",
	TRANSFER: "mp",
	LURE: "fs",
	ECHO_POWER: "mp",
	ECHOES: "ms",
	COUNTERSONG: "ms",
}

## Les nombres de mécanique (jalon 34). Chacun est lu par les formes qui en ont l'usage,
## et **seulement par elles** : ARCHITECTURE, « Que pose un lancer », dit lesquelles.
const PIERCE := "pierce"
const SPLITS := "splits"
const GROUND := "ground_duration"
const END_BURST := "end_burst"
const KILL_BURST := "kill_burst"
const SEEK := "seek_radius"
## Ceux du serpent, **pas ceux des projectiles** : il n'en est pas un, et « +1 projectile »
## sur un serpent ferait croire que les affixes de projectile le touchent. Des serpents en
## plus du premier, sa vitesse accrue en points de pourcentage, ses petits à sa mort.
const BROOD := "brood"
const CRAWL_SPEED := "crawl_speed"
const HATCHLINGS := "hatchlings"
## Ceux de la foudre (jalon 35) : les rebonds d'un tir, la portée d'un saut de chaîne et
## ce que chaque saut ajoute en « plus » (en points de pourcentage), les charges statiques
## qu'une ruée sème sur son trajet.
const BOUNCES := "bounces"
const JUMP_REACH := "jump_reach"
const JUMP_GAIN := "jump_gain"
const TRAIL_CHARGES := "trail_charges"
## Ceux du froid (jalon 36) : la force du transi posé, en points de pourcentage, et la
## vitesse vers le cœur que donne chaque impulsion du vortex (un recul inversé).
const CHILL_EFFECT := "chill_effect"
const PULL := "pull"
## Ceux de la nécrose (jalon 38). La force de l'état **posé** par le lancer, en points de
## pourcentage — `StatusEffects.State.strength`, comme le transi —, une par état : chacun
## n'est visé que par un arbre. Puis la décomposition qui gagne les voisins (un rayon),
## les morts-vivants (PV accrus, abri par tête, le cercle du colosse), le tribut de la malédiction
## (mana par maudit) et le fardeau de la Nécrose (le rayon où frappe ce qu'elle ronge).
const DECAY_EFFECT := "decay_effect"
const WILTING_WEAKNESS := "wilting_weakness"
const CURSE_EFFECT := "curse_effect"
const CONTAGION := "contagion"
const MINION_LIFE := "minion_life"
const BONE_WALL := "bone_wall"
const COLOSSUS := "colossus"
const TRIBUTE := "tribute"
const SHARED_BURDEN := "shared_burden"
## Ceux du chevalier (jalon 39) : la force du saignement tiré, le recul d'un coup (une
## vitesse, comme `knockback_force`), ce que rend chaque ennemi touché, l'abri par épée
## de la couronne (comme le Rempart d'os), la portée de la volée de ses épées, les épées
## qu'un lancer fait naître en plus, et des vagues en plus — pas des projectiles, une vague
## n'en est pas un.
const BLEED_EFFECT := "bleed_effect"
const KNOCKBACK := "knockback"
const LIFE_ON_HIT := "life_on_hit"
const MANA_ON_HIT := "mana_on_hit"
const BLADE_WARD := "blade_ward"
const SWORD_VOLLEY := "sword_volley"
const WAVES := "waves"
const EXTRA_SWORDS := "extra_swords"
## Ceux du sacré (jalon 40) : la force de la bénédiction tirée, ce que chaque onde de la
## pulsation ajoute en « plus » (en points de pourcentage, comme `jump_gain`), et le rayon
## où la Lumière bénit tant qu'elle brûle.
const BLESSING_EFFECT := "blessing_effect"
const WAVE_GAIN := "wave_gain"
const AUREOLE := "aureole"
## Ceux de la sorcière (jalon 41) : la force de l'engourdi tiré, ce que chaque sort lancé
## rend de durée à l'Amplification, le mana que rend chaque ennemi tué d'un sort sous elle.
const NUMB_EFFECT := "numb_effect"
const RESONANCE := "resonance"
const SIPHON := "siphon"
## Ceux des arbres de Trinité, de la Catalyse, de la Poupée et du Familier (jalon 41). En
## points de pourcentage : l'accord, les réactions, les PV de la poupée, ce qu'elle rend et
## détourne, la part d'un écho.
const STACK_HOLD := "stack_hold"
const DISSONANCE := "dissonance"
const TEMPO := "tempo"
const PERFECT_CHORD := "perfect_chord"
const REACTION_POWER := "reaction_power"
const PRIMER := "primer"
const DOLL_LIFE := "doll_life"
const GRUDGE := "grudge"
const TRANSFER := "transfer"
const LURE := "lure"
const ECHO_POWER := "echo_power"
const ECHOES := "echoes"
const COUNTERSONG := "countersong"
## Ceux qui changent **ce que fait** le lancer, pas combien : la pastille d'un nœud les
## signale avant qu'on le survole.
const MECHANICS := [
	PIERCE, SPLITS, GROUND, END_BURST, KILL_BURST, SEEK, BROOD, HATCHLINGS,
	BOUNCES, JUMP_GAIN, TRAIL_CHARGES, PULL, CONTAGION, BONE_WALL, COLOSSUS, TRIBUTE,
	SHARED_BURDEN, KNOCKBACK, LIFE_ON_HIT, MANA_ON_HIT, BLADE_WARD, SWORD_VOLLEY, WAVES,
	EXTRA_SWORDS, WAVE_GAIN, AUREOLE, RESONANCE, SIPHON, DISSONANCE, TEMPO, PERFECT_CHORD,
	PRIMER, GRUDGE, TRANSFER, LURE, ECHOES, COUNTERSONG,
]
## Le nombre qui accroît la force de chaque état, quand un arbre en a un : **le seul
## lien** entre un état et sa force, que `strength_of()` et la fiche lisent.
const EFFECT_OF := {
	StatusEffects.Kind.CHILL: CHILL_EFFECT,
	StatusEffects.Kind.NUMB: NUMB_EFFECT,
	StatusEffects.Kind.BLEED: BLEED_EFFECT,
	StatusEffects.Kind.BLESSING: BLESSING_EFFECT,
	StatusEffects.Kind.DECAY: DECAY_EFFECT,
	StatusEffects.Kind.WILTING: WILTING_WEAKNESS,
	StatusEffects.Kind.CURSED: CURSE_EFFECT,
}

## Le sol brûlant : sa part des dégâts par impulsion, son rythme, son rayon. Et la part
## d'un coup que rend l'explosion d'un tué.
const GROUND_PART := 0.25
const GROUND_PERIOD := 0.5
const GROUND_RADIUS := 14.0
const KILL_BURST_PART := 0.5
const SPLIT_PART := 0.4
## La part d'un coup de la ruée que porte chaque charge de son sillage statique.
const TRAIL_CHARGE_PART := 0.5
## La recharge d'un geste affranchi (l'Armure de givre), **fixe** : ni nœud ni
## récupération ne la bougent. Le prix de marcher sous sa protection.
const FREED_RECHARGE := 5.0
## La vie des petits qu'un serpent relâche (`SPLITS` sur `HellSnake`).
const HATCHLING_LIFE := 2.0
## Le Colosse d'os : ses PV, en multiple de ceux d'un mort-vivant, et son échelle. Le
## cercle qu'il frappe est le nombre lui-même ; ses dégâts, une ligne du nœud.
const COLOSSUS_LIFE := 3.0
const COLOSSUS_SCALE := 1.7
## Le fardeau partagé : ce que la Nécrose ronge, rendu à ce multiple aux ennemis proches,
## tous les combien.
const BURDEN_FACTOR := 4.0
const BURDEN_PERIOD := 1.0
## La Marque de mort : combien elle maudit plus fort qu'un sceau.
const MARK_FACTOR := 2.0
## L'Auréole : tous les combien elle bénit ce qui est dans son cercle.
const AUREOLE_PERIOD := 0.5

const DAMAGE := "damage"
## Le seul nombre du lancer qu'un modificateur **sans portée** atteint : sa base est sur
## la compétence, pas sur la fiche.
const CRIT_CHANCE := "crit_chance"
## Des points de compétence en plus de ceux placés, à plat et **toujours portés par un
## mot-clé** : la fiche n'a pas de niveau de compétence.
const LEVELS := "skill_levels"

## Le début du nom d'une statistique de dégâts ajoutés : `damage_` puis
## l'identifiant d'une nature.
const ADDED_PREFIX := "damage_"

## Le début du nom d'une statistique de dégâts contre un état : `damage_vs_` puis
## l'identifiant de l'état (`StatusEffects.IDS`).
const AGAINST_PREFIX := "damage_vs_"

## L'écart minimal entre deux traits voisins, en degrés : sans lui, « +1 projectile »
## sur un trait droit en superposerait deux.
const MIN_SPREAD := 8.0

## L'identifiant de la compétence, pour le compteur de DPS.
var skill_id := ""

## Les dégâts **par nature et en fourchette**, indexés par `DamageType.Kind`.
var damage_min: Array[float] = DamageType.empty_parts()
var damage_max: Array[float] = DamageType.empty_parts()
## Réels pendant la résolution, arrondis par `finalize()` : arrondir à chaque
## modificateur ferait dépendre le résultat de leur ordre.
var projectiles := 1.0
var spread_in_degrees := 0.0
var projectile_speed := 0.0
## Réels puis arrondis, comme `projectiles`.
var targets := 1.0
var simultaneous := 0.0
var duration := 0.0
var radius := 0.0
var period := 0.0
var self_burn := 0.0
var mana_per_second := 0.0
var self_heal := 0.0
var self_wither := 0.0
## Ce que ce lancer accroît à la chance de poser son état, en points de pourcentage.
var status_chance_increase := 0.0
## L'état qu'il pose à ce qu'il touche, et sa chance (`Skill.inflicted_state`).
var inflicted_state := -1
var inflict_chance := 1.0
## Les coups d'un geste, que la forme décide.
var hits := 1
## Celle de la compétence, ou celle qu'un nœud lui a substituée : **le lancer se pose
## par elle**, jamais par `Skill.shape`.
var shape := 0
## Les nombres de mécanique, à zéro tant qu'aucun nœud ne les allume.
var pierce := 0.0
var splits := 0.0
var ground_duration := 0.0
var end_burst := 0.0
var kill_burst := 0.0
var seek_radius := 0.0
var brood := 0.0
var crawl_speed := 0.0
var hatchlings := 0.0
var bounces := 0.0
var jump_reach := 0.0
var jump_gain := 0.0
var trail_charges := 0.0
var chill_effect := 0.0
var pull := 0.0
var decay_effect := 0.0
var wilting_weakness := 0.0
var curse_effect := 0.0
var contagion := 0.0
var minion_life := 0.0
var bone_wall := 0.0
var colossus := 0.0
var tribute := 0.0
var shared_burden := 0.0
var bleed_effect := 0.0
var knockback := 0.0
var life_on_hit := 0.0
var mana_on_hit := 0.0
var blade_ward := 0.0
var sword_volley := 0.0
var waves := 0.0
var extra_swords := 0.0
var blessing_effect := 0.0
var wave_gain := 0.0
var aureole := 0.0
var numb_effect := 0.0
var resonance := 0.0
var siphon := 0.0
var stack_hold := 0.0
var dissonance := 0.0
var tempo := 0.0
var perfect_chord := 0.0
var reaction_power := 0.0
var primer := 0.0
var doll_life := 0.0
var grudge := 0.0
var transfer := 0.0
var lure := 0.0
var echo_power := 0.0
var echoes := 0.0
var countersong := 0.0
## Celui de la compétence, sauf un nœud qui l'affranchit (`TalentNode.frees`).
var binds_caster := false
## Vrai pour ce qui n'a pas de fin — l'aura, le buff, le cyclone : pas de « par lancer ».
var sustained := false
var mana_cost := 0.0
## Le temps du geste et la recharge, séparés parce que **rien ne les change ensemble** :
## la cadence du lanceur agit sur le premier, la récupération sur la seconde.
var use_time := 0.0
var recharge := 0.0

## Ce que la case attend : le plus long des deux, calculé et jamais rangé — une seule
## vérité (`Skill.interval()` dit la même chose avant résolution).
var interval: float:
	get:
		return maxf(use_time, recharge)
## Tirés à chaque coup par `DamageInfo.roll()`. Le multiplicateur est celui de la fiche.
var crit_chance := 0.0
var crit_multiplier := 1.0

## Les mots-clés que ce lancer porte vraiment, nœuds compris : c'est cette liste
## qui a filtré les modificateurs.
var keywords := PackedStringArray()

## Ce que `LEVELS` a ajouté aux points placés, pour la page du manuel.
var bonus_levels := 0

## Par état de la cible, indexés par `StatusEffects.Kind` : la somme des accrus en
## points de pourcentage, et le produit des « plus ». Lus au coup, par la hurtbox.
var against_increased: Array[float] = []
var against_more: Array[float] = []

## La nature du lancer : celle de la compétence, ou celle où une conversion l'a
## emmenée (jalon 34 : tout ou rien). Ce qu'un objet ajoute garde la sienne.
var nature := int(DamageType.Kind.PHYSICAL)

## La décomposition pour la fiche du manuel, **écrite par les appels qui calculent**
## les dégâts : recomposée à côté, elle finirait par mentir.
var base_damage := 0.0
var added_min: Array[float] = DamageType.empty_parts()
var added_max: Array[float] = DamageType.empty_parts()
## Les « % dégâts » portés, en facteurs : les accrus sommés (deux « +10 % » font 1,20),
## puis le produit des « plus » (deux font 1,21).
var increased := 1.0
var more := 1.0


func _init() -> void:
	against_increased.resize(StatusEffects.Kind.size())
	against_increased.fill(0.0)
	against_more.resize(StatusEffects.Kind.size())
	against_more.fill(1.0)


## La nature ajoutée par cette statistique, ou -1.
static func added_nature(stat: String) -> int:
	if not stat.begins_with(ADDED_PREFIX):
		return -1
	return DamageType.IDS.find(stat.trim_prefix(ADDED_PREFIX))


static func added_stat(nature: DamageType.Kind) -> String:
	return ADDED_PREFIX + DamageType.IDS[nature]


## « 3–7 », ou « 23 » quand les deux bornes s'arrondissent au même nombre : des
## dégâts résolus sont des réels, et « 29–29 » se lirait comme une faute.
static func readable_range(low: float, top: float) -> String:
	var b := roundi(low)
	var h := roundi(top)
	return str(b) if b == h else "%d–%d" % [b, h]


## L'état visé par cette statistique, ou -1.
static func against(stat: String) -> int:
	if not stat.begins_with(AGAINST_PREFIX):
		return -1
	return StatusEffects.IDS.find(stat.trim_prefix(AGAINST_PREFIX))


static func against_stat(kind: StatusEffects.Kind) -> String:
	return AGAINST_PREFIX + StatusEffects.IDS[kind]


## Un nombre nommé, des dégâts ajoutés d'une nature connue, ou contre un état connu.
static func modifiable(stat: String) -> bool:
	return LABELS.has(stat) or added_nature(stat) >= 0 or against(stat) >= 0


func projectile_count() -> int:
	return int(projectiles)


func target_count() -> int:
	return int(targets)


func max_simultaneous() -> int:
	return int(simultaneous)


## Une impulsion à la pose, puis une par période ; l'epsilon absorbe l'arrondi d'une
## durée modifiée. **Le nuage compte ses frappes par ici**, comme la fiche.
func strikes_over_duration() -> int:
	if duration <= 0.0 or period <= 0.0:
		return 1
	return maxi(floori(duration / period + 0.0001), 1)


## Combien d'impulsions un geste qui dure doit avoir données à cet âge : la n-ième part
## à n périodes, jusqu'à `strikes_over_duration()`. Le nuage, le pilier, la pulsation,
## le vortex, la trace d'une ruée et le portail l'écrivaient chacun.
func strikes_due(age: float) -> int:
	var total := strikes_over_duration()
	var due := 0
	while due < total and age >= float(due) * period:
		due += 1
	return due


## « Projectile · Foudre · Sort », nœuds compris.
func keywords_label() -> String:
	return Keywords.line(keywords)


## Les dégâts propres de la compétence, dans sa nature, bornes égales.
func place_the_base(nature: int, amount: float) -> void:
	base_damage = amount
	damage_min[nature] += amount
	damage_max[nature] += amount


## La borne haute ne descend jamais sous la basse.
func add_to(nature: int, low: float, top: float) -> void:
	var top_point := maxf(top, low)
	added_min[nature] += low
	added_max[nature] += top_point
	damage_min[nature] += low
	damage_max[nature] += top_point


## Toutes les parts, une fois. Un accru sous −100 % ne rend pas les dégâts négatifs.
func scale_damage(increased_percent: float, more_factor: float) -> void:
	increased = maxf(1.0 + increased_percent * 0.01, 0.0)
	more = more_factor
	for i in damage_min.size():
		damage_min[i] *= increased * more
		damage_max[i] *= increased * more


## Le facteur d'un coup sur cette cible : l'accru d'un état **s'ajoute aux accrus du
## lancer** (§2 du jalon 14), le « plus » multiplie. Un pour une cible sans état, et
## pour un lancer qui ne vise aucun état — le cas de presque tous les coups.
func against_factor(states: StatusEffects) -> float:
	if states == null or states.is_clear:
		return 1.0
	var added := 0.0
	var product := 1.0
	for kind in against_increased.size():
		if (against_increased[kind] != 0.0 or against_more[kind] != 1.0) and states.active(kind):
			added += against_increased[kind]
			product *= against_more[kind]
	if increased <= 0.0:
		return product
	return maxf(increased + added * 0.01, 0.0) / increased * product


## La part de chaque nature, somme à un ; toute dans sa nature sans dégâts.
## Ce qu'un objet ajoute compte.
func distribution() -> Array[float]:
	var out := DamageType.empty_parts()
	var total := total_min() + total_max()
	if total <= 0.0:
		out[nature] = 1.0
		return out
	for i in out.size():
		out[i] = (damage_min[i] + damage_max[i]) / total
	return out


func total_min() -> float:
	var total := 0.0
	for part in damage_min:
		total += part
	return total


func total_max() -> float:
	var total := 0.0
	for part in damage_max:
		total += part
	return total


## Les chiffres des mécaniques, pour les descriptions des nœuds (`{part_sol}`…) : lus
## ici, sur les constantes mêmes qui les appliquent.
static func facts() -> Dictionary:
	return {
		"part_sol": roundi(GROUND_PART * 100.0),
		"rythme_sol": GROUND_PERIOD,
		"rayon_sol": roundi(GROUND_RADIUS),
		"part_eclat": roundi(SPLIT_PART * 100.0),
		"part_tue": roundi(KILL_BURST_PART * 100.0),
		"vie_petit": roundi(HATCHLING_LIFE),
		"part_charge": roundi(TRAIL_CHARGE_PART * 100.0),
		"recharge_libre": roundi(FREED_RECHARGE),
		"vie_colosse": roundi(COLOSSUS_LIFE),
		"fardeau": roundi(BURDEN_FACTOR),
		"rythme_fardeau": BURDEN_PERIOD,
		"force_marque": roundi(MARK_FACTOR),
	}


## Le lancer du sol brûlant qu'il laisse : un lancer dérivé, rythmé comme un sillage.
## `GROUND_RADIUS` sous un impact ; la nova pose le sien à sa taille (jalon 36).
func ground(p_radius := GROUND_RADIUS) -> SkillStats:
	var g := _derived(GROUND_PART)
	g.duration = ground_duration
	g.period = GROUND_PERIOD
	g.radius = p_radius
	return g


## Le lancer d'un éclat : la moitié du rayon, pour qu'une explosion d'éclat ne se lise pas
## comme celle du tir.
func shard() -> SkillStats:
	var g := _derived(SPLIT_PART)
	g.projectile_speed = projectile_speed
	g.radius = radius * 0.5
	return g


## Un lancer né d'un autre, à une part de ses dégâts : ce qui qualifie un coup —
## mots-clés, critique, chances d'état, bonus contre un état — et **rien de ce qui en
## ferait naître un autre** (ni sol, ni éclat, ni explosion, ni état posé), sinon un sol
## en poserait un autre.
func _derived(part: float) -> SkillStats:
	var g := SkillStats.new()
	g.skill_id = skill_id
	g.nature = nature
	g.shape = shape
	g.keywords = keywords
	for i in damage_min.size():
		g.damage_min[i] = damage_min[i] * part
		g.damage_max[i] = damage_max[i] * part
	g.increased = increased
	g.against_increased = against_increased.duplicate()
	g.against_more = against_more.duplicate()
	g.crit_chance = crit_chance
	g.crit_multiplier = crit_multiplier
	g.status_chance_increase = status_chance_increase
	g.chill_effect = chill_effect
	g.numb_effect = numb_effect
	g.crawl_speed = crawl_speed
	return g


## Le même lancer à une part de ses dégâts, **tout compris** : ce que rejoue le Familier
## (jalon 41) est le sort entier, son sol, ses éclats et son état posé avec.
func echoed(part: float) -> SkillStats:
	var g := SkillStats.new()
	for p in get_property_list():
		# `interval` se déduit : il n'a rien à recopier.
		if p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE and p["name"] != "interval":
			var value: Variant = get(p["name"])
			g.set(p["name"], value.duplicate() if value is Array else value)
	for i in damage_min.size():
		g.damage_min[i] *= part
		g.damage_max[i] *= part
	return g


## Les dégâts répartis à parts égales entre ces natures : la Triade, dont les trois comètes
## portent chacune son élément (jalon 41). La fiche et le tirage des états lisent ces parts.
func blend(natures: Array[int]) -> void:
	var low := total_min() / float(natures.size())
	var top := total_max() / float(natures.size())
	damage_min.fill(0.0)
	damage_max.fill(0.0)
	for n in natures:
		damage_min[n] += low
		damage_max[n] += top


## Le multiplicateur d'effet de cet état quand ce lancer le pose : 1, plus ce que l'arbre
## y ajoute — le transi qu'il tire, l'état qu'il pose (jalon 38) —, fois deux sous la
## Marque de mort. **Le seul calcul** : la fiche l'affiche, le coup et le sceau le posent.
func strength_of(kind: int) -> float:
	var effect := float(get(EFFECT_OF[kind])) if EFFECT_OF.has(kind) else 0.0
	var factor := 1.0 + effect * 0.01
	if kind == inflicted_state and shape == Skill.Shape.MARK:
		factor *= MARK_FACTOR
	return factor


## Le milieu de chaque fourchette.
func average_per_hit() -> float:
	return (total_min() + total_max()) * 0.5


## Un lancer entier **si tout touche**, avant défenses et sans critique :
## projectiles × vagues × cibles × coups × frappes dans la durée. Zéro pour une aura.
func average_per_cast() -> float:
	if sustained:
		return 0.0
	var strikes := 0.0
	for i in strikes_over_duration():
		strikes += wave_factor(i)
	var count := projectile_count() * (1 + int(waves)) * target_count() * hits
	return average_per_hit() * float(count) * strikes


## Ce que porte la frappe `index` d'un geste qui dure, sous l'Exaltation (jalon 40) :
## chaque onde déjà partie ajoute son gain. Le seul calcul, que la pulsation et
## l'estimation lisent.
func wave_factor(index: int) -> float:
	return 1.0 + wave_gain * 0.01 * float(index)


## Par l'intervalle entre deux lancers, sans compter la réserve ; pour une aura, un
## coup par période. Une orbite est bornée par son maximum simultané.
func average_per_second() -> float:
	if sustained:
		return average_per_hit() / period if period > 0.0 else 0.0
	if interval <= 0.0:
		return 0.0
	var per_second := average_per_cast() / interval
	if max_simultaneous() > 0 and period > 0.0:
		per_second = minf(per_second, average_per_hit() * float(max_simultaneous()) / period)
	return per_second


## Les parts d'**un** coup : un tirage par fourchette ouverte, quel que soit le
## résultat (invariant 3).
func roll(rng: RandomNumberGenerator) -> Array[float]:
	var parts := DamageType.empty_parts()
	for i in parts.size():
		parts[i] = damage_min[i]
		if damage_max[i] > damage_min[i]:
			parts[i] = rng.randf_range(damage_min[i], damage_max[i])
	return parts


## Les bornes, une fois tous les modificateurs appliqués : dispersion bornée au tour
## complet, et une chaîne garde au moins une cible.
func finalize() -> void:
	var n := maxi(roundi(projectiles), 1)
	projectiles = float(n)
	spread_in_degrees = clampf(
		maxf(spread_in_degrees, MIN_SPREAD * float(n - 1)), 0.0, 360.0
	)
	targets = float(maxi(roundi(targets), 1))
	simultaneous = float(maxi(roundi(simultaneous), 0))
	pierce = float(maxi(roundi(pierce), 0))
	splits = float(maxi(roundi(splits), 0))
	bounces = float(maxi(roundi(bounces), 0))
	trail_charges = float(maxi(roundi(trail_charges), 0))
	waves = float(maxi(roundi(waves), 0))
	extra_swords = float(maxi(roundi(extra_swords), 0))
	duration = maxf(duration, 0.0)
	radius = maxf(radius, 0.0)
	period = maxf(period, 0.0)
	self_burn = maxf(self_burn, 0.0)
	self_wither = maxf(self_wither, 0.0)
	inflict_chance = clampf(inflict_chance, 0.0, 1.0)
	crit_chance = clampf(crit_chance, 0.0, 1.0)
