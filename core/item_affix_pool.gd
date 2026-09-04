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
	preload("res://resources/item_affixes/cuirasse.tres"),
]

## Poids du nombre d'affixes, de 0 à 6. La courbe descend vite : un objet à six
## affixes doit rester l'histoire qu'on raconte, pas le butin du mardi.
##
## Le maximum réel dépend de la base : six affixes d'arme existent, donc une épée
## peut les porter tous ; les armures n'en ont que quatre et plafonnent là. C'est
## la réserve qui décide, pas cette table.
##
## Un objet sur deux sort nu — c'est ce qui donne sa valeur au reste, et le
## joueur doit pouvoir jeter la moitié de ce qu'il ramasse sans réfléchir.
const COUNT_WEIGHTS := [46, 24, 14, 8, 5, 2, 1]


## Ce qui peut sortir sur cette base. Une armure et une épée ne tirent pas dans
## la même réserve : c'est ce qui donne un sens au type de l'objet.
static func eligible(base: ItemBase) -> Array:
	var out := []
	for a in ALL:
		if a.fits(base):
			out.append(a)
	return out


## Combien d'affixes pour cet objet. Borné par la réserve réellement disponible :
## une base dont la famille compte quatre affixes ne peut pas en porter six, et
## le tirage doit le dire plutôt que de rendre des lignes vides.
static func roll_count(rng: RandomNumberGenerator, disponibles: int) -> int:
	var total := 0
	for w in COUNT_WEIGHTS:
		total += w
	var pick := rng.randi_range(1, total)
	for i in COUNT_WEIGHTS.size():
		pick -= COUNT_WEIGHTS[i]
		if pick <= 0:
			return mini(i, disponibles)
	return 0


## Les affixes d'un objet neuf, tirés distincts : deux fois « acéré » sur la
## même épée se liraient comme un bug, et additionner deux fois la même ligne
## n'ajoute rien qu'un affixe plus large n'aurait fait.
static func roll(rng: RandomNumberGenerator, base: ItemBase) -> Array[StatMod]:
	var mods: Array[StatMod] = []
	var reste := eligible(base)
	for i in roll_count(rng, reste.size()):
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
