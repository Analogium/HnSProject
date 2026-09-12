class_name TalentInvesti
extends RefCounted

## Un nœud d'arbre et ce qu'on y a placé. Le nœud vient du `.tres` partagé, les
## points de l'exemplaire de manuel : il n'existe pas d'endroit où les deux
## soient déjà ensemble, et c'est la résolution d'un lancer qui a besoin des
## deux.
##
## Une petite classe aux deux champs nommés plutôt qu'un tableau de paires : la
## résolution en parcourt une liste à chaque lancer, et `t[0]` obligerait à se
## souvenir duquel des deux il s'agit.

var noeud: NoeudDeTalent
var points: int


func _init(p_noeud: NoeudDeTalent, p_points: int) -> void:
	noeud = p_noeud
	points = p_points


func mods() -> Array[StatMod]:
	return noeud.mods(points)


func conversion() -> float:
	return noeud.conversion(points)
