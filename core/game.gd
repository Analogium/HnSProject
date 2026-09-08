extends Node

## Durée du hit-stop, en secondes réelles. C'est LE réglage du game feel :
## teste entre 0.03 et 0.10, tu sentiras la différence immédiatement.
## Réglable à chaud depuis l'arène de test.
var hit_stop_duration := 0.05

var rng := RandomNumberGenerator.new()

## Le personnage en cours de partie, posé par l'écran de sélection et lu par la
## zone. Null quand on lance une scène de réglage directement depuis l'éditeur :
## la zone repart alors des valeurs par défaut du joueur, et n'écrit rien.
##
## Sur l'autoload parce qu'il doit survivre au changement de scène — c'est
## exactement ce qu'un changement de scène détruit.
var personnage: Personnage

## Le niveau de la zone en cours : celui de ses ennemis, et celui des objets qui
## y tombent. Sur l'autoload pour la même raison que `personnage` — il doit
## survivre au changement de scène, et c'est l'écran de réglage de génération qui
## le pose avant d'entrer dans la zone.
##
## 1 par défaut, et les scènes de réglage n'y touchent pas : l'arène, le banc de
## stress et la galerie n'ont pas de niveau et n'ont rien à en savoir.
var niveau_de_zone := 1

## Les bornes du niveau. Soixante parce que c'est là que s'arrêtent les échelles
## d'affixes : au-delà, plus rien ne s'ouvrirait et le danger monterait sans que
## la récompense suive.
const NIVEAU_MIN := 1
const NIVEAU_MAX := 60


## Monte ou descend le niveau des zones à venir, et rend la valeur obtenue.
##
## Ici et non chez les deux écrans qui l'appellent : ils bornaient chacun de leur
## côté, et le jour où le maximum bougera, celui qui l'aurait oublié laisserait
## engendrer une zone dont aucun affixe ne suit.
func changer_niveau_de_zone(delta: int) -> int:
	niveau_de_zone = clampi(niveau_de_zone + delta, NIVEAU_MIN, NIVEAU_MAX)
	return niveau_de_zone

## « Quelqu'un s'apprête à partir, écris maintenant. » Émis à la fermeture de la
## fenêtre, au retour au menu et à la sortie du jeu.
##
## Un signal et non un appel direct : l'autoload n'a aucune raison de connaître
## la zone, ni le joueur, ni quel nœud tient l'état à écrire. Ceux qui ont
## quelque chose à sauvegarder s'y abonnent.
signal sauvegarde_demandee

## Scène d'où l'on vient, pour pouvoir ressortir d'un aperçu par la touche qui
## l'a ouvert. Passer par goto_scene() plutôt que par change_scene_to_file()
## directement, sinon l'historique se désynchronise.
var previous_scene_path := ""

## Vrai quand une fenêtre d'interface s'est emparée de la souris. Un drapeau
## global parce que le joueur lit ses attaques par sondage
## (Input.is_action_just_pressed) dans _physics_process : ces lectures ne passent
## pas par l'arbre d'entrées, donc aucune fenêtre ne peut les intercepter en
## consommant l'événement.
##
## **En lecture seule.** Passer par grab_ui_input() pour le modifier.
var ui_grabs_input := false

## Qui réclame la souris. Un ensemble et non un simple booléen : le sac et la
## fiche de personnage peuvent être ouverts en même temps, et le premier des deux
## à se fermer remettrait le drapeau à faux alors que l'autre tient encore la
## souris — le joueur se retrouverait à frapper en cliquant dans un panneau.
var _ui_grabbers := {}


## Déclare qu'un panneau prend la souris, ou qu'il la rend. À appeler avec le
## même objet dans les deux sens, et **toujours** depuis _exit_tree en plus de la
## fermeture : une scène rechargée panneau ouvert laisserait sinon le joueur
## incapable de frapper dans une scène où plus aucun panneau n'existe.
func grab_ui_input(source: Object, grabbing: bool) -> void:
	if grabbing:
		_ui_grabbers[source] = true
	else:
		_ui_grabbers.erase(source)
	ui_grabs_input = not _ui_grabbers.is_empty()

var _hit_stop_active := false


func _ready() -> void:
	rng.randomize()
	# Sinon la croix de la fenêtre ferme le jeu sans que personne ait pu écrire.
	# Le pendant obligatoire est _notification : sans lui la fenêtre ne se
	# fermerait plus du tout.
	get_tree().auto_accept_quit = false


## La fermeture par la croix ou par Alt+F4. On laisse une dernière chance
## d'écrire, puis **on quitte quoi qu'il arrive** : un abonné en erreur ne doit
## pas transformer la fenêtre en piège.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		sauvegarde_demandee.emit()
		get_tree().quit()


func goto_scene(path: String) -> void:
	var tree := get_tree()
	if tree.current_scene != null:
		previous_scene_path = tree.current_scene.scene_file_path
	tree.change_scene_to_file(path)


## Revient d'où l'on venait. Comme go_back() passe elle-même par goto_scene(),
## deux appels successifs font un aller-retour : la touche qui ouvre un aperçu
## peut donc aussi le refermer.
func go_back(fallback: String = "res://world/zone.tscn") -> void:
	goto_scene(previous_scene_path if previous_scene_path != "" else fallback)


## Fige le jeu très brièvement à l'impact.
func hit_stop(duration: float = -1.0) -> void:
	if _hit_stop_active:
		return
	var d := hit_stop_duration if duration < 0.0 else duration
	if d <= 0.0:
		return
	_hit_stop_active = true
	Engine.time_scale = 0.02
	# 4e paramètre = ignore_time_scale, sinon le timer est figé lui aussi
	await get_tree().create_timer(d, true, false, true).timeout
	Engine.time_scale = 1.0
	_hit_stop_active = false


func shake_camera(camera: Camera2D, amount: float = 3.0, duration: float = 0.15) -> void:
	var elapsed := 0.0
	while elapsed < duration:
		var falloff := 1.0 - (elapsed / duration)
		camera.offset = Vector2(
			rng.randf_range(-amount, amount),
			rng.randf_range(-amount, amount)
		) * falloff
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	camera.offset = Vector2.ZERO
