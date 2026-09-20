extends GutTest

const Weapons := preload("res://tests/weapons.gd")

## Le joueur monté dans l'arbre : réserve de mana, régénérations, équipement et
## recalcul de la fiche. Rien de tout ça n'existe hors scène.

var _p: Player
## Retenu et pas seulement branché : le test des dégâts de sort a besoin d'aller
## regarder le tir qui vient d'en sortir.
var _bolts_fired: Node2D


func before_each() -> void:
	_p = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_p)
	# Un parent dédié pour les tirs : sans lui ils naissent sous le script de
	# test et y restent après coup, ce que GUT signale en enfants non libérés.
	_bolts_fired = Node2D.new()
	add_child_autofree(_bolts_fired)
	_p.projectile_parent = _bolts_fired
	await wait_physics_frames(1)


## Les valeurs sont exprimées à partir des constantes de dérivation et non en
## dur : un recalibrage des attributs ne doit pas faire échouer un test qui ne
## parle pas de calibrage.
func test_full_pool_at_spawn() -> void:
	var expected := 50.0 + 10.0 * CharacterStats.MANA_PER_INTELLIGENCE
	assert_eq(_p.stats.max_mana, expected, "réserve de base plus l'intelligence")
	assert_eq(_p.mana, _p.stats.max_mana, "full")
	assert_eq(_p.health, _p.stats.max_health, "en pleine santé")


func test_the_bolt_costs_mana() -> void:
	_p.equip(Weapons.bare(true), EquipmentSlots.WEAPON)
	var before := _p.mana
	_p.cast_slot(1)
	assert_eq(
		_p.mana, before - SkillCatalog.by_id(SkillCatalog.ID_BOLT).mana_cost,
		"le coût exact, pas un de plus"
	)


## La nature du tir est écrite à deux endroits tant que la bille porte la sienne :
## sur la compétence, et sur la scène du projectile. Elles disent aujourd'hui la
## même chose, et ce test est ce qui l'exige — le jour où la compétence deviendra
## seule à décider, il tombera de lui-même.
func test_the_bolt_nature_does_not_diverge_from_the_pellet() -> void:
	# Hors de l'arbre : montée, la bille avancerait et se libérerait toute seule.
	var pellet: Projectile = load("res://actors/projectiles/player_bolt.tscn").instantiate()
	var nature: int = pellet.damage_type
	pellet.free()
	assert_eq(
		SkillCatalog.by_id(SkillCatalog.ID_BOLT).nature, nature,
		"« %s » et la bille annoncent la même nature" % SkillCatalog.by_id(SkillCatalog.ID_BOLT).name
	)


func test_insufficient_pool_refuses_the_bolt() -> void:
	_p.equip(Weapons.bare(true), EquipmentSlots.WEAPON)
	_p._set_mana(2.0)
	_p.cast_slot(1)
	assert_eq(_p.mana, 2.0, "ni tir, ni prélèvement partiel")


func test_regenerations() -> void:
	_p._set_mana(10.0)
	_p._regen(1.0)
	var regen := 4.0 + 10.0 * CharacterStats.MANA_REGEN_PER_INTELLIGENCE
	assert_eq(_p.mana, 10.0 + regen, "régénération de base plus ce que l'intelligence rapporte")
	_p._set_health(50.0)
	_p._regen(1.0)
	assert_eq(_p.health, 51.0, "1 PV par seconde")


func test_regeneration_does_not_exceed_the_cap() -> void:
	_p._regen(10.0)
	assert_eq(_p.health, _p.stats.max_health)
	assert_eq(_p.mana, _p.stats.max_mana)


## La hurtbox reçoit la fiche courante, pas une copie périmée : recompute_stats
## en fabrique une neuve à chaque équipement.
func test_the_hurtbox_follows_the_sheet() -> void:
	assert_eq(_p.hurtbox.stats, _p.stats, "à la naissance")
	_p.equip(Item.new(load("res://resources/items/breastplate.tres")))
	assert_eq(_p.hurtbox.stats, _p.stats, "après un équipement")
	_p.unequip("chest")
	assert_eq(_p.hurtbox.stats, _p.stats, "après un retrait")


func test_the_wand_speeds_up_casting_not_the_blade() -> void:
	var swing := _p.stats.attack_time
	var casting := _p.stats.cast_speed
	_p.equip(Item.new(load("res://resources/items/wand.tres")))
	# Aucun attribut ne donne de cadence d'incantation : l'arme est la seule source ici.
	assert_eq(casting, 1.0, "nue, la fiche incante à 100 %")
	assert_almost_eq(_p.stats.cast_speed, casting * 1.15, 0.001, "+15 %")
	assert_eq(_p.stats.attack_time, swing, "le corps à corps est intact")


## Le cœur du système d'équipement : un objet retiré ne laisse rien derrière lui,
## parce que recompute_stats repart toujours de la ressource du disque.
func test_a_removed_item_leaves_nothing() -> void:
	var hp := _p.stats.max_health
	var mod := StatMod.new("armor", StatMod.Mode.FLAT, 40.0)
	_p.equip(Item.new(load("res://resources/items/breastplate.tres"), [mod]))
	assert_eq(_p.stats.armor, 40.0)
	_p.unequip("chest")
	assert_eq(_p.stats.armor, 0.0)
	assert_eq(_p.stats.max_health, hp, "l'implicite est parti aussi")


