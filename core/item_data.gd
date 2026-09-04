class_name ItemData
extends Resource

## Un objet ramassable. Une Resource comme CharacterStats et Affix : un `.tres`
## par objet, éditable dans l'inspecteur, et en ajouter un ne demande pas de code.
##
## Volontairement nu pour l'instant : ni bonus, ni rareté qui compte. C'est la
## boucle « ça tombe, je le ramasse » qu'on valide d'abord ; les modificateurs
## viendront s'ajouter ici sans rien déplacer.

@export var display_name: String = ""

## Ce que l'objet est, au sens de SpriteForge : "sword", "wand", "torso"…
## C'est lui qui décide du dessin de l'icône — pour une arme, c'est exactement
## la fonction qui la pose dans la main d'un personnage, donc l'icône et l'arme
## portée ne peuvent pas diverger.
@export var kind: String = "sword"

## Emplacement d'équipement. Vide pour un objet qui ne s'équipe pas.
@export var slot: String = "weapon"

## Encombrement dans le sac, en cases : colonnes × lignes. C'est la règle de
## Path of Exile et de Hero Siege — une épée mange une colonne sur trois lignes,
## un plastron deux sur trois. Le sac ne compte donc pas les objets mais la
## place, et un gros butin coûte quelque chose même quand on a de la marge.
##
## Vector2i et non deux entiers : c'est un couple qu'on lit, teste et décale
## toujours d'un bloc.
@export var grid_size: Vector2i = Vector2i(1, 1)
