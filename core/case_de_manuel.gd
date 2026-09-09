class_name CaseDeManuel
extends Resource

## Une case de la page d'un manuel : une compétence, et l'endroit où elle est
## posée.
##
## La position est ici et non sur la compétence : une compétence est ce qu'elle
## fait, pas l'endroit où on la trouve. Le jour où deux manuels partageront un
## sort, chacun le posera où il veut sans que l'autre ait son mot à dire.

@export var competence: Competence
## En cases de la grille de la page, pas en pixels : la page se redessine à une
## autre taille sans qu'aucun `.tres` ne bouge.
@export var position: Vector2i = Vector2i.ZERO
