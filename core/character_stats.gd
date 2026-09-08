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
## Les trois attributs classiques du genre. Ils ne servent à rien par eux-mêmes :
## ce sont des **entrées**, dont on dérive des statistiques réelles (voir
## apply_attributes). Un attribut qui ne gouverne rien serait une ligne de plus
## sur la fiche et rien d'autre.
##
## Zéro par défaut, comme le mana : un grunt n'a pas d'attributs, et lui en
## donner dix silencieusement lui offrirait vingt points de vie que personne
## n'aurait décidés. C'est la fiche du joueur qui les pose.
@export var strength: float = 0.0
@export var dexterity: float = 0.0
@export var intelligence: float = 0.0

@export_group("Vie et ressource")
@export var max_health: float = 100.0
## Points de vie par seconde. Zéro par défaut : un ennemi qui se régénère tout
## seul est une décision de design, pas un état par défaut.
@export var health_regen: float = 0.0
## Zéro par défaut pour la même raison — un grunt n'a pas de réserve de mana, et
## lui en donner une silencieusement afficherait une barre vide sur la fiche.
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
@export var attack_damage: float = 12.0
## Les dégâts d'un tir, avant les résistances de la cible. Distinct
## d'attack_damage, et pas seulement par symétrie : c'est cette séparation qui
## permet à une arme d'incantation de ne rien devoir aux affixes de mêlée.
##
## Zéro par défaut, comme le mana : un grunt ne lance rien, et lui donner des
## dégâts de sort silencieusement lui offrirait une attaque que personne n'a
## décidée. C'est la fiche du joueur qui la pose.
##
## Avant lui, le tir lisait `Player.bolt_damage` — un export du nœud, absent de
## la fiche, donc qu'aucun objet ne pouvait toucher. Une baguette n'avait alors
## aucun affixe offensif à recevoir.
@export var spell_damage: float = 0.0
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
## Zéro par défaut : ce jeu n'a pas de recul. Le mécanisme est entier — il
## suffit de monter ce chiffre, ou d'utiliser les touches 3/4 de l'arène de
## test — mais un nouvel ennemi doit naître comme les autres, sans recul, et
## pas obliger à penser à le débrancher.
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
## Linéaire et non exponentiel : une courbe exponentielle demande un exposant
## qu'on ne saura pas régler avant d'avoir joué, et se trompe d'un facteur dix à
## la soixantième marche. À niveau 40, un grunt a huit fois sa vie et cinq fois
## ses dégâts — c'est brutal, c'est réglable, et c'est mesurable en une partie.
##
## Ni l'armure ni les résistances ne montent. Le joueur n'a aucun moyen de
## percer une armure ; la faire croître transformerait une zone profonde en mur
## au lieu d'un danger.
const VIE_PAR_NIVEAU := 0.18
const DEGATS_PAR_NIVEAU := 0.12


## Met une fiche à l'échelle d'un niveau de zone. **Écrit dans la fiche qu'on
## lui donne** : à l'appelant de l'avoir dupliquée, car les fiches d'archétypes
## sont des `.tres` partagés par tous leurs exemplaires.
##
## Les dégâts de sort suivent les dégâts d'attaque : le tir du caster lit
## attack_damage, mais un ennemi qui lancerait un vrai sort ne doit pas rester
## au niveau 1 par oubli.
static func mettre_a_l_echelle(stats: CharacterStats, niveau: int) -> void:
	var marches := float(maxi(niveau, 1) - 1)
	stats.max_health *= 1.0 + VIE_PAR_NIVEAU * marches
	stats.attack_damage *= 1.0 + DEGATS_PAR_NIVEAU * marches
	stats.spell_damage *= 1.0 + DEGATS_PAR_NIVEAU * marches


## Les trois champs d'attributs, pour que l'appelant n'ait pas à les énumérer à
## la main. C'est cette liste qui sépare les modificateurs à appliquer **avant**
## la dérivation de ceux qui viennent après.
const ATTRIBUTES := ["strength", "dexterity", "intelligence"]


## Une répartition vierge : un compteur par attribut, à zéro. Le joueur la tient
## pour ses points placés, la sauvegarde la relit. Dérivée d'ATTRIBUTES et non
## réécrite en dur des deux côtés : un quatrième attribut ajouté à la liste doit
## apparaître dans les deux, ou celui qui l'oublie perd les points du joueur
## sans rien dire.
static func empty_attributes() -> Dictionary:
	var vide := {}
	for champ in ATTRIBUTES:
		vide[champ] = 0
	return vide

## Ce que chaque point d'attribut rapporte. Chacun gouverne une réserve et une
## cadence : monter un attribut doit changer deux choses, sinon c'est un alias
## pour la statistique qu'il pilote et autant modifier celle-ci directement.
##
## Première calibration, à ajuster en jouant : à dix dans chaque attribut — le
## départ — cela vaut +20 PV, +2 dégâts, 15 d'esquive, +15 de mana et +4 % sur
## les deux cadences.
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
## appelée deux fois, elle compterait les bonus deux fois. C'est la même règle
## que pour recompute_stats, dont elle est un morceau.
##
## Elle se place entre les modificateurs qui visent les attributs et ceux qui
## visent le reste : un objet qui donne « +20 force » doit rapporter ses quarante
## points de vie, et un objet qui donne « +10 % PV » doit les multiplier aussi.
func apply_attributes() -> void:
	max_health += strength * HEALTH_PER_STRENGTH
	attack_damage += strength * DAMAGE_PER_STRENGTH

	evasion += dexterity * EVASION_PER_DEXTERITY
	attack_speed += dexterity * ATTACK_SPEED_PER_DEXTERITY * 0.01

	max_mana += intelligence * MANA_PER_INTELLIGENCE
	cast_speed += intelligence * CAST_SPEED_PER_INTELLIGENCE * 0.01
