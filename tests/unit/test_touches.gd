extends GutTest

## La lecture d'un appui clavier.
##
## Sept scènes ouvraient leur `_unhandled_input` sur la même garde recopiée à la
## main, et **aucune n'était couverte** : la campagne ne pilote pas de clavier.
## La règle vit maintenant à un seul endroit, donc elle peut enfin être mise à
## l'épreuve — c'est la moitié de l'intérêt de l'avoir extraite.


func _touche(code: Key, pressed := true, echo := false) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = pressed
	e.echo = echo
	return e


func test_un_appui_rend_sa_touche() -> void:
	assert_eq(Touches.enfoncee(_touche(KEY_F4)), KEY_F4)
	assert_eq(Touches.enfoncee(_touche(KEY_ESCAPE)), KEY_ESCAPE)


## Le relâchement ne doit rien déclencher : sans ce test, ouvrir la forge par F4
## la refermerait aussitôt en lâchant la touche.
func test_un_relachement_ne_compte_pas() -> void:
	assert_eq(Touches.enfoncee(_touche(KEY_F4, false)), KEY_NONE)


## La répétition automatique non plus. C'est le test qu'on oublie en recopiant
## la garde à la main, et son absence ne se voit pas : la touche maintenue
## déclenche alors soixante fois par seconde une action prévue pour une — une
## seule pression régénérerait la zone des dizaines de fois.
func test_une_repetition_automatique_ne_compte_pas() -> void:
	assert_eq(Touches.enfoncee(_touche(KEY_F5, true, true)), KEY_NONE)


## Tout ce qui n'est pas un clavier passe son chemin plutôt que de planter : le
## même `_unhandled_input` reçoit aussi les souris et les manettes.
func test_ce_qui_n_est_pas_un_clavier_est_ignore() -> void:
	assert_eq(Touches.enfoncee(InputEventMouseButton.new()), KEY_NONE)
	assert_eq(Touches.enfoncee(InputEventJoypadButton.new()), KEY_NONE)
	assert_eq(Touches.enfoncee(null), KEY_NONE)


## KEY_NONE vaut zéro, et c'est ce qui rend le `if touche == KEY_NONE` des
## appelants correct : aucune vraie touche ne peut porter ce code.
func test_le_refus_ne_peut_pas_etre_confondu_avec_une_touche() -> void:
	assert_eq(KEY_NONE, 0, "le code de refus est bien le zéro attendu")
	assert_ne(Touches.enfoncee(_touche(KEY_A)), KEY_NONE)
