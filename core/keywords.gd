class_name Keywords

## Les mots-clés de compétence : une liste fermée de **prises** pour les modificateurs.
## Fermée, pour qu'une faute de frappe ne donne pas un mot que rien ne vise ; honnête,
## pour qu'un mot affiché promette un bonus possible (test de la réserve). Distincts de
## `ItemBase.tags`, qui disent ce qu'un objet **est**. Une feuille.

const PROJECTILE := "projectile"
const LIGHTNING := "lightning"
const FIRE := "fire"
const SPELL := "spell"
const ATTACK := "attack"

## Identifiant et libellé, dans l'ordre de lecture. **Identifiants définitifs**
## (invariant 1).
const LABELS := {
	PROJECTILE: "Projectile",
	LIGHTNING: "Foudre",
	FIRE: "Feu",
	SPELL: "Sort",
	ATTACK: "Attaque",
}


## « … **aux sorts** » ; un mot-clé absent d'ici s'écrit par son libellé entre
## parenthèses.
const RECIPIENTS := {
	ATTACK: "aux attaques",
	SPELL: "aux sorts",
}


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
