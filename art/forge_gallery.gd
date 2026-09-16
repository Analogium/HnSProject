class_name ForgeGallery
extends Control

## La planche-contact de la forge : un archétype par page, ses quatre variantes en
## lignes, ses neuf animations en colonnes, le tout en train de jouer. Sans elle
## on règle une silhouette à l'aveugle, en relançant le jeu et en cherchant un
## ennemi du bon type.
##
## Et, depuis les planches d'objets, la **fiche d'une base** : ce qu'elle est,
## entre quels niveaux de zone elle tombe, et tout ce qu'elle peut recevoir comme
## affixe — chaque palier avec les zones qui l'ouvrent et la plage dans laquelle
## il tire. Ces trois informations vivent dans trois fichiers différents, et les
## rapprocher à la main était le vrai coût de chaque retouche d'équilibrage.
##
## [S] écrit toutes les planches en PNG : un sprite exporté peut être retouché
## dans un éditeur d'image et rechargé comme un asset ordinaire.

const CELL := 64          # 32 px de sprite, agrandis 2 fois
const SCALE := 2
const COLS := 9           # 3 animations x 3 directions
## Dans le projet et non dans user:// : un dossier enfoui sous AppData, on ne
## le retrouve jamais. En jeu exporté res:// n'est pas inscriptible, on
## retombe donc sur user://.
const EXPORT_DIR := "res://art/generated"
const EXPORT_FALLBACK := "user://forge_export"

const ANIMS := ["idle", "walk", "attack"]

## Les planches d'objets, après les archétypes. Les bases y arrivent dans l'ordre
## du catalogue — par lignée, puis par palier — donc les trois âges d'un même
## objet sont voisins, et c'est exactement la comparaison qu'on vient faire.
##
## Agrandies deux fois : à leur taille native l'icône fait seize pixels alors que
## le sac l'agrandit pour remplir sa case, et une planche qui montre plus petit
## que le jeu ne sert à rien.
const ITEM_COLS := 6
const ITEM_ROWS := 4
const ITEM_CELL := Vector2(104.0, 60.0)
const ITEM_SCALE := 2

## La fiche d'une base. Elle remplace la planche au lieu de se poser à côté : elle
## a besoin de toute la largeur.
##
## **Deux volets**, parce que les deux questions qu'on vient poser ne sont pas de
## la même taille : « qu'est-ce que cette base peut avoir » se répond d'un coup
## d'œil sur dix-sept lignes, « combien donne celui-là et quand » demande un
## tableau. Mélangés dans un seul damier, ils étaient illisibles.
const SHEET_TOP := 68.0
## Dix et non onze : les bijoux acceptent vingt-trois affixes depuis les dégâts
## ajoutés par nature, et la liste doit tenir au-dessus de l'aide. Le test de
## hauteur dira quand le prochain affixe la fera déborder.
const SHEET_LINE := 10.0
const SHEET_SIZE := 8
const SHEET_TITLE_SIZE := 9

const LIST_X := 10.0
const LIST_W := 262.0
## Les deux colonnes de la liste, en décalage depuis son bord, comme le tableau de
## droite. L'identifiant tenait dans 78 px jusqu'aux dégâts ajoutés par nature :
## `lightning_to_attacks` touchait « dégâts de foudre aux attaques », et seule une
## capture le voyait (`test_the_affix_ids_clear_their_column`).
const COL_ID := 3.0
const COL_STAT := 92.0
const TABLE_X := 292.0
const TABLE_W := 338.0
## Les trois colonnes du tableau de droite, en décalage depuis son bord.
const COL_TIER := 0.0
const COL_ZONES := 46.0
const COL_VALUE := 158.0

const SHEET_TITLE := Color(0.90, 0.88, 0.95)
const SHEET_TEXT := Color(0.74, 0.72, 0.82)
const SHEET_MUTED := Color(0.52, 0.50, 0.60)
const SHEET_VALUE := Color(0.62, 0.78, 1.00)
## La ligne choisie dans la liste. Un fond plein plutôt qu'une couleur de texte :
## il faut voir d'où l'on vient sans lire, en passant d'un affixe à l'autre.
const SHEET_SELECTED := Color(0.20, 0.22, 0.32)
const SHEET_SEPARATOR := Color(0.26, 0.25, 0.32)


@onready var header: Label = $Header
@onready var footer: Label = $Footer
@onready var columns: Label = $Columns
@onready var stage: Node2D = $Stage

