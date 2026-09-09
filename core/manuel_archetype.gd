class_name ManuelArchetype
extends Resource

## Le contenu d'un manuel : ce qu'on peut y apprendre, et où c'est posé sur la
## page. **Partagé par tous les exemplaires** — c'est un `.tres` du disque.
##
## Rien de ce qu'un joueur gagne ne s'écrit ici (invariant 2). L'expérience et
## les points vivent sur `Manuel`, un par exemplaire ramassé : les poser ici
## donnerait à tous les manuels de foudre du jeu — et de toutes les parties
## suivantes de la session — les points du dernier livre ouvert, et l'éditeur
## pourrait graver le résultat sur le disque.

@export var id: String = ""
@export var nom: String = ""

## Les cases de la page. L'ordre est celui de la lecture, pas celui du dessin :
## chaque case porte sa propre position.
@export var cases: Array[CaseDeManuel] = []


## La case qui porte cette compétence, ou null. Le null est un cas de jeu et non
## une erreur : une sauvegarde peut citer une compétence retirée de l'archétype
## depuis, et ses points sont alors simplement oubliés.
func case_de(id_competence: String) -> CaseDeManuel:
	for c in cases:
		if c.competence != null and c.competence.id == id_competence:
			return c
	return null


## Les compétences de ce manuel, dans l'ordre des cases. Rendues plutôt que
## laissées à parcourir : l'appelant ne doit pas avoir à savoir qu'une case peut
## être vide.
func competences() -> Array[Competence]:
	var out: Array[Competence] = []
	for c in cases:
		if c.competence != null:
			out.append(c.competence)
	return out
