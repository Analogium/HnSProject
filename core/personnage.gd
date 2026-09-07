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
## le `.tres` : une Resource sauvegardée porte des chemins de scripts, casse
## quand on range un fichier ailleurs, et **exécute du code** au chargement. Une
## sauvegarde est un fichier que le joueur peut recevoir de quelqu'un d'autre.

## Le numéro de format **écrit**. Il monte dès qu'un champ apparaît dans le
## fichier : ici, le niveau des objets, au jalon 5.
const VERSION := 2

## Les numéros qu'on sait **lire**, et c'est une liste, pas une égalité.
##
## Le code refusait tout ce qui n'était pas exactement `VERSION` — la bonne
## règle tant qu'il n'existait qu'un format. Monter le numéro sans écrire la
## lecture de l'ancien aurait fait passer tous les personnages existants en
## « illisible » d'un coup, grisés dans l'écran de sélection, alors que leurs
## fichiers sont intacts. C'est la faute la plus coûteuse du jalon, et elle ne
## se serait vue qu'au premier lancement après la mise à jour.
##
## Ce qu'une version 1 devient en version 2 : ses objets prennent le niveau 1.
## On ne sait pas dans quelle zone ils sont tombés, et prétendre le contraire
## serait inventer. Un numéro **inconnu** reste refusé — jamais deviner.
const VERSIONS_LUES := [1, 2]

## Longueur maximale du nom. Bornée parce que l'écran de sélection le dessine
## sur une ligne, et qu'un nom de deux cents caractères y déborderait sur le
## niveau et la date.
##
## Vingt et non seize : la première valeur, posée au jugé, refusait
## « Jean-Luc de l'Est ». Une borne qui rejette un nom composé ordinaire n'est
## pas une protection, c'est un bug. À revérifier quand l'écran de sélection
## sera dessiné — c'est lui qui a le dernier mot sur ce qui tient sur sa ligne.
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

## Ce que le joueur a **placé**, et non ce qu'il a en tout. Le total se
## reconstruit à partir de la fiche de départ et de l'équipement ; écrire le
## total figerait les valeurs de départ du jour de la sauvegarde, et un
## rééquilibrage n'atteindrait jamais les personnages existants.
var attributs := CharacterStats.empty_attributes()
## Sauvegardé aussi : monter de niveau puis quitter sans répartir ne doit pas
## coûter les points.
var points_a_placer := 0

var sac := Inventory.new(Inventory.DEFAULT_COLS, Inventory.DEFAULT_ROWS)
## Ce qui est porté, par emplacement. Les noms d'emplacements ne sont pas
## validés ici : c'est le Player qui sait lesquels existent, et il refuse déjà
## ce qu'il ne sait pas porter.
var equipement := {}

## Vrai pour l'entrée d'un fichier qu'on n'a pas su lire. Elle existe pour que
## l'écran de sélection puisse la montrer grisée plutôt que la faire disparaître
## en silence — un personnage qui s'évapore du menu ressemble à une perte, même
## quand le fichier est toujours là.
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
## système de fichiers refuse — barres obliques, points, noms réservés.
##
## Tire sur le générateur global et non sur Game.rng : celui-là est le fil des
## tirages de la partie, et lui prendre deux nombres pour nommer un fichier
## décalerait toutes les graines de zone tirées ensuite.
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
## **recalculent** à partir de la fiche de base, des attributs et de
## l'équipement, et les écrire ici créerait une deuxième vérité qui finirait par
## contredire recompute_stats().
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
	}


## Le chemin inverse, et **le seul endroit** qui fait confiance à des données
## venues du dehors. Tout y est reconverti explicitement : le JSON ne connaît
## qu'un seul type de nombre, donc un niveau relu vaut 7.0 et non 7, et un
## `assert_eq(niveau, 7)` échouerait sur un personnage pourtant intact.
##
## Renvoie null quand le fichier n'est pas exploitable. Un champ isolé qui
## manque ne fait pas échouer le personnage — il reprend sa valeur par défaut,
## parce que perdre un personnage entier pour un champ absent est le pire des
## résultats possibles.
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

	return p


## Un objet : sa base par identifiant, et ses affixes déjà résolus en valeurs.
## Jamais la base elle-même — la sérialiser figerait les valeurs d'équilibrage
## du jour, et les rejouerait des mois plus tard.
static func _item_vers_dict(item: Item) -> Dictionary:
	var affixes := []
	for m in item.explicits:
		affixes.append({"stat": m.stat, "mode": int(m.mode), "valeur": m.value})
	return {"base": item.base.id, "niveau": item.item_level, "affixes": affixes}


## Renvoie null quand la base n'existe plus dans le projet. L'objet est alors
## ignoré et le reste du personnage se charge : perdre une épée est désagréable,
## perdre le personnage est inacceptable.
static func _item_depuis_dict(source: Variant) -> Item:
	if not source is Dictionary:
		return null
	var identifiant := String((source as Dictionary).get("base", ""))
	var base := ItemCatalog.by_id(identifiant)
	if base == null:
		push_warning("Base d'objet inconnue « %s » : objet ignoré." % identifiant)
		return null

	var explicits: Array[StatMod] = []
	for a in _liste((source as Dictionary).get("affixes")):
		if not a is Dictionary:
			continue
		var stat := String((a as Dictionary).get("stat", ""))
		if stat.is_empty():
			continue
		var mode := StatMod.Mode.PERCENT if _entier(a as Dictionary, "mode", 0) == StatMod.Mode.PERCENT else StatMod.Mode.FLAT
		explicits.append(StatMod.new(stat, mode, _reel(a as Dictionary, "valeur", 0.0)))
	# Absent, il vaut 1 : c'est le cas de tous les objets d'une sauvegarde de
	# version 1, et il n'y a pas de version à tester pour le savoir — un champ
	# manquant vaut son défaut, ici comme partout ailleurs dans cette fonction.
	var niveau := _entier(source as Dictionary, "niveau", 1)
	return Item.new(base, explicits, niveau)


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
