class_name InventoryPanel
extends Control

## Le sac, à la touche I : une grille rectangulaire où chaque objet occupe la
## place qu'il prend réellement, et où on range à la souris.
##
## Deux gestes pour une seule mécanique : **glisser** (presser, déplacer,
## relâcher) et **clic-clic** (cliquer pour prendre, cliquer pour poser). Un
## relâchement qui n'a pas bougé de plus de quelques pixels est un clic, pas la fin
## d'un glisser — c'est la seule règle qui les sépare, et elle évite de choisir à
## la place du joueur.
##
## Relâché **hors du panneau**, l'objet tombe au sol ; relâché sur un emplacement,
## il est porté si c'est le bon. Le clic droit reste le raccourci : équiper,
## retirer, jeter ce qu'on tient.
##
## Il ne détient rien : le sac vit sur le joueur. Deux listes à tenir d'accord
## finissent toujours par diverger.

## Ce qu'on jette du sac. Un signal plutôt qu'une référence au monde : le
## panneau vit dans une CanvasLayer et n'a aucune raison de savoir où poser des
## nœuds — c'est la scène qui sait.
signal drop_requested(item: Item)

const CELL := 20.0
const PAD := 1.0
const HEADER := 16.0
## Deux lignes d'aide : les gestes sont maintenant trop nombreux pour tenir sur
## la largeur du panneau.
const FOOTER := 22.0
## La fenêtre de personnage. Chaque emplacement occupe le rectangle de cases qu'un
## objet de sa famille occuperait dans le sac : la place que prend un objet est une
## information de jeu, et l'équipement doit la dire aussi. Une grille de carrés
## identiques donnait dix cases interchangeables où plus rien n'annonçait ce qui
## allait où.
##
## Trois colonnes larges séparées par une gouttière d'une case, et le corps qui
## descend : le portrait, la tête et le cou en haut ; les deux mains encadrant le
## torse ; les gants, la ceinture et les bottes en bas ; les deux bagues dans les
## gouttières.
const DOLL := {
	"helmet": Rect2i(4, 0, 3, 2), "amulet": Rect2i(8, 0, 3, 2),
	"weapon": Rect2i(0, 2, 3, 3), "chest": Rect2i(4, 2, 3, 3), "offhand": Rect2i(8, 2, 3, 3),
	"gloves": Rect2i(0, 5, 3, 2), "belt": Rect2i(4, 5, 3, 2), "boots": Rect2i(8, 5, 3, 2),
	"ring_left": Rect2i(3, 5, 1, 2), "ring_right": Rect2i(7, 5, 1, 2),
}
const DOLL_COLS := 11
const DOLL_ROWS := 7

const DOLL_AREA := Rect2i(0, 0, 2, 2)
const DOLL_ANIM := "idle_down"

## Un emplacement vide montre l'objet qu'il attend, peint très sombre : une
## silhouette fantôme se comprend sans lire, là où « BAGUE G. » ne tenait même pas
## dans sa case.
const GHOST := Color(1.0, 1.0, 1.0, 0.13)
## Marge autour d'une icône dans son emplacement. Sans elle, un objet qui remplit
## exactement son rectangle mange les lignes de la grille et on ne voit plus où
## il commence.
const MARGIN := 3

const SLOT := Color(0.14, 0.13, 0.17)
const SLOT_EDGE := Color(0.22, 0.20, 0.26)
## Fond des cases occupées : c'est lui qui donne la forme de l'objet d'un coup
## d'œil, avant même que l'icône soit lue.
const ITEM_BACK := Color(0.22, 0.21, 0.28)
## Le cadre d'un objet rangé prend sa couleur de rareté, assombrie pour ne pas
## crier : le sac se lit alors d'un coup d'œil, sans survoler case par case.
const ITEM_EDGE_DIM := 0.3
## Distance à partir de laquelle un relâchement est la fin d'un glisser et non
## un clic. Quelques pixels suffisent : c'est le tremblement de la main qu'on
## veut ignorer, pas un déplacement.
const DRAG_MIN := 5.0
const CAN_PLACE := Color(0.35, 0.85, 0.45, 0.28)
const BLOCKED := Color(0.90, 0.30, 0.28, 0.28)
## L'infobulle. Son fond est celui de toutes les infobulles du jeu et vit dans
## UiPalette ; son cadre prend la couleur de rareté de l'objet — la même
## information que le halo au sol, donc la même couleur.
##
## La ligne d'implicite : ce que la base garantit, avant tout tirage.
const TIP_IMPLICIT := Color(0.62, 0.60, 0.68)
## Le niveau de l'objet, sous son nom. Plus effacé que l'implicite : c'est une
## étiquette, pas une ligne de statistique, et il ne doit pas se lire comme un
## bonus de plus.
const TIP_LEVEL := Color(0.46, 0.44, 0.52)
## La colonne des paliers, sous Alt. Plus sourde que les affixes eux-mêmes :
## c'est une note de bas de page sur la ligne, pas une deuxième ligne.
const TIP_TIER := Color(0.55, 0.53, 0.62)
## Gouttière entre un affixe et son palier. Collés, on ne sait plus si « T4 »
## appartient à la ligne du dessus ou du dessous.
const TIP_TIER_GAP := 10.0
const TIP_EXPLICIT := Color(0.55, 0.75, 1.0)
const TIP_PAD := 5.0
const TIP_LINE := 9.0
## Écart entre le sac et son infobulle : collée, on ne sait plus laquelle des
## deux bordures appartient à quoi.
const TIP_GAP := 5.0
const TIP_MIN_W := 74.0
const FONT_SIZE := 8
const TITLE_SIZE := 9

