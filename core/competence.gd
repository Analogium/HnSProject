class_name Competence
extends Resource

## Ce qu'un personnage sait faire : une fiche de contenu — une Resource, donc un
## fichier de plus et non une branche de code. Elle ne connaît ni le joueur ni le
## manuel : le sens de circulation ne s'inverse jamais.

@export var id: String = ""
@export var nom: String = ""

## La nature du coup : la résistance qui s'y oppose et sa couleur.
@export var nature: DamageType.Kind = DamageType.Kind.PHYSICAL

## `ARME` : l'intervalle vient de la fiche (`attack_cooldown` / `attack_speed`), et
## `recharge` est ignorée. `INCANTATION` : `recharge` / `cast_speed`.
enum Cadence { ARME, INCANTATION }

@export var cadence: Cadence = Cadence.INCANTATION

## Ce que le lancer pose dans le monde, comportement et dessin ensemble — `FRAPPE`
## ne diffère d'`ARC` que par le dessin. Aucun nœud ne la change.
## **Ajouter à la fin seulement** : les `.tres` écrivent l'entier.
enum Forme { ARC, TRAIT, FRAPPE, BOULE, CHAINE, NUAGE, AURA, SERPENT, CROIX, ORBITE }

@export var forme: Forme = Forme.ARC

## Seulement ce que ni la nature, ni la cadence, ni la forme ne donnent déjà
## (aujourd'hui rien) : le redéclarer ferait deux vérités.
@export var mots_cles_declares: PackedStringArray = PackedStringArray()

## Une nature absente ne donne aucun mot-clé : l'afficher enverrait chercher un
## affixe qui n'existe pas.
const MOT_CLE_DE_CADENCE := {
	Cadence.ARME: MotsCles.ATTAQUE,
	Cadence.INCANTATION: MotsCles.SORT,
}
const MOT_CLE_DE_NATURE := {
	DamageType.Kind.FIRE: MotsCles.FEU,
	DamageType.Kind.LIGHTNING: MotsCles.FOUDRE,
}
const MOT_CLE_DE_FORME := {
	Forme.TRAIT: MotsCles.PROJECTILE,
	Forme.BOULE: MotsCles.PROJECTILE,
}

## Une table et non un champ : un troisième coup en croix n'aurait pas de dessin.
const COUPS_PAR_FORME := {
	Forme.CROIX: 2,
}

## En secondes, avant `cast_speed`. Ignorée à la cadence de l'arme.
@export var recharge: float = 0.0

## Nombre de traits et écart total en degrés : 1 et 0 pour un trait, 8 et 360 pour
## une nova.
@export var projectiles: int = 1
@export var dispersion_en_degres: float = 0.0

## En pixels par seconde, sur la compétence et non sur la scène du tir : deux
## compétences d'une même scène diffèrent, et un modificateur l'atteint.
@export var vitesse_de_projectile: float = 0.0

## Les nombres des formes qui ne sont pas un tir ; un test refuse une forme à qui
## manque le sien. `cibles` : les ennemis d'une chaîne, le premier compris.
@export var cibles: int = 1
## En secondes : ce que vit un nuage, un serpent, une épée en orbite. Zéro pour ce
## qui ne dure pas — et pour l'aura, qui dure tant qu'on ne l'éteint pas.
@export var duree: float = 0.0
## En pixels : la zone d'un nuage, d'une aura, l'explosion d'une boule.
@export var rayon: float = 0.0
## En secondes, entre deux frappes d'un nuage ou d'une aura, ou entre deux touches
## d'une même cible par un serpent ou une épée. **Aucun nœud ne la vise** : elle
## change le nombre de coups sans changer ce que la fiche appelle dégâts.
@export var periode: float = 0.0
## Combien de ces présences peuvent exister à la fois. Zéro : sans limite.
@export var simultanes: int = 0
## La part des PV max qu'une aura brûle au lanceur, par seconde. Hors de portée des
## nœuds : réduite à zéro, elle ferait de l'aura un sort sans prix.
@export var brulure: float = 0.0

## Zéro pour un coup gratuit.
@export var cout_en_mana: float = 0.0

## Un nombre **par point placé** : sa longueur est le nombre de points de la case.
## Une table et non une formule, pour lire la valeur d'un point sans relire de code.
@export var degats_par_point: Array[float] = []

## Le niveau de manuel à partir duquel la case accepte son premier point. Zéro
## pour ce qui ne vient d'aucun manuel.
@export var niveau_de_manuel_requis: int = 0

## L'image, ou null — un état normal : la barre dessine alors un disque de la
## couleur de la nature. Ramenée à la grille par `IconeDeCompetence`.
@export var icone: Texture2D


## Borné en bas comme `CharacterStats.attack_interval()` : une vitesse nulle
## figerait le lanceur.
func intervalle(stats: CharacterStats) -> float:
	if stats == null:
		return recharge
	if cadence == Cadence.ARME:
		return stats.attack_interval()
	return recharge / maxf(stats.cast_speed, 0.1)


