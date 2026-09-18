extends Node

## Les réglages du joueur — `Game` porte la partie —, écrits sur le disque. Par
## signal : trois cents barres de vie n'ont pas à relire le réglage à chaque image.

signal changed

## Distinct des personnages : ces réglages valent pour la machine.
const FILE := "user://settings.json"

## Ce que « plein écran » vaut dans `scale_factor`.
const FULLSCREEN := 0

## Le français est la langue source : ses textes sont les clés, l'anglais vit dans
## `i18n/en.po`.
const FRENCH := "fr"
const ENGLISH := "en"

## Barres de vie au-dessus des acteurs, ennemis comme alliés.
var show_health_bars := true:
	set(value):
		if value == show_health_bars:
			return
		show_health_bars = value
		_announce()

## Noms des affixes empilés au-dessus des ennemis qui en portent.
var show_affix_names := true:
	set(value):
		if value == show_affix_names:
			return
		show_affix_names = value
		_announce()

## Deux cases : ce que subit le joueur, brûlures comprises, et ce que subissent
## les ennemis.
var damage_taken_visible := true:
	set(value):
		if value == damage_taken_visible:
			return
		damage_taken_visible = value
		_announce()

var damage_dealt_visible := true:
	set(value):
		if value == damage_dealt_visible:
			return
		damage_dealt_visible = value
		_announce()


## Les touches choisies par le joueur, action → « key:76 ». **Seules celles qu'il a
## changées** y sont ; le reste vient de `project.godot`, par `Keybinds`. Posées, elles
## réécrivent la table du moteur — c'est le seul endroit qui la touche.
var key_binds := {}:
	set(value):
		key_binds = value
		Keybinds.apply(key_binds)
		if _loading:
			return
		_announce()


## Un réglage vient de changer : ceux qui le lisent, puis le disque. Six setters
## écrivaient les deux lignes à la main — sans `changed`, trois cents barres de vie
## gardent l'ancien réglage ; sans `_write()`, le choix meurt avec la session.
func _announce() -> void:
	changed.emit()
	_write()


## Le seul chemin d'un changement de touche : l'échange décidé par `Keybinds`, puis
## la table du moteur et le disque, par le setter.
func bind(action: String, event: InputEvent) -> void:
	key_binds = Keybinds.rebound(key_binds, action, event)


## Rend toutes les touches à `project.godot`.
func reset_key_binds() -> void:
	key_binds = {}


## Le choix entre les deux cases, ici et nulle part ailleurs.
func shows_damage(on_the_player: bool) -> bool:
	return damage_taken_visible if on_the_player else damage_dealt_visible

## « fr » ou « en », toujours normalisée. La poser change la locale du moteur, qui
## retraduit les scènes et notifie les panneaux dessinés.
var language := FRENCH:
	set(value):
		var chosen := normalize(value)
		if chosen == language:
			return
		language = chosen
		TranslationServer.set_locale(language)
		_announce()

## Le facteur de la fenêtre, ou PLEIN_ECRAN. Le jeu remplit toujours la fenêtre
## (échelle fractionnaire) : ces facteurs sont des raccourcis vers les tailles
## nettes. Pas de signal `changed` : rien n'a à y réagir.
var scale_factor := 2:
	set(value):
		var clamped := clampi(value, FULLSCREEN, max_scale_factor())
		if clamped == scale_factor:
			return
		scale_factor = clamped
		# Pendant une lecture, on note la valeur sans toucher à la fenêtre :
		# c'est `_ready` qui décide s'il faut l'appliquer.
		if _loading:
			return
		_apply()
		_write()

## Pendant la lecture : sans lui, chaque champ relu réécrirait le fichier.
var _loading := false


## **On n'impose la taille que si le joueur l'a choisie** : sans fichier, on lit le
## facteur de la fenêtre en place (le cadre de l'éditeur a son propre sélecteur).
## La langue suit la même règle, posée sans écrire : un premier lancement ne doit
## pas créer un fichier qui ferait passer les défauts pour un choix.
func _ready() -> void:
	var chosen := FileAccess.file_exists(FILE)

	_loading = true
	language = normalize(TranslationServer.get_locale())
	_loading = false
	_load()

	# Toujours : le moteur doit tourner sur « fr » ou « en », jamais sur « fr_CA ».
	TranslationServer.set_locale(language)

	if chosen:
		_apply()
		return

	_loading = true
	scale_factor = observed_scale_factor()
	_loading = false


# --------------------------------------------------------------------------
# La langue
# --------------------------------------------------------------------------

## Ce qui commence par « fr » donne le français, le reste l'anglais : un système
## allemand afficherait sinon les clés. Statique, pour que le test ne dépende pas
## de la machine.
static func normalize(locale: String) -> String:
	return FRENCH if locale.to_lower().begins_with(FRENCH) else ENGLISH


## La langue en cours écrite dans cette langue, jamais traduite : un joueur perdu
## doit reconnaître la sienne.
const LANGUAGE_LABELS := {
	FRENCH: "Langue : Français",
	ENGLISH: "Language: English",
}


static func language_label(value: String) -> String:
	return LANGUAGE_LABELS.get(normalize(value), "")


func current_language_label() -> String:
	return language_label(language)


## Écrite comme une ronde : une troisième langue ne touchera pas aux boutons.
static func next_language(current_one: String) -> String:
	return ENGLISH if normalize(current_one) == FRENCH else FRENCH


## Appelée par les options et par l'écran des personnages.
func cycle_language() -> void:
	language = next_language(language)


