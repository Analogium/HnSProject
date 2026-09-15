class_name BenchProfiles

## Les personnages types du banc d'équilibrage, **reconstruits par les règles du jeu** à
## chaque lancement : une sauvegarde écrite à la main garderait les objets du jour où
## elle a été faite (hack-n-slash-jalon-13.md, §2).

const ZONE := preload("res://world/zone.gd")

## Décidé le 15 septembre 2026.
const ZONES := [1, 10, 20, 40, 60, 90, 120]

enum Profile { BEGINNER, BARE, UNDER_EQUIPPED, EQUIPPED, OVER_EQUIPPED }
const PROFILE_NAMES := ["Débutant", "Nu", "Sous-équipé", "Équipé", "Sur-équipé"]
## Le niveau des objets portés, par rapport à la zone ; null : rien.
const ITEM_GAP := [null, null, -20, 0, 30]

## Le personnage n'a pas de niveau maximal ; `Progression` en demande un.
const LEVEL_CAP := 1000

## Assez de tirages pour que la moyenne d'expérience d'une zone ne bouge plus au
## centième ; la graine fige le résultat d'un lancement à l'autre.
const AFFIX_ROLLS := 4000
const AFFIX_SEED := 1313

## La graine d'équipement hache l'identifiant qu'avait le build avant la traduction du
## code : le changer rebat tous les objets du banc, et déplace les couloirs.
const SEED_KEYS := {"spell": "sort"}


class Build:
	var id: String
	var name: String
	var manual: String
	var attribute: String
	## Où vont les points du manuel, chaque entrée remplie avant la suivante. Les
	## compétences y forment la barre, dans cet ordre.
	var order: PackedStringArray
	## L'étiquette d'objet de l'autre build : une épée ne va pas à un sort.
	var excluded_one: String

	func _init(
		p_id: String, p_name: String, p_manual: String, p_attribute: String,
		p_order: PackedStringArray, p_excluded: String
	) -> void:
		id = p_id
		name = p_name
		manual = p_manual
		attribute = p_attribute
		order = p_order
		excluded_one = p_excluded


## Une combinaison d'affixes d'ennemi et la part des tirages qui la donnent.
class RolledAffixes:
	var affixes: Array[Affix]
	var part: float


static var _experience_per_zone := {}
static var _rolls: Array[RolledAffixes] = []


## Les compétences en tête ; ce qui est ouvert au niveau 1 du manuel en fin, pour
## qu'un débutant ait de quoi lancer.
static func builds() -> Array[Build]:
	return [
		Build.new("spell", "Sort", "manual_lightning", "intelligence", PackedStringArray([
			"chain_lightning", "lightning_nova", "storm_cloud", "conductor",
			"swift_bolt", "chain_lightning_branching",
		]), "melee"),
		Build.new("melee", "Mêlée", "manual_weapons", "strength", PackedStringArray([
			"heavy_strike", "cross_slash", "spiral_sword", "iron_guard",
			"heavy_strike_momentum",
		]), "caster"),
	] as Array[Build]


static func character(build: Build, profile: Profile, zone: int) -> Character:
	var p := Character.create_new("%s %s %d" % [build.name, PROFILE_NAMES[profile], zone], 0)
	var experience := 0
	if profile != Profile.BEGINNER:
		var expected := expected_level(zone)
		p.level = expected.x
		experience = expected.y
		p.experience = Progression.progress(
			experience, Player.XP_BASE, Player.XP_POWER, LEVEL_CAP
		).x
	p.attributes[build.attribute] = (p.level - 1) * Player.POINTS_PER_LEVEL
	p.manual_given = true

	# Le manuel gagne ce que gagne le personnage : `Player.reward()` leur verse le
	# même montant.
	var book := Item.new(ItemCatalog.by_id(build.manual))
	var archetype := book.base.manual
	book.manual.gain_experience(experience)
	p.bar = SkillBar.new()
	var cell := 0
	for id in build.order:
		while book.manual.invest(archetype, id):
			pass
		if archetype.cell_of(id) != null and book.manual.points_of(id) > 0:
			p.bar.put(cell, id)
			cell += 1
	p.rack.put(0, book)

	var level := item_level_for(profile, zone)
	if level > 0:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([SEED_KEYS.get(build.id, build.id), profile, zone])
		_equip(p, build, level, rng)
	return p


