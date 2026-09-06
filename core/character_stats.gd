class_name CharacterStats
extends Resource

## La fiche d'un personnage — joueur comme ennemi, même classe pour les deux.
##
## Les règles de mitigation (armure, esquive, résistances) sont **ici** et non
## dans la Hurtbox qui les applique : la fiche de personnage doit pouvoir
## annoncer « 40 d'armure, soit 44 % contre un coup de 10 » sans réimplémenter
## la formule de son côté. Un seul endroit où la règle est écrite, deux endroits
## qui la lisent.

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
