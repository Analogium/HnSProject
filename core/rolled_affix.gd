class_name RolledAffix
extends RefCounted

## Un affixe tel qu'un objet le porte : d'où il vient, à quel palier, et la
## valeur qui en est sortie.
##
## Avant lui, `Item.explicits` était une liste de StatMod — une statistique, un
## mode, une valeur. **De quel affixe cette valeur venait-elle, et de quel
## palier ?** Rien ne le disait, et l'infobulle des tiers ne peut pas l'inventer :
## deux paliers voisins se chevauchent, une déduction depuis la valeur serait
## fausse une fois sur trois.
##
## Le StatMod reste ce que le calcul des statistiques consomme. C'est
## l'infobulle, et elle seule, qui a besoin de la provenance — d'où une coquille
## autour du modificateur plutôt qu'un champ de plus dans StatMod, que le calcul
## des stats du joueur et les implicites de bases traînent pour rien.

## L'identifiant de l'ItemAffix d'origine. Vide quand on ne sait pas : c'est le
## cas des objets d'une sauvegarde de version 1, qui n'écrivait pas la
## provenance.
var affix_id: String
## Le palier, **1 étant le meilleur**. Zéro quand la provenance est inconnue —
## jamais un palier deviné.
var tier: int
var mod: StatMod


func _init(p_affix_id: String, p_tier: int, p_mod: StatMod) -> void:
	affix_id = p_affix_id
	tier = p_tier
	mod = p_mod


## Un modificateur sans provenance : un objet d'avant les paliers, ou un objet
## fabriqué à la main dans un test. Il s'applique exactement comme les autres, il
## n'a simplement rien à dire sur son tirage.
static func orphelin(p_mod: StatMod) -> RolledAffix:
	return RolledAffix.new("", 0, p_mod)


## Vrai quand on sait d'où vient cette ligne. L'infobulle s'en sert pour montrer
## un palier ou n'en montrer aucun — pas de colonne vaut mieux qu'une colonne
## fausse.
func connu() -> bool:
	return tier > 0 and not affix_id.is_empty()
