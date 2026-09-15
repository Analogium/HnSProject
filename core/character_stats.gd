class_name CharacterStats
extends Resource

## La fiche d'un personnage, joueur comme ennemi. La mitigation vit ici et non dans
## la Hurtbox : la fiche de personnage l'annonce par les mêmes fonctions.

@export_group("Attributs")
## Des **entrées** dont on dérive des statistiques (`apply_attributes`). Zéro par
## défaut : un grunt n'a pas d'attributs.
@export var strength: float = 0.0
@export var dexterity: float = 0.0
@export var intelligence: float = 0.0

@export_group("Vie et ressource")
@export var max_health: float = 100.0
## Points de vie par seconde. Zéro par défaut : un ennemi qui se régénère tout
## seul est une décision de design, pas un état par défaut.
@export var health_regen: float = 0.0
## Zéro pour la même raison : pas de barre de mana vide sur un grunt.
@export var max_mana: float = 0.0
@export var mana_regen: float = 0.0

@export_group("Défenses")
## Une **notation**, pas des points retranchés : la réduction dépend de la taille du
## coup — forte contre les petits, faible contre les gros, jamais invulnérable.
@export var armor: float = 0.0
## Notation lue par la même famille de courbe, mais tout ou rien : c'est ce qui la
## distingue de l'armure.
@export var evasion: float = 0.0

@export_subgroup("Résistances")
## En pourcentage, bornées à MAX_RESISTANCE ; négatives, elles amplifient.
@export var res_cold: float = 0.0
@export var res_fire: float = 0.0
@export var res_lightning: float = 0.0
@export var res_necrotic: float = 0.0
@export var res_holy: float = 0.0

@export_group("Combat")
## Les dégâts d'un coup **d'ennemi**, que le niveau de zone multiplie. Le joueur ne
## le lit pas : ses dégâts viennent de ses compétences.
@export var attack_damage: float = 12.0
## Le temps de base entre deux coups, propre à l'arme ; `attack_speed` en est le
## multiplicateur porté par le personnage.
@export var attack_cooldown: float = 0.45
## Multiplicateurs, 1.0 = cadence de base : les affixes y portent en pourcentage.
@export var attack_speed: float = 1.0
@export var cast_speed: float = 1.0
@export var attack_range: float = 28.0
## Zéro : ce jeu n'a pas de recul, le mécanisme reste (touches 3/4 de l'arène).
@export var knockback_force: float = 0.0
@export_range(0.0, 1.0) var crit_chance: float = 0.05
@export var crit_multiplier: float = 2.0

@export_group("Déplacement")
@export var move_speed: float = 90.0


## Constante de la courbe d'armure : 60 d'armure valent 50 % contre un coup de 12.
const ARMOR_K := 5.0
## Un coup passe toujours.
const MAX_ARMOR_REDUCTION := 0.90

## Même courbe, sans dépendre du coup : 60 d'évasion, une chance sur deux.
const EVASION_K := 60.0
## Au-delà, le combat devient une loterie qu'on gagne en attendant.
const MAX_EVASION := 0.75

## Ce qu'un niveau de zone ajoute à un ennemi, par niveau au-delà du premier.
## Linéaire : à 40, huit fois la vie et cinq fois les dégâts. Ni armure ni
## résistances ne montent — le joueur n'a aucun moyen de les percer.
const VIE_PAR_NIVEAU := 0.18
const DEGATS_PAR_NIVEAU := 0.12


## **Écrit dans la fiche donnée** : à l'appelant de l'avoir dupliquée (invariant 2).
static func mettre_a_l_echelle(stats: CharacterStats, niveau: int) -> void:
	var marches := float(maxi(niveau, 1) - 1)
	stats.max_health *= 1.0 + VIE_PAR_NIVEAU * marches
	stats.attack_damage *= 1.0 + DEGATS_PAR_NIVEAU * marches


## Cette liste sépare les modificateurs à appliquer **avant** la dérivation.
const ATTRIBUTES := ["strength", "dexterity", "intelligence"]


## Dérivée d'ATTRIBUTES : un attribut ajouté y apparaît sans qu'on y pense.
static func empty_attributes() -> Dictionary:
	var vide := {}
	for champ in ATTRIBUTES:
		vide[champ] = 0
	return vide

## Chaque attribut gouverne une réserve et une cadence. À dix partout, le départ :
## +20 PV, +2 dégâts, 15 d'esquive, +15 mana, +4 % sur les deux cadences.
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


## Ce que la force ajoute aux attaques en dégâts physiques, versé par le joueur dans
## ses modificateurs de compétence.
func degats_de_force() -> float:
	return strength * DAMAGE_PER_STRENGTH


## La fraction retranchée à un coup physique de cette taille, avant mitigation.
func armor_reduction(damage: float) -> float:
	if armor <= 0.0 or damage <= 0.0:
		return 0.0
	return minf(armor / (armor + ARMOR_K * damage), MAX_ARMOR_REDUCTION)


## La probabilité d'éviter entièrement un coup, entre 0 et MAX_EVASION.
func evade_chance() -> float:
	if evasion <= 0.0:
		return 0.0
	return minf(evasion / (evasion + EVASION_K), MAX_EVASION)


## Ce qui reste d'une part après sa défense : l'armure pour le physique, la
## résistance sinon. **La seule règle** : coup reçu et brûlure d'aura passent ici.
func attenuer(kind: int, part: float) -> float:
	if part <= 0.0:
		return part
	if kind == DamageType.Kind.PHYSICAL:
		return part * (1.0 - armor_reduction(part))
	return part * (1.0 - resistance(kind) * 0.01)

## Bornée ; zéro pour le physique, qui passe par l'armure.
func resistance(kind: DamageType.Kind) -> float:
	var field: String = DamageType.RESIST_FIELDS[kind]
	if field.is_empty():
		return 0.0
	return clampf(float(get(field)), MIN_RESISTANCE, MAX_RESISTANCE)


## Le plancher évite qu'une vitesse nulle fige l'attaquant.
func attack_interval() -> float:
	return attack_cooldown / maxf(attack_speed, 0.1)


## Verse ce que rapportent les attributs. **Une fois par recalcul, sur une fiche
## neuve**, sinon compté deux fois. Entre les modificateurs d'attributs et les
## autres : « +20 force » rapporte ses PV, et « +10 % PV » les multiplie.
func apply_attributes() -> void:
	max_health += strength * HEALTH_PER_STRENGTH

	evasion += dexterity * EVASION_PER_DEXTERITY
	attack_speed += dexterity * ATTACK_SPEED_PER_DEXTERITY * 0.01

	max_mana += intelligence * MANA_PER_INTELLIGENCE
	cast_speed += intelligence * CAST_SPEED_PER_INTELLIGENCE * 0.01
