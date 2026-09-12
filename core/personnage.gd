class_name Personnage
extends RefCounted

## Un personnage tel qu'il survit à la fermeture du jeu : un nom, une
## silhouette, une progression, un sac, deux emplacements.
##
## À ne pas confondre avec le Player, qui est son **incarnation dans une scène**
## — un corps avec une position, une vitesse, des PV du moment et une zone
## autour de lui. Rien de tout ça n'est ici : le jalon 3 sauvegarde le
## personnage, jamais la partie. Reprendre un personnage le fait renaître dans
## une zone neuve, en pleine santé.
##
## RefCounted et non Resource, pour la raison qui a fait choisir le JSON contre
## le `.tres` : une Resource sauvegardée porte des chemins de scripts et
## **exécute du code** au chargement. Une sauvegarde est un fichier que le joueur
## peut recevoir de quelqu'un d'autre.

## Le numéro de format **écrit**. Il monte dès qu'un champ apparaît dans le
## fichier : le niveau des objets au jalon 5, les manuels et ce qu'on en a
## appris au jalon 6, la portée d'un affixe au jalon 7, la borne haute d'une
## fourchette au jalon 8.
const VERSION := 5

## Les numéros qu'on sait **lire**, et c'est une liste, pas une égalité. Monter
## VERSION sans ajouter l'ancien numéro ici ferait passer tous les personnages
## existants en « illisible » d'un coup, alors que leurs fichiers sont intacts —
## et cela ne se verrait qu'au premier lancement après la mise à jour.
##
## Ce qu'une version 1 devient en version 2 : ses objets prennent le niveau 1.
## Ce qu'une version 2 devient en version 3 : un râtelier vide, la barre de
## départ — le coup d'épée et le tir, c'est-à-dire le jeu d'avant — et un manuel
## de départ qui n'a pas encore été offert. Ce qu'une version 3 devient en
## version 4 : rien, toutes ses lignes d'affixes visent la fiche. Ce que les
## versions 1 à 4 deviennent en version 5 : leurs dégâts plats sont convertis en
## fourchettes — voir `_ligne_actuelle`. Un numéro **inconnu** reste refusé :
## jamais deviner.
const VERSIONS_LUES := [1, 2, 3, 4, 5]

## Les deux statistiques de dégâts plats d'avant le jalon 8. Elles ne vivent plus
## que dans les sauvegardes, et ne sont nommées qu'ici, pour être converties.
const ANCIENS_DEGATS_D_ATTAQUE := "attack_damage"
const ANCIENS_DEGATS_DE_SORT := "spell_damage"

## Longueur maximale du nom. Bornée parce que l'écran de sélection le dessine sur
## une ligne. Vingt et non seize : une borne qui rejette « Jean-Luc de l'Est »
## n'est pas une protection, c'est un bug.
const NOM_MAX := 20

var id := ""
var nom := ""
## L'index de variante que la forge sait dessiner. Un entier et non un chemin de
## sprite : c'est la génération procédurale utilisée comme règle de jeu.
var silhouette := 0
var cree_le := ""
var joue_le := ""

var niveau := 1
var experience := 0

## Ce que le joueur a **placé**, et non ce qu'il a en tout : écrire le total
## figerait les valeurs de départ du jour de la sauvegarde, et un rééquilibrage
## n'atteindrait jamais les personnages existants.
var attributs := CharacterStats.empty_attributes()
## Sauvegardé aussi : monter de niveau puis quitter sans répartir ne doit pas
## coûter les points.
var points_a_placer := 0

var sac := Inventory.new(Inventory.DEFAULT_COLS, Inventory.DEFAULT_ROWS)
## Ce qui est porté, par emplacement. Les noms d'emplacements ne sont pas
## validés ici : c'est le Player qui sait lesquels existent, et il refuse déjà
## ce qu'il ne sait pas porter.
var equipement := {}

