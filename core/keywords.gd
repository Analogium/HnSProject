class_name Keywords

## Les mots-clés de compétence : une liste fermée de **prises** pour les modificateurs.
## Fermée, pour qu'une faute de frappe ne donne pas un mot que rien ne vise ; honnête,
## pour qu'un mot affiché promette un bonus possible (test de la réserve). Distincts de
## `ItemBase.tags`, qui disent ce qu'un objet **est**. Une feuille.

const PROJECTILE := "projectile"
## Ce qui frappe une surface plutôt qu'une cible : nuage, aura, serpent. Une forme,
## jamais une nature — un éclair peut être de zone.
const AREA := "area"
const LIGHTNING := "lightning"
const FIRE := "fire"
const COLD := "cold"
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
	LIGHTNING: "Foudre",
	FIRE: "Feu",
	COLD: "Froid",
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
	LIGHTNING: "aux compétences de foudre",
	FIRE: "aux compétences de feu",
	COLD: "aux compétences de froid",
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
	LIGHTNING: "de foudre",
	FIRE: "de feu",
	COLD: "de froid",
	SPELL: "de sort",
	ATTACK: "d'attaque",
	MELEE: "de mêlée",
}


## Vide pour ce qui n'en a pas : la phrase se passe alors de qualificatif.
static func qualifier(id: String) -> String:
	return Texts.t(QUALIFIERS[id]) if QUALIFIERS.has(id) else ""


static func recipient(id: String) -> String:
	if RECIPIENTS.has(id):
		return Texts.t(RECIPIENTS[id])
	return "(%s)" % label_of(id)


static func exists(id: String) -> bool:
	return LABELS.has(id)


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