@onready var title: Label = $Title

## La même source que les autres panneaux du jeu : get_theme_default_font() rend
## la même police, mais oblige à retester le null à chaque bloc de dessin.
var _font: Font

var _player: Player
var _inventory: Inventory

## L'objet tenu à la main, sorti du sac tant qu'on ne l'a pas reposé.
var _held: Item
## Sa case d'origine, pour le rendre là où on l'a pris si on referme le sac.
var _from := Vector2i.ZERO
## Quelle case de l'objet le curseur avait attrapée : sans elle, un plastron
## saisi par son coin bas-droit sauterait sous le curseur au moment de la prise.
var _grab := Vector2i.ZERO
## Le même décalage en pixels. La case sert à viser, les pixels à dessiner :
## l'objet suit le curseur au pixel près, seule sa destination s'aligne.
var _grab_px := Vector2.ZERO
## Dernière position connue de la souris, dans le repère du panneau.
var _mouse := Vector2.ZERO
## Où le bouton a été pressé, pour distinguer le glisser du clic.
var _press := Vector2.ZERO
## Alt maintenue : l'infobulle montre alors le palier de chaque affixe et la
## fourchette de ce palier. Relevé dans _process, jamais posé depuis un
## événement — voir la raison là-bas.
var _alt := false
var _hover := Vector2i(-1, -1)
## L'emplacement d'équipement survolé, ou -1. Séparé de la case survolée : les
## deux zones ne se recouvrent pas, mais un même Vector2i ne peut pas désigner
## à la fois « case (2,1) du sac » et « emplacement torse ».
var _hover_slot := -1

## La silhouette du personnage. Dessinée par _draw et non montée comme
## AnimatedSprite2D : un nœud enfant se peint **au-dessus** du Control, donc de
## l'objet qu'on traîne à la souris, qui disparaîtrait en la traversant.
var _doll_frames: SpriteFrames
## L'image affichée, et la clé de ce qui est chargé. Sans la clé, chaque
## rafraîchissement rebâtirait les planches et relancerait l'animation.
var _doll_shown := 0
var _doll_key := ""


func _ready() -> void:
	visible = false
	_font = ThemeDB.fallback_font
	title.add_theme_color_override("font_color", UiPalette.TITRE)


## Le sac ouvert prend la souris. Le drapeau doit retomber quoi qu'il arrive —
## y compris si la zone est rechargée sac ouvert, sinon le joueur se retrouve
## incapable de frapper dans une scène où plus aucun panneau n'existe.
func _exit_tree() -> void:
	if visible:
		Game.grab_ui_input(self, false)


## La langue a changé. Ce qui est dessiné à la main ne se retraduit pas tout
## seul, contrairement aux `Label` des scènes — et le titre, écrit par le code,
## doit être refait plutôt que redessiné.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_on_changed()


func bind(player: Player) -> void:
	_player = player
	_inventory = player.inventory
	_inventory.changed.connect(_on_changed)
	player.equipment_changed.connect(_on_changed)

	# La taille se déduit de la grille au lieu d'être réglée dans la scène :
	# changer le nombre de colonnes du sac ne doit pas demander de rouvrir
	# l'éditeur. Le coin bas-droite, lui, reste celui posé par les ancres.
	var s := _panel_size()
	offset_left = offset_right - s.x
	offset_top = offset_bottom - s.y
	title.offset_right = s.x - 4.0

	_on_changed()


