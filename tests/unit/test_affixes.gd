extends GutTest

## La réserve d'affixes d'objets. Ce qui est vérifié ici n'est pas le hasard
## mais ses garde-fous : un affixe qui vise un champ inexistant ne modifierait
## rien du tout, silencieusement.


## Les affixes de fiche seulement : ceux qui visent un mot-clé ont leur propre
## vérification juste en dessous, contre les nombres d'un lancer.
func test_each_affix_targets_a_real_named_field() -> void:
	var st := CharacterStats.new()
	for a in ItemAffixPool.ALL:
		if not a.scope.is_empty():
			continue
		assert_not_null(st.get(a.stat), "l'affixe %s vise un champ réel" % a.id)
		assert_true(StatMod.LABELS.has(a.stat), "l'affixe %s a un libellé" % a.id)


## **La faute de frappe silencieuse**, côté objet : une portée hors de la liste ne
## serait portée par aucune compétence, et l'affixe ne ferait jamais rien. Un
## nombre hors des `LABELS` serait écarté par la résolution, avec le même
## résultat.
func test_each_scoped_affix_targets_a_keyword_and_a_cast_number() -> void:
	var worn_items := 0
	for a in ItemAffixPool.ALL:
		if a.scope.is_empty():
			continue
		worn_items += 1
		assert_true(Keywords.exists(a.scope), "« %s » vise « %s », hors de la liste" % [a.id, a.scope])
		assert_true(
			SkillStats.modifiable(a.stat),
			"« %s » vise « %s », qu'un modificateur ne peut pas toucher" % [a.id, a.stat]
		)
	assert_gt(worn_items, 0, "la réserve en contient")


## **Le mot-clé décoratif.** Chaque mot-clé qu'une page de manuel affiche promet
## au joueur que quelque chose l'améliore. S'il ne visait rien, le joueur
## chercherait un objet qui n'existe pas.
##
## `spell` et `attack` sont atteints par construction : `Skill.interval()`
## divise la recharge d'une incantation par la vitesse d'incantation, et celle
## d'une attaque suit la vitesse d'attaque — deux affixes de fiche qui existent.
func test_each_keyword_is_targeted_by_something() -> void:
	var vises := {}
	for a in ItemAffixPool.ALL:
		vises[a.scope] = true
	var by_cadence := Skill.KEYWORD_OF_CADENCE.values()
	for id in Keywords.LABELS:
		if by_cadence.has(id):
			continue
		assert_true(vises.has(id), "« %s » s'affiche sur les compétences, et rien ne le vise" % id)


func test_each_implicit_targets_a_real_named_field() -> void:
	var st := CharacterStats.new()
	for name in ["wand", "breastplate", "shield"]:
		var base: ItemBase = load("res://resources/items/%s.tres" % name)
		assert_not_null(st.get(base.implicit_stat), "l'implicite de %s existe" % name)
		assert_true(StatMod.LABELS.has(base.implicit_stat), "et il a un libellé")


## Tout ce qu'un objet peut donner doit se voir quelque part. Un affixe qui
## modifie une statistique absente de la fiche est invérifiable en jouant.
##
## Ce qui vise un mot-clé ne se lit pas sur la fiche du personnage mais sur celle
## de la compétence, dans la page du manuel.
func test_everything_modifiable_reads_on_the_sheet() -> void:
	var visible_ones := {}
	for group in StatsPanel.GROUPS:
		for field in group[1]:
			visible_ones[field] = true
	for a in ItemAffixPool.ALL:
		if not a.scope.is_empty():
			continue
		assert_true(visible_ones.has(a.stat), "l'affixe %s est visible sur la fiche" % a.id)


func test_an_affix_only_rolls_on_the_right_slot() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for name in ["sword", "breastplate"]:
		var base: ItemBase = load("res://resources/items/%s.tres" % name)
		for i in 400:
			for m in ItemAffixPool.roll(rng, base, 60):
				var found := false
				for a in ItemAffixPool.eligible(base, 60):
					if a.stat == m.mod.stat:
						found = true
						break
				assert_true(found, "%s ne reçoit que ses affixes (%s)" % [name, m.mod.stat])


## Le nombre tiré est borné par ce que la réserve peut réellement fournir : une
## armure ne peut pas porter six affixes s'il n'en existe que quatre pour elle.
func test_the_affix_count_is_bounded_by_the_pool() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var breastplate: ItemBase = load("res://resources/items/breastplate.tres")
	var available_count := ItemAffixPool.eligible(breastplate, 60).size()
	for i in 2000:
		assert_lte(ItemAffixPool.roll(rng, breastplate, 60).size(), available_count)


