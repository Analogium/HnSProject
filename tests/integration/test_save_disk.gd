extends GutTest

## La couche disque. Pas de nœud ici non plus, mais ça touche un vrai système de
## fichiers — un aller-retour en mémoire ne prouve pas qu'un fichier écrit se
## relit. C'est ce qui range ces tests avec l'intégration.
##
## Ils écrivent dans le `user://` de la copie temporaire du projet : le lanceur
## fait tourner la campagne sous un nom de projet distinct, donc rien n'atterrit
## dans les données du vrai jeu.

const NAME := "Sauvegardée"

var _created: PackedStringArray


func before_each() -> void:
	_created = PackedStringArray()


## Chaque test range derrière lui : un personnage oublié ferait passer ou échouer
## le test suivant selon l'ordre d'exécution.
func after_each() -> void:
	for id in _created:
		SaveStore.delete(id)


func _write(p: Character) -> bool:
	_created.append(p.id)
	return SaveStore.write(p)


func _played_character() -> Character:
	var p := Character.create_new(NAME, 1)
	p.level = 4
	p.experience = 90
	p.attributes["dexterity"] = 6
	p.unspent_points = 2
	p.bag.place(Item.new(ItemCatalog.by_id("sword"), [
		StatMod.ranged("damage_physical", 3.0, 7.0, Keywords.ATTACK),
	] as Array[StatMod]), Vector2i(2, 0))
	p.equipment["chest"] = Item.new(ItemCatalog.by_id("breastplate"))
	return p


## Le critère de réussite du jalon, en petit : jouer, écrire, tout retrouver.
func test_write_then_reread_gives_the_same_character() -> void:
	var before := _played_character()
	assert_true(_write(before), "écriture réussie")

	var after := SaveStore.read(before.id)
	assert_not_null(after, "le fichier se relit")
	assert_eq(after.name, NAME)
	assert_eq(after.level, 4)
	assert_eq(after.experience, 90)
	assert_eq(after.attributes["dexterity"], 6)
	assert_eq(after.unspent_points, 2)
	assert_eq(after.bag.placed.size(), 1)
	assert_eq(after.bag.placed[0].cell, Vector2i(2, 0))
	assert_eq(after.equipment["chest"].base.id, "breastplate")
	assert_false(after.unreadable)


func test_saving_stamps_today_date() -> void:
	var p := _played_character()
	p.played_on = "2020-01-01"
	_write(p)
	assert_eq(p.played_on, Time.get_date_string_from_system(), "sauvegarder, c'est avoir joué")
	assert_eq(SaveStore.read(p.id).played_on, p.played_on, "et c'est ce qui est sur le disque")


func test_the_list_contains_what_was_written() -> void:
	var a := _played_character()
	var b := Character.create_new("Autre", 3)
	_write(a)
	_write(b)

	var ids := Array(SaveStore.ids())
	assert_true(ids.has(a.id), "le premier est listé")
	assert_true(ids.has(b.id), "le second aussi")

	var names := []
	for p in SaveStore.list_all():
		names.append(p.name)
	assert_true(names.has(NAME) and names.has("Autre"), "et list_all() les charge tous les deux")


func test_rewriting_replaces_instead_of_stacking() -> void:
	var p := _played_character()
	_write(p)
	var before := SaveStore.ids().size()

	p.level = 12
	_write(p)
	assert_eq(SaveStore.ids().size(), before, "toujours un seul fichier")
	assert_eq(SaveStore.read(p.id).level, 12, "et c'est la nouvelle version")


## Un `.tmp` qui traîne est le reste d'une écriture coupée. Après une écriture
## réussie il ne doit plus en rester, et il ne doit jamais entrer dans la liste.
func test_writing_leaves_no_temporary_file() -> void:
	var p := _played_character()
	_write(p)
	assert_false(
		FileAccess.file_exists(SaveStore.path(p.id) + SaveStore.TEMPORARY),
		"le temporaire a été renommé"
	)
	for id in SaveStore.ids():
		assert_false(id.ends_with(".json"), "aucun identifiant ne porte d'extension")


