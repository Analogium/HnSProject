class_name SkillStats
extends RefCounted

## Ce qu'un lancer fait vraiment : les nombres de la compétence après modificateurs.
## Le résultat d'un lancer, jamais gardé, donc jamais périmé. Hors de
## `CharacterStats` : c'est la propriété d'un geste, pas d'un corps.

## Ce qu'un modificateur peut viser, et son nom à l'écran — en plus des dégâts
## ajoutés `damage_<nature>`. `damage` ne se vise qu'en pourcentage et multiplie
## toutes les parts. Ni coût, ni `period`, `self_burn` ou `status_chance_increase`
## (voir `Skill`). **`use_time` et `recharge` y sont depuis le jalon 23** : la cadence
## et la récupération du porteur les tiennent déjà, mais un nœud change ce que la
## compétence demande — « plus de recharge » se dit par −100 % de `recharge`.
## `interval` n'y est pas : il se déduit des deux, le viser mentirait.
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
}

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
## Ce que ce lancer accroît à la chance de poser son état, en points de pourcentage.
var status_chance_increase := 0.0
## L'état qu'il pose à ce qu'il touche, et sa chance (`Skill.inflicted_state`).
var inflicted_state := -1
var inflict_chance := 1.0
## Les coups d'un geste, que la forme décide.
var hits := 1
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

## La nature de la compétence, avant conversion.
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
## La part du coup qu'un nœud a déplacée, **par nature d'arrivée**, pour la fiche.
## Le lancer n'en a pas besoin : `damage_min` et `damage_max` sont déjà déplacés.
var conversions: Array[float] = DamageType.empty_parts()


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


## La nature que le lancer **montre** : la sienne, ou celle où une conversion a
## emmené le plus de ses dégâts propres — jamais ce qu'un objet ajoute (jalon 8).
func dominant_nature() -> int:
	var best_one := nature
	var part := 1.0
	for p in conversions:
		part -= p
	for i in conversions.size():
		if conversions[i] > part:
			part = conversions[i]
			best_one = i
	return best_one


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


## Le nœud de conversion, appelé **après les fourchettes ajoutées** : il prend sa part
## de **chaque** nature, ajouts compris. Entière, il ne reste qu'une nature, donc
## qu'un état possible.
func apply_conversion(target: int, part: float) -> void:
	var rest := clampf(part, 0.0, 1.0)
	if rest <= 0.0:
		return
	for source in damage_min.size():
		if source == target:
			continue
		var low := damage_min[source] * rest
		var top := damage_max[source] * rest
		damage_min[source] -= low
		damage_max[source] -= top
		damage_min[target] += low
		damage_max[target] += top
		conversions[source] *= 1.0 - rest
	# La part du coup **entier** : deux nœuds à 50 % font 75 %, pas 100 %.
	conversions[target] += rest * (1.0 - conversions[target])


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
## Contrairement à `dominant_nature()`, ce qu'un objet ajoute compte.
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


## Le milieu de chaque fourchette.
func average_per_hit() -> float:
	return (total_min() + total_max()) * 0.5


## Un lancer entier **si tout touche**, avant défenses et sans critique :
## projectiles × cibles × coups × frappes dans la durée. Zéro pour une aura.
func average_per_cast() -> float:
	if sustained:
		return 0.0
	var count := projectile_count() * target_count() * hits * strikes_over_duration()
	return average_per_hit() * float(count)


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
	duration = maxf(duration, 0.0)
	radius = maxf(radius, 0.0)
	crit_chance = clampf(crit_chance, 0.0, 1.0)
