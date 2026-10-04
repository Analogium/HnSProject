class_name Manual
extends RefCounted

## Ce qu'un exemplaire de manuel a appris : son expérience et ses points placés. Son
## niveau se déduit, jamais retenu. RefCounted comme `Item` ; il ne connaît pas son
## archétype, que les règles reçoivent en argument.

## La courbe du manuel. Premier réglage : un livre neuf monte d'un niveau en une
## poignée d'ennemis, de trois en une zone.
const XP_BASE := 90.0
const XP_POWER := 1.25

## Vingt niveaux, vingt points, pour bien plus de destinations : le plafond fait du
## livre un choix plutôt qu'une collection.
const MAX_LEVEL := 20

## L'expérience **totale** : c'est elle qu'on écrit.
var experience := 0

## Points placés par identifiant : cases, passifs et nœuds partagent ce dictionnaire
## et ne doivent jamais se confondre (invariant 1). On y entre par `invest()` et
## `refund()`, qui portent les conditions.
var points := {}


## Déduit à chaque appel, jamais retenu.
func level() -> int:
	return Progression.reached_level(experience, XP_BASE, XP_POWER, MAX_LEVEL)


## Ce qu'il reste avant le niveau suivant, et le coût de ce niveau.
func progress() -> Vector2i:
	return Progression.progress(experience, XP_BASE, XP_POWER, MAX_LEVEL)


## Un point par niveau, le premier compris : un livre neuf ouvre une case. **Autant
## pour chaque arbre** (jalon 34) : le livre dit quels sorts, l'arbre comment ils se jouent.
func points_gained() -> int:
	return level()


func remaining_points(archetype: ManualArchetype) -> int:
	return points_gained() - points_spent(archetype)


## Le seul chemin : les manuels du râtelier, à chaque récompense.
func gain_experience(amount: int) -> void:
	if amount > 0:
		experience += amount


func points_of(identifier: String) -> int:
	return int(points.get(identifier, 0))


## Ce que les cases et les passifs ont pris au livre : un nœud paie sur son arbre.
## Sans archétype, aucun identifiant n'est reconnu comme nœud.
func points_spent(archetype: ManualArchetype) -> int:
	var total := 0
	for id in points:
		if archetype == null or archetype.node_of(id) == null:
			total += int(points[id])
	return total


func tree_points_spent(cell: ManualCell) -> int:
	var total := 0
	for node in cell.talents:
		total += points_of(node.id)
	return total


func tree_remaining(cell: ManualCell) -> int:
	return points_gained() - tree_points_spent(cell)


## **Toutes les conditions sont ici**, pour les trois sortes de destination :
## l'interface n'en vérifie aucune.
func can_invest(archetype: ManualArchetype, identifier: String) -> bool:
	if not is_open(archetype, identifier) or points_of(identifier) >= _maximum(archetype, identifier):
		return false
	var cell := archetype.cell_of_node(identifier)
	return (tree_remaining(cell) if cell != null else remaining_points(archetype)) > 0


## Les conditions **structurelles** seules : la page distingue « verrouillé » de
## « plus de point à placer ».
func is_open(archetype: ManualArchetype, identifier: String) -> bool:
	if archetype == null:
		return false
	var cell := archetype.cell_of(identifier)
	if cell != null:
		return level() >= cell.required_level()
	var passive := archetype.passive_of(identifier)
	if passive != null:
		return level() >= passive.required_manual_level
	cell = archetype.cell_of_node(identifier)
	return cell != null and node_open(cell, cell.node_of(identifier))


## Un point dans la compétence, et un lien tenu (jalon 34 : un réseau sans paliers).
## **Un lien se prend dans les deux sens** (jalon 39) : par le parent, qui porte les
## points demandés, ou par l'enfant, qui a payé son propre lien pour être là — le Ressac
## ouvre les Vagues jumelles qui l'ouvrent.
func node_open(cell: ManualCell, node: TalentNode) -> bool:
	if cell.skill == null or points_of(cell.skill.id) <= 0:
		return false
	return _linked(cell, node, _reached(cell))