## `nom` est la clé française : l'afficher directement resterait en français.
func nom_affiche() -> String:
	return Textes.t(nom)


## Déduit de la table, jamais saisi à côté.
func points_max() -> int:
	return degats_par_point.size()


## Déclarés, plus ceux de la cadence, de la nature et de la forme. Pas ceux d'un
## nœud : ils appartiennent au lancer, et `resoudre()` les ajoute.
func mots_cles() -> PackedStringArray:
	return _mots_cles(PackedStringArray())


## Les mots-clés portés, ceux-ci en plus. L'ordre de lecture est celui de
## `MotsCles` et de nulle part ailleurs.
func _mots_cles(ajoutes: PackedStringArray) -> PackedStringArray:
	var tous := PackedStringArray([
		MOT_CLE_DE_CADENCE.get(cadence, ""), MOT_CLE_DE_NATURE.get(nature, ""),
		MOT_CLE_DE_FORME.get(forme, ""),
	])
	tous.append_array(mots_cles_declares)
	tous.append_array(ajoutes)
	return MotsCles.ordonner(tous)


func porte(mot_cle: String) -> bool:
	return mots_cles().has(mot_cle)


## Ceux de la compétence ; la page du manuel affiche ceux du geste résolu, nœuds
## compris.
func libelle_des_mots_cles() -> String:
	return MotsCles.ligne(mots_cles())


## Les dégâts propres, sans objet : la ligne de la table. Aucun attribut ne les
## multiplie (retiré le 15 septembre 2026).
func degats(points: int) -> float:
	if points <= 0 or degats_par_point.is_empty():
		return 0.0
	# Au-delà du dernier point, le dernier plutôt qu'une erreur d'indice.
	return degats_par_point[mini(points, points_max()) - 1]


## **Le seul calcul d'un lancer** : le lancer et la fiche du manuel passent par ici.
##
## Ordre des dégâts : propres, fourchettes ajoutées, conversion, pourcentages. Un
## modificateur qui vise un nombre inconnu est ignoré : c'est aux tests de l'attraper.
##
## Les talents ne sont pas filtrés, mais leurs mots-clés sont posés avant le filtre :
## un nœud de conversion rend un affixe de feu mordant sur un sort de foudre.
##
## Mesuré : 8,1 µs nue, 21,6 µs avec trois lignes d'objet et deux nœuds.
func resoudre(
	points: int, stats: CharacterStats, mods: Array = [], talents: Array = []
) -> StatsDeCompetence:
	var r := StatsDeCompetence.new()
	r.nature = nature
	r.poser_la_base(nature, degats(points))
	r.projectiles = float(projectiles)
	r.dispersion_en_degres = dispersion_en_degres
	r.vitesse_de_projectile = vitesse_de_projectile
	r.cibles = float(cibles)
	r.duree = duree
	r.rayon = rayon
	r.periode = periode
	r.simultanes = float(simultanes)
	r.brulure = brulure
	r.coups = COUPS_PAR_FORME.get(forme, 1)
	r.entretenue = forme == Forme.AURA
	r.cout_en_mana = cout_en_mana
	r.intervalle = intervalle(stats)

	var donnes := PackedStringArray()
	for t: TalentInvesti in talents:
		donnes.append_array(t.noeud.mots_cles_ajoutes)
	var portes := _mots_cles(donnes)
	r.mots_cles = portes

	var champs: Array[StatMod] = []
	var pourcents_de_degats: Array[StatMod] = []
	for m: StatMod in mods:
		if portes.has(m.portee):
			_ranger(r, m, champs, pourcents_de_degats)
	for t: TalentInvesti in talents:
		for m in t.mods():
			_ranger(r, m, champs, pourcents_de_degats)

	StatMod.appliquer(r, champs)
	for t: TalentInvesti in talents:
		r.convertir(t.noeud.convertit_vers, t.conversion())
	for m in pourcents_de_degats:
		r.accroitre(m.value)
	r.conclure()
	# Ici et non dans `conclure()` : zéro veut dire « sans limite », et un nœud ne doit
	# pas rendre infinie une orbite bornée.
	if simultanes > 0:
		r.simultanes = maxf(r.simultanes, 1.0)
	return r


## Une seule fonction pour les lignes d'objet et de talent, sinon « +12 % dégâts »
## serait traité différemment selon sa source.
static func _ranger(
	r: StatsDeCompetence, m: StatMod, champs: Array[StatMod], pourcents: Array[StatMod]
) -> void:
	var ajoutee := StatsDeCompetence.nature_ajoutee(m.stat)
	if ajoutee >= 0 and m.mode == StatMod.Mode.FLAT:
		r.ajouter(ajoutee, m.value, m.value_max)
	elif m.stat == StatsDeCompetence.DEGATS and m.mode == StatMod.Mode.PERCENT:
		pourcents.append(m)
	elif m.stat != StatsDeCompetence.DEGATS and StatsDeCompetence.LABELS.has(m.stat):
		champs.append(m)