## Retirer un plastron baisse le plafond : la vie courante doit le suivre, sinon
## la barre déborde et le joueur garde des PV qu'il n'a plus.
func test_hp_go_back_under_the_new_cap() -> void:
	var without_breastplate := _p.stats.max_health
	_p.equip(Item.new(load("res://resources/items/breastplate.tres")))
	_p._set_health(_p.stats.max_health)
	assert_gt(_p.health, without_breastplate, "le plastron a bien relevé le plafond")
	_p.unequip("chest")
	assert_eq(_p.health, without_breastplate, "la vie redescend avec le plafond")


## La ressource du disque n'est jamais écrite : aucun .tres du projet n'est
## resource_local_to_scene, l'y toucher contaminerait toutes les parties.
func test_the_disk_sheet_stays_intact() -> void:
	_p.equip(Item.new(
		load("res://resources/items/breastplate.tres"),
		[StatMod.new("max_health", StatMod.Mode.PERCENT, 50.0)]
	))
	var disk: CharacterStats = load("res://resources/stats/player_stats.tres")
	assert_eq(disk.max_health, 100.0, "le fichier n'a pas bougé")
	assert_ne(_p.stats, disk, "la copie de travail est distincte")


func test_a_full_bag_leaves_the_item_on_the_ground() -> void:
	var breastplate: ItemBase = load("res://resources/items/breastplate.tres")
	while _p.inventory.add(Item.new(breastplate)):
		pass
	assert_false(_p.pick_up(Item.new(breastplate)), "refusé, donc il reste au sol")


## Les attributs de départ arrivent bien dans la fiche, dérivation comprise.
func test_starting_attributes_are_derived() -> void:
	assert_eq(_p.stats.strength, 10.0)
	assert_eq(
		_p.stats.max_health, 100.0 + 10.0 * CharacterStats.HEALTH_PER_STRENGTH,
		"PV de base plus ce que la force rapporte"
	)
	assert_eq(
		_p.stats.max_mana, 50.0 + 10.0 * CharacterStats.MANA_PER_INTELLIGENCE,
		"réserve de base plus ce que l'intelligence rapporte"
	)
	assert_gt(_p.stats.evasion, 0.0, "la dextérité donne enfin une source à l'esquive")


func test_a_level_up_gives_a_tree_point() -> void:
	assert_eq(_p.remaining_passive_points(), 0, "aucun point au départ")
	_p.gain_xp(_p.xp_to_next)
	assert_eq(_p.level, 2)
	assert_eq(_p.remaining_passive_points(), 1)


## Au plafond l'expérience ne s'accumule plus, sinon la barre déborderait.
func test_the_level_stops_at_the_cap() -> void:
	_p.level = Player.MAX_LEVEL - 1
	_p.xp_to_next = _p._needed_for(_p.level)
	_p.gain_xp(_p.xp_to_next * 3)
	assert_eq(_p.level, Player.MAX_LEVEL)
	assert_eq(_p.xp, 0)
	assert_eq(_p.xp_to_next, 0)
	_p.gain_xp(1000)
	assert_eq(_p.level, Player.MAX_LEVEL, "rien au-delà")
	assert_eq(_p.xp, 0)


## start — force (+10 force) — colosse (+50 % de PV amplifiés), écrit ici : le contenu
## changera, la règle non.
func _small_tree() -> PassiveTree:
	var start := PassiveNode.new()
	start.id = "start"
	start.kind = PassiveNode.Kind.START
	var strength := PassiveNode.new()
	strength.id = "strength"
	strength.links = PackedStringArray(["start"])
	strength.lines = [_line("strength", 10.0)] as Array[TalentLine]
	var colossus := PassiveNode.new()
	colossus.id = "colossus"
	colossus.kind = PassiveNode.Kind.KEYSTONE
	colossus.links = PackedStringArray(["strength"])
	colossus.lines = [_line("max_health", 50.0, true, true)] as Array[TalentLine]
	var tree := PassiveTree.new()
	tree.nodes = [start, strength, colossus] as Array[PassiveNode]
	return tree


func _line(stat: String, value: float, percentage := false, more := false) -> TalentLine:
	var l := TalentLine.new()
	l.stat = stat
	l.value_per_point = value
	l.percentage = percentage
	l.more = more
	return l


func test_a_taken_node_changes_the_sheet_and_its_release_restores_it() -> void:
	_p.passive_tree = _small_tree()
	_p.gain_xp(_p.xp_to_next)
	var before := _p.stats.max_health
	assert_true(_p.take_passive("strength"))
	assert_eq(_p.stats.strength, 20.0)
	assert_eq(_p.stats.max_health, before + 10.0 * CharacterStats.HEALTH_PER_STRENGTH)
	assert_true(_p.release_passive("strength"))
	assert_eq(_p.stats.strength, 10.0)
	assert_eq(_p.stats.max_health, before)


