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
## Sa vignette dans l'arbre (jalon 42), au côté que demande son rôle
## (`ManualPanel.NODE_ICONS`) et déjà découpée à sa silhouette : `tools/node_icons.py`.
@export var icon: Texture2D

## En cases autour de la compétence, qui tient `(0, 0)` : un réseau, pas des colonnes
## (jalon 34, Last Epoch). Pas en pixels.
@export var position: Vector2i = Vector2i.ZERO

## Les nœuds reliés en amont, avec les points que chacun doit porter : **un seul**
## suffit à ouvrir celui-ci. Vide : relié à la compétence, qui demande un point.
@export var parents: Dictionary[String, int] = {}
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

## L'affranchissement (jalon 36) : le geste n'enferme plus son lanceur, et sa recharge
## est fixée à `SkillStats.FREED_RECHARGE` — l'Armure de givre. Un buff ne se transforme
## pas (`Skill.TRANSFORMABLE`), d'où un drapeau à part.
@export var frees := false


func displayed_name() -> String:
	return Texts.t(name)


## Les sortes d'un nœud qui change le jeu plutôt qu'un nombre, **clés de traduction**.
const KINDS := ["transformation", "conversion", "mécanique"]


## Sa sorte, ou vide pour un nœud de nombres.
func kind() -> String:
	if transforms:
		return KINDS[0]
	if converts:
		return KINDS[1]
	if frees:
		return KINDS[2]
	for line in lines:
		if line.stat in SkillStats.MECHANICS:
			return KINDS[2]
	return ""


func displayed_description() -> String:
	return Texts.t(description).format(SkillStats.facts()) if not description.is_empty() else ""


## Sous la forme que la résolution et l'affichage connaissent déjà.
func mods(points: int) -> Array[StatMod]:
	return TalentLine.modifiers(lines, points)
