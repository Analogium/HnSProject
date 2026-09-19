class_name Affix
extends Resource

## Un modificateur d'ennemi et sa couleur. Chaque affixe a une contrepartie, sinon
## c'est une barre de vie plus longue.

@export var id: String = ""
@export var display_name: String = ""

## La teinte appliquée au sprite. C'est le seul canal par lequel le joueur
## apprend l'affixe : elle doit être franche, et unique dans le lot.
@export var tint: Color = Color.WHITE

@export_group("Multipliers")
@export var health_mult: float = 1.0
@export var speed_mult: float = 1.0
@export var damage_mult: float = 1.0
@export var attack_time_mult: float = 1.0

@export_group("Effects")
## Ajouté à la notation d'armure : rend le harcèlement inefficace, et le tir
## élémentaire reste le recours.
@export var armor: float = 0.0
## Fraction des dégâts infligés reconvertie en soin.
@export var lifesteal: float = 0.0

@export_group("Récompense")
@export var xp_mult: float = 1.5


## `display_name` est la clé française.
func displayed_name() -> String:
	return Texts.t(display_name)
