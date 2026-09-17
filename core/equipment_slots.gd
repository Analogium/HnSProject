class_name EquipmentSlots

## Les emplacements et la famille que chacun accepte. **Un emplacement n'est pas une
## famille** : un anneau, deux doigts. Dans l'ordre du panneau. **Identifiants
## définitifs** (invariant 1).

const SLOTS := {
	"weapon": {"family": "weapon", "label": "ARME"},
	"offhand": {"family": "offhand", "label": "MAIN G."},
	"helmet": {"family": "helmet", "label": "CASQUE"},
	"chest": {"family": "chest", "label": "TORSE"},
	"gloves": {"family": "gloves", "label": "GANTS"},
	"boots": {"family": "boots", "label": "BOTTES"},
	"belt": {"family": "belt", "label": "CEINTURE"},
	"amulet": {"family": "amulet", "label": "AMULETTE"},
	# « BAGUE » : les deux « ANNEAU » se tronquaient au même endroit.
	"ring_left": {"family": "ring", "label": "BAGUE G."},
	"ring_right": {"family": "ring", "label": "BAGUE D."},
}

const WEAPON := "weapon"

## Calculés une fois : `keys()` alloue, et le panneau les demande à chaque image.
static var _ids := PackedStringArray(SLOTS.keys())


static func ids() -> PackedStringArray:
	return _ids


static func count() -> int:
	return SLOTS.size()


static func exists(slot: String) -> bool:
	return SLOTS.has(slot)


## Un objet de cette famille se porte-t-il ? **La seule question** qui fait échapper
## un manuel aux règles d'équipement.
static func equippable_family(family: String) -> bool:
	for id in SLOTS:
		if SLOTS[id]["family"] == family:
			return true
	return false


static func family_of(slot: String) -> String:
	return SLOTS[slot]["family"] if SLOTS.has(slot) else ""


## Dans la langue du joueur ; la table française est la clé.
static func label(slot: String) -> String:
	return Texts.t(SLOTS[slot]["label"]) if SLOTS.has(slot) else slot


## Vide si l'objet ne s'équipe pas.
static func family_of_item(item: Item) -> String:
	if item == null or item.base == null:
		return ""
	return item.base.family


static func accepts(slot: String, item: Item) -> bool:
	var family := family_of_item(item)
	return not family.is_empty() and family_of(slot) == family


## Le premier emplacement libre de sa famille, à défaut le premier : la règle des
## anneaux. Vide pour ce qui ne s'équipe pas — l'appelant le rend intact.
static func free_for(item: Item, worn: Dictionary) -> String:
	var family := family_of_item(item)
	if family.is_empty():
		return ""
	var first := ""
	for id in SLOTS:
		if SLOTS[id]["family"] != family:
			continue
		if first.is_empty():
			first = id
		if worn.get(id) == null:
			return id
	return first
