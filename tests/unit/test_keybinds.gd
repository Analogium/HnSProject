extends GutTest

## Les touches du joueur : ce qui s'écrit dans `settings.json`, ce qui arrive dans
## la table du moteur, et l'échange qui empêche deux actions de partager une touche.
##
## Aucun test ne pilote un vrai clavier : ce qu'on vérifie ici, c'est ce que le jeu
## lira quand la touche tombera.


## La table du moteur est globale : un test qui la laisse rebindée ferait échouer
## les suivants loin de sa cause.
func after_each() -> void:
	Keybinds.apply({})


## **Une case de barre, un déclencheur.** L'onglet des touches ne montre que le premier
## (`Keybinds.text_of`), et l'échange de `rebound()` ne compare que celui-là : un second
## reste invisible *et* inéchangeable. C'est ainsi qu'Espace lançait la première
## compétence sans que rien ne le dise, un reste d'avant la barre.
##
## Les déplacements font exception et gardent leurs flèches : un doublon de WASD qui
## fait la même chose, là où Espace lançait un sort à l'insu du joueur.
func test_a_skill_slot_has_a_single_trigger() -> void:
	Keybinds.apply({})
	for i in SkillBar.SLOT_COUNT:
		var action := "skill_%d" % (i + 1)
		var triggers := PackedStringArray()
		for event in InputMap.action_get_events(action):
			var written := Keybinds.to_text(event)
			if not written.is_empty():
				triggers.append(written)
		assert_eq(triggers.size(), 1, "« %s » en a %s" % [action, triggers])


func test_a_key_reads_and_writes_as_text() -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_J
	assert_eq(Keybinds.to_text(key), "key:%d" % KEY_J)
	assert_eq((Keybinds.from_text("key:%d" % KEY_J) as InputEventKey).keycode, KEY_J)

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	assert_eq(Keybinds.to_text(click), "mouse:%d" % MOUSE_BUTTON_RIGHT)
	assert_eq(
		(Keybinds.from_text("mouse:%d" % MOUSE_BUTTON_RIGHT) as InputEventMouseButton).button_index,
		MOUSE_BUTTON_RIGHT
	)


## Les boutons latéraux se bindent ; la molette, non.
func test_the_side_buttons_bind_but_not_the_wheel() -> void:
	for button in [MOUSE_BUTTON_XBUTTON1, MOUSE_BUTTON_XBUTTON2]:
		var click := InputEventMouseButton.new()
		click.button_index = button
		assert_eq(Keybinds.to_text(click), "mouse:%d" % button)
		assert_eq((Keybinds.from_text("mouse:%d" % button) as InputEventMouseButton).button_index, button)
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	assert_eq(Keybinds.to_text(wheel), "")


## Une position, faute de code de disposition : c'est ainsi que `project.godot` lie
## les déplacements, et c'est la position qui doit partir dans les réglages.
func test_a_position_is_written_when_there_is_no_layout_code() -> void:
	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	assert_eq(Keybinds.to_text(key), "pos:%d" % KEY_W, "une position, pas une lettre")
	var back := Keybinds.from_text("pos:%d" % KEY_W) as InputEventKey
	assert_eq(back.physical_keycode, KEY_W)
	assert_eq(back.keycode, KEY_NONE, "et elle le reste : ZQSD doit tomber où tombe WASD")


## Un fichier retouché à la main ne doit priver personne de sa touche : ce qui ne se
## lit pas est écarté, et l'action retombe sur son défaut.
func test_a_damaged_file_falls_back_on_the_defaults() -> void:
	assert_null(Keybinds.from_text(""))
	assert_null(Keybinds.from_text("key"))
	assert_null(Keybinds.from_text("key:abc"))
	assert_null(Keybinds.from_text("pos:x"))
	assert_null(Keybinds.from_text("joypad:3"), "seuls le clavier et la souris se bindent")

	var kept := Settings.valid_binds({
		"panel_inventory": "key:%d" % KEY_J,
		"action_from_2027": "key:%d" % KEY_K,
		"panel_manuals": "n'importe quoi",
	})
	assert_eq(kept, {"panel_inventory": "key:%d" % KEY_J}, "l'action inconnue et la touche illisible partent")
	assert_eq(Settings.valid_binds("pas un dictionnaire"), {})


func test_without_a_choice_the_project_defaults_stand() -> void:
	Keybinds.apply({})
	assert_eq(Keybinds.key_label("panel_inventory"), "I")
	assert_false(
		InputMap.action_get_events("move_up").is_empty(), "et un déplacement garde les siens"
	)


func test_a_chosen_key_replaces_the_default() -> void:
	Keybinds.apply({"panel_inventory": "key:%d" % KEY_J})
	var events := InputMap.action_get_events("panel_inventory")
	assert_eq(events.size(), 1, "une action rebindée n'a plus qu'une touche")
	assert_eq((events[0] as InputEventKey).keycode, KEY_J)
	assert_eq(Keybinds.key_label("panel_inventory"), "J")

	Keybinds.apply({})
	assert_eq(Keybinds.key_label("panel_inventory"), "I", "et le défaut revient")


## **Un échange, pas un écrasement** : prendre la touche d'une autre action lui
## laisse celle qu'on quitte. Sans ça, une action se retrouverait muette sans que
## rien ne le dise, et deux actions répondraient à la même touche.
func test_taking_a_used_key_swaps_the_two() -> void:
	Keybinds.apply({})
	var wanted := InputEventKey.new()
	wanted.keycode = KEY_C

	var binds := Keybinds.rebound({}, "panel_inventory", wanted)
	Keybinds.apply(binds)
	assert_eq(Keybinds.key_label("panel_inventory"), "C")
	assert_eq(Keybinds.key_label("panel_character"), "I", "la fiche a récupéré la touche libérée")


## Rebinder une action sur sa propre touche ne la casse pas.
func test_binding_a_key_an_action_already_has_changes_nothing() -> void:
	Keybinds.apply({})
	var same := InputEventKey.new()
	same.keycode = KEY_I
	Keybinds.apply(Keybinds.rebound({}, "panel_inventory", same))
	assert_eq(Keybinds.key_label("panel_inventory"), "I")


## Chaque action de la table existe dans `project.godot`, et chaque libellé y est :
## une action ajoutée d'un côté seulement ne se binderait jamais.
func test_each_action_exists_and_is_named() -> void:
	for action: String in Keybinds.ACTIONS:
		assert_true(InputMap.has_action(action), "« %s » manque à project.godot" % action)
		assert_false(String(Keybinds.ACTIONS[action]).is_empty(), "« %s » sans libellé" % action)
		assert_ne(Keybinds.key_label(action), Keybinds.UNBOUND, "« %s » sans touche" % action)


## Deux actions ne partagent pas une touche au départ : le défaut doit valoir ce que
## l'échange garantit ensuite.
func test_no_two_default_keys_collide() -> void:
	Keybinds.apply({})
	var seen := {}
	for action: String in Keybinds.ACTIONS:
		var written := Keybinds.text_of(action)
		assert_false(seen.has(written), "« %s » et « %s » partagent %s" % [
			action, seen.get(written, ""), written
		])
		seen[written] = action