## La page courante : un archétype, ou la planche d'objets en dernier.
var _index := 0
var _status := ""
## L'index dans ItemCatalog.ALL de la base dont on regarde la fiche, -1 sur la
## planche. C'est le seul état qui distingue les deux écrans.
var _detail := -1
## L'affixe choisi dans la liste de gauche, dont le volet de droite montre le
## détail. Remis à zéro en changeant de base : la liste n'est pas la même, et
## garder le rang ferait atterrir sur un affixe qu'on n'a pas désigné.
var _affix_detail := 0


## Une ligne du tableau de droite : un palier, les zones où il sort **sur cette
## base**, et ce qu'il y donne. Une petite classe et non un tableau indexé à la
## main — `tier.zones` se relit là où `p[1]` oblige à se souvenir de l'ordre.
class Tier:
	var number: int
	var zones: Vector2i
	var value: String

	func _init(p_number: int, p_zones: Vector2i, p_value: String) -> void:
		number = p_number
		zones = p_zones
		value = p_value


## Les archétypes, puis autant de planches d'objets qu'il en faut.
static func _item_pages() -> int:
	return ceili(float(ItemCatalog.ALL.size()) / float(ITEM_COLS * ITEM_ROWS))


static func _pages() -> int:
	return SpriteForge.ARCHETYPES.size() + _item_pages()


func _ready() -> void:
	# Posés ici et non dans la scène : le clic sur un objet doit arriver jusqu'à
	# _gui_input, et le fond comme les trois étiquettes le mangeraient avant —
	# ils couvrent toute la largeur. Un filtre par défaut est un détail qui
	# change d'une version du moteur à l'autre ; celui-ci est écrit.
	mouse_filter = Control.MOUSE_FILTER_STOP
	for child in get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


## Clic gauche : sur la planche d'objets il ouvre la fiche de l'objet visé, sur
## une fiche il la referme. Pas de bouton « retour » à viser — on ressort par où
## l'on est entré, et Échap fait la même chose.
func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return

	if _detail >= 0:
		# Dans la fiche, un clic sur la liste choisit l'affixe ; ailleurs, il
		# referme. Choisir prime : c'est le geste qu'on répète, et refermer par
		# mégarde en visant une ligne serait le pire des deux.
		var affix := _affix_at(click.position)
		if affix >= 0:
			_affix_detail = affix
			_build()
		else:
			_close_sheet()
	else:
		var targeted := _item_at(click.position)
		if targeted < 0:
			return
		_detail = targeted
		_build()
	accept_event()


## La ligne de la liste sous un point, ou -1.
func _affix_at(point: Vector2) -> int:
	if _detail < 0:
		return -1
	var affixes := affixes_of(ItemCatalog.ALL[_detail])
	for rank in affixes.size():
		if _rank_rect(rank).has_point(point):
			return rank
	return -1


## L'objet sous un point, ou -1. Hors d'une planche d'objets, il n'y a rien à
## viser : les archétypes ne sont pas des bases du catalogue.
func _item_at(point: Vector2) -> int:
	if _index < SpriteForge.ARCHETYPES.size():
		return -1
	var first := (_index - SpriteForge.ARCHETYPES.size()) * ITEM_COLS * ITEM_ROWS
	for rank in ITEM_COLS * ITEM_ROWS:
		if first + rank >= ItemCatalog.ALL.size():
			break
		if _item_rect(rank).has_point(point):
			return first + rank
	return -1


## Referme la fiche **sur la page où se trouve l'objet regardé**, et non sur
## celle d'où l'on venait : les flèches font défiler le catalogue entier depuis
## la fiche, et retomber trois planches plus tôt donnerait l'impression d'avoir
## perdu sa place.
func _close_sheet() -> void:
	if _detail >= 0:
		_index = SpriteForge.ARCHETYPES.size() + _detail / (ITEM_COLS * ITEM_ROWS)
	_detail = -1
	_build()


