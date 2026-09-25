class_name Keywords

## Les mots-clés de compétence : une liste fermée de **prises** pour les modificateurs.
## Fermée, pour qu'une faute de frappe ne donne pas un mot que rien ne vise ; honnête,
## pour qu'un mot affiché promette un bonus possible (test de la réserve). Distincts de
## `ItemBase.tags`, qui disent ce qu'un objet **est**. Une feuille.

const PROJECTILE := "projectile"
## Ce qui frappe une surface plutôt qu'une cible : nuage, aura, serpent. Une forme,
## jamais une nature — un éclair peut être de zone.
const AREA := "area"
## Ce qui se bat pour le personnage : ce qu'il lève, ce qu'un portail crache.
const SUMMON := "summon"
const CURSE := "curse"
## Ce qui continue de blesser après le coup — un état qu'un lancer pose. Déclaré.
const DOT := "dot"
const LIGHTNING := "lightning"
const FIRE := "fire"
const COLD := "cold"
const NECROTIC := "necrotic"
const HOLY := "holy"
## Toutes les attaques du jeu, tant qu'aucune ne naît d'une autre nature.
const PHYSICAL := "physical"
const SPELL := "spell"
const ATTACK := "attack"
## Une attaque qui ne lance rien. Sous `ATTACK` dans l'ordre de lecture : tout ce qui
## est mêlée est aussi attaque, l'inverse est faux.
const MELEE := "melee"

## Identifiant et libellé, dans l'ordre de lecture. **Identifiants définitifs**
## (invariant 1).
const LABELS := {
	PROJECTILE: "Projectile",
	AREA: "Zone",
	SUMMON: "Invocation",
	CURSE: "Malédiction",
	DOT: "Dégâts continus",
	LIGHTNING: "Foudre",
	FIRE: "Feu",
	COLD: "Froid",
	NECROTIC: "Nécrotique",
	HOLY: "Sacré",
	PHYSICAL: "Physique",
	SPELL: "Sort",
	ATTACK: "Attaque",
	MELEE: "Mêlée",
}


## « … **aux sorts** » : à qui une ligne de dégâts ajoutés s'adresse. Un mot-clé absent
## d'ici retombe sur son libellé entre parenthèses — un repli, pas une façon d'écrire :
## `test_no_content_line_ends_in_parentheses` dit quand il faut lui écrire sa phrase.
const RECIPIENTS := {
	PROJECTILE: "aux projectiles",
	AREA: "aux compétences de zone",
	SUMMON: "aux invocations",
	CURSE: "aux malédictions",
	DOT: "aux compétences à dégâts continus",
	LIGHTNING: "aux compétences de foudre",
	FIRE: "aux compétences de feu",
	COLD: "aux compétences de froid",
	NECROTIC: "aux compétences nécrotiques",
	HOLY: "aux compétences sacrées",
	PHYSICAL: "aux compétences physiques",
	SPELL: "aux sorts",
	ATTACK: "aux attaques",
	MELEE: "aux attaques de mêlée",
}


## Ce qui qualifie un nom dans la phrase : « dégâts **de feu** accrus ». L'ordre des
## mots change avec la langue — « fire damage » —, donc c'est le gabarit
## `{stat} {qualificatif}` de `StatMod` qui les assemble, jamais une concaténation.
##
## Distinct de `RECIPIENTS`, qui dit à **qui** une ligne s'adresse (« aux sorts ») : ici
## on dit de **quoi** on parle.
const QUALIFIERS := {
	PROJECTILE: "de projectile",
	AREA: "de zone",
	SUMMON: "d'invocation",
	CURSE: "de malédiction",
	LIGHTNING: "de foudre",
	FIRE: "de feu",
	COLD: "de froid",
	NECROTIC: "nécrotiques",
	HOLY: "sacrés",
	PHYSICAL: "physiques",
	SPELL: "de sort",
	ATTACK: "d'attaque",
	MELEE: "de mêlée",
}


## Ce qui forme **avec les dégâts un seul nom**, traduit d'un bloc : « damage over
## time » ne se coupe pas en qualificatif, et le gabarit anglais, qui le poserait
## devant, écrirait « damage over time damage ».
const DAMAGE_NOUNS := {
	DOT: "dégâts continus",
}


## Vide pour ce qui n'en a pas : la phrase se passe alors de qualificatif. Une portée
## double les assemble par gabarit, l'ordre changeant avec la langue : « de sort de
## feu », « fire spell ».
static func qualifier(scope: String) -> String:
	var ids := words(scope)
	if ids.size() == 2:
		return Texts.t("{famille} {nature}").format(
			{"nature": qualifier(ids[0]), "famille": qualifier(ids[1])}
		)
	return Texts.t(QUALIFIERS[scope]) if QUALIFIERS.has(scope) else ""


static func recipient(id: String) -> String:
	if RECIPIENTS.has(id):
		return Texts.t(RECIPIENTS[id])
	return "(%s)" % label_of(id)


static func exists(id: String) -> bool:
	return LABELS.has(id)


## Une portée nomme un mot-clé, ou plusieurs séparés d'une espace — `fire spell` : les
## sorts de feu. **Tous** doivent être portés.
static func words(scope: String) -> PackedStringArray:
	return scope.split(" ", false)


static func covered(worn: PackedStringArray, scope: String) -> bool:
	for id in words(scope):
		if not worn.has(id):
			return false
	return not scope.is_empty()


## Dans l'ordre de lecture et sans doublon, hors liste écartée. **Le seul endroit qui
## connaît cet ordre** : les mots-clés arrivent de trois sources.
static func sort_in_order(ids: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	for id: String in LABELS:
		if ids.has(id):
			out.append(id)
	return out


## « Projectile · Foudre · Sort ».
static func line(ids: PackedStringArray) -> String:
	var names := PackedStringArray()
	for id in ids:
		names.append(label_of(id))
	return " · ".join(names)


## Dans la langue du joueur ; la table française est la clé.
static func label_of(id: String) -> String:
	return Texts.t(LABELS.get(id, id))
