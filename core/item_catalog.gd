class_name ItemCatalog

## Toutes les bases d'objets du projet, et **le seul endroit où elles sont
## listées**. La table de butin y puise, la sauvegarde y retrouve une base par
## son identifiant : deux listes séparées auraient fini par diverger, et un objet
## qui tombe sans pouvoir être rechargé est pire qu'un objet qui ne tombe pas.
##
## Ajouter une base = ajouter une ligne ici et un `id` dans son `.tres`. Le test
## du catalogue refuse un identifiant vide ou en double.

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
]


## Les bases qu'une zone de ce niveau peut lâcher. Ici et non dans LootTable :
## c'est le catalogue qui sait ce qu'il contient, et la table de butin n'a qu'à
## tirer dans ce qu'on lui donne.
##
## Une seule règle pour l'instant — le niveau requis de la base. L'étape 5 y
## ajoutera celle qui compte vraiment : ne garder que les deux meilleurs paliers
## de chaque lignée, sans quoi trente bases tirées à égalité donneraient une
## chute utile sur cinq.
## Combien de paliers d'une même lignée peuvent tomber en même temps.
##
## Sans cette borne, chaque base ajoutée dilue les autres : à niveau 40, une
## chute sur cinq serait une dague de niveau 1, et le rythme de récompense
## s'effondrerait au moment précis où il devrait s'améliorer. Avec elle, entrer
## dans une zone de niveau 34 fait disparaître les épées larges au profit des
## lames de guerre en deux ou trois chutes — et ça se sent sans rien lire.
##
## Deux et non un : le palier précédent qui traîne encore est ce qui rend la
## bascule progressive plutôt que brutale, et il reste souhaitable quand ses
## affixes sortent mieux.
const PALIERS_VISIBLES := 2


static func disponibles(niveau: int) -> Array:
	# Par lignée, les paliers atteints, du meilleur au pire.
	var par_lignee := {}
	for base in ALL:
		if base.niveau_requis > niveau:
			continue
		if not par_lignee.has(base.lignee):
			par_lignee[base.lignee] = []
		par_lignee[base.lignee].append(base)

	var out := []
	for lignee in par_lignee:
		var membres: Array = par_lignee[lignee]
		membres.sort_custom(func(a: ItemBase, b: ItemBase) -> bool: return a.palier > b.palier)
		for i in mini(membres.size(), PALIERS_VISIBLES):
			out.append(membres[i])
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