func _unhandled_input(event: InputEvent) -> void:
	var key := Keys.pressed_down(event)
	if key == KEY_NONE:
		return

	# Retenu avant le match : un changement de scène détache ce nœud de l'arbre
	# et get_viewport() renverrait null.
	var vp := get_viewport()

	match key:
		# Sur une fiche, les flèches parcourent le catalogue entier plutôt que
		# les pages : les paliers d'une même lignée s'y suivent, donc comparer
		# une épée à l'épée large est une seule touche.
		KEY_RIGHT, KEY_SPACE:
			if _detail >= 0:
				_detail = (_detail + 1) % ItemCatalog.ALL.size()
				# La liste change avec la base : garder le rang ferait atterrir
				# sur un affixe qu'on n'a pas désigné.
				_affix_detail = 0
			else:
				_index = (_index + 1) % _pages()
			_build()
		KEY_LEFT:
			if _detail >= 0:
				_detail = (_detail - 1 + ItemCatalog.ALL.size()) % ItemCatalog.ALL.size()
				_affix_detail = 0
			else:
				_index = (_index - 1 + _pages()) % _pages()
			_build()
		# Haut et bas ne servent que dans la fiche : la planche n'a qu'une
		# dimension de navigation, et leur donner un sens ailleurs inventerait un
		# geste que rien n'annonce.
		KEY_UP, KEY_DOWN:
			if _detail < 0:
				return
			var affixes := affixes_of(ItemCatalog.ALL[_detail])
			if affixes.is_empty():
				return
			var step := 1 if key == KEY_DOWN else -1
			_affix_detail = posmod(_affix_detail + step, affixes.size())
			_build()
		KEY_S:
			_export()
		# La touche qui a ouvert la forge la referme, comme pour la carte de
		# réglage (F3) — et Échap referme n'importe quel aperçu. Une fiche
		# ouverte se referme d'abord : c'est la règle du menu de pause, où Échap
		# sort des options avant de sortir du menu.
		KEY_F4, KEY_ESCAPE:
			if _detail >= 0:
				_close_sheet()
			else:
				Game.go_back()
		_:
			return

	vp.set_input_as_handled()


func _build() -> void:
	for child in stage.get_children():
		child.queue_free()

	if _detail >= 0:
		_build_detail()
		return

	if _index >= SpriteForge.ARCHETYPES.size():
		_build_items()
		return

	var archetype: String = SpriteForge.ARCHETYPES[_index]
	var x0 := (size.x - COLS * CELL) * 0.5
	var y0 := 62.0

	for variant in SpriteForge.VARIANTS:
		var frames := SpriteForge.frames(archetype, variant)
		var col := 0
		for anim in ANIMS:
			for dir in SpriteForge.DIRS:
				var s := AnimatedSprite2D.new()
				s.sprite_frames = frames
				s.scale = Vector2(SCALE, SCALE)
				s.position = Vector2(
					x0 + col * CELL + CELL * 0.5,
					y0 + variant * CELL + CELL * 0.5
				)
				s.play("%s_%s" % [anim, dir])
				# L'attaque ne boucle pas dans le jeu — sur la planche, si :
				# une pose figée ne dit rien du mouvement.
				s.animation_finished.connect(_replay.bind(s))
				stage.add_child(s)
				col += 1

	header.text = "FORGE  —  %s   (variante 0 a %d, de haut en bas)" % [
		archetype.to_upper(), SpriteForge.VARIANTS - 1
	]
	columns.text = "        repos  ^  |  marche  ^  |  attaque  ^"
	footer.text = "\n".join([
		"[<-] [->] page          [S] exporter les planches en PNG",
		"[F4] ou [ECHAP] retour",
		_status,
	])


