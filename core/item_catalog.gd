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


## Les bases qu'une zone de ce niveau peut lâcher. Ici et non dans LootTable :
## c'est le catalogue qui sait ce qu'il contient, et la table de butin n'a qu'à
## tirer dans ce qu'on lui donne.
##
## Une seule règle pour l'instant — le niveau requis de la base. L'étape 5 y
## ajoutera celle qui compte vraiment : ne garder que les deux meilleurs paliers
## de chaque lignée, sans quoi trente bases tirées à égalité donneraient une
## chute utile sur cinq.
static func disponibles(niveau: int) -> Array:
	var out := []
	for base in ALL:
		if base.niveau_requis <= niveau:
			out.append(base)
	return out


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
