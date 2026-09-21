extends GutTest

## La sérialisation d'un personnage. Aucun nœud, aucun disque : c'est du calcul
## sur des dictionnaires, exactement comme un module web.
##
## Tous les allers-retours passent **par le texte JSON** et non par le
## dictionnaire seul. Ce n'est pas de la coquetterie : le JSON ne connaît qu'un
## type de nombre, donc un aller-retour en mémoire garde des entiers là où un
## vrai fichier rend des flottants. Un test qui saute l'encodage passerait sur
## un code qui casse dès le premier rechargement.


func _round_trip(p: Character) -> Character:
	var text_value := JSON.stringify(p.to_dict())
	var reread: Variant = JSON.parse_string(text_value)
	assert_true(reread is Dictionary, "le texte produit est du JSON valide")
	return Character.from_dict(reread)


func _ornate_sword() -> Item:
	return Item.new(ItemCatalog.by_id("sword"), [
		StatMod.ranged("damage_physical", 4.0, 9.0, Keywords.ATTACK),
		StatMod.new("attack_speed", StatMod.Mode.PERCENT, 8.0),
	] as Array[StatMod])


## Un personnage qui a vécu : des niveaux, un chemin dans l'arbre et des points en
## attente, trois objets rangés à des endroits choisis, un plastron sur le dos.
func _played_character() -> Character:
	var p := Character.create_new("Brenna", 2)
	p.level = 7
	p.experience = 240
	p.passives = PackedStringArray(["str_1", "str_2", "str_3"])
	p.bag.place(_ornate_sword(), Vector2i(3, 1))
	p.bag.place(Item.new(ItemCatalog.by_id("wand")), Vector2i(0, 0))
	p.equipment["chest"] = Item.new(ItemCatalog.by_id("breastplate"), [
		StatMod.new("max_health", StatMod.Mode.PERCENT, 12.0),
	] as Array[StatMod])
	return p


func test_a_new_character_starts_from_zero() -> void:
	var p := Character.create_new("Aldric", 1)
	assert_false(p.id.is_empty(), "un identifiant est généré")
	assert_eq(p.name, "Aldric")
	assert_eq(p.level, 1)
	assert_eq(p.experience, 0)
	assert_eq(p.passives.size(), 0, "l'arbre se prend en jouant, pas à la création")
	assert_eq(p.bag.placed.size(), 0)
	assert_eq(p.equipment.size(), 0)


## Le nom ne fait pas l'identifiant : deux personnages peuvent s'appeler pareil,
## et un nom peut contenir ce qu'un système de fichiers refuse.
func test_two_characters_with_the_same_name_have_two_ids() -> void:
	var a := Character.create_new("Brenna", 0)
	var b := Character.create_new("Brenna", 0)
	assert_ne(a.id, b.id)


func test_full_round_trip_through_json() -> void:
	var before := _played_character()
	var after := _round_trip(before)
	assert_not_null(after, "le personnage se relit")

	assert_eq(after.id, before.id)
	assert_eq(after.name, "Brenna")
	assert_eq(after.silhouette, 2)
	assert_eq(after.level, 7, "un entier relu reste un entier")
	assert_eq(after.experience, 240)
	assert_eq(after.passives, before.passives, "les nœuds pris, dans leur ordre")
	assert_eq(after.created_on, before.created_on)
	assert_eq(after.bag.placed.size(), 2)
	assert_eq(after.equipment.size(), 1)


func test_items_keep_their_place_in_the_bag() -> void:
	var after := _round_trip(_played_character())
	var i := after.bag.index_at(Vector2i(3, 1))
	assert_ne(i, Inventory.EMPTY, "l'épée est revenue là où elle était")
	assert_eq(after.bag.placed[i].data.base.id, "sword")
	assert_ne(after.bag.index_at(Vector2i(3, 3)), Inventory.EMPTY, "épée sur trois lignes")
	assert_eq(after.bag.index_at(Vector2i(9, 4)), Inventory.EMPTY, "et le reste est libre")


func test_affixes_survive_with_their_mode() -> void:
	var after := _round_trip(_played_character())
	var sword: Item = after.bag.placed[after.bag.index_at(Vector2i(3, 1))].data
	assert_eq(sword.explicits.size(), 2)
	assert_eq(sword.explicits[0].mod.stat, "damage_physical")
	assert_eq(sword.explicits[0].mod.mode, StatMod.Mode.FLAT)
	assert_almost_eq(sword.explicits[0].mod.value, 4.0, 0.0001)
	assert_almost_eq(sword.explicits[0].mod.value_max, 9.0, 0.0001, "et la borne haute de la fourchette")
	assert_eq(sword.explicits[1].mod.mode, StatMod.Mode.PERCENT, "le mode n'est pas retombé sur plat")
	assert_eq(sword.rarity(), Item.Rarity.MAGIC, "deux affixes, donc bleu")


