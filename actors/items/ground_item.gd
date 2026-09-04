class_name GroundItem
extends Area2D

## Un objet posé au sol, en attente d'être ramassé.
##
## Ramassage au contact, comme dans un ARPG classique : s'arrêter pour appuyer
## sur une touche au milieu d'une mêlée casse le rythme du combat.

## Halo au sol. Sans lui, une icône de 24 px posée sur des tuiles texturées se
## perd complètement — c'est le halo qu'on repère du coin de l'œil, pas l'objet.
##
## Il prend la couleur de rareté : de loin, avant même de distinguer la forme,
## on sait si ça vaut le détour. C'est le seul rôle de la rareté au sol.
const GLOW_ALPHA := 0.34
const GLOW_RX := 9.0
const GLOW_RY := 4.5

## Flottement : c'est ce qui distingue un objet à ramasser d'un détail du décor.
const BOB_SPEED := 3.2
const BOB_AMOUNT := 1.5

## Délai avant qu'un objet jeté depuis le sac puisse être repris. Sans lui, le
## joueur qui jette une épée est déjà dans la zone de ramassage : elle lui
## reviendrait dans le sac à l'image suivante, et le bouton « jeter » ne ferait
## rien de visible.
const DROP_DELAY := 0.6

@onready var icon: Sprite2D = $Icon

var data: Item

## Temps restant avant que le ramassage soit permis. Zéro pour le butin d'un
## ennemi : celui-là, on veut pouvoir le prendre en courant dessus.
var pickup_delay := 0.0

var _t := 0.0
## Hauteur de repos de l'icône, déduite de sa taille : un objet doit se poser
## *sur* son halo, pas dessus. À hauteur fixe, les objets étroits allaient bien
## et un plastron cachait complètement le halo qui sert à le repérer.
var _rest_y := 0.0
var _glow := Color(0.98, 0.86, 0.45, GLOW_ALPHA)

static var _scene: PackedScene


## Pose un objet dans le monde. Statique et sur la classe de l'objet plutôt que
## recopiée chez chaque appelant : l'ennemi qui lâche son butin et le sac qui
## jette une pièce font exactement la même chose, à la position près.
##
## **Entrée dans l'arbre différée.** Un ennemi meurt presque toujours depuis un
## callback de physique — le `area_entered` d'un coup d'épée ou d'un tir — et
## Godot refuse qu'on y ajoute une Area2D : « Can't change this state while
## flushing queries ». La forme de ramassage n'était alors pas initialisée et
## l'objet risquait de rester à jamais impossible à ramasser.
static func spawn(parent: Node, at: Vector2, item: Item, delay := 0.0) -> GroundItem:
	# Chargée à la première pose et non par preload : un script qui préchargerait
	# la scène dont il est lui-même le script forme un cycle de dépendances que
	# Godot refuse.
	if _scene == null:
		_scene = load("res://actors/items/ground_item.tscn")
	var drop: GroundItem = _scene.instantiate()
	# Posées avant l'ajout : _ready en a besoin pour construire l'icône.
	drop.data = item
	drop.pickup_delay = delay
	parent.add_child.call_deferred(drop)
	# Après l'ajout, dans le même ordre que les appels différés : hors de
	# l'arbre, une position globale ne veut rien dire.
	drop.set_deferred("global_position", at)
	return drop


## L'icône se construit ici et non dans une méthode à appeler après coup : le
## nœud entre dans l'arbre en différé, donc l'appelant n'a plus de moment sûr
## pour le faire lui-même.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if data == null:
		return
	icon.texture = SpriteForge.ground_icon(data.base.kind)
	_rest_y = -icon.texture.get_height() * 0.5 - 1.0
	_glow = data.color()
	_glow.a = GLOW_ALPHA


func _process(delta: float) -> void:
	_t += delta * BOB_SPEED
	pickup_delay = maxf(pickup_delay - delta, 0.0)
	# Position entière : un sprite à cheval sur deux pixels bave et trahit le
	# rendu pixel art.
	icon.position.y = roundf(sin(_t) * BOB_AMOUNT + _rest_y)
	queue_redraw()


func _draw() -> void:
	# Un cercle unitaire écrasé par la transformation : c'est le seul moyen de
	# tracer une ellipse sans construire un polygone à la main.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(GLOW_RX, GLOW_RY))
	draw_circle(Vector2.ZERO, 1.0, _glow)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## L'objet ne disparaît que si le sac l'a réellement pris : sac plein, il reste
## au sol. Le joueur devra ressortir de la zone de ramassage et y revenir, ce
## qui est aussi ce qu'on veut après avoir volontairement jeté quelque chose.
func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null or data == null or pickup_delay > 0.0:
		return
	if player.pick_up(data):
		queue_free()
