class_name GroundItem
extends Area2D

## Un objet posé au sol, en attente d'être ramassé.
##
## Ramassage au contact, comme dans un ARPG classique : s'arrêter pour appuyer
## sur une touche au milieu d'une mêlée casse le rythme du combat.

## Halo au sol. Sans lui, une icône de 24 px posée sur des tuiles texturées se
## perd complètement — c'est le halo qu'on repère du coin de l'œil, pas l'objet.
const GLOW := Color(0.98, 0.86, 0.45, 0.30)
const GLOW_RX := 9.0
const GLOW_RY := 4.5

## Flottement : c'est ce qui distingue un objet à ramasser d'un détail du décor.
const BOB_SPEED := 3.2
const BOB_AMOUNT := 1.5

@onready var icon: Sprite2D = $Icon

var data: ItemData

var _t := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


## À appeler après add_child : l'icône est un nœud enfant, elle n'existe pas
## avant l'entrée dans l'arbre.
func setup(item: ItemData) -> void:
	data = item
	icon.texture = SpriteForge.weapon_icon(item.kind)


func _process(delta: float) -> void:
	_t += delta * BOB_SPEED
	# Position entière : un sprite à cheval sur deux pixels bave et trahit le
	# rendu pixel art.
	icon.position.y = roundf(sin(_t) * BOB_AMOUNT) - 4.0
	queue_redraw()


func _draw() -> void:
	# Un cercle unitaire écrasé par la transformation : c'est le seul moyen de
	# tracer une ellipse sans construire un polygone à la main.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(GLOW_RX, GLOW_RY))
	draw_circle(Vector2.ZERO, 1.0, GLOW)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null or data == null:
		return
	player.pick_up(data)
	queue_free()
