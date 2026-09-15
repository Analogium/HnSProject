class_name MotsCles

## Les mots-clés de compétence : une liste fermée de **prises** pour les modificateurs.
## Fermée, pour qu'une faute de frappe ne donne pas un mot que rien ne vise ; honnête,
## pour qu'un mot affiché promette un bonus possible (test de la réserve). Distincts de
## `ItemBase.tags`, qui disent ce qu'un objet **est**. Une feuille.

const PROJECTILE := "projectile"
const FOUDRE := "foudre"
const FEU := "feu"
const SORT := "sort"
const ATTAQUE := "attaque"

## Identifiant et libellé, dans l'ordre de lecture. **Identifiants définitifs**
## (invariant 1).
const LIBELLES := {
	PROJECTILE: "Projectile",
	FOUDRE: "Foudre",
	FEU: "Feu",
	SORT: "Sort",
	ATTAQUE: "Attaque",
}


## « … **aux sorts** » ; un mot-clé absent d'ici s'écrit par son libellé entre
## parenthèses.
const DESTINATAIRES := {
	ATTAQUE: "aux attaques",
	SORT: "aux sorts",
}


static func destinataire(id: String) -> String:
	if DESTINATAIRES.has(id):
		return Textes.t(DESTINATAIRES[id])
	return "(%s)" % libelle(id)


static func existe(id: String) -> bool:
	return LIBELLES.has(id)


## Dans l'ordre de lecture et sans doublon, hors liste écartée. **Le seul endroit qui
## connaît cet ordre** : les mots-clés arrivent de trois sources.
static func ordonner(ids: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	for id: String in LIBELLES:
		if ids.has(id):
			out.append(id)
	return out


## « Projectile · Foudre · Sort ».
static func ligne(ids: PackedStringArray) -> String:
	var noms := PackedStringArray()
	for id in ids:
		noms.append(libelle(id))
	return " · ".join(noms)


## Dans la langue du joueur ; la table française est la clé.
static func libelle(id: String) -> String:
	return Textes.t(LIBELLES.get(id, id))
