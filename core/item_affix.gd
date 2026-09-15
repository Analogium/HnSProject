class_name ItemAffix
extends Resource

## La *définition* d'un affixe : statistique et échelle de paliers ; le tirage donne
## un RolledAffix. Des fourchettes : c'est ce qui fait comparer deux épées « acérées ».

@export var id: String = ""

## Les étiquettes qu'une base doit porter, **une seule suffit** (voir `ItemBase.tags`).
## Vide = partout, sous réserve d'`excludes`.
@export var tags: PackedStringArray = PackedStringArray()

## Les étiquettes qui interdisent, et qui **l'emportent** : « partout sauf les armes »,
## dont une base ajoutée plus tard hérite sans qu'on y pense.
@export var excludes: PackedStringArray = PackedStringArray()

## Sans portée, un champ de CharacterStats (dans StatMod.LABELS) ; avec, un nombre de
## StatsDeCompetence.
@export var stat: String = "attack_damage"

## Le mot-clé visé, ou vide pour la fiche (voir `StatMod.scope`).
@export var scope: String = ""

## Pourcentage plutôt que valeur absolue.
@export var percent: bool = false

## Les paliers, **du meilleur au pire** : le premier est le T1, le numéro est une
## position.
@export var tiers: Array[ItemAffixTier] = []

## Le pas d'arrondi : 1 pour un entier, 0.01 pour une fraction. Un champ et non une
## déduction, pour que tous les paliers s'arrondissent pareil.
@export var rounded: float = 1.0

## Poids dans la réserve.
@export var weight: int = 10


## `excludes` d'abord : il l'emporte sur `tags`.
func fits(base: ItemBase) -> bool:
	if base == null:
		return false
	for t in excludes:
		if base.tags.has(t):
			return false
	if tags.is_empty():
		return true
	for t in tags:
		if base.tags.has(t):
			return true
	return false


## Combien de paliers restent ouverts : le meilleur atteint et les trois du dessous.
## **Une fenêtre et non un plafond** : un objet de niveau 60 ne sort plus le T8, et une
## bonne sortie reste une bonne nouvelle sans être garantie.
const OPEN_TIERS := 4


## Les indices des paliers ouverts à ce niveau, du meilleur au pire.
func unlocked_tiers(level: int) -> Array:
	var out := []
	for i in tiers.size():
		if tiers[i].required_level > level:
			continue
		out.append(i)
		if out.size() >= OPEN_TIERS:
			break
	return out


## L'union des fenêtres entre deux niveaux : ce qu'une base peut réellement sortir sur
## sa fenêtre de chute. Vaut pour ce qui tombe.
func open_between(first: int, last: int) -> Array:
	var seen_all := {}
	for level in range(maxi(first, 1), maxi(last, first) + 1):
		for i in unlocked_tiers(level):
			seen_all[i] = true
	var out := seen_all.keys()
	# Du meilleur au pire, comme `tiers` : l'ordre dans lequel la fiche les lit.
	out.sort()
	return out


## Entre quels niveaux ce palier sort, **dans la plage demandée** — (0, 0) sinon. La
## réponse vient de `unlocked_tiers` : la forge ne peut pas annoncer ce que le tirage refuse.
func tier_window(index: int, first: int, last: int) -> Vector2i:
	var start := 0
	var end := 0
	for level in range(maxi(first, 1), maxi(last, first) + 1):
		if not unlocked_tiers(level).has(index):
			continue
		if start == 0:
			start = level
		end = level
	return Vector2i(start, end)


## Le niveau à partir duquel cet affixe existe. Rien à voir avec son meilleur
## palier : c'est le plus bas de l'échelle, et il doit valoir 1.
func minimum_level() -> int:
	var mini := 0
	for t in tiers:
		if mini == 0 or t.required_level < mini:
			mini = t.required_level
	return mini


## Un exemplaire pour un objet de ce niveau, ou null si aucun palier n'est ouvert.
func roll(rng: RandomNumberGenerator, level: int) -> RolledAffix:
	var index := _pick_tier(rng, level)
	if index < 0:
		return null
	var tier: ItemAffixTier = tiers[index]
	var v := snappedf(rng.randf_range(tier.min_value, tier.max_value), rounded)
	# Un tirage de plus pour la borne haute d'une fourchette. Le compte dépend de
	# l'affixe, jamais de ce qui sort (invariant 3).
	var top := v
	if is_a_range():
		top = snappedf(rng.randf_range(tier.min_top, tier.max_top), rounded)
	return RolledAffix.new(id, index + 1, modifier(v, top))


## Deux nombres par palier ; déduit de la statistique, jamais saisi.
func is_a_range() -> bool:
	return StatMod.ranged_stat(stat)


## Le tirage et l'établi passent par ici : une portée oubliée d'un côté ferait une
## ligne de fiche qui vise un champ inconnu.
func modifier(value: float, value_max := 0.0) -> StatMod:
	return StatMod.from_definition(stat, percent, value, value_max, scope)


## Le haut de chaque fourchette, arrondi comme le tirage : l'établi pose un réglage
## reproductible.
func at_top(index: int) -> StatMod:
	var tier: ItemAffixTier = tiers[index]
	return modifier(snappedf(tier.max_value, rounded), snappedf(tier.max_top, rounded))


## « 45–58 », « 8–11 % », « 3–4 à 7–9 » : forge, catalogue et infobulle passent ici.
func span(index: int) -> String:
	var tier: ItemAffixTier = tiers[index]
	var mode := StatMod.Mode.PERCENT if percent else StatMod.Mode.FLAT
	var low := StatMod.range_label(stat, mode, tier.min_value, tier.max_value)
	if not is_a_range():
		return low
	return "%s à %s" % [low, StatMod.range_label(stat, mode, tier.min_top, tier.max_top)]


## Tirage pondéré parmi les paliers ouverts. `unlocked_tiers` n'est appelé qu'une fois :
## les poids et la descente doivent porter sur la même liste, dans le même ordre.
func _pick_tier(rng: RandomNumberGenerator, level: int) -> int:
	var open_tiers := unlocked_tiers(level)
	var weights := []
	for i in open_tiers:
		weights.append(tiers[i].weight)
	var selected := WeightedRoll.weighted(rng, weights)
	return -1 if selected < 0 else open_tiers[selected]
