class_name PassiveNode
extends Resource

## Un nœud de l'arbre de passifs. Ses lignes sont celles d'un passif de manuel, prises
## une fois : un nœud d'arbre n'a pas de rangs.

## **Ajouter à la fin** : les `.tres` écrivent l'entier.
enum Kind { START, SMALL, NOTABLE, KEYSTONE }

## **Définitif** (invariant 1) : il part dans les sauvegardes.
@export var id: String = ""
## Clé française ; vide pour un petit nœud, que ses lignes suffisent à dire.
@export var name: String = ""
@export var kind: Kind = Kind.SMALL

## En cases de la grille de l'arbre, pas en pixels.
@export var position: Vector2i = Vector2i.ZERO

## Écrit d'un seul côté : `PassiveTree` rend le graphe symétrique.
@export var links: PackedStringArray = PackedStringArray()

@export var lines: Array[TalentLine] = []


func displayed_name() -> String:
	return Texts.t(name)


func mods() -> Array[StatMod]:
	return TalentLine.modifiers(lines, 1)
