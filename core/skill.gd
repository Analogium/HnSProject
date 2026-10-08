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

## Des natures prises **à tour de rôle**, un lancer chacune (le Projectile élémentaire) ;
## vide pour la plupart. Le tour est compté par le lanceur, la compétence n'en sait rien.
@export var nature_cycle: Array[int] = []

## Ce qui décide du **temps du geste** : `WEAPON` le prend sur l'arme
## (`CharacterStats.attack_interval()`) et ignore `cast_time` ; `CAST` prend `cast_time`
## divisé par `cast_speed`. La **recharge** ne dépend d'aucune des deux.
enum Cadence { WEAPON, CAST }

@export var cadence: Cadence = Cadence.CAST

## Ce que le lancer pose dans le monde, comportement et dessin ensemble — `STRIKE`
## ne diffère d'`ARC` que par le dessin, `COMET` de `BOLT` de même. Aucun nœud ne la change.
## **Ajouter à la fin seulement** : les `.tres` écrivent l'entier.
enum Shape {
	ARC, BOLT, STRIKE, BALL, CHAIN, CLOUD, AURA, SNAKE, CROSS, ORBIT, DASH, BUFF,
	WAVE, CYCLONE, SPIKES, NOVA, VORTEX, BEAM, PILLAR, PULSE, SUMMON, GATE, CURSE,
	LUNGE, COMET,
	# Jalon 34 : des formes que seule une transformation donne — le Météore, le Bond.
	METEOR, LEAP,
	# Jalon 35 : l'Orbe statique, la Toile d'arcs, l'Orage portatif.
	ORB, WEB, TEMPEST,
	# Jalon 36 : le Sillon de glace, l'Onde de givre, l'Implosion.
	FISSURE, RING, IMPLOSION,
	# Jalon 38 : l'Haleine, le Nid porté, la Marque de mort.
	BREATH, NEST, MARK,
	# Jalon 39 : le Brise-sol, le Ressac.
	SLAM, BOOMERANG,
	# Jalon 40 : la Croix de lumière, le Pilier errant.
	HOLY_CROSS, DRIFT,
	# Jalon 41, la sorcière : la Catalyse, la Poupée de chiffon, le Familier, la Triade.
	CATALYSIS, DOLL, FAMILIAR, TRIAD,
	# Jalon 42 : le Brasero.
	TURRET,
}

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
	DamageType.Kind.COLD: Keywords.COLD,
	DamageType.Kind.NECROTIC: Keywords.NECROTIC,
	DamageType.Kind.HOLY: Keywords.HOLY,
	DamageType.Kind.PHYSICAL: Keywords.PHYSICAL,
}
const KEYWORD_OF_SHAPE := {
	Shape.BOLT: Keywords.PROJECTILE,
	Shape.BALL: Keywords.PROJECTILE,
	Shape.COMET: Keywords.PROJECTILE,
	Shape.ORB: Keywords.PROJECTILE,
	# Le brasero est planté, mais ce qu'il tire, ce sont des boules.
	Shape.TURRET: Keywords.PROJECTILE,
	Shape.STRIKE: Keywords.MELEE,
	Shape.CROSS: Keywords.MELEE,
	Shape.ORBIT: Keywords.MELEE,
	Shape.CLOUD: Keywords.AREA,
	Shape.AURA: Keywords.AREA,
	Shape.SNAKE: Keywords.AREA,
	Shape.DASH: Keywords.AREA,
	Shape.LEAP: Keywords.AREA,
	Shape.METEOR: Keywords.AREA,
	Shape.TEMPEST: Keywords.AREA,
	Shape.CATALYSIS: Keywords.AREA,
	Shape.TRIAD: Keywords.AREA,
	# Le fétiche ne frappe qu'en éclatant.
	Shape.DOLL: Keywords.AREA,
	# La vague part de la lame et le cyclone tourne sur place : deux gestes d'arme,
	# donc de la mêlée, quoi qu'ils atteignent au-delà du bras.
	Shape.WAVE: Keywords.MELEE,
	Shape.CYCLONE: Keywords.MELEE,
	Shape.BOOMERANG: Keywords.MELEE,
	# La lame s'abat devant soi : un coup d'arme, même s'il frappe un cercle.
	Shape.SLAM: Keywords.MELEE,
	Shape.SPIKES: Keywords.AREA,
	Shape.NOVA: Keywords.AREA,
	Shape.VORTEX: Keywords.AREA,
	Shape.FISSURE: Keywords.AREA,
	Shape.RING: Keywords.AREA,
	Shape.IMPLOSION: Keywords.AREA,
	Shape.BREATH: Keywords.AREA,
	# Le faisceau n'y est **pas** : une ligne n'est ni un tir ni une surface, et lui
	# prêter `area` promettrait un affixe qui ne le servirait pas.
	# La croix non plus : quatre lignes.
	Shape.PILLAR: Keywords.AREA,
	Shape.DRIFT: Keywords.AREA,
	Shape.PULSE: Keywords.AREA,
	# Le portail déclare `area` lui-même : ce qu'il crache se bat pour le joueur, et
	# explose.
	Shape.SUMMON: Keywords.SUMMON,
	Shape.GATE: Keywords.SUMMON,
	Shape.NEST: Keywords.SUMMON,
	Shape.CURSE: Keywords.CURSE,
	Shape.MARK: Keywords.CURSE,
	# On se jette sur une cible pour la frapper à l'arme : de la mêlée, d'où qu'on parte.
	Shape.LUNGE: Keywords.MELEE,
}

