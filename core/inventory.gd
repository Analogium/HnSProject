class_name Inventory
extends RefCounted

## Le sac : chaque objet occupe un **rectangle**, et c'est la place qui limite, pas le
## nombre. Modèle pur, sans nœud.

signal changed

const EMPTY := -1

## Ici et non chez le Player : la sauvegarde reconstruit la grille sans l'acteur.
## Large plutôt que haut : une épée mange trois lignes.
const DEFAULT_COLS := 10
const DEFAULT_ROWS := 5


## Un objet et son coin haut-gauche.
class Placed:
	var data: Item
	var cell: Vector2i

	func _init(p_data: Item, p_cell: Vector2i) -> void:
		data = p_data
		cell = p_cell

	func rect() -> Rect2i:
		return Rect2i(cell, Inventory.footprint(data))


var cols: int
var rows: int

## Les objets rangés, dans leur ordre d'arrivée.
var placed: Array[Placed] = []

## Case -> index dans `placed` : sans lui, chaque survol relirait la liste.
var _cells: PackedInt32Array


func _init(p_cols: int, p_rows: int) -> void:
	cols = p_cols
	rows = p_rows
	_cells.resize(cols * rows)
	_cells.fill(EMPTY)


## Au moins une case : un `.tres` à 0×0 serait invisible et impossible à reprendre.
static func footprint(item: Item) -> Vector2i:
	if item == null or item.base == null:
		return Vector2i.ONE
	var s := item.base.grid_size
	return Vector2i(maxi(s.x, 1), maxi(s.y, 1))


func cell_count() -> int:
	return cols * rows


func used_cells() -> int:
	var n := 0
	for p in placed:
		var s := footprint(p.data)
		n += s.x * s.y
	return n


## Le rectangle tient-il entièrement dans la grille, sur des cases libres ?
func fits(item: Item, cell: Vector2i) -> bool:
	var s := footprint(item)
	if cell.x < 0 or cell.y < 0 or cell.x + s.x > cols or cell.y + s.y > rows:
		return false
	for y in range(cell.y, cell.y + s.y):
		for x in range(cell.x, cell.x + s.x):
			if _cells[y * cols + x] != EMPTY:
				return false
	return true


func place(item: Item, cell: Vector2i) -> bool:
	if item == null or not fits(item, cell):
		return false
	placed.append(Placed.new(item, cell))
	_stamp(placed.size() - 1)
	changed.emit()
	return true


## À la première place libre, ligne par ligne. Faux quand rien ne rentre : l'appelant
## laisse l'objet où il est.
func add(item: Item) -> bool:
	for y in rows:
		for x in cols:
			if fits(item, Vector2i(x, y)):
				return place(item, Vector2i(x, y))
	return false


func index_at(cell: Vector2i) -> int:
	if cell.x < 0 or cell.y < 0 or cell.x >= cols or cell.y >= rows:
		return EMPTY
	return _cells[cell.y * cols + cell.x]


## Rend l'objet de cette case. La grille est reconstruite en entier : la rapiécer
## laissait des cases fantômes.
func take_at(cell: Vector2i) -> Item:
	var i := index_at(cell)
	if i == EMPTY:
		return null
	var item: Item = placed[i].data
	placed.remove_at(i)
	_rebuild()
	changed.emit()
	return item


## Vide le sac sans le remplacer : le panneau garde une référence sur cet objet.
func clear() -> void:
	if placed.is_empty():
		return
	placed.clear()
	_rebuild()
	changed.emit()


func _stamp(index: int) -> void:
	var r := placed[index].rect()
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			_cells[y * cols + x] = index


func _rebuild() -> void:
	_cells.fill(EMPTY)
	for i in placed.size():
		_stamp(i)