## Deux lignes strictement identiques sur un objet se liraient comme un bug.
##
## L'unicité porte sur le couple (statistique, mode) et non sur la seule
## statistique : « +6 dégâts » et « +10 % dégâts » sont deux affixes distincts
## et cohabiter est voulu — c'est tout l'intérêt d'avoir les deux formes.
func test_no_duplicate_line_on_an_item() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var duplicates := 0
	for name in ["sword", "breastplate"]:
		var base: ItemBase = load("res://resources/items/%s.tres" % name)
		for i in 1000:
			var seen_all := {}
			for m in ItemAffixPool.roll(rng, base, 60):
				var key := "%s/%d" % [m.mod.stat, m.mod.mode]
				if seen_all.has(key):
					duplicates += 1
				seen_all[key] = true
	assert_eq(duplicates, 0, "aucune ligne répétée sur 2000 objets")


## Le même invariant, vu depuis la réserve : deux définitions qui partagent
## statistique **et** mode produiraient forcément des doublons un jour.
func test_the_pool_does_not_contain_the_same_line_twice() -> void:
	var seen_all := {}
	for a in ItemAffixPool.ALL:
		var key := "%s/%s/%s/%s/%s" % [a.stat, a.scope, a.percent, a.tags, a.excludes]
		assert_false(seen_all.has(key), "%s fait doublon avec %s" % [a.id, seen_all.get(key, "")])
		seen_all[key] = a.id


func test_rarity_is_deduced_from_the_affix_count() -> void:
	var base: ItemBase = load("res://resources/items/sword.tres")
	assert_eq(Item.new(base).rarity(), Item.Rarity.COMMON, "sans affixe")
	var one: Array[StatMod] = [StatMod.new("armor", StatMod.Mode.FLAT, 1.0)]
	assert_eq(Item.new(base, one).rarity(), Item.Rarity.MAGIC)
	var three: Array[StatMod] = [one[0], one[0], one[0]]
	assert_eq(Item.new(base, three).rarity(), Item.Rarity.RARE)


# --------------------------------------------------------------------------
# Les étiquettes (jalon 5)
# --------------------------------------------------------------------------

## Le cas qui a fait passer le filtre des familles aux étiquettes. Une épée et
## une baguette sont toutes deux de famille `weapon` : tant que le filtre lisait
## la famille, il était **impossible** de donner les dégâts d'attaque à l'une et
## pas à l'autre, et une baguette sortait « acérée ».
func test_a_wand_never_rolls_a_melee_affix() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var forbidden := ["attack_speed", "attack_range"]
	var wand: ItemBase = load("res://resources/items/wand.tres")
	for i in 1000:
		for m in ItemAffixPool.roll(rng, wand, 60):
			assert_false(
				m.mod.stat in forbidden or m.mod.scope == Keywords.ATTACK,
				"une baguette a tiré « %s », qui appartient au corps à corps" % m.mod.label()
			)


## L'épée, elle, doit continuer de les recevoir : un filtre qui ne laisse plus
## rien passer passerait ce test-là sans rien dire.
func test_a_sword_still_rolls_its_melee_affixes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	var sword: ItemBase = load("res://resources/items/sword.tres")
	var seen_all := {}
	for i in 600:
		for m in ItemAffixPool.roll(rng, sword, 60):
			seen_all[m.mod.stat] = true
			seen_all[m.mod.scope] = true
	for expected in [Keywords.ATTACK, "attack_speed", "attack_range"]:
		assert_true(seen_all.has(expected), "l'épée tire encore « %s »" % expected)


## `bewitched` ne sort que sur ce qu'on tient pour lancer : les armes et les main
## gauche de lanceur, jamais un bijou ni une épée. Vérifié base par base sur tout
## le catalogue : une étiquette `caster` posée un jour sur une capuche le ferait
## tomber ici, et ce serait une décision à prendre plutôt qu'un effet de bord.
func test_percent_spell_damage_only_rolls_on_caster_items() -> void:
	var bewitched := ItemAffixPool.by_id("bewitched")
	assert_eq(bewitched.scope, Keywords.SPELL)
	var caster_only := 0
	for base: ItemBase in ItemCatalog.ALL:
		var expected: bool = base.family in ["weapon", "offhand"] and base.tags.has("caster")
		assert_eq(bewitched.fits(base), expected, "« %s »" % base.id)
		if expected:
			caster_only += 1
	assert_gt(caster_only, 0, "encore faut-il qu'il existe des objets de lanceur")


## Une statistique qui ne se trouve qu'à un endroit fait de cet endroit une
## décision. La vitesse de déplacement est la seule du jalon 4 à être passée
## d'un emplacement à deux ; elle revient aux bottes seules.
func test_movement_speed_only_rolls_on_boots() -> void:
	for base in ItemCatalog.ALL:
		for a in ItemAffixPool.eligible(base, 60):
			if a.stat != "move_speed":
				continue
			assert_eq(
				base.family, "boots",
				"« %s » peut tirer de la vitesse de déplacement" % base.display_name
			)


## Le refus l'emporte sur l'autorisation, sinon « partout sauf les armes » se
## lirait « partout, y compris les armes qui portent une étiquette autorisée ».
func test_an_exclusion_wins_over_an_allowed_tag() -> void:
	var sword: ItemBase = load("res://resources/items/sword.tres")
	var a := ItemAffix.new()
	a.tags = PackedStringArray(["melee"])
	assert_true(a.fits(sword), "l'étiquette autorise")
	a.excludes = PackedStringArray(["weapon"])
	assert_false(a.fits(sword), "et l'exclusion referme")


