class_name SkillCatalog

## Toutes les compétences, **le seul endroit qui les liste**. Un identifiant disparu
## rend null plutôt que de faire échouer un chargement.

## Les attaques de départ, que personne n'apprend : les seuls identifiants cités par
## le code.
const ID_ATTACK := "attack"
const ID_BOLT := "bolt"

## Ce qu'on sait sans l'avoir appris, dans l'ordre du menu de la barre.
const STARTING := [ID_ATTACK, ID_BOLT]

const ALL := [
	preload("res://resources/skills/attack.tres"),
	preload("res://resources/skills/bolt.tres"),

	# Chaque manuel, dans l'ordre de ses cases.
	preload("res://resources/skills/swift_bolt.tres"),
	preload("res://resources/skills/chain_lightning.tres"),
	preload("res://resources/skills/storm_cloud.tres"),
	preload("res://resources/skills/lightning_nova.tres"),

	preload("res://resources/skills/fireball.tres"),
	preload("res://resources/skills/hell_snake.tres"),
	preload("res://resources/skills/immolation.tres"),

	# Le chevalier : les compétences apprises qui suivent la cadence de l'arme.
	preload("res://resources/skills/heavy_strike.tres"),
	preload("res://resources/skills/cross_slash.tres"),
	preload("res://resources/skills/spiral_sword.tres"),
]


static func is_starting(id: String) -> bool:
	return STARTING.has(id)


## Null pour un identifiant retiré du projet, qu'une barre sauvegardée peut citer.
## Balayage linéaire : le catalogue se compte en unités.
static func by_id(id: String) -> Skill:
	for c in ALL:
		if c.id == id:
			return c
	return null