func test_a_more_line_stays_more() -> void:
	var p := Character.create_new("Brenna", 2)
	p.equipment["chest"] = Item.new(ItemCatalog.by_id("breastplate"), [
		StatMod.new("max_health", StatMod.Mode.MORE, 12.0),
	] as Array[StatMod])
	var after := _round_trip(p)
	assert_eq(after.equipment["chest"].explicits[0].mod.mode, StatMod.Mode.MORE)


## L'implicite n'est **pas** sauvegardé : il appartient à la base et se
## reconstruit, seule sa position dans la plage part au fichier. Le sauvegarder
## figerait les valeurs d'équilibrage du jour.
func test_the_implicit_comes_from_the_base_not_the_file() -> void:
	var dict := _played_character().to_dict()
	var text_value := JSON.stringify(dict)
	assert_false(text_value.contains("implicit"), "rien de la base n'entre dans le fichier")

	var after := _round_trip(_played_character())
	var sword: Item = after.bag.placed[after.bag.index_at(Vector2i(3, 1))].data
	assert_eq(sword.mods().size(), 4, "l'implicite de l'épée, ses deux affixes et sa chance critique")


## La doctrine du projet : la base est partagée, jamais recopiée ni écrite.
func test_the_reloaded_item_points_to_the_catalog_base() -> void:
	var after := _round_trip(_played_character())
	var sword: Item = after.bag.placed[after.bag.index_at(Vector2i(3, 1))].data
	assert_eq(sword.base, ItemCatalog.by_id("sword"), "la même ressource, pas une copie")
	assert_eq(sword.base.implicit_value, 2.0, "epee.tres n'a pas été touché")
	assert_eq(sword.base.implicit_value_max, 6.0)


func test_a_full_bag_reloads_entirely() -> void:
	var p := Character.create_new("Mule", 0)
	var poses := 0
	while p.bag.add(_ornate_sword()):
		poses += 1
	assert_eq(poses, 10, "dix épées de 1 x 3 dans une grille de 10 x 5")

	var after := _round_trip(p)
	assert_eq(after.bag.placed.size(), poses, "aucune n'est tombée en route")
	assert_eq(after.bag.used_cells(), p.bag.used_cells())


func test_an_item_with_six_affixes_survives() -> void:
	var many: Array[StatMod] = []
	for i in 6:
		many.append(StatMod.new("armor", StatMod.Mode.FLAT, float(i) + 0.5))
	var p := Character.create_new("Chargé", 0)
	p.bag.place(Item.new(ItemCatalog.by_id("breastplate"), many), Vector2i(0, 0))

	var cooldown: Item = _round_trip(p).bag.placed[0].data
	assert_eq(cooldown.explicits.size(), 6)
	assert_almost_eq(cooldown.explicits[5].mod.value, 5.5, 0.0001, "les décimales aussi")


func test_a_character_with_nothing_reloads() -> void:
	var after := _round_trip(Character.create_new("Nu", 3))
	assert_not_null(after, "sac vide et aucun équipement, ce n'est pas une erreur")
	assert_eq(after.bag.placed.size(), 0)
	assert_eq(after.equipment.size(), 0)
	assert_eq(after.silhouette, 3)


## On écrit les nœuds pris, pas ce qu'ils donnent. Écrire le total figerait
## l'équilibrage du jour de la sauvegarde : un rééquilibrage de l'arbre n'atteindrait
## jamais les personnages existants.
func test_the_taken_nodes_are_saved_not_the_total() -> void:
	var dict := _played_character().to_dict()
	assert_eq(dict["passives"], ["str_1", "str_2", "str_3"])
	assert_false(dict.has("attributes"), "plus d'attributs placés")
	assert_false(dict.has("unspent_points"), "les points restants se déduisent du niveau")
	assert_false(dict.has("stats"), "aucune statistique calculée dans le fichier")
	assert_false(dict.has("max_health"))


## Le champ version existe pour refuser, pas pour deviner.
func test_an_unknown_version_is_refused() -> void:
	var dict := _played_character().to_dict()
	dict["version"] = 99
	assert_null(Character.from_dict(dict), "on ne tente pas de lire un format futur")
	dict.erase("version")
	assert_null(Character.from_dict(dict), "ni un fichier sans version")


func test_absurd_content_is_refused_without_crashing() -> void:
	assert_null(Character.from_dict({}))
	assert_null(Character.from_dict({"version": 1}), "sans identifiant, on ne sait pas quoi écraser")


