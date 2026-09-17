class_name ItemAffixPool

## Le tirage des affixes d'un objet. Rien de commun avec AffixPool, les affixes
## d'ennemis.

const ALL := [
	preload("res://resources/item_affixes/vigorous.tres"),
	preload("res://resources/item_affixes/sturdy.tres"),
	preload("res://resources/item_affixes/nimble.tres"),
	preload("res://resources/item_affixes/quick.tres"),
	preload("res://resources/item_affixes/cruel.tres"),
	preload("res://resources/item_affixes/precise.tres"),
	preload("res://resources/item_affixes/keen.tres"),
	preload("res://resources/item_affixes/bloody.tres"),
	preload("res://resources/item_affixes/far_reaching.tres"),
	preload("res://resources/item_affixes/cuirassed.tres"),

	# Défenses élémentaires, réserve, incantation et attributs.
	preload("res://resources/item_affixes/frosted.tres"),
	preload("res://resources/item_affixes/fireproof.tres"),
	preload("res://resources/item_affixes/insulated.tres"),
	preload("res://resources/item_affixes/embalmed.tres"),
	preload("res://resources/item_affixes/unholy.tres"),
	preload("res://resources/item_affixes/elusive.tres"),
	preload("res://resources/item_affixes/plated.tres"),
	preload("res://resources/item_affixes/regenerating.tres"),
	preload("res://resources/item_affixes/shrewd.tres"),
	preload("res://resources/item_affixes/lucid.tres"),
	preload("res://resources/item_affixes/incanting.tres"),
	preload("res://resources/item_affixes/muscular.tres"),
	preload("res://resources/item_affixes/agile.tres"),
	preload("res://resources/item_affixes/erudite.tres"),

	# Ceux qui visent un mot-clé : ils rendent vrais les mots-clés affichés.
	preload("res://resources/item_affixes/forked.tres"),
	preload("res://resources/item_affixes/whistling.tres"),
	preload("res://resources/item_affixes/stormy.tres"),
	# Le pendant d'`stormy` pour le feu.
	preload("res://resources/item_affixes/ardent.tres"),
	preload("res://resources/item_affixes/bewitched.tres"),

	# Les dégâts ajoutés, chaque nature aux attaques puis aux sorts, sur une échelle
	# commune ; chaque famille pèse ce que pesait l'affixe qu'elle remplace.
	preload("res://resources/item_affixes/physical_to_attacks.tres"),
	preload("res://resources/item_affixes/cold_to_attacks.tres"),
	preload("res://resources/item_affixes/fire_to_attacks.tres"),
	preload("res://resources/item_affixes/lightning_to_attacks.tres"),
	preload("res://resources/item_affixes/necrotic_to_attacks.tres"),
	preload("res://resources/item_affixes/holy_to_attacks.tres"),
	preload("res://resources/item_affixes/physical_to_spells.tres"),
	preload("res://resources/item_affixes/cold_to_spells.tres"),
	preload("res://resources/item_affixes/fire_to_spells.tres"),
	preload("res://resources/item_affixes/lightning_to_spells.tres"),
	preload("res://resources/item_affixes/necrotic_to_spells.tres"),
	preload("res://resources/item_affixes/holy_to_spells.tres"),

	# Jalon 14 : les niveaux de compétence, rares, et les dégâts contre un état.
	preload("res://resources/item_affixes/fire_skill_levels.tres"),
	preload("res://resources/item_affixes/lightning_skill_levels.tres"),
	preload("res://resources/item_affixes/scorching.tres"),
	preload("res://resources/item_affixes/electrocuting.tres"),
	preload("res://resources/item_affixes/shattering.tres"),
	preload("res://resources/item_affixes/butchering.tres"),

	# Les deux portées du jalon 19 : sans elles, « Mêlée » et « Zone » s'afficheraient
	# sur des compétences sans que rien ne les vise (`test_each_keyword_is_targeted…`).
	preload("res://resources/item_affixes/crushing.tres"),
	preload("res://resources/item_affixes/expansive.tres"),
]

## Poids du nombre d'affixes, de 0 à 6 : un objet sur deux sort nu, six affixes
## restent une histoire. La réserve compatible borne le maximum réel.
const COUNT_WEIGHTS := [46, 24, 14, 8, 5, 2, 1]


## Null pour un affixe retiré du projet : sa valeur s'applique, son palier ne
## s'affiche plus.
static func by_id(id: String) -> ItemAffix:
	for a in ALL:
		if a.id == id:
			return a
	return null


## Tout ce que cette base peut porter un jour, quel que soit son niveau (la forge) ;
## `eligible` dit ce qu'elle reçoit maintenant (le tirage). Le filtre n'est qu'ici.
static func compatibles(base: ItemBase) -> Array:
	# Ce qui ne se porte pas ne reçoit rien, pas même les affixes universels. Ici et non
	# en `excludes` sur chaque affixe, que le prochain oublierait.
	if base == null or not EquipmentSlots.equippable_family(base.family):
		return []
	var out := []
	for a in ALL:
		if a.fits(base):
			out.append(a)
	return out


## Ce qui peut sortir à ce niveau : un affixe sans palier ouvert n'est pas dans la
## réserve.
static func eligible(base: ItemBase, level: int) -> Array:
	var out := []
	for a in compatibles(base):
		if not a.unlocked_tiers(level).is_empty():
			out.append(a)
	return out


## Borné par la réserve disponible : pas de lignes vides.
static func roll_count(rng: RandomNumberGenerator, available: int) -> int:
	var i := WeightedRoll.weighted(rng, COUNT_WEIGHTS)
	return 0 if i < 0 else mini(i, available)


## Tirés distincts : deux fois « acéré » se lirait comme un bug.
static func roll(rng: RandomNumberGenerator, base: ItemBase, level: int) -> Array[RolledAffix]:
	var results: Array[RolledAffix] = []
	var rest := eligible(base, level)
	for i in roll_count(rng, rest.size()):
		var selected := _pick(rng, rest)
		if selected == null:
			break
		rest.erase(selected)
		var rolled := selected.roll(rng, level)
		# `eligible` a déjà écarté les affixes sans palier ; ignorer null reste plus sûr.
		if rolled != null:
			results.append(rolled)
	return results


## Poids relevés à chaque appel : retirer un affixe tiré change les suivants.
static func _pick(rng: RandomNumberGenerator, pool: Array) -> ItemAffix:
	var weights := []
	for a in pool:
		weights.append(a.weight)
	var i := WeightedRoll.weighted(rng, weights)
	return null if i < 0 else pool[i]
