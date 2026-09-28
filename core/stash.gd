class_name Stash
extends RefCounted

## Le coffre de la ville : cinq onglets, **partagés par tous les personnages** comme
## dans PoE — c'est ce qui permet de passer un objet de l'un à l'autre. Modèle pur ;
## le disque est à `SaveStore`.

## Le format du fichier, à part de celui des personnages : les deux évoluent seuls
## (invariant 7).
const VERSION := 1
const READABLE_VERSIONS := [1]

const TABS := 5
## Le coffre de PoE ; 253 px de côté, qui tiennent dans les 360 de haut.
const COLS := 12
const ROWS := 12

var tabs: Array[Inventory] = []

## Un fichier présent mais illisible : le coffre ne s'ouvre pas et ne s'écrit jamais,
## sans quoi le premier objet rangé écraserait tout ce que le fichier contient.
var unreadable := false


func _init() -> void:
	for i in TABS:
		tabs.append(Inventory.new(COLS, ROWS))


func to_dict() -> Dictionary:
	var written := []
	for tab in tabs:
		written.append(Character.grid_to_list(tab))
	return {"version": VERSION, "tabs": written}


## Null pour une version inconnue ; un onglet manquant reste vide.
static func from_dict(source: Dictionary) -> Stash:
	var version: Variant = source.get("version", 0)
	if not (version is float or version is int) or not READABLE_VERSIONS.has(int(version)):
		push_warning("Coffre de version %s, connues %s : refusé." % [version, READABLE_VERSIONS])
		return null
	var stash := Stash.new()
	var written: Variant = source.get("tabs")
	if written is Array:
		for i in mini((written as Array).size(), TABS):
			Character.grid_from_list(stash.tabs[i], written[i])
	return stash
