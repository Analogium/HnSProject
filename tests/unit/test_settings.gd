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
func test_the_factor_follows_the_screen() -> void:
	assert_eq(Settings.fitting_scale_factor(Vector2i(1920, 1080), BASE), 3, "1080p")
	assert_eq(Settings.fitting_scale_factor(Vector2i(2560, 1440), BASE), 4, "1440p")
	assert_eq(Settings.fitting_scale_factor(Vector2i(3840, 2160), BASE), 6, "4K")
	assert_eq(Settings.fitting_scale_factor(Vector2i(1280, 720), BASE), 2, "720p")


## C'est la **plus petite** des deux dimensions qui décide. Un écran large et bas
## — une barre des tâches mange la hauteur, un ultra-large la donne en largeur —
## tiendrait sinon un facteur qui déborde par le bas, et la barre de vie du
## joueur passerait sous le bureau.
func test_the_tightest_dimension_decides() -> void:
	assert_eq(
		Settings.fitting_scale_factor(Vector2i(3440, 1000), BASE), 2,
		"ultra-large mais court : la hauteur commande"
	)
	assert_eq(
		Settings.fitting_scale_factor(Vector2i(1300, 2000), BASE), 2,
		"étroit et haut : la largeur commande"
	)


## Un écran plus petit que le cadrage du jeu doit quand même pouvoir le lancer.
## Zéro serait une fenêtre de taille nulle, donc rien à l'écran du tout.
func test_a_small_screen_returns_at_least_one() -> void:
	assert_eq(Settings.fitting_scale_factor(Vector2i(400, 300), BASE), 1)
	assert_eq(Settings.fitting_scale_factor(Vector2i(1, 1), BASE), 1)


## Une base absurde ne doit pas diviser par zéro. Elle ne peut venir que d'un
## réglage de projet effacé, mais planter au démarrage pour ça serait cher payé.
func test_a_zero_base_does_not_divide_by_zero() -> void:
	assert_eq(Settings.fitting_scale_factor(Vector2i(1920, 1080), Vector2i.ZERO), 1)


# --------------------------------------------------------------------------
# La ronde du bouton
# --------------------------------------------------------------------------

## On monte jusqu'au maximum de l'écran, puis on passe en plein écran, puis on
## revient au plus petit. Le plein écran est **après** les facteurs : on en sort
## en continuant d'appuyer, sans deviner qu'il faudrait revenir en arrière.
func test_the_cycle_goes_through_fullscreen_then_back() -> void:
	assert_eq(Settings.next_scale_factor(1, 3), 2)
	assert_eq(Settings.next_scale_factor(2, 3), 3)
	assert_eq(Settings.next_scale_factor(3, 3), Settings.FULLSCREEN, "au bout : plein écran")
	assert_eq(Settings.next_scale_factor(Settings.FULLSCREEN, 3), 1, "puis on repart à ×1")


## Un écran qui ne tient qu'un seul facteur ne doit pas piéger le joueur dans le
## plein écran ni dans la fenêtre : la ronde marche à deux valeurs.
func test_the_cycle_works_with_a_single_factor() -> void:
	assert_eq(Settings.next_scale_factor(1, 1), Settings.FULLSCREEN)
	assert_eq(Settings.next_scale_factor(Settings.FULLSCREEN, 1), 1)


## Un facteur enregistré sur un écran plus grand ne doit pas bloquer la ronde :
## elle repart vers le plein écran plutôt que de monter vers l'inatteignable.
func test_a_too_large_factor_comes_back_down() -> void:
	assert_eq(Settings.next_scale_factor(5, 3), Settings.FULLSCREEN)


# --------------------------------------------------------------------------
# Le libellé
# --------------------------------------------------------------------------

## Le bouton annonce la taille en pixels et pas seulement le facteur : « ×3 » ne
## dit rien tant qu'on ne connaît pas le cadrage de départ.
func test_the_label_states_the_obtained_size() -> void:
	assert_eq(Settings.label_of(2, BASE), "Fenêtre : ×2  (1280 × 720)")
	assert_eq(Settings.label_of(3, BASE), "Fenêtre : ×3  (1920 × 1080)")
	assert_eq(Settings.label_of(Settings.FULLSCREEN, BASE), "Fenêtre : plein écran")


## La taille de base vient des réglages du projet et n'est pas recopiée : c'est
## elle qui décide de tout le reste, et deux définitions de 640 × 360 finiraient
## par se contredire.
func test_the_base_size_comes_from_the_project() -> void:
	assert_eq(Settings.base_size(), BASE)


# --------------------------------------------------------------------------
# Le disque
# --------------------------------------------------------------------------

## Aller-retour complet. Un réglage qui se remet à zéro à chaque lancement n'est
## pas un réglage.
func test_settings_make_the_round_trip() -> void:
	var before := Settings.to_dict()

	Settings.show_health_bars = false
	Settings.show_affix_names = false
	Settings.damage_taken_visible = false
	Settings.damage_dealt_visible = false
	var written := Settings.to_dict()

	Settings.from_dict({
		"health_bars": true, "affix_names": true, "scale_factor": 1,
		"damage_taken": true, "damage_dealt": true,
	})
	assert_true(Settings.show_health_bars)
	assert_true(Settings.show_affix_names)
	assert_true(Settings.damage_taken_visible)
	assert_true(Settings.damage_dealt_visible)

	Settings.from_dict(written)
	assert_false(Settings.show_health_bars, "les valeurs relues sont celles écrites")
	assert_false(Settings.show_affix_names)
	assert_false(Settings.damage_taken_visible)
	assert_false(Settings.damage_dealt_visible)

	Settings.from_dict(before)


