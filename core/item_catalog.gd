class_name ItemCatalog

## Toutes les bases d'objets du projet, et **le seul endroit où elles sont
## listées**. La table de butin y puise, la sauvegarde y retrouve une base par
## son identifiant : deux listes séparées auraient fini par diverger, et un objet
## qui tombe sans pouvoir être rechargé est pire qu'un objet qui ne tombe pas.
##
## Ajouter une base = ajouter une ligne ici et un `id` dans son `.tres`. Le test
## du catalogue refuse un identifiant vide ou en double.

## Dans l'ordre des emplacements d'EquipmentSlots : une base manquante pour un
## emplacement se voit en lisant la liste, et le test le confirme.
const ALL := [
	preload("res://resources/items/epee.tres"),
	preload("res://resources/items/baguette.tres"),
	preload("res://resources/items/bouclier.tres"),
	preload("res://resources/items/casque.tres"),
	preload("res://resources/items/plastron.tres"),
	preload("res://resources/items/gants.tres"),
	preload("res://resources/items/bottes.tres"),
	preload("res://resources/items/ceinture.tres"),
	preload("res://resources/items/amulette.tres"),
	preload("res://resources/items/anneau.tres"),
]


## La base portant cet identifiant, ou null s'il n'existe plus. Le null n'est pas
## une erreur de programmation mais un cas de jeu : une sauvegarde peut contenir
## un objet dont la base a été retirée du projet depuis. L'appelant l'ignore,
## il ne plante pas.
##
## Balayage linéaire : trois bases. Le jour où il y en aura cinquante, un
## dictionnaire construit une fois remplacera cette boucle — pas avant, une table
## de correspondance pour trois entrées coûte plus à lire qu'elle ne rapporte.
static func by_id(id: String) -> ItemBase:
	for base in ALL:
		if base.id == id:
			return base
	return null