## Zéro pour un profil qui ne porte rien.
static func item_level_for(profile: Profile, zone: int) -> int:
	if ITEM_GAP[profile] == null:
		return 0
	return clampi(zone + int(ITEM_GAP[profile]), Game.MIN_LEVEL, Game.MAX_LEVEL)


## Un objet par emplacement, tiré comme `LootTable.roll()` le tire — base au hasard parmi
## ce qui tombe, puis ses affixes —, mais sur le tirage du profil (invariant 3).
static func _equip(p: Character, build: Build, level: int, rng: RandomNumberGenerator) -> void:
	for slot in EquipmentSlots.ids():
		var bases: Array[ItemBase] = []
		for base: ItemBase in ItemCatalog.available(level):
			if base.family == EquipmentSlots.family_of(slot) and not base.tags.has(build.excluded_one):
				bases.append(base)
		if bases.is_empty():
			continue
		var base := bases[rng.randi() % bases.size()]
		p.equipment[slot] = Item.new(base, ItemAffixPool.roll(rng, base, level), level)


## Le niveau (x) et l'expérience totale (y) d'un personnage qui a vidé une fois chaque
## zone de 1 à `zone` − 1. Le facteur de retard est pris à l'entrée de chaque zone.
static func expected_level(zone: int) -> Vector2i:
	var total := 0.0
	for z in range(1, zone):
		total += zone_experience(z) * Enemy.experience_factor(z, _level_of(roundi(total)))
	return Vector2i(_level_of(roundi(total)), roundi(total))


static func _level_of(experience: int) -> int:
	return Progression.reached_level(experience, Player.XP_BASE, Player.XP_POWER, LEVEL_CAP)


## Ce que rapporte une zone vidée une fois : la population moyenne de l'`EnemySpawner`,
## chaque ennemi par `Enemy.experience_of()`.
static func zone_experience(zone: int) -> float:
	if _experience_per_zone.has(zone):
		return _experience_per_zone[zone]
	var spawner := EnemySpawner.new()
	var count := spawner.pack_count * (spawner.pack_size_min + spawner.pack_size_max) * 0.5
	var weight := {ZONE.GRUNT_SCENE: spawner.grunt_weight, ZONE.CASTER_SCENE: spawner.caster_weight}
	var sum := float(spawner.grunt_weight + spawner.caster_weight)
	spawner.free()

	var per_enemy := 0.0
	for scene: PackedScene in weight:
		var base := base_sheet(scene)
		var average := 0.0
		for t in _affix_rolls():
			average += t.part * Enemy.experience_of(Enemy.sheet_of(base, zone, t.affixes), t.affixes)
		per_enemy += average * float(weight[scene]) / sum
	_experience_per_zone[zone] = per_enemy * count
	return _experience_per_zone[zone]


## Regroupés par combinaison : quelques dizaines de fiches par zone au lieu de milliers.
static func _affix_rolls() -> Array[RolledAffixes]:
	if not _rolls.is_empty():
		return _rolls
	var rng := RandomNumberGenerator.new()
	rng.seed = AFFIX_SEED
	var by_key := {}
	for i in AFFIX_ROLLS:
		var affixes := AffixPool.roll(rng)
		var key := ",".join(PackedStringArray(affixes.map(func(a: Affix) -> String: return a.id)))
		if not by_key.has(key):
			var t := RolledAffixes.new()
			t.affixes = affixes
			by_key[key] = t
		by_key[key].part += 1.0 / AFFIX_ROLLS
	_rolls.assign(by_key.values())
	return _rolls


## La fiche du `.tres` que porte la scène : lue sur le corps, pas recopiée à côté.
static func base_sheet(scene: PackedScene) -> CharacterStats:
	var body: Enemy = scene.instantiate()
	var sheet := body.stats
	body.free()
	return sheet
