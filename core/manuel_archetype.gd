class_name ManuelArchetype
extends Resource

## Le contenu d'un manuel : ce qu'on peut y apprendre, où c'est posé sur la page,
## et ce que chaque compétence peut devenir. **Partagé par tous les
## exemplaires** — c'est un `.tres` du disque.
##
## Rien de ce qu'un joueur gagne ne s'écrit ici (invariant 2). L'expérience et
## les points vivent sur `Manuel`, un par exemplaire ramassé : les poser ici
## donnerait à tous les manuels de foudre du jeu — et de toutes les parties
## suivantes de la session — les points du dernier livre ouvert, et l'éditeur
## pourrait graver le résultat sur le disque.
##
## Les trois fonctions de recherche — `case_de`, `passif_de`, `noeud_de` — rendent
## null sur un identifiant inconnu, et ce n'est pas une erreur de programmation :
## une sauvegarde peut citer ce que l'archétype ne contient plus.

@export var id: String = ""
@export var nom: String = ""

## Les cases de la page. L'ordre est celui de la lecture, pas celui du dessin :
## chaque case porte sa propre position.
@export var cases: Array[CaseDeManuel] = []


## Le nom tel que le joueur le lit. `nom` est la clé française écrite dans le
## `.tres` : une interface qui l'afficherait directement resterait en français.
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


## Ce livre connaît-il cet identifiant, case, passif ou nœud confondus ?
##
## **La question de la relecture d'une sauvegarde** : les trois sortes partagent
## le dictionnaire de points du manuel, et un point dont personne ne reconnaît
## l'identifiant n'est dépensable nulle part.
func connait(identifiant: String) -> bool:
	return (
		case_de(identifiant) != null
		or passif_de(identifiant) != null
		or noeud_de(identifiant) != null
	)


## Les compétences de ce manuel, dans l'ordre des cases. Rendues plutôt que
## laissées à parcourir : l'appelant ne doit pas avoir à savoir qu'une case peut
## porter autre chose.
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
