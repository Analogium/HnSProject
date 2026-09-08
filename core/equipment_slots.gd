class_name EquipmentSlots

## Les emplacements d'équipement du personnage, et la famille d'objets que chacun
## accepte.
##
## **Un emplacement n'est pas une famille.** Une base dit ce qu'elle est — un
## anneau ; le personnage, lui, a deux doigts. Les confondre fait disparaître le
## premier anneau dès qu'on en équipe un second, sans que rien ne le signale.
##
## L'ordre d'insertion est celui dans lequel le panneau les montre — un Dictionary
## GDScript le conserve.
##
## **Les identifiants ne changent jamais.** Ils sont écrits dans les sauvegardes :
## renommer `chest` en `torse` ferait disparaître le plastron de tout le monde, au
## prochain chargement seulement. Le nom lisible, lui, se traduit librement.

const SLOTS := {
	"weapon": {"family": "weapon", "label": "ARME"},
	"offhand": {"family": "offhand", "label": "MAIN G."},
	"helmet": {"family": "helmet", "label": "CASQUE"},
	"chest": {"family": "chest", "label": "TORSE"},
	"gloves": {"family": "gloves", "label": "GANTS"},
	"boots": {"family": "boots", "label": "BOTTES"},
	"belt": {"family": "belt", "label": "CEINTURE"},
	"amulet": {"family": "amulet", "label": "AMULETTE"},
	# « BAGUE » et non « ANNEAU » : à la taille du cadrage, les deux libellés en
	# ANNEAU se faisaient tronquer au même endroit et annonçaient donc la même
	# chose — pire que le débordement qu'on corrigeait.
	"ring_left": {"family": "ring", "label": "BAGUE G."},
	"ring_right": {"family": "ring", "label": "BAGUE D."},
}

## Les identifiants dans l'ordre du panneau. Calculés une fois : `keys()` alloue
## un tableau neuf à chaque appel, et le dessin du panneau le demande soixante
## fois par seconde.
static var _ids := PackedStringArray(SLOTS.keys())


static func ids() -> PackedStringArray:
	return _ids


static func count() -> int:
	return SLOTS.size()


static func exists(slot: String) -> bool:
	return SLOTS.has(slot)


static func family_of(slot: String) -> String:
	return SLOTS[slot]["family"] if SLOTS.has(slot) else ""


static func label(slot: String) -> String:
	return SLOTS[slot]["label"] if SLOTS.has(slot) else slot


## La famille d'un objet, vide s'il ne s'équipe pas. Passe par la base : c'est
## elle qui sait ce qu'est l'objet.
static func family_of_item(item: Item) -> String:
	if item == null or item.base == null:
		return ""
	return item.base.family


static func accepts(slot: String, item: Item) -> bool:
	var famille := family_of_item(item)
	return not famille.is_empty() and family_of(slot) == famille


## Où poser cet objet quand l'appelant n'impose rien : **le premier emplacement
## libre de sa famille**, à défaut le premier de cette famille.
##
## C'est toute la règle des anneaux : le second va au doigt libre, le troisième
## remplace celui de gauche, et c'est à l'interface de proposer l'autre en le
## lâchant dessus.
##
## Rend une chaîne vide pour un objet qui ne s'équipe nulle part — l'appelant doit
## alors le rendre intact, jamais le perdre.
static func free_for(item: Item, worn: Dictionary) -> String:
	var famille := family_of_item(item)
	if famille.is_empty():
		return ""
	var premier := ""
	for id in SLOTS:
		if SLOTS[id]["family"] != famille:
			continue
		if premier.is_empty():
			premier = id
		if worn.get(id) == null:
			return id
	return premier