## Les manuels à l'étude. Ils ont quitté le sac pour y entrer, comme un plastron
## qu'on enfile : ils sont donc écrits ici et **nulle part ailleurs**, sans quoi
## il y aurait deux vérités sur leurs points et le rechargement en choisirait une.
var ratelier := Ratelier.new()

## Les cinq cases de la barre. Par défaut celles du jeu d'avant, ce qui est aussi
## ce que devient une sauvegarde de version 2.
var barre := BarreDeCompetences.par_defaut()

## Le manuel de départ a-t-il déjà été donné. Sauvegardé, et non déduit de « le
## sac contient un manuel » : un joueur qui jette le sien en recevrait un second,
## et le livre de départ deviendrait une monnaie.
var manuel_offert := false

## Vrai pour l'entrée d'un fichier qu'on n'a pas su lire : l'écran de sélection la
## montre grisée plutôt que de la faire disparaître, un personnage qui s'évapore
## du menu ressemblant à une perte même quand son fichier est intact.
var illisible := false


static func nouveau(p_nom: String, p_silhouette: int) -> Personnage:
	var p := Personnage.new()
	p.id = nouvel_id()
	p.nom = p_nom.strip_edges()
	p.silhouette = p_silhouette
	p.cree_le = Time.get_date_string_from_system()
	p.joue_le = p.cree_le
	return p


static func illisible_avec(p_id: String) -> Personnage:
	var p := Personnage.new()
	p.id = p_id
	p.illisible = true
	return p


## L'identifiant est **généré**, jamais dérivé du nom saisi : deux personnages
## peuvent porter le même nom, et un nom peut contenir des caractères qu'un
## système de fichiers refuse.
##
## Tire sur le générateur global et non sur Game.rng, dont l'état est le fil des
## tirages de la partie : lui prendre deux nombres décalerait toutes les graines
## de zone tirées ensuite.
static func nouvel_id() -> String:
	return "p_%d_%04d" % [int(Time.get_unix_time_from_system()), randi() % 10000]


## Non vide, borné, et sans caractères de contrôle — ceux-là ne se voient pas à
## l'écran mais se retrouveraient dans le fichier et dans la liste.
static func nom_valide(p_nom: String) -> bool:
	var n := p_nom.strip_edges()
	if n.is_empty() or n.length() > NOM_MAX:
		return false
	for i in n.length():
		var code := n.unicode_at(i)
		if code < 32 or code == 127:
			return false
	return true


## Ce qui part sur le disque. Aucune statistique calculée : elles se
## **recalculent** à partir de la fiche de base, des attributs et de l'équipement,
## et les écrire créerait une deuxième vérité.
func vers_dict() -> Dictionary:
	var objets := []
	for pose in sac.placed:
		var entree := _item_vers_dict(pose.data)
		entree["cellule"] = [pose.cell.x, pose.cell.y]
		objets.append(entree)

	var porte := {}
	for emplacement in equipement:
		var item: Item = equipement[emplacement]
		if item != null and item.base != null:
			porte[emplacement] = _item_vers_dict(item)

	# Les trois emplacements sont écrits même vides : une liste de trois entrées
	# dont deux valent null se relit sans avoir à deviner laquelle manquait.
	var livres := []
	for item in ratelier.manuels:
		livres.append(_item_vers_dict(item) if item != null and item.base != null else null)

	# Une case vide s'écrit null et non chaîne vide : le fichier se lit à l'œil,
	# et « rien » y ressemble à rien.
	var cases := []
	for i in BarreDeCompetences.EMPLACEMENTS:
		var id := barre.id_de(i)
		cases.append(null if id.is_empty() else id)

	return {
		"version": VERSION,
		"id": id,
		"nom": nom,
		"silhouette": silhouette,
		"cree_le": cree_le,
		"joue_le": joue_le,
		"niveau": niveau,
		"experience": experience,
		"attributs": attributs.duplicate(),
		"points_a_placer": points_a_placer,
		"sac": objets,
		"equipement": porte,
		"ratelier": livres,
		"barre": cases,
		"manuel_offert": manuel_offert,
	}