## Une planche d'objets : les bases du catalogue sous leur nom et leur palier,
## dessinées comme le sac les dessine puis agrandies d'ITEM_SCALE.
func _build_items() -> void:
	var page := _index - SpriteForge.ARCHETYPES.size()
	var per_page := ITEM_COLS * ITEM_ROWS
	var first := page * per_page
	var last := mini(first + per_page, ItemCatalog.ALL.size())

	for i in range(first, last):
		var base: ItemBase = ItemCatalog.ALL[i]
		var rank := i - first
		var center := _item_center(rank)

		var s := Sprite2D.new()
		s.texture = SpriteForge.inventory_icon(base.kind, Vector2i.ZERO, base.tier)
		s.scale = Vector2(ITEM_SCALE, ITEM_SCALE)
		s.position = center
		stage.add_child(s)

		var l := Label.new()
		l.text = "%s %d" % [base.display_name, base.tier]
		l.add_theme_font_size_override("font_size", 8)
		l.add_theme_color_override("font_color", Color(0.70, 0.68, 0.76))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# Largeur imposée **et** texte coupé : sans la largeur un nom long se
		# centre sur lui-même et déborde sur l'objet voisin, sans la coupe il
		# déborde quand même. « Marteau de guerre » et « Baguette » se
		# recouvraient exactement comme ça.
		l.size = Vector2(ITEM_CELL.x, 10.0)
		l.clip_text = true
		# Sans ça l'étiquette mange le clic sur l'objet qu'elle nomme : elle est
		# posée dans sa case, et c'est le bas de la case qu'on vise naturellement.
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.position = center + Vector2(-ITEM_CELL.x * 0.5, ITEM_CELL.y * 0.5 - 14.0)
		stage.add_child(l)

	header.text = "FORGE  —  OBJETS  %d/%d   (%d bases, par lignee puis par palier)" % [
		page + 1, _item_pages(), ItemCatalog.ALL.size()
	]
	columns.text = "        palier 1 terne  |  2 acier  |  3 clair"
	footer.text = "\n".join([
		"[<-] [->] page          [clic sur un objet] sa fiche : chutes, affixes, paliers",
		"[F4] ou [ECHAP] retour",
		_status,
	])


## La fiche d'une base : son identité en tête, ses affixes à gauche, le détail
## du sélectionné à droite.
func _build_detail() -> void:
	var base: ItemBase = ItemCatalog.ALL[_detail]
	var affixes := affixes_of(base)
	_affix_detail = clampi(_affix_detail, 0, maxi(affixes.size() - 1, 0))

	header.text = "FORGE  —  %s   (palier %d de la lignée « %s »)" % [
		base.display_name.to_upper(), base.tier, base.lineage
	]
	columns.text = _identity(base)

	var icon := Sprite2D.new()
	icon.texture = SpriteForge.inventory_icon(base.kind, Vector2i.ZERO, base.tier)
	icon.scale = Vector2(ITEM_SCALE, ITEM_SCALE)
	icon.position = Vector2(size.x - 40.0, 44.0)
	stage.add_child(icon)

	# Le trait qui sépare les deux volets. Sans lui les deux colonnes de texte se
	# lisent comme une seule liste en deux morceaux.
	#
	# `separation` et non `trait` : GDScript réserve ce mot, et l'erreur qu'il
	# rend — « Expected variable name after var » — ne le nomme pas.
	_rectangle(
		SHEET_SEPARATOR,
		Vector2(TABLE_X - 14.0, SHEET_TOP),
		Vector2(1.0, footer.offset_top - SHEET_TOP - 6.0)
	)

	_build_list(base, affixes)
	if not affixes.is_empty():
		_build_table(base, affixes[_affix_detail])

	footer.text = "\n".join([
		"[HAUT/BAS] ou [clic] choisir un affixe        [<-] [->] objet précédent / suivant",
		"[ECHAP] ou [F4] retour à la planche",
		_status,
	])


## Le volet de gauche : un affixe par ligne, avec la statistique qu'il touche et
## **tout ce qu'il peut donner sur cette base**. C'est la ligne qui permet de
## comparer deux affixes sans ouvrir chacun.
func _build_list(base: ItemBase, affixes: Array) -> void:
	_label(
		"AFFIXES POSSIBLES  (%d)" % affixes.size(),
		Vector2(LIST_X, SHEET_TOP), SHEET_MUTED, SHEET_SIZE
	)

	for rank in affixes.size():
		var affix: ItemAffix = affixes[rank]
		var r := _rank_rect(rank)

		if rank == _affix_detail:
			_rectangle(SHEET_SELECTED, r.position, r.size)

		var tint := SHEET_TITLE if rank == _affix_detail else SHEET_TEXT
		_label(affix.id, Vector2(LIST_X + COL_ID, r.position.y), tint, SHEET_SIZE)
		_label(
			StatMod.name(affix.stat, affix.scope),
			Vector2(LIST_X + COL_STAT, r.position.y), SHEET_MUTED, SHEET_SIZE
		)
		_right_column(
			_total_span(base, affix),
			Vector2(LIST_X, r.position.y), LIST_W - 6.0, SHEET_VALUE
		)