func toggle() -> void:
	visible = not visible
	Game.grab_ui_input(self, visible)
	if visible:
		# Sans ça, la case survolée reste celle d'avant la fermeture jusqu'au
		# premier mouvement de souris.
		_track(get_local_mouse_position())
	else:
		var left := _return_held()
		if left != null:
			drop_requested.emit(left)
	_on_changed()


func _input(event: InputEvent) -> void:
	if not visible or _inventory == null:
		return

	# La position vient de l'événement et non du curseur : c'est elle qui est vraie
	# au moment du clic, et elle rend le geste rejouable dans un test sans avoir à
	# déplacer la souris de l'écran.
	var souris := make_input_local(event) as InputEventMouse
	if souris == null:
		return

	if souris is InputEventMouseMotion:
		_track(souris.position)
		return

	if not _possede_le_clic(souris.position):
		return

	var button := souris as InputEventMouseButton
	if not button.pressed:
		if button.button_index == MOUSE_BUTTON_LEFT:
			_track(button.position)
			_release(button.position)
			get_viewport().set_input_as_handled()
		return

	# Le survol est recalé sur le clic : ouvrir le sac au clavier puis cliquer
	# sans bouger la souris ne doit pas viser la case d'avant.
	_track(button.position)

	match button.button_index:
		MOUSE_BUTTON_LEFT:
			_press = button.position
			# Presser en tenant quelque chose, c'est poser : le clic-clic se
			# résout ici, le glisser au relâchement.
			if _held != null:
				_resolve(button.position, false)
			else:
				_take(button.position)
		MOUSE_BUTTON_RIGHT:
			_right_click()
		_:
			return

	get_viewport().set_input_as_handled()


## Relâcher ne fait quelque chose que si la souris a bougé depuis la pression :
## sinon c'était un clic, et l'objet reste au curseur jusqu'au clic suivant.
func _release(point: Vector2) -> void:
	if _held == null or point.distance_to(_press) < DRAG_MIN:
		return
	_resolve(point, true)


## Ce que la souris survole, sac et emplacements ensemble.
func _track(point: Vector2) -> void:
	_mouse = point
	var cell := _cell_at(point)
	var slot := _slot_at(point)
	# Un objet en main suit le curseur au pixel : il faut alors redessiner à
	# chaque mouvement, et pas seulement quand on change de case.
	if cell == _hover and slot == _hover_slot and _held == null:
		return
	_hover = cell
	_hover_slot = slot
	queue_redraw()


## Le clic droit fait trois choses selon ce qu'il vise, et jamais deux à la
## fois : jeter ce qu'on tient, retirer ce qui est porté, équiper ce qu'on
## survole dans le sac.
func _right_click() -> void:
	if _held != null:
		drop_requested.emit(_held)
		_held = null
		queue_redraw()
		return
	if _player == null:
		return
	if _hover_slot >= 0:
		_unequip(EquipmentSlots.ids()[_hover_slot])
	else:
		_equip(_hover)


## Équipe l'objet du sac. Il est **sorti du sac d'abord** : c'est ce qui garantit
## que l'objet remplacé trouve au moins sa place. Ce qui déborde vraiment tombe au
## sol plutôt que d'annuler l'échange — on a demandé à porter cet objet.
func _equip(cell: Vector2i) -> void:
	var index := _inventory.index_at(cell)
	if index == Inventory.EMPTY:
		return
	var origine: Vector2i = _inventory.placed[index].cell
	var item := _inventory.take_at(cell)
	if not _wear(item):
		# Rien à quoi l'attacher : il retourne exactement d'où il vient.
		_inventory.place(item, origine)
	queue_redraw()


## Porte un objet et reloge celui qu'il remplace : le sac s'il y reste de la
## place, le sol sinon. **Le seul endroit** où le remplacement est relogé, pour le
## clic droit comme pour le dépôt.
##
## `emplacement` vide au clic droit — aucune destination désignée, le joueur
## choisit le premier doigt libre. Rempli quand l'objet a été lâché sur un
## emplacement précis : c'est celui-là qu'on veut, même si l'autre est libre.
func _wear(item: Item, emplacement := "") -> bool:
	if _player == null:
		return false
	# Un manuel ne se porte pas, il s'étudie. Le clic droit l'envoie donc au
	# râtelier plutôt qu'à un emplacement d'équipement, qui le refuserait — et
	# l'objet, refusé, retournerait dans sa case sans que rien ne dise pourquoi.
	var ancien := _player.etudier(item) if Ratelier.accepte(item) else _player.equip(item, emplacement)
	if ancien == item:
		return false
	if ancien != null and not _inventory.add(ancien):
		drop_requested.emit(ancien)
	return true


