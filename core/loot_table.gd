class_name LootTable

## Ce qui tombe d'un ennemi, et avec quelle probabilité.
##
## Le tirage se fait sur Game.rng et **non** sur le tirage de la zone, contrairement
## à la règle qui vaut pour tout ce qui décrit le monde. Une raison précise : le
## butin récompense une action, pas un lieu. Adossé à la case d'apparition, tuer
## le même ennemi dans une zone qu'on revisite redonnerait toujours le même
## résultat — on saurait d'avance quoi frapper, et recharger suffirait à garantir
## une chute.

const ITEMS := [
	preload("res://resources/items/epee.tres"),
	preload("res://resources/items/baguette.tres"),
]

## Probabilité de base qu'un ennemi ordinaire lâche quelque chose.
const BASE_CHANCE := 0.10

## Quantité de butin gagnée par affixe porté, en fraction. Multiplicatif sur la
## chance : un ennemi à deux affixes tombe à 12 % là où un ordinaire est à 10 %.
## C'est volontairement modeste — le gros de la récompense d'un élite reste son
## expérience, qui vaut déjà près du double.
const QUANTITY_PER_AFFIX := 0.10


static func quantity_for(affix_count: int) -> float:
	return 1.0 + QUANTITY_PER_AFFIX * float(affix_count)


## Renvoie null quand rien ne tombe — le cas courant.
static func roll(affix_count: int) -> ItemData:
	if ITEMS.is_empty():
		return null
	if Game.rng.randf() >= BASE_CHANCE * quantity_for(affix_count):
		return null
	return ITEMS[Game.rng.randi() % ITEMS.size()]
