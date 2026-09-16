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


## Un point par niveau, le premier compris : un livre neuf ouvre une case.
func points_gained() -> int:
	return level()


func remaining_points() -> int:
	return points_gained() - points_spent()


## Le seul chemin : les manuels du râtelier, à chaque récompense.
func gain_experience(amount: int) -> void:
	if amount > 0:
		experience += amount


func points_of(identifier: String) -> int:
	return int(points.get(identifier, 0))


## Tous points confondus.
func points_spent() -> int:
	var total := 0
	for id in points:
		total += int(points[id])
	return total


## **Toutes les conditions sont ici**, pour les trois sortes de destination :
## l'interface n'en vérifie aucune.
func can_invest(archetype: ManualArchetype, identifier: String) -> bool:
	return (
		remaining_points() > 0
		and is_open(archetype, identifier)
		and points_of(identifier) < _maximum(archetype, identifier)
	)


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
	return _open_node(archetype, identifier)


## Sur les points de sa compétence, et son parent doit en porter un.
func _open_node(archetype: ManualArchetype, node_id: String) -> bool:
	var node := archetype.node_of(node_id)
	if node == null:
		return false
	var cell := archetype.cell_of_node(node_id)
	if cell == null or cell.skill == null:
		return false
	if points_of(cell.skill.id) < node.required_points:
		return false
	return node.parent.is_empty() or points_of(node.parent) > 0


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


## Un point se reprend partout (décidé le 14 septembre 2026), sauf un nœud dont un
## enfant porte des points, et une compétence qui passerait sous les points qu'un de
## ses nœuds investis demande.
func can_refund(archetype: ManualArchetype, identifier: String) -> bool:
	if archetype == null or points_of(identifier) <= 0:
		return false
	if archetype.passive_of(identifier) != null:
		return true
	var cell := archetype.cell_of(identifier)
	if cell != null:
		for node in cell.talents:
			if points_of(node.id) > 0 and points_of(identifier) - 1 < node.required_points:
				return false
		return true
	if archetype.node_of(identifier) == null:
		return false
	var cell_of_node := archetype.cell_of_node(identifier)
	if cell_of_node == null:
		return false
	for child in cell_of_node.children_of(identifier):
		if points_of(child.id) > 0:
			return false
	return true


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