func test_cannot_take_what_we_do_not_have() -> void:
	_p.passive_tree = _small_tree()
	assert_false(_p.take_passive("strength"), "aucun point au niveau 1")
	_p.gain_xp(_p.xp_to_next)
	assert_false(_p.take_passive("colossus"), "pas voisin d'un nœud pris")
	assert_false(_p.release_passive("strength"), "pas pris")
	assert_eq(_p.passives.size(), 0, "rien n'a été consommé")


## Le « plus » d'une clé de voûte multiplie après la somme des accrus des objets.
func test_a_more_keystone_multiplies_after_item_increases() -> void:
	_p.passive_tree = _small_tree()
	_p.gain_xp(_p.xp_to_next)
	_p.gain_xp(_p.xp_to_next)
	_p.take_passive("strength")
	_p.take_passive("colossus")
	_p.equip(Item.new(
		load("res://resources/items/breastplate.tres"),
		[StatMod.new("max_health", StatMod.Mode.PERCENT, 100.0)]
	))
	var expected := (100.0 + 20.0 * CharacterStats.HEALTH_PER_STRENGTH + 20.0) * 2.0 * 1.5
	assert_almost_eq(_p.stats.max_health, expected, 0.001, "base, force et implicite, doublés puis ×1,5")


## Les nœuds pris survivent à un recalcul : tenus sur le joueur et non sur `stats`,
## reconstruite de zéro à chaque équipement.
func test_taken_nodes_survive_equipping() -> void:
	_p.passive_tree = _small_tree()
	_p.gain_xp(_p.xp_to_next)
	_p.take_passive("strength")
	_p.equip(Item.new(load("res://resources/items/breastplate.tres")))
	_p.unequip("chest")
	assert_eq(_p.stats.strength, 20.0, "le nœud pris est toujours là")


## L'ordre du recalcul : les attributs doivent être définitifs avant qu'on en
## dérive quoi que ce soit, sinon un objet qui donne de la force ne rapporterait
## pas les points de vie correspondants.
func test_an_item_giving_strength_gives_the_matching_hp() -> void:
	var before := _p.stats.max_health
	_p.equip(Item.new(
		load("res://resources/items/breastplate.tres"),
		[StatMod.new("strength", StatMod.Mode.FLAT, 20.0)]
	))
	assert_eq(_p.stats.strength, 30.0)
	assert_eq(
		_p.stats.max_health,
		before + 20.0 + 20.0 * CharacterStats.HEALTH_PER_STRENGTH,
		"l'implicite du plastron, plus ce que les 20 de force rapportent"
	)


## Et la dérivation doit précéder les pourcentages, pour qu'un « +10 % PV »
## multiplie aussi ce que la force a donné.
func test_a_percentage_also_multiplies_strength_hp() -> void:
	_p.equip(Item.new(
		load("res://resources/items/breastplate.tres"),
		[StatMod.new("max_health", StatMod.Mode.PERCENT, 100.0)]
	))
	var expected := (
		100.0 + 10.0 * CharacterStats.HEALTH_PER_STRENGTH + 20.0
	) * 2.0
	assert_eq(_p.stats.max_health, expected, "base, force et implicite, tous doublés")


## Monter la force relève le plafond de vie : la barre doit suivre, sinon elle
## affiche un maximum que le joueur n'a pas.
func test_taking_a_node_does_not_break_the_bars() -> void:
	_p.passive_tree = _small_tree()
	_p.gain_xp(_p.xp_to_next)
	_p._set_health(10.0)
	_p.take_passive("strength")
	assert_eq(_p.health, 10.0, "la vie courante ne bouge pas")
	assert_lt(_p.health, _p.stats.max_health, "mais le plafond a monté")


# --------------------------------------------------------------------------
# Emplacements et familles (jalon 4)
# --------------------------------------------------------------------------

## Une base fabriquée en mémoire : les bases des dix familles arrivent à l'étape
## suivante du jalon, la règle d'équipement doit tenir avant elles.
func _ring_item(name: String) -> Item:
	var base := ItemBase.new()
	base.id = "test_" + name
	base.family = "ring"
	base.display_name = name
	base.kind = "sword"
	return Item.new(base)


## Le défaut que le jalon 4 vient corriger : avant, le second anneau écrasait le
## premier — silencieusement, puisque rien ne disait que le doigt était pris.
func test_two_rings_fit_on_two_fingers() -> void:
	var a := _ring_item("one")
	var b := _ring_item("two")
	assert_null(_p.equip(a), "rien à remplacer")
	assert_null(_p.equip(b), "le second n'en remplace aucun")
	assert_eq(_p.equipped("ring_left"), a)
	assert_eq(_p.equipped("ring_right"), b)
	assert_eq(_p.equipment.size(), 2)


## Lâché sur un emplacement précis, l'objet y va — même si l'autre doigt est
## libre. Sans ça, le panneau ne pourrait pas viser la main droite.
func test_a_forced_slot_is_respected() -> void:
	var a := _ring_item("one")
	_p.equip(a, "ring_right")
	assert_eq(_p.equipped("ring_right"), a)
	assert_null(_p.equipped("ring_left"), "le doigt gauche est resté libre")


func test_a_forced_slot_of_the_wrong_family_is_refused() -> void:
	var a := _ring_item("one")
	assert_eq(_p.equip(a, "amulet"), a, "rendu tel quel, jamais perdu")
	assert_eq(_p.equipment.size(), 0)


