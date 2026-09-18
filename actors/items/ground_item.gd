class_name GroundItem
extends Node2D

## Un objet posé au sol, sous son nom : l'étiquette **est** le bouton, on ramasse
## en cliquant dessus. Au contact, le sac avalait ce qu'on traversait ; depuis que
## les noms se composent, ce qu'on ramasse se lit d'abord et se choisit ensuite.

## Halo au sol. Sans lui, une icône de 14 px posée sur des tuiles texturées se
## perd — c'est le halo qu'on repère du coin de l'œil, pas l'objet. Il prend la
## couleur de rareté : de loin, on sait si ça vaut le détour.
##
## Taillé sur l'icône (`SpriteForge.GROUND`), les boules d'expérience compris : plus
## large qu'elle, il se lit comme une flaque et on ne voit plus ce qui est posé
## dessus.
const GLOW_ALPHA := 0.34
const GLOW_RX := 7.0
const GLOW_RY := 3.5

## Flottement : c'est ce qui distingue un objet à ramasser d'un détail du décor.
const BOB_SPEED := 3.2
const BOB_AMOUNT := 1.5

## L'étiquette, en pixels de la fenêtre de jeu (640×360). Un cran sous les gains
## d'expérience, et serrée : c'est elle qu'on voit avant l'objet, et six chutes
## côte à côte remplissent vite l'écran. La hauteur du cadre vient de l'interligne
## de la police, d'où la marge verticale nulle.
const NAME_SIZE := 7
const NAME_PAD := Vector2(2.0, 0.0)
## Ce qui sépare le bas de l'étiquette du haut de la plus grande icône possible.
## Au-dessus de `SpriteForge.GROUND` et non de l'icône réelle : à hauteur propre,
## deux étiquettes voisines ne s'alignent plus, et le flottement les ferait danser.
const NAME_GAP := 3.0

## Le fond de l'étiquette, et ce qu'il devient sous la souris : c'est le seul signe
## qu'elle se clique.
const NAME_BACK := Color(0.055, 0.051, 0.075, 0.90)
const NAME_HOVER := Color(0.16, 0.15, 0.20, 0.95)

@onready var icon: Sprite2D = $Icon

var data: Item
## Celui qui ramasse. Passé à la pose, les deux appelants l'ayant sous la main :
## rien dans l'arbre ne mène au joueur, et un groupe pour un seul nœud mentirait.
var taker: Player

var _t := 0.0
## Hauteur de repos de l'icône, déduite de sa taille : à hauteur fixe, un plastron
## cache complètement le halo qui sert à le repérer.
var _rest_y := 0.0
var _glow := Color(0.98, 0.86, 0.45, GLOW_ALPHA)

var _font: Font
var _name := ""
## L'étiquette à sa place naturelle, en coordonnées locales, mesurée une fois : la
## mesurer à chaque image ferait relire une police pour un texte qui ne change pas.
var _label := Rect2()
## Où elle se dessine vraiment, une fois montée pour ne recouvrir personne. Égale à
## `_label` tant qu'aucune autre ne la gêne.
var _shown := Rect2()
## La position qui a servi au dernier rangement. La position arrive **après**
## `_ready` (`DeferredTree`), donc c'est elle, et non un drapeau posé à la pose, qui
## dit que le rangement est à refaire.
var _laid_at := Vector2(NAN, NAN)
var _hovered := false

static var _scene: PackedScene

## Tous ceux qui sont au sol, pour ranger leurs étiquettes ensemble. Une liste
## statique plutôt qu'un script sur le nœud parent : l'ennemi et le sac posent dans
## deux parents différents, et une règle par parent finirait par diverger.
static var _all: Array[GroundItem] = []
static var _dirty := false

## Les noms au sol s'affichent-ils ? Éteints, plus rien ne se ramasse : l'étiquette
## **est** le bouton. En lecture seule, passer par `show_labels()`.
static var labels_shown := true

## L'objet dont l'étiquette est sous le curseur, ou null.
static var hovered: GroundItem = null