func _unequip(slot: String) -> void:
	var item := _player.unequip(slot)
	if item != null and not _inventory.add(item):
		drop_requested.emit(item)
	queue_redraw()


## Prendre en main ce qui est sous le curseur : un objet du sac, ou celui d'un
## emplacement porté. Un clic dans le vide ne fait rien.
func _take(point: Vector2) -> void:
	var slot := _slot_at(point)
	if slot >= 0:
		var porte: Item = _player.equipped(EquipmentSlots.ids()[slot]) if _player != null else null
		if porte == null:
			return
		_player.unequip(EquipmentSlots.ids()[slot])
		_held = porte
		# Rien à quoi le rendre : la case d'origine est volontairement hors
		# grille, `place` la refusera et `_return_held` cherchera une place.
		_from = Vector2i(-1, -1)
		_grab = Inventory.footprint(porte) / 2
		_grab_px = _span_size(Inventory.footprint(porte)) * 0.5
		queue_redraw()
		return

	var cell := _cell_at(point)
	var index := _inventory.index_at(cell)
	if index == Inventory.EMPTY:
		return
	_from = _inventory.placed[index].cell
	_grab = cell - _from
	_grab_px = point - _rect_of(_from, Vector2i.ONE).position
	_held = _inventory.take_at(cell)
	queue_redraw()


## Poser ce qu'on tient, là où le curseur le demande : dans un emplacement, dans
## le sac, ou au sol si on est sorti du panneau.
##
## `drag` dit ce qu'il faut faire d'un geste qui échoue. Au clic, l'objet reste
## en main — on garde la main levée plutôt que de le lâcher au hasard. Au
## relâchement, non : le joueur a lâché le bouton, l'objet ne peut pas rester
## collé au curseur, il retourne donc au sac.
func _resolve(point: Vector2, drag: bool) -> void:
	if _held == null:
		return

	var slot := _slot_at(point)
	if slot >= 0:
		if _equip_held(EquipmentSlots.ids()[slot]):
			queue_redraw()
			return
	elif not _panel_rect().has_point(point):
		# Hors du panneau : au sol. C'est le seul moyen de se débarrasser d'un
		# objet, et il se lit tout seul — on l'a sorti du sac.
		drop_requested.emit(_held)
		_held = null
		queue_redraw()
		return
	elif _inventory.place(_held, _cell_at(point) - _grab):
		_held = null
		queue_redraw()
		return

	if drag:
		var reste := _return_held()
		if reste != null:
			drop_requested.emit(reste)
	queue_redraw()


## Porte l'objet tenu, si c'est bien son emplacement. Une épée déposée sur le
## torse est refusée plutôt que rangée d'office dans l'emplacement d'arme : le
## joueur a visé, on ne décide pas à sa place.
func _equip_held(slot: String) -> bool:
	if not EquipmentSlots.accepts(slot, _held) or not _wear(_held, slot):
		return false
	_held = null
	return true


## Rend au sac l'objet tenu à la main, à sa place d'origine si elle est encore
## libre. Renvoie ce qui n'a pas pu rentrer : le sac a pu se remplir pendant
## qu'on le tenait, et un objet ne doit jamais disparaître entre deux mains.
func _return_held() -> Item:
	if _held == null:
		return null
	var item := _held
	_held = null
	if _inventory.place(item, _from) or _inventory.add(item):
		return null
	return item


## Une image toutes les FPS d'animation, déduite de l'horloge plutôt que d'un
## compteur, qui repartirait de zéro à chaque ouverture.
func _process(_delta: float) -> void:
	if not visible:
		return

	# L'état **réel** de la touche, relevé à chaque image, et non un booléen
	# mémorisé sur l'événement : Alt est interceptée par le gestionnaire de
	# fenêtres, et perdre le focus la touche enfoncée ne rend jamais le
	# relâchement — l'infobulle resterait détaillée jusqu'au prochain appui.
	var alt := Input.is_key_pressed(KEY_ALT)
	if alt != _alt:
		_alt = alt
		queue_redraw()

	if _doll_frames == null:
		return
	var i := _doll_frame_index()
	if i != _doll_shown:
		_doll_shown = i
		queue_redraw()


func _doll_frame_index() -> int:
	var n := _doll_frames.get_frame_count(DOLL_ANIM)
	if n <= 1:
		return 0
	var fps := _doll_frames.get_animation_speed(DOLL_ANIM)
	return int(Time.get_ticks_msec() * 0.001 * fps) % n


