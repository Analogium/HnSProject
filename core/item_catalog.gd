class_name ItemCatalog

## Toutes les bases d'objets, **le seul endroit où elles sont listées** : butin et
## sauvegarde y puisent. Un test refuse un identifiant vide ou en double.

## Par lignée, puis par palier croissant : un palier manquant se voit sans compter.
const ALL := [
	# lame
	preload("res://resources/items/epee.tres"),
	preload("res://resources/items/epee_large.tres"),
	preload("res://resources/items/lame_de_guerre.tres"),
	# dague
	preload("res://resources/items/dague.tres"),
	preload("res://resources/items/misericorde.tres"),
	# contondante
	preload("res://resources/items/masse.tres"),
	preload("res://resources/items/masse_d_armes.tres"),
	preload("res://resources/items/marteau_de_guerre.tres"),
	# focus
	preload("res://resources/items/baguette.tres"),
	preload("res://resources/items/sceptre.tres"),
	preload("res://resources/items/sceptre_runique.tres"),
	# bouclier
	preload("res://resources/items/bouclier.tres"),
	preload("res://resources/items/ecu.tres"),
	preload("res://resources/items/pavois.tres"),
	# grimoire
	preload("res://resources/items/grimoire.tres"),
	preload("res://resources/items/codex.tres"),
	# casque_lourd
	preload("res://resources/items/casque.tres"),
	preload("res://resources/items/heaume.tres"),
	preload("res://resources/items/armet.tres"),
	# casque_leger
	preload("res://resources/items/capuche.tres"),
	preload("res://resources/items/capuche_de_maitre.tres"),
	# torse_lourd
	preload("res://resources/items/plastron.tres"),
	preload("res://resources/items/cotte_de_mailles.tres"),
	preload("res://resources/items/harnois.tres"),
	# torse_leger
	preload("res://resources/items/tunique.tres"),
	preload("res://resources/items/justaucorps.tres"),
	# gants
	preload("res://resources/items/gants.tres"),
	preload("res://resources/items/gants_renforces.tres"),
	preload("res://resources/items/gants_de_maitre.tres"),
	# bottes
	preload("res://resources/items/bottes.tres"),
	preload("res://resources/items/bottes_cloutees.tres"),
	preload("res://resources/items/bottes_de_marche.tres"),
	# ceinture
	preload("res://resources/items/ceinture.tres"),
	preload("res://resources/items/ceinturon.tres"),
	preload("res://resources/items/baudrier.tres"),
	# amulette
	preload("res://resources/items/amulette.tres"),
	preload("res://resources/items/talisman.tres"),
	preload("res://resources/items/pendentif.tres"),
	# anneau
	preload("res://resources/items/anneau.tres"),
	preload("res://resources/items/bague_ouvragee.tres"),
	preload("res://resources/items/chevaliere.tres"),

	# Les manuels tombent et se rechargent, mais ne se portent pas : les règles
	# d'équipement les laissent de côté (`EquipmentSlots.famille_equipable()`).
	preload("res://resources/items/manuel_foudre.tres"),
	# Chacun sa lignée d'un palier, qui dit sa rareté, et son propre `kind`.
	preload("res://resources/items/manuel_armes.tres"),
	preload("res://resources/items/manuel_feu.tres"),
]


## Un identifiant et non un tirage : la mécanique centrale ne s'apprend pas au hasard.
const ID_MANUEL_DE_DEPART := "manuel_foudre"

## Combien de niveaux une base tombe encore **après** l'ouverture de sa remplaçante :
## un chevauchement, pas une falaise. La lame de guerre ouvre au 34, l'épée large
## cesse après 40.
const MARGE_DE_RELEVE := 6


## La relève de chaque base dans sa lignée, ou null. Retenue : `disponibles` la
## demande pour chaque base à chaque chute.
static var _releves: Dictionary = {}


static func releve_de(base: ItemBase) -> ItemBase:
	if _releves.is_empty():
		for candidate in ALL:
			var suivante: ItemBase = null
			for autre in ALL:
				if autre.lignee != candidate.lignee or autre.palier <= candidate.palier:
					continue
				if suivante == null or autre.palier < suivante.palier:
					suivante = autre
			_releves[candidate.id] = suivante
	return _releves.get(base.id)


## Niveau requis et dernier niveau de chute ; **y à zéro : sans fin**. C'est la règle
## elle-même : `disponibles` décide par elle, la forge l'affiche.
static func fenetre_de_chute(base: ItemBase) -> Vector2i:
	var suivante := releve_de(base)
	return Vector2i(
		base.niveau_requis,
		0 if suivante == null else suivante.niveau_requis + MARGE_DE_RELEVE
	)


## Les bases qu'une zone de ce niveau peut lâcher, par la fenêtre de chute.
static func disponibles(niveau: int) -> Array:
	var out := []
	for base in ALL:
		var fenetre := fenetre_de_chute(base)
		if niveau < fenetre.x:
			continue
		if fenetre.y > 0 and niveau > fenetre.y:
			continue
		out.append(base)
	return out


## Null pour une base retirée du projet, qu'une sauvegarde peut citer. Balayage
## linéaire : jamais dans une boucle de jeu.
static func by_id(id: String) -> ItemBase:
	for base in ALL:
		if base.id == id:
			return base
	return null
