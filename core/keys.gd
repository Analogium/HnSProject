class_name Keys

## La lecture d'un appui clavier, et rien d'autre.
##
## Sept scènes ouvrent leur `_unhandled_input` sur la même garde : un événement
## clavier, enfoncé, et qui n'est pas une répétition automatique. L'oubli du
## dernier test est celui qui ne se voit pas — la touche maintenue déclenche
## alors soixante fois par seconde une action prévue pour une.


## Le code de la touche qu'on vient d'enfoncer, ou KEY_NONE pour tout le reste :
## un relâchement, une répétition, une souris.
static func pressed_down(event: InputEvent) -> Key:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return KEY_NONE
	return key.keycode