## Perdre une épée est désagréable ; perdre le personnage est inacceptable.
func test_an_item_whose_base_vanished_is_ignored() -> void:
	var dict := _played_character().to_dict()
	dict["bag"][0]["base"] = "halberd_from_2027"
	dict["equipment"]["chest"]["base"] = "forgotten_cape"

	var after := Character.from_dict(dict)
	assert_not_null(after, "le personnage se charge quand même")
	assert_eq(after.level, 7, "avec toute sa progression")
	assert_eq(after.bag.placed.size(), 1, "seul l'objet inconnu manque")
	assert_eq(after.equipment.size(), 0, "et le plastron inconnu n'est pas porté")


## Un nœud disparu de l'arbre est ignoré, comme une base d'objet disparue.
func test_an_unknown_node_is_ignored() -> void:
	var dict := _played_character().to_dict()
	dict["passives"] = ["str_1", "vanished", "str_2"]
	assert_eq(Character.from_dict(dict).passives, PackedStringArray(["str_1", "str_2"]))


## Un nœud relu qui n'est plus relié au départ part avec ses suivants : une sauvegarde
## ne contourne jamais la règle de prise.
func test_an_orphan_node_is_removed_with_what_follows() -> void:
	var dict := _played_character().to_dict()
	dict["passives"] = ["str_2", "str_3", "dex_1"]
	assert_eq(Character.from_dict(dict).passives, PackedStringArray(["dex_1"]))


func test_no_more_nodes_than_points() -> void:
	var dict := _played_character().to_dict()
	dict["level"] = 2
	assert_eq(Character.from_dict(dict).passives, PackedStringArray(["str_1"]))


## Les attributs placés d'avant la v7 sont abandonnés : l'arbre est vide, tous les
## points du niveau sont à placer.
func test_a_v6_rereads_with_an_empty_tree() -> void:
	var content: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/character_v6.json"))
	var p := Character.from_dict(content)
	assert_eq(p.passives.size(), 0)
	assert_eq(PassiveTree.remaining_points(p.passives, p.level), p.level - 1)


func test_the_name_is_bounded_and_without_control_characters() -> void:
	assert_true(Character.valid_name("Brenna"))
	assert_true(Character.valid_name("Jean-Luc de l'Est"))
	assert_false(Character.valid_name(""), "empty")
	assert_false(Character.valid_name("   "), "que des espaces")
	assert_false(Character.valid_name("a".repeat(Character.NAME_MAX + 1)), "trop long")
	assert_false(Character.valid_name("Bren\nna"), "retour à la ligne")
	assert_false(Character.valid_name("Bren\tna"), "tabulation")


## Le test qui attrape ce qu'un aller-retour ne peut pas attraper : un champ
## renommé des deux côtés à la fois. Ce fichier-là est figé dans le dépôt, il
## représente les sauvegardes déjà sur les disques des joueurs.
func test_the_reference_file_rereads() -> void:
	var file := FileAccess.open("res://tests/fixtures/character_v1.json", FileAccess.READ)
	assert_not_null(file, "le fichier de référence est bien dans le dépôt")
	var content: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	var p := Character.from_dict(content)
	assert_not_null(p, "une sauvegarde de version 1 se lit toujours")
	assert_eq(p.name, "Brenna")
	assert_eq(p.level, 7)
	assert_eq(p.experience, 240)
	assert_eq(p.silhouette, 2)
	assert_eq(p.passives.size(), 0, "les attributs placés sont abandonnés")
	assert_eq(p.bag.placed.size(), 2, "l'épée et la baguette")
	assert_ne(p.bag.index_at(Vector2i(3, 1)), Inventory.EMPTY, "l'épée à sa place")
	assert_eq(p.equipment["chest"].base.id, "breastplate")
	assert_eq(p.equipment["chest"].explicits[0].mod.mode, StatMod.Mode.PERCENT)
	# Une version 1 ne dit pas d'où venaient ses objets. Ils valent 1, et pas un
	# niveau déduit du personnage : ce serait inventer.
	assert_eq(p.equipment["chest"].item_level, 1, "un objet de version 1 vaut le niveau 1")
	for placed in p.bag.placed:
		assert_eq(placed.data.item_level, 1)


# --------------------------------------------------------------------------
# Le niveau d'objet et la version 2 (jalon 5)
# --------------------------------------------------------------------------

## Le niveau est posé à la chute et ne bouge plus : il doit donc traverser le
## disque intact. Sans lui, un objet rechargé perdrait ce qui dit ce qu'il a pu
## recevoir comme tiers, et deux objets identiques à l'écran n'auraient pas la
## même histoire.
func test_the_item_level_survives_the_round_trip() -> void:
	var p := Character.create_new("Levels", 0)
	p.bag.place(Item.new(ItemCatalog.by_id("sword"), [], 42), Vector2i(0, 0))
	p.equipment["chest"] = Item.new(ItemCatalog.by_id("breastplate"), [], 28)

	var reread := Character.from_dict(p.to_dict())
	assert_not_null(reread)
	assert_eq(reread.bag.placed[0].data.item_level, 42, "l'épée garde son niveau")
	assert_eq(reread.equipment["chest"].item_level, 28, "le plastron aussi")


