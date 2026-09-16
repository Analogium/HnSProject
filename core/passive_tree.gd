class_name PassiveTree
extends Resource

## L'arbre de passifs, partagé par tous les personnages et **jamais écrit**
## (invariant 2). Toutes les règles de prise et de reprise sont ici : le personnage ne
## garde que la liste des nœuds pris, l'interface n'en vérifie aucune.

const PATH := "res://resources/passive_tree.tres"

@export var nodes: Array[PassiveNode] = []

## Déduits des nœuds au premier appel, jamais sauvegardés.
var _by_id := {}
var _neighbors := {}


## Chargé une fois : `load()` rend la même instance à chaque appel.
static func shared() -> PassiveTree:
	return load(PATH)


## Un point par niveau après le premier, **déduit** comme `Manual.points_gained()`.
static func points_gained(level: int) -> int:
	return maxi(level - 1, 0)


static func remaining_points(taken: PackedStringArray, level: int) -> int:
	return points_gained(level) - taken.size()


func node(id: String) -> PassiveNode:
	_index()
	return _by_id.get(id)


func start() -> PassiveNode:
	for n in nodes:
		if n.kind == PassiveNode.Kind.START:
			return n
	return null


## Les voisins dans les deux sens, quel que soit le côté où le lien est écrit.
func neighbors(id: String) -> PackedStringArray:
	_index()
	return _neighbors.get(id, PackedStringArray())


func can_take(taken: PackedStringArray, id: String, level: int) -> bool:
	var n := node(id)
	if n == null or n.kind == PassiveNode.Kind.START or id in taken:
		return false
	if remaining_points(taken, level) <= 0:
		return false
	for neighbor in neighbors(id):
		if neighbor in taken or node(neighbor).kind == PassiveNode.Kind.START:
			return true
	return false


## Gratuit, tant que **tous les autres** nœuds pris restent reliés au départ sans lui :
## un nœud du milieu d'une boucle se reprend, pas une feuille seule.
func can_release(taken: PackedStringArray, id: String) -> bool:
	if not id in taken:
		return false
	var without := taken.duplicate()
	without.remove_at(without.find(id))
	return connected(without).size() == without.size()


## Les nœuds pris reliés au départ, dans l'ordre d'un parcours en largeur : un préfixe
## de la liste reste relié. Ce qui est inconnu ou coupé en est écarté.
func connected(taken: PackedStringArray) -> PackedStringArray:
	var origin := start()
	var out := PackedStringArray()
	if origin == null:
		return out
	var queue: Array[String] = [origin.id]
	var seen := {origin.id: true}
	while not queue.is_empty():
		for neighbor in neighbors(queue.pop_front()):
			if seen.has(neighbor) or not neighbor in taken:
				continue
			seen[neighbor] = true
			out.append(neighbor)
			queue.append(neighbor)
	return out


## Ce qu'une sauvegarde peut porter : relié au départ, et pas plus de nœuds que de
## points — un fichier ne contourne pas la règle de prise.
func legal(taken: PackedStringArray, level: int) -> PackedStringArray:
	return connected(taken).slice(0, points_gained(level))


## Les lignes des nœuds pris, dans la forme d'un objet porté.
func mods(taken: PackedStringArray) -> Array[StatMod]:
	var out: Array[StatMod] = []
	for id in taken:
		var n := node(id)
		if n != null:
			out.append_array(n.mods())
	return out


func _index() -> void:
	if not _by_id.is_empty():
		return
	for n in nodes:
		_by_id[n.id] = n
	var both := {}
	for n in nodes:
		both[n.id] = []
	for n in nodes:
		for other in n.links:
			if both.has(other) and not other in both[n.id]:
				both[n.id].append(other)
				both[other].append(n.id)
	for id in both:
		_neighbors[id] = PackedStringArray(both[id])