## Ce que vaut chaque niveau au-delà de la table, composé : la pente des tables
## actuelles, environ 25 % par point (décidé au jalon 14).
const GROWTH_PER_EXTRA_LEVEL := 1.25

## Une table et non un champ : un troisième coup en croix n'aurait pas de dessin.
## Ce qui brûle tant qu'on l'entretient : ni « par lancer », ni transformation.
const SUSTAINED_SHAPES: Array[Shape] = [Shape.AURA, Shape.BUFF, Shape.CYCLONE, Shape.FAMILIAR]

## Ce qu'une transformation peut quitter et rejoindre (jalon 34) : ce qui se pose et
## s'oublie — la malédiction aussi, depuis le jalon 38. Le reste tient un état chez le lanceur — ce qui brûle, la couronne, les
## morts-vivants, la cible de la frappe vive — qu'un nœud rendrait orphelin.
const TRANSFORMABLE: Array[Shape] = [
	Shape.BOLT, Shape.BALL, Shape.COMET, Shape.CHAIN, Shape.CLOUD, Shape.SNAKE,
	Shape.WAVE, Shape.SPIKES, Shape.NOVA, Shape.VORTEX, Shape.BEAM, Shape.PILLAR,
	Shape.GATE, Shape.STRIKE, Shape.CROSS, Shape.ARC, Shape.DASH, Shape.METEOR, Shape.LEAP,
	Shape.ORB, Shape.WEB, Shape.TEMPEST, Shape.FISSURE, Shape.RING, Shape.IMPLOSION,
	Shape.CURSE, Shape.BREATH, Shape.NEST, Shape.MARK, Shape.SLAM, Shape.BOOMERANG,
	Shape.HOLY_CROSS, Shape.DRIFT, Shape.CATALYSIS, Shape.TRIAD,
]

