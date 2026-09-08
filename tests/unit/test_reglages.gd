extends GutTest

## Les réglages du joueur : la taille de la fenêtre, et le fait qu'ils survivent
## à la fermeture du jeu.
##
## Deux règles s'écrivent facilement de travers ici, et aucune ne se voit sans
## être essayée sur la bonne machine : le plus grand facteur qui tient dans un
## écran, et la ronde du bouton. Toutes deux sont donc **pures** — on leur donne
## l'écran, elles ne le demandent pas — et ce fichier les met à l'épreuve sur des
## écrans que la machine de test n'a pas.

const BASE := Vector2i(640, 360)


# --------------------------------------------------------------------------
# Le facteur qui tient dans l'écran
# --------------------------------------------------------------------------

## Le cas ordinaire, sur les écrans qu'on croise vraiment.
func test_le_facteur_suit_l_ecran() -> void:
	assert_eq(Settings.echelle_qui_tient(Vector2i(1920, 1080), BASE), 3, "1080p")
	assert_eq(Settings.echelle_qui_tient(Vector2i(2560, 1440), BASE), 4, "1440p")
	assert_eq(Settings.echelle_qui_tient(Vector2i(3840, 2160), BASE), 6, "4K")
	assert_eq(Settings.echelle_qui_tient(Vector2i(1280, 720), BASE), 2, "720p")


## C'est la **plus petite** des deux dimensions qui décide. Un écran large et bas
## — une barre des tâches mange la hauteur, un ultra-large la donne en largeur —
## tiendrait sinon un facteur qui déborde par le bas, et la barre de vie du
## joueur passerait sous le bureau.
func test_c_est_la_dimension_la_plus_serree_qui_decide() -> void:
	assert_eq(
		Settings.echelle_qui_tient(Vector2i(3440, 1000), BASE), 2,
		"ultra-large mais court : la hauteur commande"
	)
	assert_eq(
		Settings.echelle_qui_tient(Vector2i(1300, 2000), BASE), 2,
		"étroit et haut : la largeur commande"
	)


## Un écran plus petit que le cadrage du jeu doit quand même pouvoir le lancer.
## Zéro serait une fenêtre de taille nulle, donc rien à l'écran du tout.
func test_un_petit_ecran_rend_au_moins_un() -> void:
	assert_eq(Settings.echelle_qui_tient(Vector2i(400, 300), BASE), 1)
	assert_eq(Settings.echelle_qui_tient(Vector2i(1, 1), BASE), 1)


## Une base absurde ne doit pas diviser par zéro. Elle ne peut venir que d'un
## réglage de projet effacé, mais planter au démarrage pour ça serait cher payé.
func test_une_base_nulle_ne_divise_pas_par_zero() -> void:
	assert_eq(Settings.echelle_qui_tient(Vector2i(1920, 1080), Vector2i.ZERO), 1)


# --------------------------------------------------------------------------
# La ronde du bouton
# --------------------------------------------------------------------------

## On monte jusqu'au maximum de l'écran, puis on passe en plein écran, puis on
## revient au plus petit. Le plein écran est **après** les facteurs : on en sort
## en continuant d'appuyer, sans deviner qu'il faudrait revenir en arrière.
func test_la_ronde_passe_par_le_plein_ecran_puis_revient() -> void:
	assert_eq(Settings.echelle_suivante(1, 3), 2)
	assert_eq(Settings.echelle_suivante(2, 3), 3)
	assert_eq(Settings.echelle_suivante(3, 3), Settings.PLEIN_ECRAN, "au bout : plein écran")
	assert_eq(Settings.echelle_suivante(Settings.PLEIN_ECRAN, 3), 1, "puis on repart à ×1")


## Un écran qui ne tient qu'un seul facteur ne doit pas piéger le joueur dans le
## plein écran ni dans la fenêtre : la ronde marche à deux valeurs.
func test_la_ronde_marche_avec_un_seul_facteur() -> void:
	assert_eq(Settings.echelle_suivante(1, 1), Settings.PLEIN_ECRAN)
	assert_eq(Settings.echelle_suivante(Settings.PLEIN_ECRAN, 1), 1)


## Un facteur enregistré sur un écran plus grand ne doit pas bloquer la ronde :
## elle repart vers le plein écran plutôt que de monter vers l'inatteignable.
func test_un_facteur_trop_grand_redescend() -> void:
	assert_eq(Settings.echelle_suivante(5, 3), Settings.PLEIN_ECRAN)


# --------------------------------------------------------------------------
# Le libellé
# --------------------------------------------------------------------------

## Le bouton annonce la taille en pixels et pas seulement le facteur : « ×3 » ne
## dit rien tant qu'on ne connaît pas le cadrage de départ.
func test_le_libelle_dit_la_taille_obtenue() -> void:
	assert_eq(Settings.libelle(2, BASE), "Fenêtre : ×2  (1280 × 720)")
	assert_eq(Settings.libelle(3, BASE), "Fenêtre : ×3  (1920 × 1080)")
	assert_eq(Settings.libelle(Settings.PLEIN_ECRAN, BASE), "Fenêtre : plein écran")


## La taille de base vient des réglages du projet et n'est pas recopiée : c'est
## elle qui décide de tout le reste, et deux définitions de 640 × 360 finiraient
## par se contredire.
func test_la_taille_de_base_vient_du_projet() -> void:
	assert_eq(Settings.taille_de_base(), BASE)


# --------------------------------------------------------------------------
# Le disque
# --------------------------------------------------------------------------

## Aller-retour complet. Un réglage qui se remet à zéro à chaque lancement n'est
## pas un réglage.
func test_les_reglages_font_l_aller_retour() -> void:
	var avant := Settings.vers_dict()

	Settings.show_health_bars = false
	Settings.show_affix_names = false
	var ecrit := Settings.vers_dict()

	Settings.depuis_dict({"barres_de_vie": true, "noms_d_affixes": true, "echelle": 1})
	assert_true(Settings.show_health_bars)
	assert_true(Settings.show_affix_names)

	Settings.depuis_dict(ecrit)
	assert_false(Settings.show_health_bars, "les valeurs relues sont celles écrites")
	assert_false(Settings.show_affix_names)

	Settings.depuis_dict(avant)


## Un champ absent garde sa valeur plutôt que de faire échouer la lecture
## entière : un fichier écrit par une version plus ancienne doit encore servir.
func test_un_champ_absent_garde_sa_valeur() -> void:
	var avant := Settings.vers_dict()
	Settings.show_health_bars = true
	Settings.depuis_dict({"noms_d_affixes": false})
	assert_true(Settings.show_health_bars, "le champ absent n'a pas bougé")
	assert_false(Settings.show_affix_names, "le champ présent, si")
	Settings.depuis_dict(avant)


## Une valeur d'échelle qui n'est pas un nombre est ignorée plutôt que convertie
## en zéro — ce qui mettrait le jeu en plein écran sur un fichier abîmé.
func test_une_echelle_illisible_ne_met_pas_en_plein_ecran() -> void:
	var avant := Settings.vers_dict()
	Settings.depuis_dict({"echelle": 1})
	Settings.depuis_dict({"echelle": "grand"})
	assert_ne(Settings.echelle, Settings.PLEIN_ECRAN, "le texte n'est pas lu comme zéro")
	Settings.depuis_dict(avant)
