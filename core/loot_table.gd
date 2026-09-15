class_name LootTable

## Ce qui tombe d'un ennemi. Sur `Game.rng` et non sur le tirage de zone : le butin
## récompense une action, pas un lieu — sinon recharger garantirait une chute.

## La chance de base : c'est la grappe qui récompense, pas la centième mise à mort.
const BASE_CHANCE := 0.20

## Multiplicatif par affixe : deux affixes, 24 % au lieu de 20 %. Modeste, l'élite
## rapportant surtout son expérience.
const QUANTITY_PER_AFFIX := 0.10


static func quantity_for(affix_count: int) -> float:
	return 1.0 + QUANTITY_PER_AFFIX * float(affix_count)


## Null quand rien ne tombe. Un exemplaire neuf, au niveau de la zone.
static func roll(affix_count: int, niveau: int) -> Item:
	var bases := ItemCatalog.disponibles(niveau)
	if bases.is_empty():
		return null
	if Game.rng.randf() >= BASE_CHANCE * quantity_for(affix_count):
		return null
	var base: ItemBase = bases[Game.rng.randi() % bases.size()]
	return Item.new(base, ItemAffixPool.roll(Game.rng, base, niveau), niveau)