func test_an_item_without_family_is_returned_intact() -> void:
	var base := ItemBase.new()
	base.family = ""
	var pebble := Item.new(base)
	assert_eq(_p.equip(pebble), pebble)
	assert_eq(_p.equipment.size(), 0)


## Les deux doigts pris, on remplace celui de gauche et l'ancien revient à
## l'appelant : c'est lui qui décide s'il retourne au sac ou au sol.
func test_the_third_ring_returns_the_one_it_replaces() -> void:
	var a := _ring_item("one")
	_p.equip(a)
	_p.equip(_ring_item("two"))
	assert_eq(_p.equip(_ring_item("three")), a, "le premier doigt est rendu")
	assert_eq(_p.equipment.size(), 2, "toujours deux anneaux portés")


## Les dix emplacements entrent tous dans le calcul, pas seulement les deux
## d'avant : un bonus porté à un doigt doit se voir sur la fiche.
func test_a_ring_counts_in_the_sheet() -> void:
	var base := ItemBase.new()
	base.id = "test_ring_armor"
	base.family = "ring"
	base.implicit_stat = "armor"
	base.implicit_value = 12.0
	var before := _p.stats.armor
	_p.equip(Item.new(base))
	assert_eq(_p.stats.armor, before + 12.0, "l'implicite de l'anneau est entré")
	_p.unequip("ring_left")
	assert_eq(_p.stats.armor, before, "et il repart avec lui")


## L'invariant que l'affichage trahissait : la vie ne dépasse jamais le
## maximum, quel que soit le chemin qui a modifié la fiche. Le modèle était
## sain — c'était le texte qui mentait — et ce test est là pour qu'il le reste.
func test_health_never_exceeds_the_maximum() -> void:
	var breastplate := Item.new(load("res://resources/items/breastplate.tres"))
	_p.equip(breastplate)
	assert_lte(_p.health, _p.stats.max_health, "après avoir équipé")

	_p.gain_xp(3000)
	assert_lte(_p.health, _p.stats.max_health, "après plusieurs niveaux")

	_p.take_passive("str_1")
	assert_lte(_p.health, _p.stats.max_health, "après un nœud de force")

	_p.unequip("chest")
	assert_lte(_p.health, _p.stats.max_health, "et après avoir retiré le plastron")

	_p._regen(100.0)
	assert_eq(_p.health, _p.stats.max_health, "la régénération s'arrête pile au plafond")


## Le tir reçoit ce que l'équipement ajoute aux sorts. C'est cette ligne qui rend
## une arme d'incantation offensive : sans elle, une baguette n'aurait rien à
## donner à un sort.
func test_the_bolt_receives_what_equipment_adds_to_spells() -> void:
	_p.equip(Item.new(ItemCatalog.by_id("wand"), [
		StatMod.ranged("damage_lightning", 33.0, 33.0, Keywords.SPELL),
	]))
	_p.cast_slot(1)
	assert_eq(_bolts_fired.get_child_count(), 1, "un tir est parti")
	var bolt := _bolts_fired.get_child(0) as Projectile
	assert_not_null(bolt)
	assert_eq(bolt._parts[DamageType.Kind.LIGHTNING], 7.0 + 33.0, "sa table, plus la baguette")


## La force ajoute ses dégâts physiques aux attaques, et à elles seules : le Trait
## est un sort.
func test_strength_adds_physical_to_attacks_only() -> void:
	assert_gt(_p.stats.strength_damage(), 0.0, "la fiche de départ a de la force")
	var attack := _p.resolve(SkillCatalog.by_id(SkillCatalog.ID_ATTACK), 1)
	assert_almost_eq(
		attack.damage_min[DamageType.Kind.PHYSICAL], 12.0 + _p.stats.strength_damage(), 0.0001
	)
	assert_eq(_p.resolve(SkillCatalog.by_id(SkillCatalog.ID_BOLT), 1).damage_min[DamageType.Kind.PHYSICAL], 0.0)


## **La séparation des deux familles**, vue depuis le joueur : une épée ajoute ses
## dégâts à l'Attaque, et le Trait n'en voit rien.
func test_a_sword_adds_its_damage_to_the_attack_and_not_the_bolt() -> void:
	var sword := ItemCatalog.by_id("sword")
	var attack_before := _p.resolve(SkillCatalog.by_id(SkillCatalog.ID_ATTACK), 1)
	var bolt_before := _p.resolve(SkillCatalog.by_id(SkillCatalog.ID_BOLT), 1).total_max()
	_p.equip(Item.new(sword))
	var attack := _p.resolve(SkillCatalog.by_id(SkillCatalog.ID_ATTACK), 1)
	assert_almost_eq(attack.total_min(), attack_before.total_min() + sword.implicit_value, 0.0001)
	assert_almost_eq(attack.total_max(), attack_before.total_max() + sword.implicit_value_max, 0.0001)
	assert_eq(_p.resolve(SkillCatalog.by_id(SkillCatalog.ID_BOLT), 1).total_max(), bolt_before, "le Trait n'a rien reçu")


