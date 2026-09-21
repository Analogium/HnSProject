class_name BenchProfiles

## Les personnages types du banc d'équilibrage, **reconstruits par les règles du jeu** à
## chaque lancement : une sauvegarde écrite à la main garderait les objets du jour où
## elle a été faite (JALONS/hack-n-slash-jalon-13.md, §2).

const ZONE := preload("res://world/zone.gd")

## Décidé le 15 septembre 2026.
const ZONES := [1, 10, 20, 40, 60, 90, 120]

enum Profile { BEGINNER, BARE, UNDER_EQUIPPED, EQUIPPED, OVER_EQUIPPED }
const PROFILE_NAMES := ["Débutant", "Nu", "Sous-équipé", "Équipé", "Sur-équipé"]
## Le niveau des objets portés, par rapport à la zone ; null : rien.
const ITEM_GAP := [null, null, -20, 0, 30]

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
	## Les nœuds de l'arbre de passifs, pris dans l'ordre tant qu'il reste des points.
	var path: PackedStringArray
	## Où vont les points du manuel, chaque entrée remplie avant la suivante. Les
	## compétences y forment la barre, dans cet ordre.
	var order: PackedStringArray
	## L'étiquette d'objet de l'autre build : une épée ne va pas à un sort.
	var excluded_one: String

	func _init(
		p_id: String, p_name: String, p_manual: String, p_path: PackedStringArray,
		p_order: PackedStringArray, p_excluded: String
	) -> void:
		id = p_id
		name = p_name
		manual = p_manual
		path = p_path
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
		# Orage, Sorts et Savoir, puis l'Esprit d'orage ; ensuite la réserve, l'onde, l'esquive
		# et, par l'anneau intérieur, la chair.
		Build.new("spell", "Sort", "manual_lightning", PackedStringArray([
			"int_1", "int_2", "int_3", "int_4", "int_5",
			"storm_1", "storm_2", "storm_3", "quick_lightning", "storm_4", "storm_5", "storm_crash",
			"int_6", "int_7", "outer_str_int_6", "outer_str_int_5",
			"spells_1", "spells_2", "spells_3", "spells_4", "sharp_incantation", "spells_5", "spells_6",
			"outer_int_dex_1", "outer_int_dex_2", "outer_int_dex_3",
			"lore_1", "lore_2", "lore_3", "lore_4", "arcane_lore", "lore_5", "lore_6",
			"int_8", "int_9", "int_10", "storm_mind",
			"outer_str_int_4", "reserve_1", "reserve_2", "reserve_3", "reserve_4", "mana_well",
			"wave_1", "wave_2", "wave_3", "wave_4", "wide_wave", "wave_5", "wave_6",
			"outer_int_dex_4", "outer_int_dex_5", "breath_1", "breath_2", "breath_3", "breath_4", "reflexes",
			"inner_str_int_3", "inner_str_int_2", "inner_str_int_1", "str_3", "str_4", "str_5",
			"flesh_1", "flesh_2", "flesh_3", "flesh_4", "sturdy_blood",
		]), PackedStringArray([
			"chain_lightning", "lightning_nova", "storm_cloud", "conductor",
			"swift_bolt", "chain_lightning_branching",
		]), "melee"),
		# Frappe, Chair et Plaques, puis le Colosse ; ensuite les armes, la plaie et la
		# repousse.
		Build.new("melee", "Mêlée", "manual_weapons", PackedStringArray([
			"str_1", "str_2", "str_3", "str_4", "str_5",
			"strike_1", "strike_2", "strike_3", "strike_4", "brute_force", "strike_5", "strike_6",
			"flesh_1", "flesh_2", "flesh_3", "flesh_4", "sturdy_blood", "flesh_5", "flesh_6",
			"str_6", "str_7", "outer_str_int_1", "outer_str_int_2",
			"plates_1", "plates_2", "plates_3", "plates_4", "iron_skin", "plates_5", "plates_6",
			"str_8", "str_9", "str_10", "colossus",
			"outer_dex_str_6", "outer_dex_str_5",
			"arms_1", "arms_2", "arms_3", "arms_4", "weapon_master", "arms_5", "arms_6",
			"wound_1", "wound_2", "wound_3", "wound_4", "open_wound", "wound_5", "wound_6",
			"outer_dex_str_4", "regrowth_1", "regrowth_2", "regrowth_3", "regrowth_4", "regrowing_flesh",
		]), PackedStringArray([
			"heavy_strike", "cross_slash", "spiral_sword", "iron_guard",
			"heavy_strike_momentum",
		]), "caster"),
	] as Array[Build]


## `draw` choisit le tirage d'objets ; le 0 garde la graine d'avant les tirages multiples.
static func character(build: Build, profile: Profile, zone: int, draw := 0) -> Character:
	var p := Character.create_new("%s %s %d" % [build.name, PROFILE_NAMES[profile], zone], 0)
	var experience := 0
	if profile != Profile.BEGINNER:
		var expected := expected_level(zone)
		p.level = expected.x
		experience = expected.y
		p.experience = Progression.progress(
			experience, Player.XP_BASE, Player.XP_POWER, Player.MAX_LEVEL
		).x
	var tree := PassiveTree.shared()
	var taken := PackedStringArray()
	for id in build.path:
		if tree.can_take(taken, id, p.level):
			taken.append(id)
	p.passives = taken
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
		var key := [SEED_KEYS.get(build.id, build.id), profile, zone]
		if draw > 0:
			key.append(draw)
		rng.seed = hash(key)
		_equip(p, build, level, rng)
	else:
		# Le débutant garde l'arme nue de départ, celle de sa voie.
		var melee := build.excluded_one == ItemBase.CASTER_TAG
		p.equipment[EquipmentSlots.WEAPON] = Item.new(ItemCatalog.by_id(
			ItemCatalog.ID_STARTING_WEAPON if melee else ItemCatalog.ID_STARTING_WAND
		))
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
		p.equipment[slot] = Item.rolled(rng, base, level)


## Le niveau (x) et l'expérience totale (y) d'un personnage qui a vidé une fois chaque
## zone de 1 à `zone` − 1. Le facteur de retard est pris à l'entrée de chaque zone.
static func expected_level(zone: int) -> Vector2i:
	var total := 0.0
	for z in range(1, zone):
		total += zone_experience(z) * Enemy.experience_factor(z, _level_of(roundi(total)))
	return Vector2i(_level_of(roundi(total)), roundi(total))


static func _level_of(experience: int) -> int:
	return Progression.reached_level(experience, Player.XP_BASE, Player.XP_POWER, Player.MAX_LEVEL)


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
