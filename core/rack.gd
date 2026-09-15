class_name Rack
extends RefCounted

## Les manuels à l'étude : trois emplacements, **le seul endroit où un manuel
## apprend**. Trois pour que ce soit un choix ; un manuel posé ici quitte le sac.

const SLOT_COUNT := 3

## Un Item par emplacement, ou null : l'objet entier, rendu tel qu'il est entré.
var manuals: Array[Item] = []


func _init() -> void:
	manuals.resize(SLOT_COUNT)


## Ce qui se pose ici : un objet qui porte un manuel, et rien d'autre.
static func accepts(item: Item) -> bool:
	return item != null and item.manual != null


## Rend celui qu'il remplace, ou **l'objet lui-même s'il est refusé** — jamais perdu,
## comme `Player.equip()`.
func put(index: int, item: Item) -> Item:
	if item == null:
		return null
	if index < 0 or index >= SLOT_COUNT or not accepts(item):
		return item
	var old := manuals[index]
	manuals[index] = item
	return old


func remove(index: int) -> Item:
	if index < 0 or index >= SLOT_COUNT:
		return null
	var gone := manuals[index]
	manuals[index] = null
	return gone


func at(index: int) -> Item:
	return manuals[index] if index >= 0 and index < SLOT_COUNT else null


## Les manuels posés, sans les trous.
func equipped_items() -> Array[Item]:
	var out: Array[Item] = []
	for item in manuals:
		if item != null:
			out.append(item)
	return out


func empty() -> bool:
	return equipped_items().is_empty()