## Le personnage et les manuels montent sur la **même fonction**, avec leurs
## propres constantes. Deux exponentielles écrites côte à côte finiraient par
## diverger d'un arrondi, et personne ne saurait laquelle est la bonne.
func test_the_character_curve_is_the_shared_curve() -> void:
	for level in [1, 2, 7, 30]:
		assert_eq(
			_p._needed_for(level),
			Progression.level_cost(level, Player.XP_BASE, Player.XP_POWER),
			"le palier %d" % level
		)


# --------------------------------------------------------------------------
# La barre de compétences (jalon 6, étape 6)
# --------------------------------------------------------------------------

func _worked_book() -> Item:
	var book := Item.new(ItemCatalog.by_id("manual_lightning"))
	book.manual.gain_experience(999999)
	book.manual.invest(book.base.manual, "swift_bolt")
	return book


## Ce qu'on peut poser dans une case : les deux attaques de départ, et ce qu'on a
## réellement appris dans les livres à l'étude. Une case à zéro point n'y est pas
## — on ne propose pas de mettre sous les doigts ce qui ne fait rien.
func test_what_can_be_placed_in_a_slot() -> void:
	var names := []
	for c in _p.available_skills():
		names.append(c.id)
	assert_eq(names, [SkillCatalog.ID_ATTACK, SkillCatalog.ID_BOLT], "les deux de départ")

	_p.study(_worked_book())
	names = []
	for c in _p.available_skills():
		names.append(c.id)
	assert_true(names.has("swift_bolt"), "la case où l'on a mis un point")
	assert_false(names.has("storm_dash"), "mais pas celles restées vides")


func test_skill_points_come_from_the_book_that_teaches_it() -> void:
	assert_eq(_p.skill_points("swift_bolt"), 0, "aucun livre à l'étude")
	assert_eq(
		_p.skill_points(SkillCatalog.ID_ATTACK), 1,
		"les attaques de départ ne s'apprennent pas"
	)
	_p.study(_worked_book())
	assert_eq(_p.skill_points("swift_bolt"), 1)


## Le lancement porte lui-même ses refus : aucun appelant n'a à les
## refaire, et c'est ce qui permet à la touche, à la barre et aux tests de passer
## par le même chemin.
func test_cast_refuses_what_was_not_learned() -> void:
	_p.equip(Weapons.bare(true), EquipmentSlots.WEAPON)
	_p.bar.put(2, "swift_bolt")
	assert_false(_p.cast_slot(2), "la compétence n'est dans aucun livre à l'étude")
	assert_eq(_bolts_fired.get_child_count(), 0)

	_p.study(_worked_book())
	assert_true(_p.cast_slot(2), "le livre à l'étude la rend lançable")
	assert_eq(_bolts_fired.get_child_count(), 1)


## Une attaque veut une arme d'attaque, un sort une arme d'incantation ; sans arme,
## rien ne part.
func test_cast_refuses_a_skill_its_weapon_does_not_allow() -> void:
	var before := _p.mana
	assert_false(_p.cast_slot(1), "le tir, les mains vides")
	_p.equip(Weapons.bare(false), EquipmentSlots.WEAPON)
	assert_false(_p.cast_slot(1), "le tir, une épée en main")
	assert_eq(_p.mana, before, "sans rien payer")
	assert_true(_p.cast_slot(0), "le coup d'épée part")
	_p.equip(Weapons.bare(true), EquipmentSlots.WEAPON)
	assert_true(_p.cast_slot(1), "le tir, une baguette en main")


func test_cast_refuses_an_empty_slot_and_a_running_cooldown() -> void:
	_p.equip(Weapons.bare(true), EquipmentSlots.WEAPON)
	assert_false(_p.cast_slot(4), "la cinquième case est vide")
	assert_true(_p.cast_slot(1), "le tir part")
	assert_false(_p.cast_slot(1), "et ne repart pas tant qu'il se recharge")


## La couronne : huit projectiles sur un tour complet, chacun à son angle.
##
## Le lancer est monté à la main depuis que le jalon 20 a retiré la Nova de foudre :
## plus aucune compétence ne tire en cercle, et c'est `_roll()` qu'on juge — la
## branche du cercle fermé, où l'écart se divise par le nombre de traits et non par
## les intervalles.
func test_a_salvo_leaves_as_a_crown() -> void:
	_p._roll(_crown(8, 360.0), _p.bolt_scene)
	assert_eq(_bolts_fired.get_child_count(), 8, "huit traits")

	var angles := {}
	for bolt in _bolts_fired.get_children():
		angles[snappedf(rad_to_deg((bolt as Projectile)._dir.angle()), 0.1)] = true
	assert_eq(angles.size(), 8, "et ils ne partent pas deux au même endroit")


## Une salve de foudre, sans compétence derrière : ce que la fiche d'un lancer porte.
func _crown(count: int, spread: float) -> SkillStats:
	var cast := SkillStats.new()
	cast.nature = DamageType.Kind.LIGHTNING
	cast.projectiles = float(count)
	cast.spread_in_degrees = spread
	cast.projectile_speed = 200.0
	cast.place_the_base(cast.nature, 10.0)
	return cast