## Recharge les planches quand la silhouette ou l'arme portée a changé — et
## seulement alors : SpriteForge les met en cache, mais réassigner relancerait
## l'animation à chaque objet ramassé.
func _refresh_doll() -> void:
	if _player == null:
		return
	var variante := _player.sprite.current_variant()
	var arme := _player.weapon_kind()
	var cle := "%d:%s" % [variante, arme]
	if cle == _doll_key:
		return
	_doll_key = cle
	_doll_frames = SpriteForge.frames("player", variante, arme)


func _on_changed() -> void:
	if _inventory != null:
		title.text = Textes.t("SAC  {occupees} / {total} cases").format({
			"occupees": _inventory.used_cells(), "total": _inventory.cell_count()
		})
	# L'arme portée peut avoir changé : la silhouette doit tenir celle qu'on
	# vient d'équiper, sinon la fenêtre montre un personnage qui n'existe plus.
	_refresh_doll()
	if visible:
		queue_redraw()


## Le panneau entier. Sert à savoir si un point est dedans — donc si un objet
## lâché doit tomber au sol.
## **Un clic hors du sac ne lui appartient pas.** Le consommer quand même — ce
## que faisait la première version — rendait sourds tous les autres panneaux
## ouverts en même temps : la fiche de personnage et la page d'un manuel ne
## recevaient plus rien tant que le sac était à l'écran.
##
## L'objet **tenu à la main** fait exception : il possède le geste jusqu'à ce
## qu'on le lâche, y compris au-dehors — c'est comme ça qu'on jette au sol.
func _possede_le_clic(point: Vector2) -> bool:
	return _held != null or _panel_rect().has_point(point)


func _panel_rect() -> Rect2:
	return Rect2(Vector2.ZERO, _panel_size())


## Le plus large des deux : la grille du sac, ou celle du personnage.
func _panel_size() -> Vector2:
	return Vector2(
		maxf(_inventory.cols * (CELL + PAD) + PAD, _equip_size().x + PAD * 2.0),
		_grid_top() + _inventory.rows * (CELL + PAD) + PAD + FOOTER
	)


## Un rectangle de cases, en pixels — la mesure de base de tout le panneau.
func _span_size(span: Vector2i) -> Vector2:
	return Vector2(span) * (CELL + PAD) - Vector2(PAD, PAD)


## Le rectangle d'une zone de la grille du personnage, en pixels du panneau.
## Même pas de grille que le sac : les deux grilles s'alignent à l'œil, et la
## place qu'un objet prend en haut est celle qu'il prendra en bas.
func _doll_rect(zone: Rect2i) -> Rect2:
	return Rect2(
		Vector2(
			_equip_left() + float(zone.position.x) * (CELL + PAD),
			HEADER + PAD + float(zone.position.y) * (CELL + PAD)
		),
		_span_size(zone.size)
	)


## Les deux grilles sont centrées dans le panneau, chacune de son côté : celle
## du personnage est la plus large et fixe donc la largeur de la fenêtre ; le sac,
## plus étroit, serait collé à gauche avec un vide à droite qui se lit comme un
## défaut d'alignement.
##
## Position entière : une grille posée sur un demi-pixel rend ses lignes floues.
func _equip_left() -> float:
	return _centered(_equip_size().x)


func _grid_left() -> float:
	return _centered(_inventory.cols * (CELL + PAD) + PAD)


func _centered(largeur: float) -> float:
	return maxf(floorf((_panel_size().x - largeur) * 0.5), PAD)


func _slot_rect(index: int) -> Rect2:
	return _doll_rect(DOLL[EquipmentSlots.ids()[index]])


## L'objet type d'un emplacement : celui dont on peint la silhouette quand il
## est vide. Pris dans le catalogue, donc jamais réécrit ici — une base ajoutée
## à une famille sans emplacement se verrait aussitôt.
static func _ghost_kind(slot: String) -> String:
	var famille := EquipmentSlots.family_of(slot)
	for base in ItemCatalog.ALL:
		if base.family == famille:
			return base.kind
	return ""


## L'encombrement de la grille du personnage, en pixels.
func _equip_size() -> Vector2:
	return _span_size(Vector2i(DOLL_COLS, DOLL_ROWS))


## Où commence le sac : sous la zone d'équipement.
func _grid_top() -> float:
	return HEADER + _equip_size().y + PAD + 6.0


