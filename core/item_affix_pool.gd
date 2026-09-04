class_name ItemAffixPool

## Le tirage des affixes d'un objet. Séparé d'Item comme AffixPool l'est
## d'Enemy : un objet n'a pas à connaître le catalogue, il reçoit ce qu'on lui
## donne.
##
## À ne pas confondre avec AffixPool, qui tire les affixes des *ennemis* : les
## deux systèmes se ressemblent de loin mais ne partagent rien. Un affixe
## d'ennemi porte une couleur et une contrepartie, un affixe d'objet une
## fourchette de valeurs et un poids.

const ALL := [
	preload("res://resources/item_affixes/acere.tres"),
	preload("res://resources/item_affixes/meurtrier.tres"),
	preload("res://resources/item_affixes/vigoureux.tres"),
	preload("res://resources/item_affixes/robuste.tres"),
	preload("res://resources/item_affixes/preste.tres"),
	preload("res://resources/item_affixes/vif.tres"),
	preload("res://resources/item_affixes/cruel.tres"),
	preload("res://resources/item_affixes/sanglant.tres"),
	preload("res://resources/item_affixes/allonge.tres"),
]

## Poids du nombre d'affixes, de 0 à 6. La courbe descend vite : un objet à six
## affixes doit rester l'histoire qu'on raconte, pas le butin du mardi. Six
## exige déjà d'en tirer six distincts sur neuf.
##
## Un objet sur deux sort nu — c'est ce qui donne sa valeur au reste, et le
## joueur doit pouvoir jeter la moitié de ce qu'il ramasse sans réfléchir.
const COUNT_WEIGHTS := [46, 24, 14, 8, 5, 2, 1]


## Combien d'affixes pour cet objet.
static func roll_count(rng: RandomNumberGenerator) -> int:
	var total := 0
	for w in COUNT_WEIGHTS:
		total += w
	var pick := rng.randi_range(1, total)
	for i in COUNT_WEIGHTS.size():
		pick -= COUNT_WEIGHTS[i]
		if pick <= 0:
			return mini(i, ALL.size())
	return 0


## Les affixes d'un objet neuf, tirés distincts : deux fois « acéré » sur la
## même épée se liraient comme un bug, et additionner deux fois la même ligne
## n'ajoute rien qu'un affixe plus large n'aurait fait.
static func roll(rng: RandomNumberGenerator) -> Array[StatMod]:
	var mods: Array[StatMod] = []
	var reste := ALL.duplicate()
	for i in roll_count(rng):
		var choisi := _pick(rng, reste)
		if choisi == null:
			break
		reste.erase(choisi)
		mods.append(choisi.roll(rng))
	return mods


## Tirage pondéré dans ce qui reste. Le total est recalculé à chaque fois :
## retirer un affixe déjà tiré change les probabilités des suivants, et garder
## un total figé donnerait des tirages nuls de plus en plus fréquents.
static func _pick(rng: RandomNumberGenerator, pool: Array) -> ItemAffix:
	var total := 0
	for a in pool:
		total += a.weight
	if total <= 0:
		return null
	var pick := rng.randi_range(1, total)
	for a in pool:
		pick -= a.weight
		if pick <= 0:
			return a
	return null
