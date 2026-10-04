class_name GuidePage
extends VBoxContainer

## Le guide du menu de pause, à la manière du journal de Hero Siege : les chapitres et
## leurs articles à gauche, l'article choisi à droite. **Les nombres sont lus dans les
## règles** à chaque ouverture — un texte recopié mentirait au premier rééquilibrage —,
## comme les touches, qui ont pu changer entre deux ouvertures.

signal closed

const INDEX_W := 116.0
const TEXT_W := 262.0
const BODY_H := 232.0
const FONT_SIZE := 9

## Les articles écrits ici, titre et texte. Des gabarits aux valeurs **nommées**, comme
## `StatHelp` : un nombre dans la clé ferait tomber l'anglais.
const ARTICLES := {
	"states": ["Les états", "Chaque nature de dégâts pose son état : le feu embrase, la foudre engourdit, le froid transit, la nécrose fait pourrir, le sacré bénit, le physique fait saigner. Un coup a {chance} de chance de poser l'état de chaque nature qu'il porte, quelle que soit sa part, plus la part des points de vie maximum que cette nature retire. La force de l'état suit la part du coup.\n\nTous les états se portent à la fois. Deux du même ne se cumulent pas : un nouveau, au moins aussi fort, remet sa durée à zéro ; un plus faible ne change rien. Ce qui brûle ne s'esquive pas, et les ennemis en posent aussi."],
	"rack": ["Le râtelier", "Un manuel ne fait rien dans le sac : il s'étudie au râtelier, qui a {places} emplacements — clic droit sur le manuel. Seuls les manuels du râtelier apprennent, et seuls leurs passifs comptent. Un même manuel ne s'étudie pas deux fois.\n\nLa touche {manuels} ouvre les manuels."],
	"class_manual": ["Le manuel de classe", "Un emplacement de plus porte le manuel de la classe. Il ne tombe jamais et ne se retire pas, mais apprend, se lit et s'investit comme les autres."],
	"manual_levels": ["Expérience et niveaux", "Chaque ennemi tué donne à chaque manuel du râtelier autant d'expérience qu'au personnage. Un manuel monte jusqu'au niveau {max}, et chaque niveau lui donne un point."],
	"cells": ["Les cases", "Une case porte une compétence ou un passif. Elle s'ouvre au niveau de manuel qu'elle demande ; un clic sur un passif y place un point, un clic sur une compétence ouvre son arbre. Un point se reprend d'un clic droit, tant que rien de ce qu'il ouvre n'en dépend."],
	"talent_trees": ["Les arbres de talents", "Chaque compétence a son arbre, et ses propres points : un par niveau du manuel, en plus de ceux du livre. Le centre de l'arbre est la compétence, payée par le livre.\n\nUn nœud s'ouvre quand la compétence a un point et qu'un des nœuds qui y mènent en porte assez — les grains sur le lien. Certains nœuds transforment la compétence, d'autres en convertissent les dégâts : ceux-là sont tout ou rien.\n\nTenir {details} sur une compétence montre ce qu'elle peut déclencher, avec les vraies chances."],
	"resistances": ["Résistances", "Chaque nature autre que le physique se réduit par sa résistance, en pourcentage direct, jusqu'à {plafond}. Une malédiction en retire avant le plafond : une résistance au-delà en protège."],
	"flasks": ["Les flacons", "Sous la ceinture, bus par les touches {touches}. Une gorgée coûte des charges ; chaque ennemi tué en rend à tous les flacons portés, une élite davantage. La ville les remplit.\n\nLes gorgées de vie et de mana rendent sur la durée et se cumulent. Un flacon utilitaire ne se reboit pas tant que son effet dure. Mourir vide les gorgées en cours."],
	"currency": ["Les pièces", "Une pièce s'applique à un objet du sac : clic droit sur la pièce, puis clic sur l'objet. Un objet qui ne porte pas d'affixes, comme un manuel, n'en accepte aucune."],
	"portal": ["Le portail", "La touche {portail} ouvre un portail vers la ville. La zone attend, figée : le portail bleu de la ville y ramène, avec les mêmes ennemis et le même butin.\n\nLe portail doré de la ville et les waypoints mènent ailleurs, et la zone qui attendait est perdue. Rien d'une zone ne survit à la fermeture du jeu."],
	"waypoints": ["Les waypoints", "Un par zone, au milieu de la route, et un en ville. Marcher dessus l'allume pour le personnage, pour de bon. Cliquer un waypoint allumé ouvre la liste des autres."],
}

