class_name Item
extends RefCounted

## Un exemplaire d'objet : une base partagée et ses propres affixes — sans lui, écrire
## un affixe l'écrirait dans le `.tres`. RefCounted : la sauvegarde en fait un
## dictionnaire.

enum Rarity { COMMUN, MAGIQUE, RARE }

## Blanc, bleu, or — l'or veut dire partout « ça compte plus ».
const RARITY_COLORS := [
	Color(0.85, 0.85, 0.88),
	Color(0.42, 0.62, 0.98),
	Color(0.95, 0.82, 0.30),
]

var base: ItemBase
## Les affixes tirés à la création, déjà résolus en valeurs, **et leur
## provenance**. Ils ne changent plus ensuite — un objet est ce qu'il est.
var explicits: Array[RolledAffix] = []

## Le niveau de la zone où il est tombé, posé une fois : il décide des paliers
## d'affixes. Pas celui du personnage — le butin s'améliore en allant au danger, pas
## en jouant longtemps. 1 par défaut (tests, sauvegardes v1).
var item_level: int = 1

## L'état du manuel quand l'objet en est un, sur l'exemplaire et **jamais sur
## l'archétype** (invariant 2).
var manuel: Manuel


## Des RolledAffix, ou des StatMod qui deviennent des affixes sans provenance.
func _init(p_base: ItemBase, p_explicits: Array = [], p_level: int = 1) -> void:
	base = p_base
	explicits = []
	for e in p_explicits:
		explicits.append(e if e is RolledAffix else RolledAffix.orphelin(e))
	item_level = maxi(p_level, 1)
	# Créé ici plutôt qu'au premier point : pas de « si null » chez les lecteurs.
	if base != null and base.manuel != null:
		manuel = Manuel.new()


## **Déduite** du nombre d'affixes : un objet doré sans affixe serait un mensonge.
func rarity() -> Rarity:
	# Un manuel n'a pas d'affixes : sa rareté est celle de son palier.
	if manuel != null:
		if base.palier <= 1:
			return Rarity.COMMUN
		return Rarity.MAGIQUE if base.palier == 2 else Rarity.RARE
	if explicits.is_empty():
		return Rarity.COMMUN
	if explicits.size() <= 2:
		return Rarity.MAGIQUE
	return Rarity.RARE


func color() -> Color:
	return RARITY_COLORS[rarity()]


## Le nom lu par le joueur ; tout affichage passe par ici, pas par `base.display_name`.
func display_name() -> String:
	return Textes.t(base.display_name)


## Faux pour tout ce qui n'est pas un manuel. La seule réponse, pour le joueur comme
## pour la relecture d'une sauvegarde.
func enseigne(id_competence: String) -> bool:
	if base == null or base.manuel == null:
		return false
	return base.manuel.case_de(id_competence) != null


## Case, passif ou nœud confondus : la question de la relecture d'une sauvegarde.
func connait(identifiant: String) -> bool:
	if base == null or base.manuel == null:
		return false
	return base.manuel.connait(identifiant)


## Vide hors manuel, ou pour une compétence que ce livre n'enseigne pas.
func talents_investis(id_competence: String) -> Array[TalentInvesti]:
	if manuel == null or base.manuel == null:
		return [] as Array[TalentInvesti]
	return manuel.talents_investis(base.manuel, id_competence)


## Ce que les passifs de ce livre donnent au personnage qui l'étudie.
func mods_de_passifs() -> Array[StatMod]:
	if manuel == null or base.manuel == null:
		return [] as Array[StatMod]
	return manuel.mods_de_passifs(base.manuel)


## Tout ce que l'objet donne, implicite compris : c'est cette liste que le calcul
## des statistiques du joueur consomme.
func mods() -> Array[StatMod]:
	var all: Array[StatMod] = []
	var imp := base.implicit()
	if imp != null:
		all.append(imp)
	for r in explicits:
		all.append(r.mod)
	return all


## L'implicite, à part et en premier : ce que la base garantit.
func implicit_line() -> String:
	var imp := base.implicit()
	return "" if imp == null else imp.label()
