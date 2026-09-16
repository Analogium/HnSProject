class_name Skill
extends Resource

## Ce qu'un personnage sait faire : une fiche de contenu — une Resource, donc un
## fichier de plus et non une branche de code. Elle ne connaît ni le joueur ni le
## manuel : le sens de circulation ne s'inverse jamais.

@export var id: String = ""
@export var name: String = ""

## La nature du coup : la résistance qui s'y oppose et sa couleur.
@export var nature: DamageType.Kind = DamageType.Kind.PHYSICAL

## `WEAPON` : l'intervalle vient de la fiche (`attack_cooldown` / `attack_speed`), et
## `cooldown` est ignorée. `CAST` : `cooldown` / `cast_speed`.
enum Cadence { WEAPON, CAST }

@export var cadence: Cadence = Cadence.CAST

## Ce que le lancer pose dans le monde, comportement et dessin ensemble — `STRIKE`
## ne diffère d'`ARC` que par le dessin. Aucun nœud ne la change.
## **Ajouter à la fin seulement** : les `.tres` écrivent l'entier.
enum Shape { ARC, BOLT, STRIKE, BALL, CHAIN, CLOUD, AURA, SNAKE, CROSS, ORBIT }

@export var shape: Shape = Shape.ARC

## Seulement ce que ni la nature, ni la cadence, ni la forme ne donnent déjà
## (aujourd'hui rien) : le redéclarer ferait deux vérités.
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
}

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
## En secondes : ce que vit un nuage, un serpent, une épée en orbite. Zéro pour ce
## qui ne dure pas — et pour l'aura, qui dure tant qu'on ne l'éteint pas.
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

## Zéro pour un coup gratuit.
@export var mana_cost: float = 0.0

## Un nombre **par point placé** : sa longueur est le nombre de points de la case.
## Une table et non une formule, pour lire la valeur d'un point sans relire de code.
@export var damage_per_point: Array[float] = []

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


## `name` est la clé française : l'afficher directement resterait en français.
func displayed_name() -> String:
	return Texts.t(name)


## Déduit de la table, jamais saisi à côté.
func points_max() -> int:
	return damage_per_point.size()


## Déclarés, plus ceux de la cadence, de la nature et de la forme. Pas ceux d'un
## nœud : ils appartiennent au lancer, et `resolve()` les ajoute.
func keywords() -> PackedStringArray:
	return _keywords(PackedStringArray())


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
	# Au-delà du dernier point, le dernier plutôt qu'une erreur d'indice.
	return damage_per_point[mini(points, points_max()) - 1]


## **Le seul calcul d'un lancer** : le lancer et la fiche du manuel passent par ici.
##
## Ordre des dégâts : propres, fourchettes ajoutées, conversion, accrus sommés, puis
## « plus ». Un modificateur qui vise un nombre inconnu est ignoré : c'est aux tests de
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
	r.place_the_base(nature, damage(points))
	r.projectiles = float(projectiles)
	r.spread_in_degrees = spread_in_degrees
	r.projectile_speed = projectile_speed
	r.targets = float(targets)
	r.duration = duration
	r.radius = radius
	r.period = period
	r.simultaneous = float(simultaneous)
	r.self_burn = self_burn
	r.hits = HITS_PER_SHAPE.get(shape, 1)
	r.sustained = shape == Shape.AURA
	r.mana_cost = mana_cost
	r.interval = interval(stats)

	var given := PackedStringArray()
	for t: InvestedTalent in talents:
		given.append_array(t.node.added_keywords)
	var worn_items := _keywords(given)
	r.keywords = worn_items

	var fields: Array[StatMod] = []
	var damage_percents: Array[StatMod] = []
	for m: StatMod in mods:
		if worn_items.has(m.scope):
			_store(r, m, fields, damage_percents)
	for t: InvestedTalent in talents:
		for m in t.mods():
			_store(r, m, fields, damage_percents)

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
	if added >= 0 and m.mode == StatMod.Mode.FLAT:
		r.add_to(added, m.value, m.value_max)
	elif m.stat == SkillStats.DAMAGE and m.mode != StatMod.Mode.FLAT:
		percents.append(m)
	elif m.stat != SkillStats.DAMAGE and SkillStats.LABELS.has(m.stat):
		fields.append(m)

