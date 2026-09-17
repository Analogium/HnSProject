class_name Item
extends RefCounted

## Un exemplaire d'objet : une base partagée et ses propres affixes — sans lui, écrire
## un affixe l'écrirait dans le `.tres`. RefCounted : la sauvegarde en fait un
## dictionnaire.

enum Rarity { COMMON, MAGIC, RARE }

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
var manual: Manual


## Des RolledAffix, ou des StatMod qui deviennent des affixes sans provenance.
func _init(p_base: ItemBase, p_explicits: Array = [], p_level: int = 1) -> void:
	base = p_base
	explicits = []
	for e in p_explicits:
		explicits.append(e if e is RolledAffix else RolledAffix.orphan(e))
	item_level = maxi(p_level, 1)
	# Créé ici plutôt qu'au premier point : pas de « si null » chez les lecteurs.
	if base != null and base.manual != null:
		manual = Manual.new()


## **Déduite** du nombre d'affixes : un objet doré sans affixe serait un mensonge.
func rarity() -> Rarity:
	# Un manuel n'a pas d'affixes : sa rareté est celle de son palier.
	if manual != null:
		if base.tier <= 1:
			return Rarity.COMMON
		return Rarity.MAGIC if base.tier == 2 else Rarity.RARE
	if explicits.is_empty():
		return Rarity.COMMON
	if explicits.size() <= 2:
		return Rarity.MAGIC
	return Rarity.RARE


func color() -> Color:
	return RARITY_COLORS[rarity()]


## Le nom lu par le joueur ; tout affichage passe par ici, pas par `base.display_name`.
func display_name() -> String:
	return Texts.t(base.display_name)


## Faux pour tout ce qui n'est pas un manuel. La seule réponse, pour le joueur comme
## pour la relecture d'une sauvegarde.
func teaches(skill_id: String) -> bool:
	if base == null or base.manual == null:
		return false
	return base.manual.cell_of(skill_id) != null


## Case, passif ou nœud confondus : la question de la relecture d'une sauvegarde.
func knows(identifier: String) -> bool:
	if base == null or base.manual == null:
		return false
	return base.manual.knows(identifier)


## Vide hors manuel, ou pour une compétence que ce livre n'enseigne pas.
func invested_talents(skill_id: String) -> Array[InvestedTalent]:
	if manual == null or base.manual == null:
		return [] as Array[InvestedTalent]
	return manual.invested_talents(base.manual, skill_id)


## Ce que les passifs de ce livre donnent au personnage qui l'étudie.
func passive_mods() -> Array[StatMod]:
	if manual == null or base.manual == null:
		return [] as Array[StatMod]
	return manual.passive_mods(base.manual)


## Tout ce que l'objet donne, implicite compris : c'est cette liste que le calcul
## des statistiques du joueur consomme. Les lignes locales n'y sont que par la
## chance critique de l'arme, qui les contient.
func mods() -> Array[StatMod]:
	var all: Array[StatMod] = []
	var imp := base.implicit()
	if imp != null:
		all.append(imp)
	for r in explicits:
		if not base.is_local(r.mod):
			all.append(r.mod)
	if base.family == ItemBase.WEAPON_FAMILY:
		all.append(StatMod.new(SkillStats.CRIT_CHANCE, StatMod.Mode.FLAT, crit_chance()))
	return all


## Celle de la base, plus ses plats locaux, fois ses accrus locaux.
func crit_chance() -> float:
	var flat := base.crit_chance
	var increased := 0.0
	for r in explicits:
		if not base.is_local(r.mod):
			continue
		if r.mod.mode == StatMod.Mode.FLAT:
			flat += r.mod.value
		else:
			increased += r.mod.value
	return maxf(flat * (1.0 + increased * 0.01), 0.0)


## L'implicite, à part et en premier : ce que la base garantit.
func implicit_line() -> String:
	var imp := base.implicit()
	return "" if imp == null else imp.label()


## Sous l'implicite, vide hors des armes.
func crit_line() -> String:
	if base.family != ItemBase.WEAPON_FAMILY:
		return ""
	return Texts.t("Chance critique de base : %s") % StatMod.format(SkillStats.CRIT_CHANCE, crit_chance())


## Une ligne tirée telle que l'infobulle l'écrit.
func explicit_line(r: RolledAffix) -> String:
	return r.mod.label() + (Texts.t(" (local)") if base.is_local(r.mod) else "")
