class_name CharacterStats
extends Resource

## La fiche d'un personnage — joueur comme ennemi, même classe pour les deux.
##
## Les règles de mitigation (armure, esquive, résistances) sont **ici** et non
## dans la Hurtbox qui les applique : la fiche de personnage doit pouvoir
## annoncer « 40 d'armure, soit 44 % contre un coup de 10 » sans réimplémenter
## la formule de son côté. Un seul endroit où la règle est écrite, deux endroits
## qui la lisent.

@export_group("Attributs")
## Des **entrées** dont on dérive des statistiques réelles (voir
## apply_attributes) : un attribut qui ne gouverne rien serait une ligne de plus
## sur la fiche et rien d'autre.
##
## Zéro par défaut : un grunt n'a pas d'attributs, et lui en donner dix
## silencieusement lui offrirait vingt points de vie que personne n'a décidés.
@export var strength: float = 0.0
@export var dexterity: float = 0.0
@export var intelligence: float = 0.0

@export_group("Vie et ressource")
@export var max_health: float = 100.0
## Points de vie par seconde. Zéro par défaut : un ennemi qui se régénère tout
## seul est une décision de design, pas un état par défaut.
@export var health_regen: float = 0.0
## Zéro pour la même raison — un grunt sans réserve ne doit pas afficher une
## barre de mana vide sur la fiche.
@export var max_mana: float = 0.0
@export var mana_regen: float = 0.0

@export_group("Défenses")
## Une **notation**, pas des points retranchés. La réduction se calcule par
## rapport à la taille du coup encaissé : beaucoup contre les petits coups
## répétés, peu contre les gros. C'est ce qui la fait rester utile à haut niveau
## sans jamais rendre invulnérable — des points plats seraient soit négligeables,
## soit une invincibilité au bout de quelques objets.
@export var armor: float = 0.0
## Notation elle aussi, lue par la même famille de courbe : le coup est esquivé
## entièrement ou pas du tout. Binaire et non une réduction, parce que c'est
## cette irrégularité qui la distingue de l'armure — sinon les deux défenses
## seraient deux noms pour la même chose.
@export var evasion: float = 0.0

@export_subgroup("Résistances")
## En pourcentage, plafonnées à MAX_RESISTANCE. Négatives, elles amplifient : la
## place est faite pour les malédictions, rien ne les inflige encore.
@export var res_cold: float = 0.0
@export var res_fire: float = 0.0
@export var res_lightning: float = 0.0
@export var res_necrotic: float = 0.0
@export var res_holy: float = 0.0

@export_group("Combat")
## Les dégâts d'un coup **d'ennemi** : un grunt n'a pas de compétence, il frappe
## avec son corps, et c'est ce nombre que la montée de niveau multiplie.
##
## Le joueur ne le lit pas. Ses dégâts viennent de ses compétences et de ce que
## ses objets y ajoutent, par nature et par famille — voir `Competence.resoudre()`.
@export var attack_damage: float = 12.0
## Le temps de base entre deux coups, propre à l'archétype ou à l'arme.
## Distinct de attack_speed, qui est le multiplicateur porté par le personnage :
## l'un est le rythme de l'outil, l'autre l'adresse de celui qui le tient.
@export var attack_cooldown: float = 0.45
## Multiplicateurs, 1.0 = cadence de base. C'est sur eux que portent les affixes,
## en pourcentage — « +10 % de vitesse d'attaque » se lit, « -9 % de temps de
## recharge » demande une conversion mentale à chaque fois.
@export var attack_speed: float = 1.0
@export var cast_speed: float = 1.0
@export var attack_range: float = 28.0
## Zéro par défaut : ce jeu n'a pas de recul. Le mécanisme est entier — touches
## 3/4 de l'arène de test — mais un nouvel ennemi doit naître sans, et non
## obliger à penser à le débrancher.
@export var knockback_force: float = 0.0
@export_range(0.0, 1.0) var crit_chance: float = 0.05
@export var crit_multiplier: float = 2.0

@export_group("Déplacement")
@export var move_speed: float = 90.0


## Constante de la courbe d'armure. Plus elle est grande, moins une notation
## donnée protège. À 5, il faut cinq fois la taille du coup en armure pour le
## réduire de moitié : 60 d'armure valent 50 % contre un coup de 12.
const ARMOR_K := 5.0
## Un coup passe toujours. Sans ce plafond, une armure suffisante rendrait
## invulnérable — c'est une impasse, pas une difficulté.
const MAX_ARMOR_REDUCTION := 0.90

## Même lecture que l'armure, mais sans dépendre de la taille du coup : esquiver
## est tout ou rien. À 60, une notation de 60 donne une chance sur deux.
const EVASION_K := 60.0
## Au-delà, le combat devient une loterie qu'on gagne en attendant.
const MAX_EVASION := 0.75

## Ce que le niveau d'une zone ajoute à un ennemi qui y naît, par niveau au-delà
## du premier.
##
## Linéaire et non exponentiel : un exposant ne se règle pas avant d'avoir joué
## et se trompe d'un facteur dix à la soixantième marche. À niveau 40, un grunt a
## huit fois sa vie et cinq fois ses dégâts.
##
## Ni l'armure ni les résistances ne montent : le joueur n'a aucun moyen de
## percer une armure, et la faire croître ferait d'une zone profonde un mur au
## lieu d'un danger.
const VIE_PAR_NIVEAU := 0.18
const DEGATS_PAR_NIVEAU := 0.12


