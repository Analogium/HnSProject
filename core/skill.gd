class_name Skill
extends Resource

## Ce qu'un personnage sait faire : une fiche de contenu — une Resource, donc un
## fichier de plus et non une branche de code. Elle ne connaît ni le joueur ni le
## manuel : le sens de circulation ne s'inverse jamais.

@export var id: String = ""
@export var name: String = ""

## Ce qu'elle fait, en une phrase : **le geste**, jamais ses nombres — la fiche les
## donne déjà, et deux vérités finiraient par diverger. Le texte français est la clé,
## comme `name`.
@export_multiline var description: String = ""

## La nature du coup : la résistance qui s'y oppose et sa couleur.
@export var nature: DamageType.Kind = DamageType.Kind.PHYSICAL

## `WEAPON` : l'intervalle vient de la fiche (`attack_cooldown` / `attack_speed`), et
## `cooldown` est ignorée. `CAST` : `cooldown` / `cast_speed`.
enum Cadence { WEAPON, CAST }

@export var cadence: Cadence = Cadence.CAST

## Ce que le lancer pose dans le monde, comportement et dessin ensemble — `STRIKE`
## ne diffère d'`ARC` que par le dessin. Aucun nœud ne la change.
## **Ajouter à la fin seulement** : les `.tres` écrivent l'entier.
enum Shape { ARC, BOLT, STRIKE, BALL, CHAIN, CLOUD, AURA, SNAKE, CROSS, ORBIT, DASH, BUFF }

@export var shape: Shape = Shape.ARC

## Seulement ce que ni la nature, ni la cadence, ni la forme ne donnent déjà : le
## redéclarer ferait deux vérités. Aujourd'hui le seul `melee` du coup d'arme, dont
## la forme `ARC` est celle que prend toute compétence qui n'en choisit pas.
@export var declared_keywords: PackedStringArray = PackedStringArray()

## Une nature absente ne donne aucun mot-clé : l'afficher enverrait chercher un
## affixe qui n'existe pas.
const KEYWORD_OF_CADENCE := {
	Cadence.WEAPON: Keywords.ATTACK,
	Cadence.CAST: Keywords.SPELL,
}
const KEYWORD_OF_NATURE := {
	DamageType.Kind.FIRE: Keywords.FIRE,
	DamageType.Kind.LIGHTNING: Keywords.LIGHTNING,
}
const KEYWORD_OF_SHAPE := {
	Shape.BOLT: Keywords.PROJECTILE,
	Shape.BALL: Keywords.PROJECTILE,
	Shape.STRIKE: Keywords.MELEE,
	Shape.CROSS: Keywords.MELEE,
	Shape.ORBIT: Keywords.MELEE,
	Shape.CLOUD: Keywords.AREA,
	Shape.AURA: Keywords.AREA,
	Shape.SNAKE: Keywords.AREA,
	Shape.DASH: Keywords.AREA,
}

## Ce que vaut chaque niveau au-delà de la table, composé : la pente des tables
## actuelles, environ 25 % par point (décidé au jalon 14).
const GROWTH_PER_EXTRA_LEVEL := 1.25

## Une table et non un champ : un troisième coup en croix n'aurait pas de dessin.
const HITS_PER_SHAPE := {
	Shape.CROSS: 2,
}

## En secondes, avant `cast_speed`. Ignorée à la cadence de l'arme.
@export var cooldown: float = 0.0

## Nombre de traits et écart total en degrés : 1 et 0 pour un trait, 8 et 360 pour
## une nova.
@export var projectiles: int = 1
@export var spread_in_degrees: float = 0.0

## En pixels par seconde, sur la compétence et non sur la scène du tir : deux
## compétences d'une même scène diffèrent, et un modificateur l'atteint.
@export var projectile_speed: float = 0.0

## Les nombres des formes qui ne sont pas un tir ; un test refuse une forme à qui
## manque le sien. `targets` : les ennemis d'une chaîne, le premier compris.
@export var targets: int = 1
## En secondes : ce que vit un nuage, un serpent, une épée en orbite, et ce qu'une ruée
## laisse derrière elle — sa trace ou son buff. Zéro pour ce qui ne dure pas, et pour
## l'aura, qui dure tant qu'on ne l'éteint pas.
@export var duration: float = 0.0
## En pixels : la zone d'un nuage, d'une aura, l'explosion d'une boule.
@export var radius: float = 0.0
## En secondes, entre deux frappes d'un nuage ou d'une aura, ou entre deux touches
## d'une même cible par un serpent ou une épée. **Aucun nœud ne la vise** : elle
## change le nombre de coups sans changer ce que la fiche appelle dégâts.
@export var period: float = 0.0
## Combien de ces présences peuvent exister à la fois. Zéro : sans limite.
@export var simultaneous: int = 0
## La part des PV max qu'une aura brûle au lanceur, par seconde. Hors de portée des
## nœuds : réduite à zéro, elle ferait de l'aura un sort sans prix.
@export var self_burn: float = 0.0
## La part du mana max qu'un buff draine par seconde. Épuisé, il s'éteint — là où les
## PV épuisés tuent.
@export var self_mana_burn: float = 0.0