## Et l'autre bout : un projectile unique part **exactement** dans la visée.
##
## Le test manquait, et la répartition en éventail traitait le cas à part pour
## cette raison. Il tient maintenant tout seul — pas nul et départ nul font une
## rotation qui ne tourne pas — mais c'était vrai sans que rien ne le vérifie, et
## une dispersion recopiée par erreur sur le trait de base ferait tirer à côté de
## la souris sans qu'aucune assertion ne s'en aperçoive.
func test_a_single_bolt_flies_straight_along_the_aim() -> void:
	_p.equip(Weapons.bare(true), EquipmentSlots.WEAPON)
	_p.facing = Vector2(0.6, -0.8)
	assert_true(_p.cast_slot(1), "le tir de départ")
	assert_eq(_bolts_fired.get_child_count(), 1, "un seul trait")
	assert_eq(
		(_bolts_fired.get_child(0) as Projectile)._dir, _p.facing,
		"la direction de la visée, au bit près"
	)


# --------------------------------------------------------------------------
# Le lancer passe par la résolution (jalon 7, étape 3)
# --------------------------------------------------------------------------

## Un point dans chaque compétence du manuel de la foudre. Ses passifs sont
## laissés vides : ce test regarde ce qui **part**, et un passif ne part pas.
func _book_open_everywhere() -> Item:
	var book := Item.new(ItemCatalog.by_id("manual_lightning"))
	book.manual.gain_experience(999999)
	for skill in book.base.manual.skills():
		book.manual.invest(book.base.manual, skill.id)
	return book


## Les tirs lancés jusqu'ici, retirés tout de suite : le test suivant compte ceux
## de son propre lancer.
func _clear_bolts() -> void:
	for bolt in _bolts_fired.get_children():
		_bolts_fired.remove_child(bolt)
		bolt.free()


## **Le test qui garantit que l'étape n'a rien changé au jeu** : sans rien porter,
## chaque sort part avec exactement les nombres de sa fiche — combien de traits, à
## quelle vitesse, pour quels dégâts, quel coût et quelle recharge.
func test_each_spell_leaves_with_its_sheet_numbers() -> void:
	_p.equip(Weapons.bare(true), EquipmentSlots.WEAPON)
	_p.study(_book_open_everywhere())
	_p.stats.max_mana = 999.0

	for id in [SkillCatalog.ID_BOLT, "swift_bolt"]:
		var c := SkillCatalog.by_id(id)
		var points := _p.skill_points(id)
		assert_gt(points, 0, "« %s » est apprise" % c.name)
		_p.bar.put(4, id)
		_p._recharges[4] = 0.0
		_p._set_mana(999.0)
		_clear_bolts()

		assert_true(_p.cast_slot(4), "« %s » part" % c.name)
		assert_eq(_bolts_fired.get_child_count(), c.projectiles, "« %s » : traits" % c.name)
		for bolt: Projectile in _bolts_fired.get_children():
			assert_eq(bolt._parts[c.nature], c.damage(points), "« %s » : dégâts" % c.name)
			assert_eq(
				DamageInfo.as_parts(bolt._parts, Vector2.ZERO).amount, c.damage(points),
				"« %s » : et aucune autre nature" % c.name
			)
			assert_eq(bolt.speed, c.projectile_speed, "« %s » : vitesse" % c.name)
		assert_eq(_p.mana, 999.0 - c.mana_cost, "« %s » : coût" % c.name)
		# À la précision d'un réel sur 32 bits, qui est celle de `_recharges` : la
		# valeur rangée n'est pas celle calculée au bit près, et elle ne l'était pas
		# davantage avant la résolution.
		assert_almost_eq(
			_p.remaining_cooldown(4), c.interval(_p.stats), 1e-6, "« %s » : recharge" % c.name
		)


func test_a_bolt_with_one_more_projectile_fires_two() -> void:
	_p.equip(Weapons.bare(true), EquipmentSlots.WEAPON)
	_p.skill_mods.assign([
		StatMod.new("projectiles", StatMod.Mode.FLAT, 1.0, Keywords.PROJECTILE),
	])
	assert_true(_p.cast_slot(1), "le tir de départ")
	assert_eq(_bolts_fired.get_child_count(), 2, "deux traits")
	var a := (_bolts_fired.get_child(0) as Projectile)._dir
	var b := (_bolts_fired.get_child(1) as Projectile)._dir
	assert_almost_eq(
		rad_to_deg(absf(a.angle_to(b))), SkillStats.MIN_SPREAD, 0.01,
		"et ils ne partent pas l'un sur l'autre"
	)


## Une fourchette ajoutée se tire **par trait** : les traits d'une nova ne portent
## pas le même froid, sinon ils se liraient comme un coup recopié.
func test_each_bolt_rolls_its_range() -> void:
	var cast := _crown(8, 360.0)
	# Large exprès : deux tirages voisins d'une fourchette étroite s'arrondiraient au
	# même nombre, et le test dirait qu'un seul a été tiré.
	cast.add_to(DamageType.Kind.COLD, 1.0, 1000.0)
	_p._roll(cast, _p.bolt_scene)

	var colds := {}
	for bolt: Projectile in _bolts_fired.get_children():
		colds[bolt._parts[DamageType.Kind.COLD]] = true
	assert_eq(colds.size(), 8, "huit traits, huit tirages")


# --------------------------------------------------------------------------
# Les passifs et les talents (jalon 10)
# --------------------------------------------------------------------------

