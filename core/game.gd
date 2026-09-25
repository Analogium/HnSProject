extends Node

## Durée du hit-stop, en secondes réelles. LE réglage du game feel : entre 0.03
## et 0.10 la différence est immédiate. Réglable à chaud depuis l'arène de test.
var hit_stop_duration := 0.05

## Le temps laissé au jeu entre deux gels, en secondes réelles : enchaîné, le gel se
## lit comme du lag. Mesuré sans elle, à trois cents ennemis et compétence tenue :
## **12 % du temps de jeu passé à 2 % de vitesse**, sans qu'une image se perde.
var hit_stop_period := 0.45

## Le zoom de la caméra du joueur : sous 1, plus de terrain à l'écran. 85 %, choisi
## sur capture parmi 100, 85, 75 et 67 (jalon 25).
const WORLD_ZOOM := 0.85


## Une taille de police pour du texte posé dans le monde, qui rétrécit avec lui :
## compensée, elle garde à l'écran la taille d'un zoom de 1. Par la police et non
## par l'échelle du nœud, pour que les cadres mesurés sur le texte suivent.
static func world_font(size: int) -> int:
	return roundi(float(size) / WORLD_ZOOM)


var rng := RandomNumberGenerator.new()

## Le personnage en cours, posé par la sélection et lu par la zone. Null quand une
## scène de réglage est lancée seule : la zone n'écrit alors rien.
var character: Character

## Le niveau de la zone en cours : ses ennemis et son butin. 1 pour l'arène, le banc
## et la galerie.
var zone_level := 1

## Le dernier palier d'affixe ouvre à 57 : au-delà, seuls les ennemis montent.
const MIN_LEVEL := 1
const MAX_LEVEL := 120


## Borné ici et non chez les deux écrans qui l'appellent.
func change_zone_level(delta: int) -> int:
	zone_level = clampi(zone_level + delta, MIN_LEVEL, MAX_LEVEL)
	return zone_level

## Émis à la fermeture, au retour au menu et à la sortie : ceux qui ont quelque chose
## à écrire s'y abonnent.
signal save_requested

## Ce que le joueur vient d'infliger, après mitigation : l'identifiant de la
## compétence (vide sans lancer), et l'état qui brûle ou `HIT` pour un coup.
signal damage_dealt(source: String, kind: int, amount: float)
const HIT := -1

## D'où l'on vient, pour ressortir d'un aperçu par sa touche. Passer par goto_scene().
var previous_scene_path := ""

## Vrai quand un panneau tient la souris : le joueur lit ses touches par sondage, hors
## de l'arbre d'entrées. **En lecture seule** : passer par grab_ui_input().
var ui_grabs_input := false

## Un ensemble et non un booléen : deux panneaux peuvent la tenir ensemble.
var _ui_grabbers := {}

## Le nombre de gels depuis le lancement, pour le banc et les tests.
var freezes := 0

var _hit_stop_active := false
## La fin du dernier gel, sur l'horloge **réelle** : le temps de jeu n'avance presque
## plus pendant un gel. La fin et non la prochaine date permise, pour qu'une période
## changée depuis l'arène se sente au coup suivant.
var _hit_stop_end := 0

## La secousse en cours : un état et non une coroutine par appel, qui se disputaient
## le même `offset`.
var _shake_camera: Camera2D
var _shake_amplitude := 0.0
var _shake_remaining := 0.0
var _shake_duration := 0.0

## Surtout pas `rng` : la secousse est décorative (invariant 3).
var _rng_camera := RandomNumberGenerator.new()


## Dans les deux sens avec le même objet, et **toujours** aussi depuis _exit_tree :
## une scène rechargée panneau ouvert laisserait le joueur incapable de frapper.
func grab_ui_input(source: Object, grabbing: bool) -> void:
	if grabbing:
		_ui_grabbers[source] = true
	else:
		_ui_grabbers.erase(source)
	ui_grabs_input = not _ui_grabbers.is_empty()


func _ready() -> void:
	rng.randomize()
	_rng_camera.randomize()
	# Rien à faire hors secousse.
	set_process(false)
	# Sinon la croix ferme le jeu avant qu'on écrive ; `_notification` quitte ensuite.
	get_tree().auto_accept_quit = false


## La croix ou Alt+F4 : on écrit, puis **on quitte quoi qu'il arrive**.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_requested.emit()
		get_tree().quit()


func goto_scene(path: String) -> void:
	var tree := get_tree()
	if tree.current_scene != null:
		previous_scene_path = tree.current_scene.scene_file_path
	tree.change_scene_to_file(path)


## Passe par goto_scene() : deux appels font un aller-retour.
func go_back(fallback: String = "res://world/zone.tscn") -> void:
	goto_scene(previous_scene_path if previous_scene_path != "" else fallback)


## Fige le jeu brièvement. **Un gel par geste et non par cible** : `hit_stop_period`
## écarte les suivants, l'appelant n'a rien à compter.
func hit_stop(duration: float = -1.0) -> void:
	if _hit_stop_active:
		return
	# La période court depuis la **fin** du gel précédent, pas depuis son début :
	# sinon un gel plus long qu'elle se rendrait la main à lui-même.
	if Time.get_ticks_msec() - _hit_stop_end < roundi(hit_stop_period * 1000.0):
		return
	var d := hit_stop_duration if duration < 0.0 else duration
	if d <= 0.0:
		return
	_hit_stop_active = true
	freezes += 1
	Engine.time_scale = 0.02
	# 4e paramètre = ignore_time_scale, sinon le timer est figé lui aussi
	await get_tree().create_timer(d, true, false, true).timeout
	Engine.time_scale = 1.0
	_hit_stop_end = Time.get_ticks_msec()
	_hit_stop_active = false


## Relancée, elle reprend la plus forte amplitude au lieu d'en ajouter une.
func shake_camera(camera: Camera2D, amount: float = 3.0, duration: float = 0.15) -> void:
	if camera == null or amount <= 0.0 or duration <= 0.0:
		return
	if camera != _shake_camera:
		_settle_camera()
		_shake_camera = camera
	_shake_amplitude = maxf(_shake_amplitude, amount)
	_shake_remaining = maxf(_shake_remaining, duration)
	_shake_duration = maxf(_shake_duration, _shake_remaining)
	set_process(true)


## Delta non dé-scalé : la secousse se fige avec le jeu pendant un gel.
func _process(delta: float) -> void:
	if not is_instance_valid(_shake_camera):
		_settle_camera()
		return
	_shake_remaining = maxf(_shake_remaining - delta, 0.0)
	if _shake_remaining <= 0.0:
		_settle_camera()
		return
	var falloff := _shake_remaining / _shake_duration
	_shake_camera.offset = Vector2(
		_rng_camera.randf_range(-_shake_amplitude, _shake_amplitude),
		_rng_camera.randf_range(-_shake_amplitude, _shake_amplitude)
	) * falloff


func _settle_camera() -> void:
	if is_instance_valid(_shake_camera):
		_shake_camera.offset = Vector2.ZERO
	_shake_camera = null
	_shake_amplitude = 0.0
	_shake_remaining = 0.0
	_shake_duration = 0.0
	set_process(false)
