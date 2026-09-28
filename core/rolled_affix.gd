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
static func orphan(p_mod: StatMod) -> RolledAffix:
	return RolledAffix.new("", 0, p_mod)


## « T4  (45–58) », ou vide sans provenance : jamais un palier déduit de la valeur,
## les fourchettes voisines se chevauchent.
func tier_and_span() -> String:
	var origin := definition()
	return "" if origin == null else "T%d  (%s)" % [tier, origin.span(tier - 1)]


func known() -> bool:
	return tier > 0 and not affix_id.is_empty()


## L'affixe d'origine, **si son palier existe encore** ; null sinon. L'infobulle et la
## pièce de diamant posaient chacune la question.
func definition() -> ItemAffix:
	if not known():
		return null
	var origin := ItemAffixPool.by_id(affix_id)
	return origin if origin != null and tier <= origin.tiers.size() else null