## C'est cette forme-là que prendront les résistances : rien à autoriser, une
## seule chose à refuser, et toute base ajoutée plus tard en hérite sans qu'on y
## pense.
func test_an_untagged_affix_rolls_everywhere_except_where_excluded() -> void:
	var a := ItemAffix.new()
	a.excludes = PackedStringArray(["weapon"])
	var weapons := 0
	var received_all := 0
	for base in ItemCatalog.ALL:
		if a.fits(base):
			received_all += 1
		else:
			weapons += 1
			assert_true(base.tags.has("weapon"), "seule une arme est refusée")
	assert_gt(weapons, 0, "il y a bien des armes dans le catalogue")
	assert_eq(received_all, ItemCatalog.ALL.size() - weapons, "et tout le reste reçoit")


## Une base sans étiquette ne recevrait que les affixes universels, et le
## constater demanderait de ramasser cent objets.
func test_an_untagged_base_does_not_receive_targeted_affixes() -> void:
	var bare := ItemBase.new()
	var a := ItemAffix.new()
	a.tags = PackedStringArray(["melee"])
	assert_false(a.fits(bare))
	assert_false(a.fits(null), "et pas de base du tout n'est pas « partout »")


# --------------------------------------------------------------------------
# Les paliers (jalon 5)
# --------------------------------------------------------------------------

## Ce qui remplace la formule. Les paliers sont écrits à la main dans les
## `.tres` — une formule donnerait à tous les affixes la même courbe — et c'est
## ce test qui attrape la faute de frappe : deux fourchettes inversées, un
## niveau qui redescend, un palier plus fort que celui du dessus.
##
## La comparaison porte sur la **valeur absolue** : un affixe dont le bon sens
## est négatif — un temps de recharge qui baisse — s'améliorera en descendant, et
## le test doit le suivre sans qu'on ait à le réécrire.
func test_each_scale_is_monotonic() -> void:
	for a in ItemAffixPool.ALL:
		assert_gt(a.tiers.size(), 1, "« %s » n\'a pas d\'échelle" % a.id)
		for i in a.tiers.size():
			var t: ItemAffixTier = a.tiers[i]
			assert_lte(t.min_value, t.max_value, "%s T%d : fourchette à l\'envers" % [a.id, i + 1])
			assert_gt(t.weight, 0, "%s T%d : un palier de poids nul ne sort jamais" % [a.id, i + 1])
			if i + 1 >= a.tiers.size():
				continue
			var worst: ItemAffixTier = a.tiers[i + 1]
			assert_gt(
				t.required_level, worst.required_level,
				"%s : T%d doit demander plus que T%d" % [a.id, i + 1, i + 2]
			)
			assert_gt(
				absf(t.min_value), absf(worst.min_value),
				"%s : T%d n\'est pas meilleur que T%d" % [a.id, i + 1, i + 2]
			)
			assert_gt(absf(t.max_value), absf(worst.max_value))
			assert_eq(
				signf(t.min_value), signf(worst.min_value),
				"%s : deux paliers de signes contraires" % a.id
			)


## Le palier le plus bas exige toujours 1. Sans cette règle, l\'affixe
## n\'existerait pas dans les premières zones, et sa première sortie
## ressemblerait à un ajout de contenu plutôt qu\'à une progression.
func test_each_affix_exists_from_level_1() -> void:
	for a in ItemAffixPool.ALL:
		assert_eq(a.minimum_level(), 1, "« %s » ne sort pas dans les premières zones" % a.id)
		assert_eq(
			a.unlocked_tiers(1).size(), 1,
			"« %s » : un seul palier ouvert au niveau 1, le pire" % a.id
		)
		assert_eq(
			a.unlocked_tiers(100).size(), mini(a.tiers.size(), ItemAffix.OPEN_TIERS),
			"« %s » : en fin de course, la fenêtre est pleine et pas davantage" % a.id
		)


## La fenêtre glisse : elle ne s\'ouvre pas, elle **se déplace**. Le meilleur
## palier atteint monte avec le niveau d\'objet, et le pire ouvert monte avec lui.
##
## C\'est la moitié qui manquait. Le plafond existait depuis le jalon 5 ; sans
## plancher, un objet de niveau 60 pouvait sortir le palier des premières zones,
## et le meilleur objet du jeu valait parfois moins que le premier ramassé.
func test_the_tier_window_slides_with_the_level() -> void:
	var physical: ItemAffix = ItemAffixPool.by_id("physical_to_attacks")
	var previous := physical.unlocked_tiers(1)

	for level in range(2, 61):
		var current_value := physical.unlocked_tiers(level)
		assert_lte(
			current_value.size(), ItemAffix.OPEN_TIERS,
			"niveau %d : jamais plus que la fenêtre" % level
		)
		if current_value.is_empty() or previous.is_empty():
			continue
		# Les indices vont du meilleur (0) au pire : la fenêtre ne peut que
		# glisser vers le meilleur, jamais revenir en arrière.
		assert_lte(
			int(current_value[0]), int(previous[0]),
			"niveau %d : le meilleur palier ouvert ne redescend pas" % level
		)
		assert_lte(
			int(current_value[current_value.size() - 1]), int(previous[previous.size() - 1]),
			"niveau %d : le pire palier ouvert ne redescend pas non plus" % level
		)
		previous = current_value