## Ce qu'une transformation ne lit pas (jalon 34) : la fiche d'un nœud de son arbre
## l'écrit en rouge plutôt que de laisser payer un point pour rien. Rien à traverser
## pour un météore, qui ne vole pas — ni prise d'air ni convergence ; le Bond ne laisse
## pas de traînée.
const IGNORED_BY_SHAPE := {
	Shape.METEOR: [SkillStats.PIERCE, SkillStats.SWELL, SkillStats.CONVERGE],
	Shape.LEAP: ["duration", "radius", SkillStats.WICK],
	Shape.ORB: [
		SkillStats.PIERCE, SkillStats.SPLITS, SkillStats.BOUNCES, SkillStats.CONTAGION,
		SkillStats.CAROMS, SkillStats.LIGHTNING_ROD, SkillStats.ROD_HEIR, SkillStats.STORM_TARGET,
	],
	Shape.WEB: [
		SkillStats.JUMP_REACH, SkillStats.JUMP_GAIN, SkillStats.CONDUCTANCE, SkillStats.BIFURCATION,
		SkillStats.GROUNDING, SkillStats.RELAY, SkillStats.RELAY_REFUND,
	],
	# Porté, il est centré sur son lanceur : l'Appel d'air n'y attirerait les ennemis que
	# là où ils marchent déjà (jalon 43).
	Shape.TEMPEST: [SkillStats.SEEK, SkillStats.HUNT, SkillStats.PULL],
	# L'onde passe sans se poser : nulle part où laisser un sol. L'implosion éclate déjà.
	Shape.RING: [SkillStats.GROUND],
	Shape.IMPLOSION: [SkillStats.END_BURST],
	# Le cône souffle et passe ; la marque ne couvre qu'un ennemi.
	Shape.BREATH: [SkillStats.GROUND],
	Shape.MARK: ["radius"],
	# Les trois comètes ne sont pas des tirs : elles naissent autour du lanceur et se
	# rejoignent au point visé.
	Shape.TRIAD: ["projectiles", "projectile_speed", SkillStats.BOUNCES],
}

## Les nombres qu'une forme apporte quand la compétence n'en a pas (jalon 35) : un trait
## devenu orbe n'a ni durée, ni rayon, ni rythme. Sans eux, la ligne du nœud qui les
## donnerait s'écrirait en perte — « +0,3 intervalle des frappes » en rouge.
const SHAPE_NUMBERS := {
	# Douze orbes par lanceur (jalon 43) : en Satellite, quarante orbes dans une meute dense
	# frappaient quatre mille fois par seconde, et le jeu tombait à 4 img/s.
	Shape.ORB: {"duration": 2.5, "radius": 28.0, "period": 0.33, "simultaneous": 12.0},
}

const HITS_PER_SHAPE := {
	Shape.CROSS: 2,
}

## Le temps que prend le geste, en secondes, avant `cast_speed`. Ignoré à la cadence de
## l'arme, qui le lit sur l'arme. Zéro pour ce qui part sans délai — un geste entretenu
## qu'on allume —, et c'est alors la recharge seule qui borne la cadence.
@export var cast_time: float = 0.0

## **La recharge, et rien d'autre** : un délai propre à la compétence, en secondes, que
## ni la vitesse d'attaque ni celle d'incantation ne touchent — seule
## `CharacterStats.cooldown_recovery` la raccourcit. Zéro pour la plupart des sorts, qui
## ne sont bornés que par leur temps d'incantation ; non nulle pour ce qu'on ne doit pas
## enchaîner — une ruée, un vortex — et pour l'anti-rebond d'un geste entretenu.
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
## En secondes : ce que vit un nuage, un serpent, une épée en orbite, un buff lancé, et
## ce qu'une ruée laisse derrière elle — sa trace ou son buff. Zéro pour ce qui ne dure
## pas, et pour l'aura ou le buff entretenus, qui durent tant qu'on ne les éteint pas.
@export var duration: float = 0.0
## En pixels : la zone d'un nuage, d'une aura, l'explosion d'une boule ou d'une créature
## de portail, celle que gardent les morts-vivants autour du joueur, **la longueur**
## d'un faisceau, dont la largeur est celle de son dessin, et la portée d'une frappe vive.
@export var radius: float = 0.0
## En secondes, entre deux frappes d'un nuage ou d'une aura, ou entre deux touches
## d'une même cible par un serpent ou une épée. **Aucun nœud ne la vise** : elle
## change le nombre de coups sans changer ce que la fiche appelle dégâts.
@export var period: float = 0.0
## Combien de ces présences peuvent exister à la fois — épées, morts-vivants. Zéro : sans
## limite.
@export var simultaneous: int = 0
## La part des PV max qu'une aura brûle au lanceur, par seconde. Hors de portée des
## nœuds : réduite à zéro, elle ferait de l'aura un sort sans prix.
@export var self_burn: float = 0.0
## Le mana qu'un geste entretenu draine **par seconde, à plat** — et non en part de la
## réserve : un prix qu'on lit sur la jauge sans calcul. Épuisée, elle l'éteint — là où
## les PV épuisés tuent.
@export var mana_per_second: float = 0.0

