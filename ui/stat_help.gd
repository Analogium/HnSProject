class_name StatHelp

## Ce que chaque statistique fait, et comment elle se calcule quand ce n'est pas
## évident. C'est le texte que la fiche de personnage montre au survol.
##
## Deux tables, comme la fiche a deux sortes de lignes : les champs de
## `CharacterStats`, sous les **mêmes noms** que `StatMod.LABELS`, et les
## compétences de départ. Un test vérifie que chaque ligne affichée par la fiche a
## son entrée. Une entrée oubliée donnerait une infobulle vide en plein jeu plutôt
## qu'un échec ici.
##
## Ici et non dans `core/` : c'est de la prose d'interface. Les règles qu'elle
## décrit, elles, vivent dans CharacterStats — et la ligne « ce que ça vaut en ce
## moment » est **calculée depuis la fiche**, jamais recopiée à la main. Un texte
## qui affirmerait 75 % de plafond pendant que le code en applique 80 serait pire
## que pas de texte du tout.
##
## **Ce sont des gabarits, et les nombres y entrent à la lecture.** Écrits dans la
## table — « Chaque point donne 2 points de vie » —, ils feraient partie de la clé
## de traduction : un rééquilibrage changerait le texte français, et l'anglais
## tomberait sans que rien ne le dise. Les valeurs y sont donc **nommées**, parce
## qu'une phrase n'a pas le même ordre dans les deux langues.

## Le coup de référence contre lequel l'armure s'explique. Le même que celui de
## la fiche : deux valeurs différentes donneraient deux pourcentages différents
## pour la même armure, à trois lignes d'écart.
const COUP_LEGER := 10.0
const COUP_LOURD := 50.0

const TEXTS := {
	"strength": "La force. Chaque point donne {pv} points de vie et {degats} dégâts.",
	"dexterity": "La dextérité. Chaque point donne {esquive} d'esquive et {vitesse} % de vitesse d'attaque.",
	"intelligence": "L'intelligence. Chaque point donne {mana} de mana et {vitesse} % de vitesse d'incantation.",

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

	"attack_cooldown": "Le délai de base entre deux coups, avant la vitesse d'attaque.",
	"attack_speed": "La cadence du corps à corps. Elle ne touche pas au tir, qui suit la vitesse d'incantation.",
	"cast_speed": "La cadence du tir. Elle ne touche pas au coup d'épée, qui suit la vitesse d'attaque.",
	"attack_range": "L'allonge du coup d'épée, en pixels.",
	"crit_chance": "La probabilité qu'un coup soit critique.",
	"crit_multiplier": "Ce que multiplie un coup critique.",
	"move_speed": "La vitesse de déplacement, en pixels par seconde.",
}

## Les deux compétences de départ, qui ont leur ligne sur la fiche. À part de
## `TEXTS` : ce ne sont pas des champs de `CharacterStats`, et cette table-là est
## vérifiée champ par champ. **Sans nombre** : la ligne montre déjà les dégâts
## résolus, et un chiffre recopié ici mentirait au premier rééquilibrage.
const COMPETENCES := {
	CompetenceCatalog.ID_ATTAQUE: "Le coup d'épée : gratuit, à la cadence de l'arme. La force et tout ce qui ajoute des dégâts aux attaques le font monter.",
	CompetenceCatalog.ID_TIR: "Le trait : un sort, qui coûte du mana et suit la vitesse d'incantation. Tout ce qui ajoute des dégâts aux sorts le fait monter.",
}


static func has(field: String) -> bool:
	return TEXTS.has(field) or COMPETENCES.has(field)


## Le texte d'une statistique : ce qu'elle fait, puis ce qu'elle vaut à cet
## instant pour ce personnage-ci. « 40 d'armure, soit 44 % contre un coup de 10 »
## en apprend plus que n'importe quelle formule.
static func lines(field: String, stats: CharacterStats) -> PackedStringArray:
	var out := PackedStringArray()
	if COMPETENCES.has(field):
		out.append(Textes.t(COMPETENCES[field]))
		return out
	if not TEXTS.has(field):
		return out
	out.append(_ce_que_ca_fait(field))
	var vaut := _now(field, stats)
	if not vaut.is_empty():
		out.append(vaut)
	return out


## L'explication elle-même, ses nombres posés. Ceux-ci viennent des constantes de
## la règle et ne sont écrits nulle part ailleurs : un texte qui annoncerait deux
## points de vie par point de force pendant que le code en donne trois serait pire
## que pas de texte du tout.
static func _ce_que_ca_fait(field: String) -> String:
	var texte := Textes.t(TEXTS[field])
	match field:
		"strength":
			return texte.format({
				"pv": "%.0f" % CharacterStats.HEALTH_PER_STRENGTH,
				"degats": "%.1f" % CharacterStats.DAMAGE_PER_STRENGTH,
			})
		"dexterity":
			return texte.format({
				"esquive": "%.1f" % CharacterStats.EVASION_PER_DEXTERITY,
				"vitesse": "%.1f" % CharacterStats.ATTACK_SPEED_PER_DEXTERITY,
			})
		"intelligence":
			return texte.format({
				"mana": "%.1f" % CharacterStats.MANA_PER_INTELLIGENCE,
				"vitesse": "%.1f" % CharacterStats.CAST_SPEED_PER_INTELLIGENCE,
			})
	return texte


## La ligne « en ce moment ». Vide pour les statistiques qui se lisent
## directement — inventer une phrase pour « 90 de vitesse » n'apprendrait rien.
static func _now(field: String, stats: CharacterStats) -> String:
	match field:
		"armor":
			return Textes.t("Ici : {legers} % sur un coup de {coup_leger}, {lourds} % sur un coup de {coup_lourd}.").format({
				"legers": roundi(stats.armor_reduction(COUP_LEGER) * 100.0),
				"coup_leger": int(COUP_LEGER),
				"lourds": roundi(stats.armor_reduction(COUP_LOURD) * 100.0),
				"coup_lourd": int(COUP_LOURD),
			})
		"evasion":
			return Textes.t("Ici : {esquive} % des coups évités, {plafond} % au plus.").format({
				"esquive": roundi(stats.evade_chance() * 100.0),
				"plafond": roundi(CharacterStats.MAX_EVASION * 100.0),
			})
		"attack_speed":
			return Textes.t("Ici : un coup toutes les %.2f s.") % stats.attack_interval()
		"crit_chance":
			return Textes.t("Ici : {coups} coups sur cent, pour {degats} % de dégâts.").format({
				"coups": roundi(stats.crit_chance * 100.0),
				"degats": roundi(stats.crit_multiplier * 100.0),
			})
	# La liste des résistances vient de DamageType, seul endroit qui sait quels
	# éléments existent : une sixième école ajoutée là hériterait de la ligne
	# sans qu'on y pense.
	if field in DamageType.RESIST_FIELDS:
		return Textes.t("Plafonnée à {plafond} %, et elle peut devenir négative (jusqu'à {plancher} %).").format({
			"plafond": roundi(CharacterStats.MAX_RESISTANCE),
			"plancher": roundi(CharacterStats.MIN_RESISTANCE),
		})
	return ""
