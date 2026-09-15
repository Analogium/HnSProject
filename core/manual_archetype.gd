class_name ManualArchetype
extends Resource

## Le contenu d'un manuel, **partagé par tous les exemplaires** : rien de ce qu'un
## joueur gagne ne s'écrit ici (invariant 2 — c'est `Manual`). Les recherches rendent
## null sur un identifiant inconnu, qu'une sauvegarde peut citer.

@export var id: String = ""
@export var name: String = ""

## Dans l'ordre de lecture ; chaque case porte sa position.
@export var cells: Array[ManualCell] = []


## `name` est la clé française.
func displayed_name() -> String:
	return Texts.t(name)


## La case qui porte cette compétence, ou null.
func cell_of(skill_id: String) -> ManualCell:
	for c in cells:
		if c.skill != null and c.skill.id == skill_id:
			return c
	return null


func passive_of(passive_id: String) -> Passive:
	for c in cells:
		if c.passive != null and c.passive.id == passive_id:
			return c.passive
	return null


func node_of(node_id: String) -> TalentNode:
	for c in cells:
		var n := c.node_of(node_id)
		if n != null:
			return n
	return null


## La case dont l'arbre contient ce nœud : c'est elle qui dit de quelle
## compétence il faut des points pour l'ouvrir.
func cell_of_node(node_id: String) -> ManualCell:
	for c in cells:
		if c.node_of(node_id) != null:
			return c
	return null


## Case, passif ou nœud confondus : la question de la relecture d'une sauvegarde.
func knows(identifier: String) -> bool:
	return (
		cell_of(identifier) != null
		or passive_of(identifier) != null
		or node_of(identifier) != null
	)


## Les compétences, dans l'ordre des cases.
func skills() -> Array[Skill]:
	var out: Array[Skill] = []
	for c in cells:
		if c.skill != null:
			out.append(c.skill)
	return out


func passives() -> Array[Passive]:
	var out: Array[Passive] = []
	for c in cells:
		if c.passive != null:
			out.append(c.passive)
	return out
