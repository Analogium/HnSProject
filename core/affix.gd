class_name Affix
extends Resource

## Un modificateur porté par un ennemi, et la couleur par laquelle il s'annonce.
## Un `.tres` par affixe, éditable dans l'inspecteur.
##
## Chaque affixe a une contrepartie. Un affixe sans contrepartie n'est pas un
## affixe, c'est une barre de vie plus longue.

@export var id: String = ""
@export var display_name: String = ""

## La teinte appliquée au sprite. C'est le seul canal par lequel le joueur
## apprend l'affixe : elle doit être franche, et unique dans le lot.
@export var tint: Color = Color.WHITE

@export_group("Multiplicateurs")
@export var health_mult: float = 1.0
@export var speed_mult: float = 1.0
@export var damage_mult: float = 1.0
@export var cooldown_mult: float = 1.0

@export_group("Effets")
## Ajouté à la notation d'armure. Elle protège proportionnellement plus des
## petits coups que des gros : c'est ce qui rend le harcèlement inefficace contre
## lui, donc ce qui change la façon de l'attaquer plutôt que la durée du combat.
## Et comme l'armure ne couvre que le physique, un tir élémentaire reste le
## recours — voir CharacterStats.armor_reduction.
@export var armor: float = 0.0
## Fraction des dégâts infligés reconvertie en soin.
@export var lifesteal: float = 0.0

@export_group("Récompense")
@export var xp_mult: float = 1.5
