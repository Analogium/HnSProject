class_name ProfilsDuBanc

## Les personnages types du banc d'équilibrage, **reconstruits par les règles du jeu** à
## chaque lancement : une sauvegarde écrite à la main garderait les objets du jour où
## elle a été faite (hack-n-slash-jalon-13.md, §2).

const ZONE := preload("res://world/zone.gd")

## Décidé le 15 septembre 2026.
const ZONES := [1, 10, 20, 40, 60, 90, 120]

enum Profil { DEBUTANT, NU, SOUS_EQUIPE, EQUIPE, SUR_EQUIPE }
const NOMS_DE_PROFIL := ["Débutant", "Nu", "Sous-équipé", "Équipé", "Sur-équipé"]
## Le niveau des objets portés, par rapport à la zone ; null : rien.
const ECART_D_OBJET := [null, null, -20, 0, 30]

## Le personnage n'a pas de niveau maximal ; `Progression` en demande un.
const NIVEAU_PLAFOND := 1000

## Assez de tirages pour que la moyenne d'expérience d'une zone ne bouge plus au
## centième ; la graine fige le résultat d'un lancement à l'autre.
const TIRAGES_D_AFFIXES := 4000
const GRAINE_D_AFFIXES := 1313


class Build:
	var id: String
	var nom: String
	var manuel: String
	var attribut: String
	## Où vont les points du manuel, chaque entrée remplie avant la suivante. Les
	## compétences y forment la barre, dans cet ordre.
	var ordre: PackedStringArray
	## L'étiquette d'objet de l'autre build : une épée ne va pas à un sort.
	var ecarte: String

	func _init(
		p_id: String, p_nom: String, p_manuel: String, p_attribut: String,
		p_ordre: PackedStringArray, p_ecarte: String
	) -> void:
		id = p_id
		nom = p_nom
		manuel = p_manuel
		attribut = p_attribut
		ordre = p_ordre
		ecarte = p_ecarte


## Une combinaison d'affixes d'ennemi et la part des tirages qui la donnent.
class AffixesTires:
	var affixes: Array[Affix]
	var part: float


static var _experience_par_zone := {}
static var _tirages: Array[AffixesTires] = []


## Les compétences en tête ; ce qui est ouvert au niveau 1 du manuel en fin, pour
## qu'un débutant ait de quoi lancer.
static func builds() -> Array[Build]:
	return [
		Build.new("sort", "Sort", "manuel_foudre", "intelligence", PackedStringArray([
			"chaine_d_eclairs", "nova_de_foudre", "nuage_d_orage", "conducteur",
			"eclair_vif", "chaine_d_eclairs_ramification",
		]), "melee"),
		Build.new("melee", "Mêlée", "manuel_armes", "strength", PackedStringArray([
			"frappe_lourde", "coup_en_croix", "epee_spirale", "garde_de_fer",
			"frappe_lourde_elan",
		]), "caster"),
	] as Array[Build]


static func personnage(build: Build, profil: Profil, zone: int) -> Personnage:
	var p := Personnage.nouveau("%s %s %d" % [build.nom, NOMS_DE_PROFIL[profil], zone], 0)
	var experience := 0
	if profil != Profil.DEBUTANT:
		var attendu := niveau_attendu(zone)
		p.niveau = attendu.x
		experience = attendu.y
		p.experience = Progression.avancement(
			experience, Player.XP_BASE, Player.XP_POWER, NIVEAU_PLAFOND
		).x
	p.attributs[build.attribut] = (p.niveau - 1) * Player.POINTS_PER_LEVEL
	p.manuel_offert = true

	# Le manuel gagne ce que gagne le personnage : `Player.recompenser()` leur verse le
	# même montant.
	var livre := Item.new(ItemCatalog.by_id(build.manuel))
	var archetype := livre.base.manuel
	livre.manuel.gagner_experience(experience)
	p.barre = BarreDeCompetences.new()
	var case := 0
	for id in build.ordre:
		while livre.manuel.investir(archetype, id):
			pass
		if archetype.case_de(id) != null and livre.manuel.points_de(id) > 0:
			p.barre.poser(case, id)
			case += 1
	p.ratelier.poser(0, livre)

	var niveau := niveau_d_objet(profil, zone)
	if niveau > 0:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([build.id, profil, zone])
		_equiper(p, build, niveau, rng)
	return p