## Un par `StatusEffects.Kind`, dans son ordre. Le titre est le nom de l'état.
const STATE_TEXTS := [
	"Posé par le feu. Brûle {part} par seconde du feu reçu, pendant {duree} s : {total} du coup en tout.",
	"Posé par la foudre. L'engourdi reçoit {force} de dégâts en plus, pendant {duree} s.",
	"Posé par le froid. Le transi perd {force} de vitesse — déplacement, attaque et incantation —, pendant {duree} s. Certains nœuds du Maître du froid le rendent plus fort.",
	"Posé par la nécrose. Brûle {part} par seconde du nécrotique reçu, pendant {duree} s, et rend à son auteur {soin} de ce qu'il brûle.",
	"Posé par le sacré. Le béni inflige {force} de dégâts en moins, pendant {duree} s.",
	"Posé par le physique. Brûle {part} par seconde du physique reçu, pendant {duree} s. Certains nœuds du Maître chevalier le font saigner plus vite.",
	"Posé par certaines compétences, jamais par un coup ordinaire. Brûle {part} par seconde du nécrotique reçu, pendant {duree} s, en {ticks} à-coups par seconde : chacun peut faire pourrir. Certains nœuds du Maître de la nécromancie la font ronger plus vite.",
	"Posé par certaines compétences, jamais par un coup ordinaire. Brûle {part} par seconde du nécrotique reçu, pendant {duree} s, en {ticks} à-coups par seconde : chacun peut faire pourrir. Certains nœuds du Maître de la nécromancie font qu'en plus, le flétri inflige moins de dégâts.",
	"Posé par certaines compétences, jamais par un coup ordinaire. Le maudit perd {force} points de résistance nécrotique, avant le plafond, pendant {duree} s. Certains nœuds du Maître de la nécromancie la rendent plus forte ou plus longue.",
]

var _index: VBoxContainer
var _index_scroll: ScrollContainer
var _title: Label
var _text: Label
var _scroll: ScrollContainer
var _picked := 0


func _ready() -> void:
	add_theme_constant_override("separation", 5)
	var heading := _label(Texts.t("GUIDE"), 12, UiPalette.TITLE)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(heading)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	add_child(body)

	_index_scroll = ScrollContainer.new()
	_index_scroll.custom_minimum_size = Vector2(INDEX_W, BODY_H)
	_index_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(_index_scroll)
	_index = VBoxContainer.new()
	_index.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_index.add_theme_constant_override("separation", 0)
	_index_scroll.add_child(_index)

	var page := VBoxContainer.new()
	body.add_child(page)
	_title = _label("", 11, UiPalette.TITLE)
	page.add_child(_title)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(TEXT_W, BODY_H - 18.0)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(_scroll)
	_text = _label("", FONT_SIZE, UiPalette.TEXT)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size.x = TEXT_W - 10.0
	_scroll.add_child(_text)

	var back := Button.new()
	back.text = "Retour"
	back.add_theme_font_size_override("font_size", 10)
	back.pressed.connect(closed.emit)
	add_child(back)


## Refait l'index à chaque ouverture : la langue et les touches ont pu changer.
func open() -> void:
	for child in _index.get_children():
		_index.remove_child(child)
		child.queue_free()
	var group := ButtonGroup.new()
	var at := 0
	for chapter in chapters():
		_index.add_child(_label(chapter["title"], FONT_SIZE, UiPalette.HINT))
		for article: Array in chapter["articles"]:
			var button := Button.new()
			button.text = "  " + article[0]
			button.flat = true
			button.toggle_mode = true
			button.button_group = group
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.add_theme_font_size_override("font_size", FONT_SIZE)
			button.pressed.connect(_show.bind(at, article))
			_index.add_child(button)
			if at == _picked:
				button.button_pressed = true
				_show(at, article)
				# Différé : le bouton n'a pas encore de place dans la liste.
				_index_scroll.ensure_control_visible.call_deferred(button)
			at += 1


