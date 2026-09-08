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

	# Défenses élémentaires, réserve, incantation et attributs : ceux-ci rendent
	# à la baguette et à la ceinture de quoi être intéressantes.
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
## affixes doit rester l'histoire qu'on raconte, pas le butin du mardi. Un objet
## sur deux sort nu — c'est ce qui donne sa valeur au reste.
##
## Le maximum réel dépend de la base : les armures n'ont que quatre affixes
## compatibles et plafonnent là. C'est la réserve qui décide, pas cette table.
const COUNT_WEIGHTS := [46, 24, 14, 8, 5, 2, 1]


## La définition portant cet identifiant, ou null s'il n'existe plus. Le null
## n'est pas une erreur de programmation mais un cas de jeu : un objet sauvegardé
## peut porter un affixe retiré du projet depuis. Sa valeur s'applique toujours,
## c'est son palier qui devient inaffichable.
static func by_id(id: String) -> ItemAffix:
	for a in ALL:
		if a.id == id:
			return a
	return null


## Tout ce que cette base peut porter, **quel que soit son niveau** : le type de
## l'objet seul décide. Une armure ne donne pas d'allonge, une baguette pas de
## dégâts d'attaque, et ça reste vrai à tous les niveaux.
##
## Séparée d'`eligible` parce que les deux questions sont distinctes : celle-ci
## est « qu'est-ce que cet objet peut avoir un jour », que pose la fiche de la
## forge ; l'autre est « qu'est-ce qu'il peut recevoir maintenant », que pose le
## tirage. Une seule des deux écrit le filtre.
static func compatibles(base: ItemBase) -> Array:
	var out := []
	for a in ALL:
		if a.fits(base):
			out.append(a)
	return out


## Ce qui peut sortir sur cette base, à ce niveau d'objet.
##
## Un affixe dont **aucun** palier n'est ouvert n'est pas dans la réserve : le
## niveau d'objet ne corrige pas des probabilités par une formule, il ouvre des
## lignes dans une table.
static func eligible(base: ItemBase, niveau: int) -> Array:
	var out := []
	for a in compatibles(base):
		if not a.ouverts(niveau).is_empty():
			out.append(a)
	return out


## Combien d'affixes pour cet objet. Borné par la réserve réellement
## disponible : une base dont la famille compte quatre affixes ne peut pas en
## porter six, et le tirage doit le dire plutôt que de rendre des lignes vides.
static func roll_count(rng: RandomNumberGenerator, disponibles: int) -> int:
	var i := Tirage.pondere(rng, COUNT_WEIGHTS)
	return 0 if i < 0 else mini(i, disponibles)


## Les affixes d'un objet neuf, tirés distincts : deux fois « acéré » sur la même
## épée se liraient comme un bug, et additionner deux fois la même ligne n'ajoute
## rien qu'un affixe plus large n'aurait fait.
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
		# palier ouvert — mais l'ignorer vaut mieux qu'une ligne vide sur un
		# objet le jour où les deux règles divergeraient.
		if tire != null:
			tires.append(tire)
	return tires


## Tirage pondéré dans ce qui reste. Les poids sont relevés à chaque appel :
## retirer un affixe déjà tiré change les probabilités des suivants, et garder
## une table figée donnerait des tirages nuls de plus en plus fréquents.
static func _pick(rng: RandomNumberGenerator, pool: Array) -> ItemAffix:
	var poids := []
	for a in pool:
		poids.append(a.weight)
	var i := Tirage.pondere(rng, poids)
	return null if i < 0 else pool[i]
