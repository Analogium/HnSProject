extends GutTest

## La lecture d'un appui clavier.
##
## Sept scènes ouvraient leur `_unhandled_input` sur la même garde recopiée à la
## main, et **aucune n'était couverte** : la campagne ne pilote pas de clavier.
## La règle vit maintenant à un seul endroit, donc elle peut enfin être mise à
## l'épreuve — c'est la moitié de l'intérêt de l'avoir extraite.


func _key_event(code: Key, pressed := true, echo := false) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = pressed
	e.echo = echo
	return e


func test_a_press_returns_its_key() -> void:
	assert_eq(Keys.pressed_down(_key_event(KEY_F4)), KEY_F4)
	assert_eq(Keys.pressed_down(_key_event(KEY_ESCAPE)), KEY_ESCAPE)


## Le relâchement ne doit rien déclencher : sans ce test, ouvrir la forge par F4
## la refermerait aussitôt en lâchant la touche.
func test_a_release_does_not_count() -> void:
	assert_eq(Keys.pressed_down(_key_event(KEY_F4, false)), KEY_NONE)


## La répétition automatique non plus. C'est le test qu'on oublie en recopiant
## la garde à la main, et son absence ne se voit pas : la touche maintenue
## déclenche alors soixante fois par seconde une action prévue pour une — une
## seule pression régénérerait la zone des dizaines de fois.
func test_an_automatic_repeat_does_not_count() -> void:
	assert_eq(Keys.pressed_down(_key_event(KEY_F5, true, true)), KEY_NONE)


## Tout ce qui n'est pas un clavier passe son chemin plutôt que de planter : le
## même `_unhandled_input` reçoit aussi les souris et les manettes.
func test_what_is_not_a_keyboard_is_ignored() -> void:
	assert_eq(Keys.pressed_down(InputEventMouseButton.new()), KEY_NONE)
	assert_eq(Keys.pressed_down(InputEventJoypadButton.new()), KEY_NONE)
	assert_eq(Keys.pressed_down(null), KEY_NONE)


## KEY_NONE vaut zéro, et c'est ce qui rend le `if key == KEY_NONE` des
## appelants correct : aucune vraie touche ne peut porter ce code.
func test_the_refusal_cannot_be_mistaken_for_a_key() -> void:
	assert_eq(KEY_NONE, 0, "le code de refus est bien le zéro attendu")
	assert_ne(Keys.pressed_down(_key_event(KEY_A)), KEY_NONE)