## La part des PV max du lanceur qui s'ajoute aux dégâts propres, **par coup**. Zéro
## pour tout ce qui ne s'adosse pas à la vie de celui qui lance.
@export var health_scaling: float = 0.0

## Ce que le lancer pose sur son lanceur : un buff nommé, ou plusieurs. Vide sur tout ce
## qui ne fait que frapper. Ils s'allument et s'éteignent ensemble.
@export var buffs: Array[SkillBuff] = []

## Zéro pour un coup gratuit.
@export var mana_cost: float = 0.0

## Un nombre **par point placé** : sa longueur est le nombre de points de la case.
## Une table et non une formule, pour lire la valeur d'un point sans relire de code.
@export var damage_per_point: Array[float] = []

## Le nombre de points d'une compétence **sans table de dégâts** — un buff. Ailleurs,
## la table le dit, et ce champ reste à zéro.
@export var declared_points_max: int = 0

## Le niveau de manuel à partir duquel la case accepte son premier point. Zéro
## pour ce qui ne vient d'aucun manuel.
@export var required_manual_level: int = 0

## L'image, ou null — un état normal : la barre dessine alors un disque de la
## couleur de la nature. Ramenée à la grille par `SkillIcon`.
@export var icon: Texture2D


## Borné en bas comme `CharacterStats.attack_interval()` : une vitesse nulle
## figerait le lanceur.
func interval(stats: CharacterStats) -> float:
	if stats == null:
		return cooldown
	if cadence == Cadence.WEAPON:
		return stats.attack_interval()
	return cooldown / maxf(stats.cast_speed, 0.1)


## Une attaque veut une arme d'attaque, un sort une arme d'incantation.
func usable_with(weapon: ItemBase) -> bool:
	return weapon != null and weapon.allowed_keyword() == KEYWORD_OF_CADENCE[cadence]


## `name` est la clé française : l'afficher directement resterait en français.
func displayed_name() -> String:
	return Texts.t(name)


## Vide reste un état normal : la fiche saute alors le paragraphe.
func displayed_description() -> String:
	return Texts.t(description) if not description.is_empty() else ""


## Déduit de la table ; à défaut de table — un buff n'inflige rien —, déclaré.
func points_max() -> int:
	return damage_per_point.size() if not damage_per_point.is_empty() else declared_points_max


## Déclarés, plus ceux de la cadence, de la nature et de la forme. Pas ceux d'un
## nœud : ils appartiennent au lancer, et `resolve()` les ajoute.
func keywords() -> PackedStringArray:
	return _keywords(PackedStringArray())


## Ce que ses buffs allumés versent dans la fiche à ce nombre de points, tous ensemble.
func buff_mods(points: int) -> Array[StatMod]:
	var out: Array[StatMod] = []
	for buff in buffs:
		out.append_array(buff.mods(points))
	return out


## Frappe-t-elle ? **Sa table de dégâts, et rien d'autre** : ce qu'un objet ajoute aux
## sorts ne rend pas offensif un déplacement qui ne touche personne.
func strikes() -> bool:
	return not damage_per_point.is_empty()


## Pose-t-elle quelque chose sur son lanceur ? Lu par la ruée, qui laisse alors un buff
## au lieu d'une trace, et par la fiche, qui lui ouvre une section.
func grants_buffs() -> bool:
	return not buffs.is_empty()


## Les mots-clés portés, ceux-ci en plus. L'ordre de lecture est celui de
## `Keywords` et de nulle part ailleurs.
func _keywords(added: PackedStringArray) -> PackedStringArray:
	var all_keywords := PackedStringArray([
		KEYWORD_OF_CADENCE.get(cadence, ""), KEYWORD_OF_NATURE.get(nature, ""),
		KEYWORD_OF_SHAPE.get(shape, ""),
	])
	all_keywords.append_array(declared_keywords)
	all_keywords.append_array(added)
	return Keywords.sort_in_order(all_keywords)


func worn(keyword: String) -> bool:
	return keywords().has(keyword)


## Ceux de la compétence ; la page du manuel affiche ceux du geste résolu, nœuds
## compris.
func keywords_label() -> String:
	return Keywords.line(keywords())


