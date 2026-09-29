class_name TalentNode
extends Resource

## Un nœud d'arbre : ce qu'il change et ce qu'il demande. Sur la **case** du manuel
## et non sur la compétence — deux manuels orienteraient un sort chacun à sa façon.

## **Définitif** (invariant 1), dans le même dictionnaire que les cases : d'où la
## forme `<compétence>_<nœud>`.
@export var id: String = ""
@export var name: String = ""
## Ce que le nœud **fait en jeu**, en une ou deux phrases : les lignes disent de combien,
## pas quoi (jalon 34). Les chiffres des mécaniques s'y écrivent en `{champ}` de
## `SkillStats.facts()`, jamais en dur : ils mentiraient au premier réglage.
@export_multiline var description: String = ""

## En cases de la grille de l'arbre, pas en pixels.
@export var position: Vector2i = Vector2i.ZERO

## Le nœud parent, ou vide pour partir de la compétence. Un parent porte un point pour
## ouvrir l'enfant, et ne se reprend pas tant que l'enfant en porte.
@export var parent: String = ""

## Le palier (jalon 34) : combien de points placés dans les nœuds **moins profonds** de
## l'arbre l'ouvrent. Zéro pour la première colonne ; l'arbre entier attend un point
## dans la compétence.
@export var required_points: int = 0
@export var points_max: int = 1

@export var lines: Array[TalentLine] = []

## La conversion, **tout ou rien** (jalon 34) : un point, et la compétence devient de
## cette nature — ses dégâts, son mot-clé, son état, sa couleur. Le drapeau et non une
## valeur sentinelle : l'enum commence au physique.
@export var converts := false
@export var converts_to: DamageType.Kind = DamageType.Kind.PHYSICAL

## La transformation (jalon 34) : la forme qui **remplace** celle de la compétence au
## lancer. Le drapeau et non une valeur sentinelle : l'enum commence à `ARC`.
@export var transforms := false
@export var shape: Skill.Shape = Skill.Shape.ARC


func displayed_name() -> String:
	return Texts.t(name)


func displayed_description() -> String:
	return Texts.t(description).format(SkillStats.facts()) if not description.is_empty() else ""


## Sous la forme que la résolution et l'affichage connaissent déjà.
func mods(points: int) -> Array[StatMod]:
	return TalentLine.modifiers(lines, points)