## Le volet de droite : ce que l'affixe choisi donne, palier par palier.
##
## Trois colonnes titrées plutôt que trois nombres collés. Le poids est rendu en
## pourcentage : « 12 » ne veut rien dire seul, « un tirage sur sept » se compare
## à l'affixe d'à côté sans calculer.
func _build_table(base: ItemBase, affix: ItemAffix) -> void:
	var y := SHEET_TOP
	_label(
		"%s  —  %s" % [affix.id, StatMod.name(affix.stat, affix.scope)],
		Vector2(TABLE_X, y), SHEET_TITLE, SHEET_TITLE_SIZE
	)

	y += SHEET_LINE + 2.0
	_label(_weight_text(base, affix), Vector2(TABLE_X, y), SHEET_MUTED, SHEET_SIZE)

	y += SHEET_LINE + 6.0
	_label("palier", Vector2(TABLE_X + COL_TIER, y), SHEET_MUTED, SHEET_SIZE)
	_label("zones où il sort", Vector2(TABLE_X + COL_ZONES, y), SHEET_MUTED, SHEET_SIZE)
	_label("valeur tirée", Vector2(TABLE_X + COL_VALUE, y), SHEET_MUTED, SHEET_SIZE)

	y += 3.0
	_rectangle(
		SHEET_SEPARATOR, Vector2(TABLE_X, y + SHEET_LINE - 2.0), Vector2(TABLE_W - 8.0, 1.0)
	)

	for tier in tiers_of(base, affix):
		y += SHEET_LINE
		var p: Tier = tier
		_label("T%d" % p.number, Vector2(TABLE_X + COL_TIER, y), SHEET_TEXT, SHEET_SIZE)
		_label(
			_zones_text(p.zones), Vector2(TABLE_X + COL_ZONES, y), SHEET_TEXT, SHEET_SIZE
		)
		_label(
			p.value, Vector2(TABLE_X + COL_VALUE, y), SHEET_VALUE, SHEET_SIZE
		)


## « zone 34 », « zones 19 à 22 », « zones 34 et au-delà ».
##
## Le singulier n'est pas de la coquetterie : « zones 34 à 34 » se lit comme une
## erreur d'affichage. Et le dernier niveau du jeu n'est pas une borne mais une
## fin d'échelle — l'en-tête dit déjà « et au-delà » de la fenêtre de chute, le
## tableau dirait « à 60 » de la même chose, et les deux phrases se
## contrediraient à trois centimètres l'une de l'autre.
static func _zones_text(zones: Vector2i) -> String:
	if zones.x == zones.y:
		return "zone %d" % zones.x
	if zones.y >= Game.MAX_LEVEL:
		return "zones %d et au-delà" % zones.x
	return "zones %d à %d" % [zones.x, zones.y]


## Ce que pèse cet affixe dans la réserve de cette base. Le poids brut ne se
## compare à rien tant qu'on ne connaît pas le total ; la part, si.
static func _weight_text(base: ItemBase, affix: ItemAffix) -> String:
	var total := 0
	for other in ItemAffixPool.compatibles(base):
		total += (other as ItemAffix).weight
	if total <= 0:
		return "poids %d" % affix.weight
	return "poids %d sur %d  —  %d %% des affixes tirés ici" % [
		affix.weight, total, roundi(100.0 * float(affix.weight) / float(total))
	]


## Les affixes qu'une base peut recevoir, dans l'ordre où la fiche les liste.
##
## Triés par identifiant : on vient chercher un affixe qu'on a en tête, et
## l'ordre de la réserve — thématique, puis chronologique — ne se devine pas.
static func affixes_of(base: ItemBase) -> Array:
	var out := ItemAffixPool.compatibles(base)
	out.sort_custom(func(a: ItemAffix, b: ItemAffix) -> bool: return a.id < b.id)
	return out


## La plage de zones dans laquelle cette base tombe, en bornes concrètes : le
## zéro de « sans fin » d'ItemCatalog résolu ici une bonne fois, pour que le
## reste de la fiche n'ait pas à connaître la convention.
static func zones_of(base: ItemBase) -> Vector2i:
	var window := ItemCatalog.drop_window(base)
	return Vector2i(window.x, Game.MAX_LEVEL if window.y <= 0 else window.y)


