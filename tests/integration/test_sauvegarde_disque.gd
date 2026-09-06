extends GutTest

## La couche disque. Pas de nœud ici non plus, mais ça touche un vrai système de
## fichiers — un aller-retour en mémoire ne prouve pas qu'un fichier écrit se
## relit. C'est ce qui range ces tests avec l'intégration.
##
## Ils écrivent dans le `user://` de la copie temporaire du projet : le lanceur
## fait tourner la campagne sous un nom de projet distinct, donc rien n'atterrit
## dans les données du vrai jeu.

const NOM := "Sauvegardée"

var _crees: PackedStringArray


func before_each() -> void:
	_crees = PackedStringArray()


## Chaque test range derrière lui : un personnage oublié ferait passer ou échouer
## le test suivant selon l'ordre d'exécution.
func after_each() -> void:
	for id in _crees:
		Sauvegarde.supprimer(id)


func _ecrire(p: Personnage) -> bool:
	_crees.append(p.id)
	return Sauvegarde.ecrire(p)


func _personnage_joue() -> Personnage:
	var p := Personnage.nouveau(NOM, 1)
	p.niveau = 4
	p.experience = 90
	p.attributs["dexterity"] = 6
	p.points_a_placer = 2
	p.sac.place(Item.new(ItemCatalog.by_id("epee"), [
		StatMod.new("attack_damage", StatMod.Mode.FLAT, 5.0),
	] as Array[StatMod]), Vector2i(2, 0))
	p.equipement["chest"] = Item.new(ItemCatalog.by_id("plastron"))
	return p


## Le critère de réussite du jalon, en petit : jouer, écrire, tout retrouver.
func test_ecrire_puis_relire_rend_le_meme_personnage() -> void:
	var avant := _personnage_joue()
	assert_true(_ecrire(avant), "écriture réussie")

	var apres := Sauvegarde.lire(avant.id)
	assert_not_null(apres, "le fichier se relit")
	assert_eq(apres.nom, NOM)
	assert_eq(apres.niveau, 4)
	assert_eq(apres.experience, 90)
	assert_eq(apres.attributs["dexterity"], 6)
	assert_eq(apres.points_a_placer, 2)
	assert_eq(apres.sac.placed.size(), 1)
	assert_eq(apres.sac.placed[0].cell, Vector2i(2, 0))
	assert_eq(apres.equipement["chest"].base.id, "plastron")
	assert_false(apres.illisible)


func test_sauvegarder_marque_la_date_du_jour() -> void:
	var p := _personnage_joue()
	p.joue_le = "2020-01-01"
	_ecrire(p)
	assert_eq(p.joue_le, Time.get_date_string_from_system(), "sauvegarder, c'est avoir joué")
	assert_eq(Sauvegarde.lire(p.id).joue_le, p.joue_le, "et c'est ce qui est sur le disque")


func test_la_liste_contient_ce_qu_on_a_ecrit() -> void:
	var a := _personnage_joue()
	var b := Personnage.nouveau("Autre", 3)
	_ecrire(a)
	_ecrire(b)

	var ids := Array(Sauvegarde.ids())
	assert_true(ids.has(a.id), "le premier est listé")
	assert_true(ids.has(b.id), "le second aussi")

	var noms := []
	for p in Sauvegarde.lister():
		noms.append(p.nom)
	assert_true(noms.has(NOM) and noms.has("Autre"), "et lister() les charge tous les deux")


func test_reecrire_remplace_au_lieu_d_empiler() -> void:
	var p := _personnage_joue()
	_ecrire(p)
	var avant := Sauvegarde.ids().size()

	p.niveau = 12
	_ecrire(p)
	assert_eq(Sauvegarde.ids().size(), avant, "toujours un seul fichier")
	assert_eq(Sauvegarde.lire(p.id).niveau, 12, "et c'est la nouvelle version")


## Un `.tmp` qui traîne est le reste d'une écriture coupée. Après une écriture
## réussie il ne doit plus en rester, et il ne doit jamais entrer dans la liste.
func test_l_ecriture_ne_laisse_pas_de_fichier_temporaire() -> void:
	var p := _personnage_joue()
	_ecrire(p)
	assert_false(
		FileAccess.file_exists(Sauvegarde.chemin(p.id) + Sauvegarde.TEMPORAIRE),
		"le temporaire a été renommé"
	)
	for id in Sauvegarde.ids():
		assert_false(id.ends_with(".json"), "aucun identifiant ne porte d'extension")


func test_supprimer_efface_vraiment() -> void:
	var p := _personnage_joue()
	_ecrire(p)
	assert_true(Sauvegarde.existe(p.id))
	assert_true(Sauvegarde.supprimer(p.id))
	assert_false(Sauvegarde.existe(p.id), "le fichier est parti")
	assert_null(Sauvegarde.lire(p.id), "et le relire ne plante pas")
	assert_false(Array(Sauvegarde.ids()).has(p.id))


func test_creer_ecrit_tout_de_suite() -> void:
	var p := Sauvegarde.creer("Neuve", 2)
	assert_not_null(p)
	_crees.append(p.id)
	assert_true(Sauvegarde.existe(p.id), "un personnage créé existe sur le disque avant d'avoir joué")
	assert_eq(Sauvegarde.lire(p.id).nom, "Neuve")


## Le cas qui ne doit surtout pas faire tomber l'écran de sélection : un fichier
## à moitié écrit, ou trafiqué à la main.
func test_un_fichier_tronque_est_refuse_proprement() -> void:
	var p := _personnage_joue()
	_ecrire(p)

	var texte := FileAccess.get_file_as_string(Sauvegarde.chemin(p.id))
	var mutile := FileAccess.open(Sauvegarde.chemin(p.id), FileAccess.WRITE)
	mutile.store_string(texte.substr(0, texte.length() / 2))
	mutile.close()

	assert_null(Sauvegarde.lire(p.id), "on ne lit pas la moitié d'un personnage")

	var liste := Sauvegarde.lister()
	var trouve: Personnage = null
	for entree in liste:
		if entree.id == p.id:
			trouve = entree
	assert_not_null(trouve, "il reste dans la liste plutôt que de disparaître")
	assert_true(trouve.illisible, "marqué comme illisible, à griser dans le menu")


func test_une_version_inconnue_sur_le_disque_est_grisee() -> void:
	var p := _personnage_joue()
	_ecrire(p)
	var dict := p.vers_dict()
	dict["version"] = 42
	var f := FileAccess.open(Sauvegarde.chemin(p.id), FileAccess.WRITE)
	f.store_string(JSON.stringify(dict))
	f.close()

	assert_null(Sauvegarde.lire(p.id))
	var liste := Sauvegarde.lister()
	assert_gt(liste.size(), 0, "lister() ne plante pas sur une version future")


## Au tout premier lancement il n'y a pas encore de dossier. Ce n'est pas une
## erreur, c'est l'état normal.
func test_un_personnage_inexistant_rend_null() -> void:
	assert_null(Sauvegarde.lire("p_qui_n_existe_pas"))
	assert_false(Sauvegarde.existe("p_qui_n_existe_pas"))


## Un personnage marqué illisible ne doit jamais être réécrit : on écraserait le
## fichier qu'on n'a pas su lire, donc la seule copie des données du joueur.
func test_on_n_ecrase_pas_un_personnage_illisible() -> void:
	assert_false(Sauvegarde.ecrire(Personnage.illisible_avec("p_abime")))
	assert_false(Sauvegarde.ecrire(null))
