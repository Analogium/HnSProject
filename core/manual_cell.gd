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


## Les nœuds qui dépendent de celui-ci. Le dessin en tire ses liens, et la
## reprise d'un point s'en sert pour refuser de couper une branche sous un nœud
## qui porte encore des points.
func children_of(node_id: String) -> Array[TalentNode]:
	var out: Array[TalentNode] = []
	for n in talents:
		if n.parent == node_id:
			out.append(n)
	return out