## Le chemin inverse, et **le seul endroit** qui fait confiance à des données
## venues du dehors. Tout y est reconverti explicitement : le JSON ne connaît
## qu'un seul type de nombre, donc un niveau relu vaut 7.0 et non 7.
##
## Renvoie null quand le fichier n'est pas exploitable. Un champ isolé qui manque
## reprend sa valeur par défaut : perdre un personnage entier pour un champ absent
## est le pire des résultats possibles.
static func depuis_dict(source: Dictionary) -> Personnage:
	var version := _entier(source, "version", 0)
	if not VERSIONS_LUES.has(version):
		push_warning("Sauvegarde de version %d, connues %s : refusée." % [version, VERSIONS_LUES])
		return null

	var p := Personnage.new()
	p.id = String(source.get("id", ""))
	if p.id.is_empty():
		push_warning("Sauvegarde sans identifiant : refusée.")
		return null

	p.nom = String(source.get("nom", ""))
	p.silhouette = _entier(source, "silhouette", 0)
	p.cree_le = String(source.get("cree_le", ""))
	p.joue_le = String(source.get("joue_le", ""))
	p.niveau = maxi(_entier(source, "niveau", 1), 1)
	p.experience = maxi(_entier(source, "experience", 0), 0)
	p.points_a_placer = maxi(_entier(source, "points_a_placer", 0), 0)

	# Champ par champ depuis ATTRIBUTES, et non en recopiant le dictionnaire lu :
	# un attribut ajouté depuis part de zéro au lieu de manquer, et un nom
	# inconnu dans le fichier est ignoré au lieu d'entrer dans la répartition.
	var lus: Dictionary = source.get("attributs", {}) if source.get("attributs") is Dictionary else {}
	for champ in CharacterStats.ATTRIBUTES:
		p.attributs[champ] = maxi(_entier(lus, champ, 0), 0)

	for entree in _liste(source.get("sac")):
		var item := _item_depuis_dict(entree)
		if item == null:
			continue
		var cellule := _cellule(entree)
		# Sa place d'abord, n'importe laquelle ensuite : si la grille a rétréci
		# ou si deux objets se recouvrent, on les range plutôt que de les perdre.
		if not p.sac.place(item, cellule) and not p.sac.add(item):
			push_warning("Objet « %s » abandonné : plus de place dans le sac." % item.display_name())

	var porte: Dictionary = source.get("equipement", {}) if source.get("equipement") is Dictionary else {}
	for emplacement in porte:
		var item := _item_depuis_dict(porte[emplacement])
		if item != null:
			p.equipement[String(emplacement)] = item

	var livres := _liste(source.get("ratelier"))
	for i in mini(livres.size(), Ratelier.EMPLACEMENTS):
		var item := _item_depuis_dict(livres[i])
		if item == null:
			continue
		# Refusé — un fichier trafiqué, un objet qui n'est pas un manuel — il
		# retombe dans le sac plutôt que de disparaître.
		if p.ratelier.poser(i, item) != null and not p.sac.add(item):
			push_warning("Manuel « %s » abandonné : le râtelier l'a refusé." % item.display_name())

	# **Clé absente : la barre de départ.** C'est ce que devient une sauvegarde
	# d'avant le jalon 6, et c'est le jeu d'avant. Clé présente : ce qu'elle dit,
	# cases vides comprises — sinon une case qu'on a délibérément vidée
	# reviendrait remplie au chargement suivant.
	if source.has("barre"):
		p.barre = BarreDeCompetences.new()
		var cases := _liste(source.get("barre"))
		for i in mini(cases.size(), BarreDeCompetences.EMPLACEMENTS):
			var id := String(cases[i]) if cases[i] is String else ""
			# Une compétence retirée du projet laisse sa case vide. Le fichier
			# reste lisible : c'est une case de barre, pas un personnage.
			if not id.is_empty() and CompetenceCatalog.by_id(id) != null:
				p.barre.poser(i, id)

	p.manuel_offert = source.get("manuel_offert", false) == true

	return p