## Vu depuis le tirage plutôt que depuis la table : le même affixe sur deux
## objets de niveaux éloignés ne peut pas rendre la même chose.
func test_a_high_level_item_no_longer_rolls_early_tiers() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var physical: ItemAffix = ItemAffixPool.by_id("physical_to_attacks")
	var last := physical.tiers.size()

	for i in 500:
		assert_eq(physical.roll(rng, 1).tier, last, "au niveau 1, le pire palier et lui seul")
		assert_lte(
			physical.roll(rng, 60).tier, ItemAffix.OPEN_TIERS,
			"au niveau 60, rien sous la fenêtre"
		)


## Ce qu\'une plage de niveaux atteint, c\'est **exactement** l\'union des fenêtres
## de cette plage. Un palier de trop décrirait un objet qui ne peut pas exister,
## un de moins cacherait une sortie possible.
func test_tiers_reachable_over_a_span_are_the_union_of_windows() -> void:
	for raw in ItemAffixPool.ALL:
		var a: ItemAffix = raw
		for span in [Vector2i(1, 22), Vector2i(34, 60)]:
			var union := a.open_between(span.x, span.y)
			for index in a.tiers.size():
				var reachable := false
				for level in range(span.x, span.y + 1):
					if a.unlocked_tiers(level).has(index):
						reachable = true
						break
				assert_eq(
					union.has(index), reachable,
					"« %s » T%d entre les niveaux %d et %d" % [a.id, index + 1, span.x, span.y]
				)


## Le cas qui a motivé le filtrage de la fiche, écrit avec ses vrais chiffres :
## l\'épée large cesse de tomber en zone 40, et le T1 du « physique aux attaques » demande le
## niveau 52. Aucune épée large ne peut donc porter ce palier — l\'afficher
## décrivait un objet impossible.
func test_a_base_does_not_reach_a_tier_outside_its_window() -> void:
	var physical: ItemAffix = ItemAffixPool.by_id("physical_to_attacks")
	var large := ItemCatalog.by_id("broadsword")
	var window := ItemCatalog.drop_window(large)

	assert_eq(physical.tiers[0].required_level, 52, "le T1 du physique aux attaques demande le niveau 52")
	assert_eq(window.y, 40, "et l\'épée large cesse de tomber en zone 40")
	assert_false(
		physical.open_between(window.x, window.y).has(0),
		"donc aucune épée large ne porte ce palier"
	)

	# La lame de guerre, elle, y arrive : sans ça le filtre serait simplement
	# en train de tout couper.
	var war := ItemCatalog.by_id("war_blade")
	assert_true(
		physical.open_between(war.required_level, Game.MAX_LEVEL).has(0),
		"la lame de guerre, elle, atteint le T1"
	)


## La fenêtre d\'un palier doit dire exactement ce que le tirage accepte : c\'est
## elle que la fiche de la forge affiche, et une fiche qui annonce un palier que
## le tirage refuse est pire qu\'une fiche absente.
func test_a_tier_window_says_what_the_roll_accepts() -> void:
	for raw in ItemAffixPool.ALL:
		var a: ItemAffix = raw
		for index in a.tiers.size():
			var window := a.tier_window(index, 1, Game.MAX_LEVEL)
			assert_eq(
				window.x, a.tiers[index].required_level,
				"« %s » T%d ouvre à son niveau requis" % [a.id, index + 1]
			)
			assert_true(
				a.unlocked_tiers(window.x).has(index),
				"« %s » T%d sort au niveau %d" % [a.id, index + 1, window.x]
			)
			assert_true(
				a.unlocked_tiers(window.y).has(index),
				"« %s » T%d sort encore au niveau %d" % [a.id, index + 1, window.y]
			)
			if window.y >= Game.MAX_LEVEL:
				continue
			assert_false(
				a.unlocked_tiers(window.y + 1).has(index),
				"« %s » T%d ne sort plus au niveau %d" % [a.id, index + 1, window.y + 1]
			)