## La position de l'implicite traverse le disque ; une sauvegarde d'avant les plages
## relit le bas, qui était la valeur fixe.
func test_the_implicit_roll_survives_the_round_trip() -> void:
	var p := Character.create_new("Implicits", 0)
	var plate := Item.new(ItemCatalog.by_id("breastplate"))
	plate.implicit_roll = 1.0
	p.equipment["chest"] = plate
	var data := p.to_dict()
	assert_eq(Character.from_dict(data).equipment["chest"].implicit_value(), 26.0, "le haut de la plage")

	data["equipment"]["chest"].erase("base_roll")
	assert_eq(Character.from_dict(data).equipment["chest"].implicit_value(), 20.0, "le bas de la plage")


## Le format qu'on écrit aujourd'hui, figé dans le dépôt à côté de celui d'hier.
## Le fichier de version 1 prouve qu'on lit encore les sauvegardes des joueurs ;
## celui-ci prouve que le champ qu'on vient d'ajouter porte bien le nom qu'on
## croit — un renommage des deux côtés à la fois passerait l'aller-retour.
func test_the_v2_reference_file_rereads() -> void:
	var file := FileAccess.open("res://tests/fixtures/character_v2.json", FileAccess.READ)
	assert_not_null(file, "le fichier de référence est bien dans le dépôt")
	var content: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	var p := Character.from_dict(content)
	assert_not_null(p, "une sauvegarde de version 2 se lit")
	assert_eq(p.name, "Brenna")
	assert_eq(p.equipment["chest"].item_level, 28, "le niveau écrit dans le fichier")
	# Le plastron du fichier n'a ni « affixe » ni « tier » : c'est le cas d'un
	# objet relu d'une version 1 puis resauvegardé. Sa ligne s'applique, elle n'a
	# simplement rien à dire sur son tirage.
	assert_false(p.equipment["chest"].explicits[0].known(), "une provenance absente le reste")
	var levels := {}
	for placed in p.bag.placed:
		levels[placed.data.base.id] = placed.data.item_level
	assert_eq(levels["sword"], 42)
	assert_eq(levels["wand"], 12)


## La version écrite est bien celle qu'on annonce, et pas un numéro laissé
## derrière : un fichier neuf marqué « version 1 » se relirait aujourd'hui et
## deviendrait indéchiffrable le jour où la version 1 cessera d'être lue.
func test_what_is_written_carries_the_current_version() -> void:
	assert_eq(Character.create_new("Version", 0).to_dict()["version"], Character.VERSION)
	assert_true(Character.READABLE_VERSIONS.has(Character.VERSION), "on sait relire ce qu'on écrit")


## La provenance accompagne la valeur jusque sur le disque : sans elle,
## l'infobulle des paliers n'aurait rien à montrer sur un objet rechargé, et un
## objet ramassé hier ne se lirait pas comme un objet ramassé à l'instant.
func test_an_affix_origin_survives_the_disk() -> void:
	var p := Character.create_new("Tiers", 0)
	var rolled := RolledAffix.new("cuirassed", 3, StatMod.new("armor", StatMod.Mode.FLAT, 29.0))
	p.equipment["chest"] = Item.new(ItemCatalog.by_id("breastplate"), [rolled], 40)

	var reread := Character.from_dict(p.to_dict())
	var refunded: RolledAffix = reread.equipment["chest"].explicits[0]
	assert_eq(refunded.affix_id, "cuirassed")
	assert_eq(refunded.tier, 3)
	assert_almost_eq(refunded.mod.value, 29.0, 0.0001, "et la valeur, qui fait foi")
	assert_true(refunded.known())


## L'inverse, et c'est le cas des sauvegardes déjà sur les disques : un affixe
## sans provenance n'en gagne pas une en passant par le disque. Un palier deviné
## depuis la valeur serait faux une fois sur trois, les fourchettes de deux
## paliers voisins se chevauchant.
func test_an_affix_without_origin_does_not_invent_one() -> void:
	var p := Character.create_new("Orphelin", 0)
	var mod := StatMod.new("max_health", StatMod.Mode.FLAT, 22.0)
	p.equipment["chest"] = Item.new(ItemCatalog.by_id("breastplate"), [mod])

	var dict := p.to_dict()
	var written: Dictionary = dict["equipment"]["chest"]["affixes"][0]
	assert_false(written.has("affix"), "rien d'inventé dans le fichier")
	assert_false(written.has("tier"))

	var refunded: RolledAffix = Character.from_dict(dict).equipment["chest"].explicits[0]
	assert_false(refunded.known())
	assert_eq(refunded.tier, 0)
	assert_almost_eq(refunded.mod.value, 22.0, 0.0001, "mais le bonus, lui, s'applique")