## Un objet : sa base par identifiant, et ses affixes déjà résolus en valeurs.
## Jamais la base elle-même — la sérialiser figerait les valeurs d'équilibrage
## du jour, et les rejouerait des mois plus tard.
static func _item_vers_dict(item: Item) -> Dictionary:
	var affixes := []
	for r in item.explicits:
		var entree := {"stat": r.mod.stat, "mode": int(r.mod.mode), "valeur": r.mod.value}
		# Écrite quand elle existe, **jamais déduite de l'affixe d'origine** à la
		# relecture : un objet sans provenance la perdrait, et son « +1 projectile »
		# deviendrait une ligne de fiche visant un champ inconnu.
		if not r.mod.portee.is_empty():
			entree["portee"] = r.mod.portee
		if r.mod.est_une_fourchette():
			entree["valeur_max"] = r.mod.value_max
		# La provenance n'est écrite que quand on l'a. Un objet relu d'une
		# version 1 puis resauvegardé ne doit pas se voir attribuer un palier
		# qu'il n'a jamais eu.
		if r.connu():
			entree["affixe"] = r.affix_id
			entree["tier"] = r.tier
		affixes.append(entree)
	var entree := {"base": item.base.id, "niveau": item.item_level, "affixes": affixes}
	# L'état d'un manuel, quand cet objet en est un. Son **niveau ne s'écrit
	# pas** : il se déduit de son expérience, et l'écrire créerait la deuxième
	# vérité que ce format refuse partout ailleurs — ni PV, ni statistiques.
	if item.manuel != null:
		entree["manuel"] = {
			"exp": item.manuel.experience,
			"points": item.manuel.points.duplicate(),
		}
	return entree


## Renvoie null quand la base n'existe plus dans le projet. L'objet est alors
## ignoré et le reste du personnage se charge : perdre une épée est désagréable,
## perdre le personnage est inacceptable.
static func _item_depuis_dict(source: Variant) -> Item:
	if not source is Dictionary:
		return null
	var objet := source as Dictionary
	var identifiant := String(objet.get("base", ""))
	var base := ItemCatalog.by_id(identifiant)
	if base == null:
		push_warning("Base d'objet inconnue « %s » : objet ignoré." % identifiant)
		return null

	var explicits: Array[RolledAffix] = []
	for brut in _liste(objet.get("affixes")):
		if not brut is Dictionary:
			continue
		var ligne := brut as Dictionary
		var stat := String(ligne.get("stat", ""))
		if stat.is_empty():
			continue
		var mode := StatMod.Mode.PERCENT if _entier(ligne, "mode", 0) == StatMod.Mode.PERCENT else StatMod.Mode.FLAT
		# Portée absente : une ligne de fiche, ce que sont toutes celles d'avant la
		# version 4.
		var valeur := _reel(ligne, "valeur", 0.0)
		var mod := StatMod.new(stat, mode, valeur, String(ligne.get("portee", "")))
		if mod.est_une_fourchette():
			mod.value_max = maxf(_reel(ligne, "valeur_max", valeur), valeur)

		var actuelle := _ligne_actuelle(mod)
		if actuelle == null:
			push_warning(
				"« %s » : ligne « %s » en pourcentage abandonnée, plus rien ne multiplie ces dégâts."
				% [identifiant, stat]
			)
			continue
		# La valeur fait foi, la provenance l'accompagne. Absente — une
		# sauvegarde de version 1, ou un affixe retiré du projet depuis — la
		# ligne s'applique quand même : c'est l'infobulle qui n'aura rien à
		# montrer, pas l'objet qui perd son bonus.
		#
		# Une ligne **convertie** perd la sienne : le palier 7 d'`acere` n'est pas
		# un palier de l'affixe qui l'a remplacé.
		var convertie := actuelle != mod
		explicits.append(RolledAffix.new(
			"" if convertie else String(ligne.get("affixe", "")),
			0 if convertie else maxi(_entier(ligne, "tier", 0), 0),
			actuelle
		))
	# Absent, il vaut 1 : c'est le cas de tous les objets d'une sauvegarde de
	# version 1, et il n'y a pas de version à tester pour le savoir — un champ
	# manquant vaut son défaut, ici comme partout ailleurs dans cette fonction.
	var niveau := _entier(objet, "niveau", 1)
	var item := Item.new(base, explicits, niveau)
	_manuel_depuis_dict(item, objet.get("manuel"))
	return item


