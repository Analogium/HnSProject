class_name StatHelp

## Ce que chaque statistique fait, au survol de la fiche : les champs de
## `CharacterStats` (clés de `StatMod.LABELS`) et les compétences de départ, chacun
## vérifié par un test. La ligne « en ce moment » est **calculée depuis la fiche**.
## Des gabarits aux valeurs **nommées** : un nombre dans la clé ferait tomber
## l'anglais au premier rééquilibrage.

## Le coup de référence de l'armure, le même que la fiche.
const LIGHT_HIT := 10.0
const HEAVY_HIT := 50.0

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

	"attack_time": "Le temps que prend un coup d'arme, avant la vitesse d'attaque.",
	"attack_speed": "La cadence du corps à corps. Elle ne touche pas au tir, qui suit la vitesse d'incantation.",
	"cooldown_recovery": "Raccourcit les recharges des compétences qui en ont une. **Ni la vitesse d'attaque ni celle d'incantation n'y touchent.**",
	"cast_speed": "La cadence du tir. Elle ne touche pas au coup d'épée, qui suit la vitesse d'attaque.",
	"attack_range": "L'allonge du coup d'épée, en pixels.",
	"crit_chance": "Celle de l'arme portée, seule à donner une base. Les bonus accrus la multiplient ensuite, compétence par compétence.",
	"crit_multiplier": "Ce que multiplie un coup critique.",
	"move_speed": "La vitesse de déplacement, en pixels par seconde.",
}

## Les compétences de départ, à part de `TEXTS` et **sans nombre** : leur ligne montre
## déjà les dégâts résolus.
const SKILLS := {
	SkillCatalog.ID_ATTACK: "Le coup d'épée : gratuit, à la cadence de l'arme. La force et tout ce qui ajoute des dégâts aux attaques le font monter.",
	SkillCatalog.ID_BOLT: "Le trait : un sort, qui coûte du mana et suit la vitesse d'incantation. Tout ce qui ajoute des dégâts aux sorts le fait monter.",
}


static func has(field: String) -> bool:
	return TEXTS.has(field) or SKILLS.has(field)


## Ce qu'elle fait, puis ce qu'elle vaut pour ce personnage-ci.
static func lines(field: String, stats: CharacterStats) -> PackedStringArray:
	var out := PackedStringArray()
	if SKILLS.has(field):
		out.append(Texts.t(SKILLS[field]))
		return out
	if not TEXTS.has(field):
		return out
	out.append(_what_it_does(field))
	var worth := _now(field, stats)
	if not worth.is_empty():
		out.append(worth)
	return out


## L'explication, ses nombres lus sur les constantes de la règle.
static func _what_it_does(field: String) -> String:
	var text_value := Texts.t(TEXTS[field])
	match field:
		"strength":
			return text_value.format({
				"pv": "%.0f" % CharacterStats.HEALTH_PER_STRENGTH,
				"degats": "%.1f" % CharacterStats.DAMAGE_PER_STRENGTH,
			})
		"dexterity":
			return text_value.format({
				"esquive": "%.1f" % CharacterStats.EVASION_PER_DEXTERITY,
				"vitesse": "%.1f" % CharacterStats.ATTACK_SPEED_PER_DEXTERITY,
			})
		"intelligence":
			return text_value.format({
				"mana": "%.1f" % CharacterStats.MANA_PER_INTELLIGENCE,
				"vitesse": "%.1f" % CharacterStats.CAST_SPEED_PER_INTELLIGENCE,
			})
	return text_value


## Vide pour ce qui se lit directement.
static func _now(field: String, stats: CharacterStats) -> String:
	match field:
		"armor":
			return Texts.t("Ici : {legers} % sur un coup de {coup_leger}, {lourds} % sur un coup de {coup_lourd}.").format({
				"legers": roundi(stats.armor_reduction(LIGHT_HIT) * 100.0),
				"coup_leger": int(LIGHT_HIT),
				"lourds": roundi(stats.armor_reduction(HEAVY_HIT) * 100.0),
				"coup_lourd": int(HEAVY_HIT),
			})
		"evasion":
			return Texts.t("Ici : {esquive} % des coups évités, {plafond} % au plus.").format({
				"esquive": roundi(stats.evade_chance() * 100.0),
				"plafond": roundi(CharacterStats.MAX_EVASION * 100.0),
			})
		"attack_speed":
			return Texts.t("Ici : un coup toutes les %.2f s.") % stats.attack_interval()
		"crit_chance":
			return Texts.t("Ici : {coups} coups sur cent avant les bonus accrus, pour {degats} % de dégâts.").format({
				"coups": roundi(stats.crit_chance * 100.0),
				"degats": roundi(stats.crit_multiplier * 100.0),
			})
	# Les résistances selon DamageType : une nature ajoutée hérite de la ligne.
	if field in DamageType.RESIST_FIELDS:
		return Texts.t("Plafonnée à {plafond} %, et elle peut devenir négative (jusqu'à {plancher} %).").format({
			"plafond": roundi(CharacterStats.MAX_RESISTANCE),
			"plancher": roundi(CharacterStats.MIN_RESISTANCE),
		})
	return ""
