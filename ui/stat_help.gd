class_name StatHelp

## Ce que chaque statistique fait, et comment elle se calcule quand ce n'est pas
## évident. C'est le texte que la fiche de personnage montre au survol.
##
## Une seule table, indexée par les **mêmes noms de champs** que
## `StatMod.LABELS` : le nom lisible d'un côté, l'explication de l'autre, et un
## test vérifie que chaque statistique affichée par la fiche a son entrée. Une
## entrée oubliée donnerait une infobulle vide en plein jeu plutôt qu'un échec
## ici.
##
## Ici et non dans `core/` : c'est de la prose d'interface. Les règles qu'elle
## décrit, elles, vivent dans CharacterStats — et la ligne « ce que ça vaut en ce
## moment » est **calculée depuis la fiche**, jamais recopiée à la main. Un texte
## qui affirmerait 75 % de plafond pendant que le code en applique 80 serait pire
## que pas de texte du tout.

## Le coup de référence contre lequel l'armure s'explique. Le même que celui de
## la fiche : deux valeurs différentes donneraient deux pourcentages différents
## pour la même armure, à trois lignes d'écart.
const COUP_LEGER := 10.0
const COUP_LOURD := 50.0

const TEXTS := {
	"strength": "La force. Chaque point donne %.0f points de vie et %.1f dégâts."
		% [CharacterStats.HEALTH_PER_STRENGTH, CharacterStats.DAMAGE_PER_STRENGTH],
	"dexterity": "La dextérité. Chaque point donne %.1f d'esquive et %.1f %% de vitesse d'attaque."
		% [CharacterStats.EVASION_PER_DEXTERITY, CharacterStats.ATTACK_SPEED_PER_DEXTERITY],
	"intelligence": "L'intelligence. Chaque point donne %.1f de mana et %.1f %% de vitesse d'incantation."
		% [CharacterStats.MANA_PER_INTELLIGENCE, CharacterStats.CAST_SPEED_PER_INTELLIGENCE],

	"max_health": "Les points de vie. À zéro, la zone est perdue — jamais le personnage.",
	"health_regen": "Vie regagnée par seconde, en permanence. Elle ne s'interrompt pas au combat.",
	"max_mana": "La réserve. Chaque tir en coûte, le coup d'épée est gratuit.",
	"mana_regen": "Mana regagné par seconde. C'est lui qui fixe la cadence de tir soutenable.",

	"armor": "Une notation, pas des points retranchés. Elle protège proportionnellement plus des petits coups que des gros, et ne couvre que les dégâts physiques : contre un élément, seule la résistance compte.",
	"evasion": "Une notation, elle aussi. Un coup esquivé ne fait rien du tout — mais l'esquive ne protège que de ce qui vise, jamais des dégâts continus.",

	"res_cold": "Réduit les dégâts de froid, en pourcentage direct.",
	"res_fire": "Réduit les dégâts de feu, en pourcentage direct.",
	"res_lightning": "Réduit les dégâts de foudre, en pourcentage direct.",
	"res_necrotic": "Réduit les dégâts nécrotiques, en pourcentage direct.",
	"res_holy": "Réduit les dégâts sacrés, en pourcentage direct.",

	"attack_damage": "Les dégâts d'un coup d'épée, avant l'armure et les résistances de la cible.",
	"attack_cooldown": "Le délai de base entre deux coups, avant la vitesse d'attaque.",
	"attack_speed": "La cadence du corps à corps. Elle ne touche pas au tir, qui suit la vitesse d'incantation.",
	"cast_speed": "La cadence du tir. Elle ne touche pas au coup d'épée, qui suit la vitesse d'attaque.",
	"attack_range": "L'allonge du coup d'épée, en pixels.",
	"crit_chance": "La probabilité qu'un coup soit critique.",
	"crit_multiplier": "Ce que multiplie un coup critique.",
	"move_speed": "La vitesse de déplacement, en pixels par seconde.",
}


static func has(field: String) -> bool:
	return TEXTS.has(field)


## Le texte d'une statistique : ce qu'elle fait, puis ce qu'elle vaut à cet
## instant pour ce personnage-ci. « 40 d'armure, soit 44 % contre un coup de 10 »
## en apprend plus que n'importe quelle formule.
static func lines(field: String, stats: CharacterStats) -> PackedStringArray:
	var out := PackedStringArray()
	if not TEXTS.has(field):
		return out
	out.append(TEXTS[field])
	var vaut := _now(field, stats)
	if not vaut.is_empty():
		out.append(vaut)
	return out


## La ligne « en ce moment ». Vide pour les statistiques qui se lisent
## directement — inventer une phrase pour « 90 de vitesse » n'apprendrait rien.
static func _now(field: String, stats: CharacterStats) -> String:
	match field:
		"armor":
			return "Ici : %d %% sur un coup de %d, %d %% sur un coup de %d." % [
				roundi(stats.armor_reduction(COUP_LEGER) * 100.0), int(COUP_LEGER),
				roundi(stats.armor_reduction(COUP_LOURD) * 100.0), int(COUP_LOURD),
			]
		"evasion":
			return "Ici : %d %% des coups évités, %d %% au plus." % [
				roundi(stats.evade_chance() * 100.0), roundi(CharacterStats.MAX_EVASION * 100.0)
			]
		"attack_speed":
			return "Ici : un coup toutes les %.2f s." % stats.attack_interval()
		"crit_chance":
			return "Ici : %d coups sur cent, pour %d %% de dégâts." % [
				roundi(stats.crit_chance * 100.0), roundi(stats.crit_multiplier * 100.0)
			]
	# La liste des résistances vient de DamageType, seul endroit qui sait quels
	# éléments existent : une sixième école ajoutée là hériterait de la ligne
	# sans qu'on y pense.
	if field in DamageType.RESIST_FIELDS:
		return "Plafonnée à %d %%, et elle peut devenir négative (jusqu'à %d %%)." % [
			roundi(CharacterStats.MAX_RESISTANCE), roundi(CharacterStats.MIN_RESISTANCE)
		]
	return ""