## Met une fiche à l'échelle d'un niveau de zone. **Écrit dans la fiche qu'on lui
## donne** : à l'appelant de l'avoir dupliquée, car les fiches d'archétypes sont
## des `.tres` partagés par tous leurs exemplaires.
static func mettre_a_l_echelle(stats: CharacterStats, niveau: int) -> void:
	var marches := float(maxi(niveau, 1) - 1)
	stats.max_health *= 1.0 + VIE_PAR_NIVEAU * marches
	stats.attack_damage *= 1.0 + DEGATS_PAR_NIVEAU * marches


## Les trois champs d'attributs, pour que l'appelant n'ait pas à les énumérer à
## la main. C'est cette liste qui sépare les modificateurs à appliquer **avant**
## la dérivation de ceux qui viennent après.
const ATTRIBUTES := ["strength", "dexterity", "intelligence"]


## Une répartition vierge : un compteur par attribut, à zéro. Dérivée
## d'ATTRIBUTES et non réécrite en dur : un quatrième attribut ajouté à la liste
## doit apparaître partout, ou celui qui l'oublie perd les points du joueur.
static func empty_attributes() -> Dictionary:
	var vide := {}
	for champ in ATTRIBUTES:
		vide[champ] = 0
	return vide

## Ce que chaque point d'attribut rapporte. Chacun gouverne une réserve et une
## cadence : monter un attribut doit changer deux choses, sinon c'est un alias
## pour la statistique qu'il pilote.
##
## À dix dans chaque attribut — le départ — cela vaut +20 PV, +2 dégâts, 15
## d'esquive, +15 de mana et +4 % sur les deux cadences.
const HEALTH_PER_STRENGTH := 2.0
const DAMAGE_PER_STRENGTH := 0.2
const EVASION_PER_DEXTERITY := 1.5
## En points de pourcentage ajoutés au multiplicateur : dix points de dextérité
## font passer la cadence de 100 à 104 %.
const ATTACK_SPEED_PER_DEXTERITY := 0.4
const MANA_PER_INTELLIGENCE := 1.5
const CAST_SPEED_PER_INTELLIGENCE := 0.4

## Le plafond classique du genre. Il donne sa valeur à l'objectif « atteindre le
## plafond », et empêche l'immunité pure à un élément.
const MAX_RESISTANCE := 75.0
## Au pire un coup fait le double, jamais plus : une malédiction doit faire mal,
## pas transformer un coup d'épingle en exécution.
const MIN_RESISTANCE := -100.0


## Ce que la force ajoute aux attaques, en dégâts physiques. Pas un champ de la
## fiche : une fourchette aux bornes égales, que le joueur verse dans ses
## modificateurs de compétence. C'est l'effet d'avant — « +0,2 dégât par point » —
## sous la forme que prennent désormais tous les dégâts ajoutés.
func degats_de_force() -> float:
	return strength * DAMAGE_PER_STRENGTH


## La fraction retranchée à un coup physique de cette taille. Prend les dégâts
## **avant** mitigation : c'est ce qui fait que l'armure protège proportionnellement
## moins des gros coups.
func armor_reduction(damage: float) -> float:
	if armor <= 0.0 or damage <= 0.0:
		return 0.0
	return minf(armor / (armor + ARMOR_K * damage), MAX_ARMOR_REDUCTION)


## La probabilité d'éviter entièrement un coup, entre 0 et MAX_EVASION.
func evade_chance() -> float:
	if evasion <= 0.0:
		return 0.0
	return minf(evasion / (evasion + EVASION_K), MAX_EVASION)


## La résistance à une nature, déjà bornée. Le physique renvoie zéro : il passe
## par l'armure, et l'appelant n'a pas à connaître l'exception.
func resistance(kind: DamageType.Kind) -> float:
	var field: String = DamageType.RESIST_FIELDS[kind]
	if field.is_empty():
		return 0.0
	return clampf(float(get(field)), MIN_RESISTANCE, MAX_RESISTANCE)


## Le temps réel entre deux coups, cadence comprise. Le plancher évite qu'une
## vitesse nulle ou négative — un affixe mal réglé, une division par zéro —
## fige l'attaquant pour toujours au lieu de le ralentir.
func attack_interval() -> float:
	return attack_cooldown / maxf(attack_speed, 0.1)


## Verse dans les statistiques ce que les attributs rapportent.
##
## **À n'appeler qu'une fois par recalcul**, et seulement sur une fiche neuve :
## appelée deux fois, elle compterait les bonus deux fois.
##
## Elle se place entre les modificateurs qui visent les attributs et ceux qui
## visent le reste : un objet qui donne « +20 force » doit rapporter ses quarante
## points de vie, et un « +10 % PV » doit les multiplier aussi.
func apply_attributes() -> void:
	max_health += strength * HEALTH_PER_STRENGTH

	evasion += dexterity * EVASION_PER_DEXTERITY
	attack_speed += dexterity * ATTACK_SPEED_PER_DEXTERITY * 0.01

	max_mana += intelligence * MANA_PER_INTELLIGENCE
	cast_speed += intelligence * CAST_SPEED_PER_INTELLIGENCE * 0.01
