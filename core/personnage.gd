class_name Personnage
extends RefCounted

## Un personnage tel qu'il survit à la fermeture : nom, silhouette, progression, sac,
## équipement, manuels — jamais la partie ; le Player est son corps en scène.
## En JSON et non en Resource : une Resource exécute du code au chargement, et une
## sauvegarde peut venir de quelqu'un d'autre.

## Le numéro de format **écrit** ; il monte avec chaque champ nouveau.
const VERSION := 5

## Les numéros qu'on sait **lire** (invariant 7) ; un numéro inconnu est refusé.
## v1 → objets de niveau 1 ; v2 → râtelier vide, barre de départ, manuel pas encore
## offert ; v3 → rien ; v1 à v4 → dégâts plats convertis par `_ligne_actuelle`.
const VERSIONS_LUES := [1, 2, 3, 4, 5]

## Les dégâts plats d'avant le jalon 8, nommés ici pour être convertis.
const ANCIENS_DEGATS_D_ATTAQUE := "attack_damage"
const ANCIENS_DEGATS_DE_SORT := "spell_damage"

## Borné pour tenir sur une ligne de la sélection. Vingt et non seize : « Jean-Luc
## de l'Est » doit passer.
const NOM_MAX := 20

var id := ""
var nom := ""
## L'index de variante de la forge, pas un chemin de sprite.
var silhouette := 0
var cree_le := ""
var joue_le := ""

var niveau := 1
var experience := 0

## Ce qui a été **placé**, pas le total : un rééquilibrage doit atteindre les
## personnages existants.
var attributs := CharacterStats.empty_attributes()
## Sauvegardé aussi : monter de niveau puis quitter sans répartir ne doit pas
## coûter les points.
var points_a_placer := 0

var sac := Inventory.new(Inventory.DEFAULT_COLS, Inventory.DEFAULT_ROWS)
## Les emplacements sont validés par le Player, pas ici.
var equipement := {}

## Écrits ici et nulle part ailleurs, sinon deux vérités sur leurs points.
var ratelier := Ratelier.new()

## Par défaut celle de départ, ce que devient aussi une sauvegarde v2.
var barre := BarreDeCompetences.par_defaut()

## Sauvegardé et non déduit du sac : un joueur qui jette le sien n'en reçoit pas un
## second.
var manuel_offert := false

## Un fichier qu'on n'a pas su lire : montré grisé plutôt que disparu.
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


## Généré, jamais dérivé du nom (homonymes, caractères interdits). Tiré sur le
## générateur global et non sur Game.rng (invariant 3).
static func nouvel_id() -> String:
	return "p_%d_%04d" % [int(Time.get_unix_time_from_system()), randi() % 10000]


## Sans caractères de contrôle, invisibles mais écrits dans le fichier.
static func nom_valide(p_nom: String) -> bool:
	var n := p_nom.strip_edges()
	if n.is_empty() or n.length() > NOM_MAX:
		return false
	for i in n.length():
		var code := n.unicode_at(i)
		if code < 32 or code == 127:
			return false
	return true


## Aucune statistique calculée : elles se recalculent au chargement.
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

	# Trois entrées même vides : le fichier se relit sans deviner laquelle manquait.
	var livres := []
	for item in ratelier.manuels:
		livres.append(_item_vers_dict(item) if item != null and item.base != null else null)

	# Une case vide s'écrit null : « rien » y ressemble à rien.
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


## **Le seul endroit** qui fait confiance à des données du dehors : tout est
## reconverti (le JSON n'a qu'un type de nombre). Null si inexploitable ; un champ
## absent reprend son défaut plutôt que de perdre le personnage.
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

	# Champ par champ depuis ATTRIBUTES : un attribut nouveau part de zéro, un nom
	# inconnu est ignoré.
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

	# Clé absente : la barre de départ (sauvegarde d'avant le jalon 6). Clé présente :
	# ce qu'elle dit, cases vides comprises.
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


## La base par identifiant et les affixes résolus, jamais la base elle-même : elle
## figerait l'équilibrage du jour.
static func _item_vers_dict(item: Item) -> Dictionary:
	var affixes := []
	for r in item.explicits:
		var entree := {"stat": r.mod.stat, "mode": int(r.mod.mode), "valeur": r.mod.value}
		# Écrite, jamais déduite de l'affixe d'origine : un objet sans provenance perdrait
		# sa portée.
		if not r.mod.portee.is_empty():
			entree["portee"] = r.mod.portee
		if r.mod.est_une_fourchette():
			entree["valeur_max"] = r.mod.value_max
		# La provenance seulement quand on l'a : pas de palier inventé.
		if r.connu():
			entree["affixe"] = r.affix_id
			entree["tier"] = r.tier
		affixes.append(entree)
	var entree := {"base": item.base.id, "niveau": item.item_level, "affixes": affixes}
	# Le niveau d'un manuel ne s'écrit pas : il se déduit de son expérience.
	if item.manuel != null:
		entree["manuel"] = {
			"exp": item.manuel.experience,
			"points": item.manuel.points.duplicate(),
		}
	return entree


## Null quand la base n'existe plus : l'objet est ignoré, le personnage se charge.
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
		# La valeur fait foi : sans provenance, la ligne s'applique quand même. Une ligne
		# **convertie** perd la sienne.
		var convertie := actuelle != mod
		explicits.append(RolledAffix.new(
			"" if convertie else String(ligne.get("affixe", "")),
			0 if convertie else maxi(_entier(ligne, "tier", 0), 0),
			actuelle
		))
	# Absent, il vaut 1 : tous les objets d'une sauvegarde v1.
	var niveau := _entier(objet, "niveau", 1)
	var item := Item.new(base, explicits, niveau)
	_manuel_depuis_dict(item, objet.get("manuel"))
	return item


## Une ligne d'avant les fourchettes (jalon 8) : elle-même, sa conversion, ou null
## quand plus rien ne l'applique. **Équivalence exacte** avec le jeu d'alors — la
## seule attaque était physique, tous les sorts de foudre ; seuls les pourcentages
## de `meurtrier` n'ont plus d'équivalent. Testée sur le nom, pas sur la version.
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
		# « Ce livre le connaît-il », pour les trois sortes : des points hors de
		# l'archétype ne se dépensent nulle part, et `enseigne()` jetterait les arbres.
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
