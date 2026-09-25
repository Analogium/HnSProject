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
## Le temps que prend **un coup d'arme**, propre à l'arme ; `attack_speed` en est le
## multiplicateur porté par le personnage. **Ce n'est pas une recharge** : une recharge
## est le délai propre d'une compétence, que la cadence ne touche pas (`Skill.cooldown`).
@export var attack_time: float = 0.45
## Multiplicateurs, 1.0 = cadence de base : les affixes y portent en pourcentage.
@export var attack_speed: float = 1.0
@export var cast_speed: float = 1.0
@export var attack_range: float = 28.0
## Zéro : ce jeu n'a pas de recul, le mécanisme reste (touches 3/4 de l'arène).
@export var knockback_force: float = 0.0
## La base de chaque lancer : celle de l'arme (`Item.crit_chance()`), plus les plats des
## autres objets et de l'arbre. Les accrus n'y entrent pas, ils la multiplient au lancer.
@export_range(0.0, 1.0) var crit_chance: float = 0.0
@export var crit_multiplier: float = 2.0

## En **points de pourcentage**, qui multiplient la chance de poser l'état : à +50, une
## chance de base de 20 % devient 30 %. Sans chance de base, ils ne font rien.
@export var ignite_chance: float = 0.0
## La chance, en points de pourcentage, qu'un coup porté à un engourdi laisse une charge
## statique. Zéro : aucune.
@export var static_charge_chance: float = 0.0
## Comme `ignite_chance`, pour le gel.
@export var chill_chance: float = 0.0
## Comme `ignite_chance`, pour la bénédiction.
@export var blessing_chance: float = 0.0
## Comme `ignite_chance`, pour la pourriture — les à-coups de décomposition compris.
@export var rot_chance: float = 0.0

## Ce qui **raccourcit les recharges**, en points de pourcentage : à +50, une recharge
## de 3 s tombe à 2 s. La seule chose qui les touche — ni la vitesse d'attaque ni celle
## d'incantation n'y peuvent rien, c'est ce qui sépare les deux notions (jalon 22).
@export var cooldown_recovery: float = 0.0

## Ce qu'on prend **en plus** de chaque coup, en points de pourcentage : négatif, on en
## prend moins. Le tombeau de glace est le seul à l'écrire aujourd'hui. Borné à −100 :
## l'invulnérabilité pure n'existe pas dans ce jeu.
@export var damage_taken: float = 0.0

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

## Par niveau au-delà du premier. La vie se **compose** — ×8 à 40, ×23 à 60, ×585 à
## 120 — parce que les dégâts du joueur se multiplient entre eux ; les dégâts restent
## linéaires (×5,7 à 40).
const HEALTH_PER_LEVEL := 0.055
const DAMAGE_PER_LEVEL := 0.12
## Linéaires (décidé le 15 septembre 2026). L'armure pèse contre la taille du coup :
## 195 en zone 40 retirent ~22 % d'un coup de 140, 595 en zone 120 ~37 % d'un coup de
## 200. Les résistances : 13 % en zone 40, 39 % en zone 120.
const ARMOR_PER_LEVEL := 5.0
const RESISTANCE_PER_LEVEL := 0.33


## **Écrit dans la fiche donnée** : à l'appelant de l'avoir dupliquée (invariant 2).
static func scale_to_level(stats: CharacterStats, level: int) -> void:
	var steps := float(maxi(level, 1) - 1)
	stats.max_health *= pow(1.0 + HEALTH_PER_LEVEL, steps)
	stats.attack_damage *= 1.0 + DAMAGE_PER_LEVEL * steps
	stats.armor += ARMOR_PER_LEVEL * steps
	for field: String in DamageType.RESIST_FIELDS:
		if not field.is_empty():
			stats.set(field, float(stats.get(field)) + RESISTANCE_PER_LEVEL * steps)


## Cette liste sépare les modificateurs à appliquer **avant** la dérivation.
const ATTRIBUTES := ["strength", "dexterity", "intelligence"]


## Chaque attribut gouverne deux choses. À dix partout, le départ : +20 PV,
## +2 dégâts, 15 d'esquive, +4 % de vitesse d'attaque, +15 mana, +0,5 mana/s.
## **L'intelligence ne donne pas de vitesse d'incantation** : la cadence des sorts
## s'achète sur les objets et l'arbre, sinon elle monterait toute seule et ne serait
## plus une statistique qu'on poursuit.
const HEALTH_PER_STRENGTH := 2.0
const DAMAGE_PER_STRENGTH := 0.2
const EVASION_PER_DEXTERITY := 1.5
## En points de pourcentage ajoutés au multiplicateur : dix points de dextérité
## font passer la cadence de 100 à 104 %.
const ATTACK_SPEED_PER_DEXTERITY := 0.4
const MANA_PER_INTELLIGENCE := 1.5
const MANA_REGEN_PER_INTELLIGENCE := 0.05

## Le plafond classique du genre. Il donne sa valeur à l'objectif « atteindre le
## plafond », et empêche l'immunité pure à un élément.
const MAX_RESISTANCE := 75.0
## Au pire un coup fait le double, jamais plus : une malédiction doit faire mal,
## pas transformer un coup d'épingle en exécution.
const MIN_RESISTANCE := -100.0


## Ce que la force ajoute aux attaques en dégâts physiques, versé par le joueur dans
## ses modificateurs de compétence.
func strength_damage() -> float:
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
## `lost` : les points de résistance qu'un état retire — la malédiction.
func mitigate(kind: int, part: float, lost := 0.0) -> float:
	if part <= 0.0:
		return part
	var defended := part
	if kind == DamageType.Kind.PHYSICAL:
		defended *= 1.0 - armor_reduction(part)
	else:
		defended *= 1.0 - resistance(kind, lost) * 0.01
	# Après la défense de la nature, et sur toutes : c'est un abri, pas une résistance.
	return defended * maxf(1.0 + damage_taken * 0.01, 0.0)

## Bornée, ce que retire une malédiction **avant** la borne ; zéro pour le physique, qui
## passe par l'armure.
func resistance(kind: DamageType.Kind, lost := 0.0) -> float:
	var field: String = DamageType.RESIST_FIELDS[kind]
	if field.is_empty():
		return 0.0
	return clampf(float(get(field)) - lost, MIN_RESISTANCE, MAX_RESISTANCE)


## Le plancher évite qu'une vitesse nulle fige l'attaquant.
func attack_interval() -> float:
	return attack_time / maxf(attack_speed, 0.1)


## Ce par quoi une recharge est divisée. Borné en bas comme les cadences : une
## récupération de −100 % figerait la compétence pour toujours.
func recovery_factor() -> float:
	return maxf(1.0 + cooldown_recovery * 0.01, 0.1)


## Verse ce que rapportent les attributs. **Une fois par recalcul, sur une fiche
## neuve**, sinon compté deux fois. Entre les modificateurs d'attributs et les
## autres : « +20 force » rapporte ses PV, et « +10 % PV » les multiplie.
func apply_attributes() -> void:
	max_health += strength * HEALTH_PER_STRENGTH

	evasion += dexterity * EVASION_PER_DEXTERITY
	attack_speed += dexterity * ATTACK_SPEED_PER_DEXTERITY * 0.01

	max_mana += intelligence * MANA_PER_INTELLIGENCE
	mana_regen += intelligence * MANA_REGEN_PER_INTELLIGENCE
