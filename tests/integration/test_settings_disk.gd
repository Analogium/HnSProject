extends GutTest

## Les réglages sur le disque, avec un vrai fichier.
##
## `test_reglages.gd` couvre les règles ; celui-ci couvre le seul endroit où
## elles rencontrent le système de fichiers. C'est le maillon qu'un aller-retour
## en mémoire ne prouve pas : un fichier jamais écrit, un fichier écrit mais
## illisible, ou un fichier relu qui ne rend pas ce qu'on y a mis se comportent
## tous les trois comme « les réglages ne se retiennent pas ».

var _before: Dictionary


func before_each() -> void:
	_before = Settings.to_dict()


func after_each() -> void:
	Settings.from_dict(_before)
	DirAccess.remove_absolute(Settings.FILE)


## Le tour complet : on change un réglage, il part sur le disque, on le remet à
## l'envers en mémoire, on relit, il revient.
func test_a_changed_setting_comes_back_after_reread() -> void:
	Settings.show_health_bars = false
	assert_true(
		FileAccess.file_exists(Settings.FILE),
		"changer un réglage écrit le fichier, sans qu'on ait à le demander"
	)

	# Remis à l'envers par le chemin de **lecture** et non par une affectation :
	# écrire le réglage l'enverrait sur le disque, et on relirait ce qu'on vient
	# d'y mettre plutôt que ce qu'on veut vérifier.
	Settings.from_dict({"health_bars": true})
	assert_true(Settings.show_health_bars, "remis à l'envers en mémoire")

	Settings._load()
	assert_false(Settings.show_health_bars, "le disque fait foi au chargement")


## Le fichier reste lisible à la main. Une ligne par réglage, des noms en clair :
## on répare un fichier de réglages dans un éditeur de texte, ou on le supprime.
func test_the_file_is_readable_by_hand() -> void:
	Settings.show_affix_names = false
	var text_value := FileAccess.get_file_as_string(Settings.FILE)
	assert_string_contains(text_value, "affix_names")
	assert_string_contains(text_value, "\n", "indenté, pas sur une seule ligne")

	var reader := JSON.new()
	assert_eq(reader.parse(text_value), OK, "et c'est du JSON valide")


## Un fichier abîmé ne doit pas empêcher le jeu de démarrer : les valeurs par
## défaut s'appliquent et on continue. Perdre trois réglages est supportable,
## refuser de se lancer ne l'est pas.
func test_a_damaged_file_does_not_block_startup() -> void:
	var file := FileAccess.open(Settings.FILE, FileAccess.WRITE)
	file.store_string("{ ceci n'est pas du JSON")
	file.close()

	Settings.show_health_bars = true
	Settings._load()
	assert_true(Settings.show_health_bars, "la valeur en place a survécu")


## Aucun fichier au tout premier lancement : c'est l'état normal, pas une erreur,
## et il ne doit rien journaliser ni rien casser.
func test_missing_file_is_the_normal_state() -> void:
	DirAccess.remove_absolute(Settings.FILE)
	assert_false(FileAccess.file_exists(Settings.FILE))
	Settings._load()
	assert_true(true, "on est arrivé jusqu'ici")


## Le choix de la langue part sur le disque comme les autres réglages, et c'est
## lui qu'on retrouve au lancement suivant — pas la langue du système, qui ne
## décide qu'au tout premier.
func test_the_chosen_language_is_reread_from_disk() -> void:
	Settings.language = Settings.ENGLISH
	assert_true(FileAccess.file_exists(Settings.FILE), "le choix est écrit")

	Settings.from_dict({"language": Settings.FRENCH})
	assert_eq(Settings.language, Settings.FRENCH, "remis en français en mémoire")

	Settings._load()
	assert_eq(Settings.language, Settings.ENGLISH, "le disque fait foi au chargement")


## La lecture ne réécrit pas ce qu'elle vient de lire. Sans ce garde-fou, chaque
## champ relu déclencherait une écriture du fichier en cours de lecture.
func test_reading_does_not_rewrite_the_file() -> void:
	Settings.show_health_bars = false
	var written := FileAccess.get_file_as_string(Settings.FILE)

	DirAccess.remove_absolute(Settings.FILE)
	Settings.from_dict(JSON.parse_string(written))
	assert_false(
		FileAccess.file_exists(Settings.FILE),
		"relire n'écrit rien"
	)


## Des réglages écrits avant la traduction du code : ancien fichier, anciennes clés. Ils
## font foi tant que le nouveau fichier n'existe pas.
func test_old_french_settings_are_read() -> void:
	DirAccess.remove_absolute(Settings.FILE)
	var file := FileAccess.open(LegacyFrench.SETTINGS_FILE, FileAccess.WRITE)
	file.store_string(JSON.stringify({"barres_de_vie": false, "langue": Settings.FRENCH}))
	file.close()
	Settings.from_dict({"health_bars": true})

	Settings._load()
	DirAccess.remove_absolute(LegacyFrench.SETTINGS_FILE)
	assert_false(Settings.show_health_bars)