## Pose un objet dans le monde : l'ennemi qui lâche son butin et le sac qui jette
## une pièce font la même chose, à la position près.
##
## **Entrée dans l'arbre différée.** Un ennemi meurt presque toujours depuis un
## callback de physique — le `area_entered` d'un coup d'épée ou d'un tir — et un
## nœud posé là arrive dans un arbre que Godot est en train de parcourir. Le
## différé porte aussi le garde-fou du parent libéré (invariant 4).
static func spawn(parent: Node, at: Vector2, item: Item, player: Player) -> GroundItem:
	# Chargée à la première pose et non par preload : un script qui préchargerait
	# la scène dont il est lui-même le script forme un cycle de dépendances que
	# Godot refuse.
	if _scene == null:
		_scene = load("res://actors/items/ground_item.tscn")
	var drop: GroundItem = _scene.instantiate()
	# Posées avant l'ajout : _ready en a besoin pour construire l'icône.
	drop.data = item
	drop.taker = player
	DeferredTree.add_deferred(parent, drop, at)
	return drop


## Éteint puis rallume les noms au sol. Le rallumage range à nouveau, **depuis la
## position du joueur à cet instant** : c'est ce qui démêle une pile qui débordait du
## haut de l'écran, une fois qu'on s'est décalé.
static func show_labels(on: bool) -> void:
	labels_shown = on
	_dirty = true
	for one in _all:
		if is_instance_valid(one):
			one.queue_redraw()


## L'icône se construit ici et non dans une méthode à appeler après coup : le nœud
## entre dans l'arbre en différé, donc l'appelant n'a plus de moment sûr.
func _ready() -> void:
	if data == null:
		return
	_font = ThemeDB.fallback_font
	icon.texture = SpriteForge.ground_icon(data.base)
	_rest_y = -icon.texture.get_height() * 0.5 - 1.0
	_glow = data.color()
	_glow.a = GLOW_ALPHA
	_measure()
	_all.append(self)
	_dirty = true


## Le nom est traduit : il se remesure quand la langue change, comme les panneaux.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and data != null:
		_measure()


## Le survol lâché à la sortie de l'arbre, **toujours** : ramassé sous le curseur,
## l'objet retiendrait à jamais le clic gauche du joueur.
func _exit_tree() -> void:
	if hovered == self:
		hovered = null
	_all.erase(self)
	_dirty = true


func _process(delta: float) -> void:
	_t += delta * BOB_SPEED
	# Position entière : un sprite à cheval sur deux pixels bave et trahit le
	# rendu pixel art.
	icon.position.y = roundf(sin(_t) * BOB_AMOUNT + _rest_y)

	# Posé, ou déplacé par une zone qui se régénère : les étiquettes se rangent.
	if _laid_at != global_position:
		_dirty = true
	# Rien à ranger tant qu'elles sont éteintes : le rangement attend le rallumage,
	# et c'est bien pour ça qu'il s'y produit.
	if _dirty and labels_shown:
		_relayout()

	_hovered = labels_shown and _shown.has_point(to_local(get_global_mouse_position()))
	if _hovered:
		hovered = self
	elif hovered == self:
		hovered = null
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	# La position de l'événement, et non celle de la souris : c'est elle qui décide
	# du clic, et elle seule se rejoue.
	if clicked(get_viewport().get_canvas_transform().affine_inverse() * click.position):
		get_viewport().set_input_as_handled()


## Un clic dans le monde : vrai s'il a pris l'objet. **Le seul chemin du
## ramassage** — la souris n'est qu'un moyen d'y arriver, et les tests n'en ont pas.
##
## L'objet ne disparaît que si le sac l'a réellement pris : sac plein, il reste au
## sol et son nom reste cliquable.
func clicked(world_point: Vector2) -> bool:
	if data == null or taker == null or not labels_shown:
		return false
	if not name_rect().has_point(world_point):
		return false
	if not taker.pick_up(data):
		return false
	queue_free()
	return true


## Ce clic-là ramasse, il ne lance pas : le joueur sonde ses touches hors de l'arbre
## d'entrées, donc sans ce refus il attaquerait à chaque objet ramassé. **Le clic
## gauche seulement** — un curseur posé sur un nom n'a jamais empêché de lancer un
## sort, et le test de `hovered` passe en premier pour ne rien lire le reste du temps.
static func takes_the_click(action: String) -> bool:
	return hovered != null and Keybinds.uses_left_click(action)


## L'étiquette dans le monde, telle qu'elle se dessine — montée comprise : c'est
## elle qui reçoit le clic, pas la place naturelle. L'icône ne répond pas, elle
## danse, et une cible qui bouge se rate.
func name_rect() -> Rect2:
	return Rect2(global_position + _shown.position, _shown.size)


