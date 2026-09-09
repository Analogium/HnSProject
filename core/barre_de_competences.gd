class_name BarreDeCompetences
extends RefCounted

## Les cinq cases à portée de doigt, en bas à droite de l'écran.
##
## Elle ne retient que des **identifiants**, jamais des `Competence` : c'est ce
## qui part sur le disque, et c'est ce qui permet à une compétence retirée du
## projet de laisser une case vide au lieu de rendre un fichier illisible. Les
## identifiants ne se renomment donc jamais (invariant 1).

const EMPLACEMENTS := 5

## Une case vide est une chaîne vide. Un `PackedStringArray` plutôt qu'un
## tableau de null : les cinq cases existent toujours, seule leur occupation
## change.
var cases := PackedStringArray()


func _init() -> void:
	cases.resize(EMPLACEMENTS)


## La barre d'un personnage neuf, et celle d'une sauvegarde d'avant le jalon 6 :
## le coup d'épée et le tir, c'est-à-dire exactement le jeu d'avant.
static func par_defaut() -> BarreDeCompetences:
	var b := BarreDeCompetences.new()
	b.poser(0, CompetenceCatalog.ID_ATTAQUE)
	b.poser(1, CompetenceCatalog.ID_TIR)
	return b


func poser(index: int, id_competence: String) -> void:
	if index < 0 or index >= EMPLACEMENTS:
		return
	cases[index] = id_competence


func vider(index: int) -> void:
	poser(index, "")


func id_de(index: int) -> String:
	return cases[index] if index >= 0 and index < EMPLACEMENTS else ""


## La compétence d'une case, ou null si la case est vide — ou si son identifiant
## ne désigne plus rien, ce qui est un cas de jeu et non une erreur.
func competence_de(index: int) -> Competence:
	var id := id_de(index)
	return null if id.is_empty() else CompetenceCatalog.by_id(id)