## Bornée à une plage, la fenêtre d'un palier reste dans cette plage : c'est ce
## qui permet à la fiche d'annoncer « zones 19 à 22 » sur une base qui s'arrête
## en 22, au lieu de « 19 à 51 » qu'il faut intersecter de tête.
func test_a_tier_window_stays_in_the_requested_span() -> void:
	var physical: ItemAffix = ItemAffixPool.by_id("physical_to_attacks")
	var sword := ItemCatalog.by_id("sword")
	var zones := ItemCatalog.drop_window(sword)
	assert_eq(zones, Vector2i(1, 22), "l\'épée tombe des zones 1 à 22")

	for raw in physical.open_between(zones.x, zones.y):
		var index := int(raw)
		var window := physical.tier_window(index, zones.x, zones.y)
		assert_gte(window.x, zones.x, "T%d ne commence pas avant la base" % [index + 1])
		assert_lte(window.y, zones.y, "T%d ne finit pas après elle" % [index + 1])
		assert_lte(window.x, window.y, "T%d a une fenêtre non vide" % [index + 1])

	# Et un palier hors de portée rend une fenêtre vide plutôt qu'une fenêtre
	# fausse : le T1 demande le niveau 52, l'épée s'arrête à 22.
	assert_eq(physical.tier_window(0, zones.x, zones.y), Vector2i(0, 0))


## Le cœur du jalon : le niveau d\'objet ne corrige pas des probabilités par une
## formule, il ouvre des lignes dans une table.
func test_a_level_1_item_never_rolls_a_locked_tier() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 606
	var index := {}
	for a in ItemAffixPool.ALL:
		index[a.id] = a
	for name in ["sword", "breastplate", "boots", "ring"]:
		var base: ItemBase = load("res://resources/items/%s.tres" % name)
		for i in 300:
			for rolled in ItemAffixPool.roll(rng, base, 1):
				var a: ItemAffix = index[rolled.affix_id]
				var tier: ItemAffixTier = a.tiers[rolled.tier - 1]
				assert_lte(
					tier.required_level, 1,
					"« %s » a sorti son T%d sur un objet de niveau 1" % [a.id, rolled.tier]
				)


## Et l\'inverse, sans quoi le test précédent passerait avec une réserve vide : à
## haut niveau, c\'est **la fenêtre entière** qui sort, le meilleur palier comme
## le moins bon des quatre. Garder plusieurs paliers ouverts est la règle — sinon
## le niveau d\'objet serait une garantie et il n\'y aurait plus rien à espérer en
## regardant tomber un objet.
##
## Ce que ce test dit maintenant et ne disait pas avant : les paliers **sous** la
## fenêtre ne sortent plus. Un objet de niveau 60 ne peut plus recevoir le T8,
## celui des premières zones.
func test_at_high_level_the_whole_window_drops_and_nothing_below() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8080
	var vigorous: ItemAffix = load("res://resources/item_affixes/vigorous.tres")
	var seen_all := {}
	for i in 4000:
		seen_all[vigorous.roll(rng, 60).tier] = true

	assert_eq(
		seen_all.size(), ItemAffix.OPEN_TIERS,
		"les %d paliers de la fenêtre sortent, %d vus" % [ItemAffix.OPEN_TIERS, seen_all.size()]
	)
	for tier in seen_all:
		assert_lte(
			int(tier), ItemAffix.OPEN_TIERS,
			"le T%d est sous la fenêtre d\'un objet de niveau 60" % tier
		)


## La promesse du jalon, mesurée plutôt que déclarée : descendre plus bas
## rapporte mieux. Ce n\'est pas une garantie objet par objet — les mauvais
## paliers sortent encore — mais la moyenne doit bouger, et franchement.
func test_a_high_level_item_rolls_better_on_average() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4711
	var vigorous: ItemAffix = load("res://resources/item_affixes/vigorous.tres")
	var low := 0.0
	var top := 0.0
	for i in 2000:
		low += vigorous.roll(rng, 1).mod.value
		top += vigorous.roll(rng, 60).mod.value
	assert_gt(top, low * 3.0, "moyennes : %.1f au niveau 1, %.1f au niveau 60" % [low / 2000.0, top / 2000.0])


## Sans provenance, l\'infobulle des tiers ne peut rien montrer — et elle ne doit
## surtout pas la déduire de la valeur : deux paliers voisins se chevauchent.
func test_a_rolled_affix_keeps_its_origin() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var sword: ItemBase = load("res://resources/items/sword.tres")
	var seen_all := 0
	for i in 200:
		for rolled in ItemAffixPool.roll(rng, sword, 45):
			seen_all += 1
			assert_true(rolled.known(), "un affixe fraîchement tiré sait d\'où il vient")
			assert_false(rolled.affix_id.is_empty())
			assert_between(rolled.tier, 1, 9, "un numéro de palier plausible")
	assert_gt(seen_all, 0, "encore faut-il que quelque chose ait été tiré")


## Un affixe dont même le dernier palier demande plus que le niveau de l\'objet
## n\'est pas dans la réserve. Rendre null plutôt qu\'un palier au rabais : c\'est
## l\'appelant qui décide, et `eligible` l\'a déjà écarté.
func test_an_affix_without_open_tier_rolls_nothing() -> void:
	var a := ItemAffix.new()
	a.id = "late"
	var t := ItemAffixTier.new()
	t.required_level = 50
	a.tiers = [t]
	assert_eq(a.minimum_level(), 50)
	assert_true(a.unlocked_tiers(10).is_empty())
	assert_null(a.roll(RandomNumberGenerator.new(), 10))