## La part des PV max du lanceur qui s'ajoute aux dégâts propres, **par coup**. Zéro
## pour tout ce qui ne s'adosse pas à la vie de celui qui lance.
@export var health_scaling: float = 0.0

## La part des PV max qu'un geste entretenu **rend** à son porteur, par seconde : le
## pendant de `self_burn`. Zéro partout ailleurs.
@export var self_heal: float = 0.0

## La part des PV **actuels** qu'un buff ronge par seconde : il ne tue jamais, il
## entame. Le pendant de `self_burn` pour ce qui ne doit pas être mortel.
@export var self_wither: float = 0.0

## Ce geste enferme-t-il son lanceur : tant qu'il brûle, rien d'autre ne part et on ne
## bouge plus. Seul le tombeau de glace le porte, et l'éteindre reste permis.
@export var binds_caster: bool = false

## Ce que ce lancer **accroît** à la chance de poser son état, en points de pourcentage :
## +50 fait passer une chance de base de 20 % à 30 %. Il s'**additionne** aux accrus du
## porteur (`CharacterStats.chill_chance`, `ignite_chance`), comme tous les accrus du
## jeu. **Hors de portée des nœuds** : c'est ce qui distingue une compétence de sa
## voisine, pas un réglage qu'on achète.
@export var status_chance_increase: float = 0.0

## L'état qu'il **pose** à ce qu'il touche (`StatusEffects.Kind`, hors de ceux que tire
## une nature), et sa chance ; −1 pour rien. Ce qu'il brûle part du coup, comme
## l'embrasement : il suit donc le niveau du sort.
@export var inflicted_state: int = -1
@export_range(0.0, 1.0) var inflict_chance: float = 1.0

## Ce que le lancer pose sur son lanceur : un buff nommé, ou plusieurs. Vide sur tout ce
## qui ne fait que frapper. Ils s'allument et s'éteignent ensemble.
@export var buffs: Array[SkillBuff] = []

## Un buff **à charges** (la Soif de sang) : ses lignes comptent une fois par charge, et
## une charge naît de chaque ennemi tué par une attaque, jusqu'à ce nombre. Zéro : un
## buff ordinaire, dont les lignes comptent une fois.
@export var stacks_max: int = 0
## Ce que vivent les charges après la dernière gagnée, en secondes.
@export var stack_duration: float = 0.0

## Ce qui donne une charge à un buff à charges : l'ennemi tué d'une attaque (la Soif de
## sang), ou le sort d'une autre nature que le sort précédent (Trinité, jalon 41).
enum StackTrigger { KILL, ALTERNATION }

@export var stack_trigger: StackTrigger = StackTrigger.KILL

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


## Le temps du geste : celui de l'arme, ou l'incantation sur la cadence du lanceur.
## Borné en bas comme `CharacterStats.attack_interval()` : une vitesse nulle figerait le
## lanceur.
func use_time(stats: CharacterStats) -> float:
	if stats == null:
		return cast_time
	if cadence == Cadence.WEAPON:
		return stats.attack_interval()
	return cast_time / maxf(stats.cast_speed, 0.1)


## La recharge, que **seule** la récupération raccourcit.
func recharge(stats: CharacterStats) -> float:
	if cooldown <= 0.0 or stats == null:
		return cooldown
	return cooldown / stats.recovery_factor()


