extends GutTest

## L'écran d'accueil. Il a besoin de l'arbre — ses champs de saisie et ses
## boutons sont des nœuds — et il touche au disque, puisqu'il liste et crée de
## vrais personnages.
##
## Ce qui est vérifié ici, ce n'est pas le dessin : ce sont les décisions.
## Refuser un nom vide, exiger le nom exact avant de supprimer, ne pas proposer
## de jouer une sauvegarde qu'on n'a pas su lire.

var _ecran: SelectionPersonnage
var _crees: PackedStringArray


func before_each() -> void:
	# La liste est celle du disque : on part d'un dossier vide, sinon un
	# personnage laissé par un autre test décalerait toutes les positions.
	for id in Sauvegarde.ids():
		Sauvegarde.supprimer(id)
	_crees = PackedStringArray()
	_ecran = load("res://ui/selection_personnage.tscn").instantiate()
	add_child_autofree(_ecran)
	await wait_process_frames(1)


func after_each() -> void:
	for id in _crees:
		Sauvegarde.supprimer(id)
	Game.personnage = null


func _poser(nom: String) -> Personnage:
	var p := Sauvegarde.creer(nom, 0)
	_crees.append(p.id)
	return p


func test_un_dossier_vide_ne_plante_pas() -> void:
	_ecran.recharger()
	assert_null(_ecran.selection(), "aucun personnage à choisir")
	assert_true(_ecran.bouton_jouer.disabled, "et rien à jouer")
	assert_true(_ecran.bouton_supprimer.disabled)


func test_la_liste_montre_les_personnages_du_disque() -> void:
	_poser("Brenna")
	_poser("Aldric")
	_ecran.recharger()
	assert_eq(_ecran._personnages.size(), 2)
	assert_not_null(_ecran.selection())
	assert_false(_ecran.bouton_jouer.disabled)


func test_creer_ecrit_et_se_place_dessus() -> void:
	_ecran._ouvrir_creation()
	_ecran.champ_nom.text = "Neuve"
	_ecran._silhouette = 3
	_ecran._creer()

	assert_eq(_ecran._etat, SelectionPersonnage.Etat.LISTE, "la fenêtre s'est refermée")
	var choisi := _ecran.selection()
	assert_not_null(choisi)
	_crees.append(choisi.id)
	assert_eq(choisi.nom, "Neuve", "on est placé sur celui qu'on vient de créer")
	assert_eq(choisi.silhouette, 3, "avec la silhouette choisie")
	assert_true(Sauvegarde.existe(choisi.id), "et il est déjà sur le disque")


func test_un_nom_vide_est_refuse_sans_rien_ecrire() -> void:
	_ecran._ouvrir_creation()
	_ecran.champ_nom.text = "   "
	_ecran._creer()

	assert_eq(_ecran._etat, SelectionPersonnage.Etat.CREATION, "on reste sur la fenêtre")
	assert_false(_ecran.erreur_creation.text.is_empty(), "avec une raison affichée")
	assert_eq(Sauvegarde.ids().size(), 0, "aucun fichier créé")


## Agaçant exprès : c'est la seule action du jeu qui détruit des heures de jeu.
func test_supprimer_exige_le_nom_exact() -> void:
	var p := _poser("Brenna")
	_ecran.recharger()
	_ecran._ouvrir_suppression()

	_ecran.champ_confirmation.text = "brenna"
	_ecran._supprimer()
	assert_true(Sauvegarde.existe(p.id), "la casse compte")

	_ecran.champ_confirmation.text = ""
	_ecran._supprimer()
	assert_true(Sauvegarde.existe(p.id), "et un champ vide ne suffit pas")
	assert_false(_ecran.erreur_suppression.text.is_empty())


func test_supprimer_avec_le_nom_exact() -> void:
	var p := _poser("Brenna")
	_ecran.recharger()
	_ecran._ouvrir_suppression()
	_ecran.champ_confirmation.text = "Brenna"
	_ecran._supprimer()

	assert_false(Sauvegarde.existe(p.id), "le fichier est parti")
	assert_eq(_ecran._personnages.size(), 0, "et la liste s'est rafraîchie")


## Elle reste visible — la faire disparaître donnerait à croire que le
## personnage est perdu — mais on ne peut pas la jouer.
func test_une_sauvegarde_illisible_se_liste_sans_se_jouer() -> void:
	var p := _poser("Abimee")
	var f := FileAccess.open(Sauvegarde.chemin(p.id), FileAccess.WRITE)
	f.store_string("{ ceci n'est pas du JSON")
	f.close()

	_ecran.recharger()
	assert_eq(_ecran._personnages.size(), 1, "elle est dans la liste")
	assert_true(_ecran.selection().illisible)
	assert_true(_ecran.bouton_jouer.disabled, "mais injouable")
	assert_false(_ecran.bouton_supprimer.disabled, "et supprimable, elle")

	_ecran._jouer()
	assert_null(Game.personnage, "aucune partie n'a démarré")


## Sans nom lisible, il n'y a rien à retaper : le mot de confirmation prend le
## relais plutôt que de laisser une entrée impossible à supprimer.
func test_une_illisible_se_supprime_par_un_mot() -> void:
	var p := _poser("Abimee")
	var f := FileAccess.open(Sauvegarde.chemin(p.id), FileAccess.WRITE)
	f.store_string("tronqué")
	f.close()
	_ecran.recharger()

	_ecran._ouvrir_suppression()
	_ecran.champ_confirmation.text = SelectionPersonnage.MOT_SANS_NOM
	_ecran._supprimer()
	assert_false(Sauvegarde.existe(p.id))


func test_les_fleches_changent_de_personnage() -> void:
	_poser("Un")
	_poser("Deux")
	_poser("Trois")
	_ecran.recharger()
	var premier := _ecran.selection()

	_ecran._deplacer(1)
	assert_ne(_ecran.selection(), premier, "on a bougé")
	_ecran._deplacer(-1)
	assert_eq(_ecran.selection(), premier, "et on est revenu")
	_ecran._deplacer(-1)
	assert_eq(_ecran.selection(), premier, "sans sortir de la liste par le haut")