# --------------------------------------------------------------------------
# Les manuels, le râtelier et la barre (jalon 6, version 3)
# --------------------------------------------------------------------------

## Ce qu'un manuel a appris traverse le disque : c'est la seule chose du jalon 6
## qui ne se recalcule pas, et la perdre serait perdre des heures de jeu.
func test_manual_points_survive_the_round_trip() -> void:
	var p := Character.create_new("Studieuse", 0)
	var book := Item.new(ItemCatalog.by_id("manual_lightning"), [], 30)
	book.manual.experience = 340
	book.manual.points["swift_bolt"] = 3
	p.bag.place(book, Vector2i(0, 0))

	var reread := Character.from_dict(p.to_dict())
	assert_not_null(reread)
	var refunded: Item = reread.bag.placed[0].data
	assert_not_null(refunded.manual, "il est revenu manuel")
	assert_eq(refunded.manual.experience, 340)
	assert_eq(refunded.manual.points_of("swift_bolt"), 3)
	assert_eq(refunded.item_level, 30, "et il garde son niveau d'objet")


## Le niveau d'un manuel se **déduit** de son expérience. L'écrire créerait la
## deuxième vérité que ce format refuse partout ailleurs : ni PV, ni statistiques,
## ni total d'attributs.
func test_a_manual_level_is_not_written() -> void:
	var p := Character.create_new("Deduite", 0)
	var book := Item.new(ItemCatalog.by_id("manual_lightning"))
	book.manual.experience = 900
	p.bag.place(book, Vector2i(0, 0))

	var written: Dictionary = p.to_dict()["bag"][0]["manual"]
	assert_true(written.has("exp"), "l'expérience, oui")
	assert_false(written.has("level"), "le niveau, non : il se recalcule")


## Un manuel au râtelier a quitté le sac : il est écrit là et **nulle part
## ailleurs**. Deux écritures feraient deux vérités sur ses points, et le
## rechargement en choisirait une au hasard.
func test_a_racked_manual_returns_to_the_rack() -> void:
	var p := Character.create_new("Row", 0)
	var book := Item.new(ItemCatalog.by_id("manual_lightning"), [], 30)
	book.manual.points["swift_bolt"] = 2
	assert_null(p.rack.put(1, book), "l'emplacement du milieu était libre")

	var reread := Character.from_dict(p.to_dict())
	assert_not_null(reread)
	assert_eq(reread.bag.placed.size(), 0, "il n'est pas aussi dans le sac")
	assert_null(reread.rack.at(0), "ni ailleurs sur le râtelier")
	var refunded := reread.rack.at(1)
	assert_not_null(refunded, "il est revenu à sa place")
	assert_eq(refunded.manual.points_of("swift_bolt"), 2)


func test_the_bar_survives_the_round_trip() -> void:
	var p := Character.create_new("Barree", 0)
	p.bar.put(2, "swift_bolt")
	p.bar.clear(1)

	var reread := Character.from_dict(p.to_dict())
	assert_not_null(reread)
	assert_eq(reread.bar.id_of(0), SkillCatalog.ID_ATTACK)
	assert_eq(reread.bar.id_of(1), "", "une case vidée exprès le reste")
	assert_eq(reread.bar.id_of(2), "swift_bolt")
	assert_eq(reread.bar.id_of(4), "")


## Une compétence retirée du projet vide sa case. Le fichier reste lisible : on
## perd une touche, pas un personnage.
func test_a_vanished_skill_leaves_its_slot_empty() -> void:
	var source := Character.create_new("Oubliee", 0).to_dict()
	source["bar"] = ["attack", "spell_removed_from_project", null, null, null]

	var reread := Character.from_dict(source)
	assert_not_null(reread, "le personnage se charge quand même")
	assert_eq(reread.bar.id_of(0), SkillCatalog.ID_ATTACK)
	assert_eq(reread.bar.id_of(1), "", "la case de la disparue est vide")


