class_name ItemData
extends Resource

## Un objet ramassable. Une Resource comme CharacterStats et Affix : un `.tres`
## par objet, éditable dans l'inspecteur, et en ajouter un ne demande pas de code.
##
## Volontairement nu pour l'instant : ni bonus, ni rareté qui compte. C'est la
## boucle « ça tombe, je le ramasse » qu'on valide d'abord ; les modificateurs
## viendront s'ajouter ici sans rien déplacer.

@export var display_name: String = ""

## Le type d'arme, au sens de SpriteForge : "sword", "wand", "cleaver"…
## C'est lui qui décide du dessin de l'icône — donc l'icône de l'objet et l'arme
## que tient un personnage sortent du même code et ne peuvent pas diverger.
@export var kind: String = "sword"

## Emplacement d'équipement. Vide pour un objet qui ne s'équipe pas.
@export var slot: String = "weapon"
