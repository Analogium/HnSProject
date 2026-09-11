class_name ItemCatalog

## Toutes les bases d'objets du projet, et **le seul endroit où elles sont
## listées**. La table de butin y puise, la sauvegarde y retrouve une base par
## son identifiant : deux listes séparées auraient fini par diverger, et un objet
## qui tombe sans pouvoir être rechargé est pire qu'un objet qui ne tombe pas.
##
## Ajouter une base = une ligne ici et un `id` dans son `.tres`. Le test du
## catalogue refuse un identifiant vide ou en double.

## Rangées par lignée, puis par palier croissant : c'est ainsi qu'on les lit, et
## une lignée à laquelle il manque un palier se voit sans compter.
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

	# Les manuels (jalon 6). Ils sont dans le catalogue parce qu'ils tombent et se
	# rechargent comme le reste — mais ils ne se **portent** pas, et les règles
	# écrites pour l'équipement les laissent donc de côté : pas d'affixes, pas de
	# lignée à deux paliers, pas d'implicite qui doit croître. La question se pose
	# à un seul endroit, `EquipmentSlots.famille_equipable()`.
	preload("res://resources/items/manuel_foudre.tres"),
]


## Le manuel qu'un personnage neuf reçoit à son premier pas. Un identifiant en
## constante et non un tirage : un jeu qui ferait chercher son premier manuel
## dans le butin apprendrait sa mécanique centrale par le hasard.
const ID_MANUEL_DE_DEPART := "manuel_foudre"

## Combien de niveaux une base continue de tomber **après** l'ouverture de celle
## qui la remplace. C'est toute la règle de relève : une base périmée qui continue
## de tomber n'est pas une chance de plus, c'est du bruit dans le butin.
##
## Six et non zéro : la bascule doit être un chevauchement, pas une falaise. Deux
## ou trois zones pendant lesquelles on voit les deux tomber, assez pour
## comprendre ce qui remplace quoi sans avoir rien à lire.
##
## Le chiffre se lit dans le jeu : la lame de guerre ouvre au niveau 34, donc
## l'épée large cesse de tomber après la zone 40.
const MARGE_DE_RELEVE := 6


## La base qui prend la relève de celle-ci dans sa lignée — le palier
## immédiatement supérieur — ou null quand c'est déjà le meilleur.
##
## Calculée une fois pour tout le catalogue et retenue : `disponibles` la demande
## pour chacune des quarante-deux bases, à chaque chute. Sans la table, ce
## serait mille sept cents comparaisons par ennemi tué.
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


## Entre quels niveaux de zone cette base tombe : son niveau requis, et le
## dernier niveau où elle sort encore. **Un y de zéro veut dire « sans fin »** —
## rien ne viendra jamais la remplacer, c'est le meilleur palier de sa lignée.
##
## C'est la règle elle-même, pas une lecture de la règle : `disponibles` s'en
## sert pour décider, et la fiche de la forge pour l'afficher. L'outil qui sert à
## vérifier le catalogue ne peut donc pas dire autre chose que ce qui tombe.
static func fenetre_de_chute(base: ItemBase) -> Vector2i:
	var suivante := releve_de(base)
	return Vector2i(
		base.niveau_requis,
		0 if suivante == null else suivante.niveau_requis + MARGE_DE_RELEVE
	)


## Les bases qu'une zone de ce niveau peut lâcher. Ici et non dans LootTable :
## c'est le catalogue qui sait ce qu'il contient, et la table de butin n'a qu'à
## tirer dans ce qu'on lui donne.
##
## Une seule règle, et c'est la fenêtre de chute : une base tombe entre son
## niveau requis et le moment où sa remplaçante l'a chassée.
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


## La base portant cet identifiant, ou null s'il n'existe plus. Le null n'est pas
## une erreur de programmation mais un cas de jeu : une sauvegarde peut contenir
## un objet dont la base a été retirée du projet depuis.
##
## Balayage linéaire : les appelants sont le chargement d'une sauvegarde et les
## tests, aucun n'est dans une boucle de jeu.
static func by_id(id: String) -> ItemBase:
	for base in ALL:
		if base.id == id:
			return base
	return null
