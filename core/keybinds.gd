class_name Keybinds

## Les touches du joueur : ce qu'il peut changer, et comment ça se lit.
##
## Les défauts vivent dans `project.godot`, la table du moteur ; le choix du joueur
## dans `Settings.key_binds` ; et les deux se rencontrent **ici seulement**. Les
## touches de réglage — F2 à F6, G, K, PAGE — n'en sont pas : elles ouvrent des
## outils et non le jeu, et `zone.gd` les lit toujours par leur code.

## Les actions rebindables, dans l'ordre de l'onglet, chacune avec son libellé.
## **Identifiants définitifs** (invariant 1) : ils partent dans `settings.json`.
## Échap n'y est pas — c'est la sortie de secours, et la perdre enfermerait le joueur.
const ACTIONS := {
	"move_up": "Avancer",
	"move_down": "Reculer",
	"move_left": "Aller à gauche",
	"move_right": "Aller à droite",
	"skill_1": "Compétence 1",
	"skill_2": "Compétence 2",
	"skill_3": "Compétence 3",
	"skill_4": "Compétence 4",
	"skill_5": "Compétence 5",
	"panel_inventory": "Inventaire",
	"panel_character": "Fiche de personnage",
	"panel_manuals": "Manuels",
	"panel_passives": "Arbre de passifs",
	"zone_map": "Carte de la zone",
	"ground_labels": "Noms des objets au sol",
	"item_details": "Détails d'un objet (maintenu)",
}

## Ce que le joueur lit sur un bouton de souris ; les autres ne se bindent pas. La
## molette en est exclue : un cran n'a ni enfoncé ni relâché, et une touche tenue
## relance à chaque recharge.
const MOUSE_LABELS := {
	MOUSE_BUTTON_LEFT: "clic G",
	MOUSE_BUTTON_RIGHT: "clic D",
	MOUSE_BUTTON_MIDDLE: "clic M",
	MOUSE_BUTTON_XBUTTON1: "clic 4",
	MOUSE_BUTTON_XBUTTON2: "clic 5",
}

## Faute de touche : une action peut rester sans rien le temps d'un échange.
const UNBOUND := "—"

## Les événements de `project.godot`, relevés avant le premier changement : une
## action réécrite a perdu les siens, et « rétablir » n'aurait plus rien à rendre.
static var _defaults := {}


## Réécrit la table du moteur : le choix du joueur là où il en a un, le défaut
## partout ailleurs. **Remplace tous les événements** d'une action rebindée — la
## flèche et la manette d'un déplacement partent avec. Une action, une touche :
## c'est ce que l'onglet montre, et montrer autre chose mentirait.
static func apply(binds: Dictionary) -> void:
	_capture_defaults()
	for action in ACTIONS:
		if not InputMap.has_action(action):
			continue
		var chosen := from_text(String(binds.get(action, "")))
		InputMap.action_erase_events(action)
		if chosen != null:
			InputMap.action_add_event(action, chosen)
			continue
		for event in _defaults[action]:
			InputMap.action_add_event(action, event)


## Le tableau des choix après avoir posé `event` sur `action`. **Un échange et non
## un écrasement** : la touche prise ailleurs y laisse celle qu'elle remplace, donc
## aucune action ne se retrouve muette et deux n'ont jamais la même.
static func rebound(binds: Dictionary, action: String, event: InputEvent) -> Dictionary:
	var wanted := to_text(event)
	if wanted.is_empty() or not ACTIONS.has(action):
		return binds
	var out := binds.duplicate()
	var freed := text_of(action)
	for other in ACTIONS:
		if other != action and text_of(other) == wanted:
			out[other] = freed
	out[action] = wanted
	return out


## La touche d'une action telle qu'elle est en place, en texte. Lue dans la table du
## moteur et non dans les choix : le défaut n'y est pas écrit.
static func text_of(action: String) -> String:
	for event in InputMap.action_get_events(action):
		var written := to_text(event)
		if not written.is_empty():
			return written
	return ""


## « key:76 », « pos:87 », « mouse:1 » : lisible dans `settings.json`, et stable là
## où un événement sérialisé par le moteur ne l'est pas d'une version à l'autre.
##
## **Deux formes pour le clavier, et il en faut deux.** Le joueur bind la lettre
## qu'il voit (`key`) ; `project.godot` lie les *positions* pour les déplacements
## (`pos`), pour que ZQSD tombe où tombe WASD. Tout ramener à `key` déplacerait la
## touche d'un AZERTY dès qu'un échange fait repasser un défaut par ici.
static func to_text(event: InputEvent) -> String:
	var key := event as InputEventKey
	if key != null:
		if key.keycode != 0:
			return "key:%d" % key.keycode
		return "pos:%d" % key.physical_keycode if key.physical_keycode != 0 else ""
	var click := event as InputEventMouseButton
	if click != null and MOUSE_LABELS.has(click.button_index):
		return "mouse:%d" % click.button_index
	return ""


## Null pour un texte vide ou abîmé : un `settings.json` retouché à la main ne doit
## pas priver le joueur de sa touche, il retombe sur le défaut.
static func from_text(text_value: String) -> InputEvent:
	var parts := text_value.split(":")
	if parts.size() != 2 or not parts[1].is_valid_int():
		return null
	var code := int(parts[1])
	if parts[0] == "key" or parts[0] == "pos":
		var key := InputEventKey.new()
		if parts[0] == "key":
			key.keycode = code
		else:
			key.physical_keycode = code
		return key
	if parts[0] == "mouse" and MOUSE_LABELS.has(code):
		var click := InputEventMouseButton.new()
		click.button_index = code
		return click
	return null


## Ce qu'un événement s'appelle sous les yeux du joueur.
static func event_label(event: InputEvent) -> String:
	var key := event as InputEventKey
	if key != null:
		return _keycode_label(key.keycode if key.keycode != 0 else key.physical_keycode, key.keycode == 0)
	var click := event as InputEventMouseButton
	if click != null and MOUSE_LABELS.has(click.button_index):
		return Texts.t(MOUSE_LABELS[click.button_index])
	return UNBOUND


## La touche d'une action, écrite dans la disposition du joueur : le jeu lie des
## positions (ZQSD comme WASD), et l'écran doit dire la lettre qu'il lit.
static func key_label(action: String) -> String:
	for event in InputMap.action_get_events(action):
		var written := event_label(event)
		if written != UNBOUND:
			return written
	return UNBOUND


## Cette action part-elle au clic gauche ? La question du butin au sol, qui se
## réserve ce bouton-là et **seulement celui-là**.
static func uses_left_click(action: String) -> bool:
	for event in InputMap.action_get_events(action):
		var click := event as InputEventMouseButton
		if click != null and click.button_index == MOUSE_BUTTON_LEFT:
			return true
	return false


## Le libellé d'une action dans la langue du joueur.
static func label_of(action: String) -> String:
	return Texts.t(String(ACTIONS.get(action, "")))


## `physical` : le code est une position, à traduire dans la disposition en place.
## Le serveur muet des tests n'en a pas ; on garde alors le nom de la position
## plutôt que de pousser une erreur moteur.
static func _keycode_label(code: int, physical: bool) -> String:
	if code == 0:
		return UNBOUND
	if physical and DisplayServer.get_name() != "headless":
		var translated := DisplayServer.keyboard_get_keycode_from_physical(code)
		if translated != 0:
			code = translated
	return OS.get_keycode_string(code)


static func _capture_defaults() -> void:
	if not _defaults.is_empty():
		return
	for action in ACTIONS:
		_defaults[action] = InputMap.action_get_events(action) if InputMap.has_action(action) else []
