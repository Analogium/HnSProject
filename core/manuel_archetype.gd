class_name ManuelArchetype
extends Resource

## Le contenu d'un manuel, **partagé par tous les exemplaires** : rien de ce qu'un
## joueur gagne ne s'écrit ici (invariant 2 — c'est `Manuel`). Les recherches rendent
## null sur un identifiant inconnu, qu'une sauvegarde peut citer.

@export var id: String = ""
@export var nom: String = ""

## Dans l'ordre de lecture ; chaque case porte sa position.
@export var cases: Array[CaseDeManuel] = []


## `nom` est la clé française.
func nom_affiche() -> String:
	return Textes.t(nom)


## La case qui porte cette compétence, ou null.
func case_de(id_competence: String) -> CaseDeManuel:
	for c in cases:
		if c.competence != null and c.competence.id == id_competence:
			return c
	return null


func passif_de(id_passif: String) -> Passif:
	for c in cases:
		if c.passif != null and c.passif.id == id_passif:
			return c.passif
	return null


func noeud_de(id_noeud: String) -> NoeudDeTalent:
	for c in cases:
		var n := c.noeud_de(id_noeud)
		if n != null:
			return n
	return null


## La case dont l'arbre contient ce nœud : c'est elle qui dit de quelle
## compétence il faut des points pour l'ouvrir.
func case_du_noeud(id_noeud: String) -> CaseDeManuel:
	for c in cases:
		if c.noeud_de(id_noeud) != null:
			return c
	return null


## Case, passif ou nœud confondus : la question de la relecture d'une sauvegarde.
func connait(identifiant: String) -> bool:
	return (
		case_de(identifiant) != null
		or passif_de(identifiant) != null
		or noeud_de(identifiant) != null
	)


## Les compétences, dans l'ordre des cases.
func competences() -> Array[Competence]:
	var out: Array[Competence] = []
	for c in cases:
		if c.competence != null:
			out.append(c.competence)
	return out


func passifs() -> Array[Passif]:
	var out: Array[Passif] = []
	for c in cases:
		if c.passif != null:
			out.append(c.passif)
	return out