func test_delete_really_erases() -> void:
	var p := _played_character()
	_write(p)
	assert_true(SaveStore.exists(p.id))
	assert_true(SaveStore.delete(p.id))
	assert_false(SaveStore.exists(p.id), "le fichier est parti")
	assert_null(SaveStore.read(p.id), "et le relire ne plante pas")
	assert_false(Array(SaveStore.ids()).has(p.id))


func test_create_writes_immediately() -> void:
	var p := SaveStore.create("Neuve", 2)
	assert_not_null(p)
	_created.append(p.id)
	assert_true(SaveStore.exists(p.id), "un personnage créé existe sur le disque avant d'avoir joué")
	assert_eq(SaveStore.read(p.id).name, "Neuve")


## Le cas qui ne doit surtout pas faire tomber l'écran de sélection : un fichier
## à moitié écrit, ou trafiqué à la main.
func test_a_truncated_file_is_cleanly_refused() -> void:
	var p := _played_character()
	_write(p)

	var text_value := FileAccess.get_file_as_string(SaveStore.path(p.id))
	var maimed := FileAccess.open(SaveStore.path(p.id), FileAccess.WRITE)
	maimed.store_string(text_value.substr(0, text_value.length() / 2))
	maimed.close()

	assert_null(SaveStore.read(p.id), "on ne lit pas la moitié d'un personnage")

	var list := SaveStore.list_all()
	var found: Character = null
	for entry in list:
		if entry.id == p.id:
			found = entry
	assert_not_null(found, "il reste dans la liste plutôt que de disparaître")
	assert_true(found.unreadable, "marqué comme illisible, à griser dans le menu")


func test_an_unknown_version_on_disk_is_greyed() -> void:
	var p := _played_character()
	_write(p)
	var dict := p.to_dict()
	dict["version"] = 42
	var f := FileAccess.open(SaveStore.path(p.id), FileAccess.WRITE)
	f.store_string(JSON.stringify(dict))
	f.close()

	assert_null(SaveStore.read(p.id))
	var list := SaveStore.list_all()
	assert_gt(list.size(), 0, "list_all() ne plante pas sur une version future")


## Au tout premier lancement il n'y a pas encore de dossier. Ce n'est pas une
## erreur, c'est l'état normal.
func test_a_nonexistent_character_returns_null() -> void:
	assert_null(SaveStore.read("p_that_does_not_exist"))
	assert_false(SaveStore.exists("p_that_does_not_exist"))


## Un personnage marqué illisible ne doit jamais être réécrit : on écraserait le
## fichier qu'on n'a pas su lire, donc la seule copie des données du joueur.
func test_an_unreadable_character_is_not_overwritten() -> void:
	assert_false(SaveStore.write(Character.unreadable_with("p_damaged")))
	assert_false(SaveStore.write(null))


## Les personnages d'avant la traduction du code vivent dans l'ancien dossier : au
## premier passage il prend le nouveau nom, et ils se listent comme les autres.
func test_the_old_save_folder_is_moved() -> void:
	DirAccess.remove_absolute(SaveStore.FOLDER)
	assert_false(DirAccess.dir_exists_absolute(SaveStore.FOLDER), "le nouveau dossier part vide")
	DirAccess.make_dir_recursive_absolute(LegacyFrench.SAVE_FOLDER)
	var p := Character.create_new(NAME, 0)
	var file := FileAccess.open("%s/%s.json" % [LegacyFrench.SAVE_FOLDER, p.id], FileAccess.WRITE)
	file.store_string(JSON.stringify(p.to_dict()))
	file.close()
	_created.append(p.id)

	assert_true(SaveStore.ids().has(p.id), "listé depuis le nouveau dossier")
	assert_false(DirAccess.dir_exists_absolute(LegacyFrench.SAVE_FOLDER), "l'ancien n'existe plus")
