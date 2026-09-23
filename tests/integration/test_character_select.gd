extends GutTest

## L'écran d'accueil. Il a besoin de l'arbre — ses champs de saisie et ses
## boutons sont des nœuds — et il touche au disque, puisqu'il liste et crée de
## vrais personnages.
##
## Ce qui est vérifié ici, ce n'est pas le dessin : ce sont les décisions.
## Refuser un nom vide, exiger le nom exact avant de supprimer, ne pas proposer
## de jouer une sauvegarde qu'on n'a pas su lire.

var _screen: CharacterSelect
var _created: PackedStringArray


func before_each() -> void:
	# La liste est celle du disque : on part d'un dossier vide, sinon un
	# personnage laissé par un autre test décalerait toutes les positions.
	for id in SaveStore.ids():
		SaveStore.delete(id)
	_created = PackedStringArray()
	_screen = load("res://ui/character_select.tscn").instantiate()
	add_child_autofree(_screen)
	await wait_process_frames(1)


func after_each() -> void:
	for id in _created:
		SaveStore.delete(id)
	Game.character = null


func _place(name: String) -> Character:
	var p := SaveStore.create(name, 0)
	_created.append(p.id)
	return p


func test_an_empty_folder_does_not_crash() -> void:
	_screen.reload()
	assert_null(_screen.selection(), "aucun personnage à choisir")
	assert_true(_screen.play_button.disabled, "et rien à jouer")
	assert_true(_screen.delete_button.disabled)


func test_the_list_shows_the_characters_on_disk() -> void:
	_place("Brenna")
	_place("Aldric")
	_screen.reload()
	assert_eq(_screen._characters.size(), 2)
	assert_not_null(_screen.selection())
	assert_false(_screen.play_button.disabled)


func test_create_writes_and_selects_it() -> void:
	_screen._open_creation()
	_screen.name_field.text = "Neuve"
	_screen._look = 3
	_screen._create()

	assert_eq(_screen._state, CharacterSelect.State.LIST, "la fenêtre s'est refermée")
	var selected := _screen.selection()
	assert_not_null(selected)
	_created.append(selected.id)
	assert_eq(selected.name, "Neuve", "on est placé sur celui qu'on vient de créer")
	assert_eq(selected.silhouette, 3, "avec la silhouette choisie")
	assert_eq(selected.character_class, Character.WARRIOR)
	assert_true(SaveStore.exists(selected.id), "et il est déjà sur le disque")


func test_the_last_look_creates_a_witch_wand_in_hand() -> void:
	_screen._open_creation()
	_screen.name_field.text = "Morgane"
	_screen._look = CharacterSelect.LOOKS.size() - 1
	_screen._create()

	var selected := _screen.selection()
	assert_not_null(selected)
	_created.append(selected.id)
	assert_eq(selected.character_class, Character.WITCH)
	var held: Item = selected.equipment[EquipmentSlots.WEAPON]
	assert_eq(held.base.id, ItemCatalog.ID_STARTING_WAND, "la baguette en main")
	assert_true(
		selected.bag.placed.any(func(p: Inventory.Placed) -> bool: return p.data.base.id == ItemCatalog.ID_STARTING_WEAPON),
		"l'épée au sac"
	)


func test_an_empty_name_is_refused_without_writing() -> void:
	_screen._open_creation()
	_screen.name_field.text = "   "
	_screen._create()

	assert_eq(_screen._state, CharacterSelect.State.CREATION, "on reste sur la fenêtre")
	assert_false(_screen.creation_error.text.is_empty(), "avec une raison affichée")
	assert_eq(SaveStore.ids().size(), 0, "aucun fichier créé")


## Agaçant exprès : c'est la seule action du jeu qui détruit des heures de jeu.
func test_delete_requires_the_exact_name() -> void:
	var p := _place("Brenna")
	_screen.reload()
	_screen._open_deletion()

	_screen.confirmation_field.text = "brenna"
	_screen._delete()
	assert_true(SaveStore.exists(p.id), "la casse compte")

	_screen.confirmation_field.text = ""
	_screen._delete()
	assert_true(SaveStore.exists(p.id), "et un champ vide ne suffit pas")
	assert_false(_screen.deletion_error.text.is_empty())


func test_delete_with_the_exact_name() -> void:
	var p := _place("Brenna")
	_screen.reload()
	_screen._open_deletion()
	_screen.confirmation_field.text = "Brenna"
	_screen._delete()

	assert_false(SaveStore.exists(p.id), "le fichier est parti")
	assert_eq(_screen._characters.size(), 0, "et la liste s'est rafraîchie")


## Elle reste visible — la faire disparaître donnerait à croire que le
## personnage est perdu — mais on ne peut pas la jouer.
func test_an_unreadable_save_is_listed_without_being_playable() -> void:
	var p := _place("Abimee")
	var f := FileAccess.open(SaveStore.path(p.id), FileAccess.WRITE)
	f.store_string("{ ceci n'est pas du JSON")
	f.close()

	_screen.reload()
	assert_eq(_screen._characters.size(), 1, "elle est dans la liste")
	assert_true(_screen.selection().unreadable)
	assert_true(_screen.play_button.disabled, "mais injouable")
	assert_false(_screen.delete_button.disabled, "et supprimable, elle")

	_screen._play()
	assert_null(Game.character, "aucune partie n'a démarré")


## Sans nom lisible, il n'y a rien à retaper : le mot de confirmation prend le
## relais plutôt que de laisser une entrée impossible à supprimer.
func test_an_unreadable_one_is_deleted_by_a_word() -> void:
	var p := _place("Abimee")
	var f := FileAccess.open(SaveStore.path(p.id), FileAccess.WRITE)
	f.store_string("tronqué")
	f.close()
	_screen.reload()

	_screen._open_deletion()
	_screen.confirmation_field.text = CharacterSelect.UNNAMED_WORD
	_screen._delete()
	assert_false(SaveStore.exists(p.id))


func test_arrows_change_character() -> void:
	_place("Un")
	_place("Deux")
	_place("Trois")
	_screen.reload()
	var first := _screen.selection()

	_screen._move(1)
	assert_ne(_screen.selection(), first, "on a bougé")
	_screen._move(-1)
	assert_eq(_screen.selection(), first, "et on est revenu")
	_screen._move(-1)
	assert_eq(_screen.selection(), first, "sans sortir de la liste par le haut")
