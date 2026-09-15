class_name SkillBar
extends RefCounted

## Les cinq cases de la barre. Des **identifiants** et jamais des `Skill` : une
## compétence retirée laisse une case vide, pas un fichier illisible (invariant 1).

const SLOT_COUNT := 5

## Une case vide est une chaîne vide.
var cells := PackedStringArray()


func _init() -> void:
	cells.resize(SLOT_COUNT)


## La barre d'un personnage neuf, et d'une sauvegarde d'avant le jalon 6.
static func starting() -> SkillBar:
	var b := SkillBar.new()
	b.put(0, SkillCatalog.ID_ATTACK)
	b.put(1, SkillCatalog.ID_BOLT)
	return b


func put(index: int, skill_id: String) -> void:
	if index < 0 or index >= SLOT_COUNT:
		return
	cells[index] = skill_id


func clear(index: int) -> void:
	put(index, "")


func id_of(index: int) -> String:
	return cells[index] if index >= 0 and index < SLOT_COUNT else ""


## Null pour une case vide, ou un identifiant qui ne désigne plus rien.
func skill_of(index: int) -> Skill:
	var id := id_of(index)
	return null if id.is_empty() else SkillCatalog.by_id(id)