func _draw() -> void:
	# Un cercle unitaire écrasé par la transformation : c'est le seul moyen de
	# tracer une ellipse sans construire un polygone à la main.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(GLOW_RX, GLOW_RY))
	draw_circle(Vector2.ZERO, 1.0, _glow)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if _font == null or _name.is_empty() or not labels_shown:
		return
	var tint := data.color()
	draw_rect(_shown, NAME_HOVER if _hovered else NAME_BACK)
	draw_rect(_shown, tint, false, 1.0)
	# La ligne de base, et non le haut du cadre : `draw_string` pose le texte dessus.
	var baseline := _shown.position + Vector2(NAME_PAD.x, NAME_PAD.y + _font.get_ascent(NAME_SIZE))
	draw_string(_font, baseline, _name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, NAME_SIZE, tint)


## Le nom et son cadre, centré sur l'objet, à sa place naturelle. C'est
## `_relayout()` qui décide ensuite de là où il tient.
func _measure() -> void:
	_name = data.display_name()
	var size := _font.get_string_size(_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, NAME_SIZE)
	size = (size + NAME_PAD * 2.0).round()
	var top := -(float(SpriteForge.GROUND.y) + NAME_GAP) - size.y
	_label = Rect2(Vector2(roundf(-size.x * 0.5), top), size)
	_shown = _label
	_dirty = true
	queue_redraw()


## Range les étiquettes pour qu'aucune n'en recouvre une autre : chacune part de sa
## place et **monte** jusqu'à trouver de l'air, comme dans PoE. Sans ça, un paquet
## mort au même endroit donne une bouillie de cadres, et on ne sait plus lequel on
## clique.
##
## Du bas vers le haut : l'objet le plus proche du joueur garde sa place, les autres
## montent. L'inverse ferait grimper toute la pile pour un seul objet en bas.
static func _relayout() -> void:
	_dirty = false
	var live: Array[GroundItem] = []
	for one in _all:
		if is_instance_valid(one) and one.is_inside_tree():
			live.append(one)
	_all = live
	# L'abscisse départage : à ordonnée égale, un ordre stable évite que deux
	# étiquettes échangent leur place d'une image à l'autre.
	live.sort_custom(func(a: GroundItem, b: GroundItem) -> bool:
		if is_equal_approx(a.global_position.y, b.global_position.y):
			return a.global_position.x < b.global_position.x
		return a.global_position.y > b.global_position.y
	)

	var ceiling := _visible_top(live)
	var taken: Array[Rect2] = []
	for one in live:
		one._laid_at = one.global_position
		var r := Rect2(one.global_position + one._label.position, one._label.size)
		# Chaque tour passe au-dessus de la plus haute gêne, donc en libère au moins
		# une : autant de tours que de voisines déjà posées suffit toujours.
		for _guard in taken.size():
			var blocker := _highest_blocker(taken, r)
			if is_nan(blocker):
				break
			# Une image de marge : deux cadres qui se touchent se lisent comme un seul.
			var lifted := blocker - r.size.y - 1.0
			if lifted < ceiling:
				# Une pile plus haute que l'écran : le reste se superpose en haut
				# plutôt que d'en sortir, où plus rien ne se cliquerait. Ramasser
				# celui du dessus rend sa place au suivant.
				r.position.y = ceiling
				break
			r.position.y = lifted
		taken.append(r)
		one._shown = Rect2(r.position - one.global_position, r.size)
		one.queue_redraw()


## Le haut de ce qui est à l'écran, en coordonnées du monde ; `-INF` hors de l'arbre.
## C'est la borne du rangement : une étiquette poussée plus haut sortirait du cadre.
static func _visible_top(live: Array[GroundItem]) -> float:
	if live.is_empty():
		return -INF
	var view := live[0].get_viewport()
	return (view.get_canvas_transform().affine_inverse() * Vector2.ZERO).y + 1.0


## Le haut de la plus haute étiquette que celle-ci rencontre, ou NAN si la place est
## libre. NAN et non zéro : zéro est une ordonnée comme une autre.
static func _highest_blocker(taken: Array[Rect2], r: Rect2) -> float:
	var top := NAN
	for other in taken:
		if not other.intersects(r):
			continue
		if is_nan(top) or other.position.y < top:
			top = other.position.y
	return top
