extends GutTest

## Les réglages sur le disque, avec un vrai fichier.
##
## `test_reglages.gd` couvre les règles ; celui-ci couvre le seul endroit où
## elles rencontrent le système de fichiers. C'est le maillon qu'un aller-retour
## en mémoire ne prouve pas : un fichier jamais écrit, un fichier écrit mais
## illisible, ou un fichier relu qui ne rend pas ce qu'on y a mis se comportent
## tous les trois comme « les réglages ne se retiennent pas ».

var _avant: Dictionary


func before_each() -> void:
	_avant = Settings.vers_dict()


func after_each() -> void:
	Settings.depuis_dict(_avant)
	DirAccess.remove_absolute(Settings.FICHIER)


## Le tour complet : on change un réglage, il part sur le disque, on le remet à
## l'envers en mémoire, on relit, il revient.
func test_un_reglage_change_revient_apres_relecture() -> void:
	Settings.show_health_bars = false
	assert_true(
		FileAccess.file_exists(Settings.FICHIER),
		"changer un réglage écrit le fichier, sans qu'on ait à le demander"
	)

	# Remis à l'envers par le chemin de **lecture** et non par une affectation :
	# écrire le réglage l'enverrait sur le disque, et on relirait ce qu'on vient
	# d'y mettre plutôt que ce qu'on veut vérifier.
	Settings.depuis_dict({"barres_de_vie": true})
	assert_true(Settings.show_health_bars, "remis à l'envers en mémoire")

	Settings._charger()
	assert_false(Settings.show_health_bars, "le disque fait foi au chargement")


## Le fichier reste lisible à la main. Une ligne par réglage, des noms en clair :
## on répare un fichier de réglages dans un éditeur de texte, ou on le supprime.
func test_le_fichier_est_lisible_a_la_main() -> void:
	Settings.show_affix_names = false
	var texte := FileAccess.get_file_as_string(Settings.FICHIER)
	assert_string_contains(texte, "noms_d_affixes")
	assert_string_contains(texte, "\n", "indenté, pas sur une seule ligne")

	var lecteur := JSON.new()
	assert_eq(lecteur.parse(texte), OK, "et c'est du JSON valide")


## Un fichier abîmé ne doit pas empêcher le jeu de démarrer : les valeurs par
## défaut s'appliquent et on continue. Perdre trois réglages est supportable,
## refuser de se lancer ne l'est pas.
func test_un_fichier_abime_ne_bloque_pas_le_demarrage() -> void:
	var fichier := FileAccess.open(Settings.FICHIER, FileAccess.WRITE)
	fichier.store_string("{ ceci n'est pas du JSON")
	fichier.close()

	Settings.show_health_bars = true
	Settings._charger()
	assert_true(Settings.show_health_bars, "la valeur en place a survécu")


## Aucun fichier au tout premier lancement : c'est l'état normal, pas une erreur,
## et il ne doit rien journaliser ni rien casser.
func test_l_absence_de_fichier_est_l_etat_normal() -> void:
	DirAccess.remove_absolute(Settings.FICHIER)
	assert_false(FileAccess.file_exists(Settings.FICHIER))
	Settings._charger()
	assert_true(true, "on est arrivé jusqu'ici")


## La lecture ne réécrit pas ce qu'elle vient de lire. Sans ce garde-fou, chaque
## champ relu déclencherait une écriture du fichier en cours de lecture.
func test_la_lecture_ne_reecrit_pas_le_fichier() -> void:
	Settings.show_health_bars = false
	var ecrit := FileAccess.get_file_as_string(Settings.FICHIER)

	DirAccess.remove_absolute(Settings.FICHIER)
	Settings.depuis_dict(JSON.parse_string(ecrit))
	assert_false(
		FileAccess.file_exists(Settings.FICHIER),
		"relire n'écrit rien"
	)
