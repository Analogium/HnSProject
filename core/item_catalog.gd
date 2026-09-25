class_name ItemCatalog

## Toutes les bases d'objets, **le seul endroit où elles sont listées** : butin et
## sauvegarde y puisent. Un test refuse un identifiant vide ou en double.

## Par lignée, puis par palier croissant : un palier manquant se voit sans compter.
const ALL := [
	# lame
	preload("res://resources/items/sword.tres"),
	preload("res://resources/items/broadsword.tres"),
	preload("res://resources/items/war_blade.tres"),
	# dague
	preload("res://resources/items/dagger.tres"),
	preload("res://resources/items/misericorde.tres"),
	# contondante
	preload("res://resources/items/mace.tres"),
	preload("res://resources/items/battle_mace.tres"),
	preload("res://resources/items/war_hammer.tres"),
	# focus
	preload("res://resources/items/wand.tres"),
	preload("res://resources/items/scepter.tres"),
	preload("res://resources/items/runic_scepter.tres"),
	# bouclier
	preload("res://resources/items/shield.tres"),
	preload("res://resources/items/kite_shield.tres"),
	preload("res://resources/items/pavise.tres"),
	# grimoire
	preload("res://resources/items/grimoire.tres"),
	preload("res://resources/items/codex.tres"),
	# casque_lourd
	preload("res://resources/items/helmet.tres"),
	preload("res://resources/items/great_helm.tres"),
	preload("res://resources/items/armet.tres"),
	# casque_leger
	preload("res://resources/items/hood.tres"),
	preload("res://resources/items/masters_hood.tres"),
	# torse_lourd
	preload("res://resources/items/breastplate.tres"),
	preload("res://resources/items/chainmail.tres"),
	preload("res://resources/items/full_plate.tres"),
	# torse_leger
	preload("res://resources/items/tunic.tres"),
	preload("res://resources/items/jerkin.tres"),
	# gants
	preload("res://resources/items/gloves.tres"),
	preload("res://resources/items/reinforced_gloves.tres"),
	preload("res://resources/items/masters_gloves.tres"),
	preload("res://resources/items/gauntlets.tres"),
	preload("res://resources/items/mail_gauntlets.tres"),
	preload("res://resources/items/plate_gauntlets.tres"),
	# bottes
	preload("res://resources/items/boots.tres"),
	preload("res://resources/items/studded_boots.tres"),
	preload("res://resources/items/travel_boots.tres"),
	preload("res://resources/items/sabatons.tres"),
	preload("res://resources/items/mail_sabatons.tres"),
	preload("res://resources/items/plate_sabatons.tres"),
	# ceinture
	preload("res://resources/items/belt.tres"),
	preload("res://resources/items/girdle.tres"),
	preload("res://resources/items/baldric.tres"),
	# amulette
	preload("res://resources/items/amulet.tres"),
	preload("res://resources/items/talisman.tres"),
	preload("res://resources/items/pendentif.tres"),
	# anneau
	preload("res://resources/items/ring.tres"),
	preload("res://resources/items/ornate_ring.tres"),
	preload("res://resources/items/signet_ring.tres"),

	# Les manuels tombent et se rechargent, mais ne se portent pas : les règles
	# d'équipement les laissent de côté (`EquipmentSlots.equippable_family()`).
	preload("res://resources/items/manual_lightning.tres"),
	# Chacun sa lignée d'un palier, qui dit sa rareté, et son propre `kind`.
	preload("res://resources/items/manual_weapons.tres"),
	preload("res://resources/items/manual_fire.tres"),
	preload("res://resources/items/manual_cold.tres"),
	preload("res://resources/items/manual_holy.tres"),
	preload("res://resources/items/manual_necrotic.tres"),
]


## Un identifiant et non un tirage : la mécanique centrale ne s'apprend pas au hasard.
const ID_STARTING_MANUAL := "manual_lightning"
const ID_STARTING_WEAPON := "sword"
const ID_STARTING_WAND := "wand"

## Combien de niveaux une base tombe encore **après** l'ouverture de sa remplaçante :
## un chevauchement, pas une falaise. La lame de guerre ouvre au 34, l'épée large
## cesse après 40.
const READING_MARGIN := 6


## La relève de chaque base dans sa lignée, ou null. Retenue : `available` la
## demande pour chaque base à chaque chute.
static var _readings: Dictionary = {}


static func reading_of(base: ItemBase) -> ItemBase:
	if _readings.is_empty():
		for candidate in ALL:
			var next_one: ItemBase = null
			for other in ALL:
				if other.lineage != candidate.lineage or other.tier <= candidate.tier:
					continue
				if next_one == null or other.tier < next_one.tier:
					next_one = other
			_readings[candidate.id] = next_one
	return _readings.get(base.id)


## Niveau requis et dernier niveau de chute ; **y à zéro : sans fin**. C'est la règle
## elle-même : `available` décide par elle, la forge l'affiche.
static func drop_window(base: ItemBase) -> Vector2i:
	var next_one := reading_of(base)
	return Vector2i(
		base.required_level,
		0 if next_one == null else next_one.required_level + READING_MARGIN
	)


## Les bases qu'une zone de ce niveau peut lâcher, par la fenêtre de chute.
static func available(level: int) -> Array:
	var out := []
	for base in ALL:
		var window := drop_window(base)
		if level < window.x:
			continue
		if window.y > 0 and level > window.y:
			continue
		out.append(base)
	return out


## Null pour une base retirée du projet, qu'une sauvegarde peut citer. Balayage
## linéaire : jamais dans une boucle de jeu.
static func by_id(id: String) -> ItemBase:
	for base in ALL:
		if base.id == id:
			return base
	return null
