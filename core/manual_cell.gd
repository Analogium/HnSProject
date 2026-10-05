class_name ManualCell
extends Resource

## Une case de la page d'un manuel : **une** compétence ou **un** passif,
## l'endroit où elle est posée, et l'arbre qui s'accroche à une compétence.
##
## La position est ici et non sur ce que la case porte : une compétence est ce
## qu'elle fait, pas l'endroit où on la trouve. Le jour où deux manuels
## partageront un sort, chacun le posera où il veut — et lui donnera son arbre —
## sans que l'autre ait son mot à dire.
##
## **Une case, une chose.** Les deux à la fois donneraient deux compteurs de
## points pour une seule case dans le dictionnaire du manuel ; aucune des deux
## serait un trou sur la page, et seulement là.

@export var skill: Skill
@export var passive: Passive
## En cases de la grille de la page, pas en pixels : la page se redessine à une
## autre taille sans qu'aucun `.tres` ne bouge.
@export var position: Vector2i = Vector2i.ZERO
## L'arbre de la compétence. Vide pour un passif, qui n'a rien à orienter.
@export var talents: Array[TalentNode] = []


## L'identifiant de ce que la case porte : c'est lui qui compte ses points. Vide
## pour une case vide, que le test de contenu refuse.
func identifier() -> String:
	if skill != null:
		return skill.id
	return passive.id if passive != null else ""


## Combien de points cette case accepte, quelle que soit la sorte de ce qu'elle
## porte : la compétence le déduit de sa table de dégâts, le passif le déclare.
func points_max() -> int:
	if skill != null:
		return skill.points_max()
	return passive.points_max if passive != null else 0


## Le niveau de manuel qui l'ouvre.
func required_level() -> int:
	if skill != null:
		return skill.required_manual_level
	return passive.required_manual_level if passive != null else 0


func node_of(node_id: String) -> TalentNode:
	for n in talents:
		if n.id == node_id:
			return n
	return null


## **Une suite** (jalon 42) : tous ses parents changent le jeu, ou en sont eux-mêmes une.
## Elle ne s'ouvre que par ce qu'elle prolonge — déduite des liens, jamais déclarée.
func is_suite(node: TalentNode) -> bool:
	if node.parents.is_empty():
		return false
	for parent: String in node.parents:
		var p := node_of(parent)
		if p.kind().is_empty() and not is_suite(p):
			return false
	return true


## Le nœud qui change le jeu au bout de la lignée d'une suite — le nœud lui-même s'il en
## change un : c'est sa sorte qui colore la suite.
func lineage_head(node: TalentNode) -> TalentNode:
	if not is_suite(node):
		return node
	return lineage_head(node_of(node.parents.keys()[0]))