## Les paliers d'un affixe **sur cette base**, et rien d'autre : ceux qu'elle
## peut atteindre, avec les zones où elle les sort réellement.
##
## Les bornes sont celles de la base et non celles du palier. Sur une épée qui
## cesse de tomber en zone 22, annoncer « de 19 à 51 » oblige à faire
## l'intersection de tête ; « zones 19 à 22 » se lit sans rien calculer.
static func tiers_of(base: ItemBase, affix: ItemAffix) -> Array:
	var zones := zones_of(base)
	var out := []
	for raw in affix.open_between(zones.x, zones.y):
		var index := int(raw)
		out.append(Tier.new(
			index + 1, affix.tier_window(index, zones.x, zones.y), affix.span(index)
		))
	return out


## Tout ce que cet affixe peut donner sur cette base, du pire palier au meilleur.
## Les bornes sont cherchées et non déduites des extrémités de la liste : un
## affixe dont la valeur baisse quand il s'améliore — un temps de recharge —
## inverserait les deux.
static func _total_span(base: ItemBase, affix: ItemAffix) -> String:
	var tiers := tiers_of(base, affix)
	if tiers.is_empty():
		return ""
	var zones := zones_of(base)
	var low := INF
	var top := -INF
	for raw in affix.open_between(zones.x, zones.y):
		var tier: ItemAffixTier = affix.tiers[int(raw)]
		low = minf(low, tier.min_value)
		# D'une fourchette, le plus haut que peut sortir sa borne haute.
		top = maxf(top, tier.max_top if affix.is_a_range() else tier.max_value)
	var mode := StatMod.Mode.PERCENT if affix.percent else StatMod.Mode.FLAT
	return StatMod.range_label(affix.stat, mode, low, top)


## L'en-tête d'une fiche : ce que la base **est**, et entre quels niveaux de zone
## elle tombe. Cette dernière est la seule information de l'écran qu'on ne peut
## lire nulle part ailleurs — ni dans le `.tres` de la base, ni dans le
## catalogue : elle naît de la rencontre entre le niveau requis et la règle de
## relève.
static func _identity(base: ItemBase) -> String:
	var pieces := [", ".join(base.tags)]
	var implicit := base.implicit()
	if implicit != null:
		pieces.append("implicite %s" % implicit.label())
	# « 1 × 1 case » et non « 1 × 1 cases » : l'anneau est le seul objet du
	# catalogue à n'en occuper qu'une, et c'est le premier qu'on regarde.
	var cells := base.grid_size.x * base.grid_size.y
	pieces.append("%d × %d %s" % [
		base.grid_size.x, base.grid_size.y, "case" if cells <= 1 else "cases"
	])
	pieces.append(_window_text(base))
	return "   ·   ".join(pieces)


## Statique, et testée : c'est une phrase, donc rien de ce qui l'entoure ne
## signale qu'elle est fausse. Elle a déjà annoncé « tombe dans les zones 35 à 0 »
## sans que rien d'autre qu'une capture ne le voie.
static func _window_text(base: ItemBase) -> String:
	var window := ItemCatalog.drop_window(base)
	if window.y <= 0:
		return "tombe dans les zones %d et au-delà" % window.x
	if window.x > window.y:
		return "NE TOMBE JAMAIS"
	return "tombe dans les zones %d à %d" % [window.x, window.y]


## Le rectangle d'une ligne de la liste, et **le seul endroit qui le sait** : le
## fond de la ligne choisie, son texte et le clic le visent tous les trois.
func _rank_rect(rank: int) -> Rect2:
	return Rect2(
		Vector2(LIST_X, SHEET_TOP + SHEET_LINE + 4.0 + float(rank) * SHEET_LINE),
		Vector2(LIST_W, SHEET_LINE)
	)


## La hauteur qu'occupe le plus haut des deux volets. C'est elle que le test
## compare au haut de l'aide : la liste grandit avec chaque affixe ajouté au
## projet, et rien d'autre ne dirait qu'elle a fini par déborder.
static func sheet_height(base: ItemBase) -> float:
	var affixes := affixes_of(base)
	var list := SHEET_TOP + SHEET_LINE + 4.0 + float(affixes.size()) * SHEET_LINE
	var table := SHEET_TOP
	for affix in affixes:
		table = maxf(
			table,
			SHEET_TOP + SHEET_LINE * 3.0 + 11.0
				+ float(tiers_of(base, affix).size()) * SHEET_LINE
		)
	return maxf(list, table)


## Un aplat de la fiche : le fond de la ligne choisie, le trait entre les deux
## volets, le filet sous les titres du tableau. Les trois posaient les mêmes
## quatre propriétés, dont le `mouse_filter` sans lequel l'aplat mange le clic
## qu'il recouvre.
func _rectangle(color: Color, at: Vector2, size_value: Vector2) -> void:
	var r := ColorRect.new()
	r.color = color
	r.position = at
	r.size = size_value
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(r)


