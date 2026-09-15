class_name Ratelier
extends RefCounted

## Les manuels à l'étude : trois emplacements, **le seul endroit où un manuel
## apprend**. Trois pour que ce soit un choix ; un manuel posé ici quitte le sac.

const EMPLACEMENTS := 3

## Un Item par emplacement, ou null : l'objet entier, rendu tel qu'il est entré.
var manuels: Array[Item] = []


func _init() -> void:
	manuels.resize(EMPLACEMENTS)


## Ce qui se pose ici : un objet qui porte un manuel, et rien d'autre.
static func accepte(item: Item) -> bool:
	return item != null and item.manuel != null


## Rend celui qu'il remplace, ou **l'objet lui-même s'il est refusé** — jamais perdu,
## comme `Player.equip()`.
func poser(index: int, item: Item) -> Item:
	if item == null:
		return null
	if index < 0 or index >= EMPLACEMENTS or not accepte(item):
		return item
	var ancien := manuels[index]
	manuels[index] = item
	return ancien


func retirer(index: int) -> Item:
	if index < 0 or index >= EMPLACEMENTS:
		return null
	var parti := manuels[index]
	manuels[index] = null
	return parti


func a(index: int) -> Item:
	return manuels[index] if index >= 0 and index < EMPLACEMENTS else null


## Les manuels posés, sans les trous.
func equipes() -> Array[Item]:
	var out: Array[Item] = []
	for item in manuels:
		if item != null:
			out.append(item)
	return out


func vide() -> bool:
	return equipes().is_empty()