## Les dégâts propres, sans objet : la ligne de la table. Aucun attribut ne les
## multiplie (retiré le 15 septembre 2026).
func damage(points: int) -> float:
	if points <= 0 or damage_per_point.is_empty():
		return 0.0
	# Au-delà, les niveaux en bonus prolongent la table (jalon 14).
	var extra := points - points_max()
	if extra > 0:
		return damage_per_point[-1] * pow(GROWTH_PER_EXTRA_LEVEL, extra)
	return damage_per_point[points - 1]


## **Le seul calcul d'un lancer** : le lancer et la fiche du manuel passent par ici.
##
## Ordre des dégâts : propres — points placés et niveaux en bonus —, fourchettes
## ajoutées, conversion, accrus sommés, puis « plus ». Un modificateur qui vise un nombre inconnu est ignoré : c'est aux tests de
## l'attraper.
##
## Les talents ne sont pas filtrés, mais leurs mots-clés sont posés avant le filtre :
## un nœud de conversion rend un affixe de feu mordant sur un sort de foudre.
##
## Mesuré : 8,1 µs nue, 21,6 µs avec trois lignes d'objet et deux nœuds.
func resolve(
	points: int, stats: CharacterStats, mods: Array = [], talents: Array = []
) -> SkillStats:
	var r := SkillStats.new()
	r.nature = nature
	r.projectiles = float(projectiles)
	r.spread_in_degrees = spread_in_degrees
	r.projectile_speed = projectile_speed
	r.targets = float(targets)
	r.duration = duration
	r.radius = radius
	r.period = period
	r.simultaneous = float(simultaneous)
	r.self_burn = self_burn
	r.self_mana_burn = self_mana_burn
	r.hits = HITS_PER_SHAPE.get(shape, 1)
	r.sustained = shape == Shape.AURA or shape == Shape.BUFF
	r.mana_cost = mana_cost
	r.interval = interval(stats)
	if stats != null:
		r.crit_chance = stats.crit_chance
		r.crit_multiplier = stats.crit_multiplier

	var given := PackedStringArray()
	for t: InvestedTalent in talents:
		given.append_array(t.node.added_keywords)
	var worn_items := _keywords(given)
	r.keywords = worn_items

	var fields: Array[StatMod] = []
	var damage_percents: Array[StatMod] = []
	for m: StatMod in mods:
		if worn_items.has(m.scope) or (m.scope.is_empty() and m.stat == SkillStats.CRIT_CHANCE):
			_store(r, m, fields, damage_percents)
	for t: InvestedTalent in talents:
		for m in t.mods():
			_store(r, m, fields, damage_percents)
	# Après le tri, qui compte les niveaux en bonus ; ils n'apprennent rien à qui n'a
	# placé aucun point.
	var own := damage(maxi(points + r.bonus_levels, 1) if points > 0 else 0)
	# Les PV du lanceur après la table et non dedans : ils montent avec le personnage, pas
	# avec le point placé.
	if own > 0.0 and health_scaling > 0.0 and stats != null:
		own += stats.max_health * health_scaling
	r.place_the_base(nature, own)

	StatMod.apply(r, fields)
	for t: InvestedTalent in talents:
		r.apply_conversion(t.node.converts_to, t.conversion())
	var increased := 0.0
	var more := 1.0
	for m in damage_percents:
		if m.mode == StatMod.Mode.MORE:
			more *= 1.0 + m.value * 0.01
		else:
			increased += m.value
	r.scale_damage(increased, more)
	r.finalize()
	# Ici et non dans `finalize()` : zéro veut dire « sans limite », et un nœud ne doit
	# pas rendre infinie une orbite bornée.
	if simultaneous > 0:
		r.simultaneous = maxf(r.simultaneous, 1.0)
	return r


## Une seule fonction pour les lignes d'objet et de talent, sinon « +12 % dégâts »
## serait traité différemment selon sa source.
static func _store(
	r: SkillStats, m: StatMod, fields: Array[StatMod], percents: Array[StatMod]
) -> void:
	var added := SkillStats.added_nature(m.stat)
	var against := SkillStats.against(m.stat)
	if m.stat == SkillStats.LEVELS:
		r.bonus_levels += roundi(m.value)
	elif against >= 0:
		if m.mode == StatMod.Mode.MORE:
			r.against_more[against] *= 1.0 + m.value * 0.01
		elif m.mode == StatMod.Mode.PERCENT:
			r.against_increased[against] += m.value
	elif added >= 0 and m.mode == StatMod.Mode.FLAT:
		r.add_to(added, m.value, m.value_max)
	elif m.stat == SkillStats.DAMAGE and m.mode != StatMod.Mode.FLAT:
		percents.append(m)
	elif m.stat != SkillStats.DAMAGE and SkillStats.LABELS.has(m.stat):
		fields.append(m)