## **Le piège du jalon 10** : les points d'un passif et d'un nœud d'arbre entrent
## dans le même dictionnaire que ceux des cases. Le filtre de relecture qui ne
## connaîtrait que les compétences les jetterait en silence, au premier
## rechargement, sur des fichiers intacts — et rien ne le dirait.
##
## Aucun champ neuf pour autant, et c'est ce que la première assertion vérifie.
func test_passive_and_node_points_survive_the_round_trip() -> void:
	var p := Character.create_new("Talentueuse", 0)
	var book := Item.new(ItemCatalog.by_id("manual_lightning"), [], 30)
	book.manual.experience = 5000
	book.manual.points["swift_bolt"] = 3
	book.manual.points["swift_bolt_overload"] = 2
	book.manual.points["conductor"] = 4
	p.rack.put(0, book)

	var source := p.to_dict()
	assert_eq(source["rack"][0]["manual"].keys(), ["exp", "points"], "le même dictionnaire, aucun champ neuf")

	var reread := Character.from_dict(source)
	assert_not_null(reread)
	var refunded := reread.rack.at(0)
	assert_eq(refunded.manual.points_of("swift_bolt"), 3, "la case")
	assert_eq(refunded.manual.points_of("swift_bolt_overload"), 2, "le nœud d'arbre")
	assert_eq(refunded.manual.points_of("conductor"), 4, "et le passif")
	assert_eq(refunded.manual.points_spent(), 9)


## Des points placés dans une case que l'archétype n'a plus ne sont dépensables
## nulle part : les garder ferait un manuel qui doit des points à personne.
func test_points_for_an_unknown_skill_are_ignored() -> void:
	var p := Character.create_new("Strikeout", 0)
	var book := Item.new(ItemCatalog.by_id("manual_lightning"))
	book.manual.points["swift_bolt"] = 1
	p.bag.place(book, Vector2i(0, 0))
	var source := p.to_dict()
	source["bag"][0]["manual"]["points"]["cell_that_no_longer_exists"] = 4
	source["bag"][0]["manual"]["points"]["node_from_another_book"] = 2

	var reread := Character.from_dict(source)
	assert_not_null(reread)
	var refunded: Item = reread.bag.placed[0].data
	assert_eq(refunded.manual.points_of("swift_bolt"), 1, "ce que le livre enseigne reste")
	assert_eq(refunded.manual.points_of("cell_that_no_longer_exists"), 0, "le reste est oublié")
	assert_eq(refunded.manual.points_of("node_from_another_book"), 0, "un nœud étranger aussi")
	assert_eq(refunded.manual.points_spent(), 1)


## Une sauvegarde d'avant le jalon 6 arrive avec le jeu d'avant : rien au
## râtelier, le coup d'épée et le tir sous les doigts, et un manuel de départ
## qu'on n'a pas encore reçu.
func test_a_version_2_arrives_with_the_former_game() -> void:
	var file := FileAccess.open("res://tests/fixtures/character_v2.json", FileAccess.READ)
	assert_not_null(file)
	var content: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	var p := Character.from_dict(content)
	assert_not_null(p)
	assert_true(p.rack.empty(), "aucun manuel à l'étude")
	assert_eq(p.bar.id_of(0), SkillCatalog.ID_ATTACK, "le coup d'épée")
	assert_eq(p.bar.id_of(1), SkillCatalog.ID_BOLT, "et le tir")
	assert_eq(p.bar.id_of(2), "", "rien d'autre")
	assert_false(p.manual_given, "le manuel de départ reste à donner")


## Le format qu'on écrit aujourd'hui, figé dans le dépôt à côté de ceux d'hier.
## Il attrape ce qu'un aller-retour en mémoire laisse passer : un champ renommé
## des deux côtés à la fois.
func test_the_v3_reference_file_rereads() -> void:
	var file := FileAccess.open("res://tests/fixtures/character_v3.json", FileAccess.READ)
	assert_not_null(file, "le fichier de référence est bien dans le dépôt")
	var content: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	var p := Character.from_dict(content)
	assert_not_null(p, "une sauvegarde de version 3 se lit")
	assert_eq(p.name, "Brenna")
	assert_true(p.manual_given, "celui-ci a déjà eu son manuel")

	var studied := p.rack.at(0)
	assert_not_null(studied, "le manuel du râtelier")
	assert_eq(studied.base.id, "manual_lightning")
	assert_eq(studied.item_level, 30)
	assert_eq(studied.manual.experience, 340)
	assert_eq(studied.manual.points_of("swift_bolt"), 3)

	assert_eq(p.bar.id_of(2), "swift_bolt", "la case du milieu")
	assert_eq(p.bar.id_of(3), "", "et les deux dernières sont vides")

	# Un second manuel dort dans le sac, vierge : c'est le cas qu'on oublie —
	# celui qui n'apprend rien parce qu'il n'est pas à l'étude.
	var store_in_bag := 0
	for placed in p.bag.placed:
		if placed.data.manual != null:
			store_in_bag += 1
			assert_eq(placed.data.manual.points_spent(), 0)
	assert_eq(store_in_bag, 1)


