class_name LootTable

## Ce qui tombe d'un ennemi. Sur `Game.rng` et non sur le tirage de zone : le butin
## récompense une action, pas un lieu — sinon recharger garantirait une chute.

## La chance de base : c'est la grappe qui récompense, pas la centième mise à mort.
const BASE_CHANCE := 0.20

## Multiplicatif par affixe : deux affixes, 24 % au lieu de 20 %. Modeste, l'élite
## rapportant surtout son expérience.
const QUANTITY_PER_AFFIX := 0.10

## Par niveau de zone au-delà du premier, multiplié aux affixes : le butin grossit à
## mesure qu'on avance — ×2,19 au niveau 120. Provisoire, comme toute la table.
const QUANTITY_PER_LEVEL := 0.01


static func quantity_for(affix_count: int, level: int) -> float:
	return (1.0 + QUANTITY_PER_AFFIX * float(affix_count)) \
		* (1.0 + QUANTITY_PER_LEVEL * float(maxi(level - 1, 0)))


## La part des chutes qui est une pièce de monnaie plutôt qu'un objet. Provisoire.
const CURRENCY_SHARE := 0.25


## Null quand rien ne tombe. Un exemplaire neuf, au niveau de la zone.
static func roll(affix_count: int, level: int) -> Item:
	var bases := ItemCatalog.available(level)
	if bases.is_empty():
		return null
	# Ce que les pièces rares gagnent en profondeur s'ajoute aux chutes au lieu de
	# prendre la place des objets et des pièces communes. Au niveau 1, `pool` vaut 1.
	var coins := CURRENCY_SHARE * Currency.weight_ratio(level)
	var pool := 1.0 - CURRENCY_SHARE + coins
	if Game.rng.randf() >= BASE_CHANCE * quantity_for(affix_count, level) * pool:
		return null
	if Game.rng.randf() * pool < coins:
		return Item.new(Currency.roll(Game.rng, level), [], level)
	var base: ItemBase = bases[Game.rng.randi() % bases.size()]
	return Item.rolled(Game.rng, base, level)