func _show(at: int, article: Array) -> void:
	_picked = at
	_title.text = article[0]
	_text.text = article[1]
	_scroll.scroll_vertical = 0


## Tout le guide, traduit et chiffré : `[{title, articles: [[titre, texte], …]}, …]`.
## Publique pour les tests, qui vérifient qu'aucune valeur n'est restée en place.
static func chapters() -> Array:
	var states: Array = [_article("states", {"chance": StatMod.percentage(StatusEffects.CHANCE * 100.0)})]
	for kind in StatusEffects.Kind.values():
		states.append([RichText.capitalized(StatusEffects.name(kind)), _state_text(kind)])

	var coins: Array = [_article("currency")]
	for id in Currency.DROP_WEIGHTS:
		var coin := ItemCatalog.by_id(id)
		coins.append([Item.new(coin).display_name(), Currency.effect(coin)])

	# Les emplacements portent le nom de leur touche.
	var flask_keys := PackedStringArray()
	for slot in EquipmentSlots.flasks():
		flask_keys.append(Keybinds.key_label(slot))

	return [
		_chapter(Texts.t("États"), states),
		_chapter(Texts.t("Manuels"), [
			_article("rack", {"places": Rack.SLOT_COUNT - 1, "manuels": Keybinds.key_label("panel_manuals")}),
			_article("class_manual"),
			_article("manual_levels", {"max": Manual.MAX_LEVEL}),
			_article("cells"),
			_article("talent_trees", {"details": Keybinds.key_label("item_details")}),
		]),
		_chapter(Texts.t("Bonus"), [
			[Glossary.title("additive"), Glossary.definition("additive")],
			[Glossary.title("multiplicative"), Glossary.definition("multiplicative")],
		]),
		_chapter(Texts.t("Défenses"), [
			[RichText.capitalized(StatMod.name("armor")), Texts.t(StatHelp.TEXTS["armor"])],
			[RichText.capitalized(StatMod.name("evasion")), Texts.t(StatHelp.TEXTS["evasion"])],
			_article("resistances", {"plafond": StatMod.percentage(CharacterStats.MAX_RESISTANCE)}),
		]),
		_chapter(Texts.t("Flacons"), [_article("flasks", {"touches": " ".join(flask_keys)})]),
		_chapter(Texts.t("Monnaie"), coins),
		_chapter(Texts.t("Voyage"), [
			_article("portal", {"portail": Keybinds.key_label("town_portal")}),
			_article("waypoints"),
		]),
	]


static func _chapter(title_text: String, articles: Array) -> Dictionary:
	return {"title": title_text, "articles": articles}


static func _article(id: String, values := {}) -> Array:
	return [Texts.t(ARTICLES[id][0]), Texts.t(ARTICLES[id][1]).format(values)]


static func _state_text(kind: int) -> String:
	var per_second := StatusEffects.burn_per_second(kind)
	var duration: float = StatusEffects.DURATIONS[kind]
	var strength := {
		StatusEffects.Kind.NUMB: StatMod.percentage(StatusEffects.NUMB * 100.0),
		StatusEffects.Kind.CHILL: StatMod.percentage(StatusEffects.CHILL * 100.0),
		StatusEffects.Kind.BLESSING: StatMod.percentage(StatusEffects.BLESSING * 100.0),
		StatusEffects.Kind.CURSED: StatMod.number(StatusEffects.CURSE),
	}
	return Texts.t(STATE_TEXTS[kind]).format({
		"part": StatMod.percentage(per_second * 100.0),
		"duree": StatMod.number(duration),
		"total": StatMod.percentage(per_second * duration * 100.0),
		"force": strength.get(kind, ""),
		"soin": StatMod.percentage(StatusEffects.ROT_HEAL * 100.0),
		"ticks": StatMod.number(1.0 / StatusEffects.DOT_TICK),
	})


func _label(text_value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