## Ce que devient une ligne écrite avant que les dégâts plats deviennent des
## fourchettes : la ligne elle-même quand rien n'a changé, sa conversion, ou null
## quand plus rien ne sait l'appliquer.
##
## **Chaque conversion est une équivalence exacte avec le jeu d'alors**, pas une
## supposition : la seule attaque était physique, et tous les sorts étaient de
## foudre. Un personnage relu frappe donc exactement comme avant la mise à jour.
## Seuls les pourcentages de dégâts de `meurtrier` n'ont plus d'équivalent.
##
## Sur le nom de la statistique et non sur la version : ces deux champs ont quitté
## la fiche du joueur, et une ligne qui les viserait ne ferait plus rien, d'où
## qu'elle vienne.
static func _ligne_actuelle(mod: StatMod) -> StatMod:
	if not mod.portee.is_empty():
		return mod
	var nature: DamageType.Kind
	var famille := ""
	match mod.stat:
		ANCIENS_DEGATS_D_ATTAQUE:
			nature = DamageType.Kind.PHYSICAL
			famille = MotsCles.ATTAQUE
		ANCIENS_DEGATS_DE_SORT:
			nature = DamageType.Kind.LIGHTNING
			famille = MotsCles.SORT
		_:
			return mod
	if mod.mode == StatMod.Mode.PERCENT:
		return null
	return StatMod.fourchette(
		StatsDeCompetence.stat_ajoutee(nature), mod.value, mod.value, famille
	)


## Remplit l'état du manuel que `Item.new()` a déjà créé vierge. On le remplit,
## on ne le remplace pas : c'est l'objet qui décide s'il en a un, d'après sa base.
static func _manuel_depuis_dict(item: Item, source: Variant) -> void:
	if item.manuel == null or not source is Dictionary:
		return
	var etat := source as Dictionary
	item.manuel.experience = maxi(_entier(etat, "exp", 0), 0)

	var points: Variant = etat.get("points")
	if not points is Dictionary:
		return
	for id in points:
		# La question n'est pas « cela existe-t-il dans le jeu » mais « ce livre
		# le connaît-il » : des points placés dans une case, un passif ou un nœud
		# que l'archétype ne contient plus ne sont dépensables nulle part, et les
		# garder ferait un manuel qui doit des points à personne.
		#
		# **Les trois sortes, et pas seulement les cases** : demander `enseigne()`
		# jetterait en silence tous les points d'arbre au premier rechargement,
		# sur des fichiers intacts.
		if item.connait(String(id)):
			item.manuel.points[String(id)] = maxi(int(points[id]), 0)


static func _cellule(source: Variant) -> Vector2i:
	var brut := _liste((source as Dictionary).get("cellule") if source is Dictionary else null)
	if brut.size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(brut[0]), int(brut[1]))


static func _liste(valeur: Variant) -> Array:
	return valeur if valeur is Array else []


static func _entier(source: Dictionary, cle: String, defaut: int) -> int:
	var v: Variant = source.get(cle, defaut)
	return int(v) if (v is float or v is int) else defaut


static func _reel(source: Dictionary, cle: String, defaut: float) -> float:
	var v: Variant = source.get(cle, defaut)
	return float(v) if (v is float or v is int) else defaut