## Un livre au râtelier, monté au plafond, avec ces points placés **par le seul
## chemin** — celui qui recalcule la fiche.
func _study(base_id: String, points: Array, slot := 0) -> Item:
	var book := Item.new(ItemCatalog.by_id(base_id))
	book.manual.gain_experience(999999)
	_p.study(book, slot)
	for id: String in points:
		assert_true(_p.invest(slot, id), "« %s »" % id)
	return book


## **Un passif entre dans la fiche comme une pièce d'armure**, et par le même
## tri : ses lignes sans portée touchent le personnage, celles qui visent un
## mot-clé restent pour les compétences.
func test_a_rack_passive_enters_the_sheet() -> void:
	var armor := _p.stats.armor
	var hp := _p.stats.max_health
	_study("manual_weapons", ["iron_guard", "iron_guard"])

	assert_eq(_p.stats.armor, armor + 24.0, "deux points de douze")
	assert_eq(_p.stats.max_health, hp + 28.0, "et de quatorze PV")


## **Et il s'en va avec le livre.** Oublié, le bonus resterait sur la fiche
## jusqu'au prochain changement d'équipement, puis disparaîtrait sans que le
## joueur ait rien fait.
func test_a_passive_leaves_with_its_book() -> void:
	var armor := _p.stats.armor
	_study("manual_weapons", ["iron_guard"])
	assert_eq(_p.stats.armor, armor + 12.0)

	var gone := _p.stop_studying(0)
	assert_eq(_p.stats.armor, armor, "la fiche est revenue à ce qu'elle était")
	assert_eq(gone.manual.points_of("iron_guard"), 1, "et le livre a gardé son point")

	# Rangé dans le sac, il ne donne rien : le râtelier est le seul endroit où un
	# manuel agit, et c'est ce qui en fait un choix.
	assert_true(_p.inventory.add(gone))
	_p.recompute_stats()
	assert_eq(_p.stats.armor, armor, "un livre dans le sac ne donne rien")


## Un passif qui vise un mot-clé ne touche pas la fiche mais les compétences qui
## le portent — y compris celles d'un **autre** livre du râtelier.
func test_a_keyword_passive_serves_another_book_skills() -> void:
	var lightning := _study("manual_lightning", ["swift_bolt"], 0)
	var without := _p.resolve(SkillCatalog.by_id("swift_bolt"), 1).total_min()

	_study("manual_lightning", ["conductor", "conductor"], 1)
	var with_it := _p.resolve(SkillCatalog.by_id("swift_bolt"), 1).total_min()
	assert_almost_eq(with_it, without * 1.12, 0.01, "deux points de 6 % de dégâts de foudre")
	assert_eq(lightning.manual.points_of("conductor"), 0, "et le premier livre n'y est pour rien")


## **La conversion se voit** : ce que le sort pose part dans la nature d'arrivée,
## et sa couleur la dit. Sans cela, le nœud le plus cher de l'arbre ne se
## remarquerait qu'en lisant une fiche.
func test_a_conversion_node_changes_the_nature_of_what_leaves() -> void:
	_p.equip(Weapons.bare(true), EquipmentSlots.WEAPON)
	_study("manual_lightning", [
		"storm_cloud", "storm_cloud", "storm_cloud", "storm_cloud_hail",
	])
	_p.stats.max_mana = 999.0
	_p._set_mana(999.0)
	_p.bar.put(3, "storm_cloud")

	assert_true(_p.cast_slot(3))
	assert_eq(_bolts_fired.get_child_count(), 1)
	var cloud := _bolts_fired.get_child(0) as StormCloud
	var parts := cloud._cast.roll(Game.rng)
	assert_gt(
		parts[DamageType.Kind.COLD], parts[DamageType.Kind.LIGHTNING],
		"les trois cinquièmes sont du froid"
	)
	assert_eq(cloud._tint, DamageType.COLORS[DamageType.Kind.COLD], "et le nuage frappe en froid")


## Ce qu'un nœud ne change pas : un ajout d'objet ne déplace pas la couleur du
## tir. C'est la décision du jalon 8 — un éclair reste un éclair — et elle tient
## parce que la nature montrée ne regarde que la base et les conversions.
func test_an_item_does_not_change_the_bolt_color() -> void:
	_p.equip(Weapons.bare(true), EquipmentSlots.WEAPON)
	_study("manual_lightning", ["swift_bolt"])
	_p.skill_mods.assign([
		StatMod.ranged("damage_cold", 900.0, 900.0, Keywords.SPELL),
	])
	_p.bar.put(3, "swift_bolt")
	assert_true(_p.cast_slot(3))
	var bolt := _bolts_fired.get_child(0) as Projectile
	assert_gt(bolt._parts[DamageType.Kind.COLD], bolt._parts[DamageType.Kind.LIGHTNING])
	assert_eq(bolt._nature, int(DamageType.Kind.LIGHTNING), "le trait reste un éclair")