## Le coin haut-gauche d'un rectangle de cases du sac, en pixels du panneau.
func _rect_of(cell: Vector2i, span: Vector2i) -> Rect2:
	return Rect2(
		Vector2(_grid_left() + cell.x * (CELL + PAD), _grid_top() + PAD + cell.y * (CELL + PAD)),
		_span_size(span)
	)


## La case sous un point. Peut sortir de la grille — c'est voulu : reposer un
## objet à cheval sur le bord doit échouer, pas être rattrapé en douce vers
## l'intérieur.
func _cell_at(point: Vector2) -> Vector2i:
	return Vector2i(
		floori((point.x - _grid_left()) / (CELL + PAD)),
		floori((point.y - _grid_top() - PAD) / (CELL + PAD))
	)


func _slot_at(point: Vector2) -> int:
	for i in EquipmentSlots.count():
		if _slot_rect(i).has_point(point):
			return i
	return -1


func _draw() -> void:
	if _inventory == null:
		return

	var s := _panel_size()
	draw_rect(Rect2(Vector2.ZERO, s), UiPalette.BACK)
	draw_rect(Rect2(Vector2.ZERO, s), UiPalette.BORDER, false, 1.0)

	for y in _inventory.rows:
		for x in _inventory.cols:
			_draw_case(_rect_of(Vector2i(x, y), Vector2i.ONE))

	_draw_doll()
	_draw_equipment()

	var survole := _inventory.index_at(_hover) if _held == null else Inventory.EMPTY
	for p in _inventory.placed:
		_draw_item(p.data, _rect_of(p.cell, p.rect().size), true)
	if survole != Inventory.EMPTY:
		var vise: Inventory.Placed = _inventory.placed[survole]
		var r := _rect_of(vise.cell, vise.rect().size)
		# Le cadre de l'objet survolé passe à sa couleur de rareté pleine, au lieu
		# d'un gris de survol qui l'effacerait justement sur les objets rares.
		draw_rect(r, vise.data.color(), false, 1.0)
		_draw_tooltip(vise.data, r.position.y)

	if _held != null:
		var span := Inventory.footprint(_held)
		var at := _hover - _grab
		# Deux choses à montrer, et il en faut deux : la **destination** calée
		# sur la grille, verte ou rouge — dans un rangement en rectangles c'est
		# la place qu'il prendrait qui compte — et l'**objet**, qui suit le
		# curseur au pixel près pour qu'on sente qu'on le tient.
		if _hover_slot < 0 and _panel_rect().has_point(_mouse):
			draw_rect(_rect_of(at, span), CAN_PLACE if _inventory.fits(_held, at) else BLOCKED)
		_draw_item(_held, Rect2(_mouse - _grab_px, _span_size(span)), false)

	if _font != null:
		draw_string(_font, Vector2(4.0, s.y - 13.0),
			Textes.t("[clic] prendre et poser     [clic droit] équiper / retirer"),
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, UiPalette.HINT)
		draw_string(_font, Vector2(4.0, s.y - 3.0),
			Textes.t("lâché hors du sac : jeté au sol"),
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, UiPalette.HINT)


## Le rectangle du portrait, dans le coin que les emplacements laissent libre.
func _doll_area_rect() -> Rect2:
	return _doll_rect(DOLL_AREA)


## Le personnage tel qu'il est dans le monde : sa silhouette choisie à la
## création, et l'arme qu'il tient réellement. C'est le seul endroit du jeu où
## on le voit en grand, et la seule façon de vérifier d'un coup d'œil que
## l'épée qu'on vient d'équiper est bien celle qu'on porte.
func _draw_doll() -> void:
	var zone := _doll_area_rect()
	_draw_case(zone)
	if _doll_frames == null or not _doll_frames.has_animation(DOLL_ANIM):
		return
	var tex := _doll_frames.get_frame_texture(DOLL_ANIM, _doll_shown)
	if tex == null:
		return
	# À sa taille native : le sprite fait 32 pixels et le portrait 41. L'agrandir
	# le ferait déborder sur le casque et l'arme.
	_draw_centered(tex, zone)