## L\'arrondi appartient à l\'affixe, pas au palier. La règle d\'avant les
## paliers le déduisait de la borne haute : les dégâts critiques, dont l\'échelle
## passe sous 1 en bas et au-dessus en haut, se seraient affichés « +0,35 » à un
## palier et « +1 » au suivant.
func test_rounding_is_the_same_at_every_tier() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var bloody: ItemAffix = load("res://resources/item_affixes/bloody.tres")
	assert_almost_eq(bloody.rounded, 0.01, 0.0001, "une fraction, à tous ses paliers")
	var fractions := 0
	for i in 500:
		var rolled := bloody.roll(rng, 60)
		var v: float = rolled.mod.value
		assert_almost_eq(v, snappedf(v, 0.01), 0.0001, "arrondi au centième")
		if not is_equal_approx(v, roundf(v)):
			fractions += 1
	assert_gt(fractions, 0, "et les décimales ne sont pas perdues en chemin")


## **T1 est le meilleur palier**, et le dernier numéro est le pire — 8 pour les
## PV plats, 9 pour l\'armure, 5 pour la vitesse de déplacement. C\'est la
## convention du genre, celle que l\'infobulle affichera, et celle que la
## monotonie fait respecter sans jamais la nommer : ce test-ci la nomme.
##
## Le numéro n\'est pas un champ saisi mais une **position** dans la liste, qui
## va du meilleur au pire. Écrire une échelle à l\'envers dans un `.tres` ferait
## donc du T1 le palier des premières zones, et personne ne s\'en apercevrait
## avant de survoler un objet.
func test_tier_1_is_the_best() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for a in ItemAffixPool.ALL:
		var best: ItemAffixTier = a.tiers[0]
		var worst: ItemAffixTier = a.tiers[a.tiers.size() - 1]
		var last: int = a.tiers.size()

		assert_gt(
			absf(best.max_value), absf(worst.max_value),
			"« %s » : le T1 doit taper plus fort que le T%d" % [a.id, last]
		)
		assert_gt(
			best.required_level, worst.required_level,
			"« %s » : le T1 doit être le plus exigeant" % a.id
		)
		assert_eq(worst.required_level, 1, "« %s » : le T%d est celui des premières zones" % [a.id, last])

		# La même chose vue depuis le tirage, qui est ce que le joueur reçoit :
		# au niveau 1 il ne sort que le dernier numéro, et le T1 est le dernier
		# palier à s\'ouvrir.
		assert_eq(a.roll(rng, 1).tier, last, "« %s » : au niveau 1, le pire palier" % a.id)
		assert_eq(
			a.unlocked_tiers(best.required_level - 1).size(),
			mini(last - 1, ItemAffix.OPEN_TIERS),
			"« %s » : le T1 est le dernier à s\'ouvrir" % a.id
		)
		assert_false(
			a.unlocked_tiers(best.required_level - 1).has(0),
			"« %s » : juste en dessous, le T1 n\'est pas encore là" % a.id
		)
		assert_between(a.roll(rng, 999).tier, 1, last, "« %s » : un numéro de palier reste dans l'échelle" % a.id)


# --------------------------------------------------------------------------
# La réserve élargie (jalon 5, étape 4)
# --------------------------------------------------------------------------

## L'inverse de `test_everything_modifiable_reads_on_the_sheet` : une
## statistique que la fiche annonce et qu'aucun affixe ne touche est une ligne
## qu'on regarde monter de niveau en niveau sans jamais pouvoir agir dessus.
##
## Le temps de recharge n'y est pas, et c'est voulu : il n'apparaît pas sur la
## fiche non plus. C'est la cadence de l'outil, la vitesse d'attaque est
## l'adresse de celui qui le tient, et ce sont les multiplicateurs que les
## affixes touchent — « +10 % de vitesse » se lit, « -9 % de recharge » demande
## une conversion mentale à chaque fois.
##
## Une ligne de compétence de départ est atteinte par les dégâts qui visent l'un
## de ses mots-clés : « dégâts de froid aux attaques » monte l'attaque.
func test_each_sheet_stat_is_reachable_by_an_affix() -> void:
	var hit_ones := {}
	for a in ItemAffixPool.ALL:
		hit_ones[a.stat] = true
	for group in StatsPanel.GROUPS:
		for field in group[1]:
			var reached_value := hit_ones.has(field)
			if StatsPanel._is_a_skill(field):
				reached_value = _added_damage_reaches(SkillCatalog.by_id(field))
			assert_true(
				reached_value,
				"« %s » s\'affiche sur la fiche mais aucun affixe ne l\'atteint" % field
			)


func _added_damage_reaches(skill: Skill) -> bool:
	for a in ItemAffixPool.ALL:
		if skill.worn(a.scope) and SkillStats.added_nature(a.stat) >= 0:
			return true
	return false