## Une mort et une boule d'expérience récompensent par le même chemin : le joueur et
## les manuels à l'étude apprennent du même montant.
func test_a_reward_feeds_the_player_and_its_manuals() -> void:
	var book := Item.new(ItemCatalog.by_id("manual_lightning"))
	_p.study(book)
	var book_exp := book.manual.experience
	assert_eq(_p.reward(10.0, 1, Vector2.ZERO), 10)
	assert_eq(_p.xp, 10)
	assert_eq(book.manual.experience, book_exp + 10, "le livre apprend du même montant")


## Et le retard sur la zone la fait fondre, boule comprise : sans ça, l'établi ferait
## monter un personnage de niveau 20 dans la zone 1 aussi vite qu'en jeu dans la 20.
func test_a_zone_left_behind_rewards_less() -> void:
	_p.level = 20
	var gain := _p.reward(100.0, 1, Vector2.ZERO)
	assert_eq(gain, maxi(roundi(100.0 * Enemy.experience_factor(1, 20)), 1))
	assert_lt(gain, 100)


## Un coup d'épée tire **une** fois : tous les ennemis de l'arc reçoivent la même
## valeur. Critique coupé, pour ne comparer que le tirage de la fourchette.
func test_a_sword_swing_hits_the_whole_arc_for_the_same_value() -> void:
	# Avant les lignes : équiper recalcule la fiche, et les effacerait.
	_p.equip(Weapons.bare(false), EquipmentSlots.WEAPON)
	_p.skill_mods.assign([
		StatMod.ranged("damage_fire", 1.0, 1000.0, Keywords.ATTACK),
		StatMod.new("crit_chance", StatMod.Mode.PERCENT, -100.0),
	])
	assert_true(_p.cast_slot(0), "le coup de base")

	var received_all: Array[float] = []
	for i in 2:
		var target := Hurtbox.new()
		add_child_autofree(target)
		target.damaged.connect(
			func(info: DamageInfo) -> void: received_all.append(info.parts[DamageType.Kind.FIRE])
		)
		_p._on_hitbox_area_entered(target)
	assert_eq(received_all.size(), 2, "les deux cibles sont touchées")
	assert_eq(received_all[0], received_all[1], "par la même valeur")
	assert_gt(received_all[0], 0.0, "et le feu ajouté est bien dedans")
	# Le geste attend la fin de son arc et le gel d'impact : on le laisse finir
	# plutôt que de libérer le joueur au milieu.
	await wait_seconds(0.4)


# --------------------------------------------------------------------------
# L'affixe porté (jalon 7, étape 4)
# --------------------------------------------------------------------------

func _wand(affixes: Array[String]) -> Item:
	var mods: Array = []
	for id in affixes:
		var affix := ItemAffixPool.by_id(id)
		mods.append(affix.modifier(affix.tiers[0].max_value))
	return Item.new(ItemCatalog.by_id("wand"), mods)


func test_a_worn_item_adds_its_projectile_and_removing_it_takes_it_back() -> void:
	var bolt := SkillCatalog.by_id(SkillCatalog.ID_BOLT)
	assert_eq(_p.resolve(bolt, 1).projectile_count(), 1, "à mains nues")
	_p.equip(_wand(["forked"] as Array[String]))
	assert_eq(_p.resolve(bolt, 1).projectile_count(), 3, "le T1 de « fourchu » : +2")
	_p.unequip("weapon")
	assert_eq(_p.resolve(bolt, 1).projectile_count(), 1, "et il repart avec l'objet")


## **La confusion des deux familles**, vue depuis le joueur : un objet dont tous
## les affixes visent un mot-clé ne change **aucun** champ de la fiche. S'il en
## changeait un, le bonus compterait deux fois — et seulement pour certaines
## compétences.
func test_a_scoped_affix_writes_nothing_on_the_sheet() -> void:
	_p.equip(_wand([] as Array[String]))
	var bare := _fields(_p.stats)
	_p.equip(_wand(["forked", "whistling", "stormy"] as Array[String]))
	assert_eq_deep(_fields(_p.stats), bare)
	assert_eq(_p.skill_mods.size(), 1 + 3, "la force, et les trois partent au lancer")


## Tous les champs d'une fiche, pour la comparer à une autre sans en oublier un.
func _fields(sheet: CharacterStats) -> Dictionary:
	var out := {}
	for property in sheet.get_property_list():
		if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			out[property["name"]] = sheet.get(property["name"])
	return out


## Retirer un livre du râtelier vide les cases qui pointaient dessus : une case
## qui annonce un sort inlançable se découvre au pire moment.
func test_storing_a_book_clears_the_slots_that_pointed_to_it() -> void:
	_p.study(_worked_book())
	_p.bar.put(2, "swift_bolt")
	_p.stop_studying(0)
	assert_eq(_p.bar.id_of(2), "", "la case est vide")
	assert_eq(_p.bar.id_of(0), SkillCatalog.ID_ATTACK, "les attaques de départ restent")


## Mais pas si un autre livre du râtelier l'enseigne encore : la question est
## « la sait-on toujours », pas « d'où venait-elle ».
func test_a_second_book_keeps_the_slot_full() -> void:
	_p.study(_worked_book(), 0)
	_p.study(_worked_book(), 1)
	_p.bar.put(2, "swift_bolt")
	_p.stop_studying(0)
	assert_eq(_p.bar.id_of(2), "swift_bolt", "l'autre livre l'enseigne toujours")