# --------------------------------------------------------------------------
# La taille de la fenêtre
# --------------------------------------------------------------------------

## Lue dans les réglages du projet, jamais recopiée.
static func base_size() -> Vector2i:
	return Vector2i(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", 640)),
		int(ProjectSettings.get_setting("display/window/size/viewport_height", 360))
	)


## Au moins 1, même sur un écran plus petit que le cadrage. Statique, pour le test.
static func fitting_scale_factor(screen: Vector2i, base: Vector2i) -> int:
	if base.x <= 0 or base.y <= 0:
		return 1
	return maxi(mini(screen.x / base.x, screen.y / base.y), 1)


## Arrondi vers le bas, par la même formule que l'écran.
static func observed_scale_factor() -> int:
	if DisplayServer.get_name() == "headless":
		return 1
	return fitting_scale_factor(DisplayServer.window_get_size(), base_size())


## Le plus grand facteur que cet écran-ci accepte.
static func max_scale_factor() -> int:
	var useful := DisplayServer.screen_get_usable_rect(
		DisplayServer.window_get_current_screen()
	).size
	return fitting_scale_factor(useful, base_size())


## 1, 2, … maximum, plein écran, puis 1 : on sort du plein écran en continuant.
static func next_scale_factor(current_one: int, maximum: int) -> int:
	if current_one == FULLSCREEN:
		return 1
	if current_one >= maximum:
		return FULLSCREEN
	return current_one + 1


## Le texte du bouton des options.
static func label_of(value: int, base: Vector2i) -> String:
	if value == FULLSCREEN:
		return Texts.t("Fenêtre : plein écran")
	return Texts.t("Fenêtre : ×{facteur}  ({largeur} × {hauteur})").format({
		"facteur": value, "largeur": base.x * value, "hauteur": base.y * value
	})


func current_label() -> String:
	return label_of(scale_factor, base_size())


## Passe au réglage suivant. Appelée par le menu des options.
func cycle_scale() -> void:
	scale_factor = next_scale_factor(scale_factor, max_scale_factor())


## Recentrée : agrandie depuis son coin, elle sortirait par le bas.
func _apply() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if scale_factor == FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var base := base_size()
	DisplayServer.window_set_size(base * scale_factor)
	var useful := DisplayServer.screen_get_usable_rect(
		DisplayServer.window_get_current_screen()
	)
	DisplayServer.window_set_position(
		useful.position + (useful.size - base * scale_factor) / 2
	)


# --------------------------------------------------------------------------
# Le disque
# --------------------------------------------------------------------------

## Un dictionnaire nommé : un réglage ajouté ne décale pas les autres.
func to_dict() -> Dictionary:
	return {
		"health_bars": show_health_bars,
		"affix_names": show_affix_names,
		"damage_taken": damage_taken_visible,
		"damage_dealt": damage_dealt_visible,
		"language": language,
		"scale_factor": scale_factor,
		"key_binds": key_binds,
	}


## Un champ absent garde son défaut : un fichier plus ancien sert encore.
func from_dict(source: Dictionary) -> void:
	_loading = true
	show_health_bars = bool(source.get("health_bars", show_health_bars))
	show_affix_names = bool(source.get("affix_names", show_affix_names))
	damage_taken_visible = bool(source.get("damage_taken", damage_taken_visible))
	damage_dealt_visible = bool(source.get("damage_dealt", damage_dealt_visible))
	# Normalisée par le setter : un fichier écrit à la main peut dire « de ».
	language = String(source.get("language", language))
	key_binds = valid_binds(source.get("key_binds", {}))
	var read_value: Variant = source.get("scale_factor", scale_factor)
	if read_value is float or read_value is int:
		# Bornée à la lecture : un fichier écrit sur un écran plus grand
		# demanderait un facteur que celui-ci ne peut pas afficher.
		scale_factor = clampi(int(read_value), FULLSCREEN, max_scale_factor())
	_loading = false


## Ce qu'un fichier peut contenir de valide : une action connue, une touche lisible.
## Le reste retombe sur le défaut — un `settings.json` retouché à la main ne doit pas
## priver le joueur d'une touche.
static func valid_binds(source: Variant) -> Dictionary:
	var out := {}
	if not source is Dictionary:
		return out
	for action: Variant in source:
		var written := String(source[action])
		if Keybinds.ACTIONS.has(action) and Keybinds.from_text(written) != null:
			out[String(action)] = written
	return out


func _load() -> void:
	var file := FileAccess.open(FILE, FileAccess.READ)
	var legacy := file == null
	if legacy:
		file = FileAccess.open(LegacyFrench.SETTINGS_FILE, FileAccess.READ)
	if file == null:
		return
	var text_value := file.get_as_text()
	file.close()

	# Une instance de JSON et non la fonction statique : celle-ci journalise une
	# erreur du moteur sur un fichier abîmé, alors que le cas est attendu ici.
	var reader := JSON.new()
	if reader.parse(text_value) != OK or not reader.data is Dictionary:
		push_warning("Réglages illisibles : les valeurs par défaut s'appliquent.")
		return
	from_dict(LegacyFrench.settings(reader.data) if legacy else reader.data)


## Sans écriture atomique, contrairement aux personnages : perdre les réglages coûte
## trois clics.
func _write() -> void:
	if _loading:
		return
	var file := FileAccess.open(FILE, FileAccess.WRITE)
	if file == null:
		push_warning("Réglages non enregistrés : écriture impossible.")
		return
	file.store_string(JSON.stringify(to_dict(), "\t"))
	file.close()