## Les emplacements portés. Ils sont dans le même panneau que le sac et non dans
## une fenêtre à part : équiper est un geste entre les deux, et deux fenêtres
## obligeraient à en ouvrir une seconde pour un aller-retour.
func _draw_equipment() -> void:
	for i in EquipmentSlots.count():
		var slot: String = EquipmentSlots.ids()[i]
		var r := _slot_rect(i)
		var item: Item = _player.equipped(slot) if _player != null else null

		if item != null:
			# Le fond prend la couleur de rareté, très assombrie : c'est la même
			# information que le cadre d'un objet rangé et que le halo au sol, et
			# elle se lit ici sans survoler, d'un bout à l'autre de la fenêtre.
			draw_rect(r, item.color().darkened(0.80))
			draw_rect(r, item.color().darkened(0.35), false, 1.0)
			_draw_item(item, r, false, true)
		else:
			_draw_case(r)
			_draw_ghost(slot, r)

		if _hover_slot != i:
			continue
		if _held != null:
			# Posée **après** l'objet porté : peinte avant, son fond opaque
			# l'effaçait, et un emplacement occupé n'annonçait jamais s'il
			# accepte ce qu'on lui apporte.
			draw_rect(r, CAN_PLACE if EquipmentSlots.accepts(slot, _held) else BLOCKED)
		elif item != null:
			draw_rect(r, item.color(), false, 1.0)
			_draw_tooltip(item, r.position.y)


## La silhouette de ce que l'emplacement attend, presque effacée. Elle remplace
## le nom de l'emplacement : « CEINTURE » tenait dans sa case, « BAGUE G. » non,
## et deux libellés tronqués au même endroit annonçaient deux emplacements
## qu'on ne distinguait plus.
func _draw_ghost(slot: String, r: Rect2) -> void:
	var kind := _ghost_kind(slot)
	if kind.is_empty():
		return
	_draw_centered(SpriteForge.inventory_icon(kind, Vector2i(_place_libre(r))), r, GHOST)


## Le fond d'une case vide : le creux et son liseré. Les deux vont toujours
## ensemble — la grille du sac, le portrait et les emplacements libres les
## écrivaient chacun de leur côté, et il suffisait d'en oublier un pour qu'une
## case se lise comme un trou dans le panneau.
func _draw_case(r: Rect2) -> void:
	draw_rect(r, SLOT)
	draw_rect(r, SLOT_EDGE, false, 1.0)


## La place utile d'un rectangle, marge déduite.
func _place_libre(r: Rect2) -> Vector2:
	return r.size - Vector2(MARGIN, MARGIN) * 2.0


## Une texture au milieu d'un rectangle, à sa taille native. Position entière :
## une image à cheval sur deux pixels bave, et c'est ce que le rendu pixel art ne
## pardonne pas.
func _draw_centered(tex: Texture2D, r: Rect2, teinte := Color.WHITE) -> void:
	if tex == null:
		return
	var at := (r.get_center() - tex.get_size() * 0.5).round()
	draw_texture_rect(tex, Rect2(at, tex.get_size()), false, teinte)