## La règle demandée : les résistances partout **sauf** sur les armes. Écrite
## avec une exclusion et aucune autorisation, donc une base ajoutée plus tard en
## hérite sans qu\'on y pense — c\'est tout l\'intérêt d\'`excludes`.
func test_resistances_never_roll_on_a_weapon() -> void:
	var weapons := 0
	var others := 0
	for base in ItemCatalog.ALL:
		# « Partout sauf sur les armes » parle de ce qu'on **porte**. Un manuel se
		# lit : il ne reçoit aucun affixe, pas même universel, et l'attendre à
		# cinq résistances reviendrait à demander des résistances à un livre.
		if not EquipmentSlots.equippable_family(base.family):
			continue
		var resistances := 0
		for a in ItemAffixPool.eligible(base, 60):
			if a.stat in DamageType.RESIST_FIELDS:
				resistances += 1
		if base.tags.has("weapon"):
			weapons += 1
			assert_eq(resistances, 0, "« %s » est une arme" % base.display_name)
		else:
			others += 1
			assert_eq(resistances, 5, "« %s » doit pouvoir tirer les cinq" % base.display_name)
	assert_gt(weapons, 0, "il y a bien des armes dans le catalogue")
	assert_gt(others, 0, "et des objets qui n\'en sont pas")


## Les défenses vont sur ce qui protège. Une épée qui donne des points de vie ou
## de l\'armure ferait de l\'arme un emplacement défensif de plus, et il n\'y
## aurait plus de raison de choisir entre frapper et tenir.
func test_defenses_never_roll_on_a_weapon() -> void:
	var defensive := ["max_health", "armor", "evasion"]
	for base in ItemCatalog.ALL:
		if not base.tags.has("weapon"):
			continue
		for a in ItemAffixPool.eligible(base, 60):
			assert_false(
				a.stat in defensive,
				"« %s » peut tirer « %s » (%s)" % [base.display_name, a.stat, a.id]
			)


## Ce que l\'étape 1 avait cassé et que celle-ci répare : la baguette avait perdu
## la mêlée sans rien recevoir en échange, et ses deux seuls affixes possibles
## étaient des critiques, qui ne s\'appliquent pas aux tirs.
func test_a_wand_has_what_it_takes_to_be_offensive() -> void:
	var wand: ItemBase = load("res://resources/items/wand.tres")
	var stats := {}
	var scopes := {}
	for a in ItemAffixPool.eligible(wand, 1):
		stats[a.stat] = true
		scopes[a.scope] = true
	assert_true(scopes.has(Keywords.SPELL), "des dégâts ajoutés aux sorts")
	assert_true(stats.has("cast_speed"), "et une cadence")
	assert_false(scopes.has(Keywords.ATTACK), "toujours pas de mêlée")
	assert_false(stats.has("attack_speed"))


## Les attributs sont les seuls affixes volontairement universels : ils ne
## servent à rien par eux-mêmes et n\'existent que par ce qu\'ils dérivent, donc
## les réserver à un emplacement n\'apprendrait rien à personne.
func test_attributes_roll_everywhere() -> void:
	for base in ItemCatalog.ALL:
		# « Partout » veut dire sur tout ce qui se porte : un manuel ne reçoit rien.
		if not EquipmentSlots.equippable_family(base.family):
			continue
		var seen_all := {}
		for a in ItemAffixPool.eligible(base, 1):
			if a.stat in CharacterStats.ATTRIBUTES:
				seen_all[a.stat] = true
		assert_eq(
			seen_all.size(), CharacterStats.ATTRIBUTES.size(),
			"« %s » ne voit que %d attribut(s)" % [base.display_name, seen_all.size()]
		)


## Les deux étiquettes que l\'étape 5 a enfin posées. L\'armure en pourcentage
## multiplie ce que les plaques apportent, donc elle n\'a de sens que sur elles ;
## l\'esquive va aux pièces légères, qui n\'ont pas de plaques à multiplier. Les
## deux affixes visaient `armour` avant, faute de porteur pour `heavy` et
## `light` — une étiquette sans porteur est une règle qu\'on croit appliquée.
func test_percent_armor_and_evasion_share_the_armors() -> void:
	var lourdes := 0
	var light_ones := 0
	for base in ItemCatalog.ALL:
		var stats := {}
		for a in ItemAffixPool.eligible(base, 60):
			stats[a.stat] = a.percent
		if base.tags.has("heavy"):
			lourdes += 1
			assert_true(stats.has("armor"), "« %s » doit tirer de l\'armure" % base.display_name)
			assert_false(stats.has("evasion"), "« %s » ne tire pas d\'esquive" % base.display_name)
		elif base.tags.has("light"):
			light_ones += 1
			assert_true(stats.has("evasion"), "« %s » doit tirer de l\'esquive" % base.display_name)
	assert_gt(lourdes, 0, "il y a bien des pièces lourdes")
	assert_gt(light_ones, 0, "et des légères")


# --------------------------------------------------------------------------
# L\'affichage des paliers (jalon 5, étape 7)
# --------------------------------------------------------------------------