# --------------------------------------------------------------------------
# La portée d'un affixe (jalon 7, version 4)
# --------------------------------------------------------------------------

## La portée traverse le disque. Perdue, un « +1 projectile » relu deviendrait une
## ligne de fiche visant un champ que la fiche n'a pas.
func test_an_affix_scope_survives_the_round_trip() -> void:
	var p := Character.create_new("Scope", 0)
	p.equipment["weapon"] = Item.new(ItemCatalog.by_id("wand"), [
		ItemAffixPool.by_id("forked").modifier(1.0),
		StatMod.new("max_mana", StatMod.Mode.FLAT, 4.0),
	])

	var dict := p.to_dict()
	var written_all: Array = dict["equipment"]["weapon"]["affixes"]
	assert_eq(written_all[0]["scope"], Keywords.PROJECTILE, "écrite quand elle existe")
	assert_false((written_all[1] as Dictionary).has("scope"), "et absente d'une ligne de fiche")

	var reread_all: Array[RolledAffix] = Character.from_dict(dict).equipment["weapon"].explicits
	assert_eq(reread_all[0].mod.scope, Keywords.PROJECTILE)
	assert_eq(reread_all[0].mod.stat, "projectiles")
	assert_eq(reread_all[1].mod.scope, "", "la ligne de fiche le reste")


## Le format qu'on écrit aujourd'hui, avec une ligne de fiche et deux lignes
## portées sur la même baguette.
func test_the_v4_reference_file_rereads() -> void:
	var file := FileAccess.open("res://tests/fixtures/character_v4.json", FileAccess.READ)
	assert_not_null(file, "le fichier de référence est bien dans le dépôt")
	var content: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	var p := Character.from_dict(content)
	assert_not_null(p, "une sauvegarde de version 4 se lit")
	assert_eq(p.name, "Ysolde")

	var wand: Item = p.equipment["weapon"]
	var scopes := []
	for r in wand.explicits:
		scopes.append(r.mod.scope)
	# La première ligne était « +5 dégâts de sort » : la version 5 la relit en
	# foudre ajoutée aux sorts. Les deux lignes portées passent telles quelles.
	assert_eq(scopes, [Keywords.SPELL, Keywords.PROJECTILE, Keywords.LIGHTNING])
	assert_eq(wand.explicits[2].mod.stat, "damage")
	assert_eq(wand.explicits[2].tier, 5, "avec sa provenance")


# --------------------------------------------------------------------------
# Les fourchettes et la conversion des dégâts plats (jalon 8, version 5)
# --------------------------------------------------------------------------

## Le format qu'on écrit aujourd'hui : deux lignes de dégâts ajoutés, avec leur
## borne haute.
func test_the_v5_reference_file_rereads() -> void:
	var file := FileAccess.open("res://tests/fixtures/character_v5.json", FileAccess.READ)
	assert_not_null(file, "le fichier de référence est bien dans le dépôt")
	var content: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	var p := Character.from_dict(content)
	assert_not_null(p, "une sauvegarde de version 5 se lit")
	var sword: Item = p.equipment["weapon"]
	var fire: StatMod = sword.explicits[0].mod
	assert_eq(fire.stat, "damage_fire")
	assert_eq(fire.value, 3.0)
	assert_eq(fire.value_max, 8.0, "la borne haute écrite dans le fichier")
	assert_eq(fire.scope, Keywords.ATTACK)
	assert_true(sword.explicits[0].known(), "une ligne du format courant garde sa provenance")
	assert_eq(p.equipment["offhand"].explicits[0].mod.value_max, 5.0)


## Un objet relu d'un fichier de version 4, portant ces lignes.
func _version_4_item(lines: Array) -> Item:
	var dict := Character.create_new("Ancien", 0).to_dict()
	dict["version"] = 4
	dict["equipment"] = {"weapon": {"base": "sword", "level": 10, "affixes": lines}}
	var reread: Variant = JSON.parse_string(JSON.stringify(dict))
	return Character.from_dict(reread).equipment["weapon"]


## « +6 dégâts » faisait six points de plus à la seule attaque du jeu, qui était
## physique : « ajoute 6 à 6 dégâts physiques aux attaques » fait exactement ça.
func test_attack_damage_becomes_physical_to_attacks() -> void:
	var line: RolledAffix = _version_4_item([
		{"stat": "attack_damage", "mode": 0, "value": 6.0, "affix": "sharp", "tier": 7},
	]).explicits[0]
	assert_eq(line.mod.stat, "damage_physical")
	assert_eq(line.mod.value, 6.0)
	assert_eq(line.mod.value_max, 6.0)
	assert_eq(line.mod.scope, Keywords.ATTACK)
	assert_false(line.known(), "le palier 7 d'acéré n'est pas un palier du nouvel affixe")


