class_name Affix
extends Resource

## Un modificateur porté par un ennemi, et la couleur par laquelle il s'annonce.
##
## Une Resource comme CharacterStats, pour la même raison : un `.tres` par
## affixe, éditable dans l'inspecteur, et en ajouter un ne demande pas de code.
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
## Retranché à chaque coup reçu, en points. Fixe et non proportionnel : c'est ce
## qui rend les petits coups répétés inefficaces contre lui, donc ce qui change
## la façon de l'attaquer plutôt que la durée du combat.
@export var damage_reduction: float = 0.0
## Fraction des dégâts infligés reconvertie en soin.
@export var lifesteal: float = 0.0

@export_group("Récompense")
@export var xp_mult: float = 1.5