func test_an_affix_is_found_by_its_id() -> void:
	for a in ItemAffixPool.ALL:
		assert_eq(ItemAffixPool.by_id(a.id), a, "aller-retour sur « %s »" % a.id)
	assert_null(ItemAffixPool.by_id("affix_from_2027"), "un affixe retiré rend null")
	assert_null(ItemAffixPool.by_id(""))


## Ce que l\'infobulle écrit à droite d\'une ligne, sous Alt : le palier et la
## fourchette **de ce palier**, pas celle de l\'affixe entier.
func test_a_rolled_affix_announces_its_tier_and_span() -> void:
	var vigorous: ItemAffix = load("res://resources/item_affixes/vigorous.tres")
	var rng := RandomNumberGenerator.new()
	rng.seed = 314
	var rolled := vigorous.roll(rng, 60)
	var tier: ItemAffixTier = vigorous.tiers[rolled.tier - 1]

	var text_value := rolled.tier_and_span()
	assert_true(text_value.begins_with("T%d" % rolled.tier), "le numéro d\'abord : « %s »" % text_value)
	assert_true(
		text_value.contains(StatMod.range_label(
			rolled.mod.stat, rolled.mod.mode, tier.min_value, tier.max_value
		)),
		"puis la fourchette du palier : « %s »" % text_value
	)
	assert_between(rolled.mod.value, tier.min_value, tier.max_value, "et la valeur en vient")


## Un objet d\'avant les paliers n\'a pas de palier, et on ne le devine pas :
## deux paliers voisins se chevauchent, la déduction serait fausse une fois sur
## trois. Pas de colonne vaut mieux qu\'une colonne fausse.
func test_an_affix_without_origin_shows_no_tier() -> void:
	var orphan := RolledAffix.orphan(StatMod.new("max_health", StatMod.Mode.FLAT, 40.0))
	assert_eq(orphan.tier_and_span(), "")


## Et un affixe retiré du projet depuis : sa valeur s\'applique toujours, c\'est
## son palier qui devient inaffichable.
func test_a_vanished_affix_shows_no_tier() -> void:
	var lost := RolledAffix.new("affix_from_2027", 3, StatMod.new("armor", StatMod.Mode.FLAT, 12.0))
	assert_eq(lost.tier_and_span(), "")
	# Et un numéro de palier hors de l\'échelle, si une échelle raccourcit.
	var old_one := RolledAffix.new("nimble", 99, StatMod.new("move_speed", StatMod.Mode.PERCENT, 5.0))
	assert_eq(old_one.tier_and_span(), "")


# --------------------------------------------------------------------------
# Les dégâts ajoutés en fourchette (jalon 8)
# --------------------------------------------------------------------------

## Une nature est une nature comme les autres : chacune s'ajoute aux attaques et
## aux sorts, y compris celles qu'aucune compétence du jeu ne porte encore.
func test_each_nature_adds_to_attacks_and_spells() -> void:
	for nature in DamageType.Kind.values():
		for family in [Keywords.ATTACK, Keywords.SPELL]:
			var found := false
			for a in ItemAffixPool.ALL:
				if a.stat == SkillStats.added_stat(nature) and a.scope == family:
					found = true
			assert_true(found, "« %s » ne s'ajoute pas %s" % [
				DamageType.NAMES[nature], Keywords.recipient(family)
			])


## Une fourchette ne sort jamais à l'envers : sa borne haute commence au-dessus de
## sa basse, et elle croît avec les paliers comme la basse.
func test_each_range_is_monotonic_and_the_right_way_round() -> void:
	for a in ItemAffixPool.ALL:
		if not a.is_a_range():
			continue
		for i in a.tiers.size():
			var t: ItemAffixTier = a.tiers[i]
			assert_lte(t.min_top, t.max_top, "%s T%d : borne haute à l'envers" % [a.id, i + 1])
			assert_gte(
				t.min_top, t.max_value,
				"%s T%d : la borne haute peut sortir sous la basse" % [a.id, i + 1]
			)
			if i + 1 >= a.tiers.size():
				continue
			var worst: ItemAffixTier = a.tiers[i + 1]
			assert_gt(
				t.min_top, worst.min_top,
				"%s : T%d n'est pas meilleur que T%d" % [a.id, i + 1, i + 2]
			)
			assert_gt(t.max_top, worst.max_top)


## Un tirage donne deux nombres, chacun dans sa plage : c'est ce que la ligne
## « T5  (7–10 à 21–29) » de l'infobulle promet.
func test_a_rolled_range_stays_in_both_its_spans() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 808
	var cold := ItemAffixPool.by_id("cold_to_spells")
	for i in 300:
		var rolled := cold.roll(rng, 60)
		var tier: ItemAffixTier = cold.tiers[rolled.tier - 1]
		assert_between(rolled.mod.value, tier.min_value, tier.max_value)
		assert_between(rolled.mod.value_max, tier.min_top, tier.max_top)
		assert_eq(rolled.mod.scope, Keywords.SPELL)