## Une étiquette de la fiche. Elles sont nombreuses — jusqu'à cent quinze pour un
## anneau — mais posées une fois et jamais retouchées : cet écran ne s'anime pas.
## Un Label par entrée plutôt qu'un bloc de texte par colonne, parce que la police
## n'est pas à chasse fixe et qu'un tableau aligné à coups d'espaces serait en
## escalier.
func _label(text_value: String, at: Vector2, tint: Color, body := SHEET_SIZE) -> Label:
	var l := Label.new()
	l.text = text_value
	l.position = at
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", body)
	l.add_theme_color_override("font_color", tint)
	stage.add_child(l)
	return l


## La même, calée sur son bord droit. Une colonne de valeurs alignée à droite se
## compare d'un coup d'œil ; alignée à gauche, il faut lire chaque nombre.
func _right_column(text_value: String, at: Vector2, width: float, tint: Color) -> void:
	var l := _label(text_value, at, tint)
	l.size = Vector2(width, SHEET_LINE)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


## Le centre de la case d'un objet sur la planche, et **le seul endroit qui le
## sait** : le dessin et le clic le visent tous les deux. Ce genre de paire ne se
## contredit pas le jour où on l'écrit, mais le jour où l'on décale la grille de
## deux pixels et où le clic reste sur l'ancienne.
func _item_center(rank: int) -> Vector2:
	var x0 := (size.x - ITEM_COLS * ITEM_CELL.x) * 0.5 + ITEM_CELL.x * 0.5
	return Vector2(
		x0 + (rank % ITEM_COLS) * ITEM_CELL.x,
		76.0 + (rank / ITEM_COLS) * ITEM_CELL.y
	)


func _item_rect(rank: int) -> Rect2:
	return Rect2(_item_center(rank) - ITEM_CELL * 0.5, ITEM_CELL)


func _replay(s: AnimatedSprite2D) -> void:
	if is_instance_valid(s):
		s.play()


## Compose une planche par variante : une ligne d'images par animation, dans
## l'ordre de SpriteForge. Le fichier obtenu s'ouvre tel quel dans un éditeur
## de pixel art.
func _export() -> void:
	# out_dir et pas dir : la boucle plus bas itère déjà sur les directions.
	# On teste l'existence plutôt que le code de retour, qui vaut aussi erreur
	# quand le dossier est simplement déjà là.
	var out_dir := EXPORT_DIR
	DirAccess.make_dir_recursive_absolute(out_dir)
	if not DirAccess.dir_exists_absolute(out_dir):
		out_dir = EXPORT_FALLBACK
		DirAccess.make_dir_recursive_absolute(out_dir)

	var written := 0
	for archetype in SpriteForge.ARCHETYPES:
		for variant in SpriteForge.VARIANTS:
			var cfg := SpriteForge.config(archetype, variant)
			var rows: Array[Array] = []
			for anim in ANIMS:
				for dir in SpriteForge.DIRS:
					var row: Array = []
					for i in _frame_count(anim):
						row.append(SpriteForge.frame_image(cfg, dir, anim, i))
					rows.append(row)

			var sheet := _compose(rows)
			var path := "%s/%s_v%d.png" % [out_dir, archetype, variant]
			if sheet.save_png(path) == OK:
				written += 1

	_status = "%d planches ecrites dans %s" % [
		written, ProjectSettings.globalize_path(out_dir)
	]
	_build()


func _frame_count(anim: String) -> int:
	match anim:
		"walk": return SpriteForge.WALK_SWING.size()
		"attack": return SpriteForge.ATTACK_FRAMES
		_: return SpriteForge.IDLE_BOB.size()


func _compose(rows: Array[Array]) -> Image:
	var widest := 0
	for row in rows:
		widest = maxi(widest, row.size())

	var f := SpriteForge.FRAME
	var sheet := Image.create_empty(widest * f, rows.size() * f, false, Image.FORMAT_RGBA8)
	var region := Rect2i(0, 0, f, f)

	for y in rows.size():
		var row: Array = rows[y]
		for x in row.size():
			sheet.blit_rect(row[x], region, Vector2i(x * f, y * f))

	return sheet
