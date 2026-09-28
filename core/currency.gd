class_name Currency

## Les pièces de monnaie (jalon 29) : un objet d'une case qu'on applique à un autre.
## **Ce que fait chaque pièce n'est écrit qu'ici** ; sa base (`resources/items/coin_*.tres`)
## ne porte que son nom et son image, et se retrouve par son identifiant.

const COPPER := "coin_copper"
const BRONZE := "coin_bronze"
const SILVER := "coin_silver"
const GOLD := "coin_gold"
const PLATINUM := "coin_platinum"
const DIAMOND := "coin_diamond"

## Du plus commun au plus rare. Provisoire : l'équilibrage se fait en dernier.
const DROP_WEIGHTS := {
	COPPER: 100, BRONZE: 50, SILVER: 20, GOLD: 8, PLATINUM: 4, DIAMOND: 1,
}

## Ce que le poids d'une pièce gagne par niveau de zone au-delà du premier, comme dans
## PoE : les rares seules, d'autant plus qu'elles le sont — le diamant ×5,76 au 120.
## Ce gain s'ajoute aux chutes (`LootTable.roll()`) : le cuivre ne tombe pas moins.
const GROWTH_PER_LEVEL := {SILVER: 0.01, GOLD: 0.02, PLATINUM: 0.03, DIAMOND: 0.04}


static func is_coin(item: Item) -> bool:
	return item != null and item.base.family == ItemBase.CURRENCY_FAMILY


## En centièmes : entiers pour `WeightedRoll`, sans que l'arrondi mange la pente du
## diamant. Dans l'ordre de `DROP_WEIGHTS`.
static func drop_weights(level: int) -> Array:
	var depth := float(maxi(level - 1, 0))
	var out := []
	for id in DROP_WEIGHTS:
		out.append(roundi(100.0 * DROP_WEIGHTS[id] * (1.0 + GROWTH_PER_LEVEL.get(id, 0.0) * depth)))
	return out


## Combien les pièces pèsent à ce niveau face au niveau 1 : ce que la zone ajoute.
static func weight_ratio(level: int) -> float:
	var total := func(w: Array) -> float: return float(w.reduce(func(a, b): return a + b, 0))
	return total.call(drop_weights(level)) / total.call(drop_weights(1))


## La base d'une pièce qui tombe, sur le fil du butin.
static func roll(rng: RandomNumberGenerator, level: int) -> ItemBase:
	var ids := DROP_WEIGHTS.keys()
	return ItemCatalog.by_id(ids[WeightedRoll.weighted(rng, drop_weights(level))])


## Ce que la pièce fait, pour l'infobulle.
static func effect(coin: ItemBase) -> String:
	match coin.id:
		COPPER: return Texts.t("Rend magique un objet normal")
		BRONZE: return Texts.t("Change les affixes d'un objet magique")
		SILVER: return Texts.t("Rend rare un objet magique")
		GOLD: return Texts.t("Change les affixes d'un objet rare")
		PLATINUM: return Texts.t("Ajoute un affixe à un objet rare")
		DIAMOND: return Texts.t("Change les valeurs des affixes d'un objet")
	return ""


## Vrai si cette pièce peut s'appliquer à cet objet : la surbrillance du sac et le
## refus d'`apply()` passent ici. Faux pour ce qui ne porte pas d'affixes.
static func accepts(coin: ItemBase, target: Item) -> bool:
	if target == null or is_coin(target):
		return false
	var pool := ItemAffixPool.eligible(target.base, target.item_level)
	if pool.is_empty():
		return false
	var count := target.explicits.size()
	var rarity := target.rarity()
	match coin.id:
		COPPER:
			return count == 0
		BRONZE:
			return rarity == Item.Rarity.MAGIC
		SILVER:
			return (
				rarity == Item.Rarity.MAGIC and ItemAffixPool.max_count(target.base) > Item.MAGIC_MAX
				and not _free(target).is_empty()
			)
		GOLD:
			return rarity == Item.Rarity.RARE and pool.size() > Item.MAGIC_MAX
		PLATINUM:
			return (
				rarity == Item.Rarity.RARE and count < ItemAffixPool.MAX_COUNT
				and not _free(target).is_empty()
			)
		DIAMOND:
			for r in target.explicits:
				if r.definition() != null:
					return true
	return false


## Faux, et l'objet intact, quand la pièce ne s'y applique pas.
static func apply(coin: ItemBase, target: Item, rng: RandomNumberGenerator) -> bool:
	if not accepts(coin, target):
		return false
	var level := target.item_level
	match coin.id:
		COPPER, SILVER, PLATINUM:
			target.explicits.append_array(ItemAffixPool.draw(rng, _free(target), 1, level))
			if coin.id == SILVER:
				target.rare = true
		BRONZE:
			_reroll(target, rng, 1, Item.MAGIC_MAX)
		GOLD:
			_reroll(target, rng, Item.MAGIC_MAX + 1, ItemAffixPool.MAX_COUNT)
		DIAMOND:
			for i in target.explicits.size():
				var definition := target.explicits[i].definition()
				# Sans provenance, on ne sait pas dans quel palier tirer : la ligne reste.
				if definition != null:
					target.explicits[i] = definition.roll_tier(rng, target.explicits[i].tier - 1)
	return true


## Ce que l'objet peut encore recevoir : l'éligible moins ce qu'il porte déjà.
static func _free(target: Item) -> Array:
	var rest := ItemAffixPool.eligible(target.base, target.item_level)
	for r in target.explicits:
		rest.erase(ItemAffixPool.by_id(r.affix_id))
	return rest


## Tout est retiré puis retiré au sort, le nombre borné à la rareté de départ.
static func _reroll(target: Item, rng: RandomNumberGenerator, low: int, high: int) -> void:
	var pool := ItemAffixPool.eligible(target.base, target.item_level)
	var count := ItemAffixPool.roll_count(rng, pool.size(), low, high)
	target.explicits = ItemAffixPool.draw(rng, pool, count, target.item_level)
