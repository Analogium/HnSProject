class_name Inventory
extends RefCounted

## Le sac : une grille de cases où chaque objet occupe un **rectangle**, comme
## dans Path of Exile ou Hero Siege. Une épée tient sur trois cases de haut, un
## plastron sur deux colonnes et trois lignes. Ce n'est donc plus le nombre
## d'objets qui limite mais la place qu'ils prennent, et ranger devient une
## décision : garder l'arme encombrante ou trois babioles.
##
## Modèle pur — aucun nœud, aucun dessin. L'interface le lit et le manipule,
## mais il tourne aussi bien dans un test sans arbre de scène.

signal changed

const EMPTY := -1


## Un objet et le coin haut-gauche qu'il occupe. Une classe et non un
## dictionnaire : c'est la structure que toute l'interface manipule, elle mérite
## des champs nommés que l'éditeur complète.
class Placed:
	var data: ItemData
	var cell: Vector2i

	func _init(p_data: ItemData, p_cell: Vector2i) -> void:
		data = p_data
		cell = p_cell

	func rect() -> Rect2i:
		return Rect2i(cell, Inventory.footprint(data))


var cols: int
var rows: int

## Les objets rangés, dans leur ordre d'arrivée.
var placed: Array[Placed] = []

## Case -> index dans `placed`, ou EMPTY. Redondant avec `placed`, mais c'est
## lui qui rend « est-ce que ça tient ici ? » immédiat : sans lui, chaque case
## survolée par la souris ferait relire la liste entière des objets.
var _cells: PackedInt32Array


func _init(p_cols: int, p_rows: int) -> void:
	cols = p_cols
	rows = p_rows
	_cells.resize(cols * rows)
	_cells.fill(EMPTY)


## L'encombrement d'un objet, borné à une case au minimum : un .tres laissé à
## 0×0 donnerait sinon un objet qui n'occupe rien, donc invisible et impossible
## à reprendre.
static func footprint(item: ItemData) -> Vector2i:
	if item == null:
		return Vector2i.ONE
	return Vector2i(maxi(item.grid_size.x, 1), maxi(item.grid_size.y, 1))


func cell_count() -> int:
	return cols * rows


func used_cells() -> int:
	var n := 0
	for p in placed:
		var s := footprint(p.data)
		n += s.x * s.y
	return n


## Le rectangle tient-il entièrement dans la grille, sur des cases libres ?
func fits(item: ItemData, cell: Vector2i) -> bool:
	var s := footprint(item)
	if cell.x < 0 or cell.y < 0 or cell.x + s.x > cols or cell.y + s.y > rows:
		return false
	for y in range(cell.y, cell.y + s.y):
		for x in range(cell.x, cell.x + s.x):
			if _cells[y * cols + x] != EMPTY:
				return false
	return true


func place(item: ItemData, cell: Vector2i) -> bool:
	if item == null or not fits(item, cell):
		return false
	placed.append(Placed.new(item, cell))
	_stamp(placed.size() - 1)
	changed.emit()
	return true


## Range l'objet à la première place libre, en balayant ligne par ligne de
## gauche à droite — l'ordre dans lequel l'œil cherche lui-même un trou.
## Renvoie faux quand plus rien ne rentre ; l'appelant doit alors laisser
## l'objet où il est plutôt que de le perdre.
func add(item: ItemData) -> bool:
	for y in rows:
		for x in cols:
			if fits(item, Vector2i(x, y)):
				return place(item, Vector2i(x, y))
	return false


func index_at(cell: Vector2i) -> int:
	if cell.x < 0 or cell.y < 0 or cell.x >= cols or cell.y >= rows:
		return EMPTY
	return _cells[cell.y * cols + cell.x]


func at(cell: Vector2i) -> ItemData:
	var i := index_at(cell)
	return placed[i].data if i != EMPTY else null


## Retire l'objet qui couvre cette case et le rend.
##
## La grille d'occupation est reconstruite en entier plutôt que rapiécée :
## retirer un élément décale l'index de tous les suivants, et recoudre ça case
## par case est exactement le genre de code qui finit par laisser une case
## fantôme occupée par un objet qui n'existe plus. Cinquante cases et une
## poignée d'objets, on peut se le payer.
func take_at(cell: Vector2i) -> ItemData:
	var i := index_at(cell)
	if i == EMPTY:
		return null
	var item: ItemData = placed[i].data
	placed.remove_at(i)
	_rebuild()
	changed.emit()
	return item


func _stamp(index: int) -> void:
	var r := placed[index].rect()
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			_cells[y * cols + x] = index


func _rebuild() -> void:
	_cells.fill(EMPTY)
	for i in placed.size():
		_stamp(i)