## Un champ absent garde sa valeur plutôt que de faire échouer la lecture
## entière : un fichier écrit par une version plus ancienne doit encore servir.
func test_a_missing_field_keeps_its_value() -> void:
	var before := Settings.to_dict()
	Settings.show_health_bars = true
	Settings.from_dict({"affix_names": false})
	assert_true(Settings.show_health_bars, "le champ absent n'a pas bougé")
	assert_false(Settings.show_affix_names, "le champ présent, si")
	Settings.from_dict(before)


## Une valeur d'échelle qui n'est pas un nombre est ignorée plutôt que convertie
## en zéro — ce qui mettrait le jeu en plein écran sur un fichier abîmé.
func test_an_unreadable_scale_does_not_go_fullscreen() -> void:
	var before := Settings.to_dict()
	Settings.from_dict({"scale_factor": 1})
	Settings.from_dict({"scale_factor": "big"})
	assert_ne(Settings.scale_factor, Settings.FULLSCREEN, "le texte n'est pas lu comme zéro")
	Settings.from_dict(before)


## Un curseur bougé atteint aussi ce qui brûle déjà — l'aura reste des minutes —, et
## chaque famille garde la sienne.
func test_an_opacity_reaches_the_living_visuals() -> void:
	var before := Settings.to_dict()
	var spell: Node2D = add_child_autofree(Node2D.new())
	var attack: Node2D = add_child_autofree(Node2D.new())
	Settings.spell_opacity = 0.5
	Settings.veil(spell, Settings.SPELLS)
	Settings.veil(attack, Settings.ENEMY_ATTACKS)
	assert_almost_eq(spell.modulate.a, 0.5, 0.001, "posée à la naissance")
	assert_almost_eq(attack.modulate.a, 1.0, 0.001, "l'autre famille n'a pas bougé")

	Settings.enemy_attack_opacity = 0.2
	Settings.spell_opacity = 7.0
	assert_almost_eq(attack.modulate.a, 0.2, 0.001, "reprise sur ce qui vit")
	assert_almost_eq(spell.modulate.a, 1.0, 0.001, "bornée à 1")

	Settings.from_dict({"spell_opacity": 0.3, "enemy_attack_opacity": "abîmé"})
	assert_almost_eq(Settings.spell_opacity, 0.3, 0.001, "relue")
	assert_almost_eq(Settings.enemy_attack_opacity, 0.2, 0.001, "un texte ne l'écrase pas")
	Settings.from_dict(before)


# --------------------------------------------------------------------------
# La langue
# --------------------------------------------------------------------------

## **La campagne tourne en français quelle que soit la machine** : c'est
## `--language fr` dans `tests/run.sh`. Sans lui, tous les tests qui affirment un
## texte français passeraient ici et échoueraient sur un Windows anglais.
func test_the_suite_runs_in_french() -> void:
	assert_eq(Settings.language, Settings.FRENCH)
	assert_true(
		TranslationServer.get_locale().begins_with(Settings.FRENCH),
		"la locale du moteur aussi, et non « %s »" % TranslationServer.get_locale()
	)


## Le premier lancement suit la langue du système, ramenée aux deux langues du
## jeu. Un Windows en allemand ne trouverait aucune traduction allemande, et le
## moteur afficherait ses clés : du français, mais par accident.
func test_an_unknown_locale_becomes_english() -> void:
	assert_eq(Settings.normalize("fr"), Settings.FRENCH)
	assert_eq(Settings.normalize("fr_CA"), Settings.FRENCH, "le Québec aussi")
	assert_eq(Settings.normalize("FR_fr"), Settings.FRENCH, "la casse ne décide pas")
	assert_eq(Settings.normalize("of"), Settings.ENGLISH)
	assert_eq(Settings.normalize("en_US"), Settings.ENGLISH)
	assert_eq(Settings.normalize(""), Settings.ENGLISH, "et l'absence de locale")


## L'anglais est bien chargé par le projet. Une déclaration oubliée dans
## `project.godot` ne se verrait qu'en passant le jeu en anglais : tout resterait
## en français, sans la moindre erreur.
func test_english_is_loaded() -> void:
	assert_has(TranslationServer.get_loaded_locales(), Settings.ENGLISH)


## Le repli est le **français**, et pas l'anglais d'usine. Les clés de traduction
## sont les textes français eux-mêmes : avec le repli d'usine, un texte affiché en
## français n'y trouverait aucune traduction française — il n'en existe pas —,
## retomberait sur l'anglais, et le jeu parlerait anglais en français.
func test_the_fallback_is_french() -> void:
	assert_eq(
		String(ProjectSettings.get_setting("internationalization/locale/fallback", "")),
		Settings.FRENCH
	)


## La langue fait l'aller-retour comme les autres réglages, et la poser change la
## locale du moteur : c'est lui qui traduit.
func test_the_language_makes_the_round_trip() -> void:
	var before := Settings.to_dict()
	assert_true(before.has("language"), "elle part sur le disque")

	Settings.from_dict({"language": Settings.ENGLISH})
	assert_eq(Settings.language, Settings.ENGLISH)
	assert_eq(TranslationServer.get_locale(), Settings.ENGLISH, "le moteur a suivi")

	# Remise en place avant de rendre la main : un test qui laisse le jeu en
	# anglais fait échouer les suivants loin de sa propre cause.
	Settings.from_dict(before)
	assert_eq(Settings.language, Settings.FRENCH)
	assert_eq(TranslationServer.get_locale(), Settings.FRENCH)


## Une langue inconnue lue dans le fichier est ramenée plutôt que posée telle
## quelle : le moteur chercherait des traductions qui n'existent pas.
func test_an_unknown_language_in_the_file_is_brought_back() -> void:
	var before := Settings.to_dict()
	Settings.from_dict({"language": "of"})
	assert_eq(Settings.language, Settings.ENGLISH)
	Settings.from_dict(before)
