class_name BarreDeCompetences
extends RefCounted

## Les cinq cases de la barre. Des **identifiants** et jamais des `Competence` : une
## compétence retirée laisse une case vide, pas un fichier illisible (invariant 1).

const EMPLACEMENTS := 5

## Une case vide est une chaîne vide.
var cases := PackedStringArray()


func _init() -> void:
	cases.resize(EMPLACEMENTS)


## La barre d'un personnage neuf, et d'une sauvegarde d'avant le jalon 6.
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


## Null pour une case vide, ou un identifiant qui ne désigne plus rien.
func competence_de(index: int) -> Competence:
	var id := id_de(index)
	return null if id.is_empty() else CompetenceCatalog.by_id(id)

