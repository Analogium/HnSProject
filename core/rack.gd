class_name Rack
extends RefCounted

## Les manuels à l'étude : trois emplacements, **le seul endroit où un manuel
## apprend**. Trois pour que ce soit un choix ; un manuel posé ici quitte le sac.
## Un quatrième porte le manuel de la classe, qui n'est pas un choix.

const SLOT_COUNT := 4
## Le dernier : posé par `Character`, jamais rangé ni remplacé. `put()` et `remove()`
## ne le voient pas.
const CLASS_SLOT := 3

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
	if index < 0 or index >= CLASS_SLOT or not accepts(item):
		return item
	var old := manuals[index]
	manuals[index] = item
	return old


func remove(index: int) -> Item:
	if index < 0 or index >= CLASS_SLOT:
		return null
	var gone := manuals[index]
	manuals[index] = null
	return gone


## Le seul chemin vers l'emplacement de la classe.
func seat(item: Item) -> void:
	manuals[CLASS_SLOT] = item


## Le premier des trois emplacements libres, sinon le premier.
func free_slot() -> int:
	for i in CLASS_SLOT:
		if manuals[i] == null:
			return i
	return 0


## Les mêmes objets, pas des copies : le joueur et son personnage partagent leurs livres.
func copy_from(other: Rack) -> void:
	manuals = other.manuals.duplicate()


func at(index: int) -> Item:
	return manuals[index] if index >= 0 and index < SLOT_COUNT else null


## Les manuels posés, sans les trous.
func equipped_items() -> Array[Item]:
	var out: Array[Item] = []
	for item in manuals:
		if item != null:
			out.append(item)
	return out