## Tous les sorts étaient de foudre : des dégâts de sort étaient de la foudre.
func test_spell_damage_becomes_lightning_to_spells() -> void:
	var line: RolledAffix = _version_4_item([
		{"stat": "spell_damage", "mode": 0, "value": 5.0, "affix": "arcane", "tier": 6},
	]).explicits[0]
	assert_eq(line.mod.stat, "damage_lightning")
	assert_eq(line.mod.value_max, 5.0)
	assert_eq(line.mod.scope, Keywords.SPELL)


## La seule perte du jalon : un pourcentage de dégâts n'a plus rien à multiplier.
## La ligne part, et le reste de l'objet reste.
func test_a_damage_percentage_is_removed() -> void:
	var sword := _version_4_item([
		{"stat": "attack_damage", "mode": 1, "value": 12.0, "affix": "murderous", "tier": 3},
		{"stat": "attack_speed", "mode": 1, "value": 8.0},
	])
	assert_eq(sword.explicits.size(), 1, "seule la vitesse reste")
	assert_eq(sword.explicits[0].mod.stat, "attack_speed")


## Jalon 18 : une chance critique plate ne se garde que sur une arme, où elle monte la
## base. Ailleurs elle n'a pas d'équivalent en accru, et part.
func test_a_flat_crit_outside_a_weapon_is_removed() -> void:
	var p := Character.create_new("Critique", 0)
	var crit := StatMod.new("crit_chance", StatMod.Mode.FLAT, 0.05)
	p.equipment["weapon"] = Item.new(ItemCatalog.by_id("sword"), [crit] as Array[StatMod])
	p.equipment["gloves"] = Item.new(ItemCatalog.by_id("gloves"), [
		crit, StatMod.new("crit_chance", StatMod.Mode.PERCENT, 20.0),
	] as Array[StatMod])
	var after := _round_trip(p)
	assert_eq(after.equipment["weapon"].explicits.size(), 1, "sur l'arme, elle reste")
	var gloves: Item = after.equipment["gloves"]
	assert_eq(gloves.explicits.size(), 1, "sur les gants, seul l'accru reste")
	assert_eq(gloves.explicits[0].mod.mode, StatMod.Mode.PERCENT)


## Une borne haute plus basse que la basse — un fichier trafiqué — ne donne pas
## une fourchette à l'envers.
func test_a_reversed_range_is_straightened() -> void:
	var line: RolledAffix = _version_4_item([
		{"stat": "damage_fire", "mode": 0, "value": 9.0, "value_max": 2.0, "scope": "attack"},
	]).explicits[0]
	assert_eq(line.mod.value_max, 9.0)


func test_the_v6_reference_file_rereads() -> void:
	var content: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/character_v6.json"))
	var p := Character.from_dict(content)
	assert_not_null(p, "une sauvegarde de version 6 se lit")
	assert_eq(p.equipment["weapon"].base.id, "sword")
	assert_eq(p.rack.at(0).manual.points["swift_bolt"], 4)
	assert_eq(p.bar.id_of(2), "swift_bolt")


func test_the_v7_reference_file_rereads() -> void:
	var content: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/character_v7.json"))
	var p := Character.from_dict(content)
	assert_not_null(p, "une sauvegarde de version 7 se lit")
	# Écrite avant le jalon 17 : « int_4 » n'est plus voisin d'« int_2 », il part à la
	# relecture avec ce qui le suit, et leurs points reviennent (jalon 17, §6).
	assert_eq(p.passives, PackedStringArray(["int_1", "int_2"]))
	assert_eq(p.rack.at(0).manual.points["swift_bolt"], 4)


## La v5 et la v6 disent la même chose, l'une aux noms français, l'autre aux noms
## anglais : relues, elles donnent le même personnage. C'est la preuve que
## `LegacyFrench` n'oublie rien de ce qu'une v5 porte.
func test_the_v5_and_v6_files_give_the_same_character() -> void:
	var written := []
	for version in [5, 6]:
		var path := "res://tests/fixtures/character_v%d.json" % version
		var d := Character.from_dict(JSON.parse_string(FileAccess.get_file_as_string(path))).to_dict()
		d.erase("id")
		d.erase("played_on")
		written.append(JSON.stringify(d))
	assert_eq(written[0], written[1])


## Un nom de personnage n'est pas un identifiant, même quand il en a l'orthographe.
func test_a_french_save_keeps_the_name_as_written() -> void:
	var dict := Character.create_new("epee", 0).to_dict()
	dict["version"] = 5
	dict["nom"] = dict["name"]
	dict.erase("name")
	assert_eq(Character.from_dict(dict).name, "epee")