## Zéro pour un profil qui ne porte rien.
static func niveau_d_objet(profil: Profil, zone: int) -> int:
	if ECART_D_OBJET[profil] == null:
		return 0
	return clampi(zone + int(ECART_D_OBJET[profil]), Game.NIVEAU_MIN, Game.NIVEAU_MAX)


## Un objet par emplacement, tiré comme `LootTable.roll()` le tire — base au hasard parmi
## ce qui tombe, puis ses affixes —, mais sur le tirage du profil (invariant 3).
static func _equiper(p: Personnage, build: Build, niveau: int, rng: RandomNumberGenerator) -> void:
	for emplacement in EquipmentSlots.ids():
		var bases: Array[ItemBase] = []
		for base: ItemBase in ItemCatalog.disponibles(niveau):
			if base.family == EquipmentSlots.family_of(emplacement) and not base.tags.has(build.ecarte):
				bases.append(base)
		if bases.is_empty():
			continue
		var base := bases[rng.randi() % bases.size()]
		p.equipement[emplacement] = Item.new(base, ItemAffixPool.roll(rng, base, niveau), niveau)


## Le niveau (x) et l'expérience totale (y) d'un personnage qui a vidé une fois chaque
## zone de 1 à `zone` − 1. Le facteur de retard est pris à l'entrée de chaque zone.
static func niveau_attendu(zone: int) -> Vector2i:
	var total := 0.0
	for z in range(1, zone):
		total += experience_d_une_zone(z) * Enemy.facteur_d_experience(z, _niveau_de(roundi(total)))
	return Vector2i(_niveau_de(roundi(total)), roundi(total))


static func _niveau_de(experience: int) -> int:
	return Progression.niveau_atteint(experience, Player.XP_BASE, Player.XP_POWER, NIVEAU_PLAFOND)


## Ce que rapporte une zone vidée une fois : la population moyenne de l'`EnemySpawner`,
## chaque ennemi par `Enemy.experience_de()`.
static func experience_d_une_zone(zone: int) -> float:
	if _experience_par_zone.has(zone):
		return _experience_par_zone[zone]
	var spawner := EnemySpawner.new()
	var nombre := spawner.pack_count * (spawner.pack_size_min + spawner.pack_size_max) * 0.5
	var poids := {ZONE.GRUNT_SCENE: spawner.grunt_weight, ZONE.CASTER_SCENE: spawner.caster_weight}
	var somme := float(spawner.grunt_weight + spawner.caster_weight)
	spawner.free()

	var par_ennemi := 0.0
	for scene: PackedScene in poids:
		var base := fiche_de_base(scene)
		var moyenne := 0.0
		for t in _tirages_d_affixes():
			moyenne += t.part * Enemy.experience_de(Enemy.fiche_de(base, zone, t.affixes), t.affixes)
		par_ennemi += moyenne * float(poids[scene]) / somme
	_experience_par_zone[zone] = par_ennemi * nombre
	return _experience_par_zone[zone]


## Regroupés par combinaison : quelques dizaines de fiches par zone au lieu de milliers.
static func _tirages_d_affixes() -> Array[AffixesTires]:
	if not _tirages.is_empty():
		return _tirages
	var rng := RandomNumberGenerator.new()
	rng.seed = GRAINE_D_AFFIXES
	var par_cle := {}
	for i in TIRAGES_D_AFFIXES:
		var affixes := AffixPool.roll(rng)
		var cle := ",".join(PackedStringArray(affixes.map(func(a: Affix) -> String: return a.id)))
		if not par_cle.has(cle):
			var t := AffixesTires.new()
			t.affixes = affixes
			par_cle[cle] = t
		par_cle[cle].part += 1.0 / TIRAGES_D_AFFIXES
	_tirages.assign(par_cle.values())
	return _tirages


## La fiche du `.tres` que porte la scène : lue sur le corps, pas recopiée à côté.
static func fiche_de_base(scene: PackedScene) -> CharacterStats:
	var corps: Enemy = scene.instantiate()
	var fiche := corps.stats
	corps.free()
	return fiche
