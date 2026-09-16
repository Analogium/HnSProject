class_name TalentNode
extends Resource

## Un nœud d'arbre : ce qu'il change et ce qu'il demande. Sur la **case** du manuel
## et non sur la compétence — deux manuels orienteraient un sort chacun à sa façon.

## **Définitif** (invariant 1), dans le même dictionnaire que les cases : d'où la
## forme `<compétence>_<nœud>`.
@export var id: String = ""
@export var name: String = ""

## En cases de la grille de l'arbre, pas en pixels.
@export var position: Vector2i = Vector2i.ZERO

## Le nœud parent, ou vide pour partir de la compétence. Un parent porte un point pour
## ouvrir l'enfant, et ne se reprend pas tant que l'enfant en porte.
@export var parent: String = ""

## Combien de points dans la **compétence** ouvrent ce nœud. Jamais zéro : un
## arbre s'achète après le sort, pas à sa place.
@export var required_points: int = 1
@export var points_max: int = 1

@export var lines: Array[TalentLine] = []

## La nature d'arrivée et la part par point. **C'est la part qui dit s'il y a
## conversion** : l'enum commence au physique.
@export var converts_to: DamageType.Kind = DamageType.Kind.PHYSICAL
@export var converted_part_per_point: float = 0.0

## **Seulement des mots-clés de nature** : `projectile`, `attack` et `spell` décident
## du chemin du lancer.
@export var added_keywords: PackedStringArray = PackedStringArray()


func displayed_name() -> String:
	return Texts.t(name)


func converts() -> bool:
	return converted_part_per_point > 0.0


## Sous la forme que la résolution et l'affichage connaissent déjà.
func mods(points: int) -> Array[StatMod]:
	return TalentLine.modifiers(lines, points)


## La part des dégâts que ces points déplacent, **bornée au tout** : un nœud mal
## réglé ne doit pas convertir plus que ce qu'il y a.
func conversion(points: int) -> float:
	if points <= 0 or not converts():
		return 0.0
	return clampf(converted_part_per_point * float(points), 0.0, 1.0)