## Un lien tenu vers ce nœud par un nœud déjà atteint, ou la racine.
func _linked(cell: ManualCell, node: TalentNode, reached: Dictionary) -> bool:
	if node.parents.is_empty():
		return true
	for parent: String in node.parents:
		if reached.has(parent) and points_of(parent) >= node.parents[parent]:
			return true
	for child in cell.talents:
		if reached.has(child.id) and child.parents.has(node.id):
			return true
	return false


## Les nœuds investis reliés à la compétence, **gagnés de proche en proche depuis elle** :
## deux nœuds reliés ne se tiennent pas ouverts l'un l'autre.
func _reached(cell: ManualCell) -> Dictionary:
	var reached := {}
	var progress := true
	while progress:
		progress = false
		for node in cell.talents:
			if not reached.has(node.id) and points_of(node.id) > 0 and _linked(cell, node, reached):
				reached[node.id] = true
				progress = true
	return reached


## Chaque nœud investi de l'arbre tient-il encore debout.
func _tree_holds(cell: ManualCell) -> bool:
	if cell.skill != null and points_of(cell.skill.id) <= 0:
		return tree_points_spent(cell) == 0
	var reached := _reached(cell)
	for node in cell.talents:
		if points_of(node.id) > 0 and not reached.has(node.id):
			return false
	return true


## Zéro pour ce que le livre ne connaît pas.
func _maximum(archetype: ManualArchetype, identifier: String) -> int:
	var cell := archetype.cell_of(identifier)
	if cell != null:
		return cell.points_max()
	var passive := archetype.passive_of(identifier)
	if passive != null:
		return passive.points_max
	var node := archetype.node_of(identifier)
	return node.points_max if node != null else 0


## Place un point et dit si c'est fait.
func invest(archetype: ManualArchetype, identifier: String) -> bool:
	if not can_invest(archetype, identifier):
		return false
	points[identifier] = points_of(identifier) + 1
	return true


## Un point se reprend partout (décidé le 14 septembre 2026) tant que l'arbre qu'il
## touche tient encore : ni nœud coupé de ses liens, ni arbre sans sort.
## Vérifié en retirant le point pour de bon puis en le rendant — une seule règle,
## celle qui ouvre les nœuds.
func can_refund(archetype: ManualArchetype, identifier: String) -> bool:
	if archetype == null or points_of(identifier) <= 0 or not archetype.knows(identifier):
		return false
	var cell := archetype.cell_of(identifier)
	if cell == null:
		cell = archetype.cell_of_node(identifier)
	if cell == null:
		return true
	points[identifier] = points_of(identifier) - 1
	var holds := _tree_holds(cell)
	points[identifier] = points_of(identifier) + 1
	return holds


## Rend le point **au livre** ; l'entrée est effacée à zéro, comme l'écrit la
## sauvegarde.
func refund(archetype: ManualArchetype, identifier: String) -> bool:
	if not can_refund(archetype, identifier):
		return false
	var remaining := points_of(identifier) - 1
	if remaining <= 0:
		points.erase(identifier)
	else:
		points[identifier] = remaining
	return true


## À la relecture : un arbre qui dépasse son pool ou dont un nœud ne tient plus est
## rendu **en entier** — il se replace en quelques clics, le nœud fautif se chercherait.
func release_broken_trees(archetype: ManualArchetype) -> void:
	if archetype == null:
		return
	for cell in archetype.cells:
		if tree_remaining(cell) >= 0 and _tree_holds(cell):
			continue
		for node in cell.talents:
			points.erase(node.id)


## Les nœuds investis de cette compétence, avec leurs points.
func invested_talents(archetype: ManualArchetype, skill_id: String) -> Array[InvestedTalent]:
	var out: Array[InvestedTalent] = []
	if archetype == null:
		return out
	var cell := archetype.cell_of(skill_id)
	if cell == null:
		return out
	for node in cell.talents:
		var spent := points_of(node.id)
		if spent > 0:
			out.append(InvestedTalent.new(node, spent))
	return out


## Dans la forme d'un objet porté : le même tri les range ensuite.
func passive_mods(archetype: ManualArchetype) -> Array[StatMod]:
	var out: Array[StatMod] = []
	if archetype == null:
		return out
	for passive in archetype.passives():
		out.append_array(passive.mods(points_of(passive.id)))
	return out
