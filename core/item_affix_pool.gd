class_name ItemAffixPool

## Le tirage des affixes d'un objet. Rien de commun avec AffixPool, les affixes
## d'ennemis.

const ALL := [
	preload("res://resources/item_affixes/vigoureux.tres"),
	preload("res://resources/item_affixes/robuste.tres"),
	preload("res://resources/item_affixes/preste.tres"),
	preload("res://resources/item_affixes/vif.tres"),
	preload("res://resources/item_affixes/cruel.tres"),
	preload("res://resources/item_affixes/sanglant.tres"),
	preload("res://resources/item_affixes/allonge.tres"),
	preload("res://resources/item_affixes/cuirasse.tres"),

	# Défenses élémentaires, réserve, incantation et attributs.
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
	preload("res://resources/item_affixes/incantateur.tres"),
	preload("res://resources/item_affixes/muscle.tres"),
	preload("res://resources/item_affixes/agile.tres"),
	preload("res://resources/item_affixes/erudit.tres"),

	# Ceux qui visent un mot-clé : ils rendent vrais les mots-clés affichés.
	preload("res://resources/item_affixes/fourchu.tres"),
	preload("res://resources/item_affixes/sifflant.tres"),
	preload("res://resources/item_affixes/orageux.tres"),
	# Le pendant d'`orageux` pour le feu.
	preload("res://resources/item_affixes/ardent.tres"),
	preload("res://resources/item_affixes/ensorcele.tres"),

	# Les dégâts ajoutés, chaque nature aux attaques puis aux sorts, sur une échelle
	# commune ; chaque famille pèse ce que pesait l'affixe qu'elle remplace.
	preload("res://resources/item_affixes/physique_aux_attaques.tres"),
	preload("res://resources/item_affixes/froid_aux_attaques.tres"),
	preload("res://resources/item_affixes/feu_aux_attaques.tres"),
	preload("res://resources/item_affixes/foudre_aux_attaques.tres"),
	preload("res://resources/item_affixes/necrotique_aux_attaques.tres"),
	preload("res://resources/item_affixes/sacre_aux_attaques.tres"),
	preload("res://resources/item_affixes/physique_aux_sorts.tres"),
	preload("res://resources/item_affixes/froid_aux_sorts.tres"),
	preload("res://resources/item_affixes/feu_aux_sorts.tres"),
	preload("res://resources/item_affixes/foudre_aux_sorts.tres"),
	preload("res://resources/item_affixes/necrotique_aux_sorts.tres"),
	preload("res://resources/item_affixes/sacre_aux_sorts.tres"),
]

## Poids du nombre d'affixes, de 0 à 6 : un objet sur deux sort nu, six affixes
## restent une histoire. La réserve compatible borne le maximum réel.
const COUNT_WEIGHTS := [46, 24, 14, 8, 5, 2, 1]


## Null pour un affixe retiré du projet : sa valeur s'applique, son palier ne
## s'affiche plus.
static func by_id(id: String) -> ItemAffix:
	for a in ALL:
		if a.id == id:
			return a
	return null


## Tout ce que cette base peut porter un jour, quel que soit son niveau (la forge) ;
## `eligible` dit ce qu'elle reçoit maintenant (le tirage). Le filtre n'est qu'ici.
static func compatibles(base: ItemBase) -> Array:
	# Ce qui ne se porte pas ne reçoit rien, pas même les affixes universels. Ici et non
	# en `exclut` sur chaque affixe, que le prochain oublierait.
	if base == null or not EquipmentSlots.famille_equipable(base.family):
		return []
	var out := []
	for a in ALL:
		if a.fits(base):
			out.append(a)
	return out


## Ce qui peut sortir à ce niveau : un affixe sans palier ouvert n'est pas dans la
## réserve.
static func eligible(base: ItemBase, niveau: int) -> Array:
	var out := []
	for a in compatibles(base):
		if not a.ouverts(niveau).is_empty():
			out.append(a)
	return out


## Borné par la réserve disponible : pas de lignes vides.
static func roll_count(rng: RandomNumberGenerator, disponibles: int) -> int:
	var i := Tirage.pondere(rng, COUNT_WEIGHTS)
	return 0 if i < 0 else mini(i, disponibles)


## Tirés distincts : deux fois « acéré » se lirait comme un bug.
static func roll(rng: RandomNumberGenerator, base: ItemBase, niveau: int) -> Array[RolledAffix]:
	var tires: Array[RolledAffix] = []
	var reste := eligible(base, niveau)
	for i in roll_count(rng, reste.size()):
		var choisi := _pick(rng, reste)
		if choisi == null:
			break
		reste.erase(choisi)
		var tire := choisi.roll(rng, niveau)
		# `eligible` a déjà écarté les affixes sans palier ; ignorer null reste plus sûr.
		if tire != null:
			tires.append(tire)
	return tires


## Poids relevés à chaque appel : retirer un affixe tiré change les suivants.
static func _pick(rng: RandomNumberGenerator, pool: Array) -> ItemAffix:
	var poids := []
	for a in pool:
		poids.append(a.weight)
	var i := Tirage.pondere(rng, poids)
	return null if i < 0 else pool[i]
