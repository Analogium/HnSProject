class_name ExperienceOrb
extends Area2D

## Une boule d'expérience posée au sol par l'établi, ramassée au contact.
##
## **Outil de réglage**, comme l'établi qui la lâche : aucun ennemi n'en laisse. Elle
## récompense pourtant par le chemin d'une mort, `Player.reward()` — le retard
## sur la zone la fait fondre et les manuels à l'étude apprennent avec le joueur —,
## pour que monter par l'établi reste monter comme en jeu.

## Ce qu'une boule vaut, en grunts de la zone : l'ennemi le plus commun, donc l'unité
## qu'on a en tête quand on joue. Cinq, pour qu'un clic sur « ×10 » fasse un vrai
## bond sans qu'il faille en ramasser cent.
const ORB_IN_GRUNTS := 5
const GRUNT := preload("res://resources/stats/grunt_stats.tres")
const PICKUP_RADIUS := 8.0
## Layer 2, « player_body » : seul le joueur la ramasse.
const PLAYER_BODY := 1 << 1
## Le bleu du « +N exp » flottant : la boule annonce ce qu'elle donnera.
const COLOR := HitFeedback.XP
const GLINT := Color(1.0, 1.0, 1.0, 0.9)
const HEIGHT := 5.0

var value := 0.0
var level := 1
var _t := 0.0


## Ce que vaut une boule dans une zone de ce niveau, avant le retard du joueur.
static func value_for(zone_level_value: int) -> float:
	var sheet: CharacterStats = GRUNT.duplicate()
	CharacterStats.scale_to_level(sheet, zone_level_value)
	return Enemy.xp_from_health(sheet.max_health) * float(ORB_IN_GRUNTS)


## Entrée dans l'arbre différée, comme `GroundItem.spawn()`.
static func put(parent: Node, at: Vector2, p_value: float, p_level: int) -> ExperienceOrb:
	var orb := ExperienceOrb.new()
	orb.value = p_value
	orb.level = p_level
	orb.collision_layer = 0
	orb.collision_mask = PLAYER_BODY
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PICKUP_RADIUS
	shape.shape = circle
	orb.add_child(shape)
	DeferredTree.add_deferred(parent, orb, at)
	return orb


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Déphasées : dix boules qui flottent à l'unisson se lisent comme un seul objet.
	_t = float(get_instance_id() % 97) * 0.1


func _process(delta: float) -> void:
	_t += delta * GroundItem.BOB_SPEED
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(GroundItem.GLOW_RX, GroundItem.GLOW_RY))
	draw_circle(Vector2.ZERO, 1.0, Color(COLOR, GroundItem.GLOW_ALPHA))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var center := Vector2(0.0, roundf(-HEIGHT + sin(_t) * GroundItem.BOB_AMOUNT))
	draw_circle(center, 4.5, Color(COLOR, 0.35))
	draw_circle(center, 3.0, COLOR)
	draw_circle(center + Vector2(-1.0, -1.0), 1.0, GLINT)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null or is_queued_for_deletion():
		return
	player.reward(value, level, global_position)
	queue_free()