## Ce que porte l'objet, à côté du sac. Sans elle, un objet à six affixes et une
## épée nue se ressemblent.
func _draw_tooltip(item: Item, haut_vise: float) -> void:
	if _font == null:
		return

	var titre := item.display_name()
	# Toujours affiché, même sur un objet blanc : c'est ce qui décide si on le
	# garde. Les paliers, eux, ne sortent que sous Alt.
	var niveau := Textes.t("niveau d'objet %d") % item.item_level
	var implicite := item.implicit_line()

	var explicites := PackedStringArray()
	var paliers := PackedStringArray()
	var detaille := false
	var sans_provenance := false
	for r in item.explicits:
		explicites.append(r.mod.label())
		# Vide quand la provenance est inconnue — un objet d'avant les paliers,
		# ou un affixe retiré du projet depuis. La ligne s'affiche sans colonne.
		var palier := r.palier_et_plage() if _alt else ""
		paliers.append(palier)
		detaille = detaille or not palier.is_empty()
		sans_provenance = sans_provenance or palier.is_empty()

	# Une bulle qui se tait sur un objet dont on vient d'ouvrir le détail se lit
	# comme une panne. Elle dit donc pourquoi — et cette ligne disparaît d'elle
	# même à mesure que le personnage remplace son équipement.
	var note := Textes.t("paliers inconnus : ramassé avant") if _alt and sans_provenance else ""

	# Deux colonnes : les affixes, puis leurs paliers. La gouttière est prise sur
	# la plus large des lignes d'affixes, pas sur chacune — une colonne en
	# escalier ne se lit plus comme une colonne.
	var w_affixes := 0.0
	for ligne in explicites:
		w_affixes = maxf(w_affixes, _font.get_string_size(
			ligne, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x)
	var w_paliers := 0.0
	for ligne in paliers:
		w_paliers = maxf(w_paliers, _font.get_string_size(
			ligne, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x)

	var w := maxf(TIP_MIN_W, _font.get_string_size(
		titre, HORIZONTAL_ALIGNMENT_LEFT, -1.0, TITLE_SIZE).x)
	w = maxf(w, _font.get_string_size(niveau, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x)
	var colonne := w_affixes + (TIP_TIER_GAP + w_paliers if detaille else 0.0)
	w = maxf(w, colonne)
	if not implicite.is_empty():
		w = maxf(w, _font.get_string_size(implicite, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x)
	if not note.is_empty():
		w = maxf(w, _font.get_string_size(note, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x)
	w += TIP_PAD * 2.0

	# Le titre et le niveau, puis une ligne par affixe, plus la note s'il y en a.
	var n := explicites.size() + (1 if not implicite.is_empty() else 0)
	n += 1 if not note.is_empty() else 0
	var h := TIP_PAD * 2.0 + TIP_LINE * 2.0 + float(n) * TIP_LINE
	# Le trait de séparation, quand il y a les deux sortes de lignes à séparer.
	var separe := not implicite.is_empty() and not explicites.is_empty()
	if separe:
		h += TIP_LINE * 0.5

	# Alignée sur le haut de l'objet, mais bornée dans les deux sens : vers le bas
	# parce que les objets de la dernière ligne sortiraient de l'écran, vers la
	# gauche parce que la bulle est dessinée à gauche du panneau et que le mode
	# détaillé l'élargit d'un tiers.
	var s := _panel_size()
	var haut := minf(haut_vise, s.y - h)
	var gauche := maxf(-w - TIP_GAP, -global_position.x)
	var r := Rect2(Vector2(gauche, haut), Vector2(w, h))

	draw_rect(r, UiPalette.TIP_BACK)
	draw_rect(r, item.color(), false, 1.0)

	var y := r.position.y + TIP_PAD + TIP_LINE - 2.0
	draw_string(_font, Vector2(r.position.x + TIP_PAD, y), titre,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, TITLE_SIZE, item.color())
	y += TIP_LINE
	draw_string(_font, Vector2(r.position.x + TIP_PAD, y), niveau,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, TIP_LEVEL)
	if not implicite.is_empty():
		y += TIP_LINE
		draw_string(_font, Vector2(r.position.x + TIP_PAD, y), implicite,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, TIP_IMPLICIT)
	if separe:
		# Ce que la base garantit au-dessus du trait, ce que le tirage a donné
		# en dessous. Sans lui, les deux se lisent comme une seule liste et
		# l'implicite passe pour un affixe de plus.
		y += TIP_LINE * 0.5
		draw_line(
			Vector2(r.position.x + TIP_PAD, y - 2.0),
			Vector2(r.end.x - TIP_PAD, y - 2.0),
			TIP_IMPLICIT * Color(1.0, 1.0, 1.0, 0.5), 1.0
		)
	for i in explicites.size():
		y += TIP_LINE
		draw_string(_font, Vector2(r.position.x + TIP_PAD, y), explicites[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, TIP_EXPLICIT)
		if paliers[i].is_empty():
			continue
		draw_string(
			_font,
			Vector2(r.position.x + TIP_PAD + w_affixes + TIP_TIER_GAP, y), paliers[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, TIP_TIER
		)

	if not note.is_empty():
		y += TIP_LINE
		draw_string(_font, Vector2(r.position.x + TIP_PAD, y), note,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, TIP_LEVEL)


## framed : le cadre de l'objet rangé. L'objet tenu à la main s'en passe — il
## est déjà posé sur la teinte verte ou rouge qui dit s'il peut tomber là.
func _draw_item(item: Item, r: Rect2, framed: bool, fill := false) -> void:
	if framed:
		draw_rect(r, ITEM_BACK)
		draw_rect(r, item.color().darkened(ITEM_EDGE_DIM), false, 1.0)

	# Dans le sac, l'icône est dimensionnée sur l'encombrement de l'objet : c'est
	# lui qui dit la place qu'il prend, et une épée n'a pas à s'étirer sur la
	# case voisine. Dans un emplacement d'équipement (`fill`), elle **remplit sa
	# case** : celle-ci est déjà taillée à la famille de l'objet, et une baguette
	# dessinée petite au milieu d'un grand cadre se lisait comme un oubli.
	#
	# Le facteur d'agrandissement reste entier et l'aspect conservé : la forge
	# s'en charge, aucun objet n'est déformé.
	var place := _place_libre(r)
	var propre := place if fill else _span_size(Inventory.footprint(item)).min(place)
	_draw_centered(
		SpriteForge.inventory_icon(item.base.kind, Vector2i(propre), item.base.palier), r
	)
