class_name OrbeDExperience
extends Area2D

## Une boule d'expérience posée au sol par l'établi, ramassée au contact.
##
## **Outil de réglage**, comme l'établi qui la lâche : aucun ennemi n'en laisse. Elle
## récompense pourtant par le chemin d'une mort, `Player.recompenser()` — le retard
## sur la zone la fait fondre et les manuels à l'étude apprennent avec le joueur —,
## pour que monter par l'établi reste monter comme en jeu.

## Ce qu'une boule vaut, en grunts de la zone : l'ennemi le plus commun, donc l'unité
## qu'on a en tête quand on joue. Cinq, pour qu'un clic sur « ×10 » fasse un vrai
## bond sans qu'il faille en ramasser cent.
const ORBE_EN_GRUNTS := 5
const GRUNT := preload("res://resources/stats/grunt_stats.tres")
const RAYON_DE_RAMASSAGE := 8.0
## Layer 2, « player_body » : seul le joueur la ramasse.
const CORPS_DU_JOUEUR := 1 << 1
## Le bleu du « +N exp » flottant : la boule annonce ce qu'elle donnera.
const COULEUR := HitFeedback.XP
const REFLET := Color(1.0, 1.0, 1.0, 0.9)
const HAUTEUR := 5.0

var valeur := 0.0
var niveau := 1
var _t := 0.0


## Ce que vaut une boule dans une zone de ce niveau, avant le retard du joueur.
static func valeur_pour(niveau_zone: int) -> float:
	var fiche: CharacterStats = GRUNT.duplicate()
	CharacterStats.mettre_a_l_echelle(fiche, niveau_zone)
	return Enemy.xp_de_la_sante(fiche.max_health) * float(ORBE_EN_GRUNTS)


## Entrée dans l'arbre différée, comme `GroundItem.spawn()` : la position globale
## s'applique après l'ajout, dans l'ordre des appels différés.
static func poser(parent: Node, at: Vector2, p_valeur: float, p_niveau: int) -> OrbeDExperience:
	var orbe := OrbeDExperience.new()
	orbe.valeur = p_valeur
	orbe.niveau = p_niveau
	orbe.collision_layer = 0
	orbe.collision_mask = CORPS_DU_JOUEUR
	var forme := CollisionShape2D.new()
	var cercle := CircleShape2D.new()
	cercle.radius = RAYON_DE_RAMASSAGE
	forme.shape = cercle
	orbe.add_child(forme)
	parent.add_child.call_deferred(orbe)
	orbe.set_deferred("global_position", at)
	return orbe


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Déphasées : dix boules qui flottent à l'unisson se lisent comme un seul objet.
	_t = float(get_instance_id() % 97) * 0.1


func _process(delta: float) -> void:
	_t += delta * GroundItem.BOB_SPEED
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(GroundItem.GLOW_RX, GroundItem.GLOW_RY))
	draw_circle(Vector2.ZERO, 1.0, Color(COULEUR, GroundItem.GLOW_ALPHA))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var centre := Vector2(0.0, roundf(-HAUTEUR + sin(_t) * GroundItem.BOB_AMOUNT))
	draw_circle(centre, 4.5, Color(COULEUR, 0.35))
	draw_circle(centre, 3.0, COULEUR)
	draw_circle(centre + Vector2(-1.0, -1.0), 1.0, REFLET)


func _on_body_entered(body: Node2D) -> void:
	var joueur := body as Player
	if joueur == null or is_queued_for_deletion():
		return
	joueur.recompenser(valeur, niveau, global_position)
	queue_free()
