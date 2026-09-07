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

	# --- Étape 4 du jalon 5. Les dix du dessus visaient la mêlée, l'armure et le
	# butin de base ; ceux-ci ouvrent les défenses élémentaires, la réserve,
	# l'incantation et les attributs — et rendent à la baguette et à la ceinture
	# de quoi être intéressantes.
	preload("res://resources/item_affixes/givre.tres"),
	preload("res://resources/item_affixes/ignifuge.tres"),
	preload("res://resources/item_affixes/isole.tres"),
	preload("res://resources/item_affixes/embaume.tres"),
	preload("res://resources/item_affixes/impie.tres"),
	preload("res://resources/item_affixes/fuyant.tres"),
	preload("res://resources/item_affixes/plaque.tres"),
	preload("res://resources/item_affixes/regenerant.tres"),
	preload("res://resources/item_affixes/sagace.tres"),
	preload("res://resources/item_affixes/limpide.tres"),
	preload("res://resources/item_affixes/arcanique.tres"),
	preload("res://resources/item_affixes/incantateur.tres"),
	preload("res://resources/item_affixes/muscle.tres"),
	preload("res://resources/item_affixes/agile.tres"),
	preload("res://resources/item_affixes/erudit.tres"),
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


## Ce qui peut sortir sur cette base, à ce niveau d'objet. Une armure et une épée
## ne tirent pas dans la même réserve — c'est ce qui donne un sens au type de
## l'objet — et un objet de bas niveau n'atteint pas tout ce qui existe.
##
## Un affixe dont **aucun** palier n'est ouvert n'est pas dans la réserve. C'est
## tout le mécanisme du jalon 5 : le niveau d'objet ne corrige pas des
## probabilités par une formule, il ouvre des lignes dans une table.
static func eligible(base: ItemBase, niveau: int) -> Array:
	var out := []
	for a in ALL:
		if a.fits(base) and not a.ouverts(niveau).is_empty():
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
static func roll(rng: RandomNumberGenerator, base: ItemBase, niveau: int) -> Array[RolledAffix]:
	var tires: Array[RolledAffix] = []
	var reste := eligible(base, niveau)
	for i in roll_count(rng, reste.size()):
		var choisi := _pick(rng, reste)
		if choisi == null:
			break
		reste.erase(choisi)
		var tire := choisi.roll(rng, niveau)
		# Null est impossible ici — `eligible` a déjà écarté les affixes sans
		# palier ouvert — mais l'ignorer silencieusement vaut mieux qu'une ligne
		# vide sur un objet le jour où les deux règles divergeraient.
		if tire != null:
			tires.append(tire)
	return tires


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