## Ce que la case attend avant de repartir : **le plus long des deux**, parce que les
## deux courent ensemble depuis le lancer. Une compétence sans recharge n'est bornée que
## par son geste, et une ruée de quatre secondes ne part pas plus vite parce qu'on
## incante vite.
func interval(stats: CharacterStats) -> float:
	return maxf(use_time(stats), recharge(stats))


## Une attaque veut une arme d'attaque, un sort une arme d'incantation.
func usable_with(weapon: ItemBase) -> bool:
	return weapon != null and weapon.allowed_keyword() == KEYWORD_OF_CADENCE[cadence]


## La nature de ce tour-là : `nature`, ou son rang dans `nature_cycle`.
func nature_at(turn: int) -> DamageType.Kind:
	if nature_cycle.is_empty():
		return nature
	return nature_cycle[posmod(turn, nature_cycle.size())] as DamageType.Kind


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
## nœud : ils appartiennent au lancer, et `resolve()` les ajoute. Ceux du premier tour
## pour une nature qui tourne.
func keywords() -> PackedStringArray:
	return _keywords(nature, shape)


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


## Fait-elle quelque chose sans frapper — un buff, un état posé ? Sinon, une case sans
## table de dégâts accepterait des points qui ne font rien.
func acts() -> bool:
	return strikes() or grants_buffs() or inflicted_state >= 0


## Un buff **lancé** : une durée et aucun prix à la seconde. Il se paie au lancer, s'éteint
## seul, et la touche le relance au lieu de l'éteindre. Le tombeau a une durée mais se
## paie à la seconde : il reste entretenu.
func is_cast_buff() -> bool:
	return shape == Shape.BUFF and duration > 0.0 \
		and self_burn + self_wither + mana_per_second <= 0.0


## Pose-t-elle quelque chose sur son lanceur ? Lu par la ruée, qui laisse alors un buff
## au lieu d'une trace, et par la fiche, qui lui ouvre une section.
func grants_buffs() -> bool:
	return not buffs.is_empty()


