class_name RolledAffix
extends RefCounted

## Un affixe tel qu'un objet le porte : provenance, palier, valeur. Une coquille
## autour du StatMod : seule l'infobulle a besoin de la provenance.

## L'ItemAffix d'origine, vide quand on ne sait pas (sauvegardes v1).
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
## fabriqué à la main dans un test. Il s'applique exactement comme les autres.
static func orphelin(p_mod: StatMod) -> RolledAffix:
	return RolledAffix.new("", 0, p_mod)


## « T4  (45–58) », ou vide sans provenance : jamais un palier déduit de la valeur,
## les fourchettes voisines se chevauchent.
func palier_et_plage() -> String:
	if not connu():
		return ""
	var definition := ItemAffixPool.by_id(affix_id)
	if definition == null or tier > definition.tiers.size():
		return ""
	return "T%d  (%s)" % [tier, definition.plage(tier - 1)]


func connu() -> bool:
	return tier > 0 and not affix_id.is_empty()