## Les mots-clés portés, ceux-ci en plus. L'ordre de lecture est celui de
## `Keywords` et de nulle part ailleurs.
## Ceux du lancer : sa nature et sa forme, qu'une conversion et une transformation ont
## pu changer (jalon 34).
func _keywords(own_nature: DamageType.Kind, cast_shape: Shape) -> PackedStringArray:
	var all_keywords := PackedStringArray([
		KEYWORD_OF_CADENCE.get(cadence, ""), KEYWORD_OF_NATURE.get(own_nature, ""),
		KEYWORD_OF_SHAPE.get(cast_shape, ""),
	])
	all_keywords.append_array(declared_keywords)
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
## ajoutées, accrus sommés, puis « plus ». Un modificateur qui vise un nombre inconnu
## est ignoré : c'est aux tests de l'attraper.
##
## Les talents ne sont pas filtrés. **Une conversion change la nature du lancer avant
## le filtre** : la boule de feu gelée est un sort de froid, que les affixes de froid
## mordent et ceux de feu non. `turn` choisit la nature d'une compétence qui en change
## à chaque lancer ; une conversion l'emporte.
##
## Mesuré : 8,1 µs nue, 21,6 µs avec trois lignes d'objet et deux nœuds.
func resolve(
	points: int, stats: CharacterStats, mods: Array = [], talents: Array = [], turn := 0
) -> SkillStats:
	var own_nature := nature_at(turn)
	var cast_shape := shape
	var freed := false
	for t: InvestedTalent in talents:
		freed = freed or t.node.frees
		if t.node.converts:
			own_nature = t.node.converts_to
		if t.node.transforms:
			cast_shape = t.node.shape
	var r := SkillStats.new()
	r.nature = own_nature
	r.projectiles = float(projectiles)
	r.spread_in_degrees = spread_in_degrees
	r.projectile_speed = projectile_speed
	r.targets = float(targets)
	r.duration = duration
	r.radius = radius
	r.period = period
	r.simultaneous = float(simultaneous)
	r.self_burn = self_burn
	r.mana_per_second = mana_per_second
	r.self_heal = self_heal
	r.self_wither = self_wither
	r.status_chance_increase = status_chance_increase
	r.inflicted_state = inflicted_state
	r.inflict_chance = inflict_chance
	r.binds_caster = binds_caster and not freed
	r.shape = cast_shape
	var brought: Dictionary = SHAPE_NUMBERS.get(cast_shape, {})
	for number: String in brought:
		if is_zero_approx(float(r.get(number))):
			r.set(number, brought[number])
	r.hits = HITS_PER_SHAPE.get(cast_shape, 1)
	r.skill_id = id
	r.sustained = cast_shape in SUSTAINED_SHAPES and not is_cast_buff()
	r.mana_cost = mana_cost
	r.use_time = use_time(stats)
	r.recharge = recharge(stats)
	if stats != null:
		r.crit_chance = stats.crit_chance
		r.crit_multiplier = stats.crit_multiplier

	var worn_items := _keywords(own_nature, cast_shape)
	r.keywords = worn_items
	# La Déflagration (jalon 42) : le rayon suit aussi ce qui vise la zone, sans que le
	# reste de la zone — ses dégâts — ne s'applique.
	var reach := worn_items.duplicate()
	if _widens(talents):
		reach.append(Keywords.AREA)

	var fields: Array[StatMod] = []
	var damage_percents: Array[StatMod] = []
	for m: StatMod in mods:
		# Le coût a sa voie, la réserve : un objet ne le vise pas. Un nœud, si (le Météore).
		if m.stat == "mana_cost":
			continue
		if Keywords.covered(worn_items, m.scope) or (m.scope.is_empty() and m.stat == SkillStats.CRIT_CHANCE) \
				or (m.stat == "radius" and Keywords.covered(reach, m.scope)):
			_store(r, m, fields, damage_percents)
	for t: InvestedTalent in talents:
		for m in t.mods():
			if not is_buff_line(m):
				_store(r, m, fields, damage_percents)
	# Après le tri, qui compte les niveaux en bonus ; ils n'apprennent rien à qui n'a
	# placé aucun point.
	var own := damage(maxi(points + r.bonus_levels, 1) if points > 0 else 0)
	# Les PV du lanceur après la table et non dedans : ils montent avec le personnage, pas
	# avec le point placé.
	if own > 0.0 and health_scaling > 0.0 and stats != null:
		own += stats.max_health * health_scaling
	r.place_the_base(own_nature, own)

	StatMod.apply(r, fields)
	if freed:
		r.recharge = SkillStats.FREED_RECHARGE
	var increased := 0.0
	var more := 1.0
	for m in damage_percents:
		if m.mode == StatMod.Mode.MORE:
			more *= 1.0 + m.value * 0.01
		else:
			increased += m.value
	r.scale_damage(increased, more)
	# La Triade (jalon 41) : les trois comètes portent chacune son élément du tour.
	if cast_shape == Shape.TRIAD and not nature_cycle.is_empty():
		r.blend(nature_cycle)
	r.finalize()
	# Ici et non dans `finalize()` : zéro veut dire « sans limite », et un nœud ne doit
	# pas rendre infinie une orbite bornée.
	if simultaneous > 0:
		r.simultaneous = maxf(r.simultaneous, 1.0)
	return r


static func _widens(talents: Array) -> bool:
	for t: InvestedTalent in talents:
		for m in t.mods():
			if m.stat == SkillStats.WIDE_BLAST:
				return true
	return false


## Sur une compétence qui pose un buff, la ligne d'un nœud qui **ne vise pas un nombre du
## lancer** — une portée, ou un champ de la fiche — est une ligne de ce buff (jalon 34).
static func is_buff_line(m: StatMod) -> bool:
	return not m.scope.is_empty() or not SkillStats.modifiable(m.stat)


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

