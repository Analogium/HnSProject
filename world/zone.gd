extends Node2D

## L'assemblage de l'étape 9 : la carte générée devient praticable.
## Deux TileMapLayer partagent le même TileSet — seule la tuile de mur porte
## une collision, donc le layer de sol ne bloque rien.
##
## Le WallLayer et le conteneur d'entités sont Y-sortés ensemble, sinon les
## personnages passeraient devant et derrière les murs de façon incohérente.

const GRUNT_SCENE := preload("res://actors/enemies/grunt.tscn")
const CASTER_SCENE := preload("res://actors/enemies/caster.tscn")
const DUMMY_SCENE := preload("res://actors/dummy/training_dummy.tscn")
const GRUNT_STATS := preload("res://resources/stats/grunt_stats.tres")

## Paquet manuel autour du joueur (touche G). Ce n'est plus le peuplement de la
## zone — c'est l'EnemySpawner qui s'en charge — mais un outil de test, pour
## provoquer une mêlée sur commande sans traverser la carte.
const PACK_GRUNTS := 4
const PACK_CASTERS := 1
const PACK_RADIUS_TILES := 6
const PACK_MIN_TILES := 3

## Le décor du biome, semé par case (jalon 33). Les arbres poussent sur le bord sud
## des murs, où l'on ne marche jamais : ils ne portent pas de collision, et le
## champ de flux n'a pas à les connaître. Buissons et rochers se traversent.
const TREES: Array[Texture2D] = [preload("res://art/decor/tree_a.png"), preload("res://art/decor/tree_b.png")]
const BUSH := preload("res://art/decor/bush.png")
const ROCK := preload("res://art/decor/rock.png")
## Par case de bord de mur, puis par case de sol : 7 buissons et 3 rochers pour
## 225 cases sur la planche.
const TREE_CHANCE := 0.15
const BUSH_CHANCE := 0.03
const ROCK_CHANCE := 0.013
## Assez pour casser l'alignement sur la grille, pas assez pour qu'un rocher
## déborde sur un mur.
const DECOR_JITTER := 8.0

@onready var floor_layer: TileMapLayer = $FloorLayer
## Ce qu'on voit au-delà de la carte : la route touche les bords, et la caméra
## montrait là le gris du fond.
@onready var beyond: ColorRect = $Beyond
@onready var wall_layer: TileMapLayer = $Entities/WallLayer
@onready var player: Player = $Entities/Player
@onready var enemy_manager: EnemyManager = $Entities/EnemyManager
@onready var projectiles: Node2D = $Entities/Projectiles
@onready var zone_loot: Node2D = $Entities/Loot
@onready var town_loot: Node2D = $Entities/Town/Loot
@onready var ground: Node2D = $Ground
@onready var decor: Node2D = $Entities/Decor
@onready var overlay: Label = $UI/Overlay
@onready var map_overlay: MapOverlay = $UI/MapOverlay
@onready var hud: Hud = $UI/Hud
@onready var inventory: InventoryPanel = $UI/Inventory
@onready var stats_panel: StatsPanel = $UI/Stats
@onready var manuals: ManualPanel = $UI/Manuals
@onready var passive_tree: PassiveTreePanel = $UI/PassiveTree
@onready var bar: SkillBarPanel = $UI/Bar
@onready var flasks: FlaskBar = $UI/Flasks
## Outil de réglage, à retirer avant publication : il tient en trois
## attaches — ce nœud, la touche B, et le branchement de `drop_requested`.
@onready var workbench: WorkbenchPanel = $UI/Workbench
@onready var spawner: EnemySpawner = $EnemySpawner
@onready var indicator: Label = $UI/Indicator
@onready var town: Node2D = $Entities/Town
@onready var merchant: Interactable = $Entities/Town/Merchant
@onready var stash_chest: Interactable = $Entities/Town/Stash
@onready var town_gate: Interactable = $Entities/Town/Gate
## Le portail de la ville qui ramène dans la zone quittée ; là seulement quand il y en a une.
@onready var way_back: Interactable = $Entities/Town/WayBack
## Le portail qu'on ouvre hors de la ville : un seul, déplacé à chaque ouverture.
@onready var portal: Interactable = $Entities/Portal
@onready var town_waypoint: Interactable = $Entities/Town/Waypoint
@onready var trainer: Interactable = $Entities/Town/Trainer
@onready var dummies: Node2D = $Entities/Town/Dummies
## Ce que chaque zone pose sur sa route : son waypoint, et le passage vers la suivante.
@onready var area_marks: Node2D = $Entities/Area
@onready var area_waypoint: Interactable = $Entities/Area/Waypoint
@onready var area_exit: Interactable = $Entities/Area/Exit

## À quelle distance devant soi tombe ce qu'on pose au sol. Posé au centre, un
## objet serait à moitié caché par le personnage ; plus loin, il franchirait un
## mur collé au dos du joueur. Le manuel de départ et ce qu'on jette du sac
## partagent ce chiffre — deux distances réglées séparément se mettraient à
## répondre différemment au même geste.
const AT_THE_FEET := 14.0
## Le rayon intérieur de la couronne de boules d'expérience : hors de portée de
## ramassage, qui est de quinze pixels du centre du joueur.
const ORB_CROWN := 26.0

## Filet de sécurité, en secondes. Ni à chaque changement — ramasser un objet
## écrirait sur le disque à chaque grappe d'ennemis tués — ni seulement à la
## fermeture, ce qui perdrait la session entière sur une coupure de courant.
const SAVE_PERIOD := 120.0

## La ville, en cases, bordure comprise : tout s'y voit d'un écran au zoom du jeu.
const TOWN_SIZE := Vector2i(24, 16)
## On arrive au milieu (`MapGenerator.get_spawn_cell()`) ; le marchand à gauche, le
## coffre à droite, le portail vers la zone au-dessus.
const MERCHANT_CELL := Vector2i(7, 7)
const STASH_CELL := Vector2i(16, 7)
const GATE_CELL := Vector2i(12, 4)
## Sous le point d'arrivée : on ressort de la ville par où l'on y est entré.
const WAY_BACK_CELL := Vector2i(12, 11)
## Le sol de la ville est tiré sur cette graine : la même salle à chaque visite.
const TOWN_SEED := 1
## Assez loin devant soi pour que le portail ouvert ne se cache pas sous le joueur.
const PORTAL_AHEAD := 28.0

## Les lieux du biome, dans l'ordre de la route (jalon 33) : la ville, puis trois
## zones qu'on traverse de l'entrée à la sortie. Le rang est ce que le personnage
## garde de ses waypoints ; la dernière zone n'a pas de sortie.
const AREAS := ["Ville", "Friches brûlées", "Val calciné", "Lande morte"]
const TOWN_WAYPOINT_CELL := Vector2i(7, 11)
## L'entraîneur et ses mannequins, en bas à droite, à l'écart des passages ; autant de
## cases que de mannequins au plus.
const TRAINER_CELL := Vector2i(16, 10)
const DUMMY_CELLS: Array[Vector2i] = [Vector2i(20, 10), Vector2i(19, 8), Vector2i(19, 12)]
## Les entrées du menu de l'entraîneur au-delà de ces deux-là sont le nombre, plus `COUNT_ID`.
const IMMORTAL_ID := 0
const MORTAL_ID := 1
const COUNT_ID := 10
## Le waypoint s'active quand on marche dessus : à moins d'une demi-case de son centre.
const WAYPOINT_REACH := 16.0

var generator: MapGenerator

## Tirage propre à la zone : tout ce qui la dessine ou la peuple passe par lui.
## C'est ce qui fait qu'une graine redonne exactement la même zone — mêmes murs,
## même sol, même décor, mêmes ennemis, mêmes silhouettes. Choisir une *nouvelle* graine
## reste, lui, un tirage global.
var zone_rng := RandomNumberGenerator.new()

var _seed := 0
## Le rang de la zone dans `AREAS` : celui de la dernière quittée tant qu'on est en ville.
var area := 1
## Les waypoints activés ; ceux du personnage chargé, la même liste.
var waypoints: Array[int] = []
var _waypoint_menu := PopupMenu.new()
## Ce qu'on a demandé à l'entraîneur, le temps de la session.
var dummy_count := 1
var dummies_mortal := false
var _trainer_menu := PopupMenu.new()
## Vrai en ville : ni ennemis ni portail à ouvrir, un marchand et le coffre.
var in_town := false
## Le coffre partagé de la session ; un coffre vide et jamais écrit sans personnage.
var stash: Stash
## Où tombe ce qu'on pose : le sol de la ville, ou celui de la zone.
var loot: Node2D
## La zone quittée par un portail, figée en attendant qu'on y revienne, et l'endroit
## d'où l'on est parti ; null quand il n'y en a pas.
var _left_zone: MapGenerator
var _left_at := Vector2.ZERO
var _gen_ms := 0.0
var _paint_ms := 0.0
var _spawned := 0


func _ready() -> void:
	var ts := TilesetBuilder.build()
	floor_layer.tile_set = ts
	wall_layer.tile_set = ts
	# Le sol partage le TileSet mais ne doit rien bloquer.
	floor_layer.collision_enabled = false

	enemy_manager.target = player
	enemy_manager.projectile_parent = projectiles
	loot = zone_loot
	enemy_manager.loot_parent = zone_loot
	enemy_manager.ground_parent = ground
	player.died.connect(_on_player_died)

	player.projectile_parent = projectiles
	map_overlay.player = player
	map_overlay.enemy_manager = enemy_manager
	map_overlay.marks = [area_waypoint, area_exit, town_waypoint, town_gate]
	hud.bind(player)
	inventory.bind(player)
	inventory.drop_requested.connect(_on_item_dropped)
	stats_panel.bind(player)
	manuals.bind(player)
	passive_tree.bind(player)
	bar.bind(player)
	flasks.bind(player)
	# Ce qu'on range et qui ne tient plus dans le sac tombe devant soi, comme ce
	# qu'on jette : un seul chemin pour poser un objet au sol.
	manuals.drop_requested.connect(_on_item_dropped)
	# L'établi pose par le même chemin que tout le reste : un seul endroit sait
	# faire tomber un objet, et l'outil de réglage n'y fait pas exception.
	workbench.drop_requested.connect(_on_item_dropped)
	workbench.requested_orbs.connect(drop_orbs)

	stash = Game.stash if Game.stash != null else Stash.new()
	merchant.used.connect(inventory.open_merchant)
	stash_chest.used.connect(_open_stash)
	town_gate.used.connect(enter_area.bind(1))
	town_gate.title = AREAS[1]
	way_back.used.connect(return_to_zone)
	portal.used.connect(enter_town)
	area_exit.used.connect(func() -> void: enter_area(area + 1))
	town_waypoint.used.connect(_open_waypoints)
	area_waypoint.used.connect(_open_waypoints)
	town_waypoint.lit = true
	merchant.position = MapGenerator.cell_center(MERCHANT_CELL)
	stash_chest.position = MapGenerator.cell_center(STASH_CELL)
	town_gate.position = MapGenerator.cell_center(GATE_CELL)
	way_back.position = MapGenerator.cell_center(WAY_BACK_CELL)
	town_waypoint.position = MapGenerator.cell_center(TOWN_WAYPOINT_CELL)
	trainer.position = MapGenerator.cell_center(TRAINER_CELL)
	trainer.used.connect(_open_trainer)
	# Comme les menus du filtre de butin : la police du jeu, et des noms déjà traduits.
	_waypoint_menu.auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	_waypoint_menu.add_theme_font_size_override("font_size", 8)
	$UI.add_child(_waypoint_menu)
	_waypoint_menu.id_pressed.connect(travel)
	_trainer_menu.auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	_trainer_menu.add_theme_font_size_override("font_size", 8)
	# Ouvert après un choix : les deux réglages se font d'une traite.
	_trainer_menu.hide_on_checkable_item_selection = false
	$UI.add_child(_trainer_menu)
	_trainer_menu.id_pressed.connect(_on_trainer_choice)
	beyond.color = TilesetBuilder.WALL_BASE

	# Le personnage vient de l'écran de sélection. Null quand la zone est lancée
	# seule depuis l'éditeur : le joueur garde alors sa fiche par défaut, et rien
	# n'est écrit — une scène de réglage ne doit pas toucher aux sauvegardes.
	if Game.character != null:
		player.load_character(Game.character)
		waypoints = Game.character.waypoints
		player.leveled_up.connect(_on_level_gained)
		Game.save_requested.connect(save)
		var safety_net := Timer.new()
		safety_net.wait_time = SAVE_PERIOD
		safety_net.timeout.connect(save)
		add_child(safety_net)
		safety_net.start()
	else:
		# L'épée de départ, sans quoi le banc de mesure et l'éditeur ne lanceraient rien.
		player.equip(Item.new(ItemCatalog.by_id(ItemCatalog.ID_STARTING_WEAPON)))

	# Un personnage arrive en ville ; une scène de réglage, directement dans une zone.
	if Game.character != null:
		enter_town()
	else:
		new_zone()


## Un manuel aux pieds d'un personnage neuf, **au sol** et non dans le sac : c'est
## le geste du ramassage qu'on veut enseigner, et un objet qui brille par terre le
## dit mieux qu'une ligne d'aide.
##
## Reposé à **chaque génération** tant qu'il n'a pas été pris, parce que
## regénérer efface le butin au sol : sans ça, un `F5` dans les premières
## secondes détruisait pour toujours le seul manuel du personnage, et rien ne le
## disait. C'est le ramassage qui pose le drapeau, pas la chute.
func _give_first_manual() -> void:
	if Game.character == null or player.manual_given:
		return
	var base := ItemCatalog.by_id(ItemCatalog.ID_STARTING_MANUAL)
	if base == null:
		return
	_drop_on_ground(Item.new(base))


## Écrit le personnage courant. Publique : c'est le point d'entrée des trois
## déclencheurs, et celui du test.
##
## Sans effet quand aucun personnage n'est chargé — c'est le cas des scènes de
## réglage, qui partagent cette scène de zone.
func save() -> void:
	if Game.character == null:
		return
	player.fill(Game.character)
	var written := SaveStore.write(Game.character)
	# Avec le personnage, toujours : un objet passé du sac au coffre ne doit exister ni
	# deux fois ni zéro. Illisible, le coffre n'est jamais écrit.
	if not stash.unreadable:
		written = SaveStore.write_stash(stash) and written
	if not written:
		# Sans fondu, exprès : un échec d'écriture doit rester à l'écran jusqu'à
		# la sauvegarde suivante, là où une réussite n'a pas à s'attarder.
		_announce(Texts.t("échec de la sauvegarde"))
		return

	_announce(Texts.t("sauvegardé"))
	create_tween().tween_property(indicator, "modulate:a", 0.0, 1.4).set_delay(0.8)


## Un témoin discret, mais un témoin : sans lui on ne sait pas si le jeu a
## sauvegardé, et on ferme la fenêtre en croisant les doigts.
##
## Le texte et l'opacité vont ensemble. Écrire le texte sans relever l'opacité
## n'affiche rien du tout — le fondu précédent l'a laissée à zéro — et ça ne se
## voit qu'en jouant.
func _announce(text_value: String) -> void:
	indicator.text = text_value
	indicator.modulate.a = 1.0


## En différé : la montée de niveau arrive depuis la boucle de l'EnemyManager,
## donc d'un rappel de physique. Rien de ce qui touche au disque ou à l'arbre ne
## part de là.
func _on_level_gained(_level: int) -> void:
	save.call_deferred()


func _on_item_dropped(item: Item) -> void:
	_drop_on_ground(item)


## Les boules d'expérience de l'établi, en couronne autour du joueur, sur trois
## rayons. Posées sous ses pieds, elles seraient ramassées avant d'avoir été vues ;
## sur un seul cercle, dix boules se touchent et se lisent comme un anneau.
##
## Au niveau de la zone **en cours**, celui de ses ennemis — pas celui qu'on a choisi
## pour la prochaine.
func drop_orbs(count: int) -> void:
	var value := ExperienceOrb.value_for(enemy_manager.level)
	for i in count:
		var spread := Vector2.from_angle(TAU * float(i) / float(count)) * (ORB_CROWN + 8.0 * float(i % 3))
		ExperienceOrb.put(loot, player.global_position + spread, value, enemy_manager.level)


## **Le seul endroit qui pose un objet au sol** : ce qu'on jette du sac, ce que le
## râtelier rend sans place pour l'accueillir, et le manuel de départ. Les trois
## écrivaient la même ligne, distance comprise ; il suffisait d'en corriger
## deux pour que le troisième tombe ailleurs, ce qui ne se voit qu'en jouant.
func _drop_on_ground(item: Item) -> void:
	GroundItem.spawn(loot, player.global_position + player.facing * AT_THE_FEET, item, player)


func _process(_delta: float) -> void:
	if (
		not in_town and not area_waypoint.lit
		and player.global_position.distance_to(area_waypoint.position) < WAYPOINT_REACH
	):
		_activate_waypoint()
	if overlay.visible:
		overlay.text = _overlay_text()


## Échap ferme d'abord ce qui est ouvert, et n'ouvre le menu qu'ensuite.
##
## Dans `_input` et non `_unhandled_input` : le menu de pause, dernier enfant de la
## zone, lit la touche avant elle. Et ici plutôt que dans le menu : c'est la zone qui
## connaît ses panneaux. La page des manuels referme son arbre avant, dans son propre
## `_input`, qu'un enfant reçoit avant son parent.
func _input(event: InputEvent) -> void:
	if Keys.pressed_down(event) == KEY_ESCAPE and close_interfaces():
		get_viewport().set_input_as_handled()


## Ferme tout ce qui est ouvert, et dit si quelque chose l'était. Par la visibilité
## et non par `Game.ui_grabs_input` : la fiche de personnage ne prend jamais la
## souris, et Échap la laisserait ouverte.
func close_interfaces() -> bool:
	var closed := false
	for panel: Control in [inventory, stats_panel, manuals, passive_tree, workbench]:
		if panel.visible:
			panel.toggle()
			closed = true
	if bar.menu_open():
		bar.close_menu()
		closed = true
	return closed


func _unhandled_input(event: InputEvent) -> void:
	# Les actions d'abord : le joueur les rebinde depuis les options, et leur touche
	# ne s'écrit donc plus ici.
	if _zone_action(event):
		get_viewport().set_input_as_handled()
		return

	var key := Keys.pressed_down(event)
	if key == KEY_NONE:
		return

	# Retenu avant le match : un changement de scène détache ce nœud de l'arbre
	# et get_viewport() renverrait null.
	var vp := get_viewport()

	match key:
		KEY_F5: new_zone()
		# Le niveau de la **prochaine** zone. Changer celui de la zone en cours
		# donnerait une population mêlée : les ennemis sont mis à l'échelle en
		# naissant, ceux déjà debout ne bougeraient plus. Le bandeau annonce donc
		# les deux quand ils diffèrent.
		KEY_PAGEUP: Game.change_zone_level(10 if (event as InputEventKey).shift_pressed else 1)
		KEY_PAGEDOWN: Game.change_zone_level(-10 if (event as InputEventKey).shift_pressed else -1)
		KEY_G: spawn_pack()
		KEY_K: kill_all()
		# **Pas une touche de fonction.** F5, F6, F7 et F8 sont les raccourcis de
		# la barre d'exécution de l'éditeur — lancer, lancer la scène, pause,
		# arrêter — et depuis Godot 4.4 la fenêtre de jeu est intégrée à
		# l'éditeur : ils atteignent le jeu pendant qu'on y joue. F8 fermait donc
		# la partie au lieu d'ouvrir l'établi. B comme banc d'essai.
		KEY_B: workbench.toggle()
		KEY_H: overlay.visible = not overlay.visible
		KEY_F2: Game.goto_scene("res://world/test_arena.tscn")
		KEY_F3: Game.goto_scene("res://world/map_debug.tscn")
		KEY_F4: Game.goto_scene("res://art/forge_gallery.tscn")
		KEY_F6: Game.goto_scene("res://world/stress_test.tscn")
		_: return

	vp.set_input_as_handled()


## Les actions de jeu que la zone porte : vrai si l'une a répondu. Leur touche vit
## dans `project.godot` et dans les réglages, **jamais ici** — c'est ce qui les rend
## rebindables. Les touches de réglage restent dans le `match` ci-dessus : elles
## ouvrent des outils, pas le jeu.
##
## Rallumer les noms au sol les range à nouveau : une pile qui débordait du haut de
## l'écran se démêle en s'étant décalé entre les deux.
func _zone_action(event: InputEvent) -> bool:
	if event.is_action_pressed("panel_inventory"):
		inventory.toggle()
	elif event.is_action_pressed("panel_character"):
		stats_panel.toggle()
	elif event.is_action_pressed("panel_manuals"):
		manuals.toggle()
	elif event.is_action_pressed("panel_passives"):
		passive_tree.toggle()
	elif event.is_action_pressed("zone_map"):
		map_overlay.visible = not map_overlay.visible
	elif event.is_action_pressed("ground_labels"):
		GroundItem.show_labels(not GroundItem.labels_shown)
	elif event.is_action_pressed("loot_filter"):
		Settings.loot_filter_on = not Settings.loot_filter_on
	elif event.is_action_pressed("town_portal"):
		open_portal()
	else:
		return false
	return true


## Une carte neuve pour la zone où l'on est : `F5`. Celle qu'on avait quittée par
## un portail est abandonnée.
func new_zone() -> void:
	generate_zone(Game.rng.randi())


## La zone de rang `index`, sur une carte neuve à chaque entrée : par l'entrée de sa
## route, ou sur son waypoint quand on y voyage.
func enter_area(index: int, at_waypoint := false) -> void:
	area = clampi(index, 1, AREAS.size() - 1)
	generate_zone(Game.rng.randi())
	if at_waypoint:
		player.global_position = MapGenerator.cell_center(generator.waypoint_cell())
	_announce(Texts.t(AREAS[area]))
	create_tween().tween_property(indicator, "modulate:a", 0.0, 1.4).set_delay(1.2)


## Le voyage d'un waypoint : le rang 0 est la ville. La zone qu'on quitte ainsi est
## abandonnée, comme par le portail d'en haut — seul le portail de ville la garde.
func travel(index: int) -> void:
	if index == 0:
		enter_town(false)
	else:
		enter_area(index, true)


## La liste des waypoints activés, sauf celui où l'on est. Un waypoint éteint ne
## mène nulle part : il faut d'abord marcher dessus.
func _open_waypoints() -> void:
	if not in_town and not area_waypoint.lit:
		return
	_waypoint_menu.clear()
	if not in_town:
		_waypoint_menu.add_item(Texts.t(AREAS[0]), 0)
	for index in range(1, AREAS.size()):
		if waypoints.has(index) and (in_town or index != area):
			_waypoint_menu.add_item(Texts.t(AREAS[index]), index)
	if _waypoint_menu.item_count == 0:
		_announce(Texts.t("aucun autre waypoint activé"))
		create_tween().tween_property(indicator, "modulate:a", 0.0, 1.4).set_delay(0.8)
		return
	_waypoint_menu.popup(Rect2i(Vector2i(get_viewport().get_mouse_position()), Vector2i.ZERO))


func _open_trainer() -> void:
	_fill_trainer_menu()
	_trainer_menu.popup(Rect2i(Vector2i(get_viewport().get_mouse_position()), Vector2i.ZERO))


## Refait à chaque choix : les coches suivent, et la langue si elle a changé.
func _fill_trainer_menu() -> void:
	_trainer_menu.clear()
	_trainer_menu.add_radio_check_item(Texts.t("Immortels"), IMMORTAL_ID)
	_trainer_menu.set_item_checked(0, not dummies_mortal)
	_trainer_menu.add_radio_check_item(Texts.t("Mortels"), MORTAL_ID)
	_trainer_menu.set_item_checked(1, dummies_mortal)
	_trainer_menu.add_separator()
	for n in range(1, DUMMY_CELLS.size() + 1):
		_trainer_menu.add_radio_check_item(Texts.t("Mannequins : %d") % n, COUNT_ID + n)
		_trainer_menu.set_item_checked(_trainer_menu.item_count - 1, n == dummy_count)


func _on_trainer_choice(id: int) -> void:
	if id >= COUNT_ID:
		dummy_count = id - COUNT_ID
	else:
		dummies_mortal = id == MORTAL_ID
	_fill_trainer_menu()
	_place_dummies()


## Neufs à chaque fois, et seulement en ville : hors d'elle, leurs corps cachés
## prendraient encore les coups, la zone partageant ses coordonnées. Un grunt de la
## prochaine zone, sans affixe : c'est contre lui qu'on règle son coup.
func _place_dummies() -> void:
	for dummy in dummies.get_children():
		dummies.remove_child(dummy)
		dummy.queue_free()
	if not in_town:
		return
	var sheet := Enemy.sheet_of(GRUNT_STATS, Game.zone_level, [])
	for i in dummy_count:
		var dummy: TrainingDummy = DUMMY_SCENE.instantiate()
		dummy.position = MapGenerator.cell_center(DUMMY_CELLS[i])
		dummy.stats = sheet
		dummy.mortal = dummies_mortal
		dummies.add_child(dummy)


## Activé pour de bon, donc écrit tout de suite : le personnage ne doit pas le
## reperdre sur une fermeture avant la sauvegarde suivante.
func _activate_waypoint() -> void:
	waypoints.append(area)
	area_waypoint.lit = true
	save()
	_announce(Texts.t("waypoint activé"))
	create_tween().tween_property(indicator, "modulate:a", 0.0, 1.4).set_delay(0.8)


## Le niveau choisi prend effet **ici**, et nulle part ailleurs : c'est le seul
## moment où l'on peut peupler une carte d'ennemis tous nés au même niveau.
func generate_zone(zone_seed: int) -> void:
	_set_town(false)
	_left_zone = null
	_freeze_zone(false)
	_seed = zone_seed
	zone_rng.seed = zone_seed
	enemy_manager.level = _area_level()
	kill_all()

	generator = MapGenerator.new()
	var t0 := Time.get_ticks_usec()
	generator.generate(_seed)
	_gen_ms = float(Time.get_ticks_usec() - t0) / 1000.0

	_lay_out()

	# **Après** le placement, jamais avant : c'est `_place_and_populate()` qui pose
	# le joueur sur le point d'apparition de la carte neuve. Offert plus tôt, le
	# livre tombait à l'endroit où le joueur était encore — le coin de la scène
	# pour un personnage qui entre en jeu pour la première fois, c'est-à-dire
	# exactement le cas qu'on veut servir.
	_place_and_populate()
	_place_marks()

	_give_first_manual()


## Le niveau choisi, plus un par zone franchie depuis la première.
func _area_level() -> int:
	return Game.zone_level + area - 1


func _place_marks() -> void:
	area_waypoint.position = MapGenerator.cell_center(generator.waypoint_cell())
	area_waypoint.lit = waypoints.has(area)
	area_exit.position = MapGenerator.cell_center(generator.road.back())
	area_exit.title = AREAS[mini(area + 1, AREAS.size() - 1)]
	area_exit.visible = area < AREAS.size() - 1


## La ville : la même salle à chaque visite, sans ennemis. On y arrive en se
## connectant et par le portail qu'on ouvre en zone — la zone se fige alors, et le
## portail de retour y ramène. Par un waypoint, `keep_zone` est faux : elle est abandonnée.
func enter_town(keep_zone := true) -> void:
	if not in_town and generator != null and keep_zone:
		_left_zone = generator
		_left_at = player.global_position
		_freeze_zone(true)
	elif not in_town:
		_left_zone = null
		kill_all()
	_set_town(true)
	zone_rng.seed = TOWN_SEED
	generator = MapGenerator.town(TOWN_SIZE.x, TOWN_SIZE.y)
	_lay_out()
	player.revive()
	player.refill_flasks()
	player.global_position = MapGenerator.cell_center(generator.get_spawn_cell())
	way_back.visible = _left_zone != null
	# Pas quand une zone attend : le sien y est encore au sol, et l'on en ramasserait deux.
	if _left_zone == null:
		_give_first_manual()


## La zone quittée, telle qu'on l'a laissée : mêmes murs, mêmes ennemis, même butin.
## On y reparaît là où l'on a pris le portail, qui se referme derrière soi.
func return_to_zone() -> void:
	if _left_zone == null:
		return
	_set_town(false)
	generator = _left_zone
	_left_zone = null
	# Le sol se repeint à l'identique : sa peinture est le premier tirage de la graine.
	zone_rng.seed = _seed
	_lay_out()
	_freeze_zone(false)
	player.global_position = _left_at


## Le portail vers la ville, devant le joueur : un seul à la fois, comme dans PoE.
func open_portal() -> void:
	if in_town:
		return
	portal.global_position = player.global_position + player.facing * PORTAL_AHEAD
	portal.show()


## Le portail ouvert se referme dès qu'on change de lieu : il a servi, ou sa zone
## n'est plus. Quitter la ville referme le coffre ou l'étal, qui n'y ont plus de sens.
## Les tirs en vol partent : ils voleraient dans les murs de l'autre carte. Le sol de
## la ville se vide aussi, dans les deux sens : caché mais pas figé, son butin se
## cliquerait encore depuis la zone.
func _set_town(on: bool) -> void:
	in_town = on
	town.visible = on
	area_marks.visible = not on
	loot = town_loot if on else zone_loot
	portal.hide()
	for node in projectiles.get_children() + town_loot.get_children():
		node.queue_free()
	if not on and inventory.storage_open():
		inventory.toggle()
	_place_dummies()


## Une zone quittée ne vit plus : désactivés, ses ennemis sortent aussi de la physique
## (`CollisionObject2D.disable_mode`), leurs coups au sol ne frappent plus, et rien ne
## s'en voit depuis la ville, qui partage ses coordonnées.
func _freeze_zone(frozen: bool) -> void:
	for part: Node2D in [enemy_manager, ground, zone_loot]:
		part.process_mode = Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT
		part.visible = not frozen


func _open_stash() -> void:
	if stash.unreadable:
		# Sans fondu, comme un échec de sauvegarde : le fichier attend qu'on le répare.
		_announce(Texts.t("coffre illisible"))
		return
	inventory.open_stash(stash.tabs)


## Pose la carte de `generator` : tuiles, collisions, carte superposée, champ de flux.
func _lay_out() -> void:
	var t0 := Time.get_ticks_usec()
	_paint()
	_paint_ms = float(Time.get_ticks_usec() - t0) / 1000.0

	# Les collisions d'une couche de tuiles ne se reconstruisent qu'en fin d'image.
	# Sans cette mise à jour, le joueur posé plus bas sur l'apparition de la carte
	# neuve chevauche encore un mur de l'ancienne à la première image de physique,
	# et s'en fait éjecter — seize pixels mesurés, de quoi envoyer le manuel de
	# départ hors de ses pieds. C'est `F5` en jeu. Hors de la mesure de peinture,
	# pour que celle-ci reste comparable à ses relevés d'avant.
	floor_layer.update_internals()
	wall_layer.update_internals()

	# La carte suit la zone réellement jouée : reconstruite ici, pas ailleurs.
	map_overlay.build(generator, MapGenerator.TILE)

	# Le champ de flux appartient à la carte : un nouveau générateur, un nouveau
	# champ. Le garder ferait poursuivre les ennemis à travers l'ancienne.
	enemy_manager.field = FlowField.new(generator)


## Remet le joueur au point d'apparition et repeuple la carte courante. Le même
## quatuor de lignes était écrit à la génération d'une zone **et** à la mort du
## joueur ; le jour où repeupler demandera une étape de plus, elle s'ajoutera ici.
##
## Placement par paquets répartis sur toute la carte, avec du vide entre eux.
## C'est ça qui donne le rythme de traversée ; un paquet autour du joueur ne sert
## plus qu'au test manuel (touche G).
func _place_and_populate() -> void:
	var spawn_cell := generator.get_spawn_cell()
	player.revive()
	player.global_position = MapGenerator.cell_center(spawn_cell)
	_spawned = spawner.populate(generator, enemy_manager, spawn_cell, _seed)


func _paint() -> void:
	var map_px := Vector2(generator.width, generator.height) * MapGenerator.TILE
	var screen := get_viewport_rect().size
	beyond.position = -screen
	beyond.size = map_px + screen * 2.0
	floor_layer.clear()
	wall_layer.clear()
	# `free` et non `queue_free` : une zone repeinte deux fois dans la même image
	# garderait sinon le décor de la première.
	for node in decor.get_children():
		node.free()
	floor_layer.material = TilesetBuilder.ground_material(
		Vector2i(generator.width, generator.height), zone_rng.randi(), generator.road
	)
	# Rien ne pousse sur la route.
	var on_road := {}
	for cell in generator.road:
		on_road[cell] = true

	for y in generator.height:
		for x in generator.width:
			var cell := Vector2i(x, y)
			if generator.grid[y][x] == MapGenerator.FLOOR:
				floor_layer.set_cell(cell, 0, Vector2i(TilesetBuilder.FLOOR_INDEX, 0))
				if in_town or on_road.has(cell):
					continue
				var roll := zone_rng.randf()
				if roll < ROCK_CHANCE:
					_plant(ROCK, cell)
				elif roll < ROCK_CHANCE + BUSH_CHANCE:
					_plant(BUSH, cell)
			else:
				var tile := _wall_tile(x, y)
				wall_layer.set_cell(cell, 0, Vector2i(tile, 0))
				if tile == TilesetBuilder.WALL_EDGE_INDEX and not in_town and zone_rng.randf() < TREE_CHANCE:
					_plant(TREES[zone_rng.randi() % TREES.size()], cell, false)


## Le pied de l'image sur le bas de la case : c'est lui qui trie le décor avec les
## corps. Un arbre ne bouge pas de son mur ; le reste se décale un peu.
func _plant(texture: Texture2D, cell: Vector2i, jitter := true) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() / 2.0, -texture.get_height())
	sprite.flip_h = zone_rng.randf() < 0.5
	var at := MapGenerator.cell_center(cell) + Vector2(0, MapGenerator.TILE / 2.0)
	if jitter:
		at += Vector2(zone_rng.randf_range(-1, 1), zone_rng.randf_range(-1, 0)) * DECOR_JITTER
	sprite.position = at.round()
	decor.add_child(sprite)


## Le dessus n'est éclairé que si la case au-dessus est du sol : sinon on est
## à l'intérieur d'une masse de murs, et une bande claire y dessinerait une
## grille de briques.
func _wall_tile(x: int, y: int) -> int:
	# Type explicite : grid est un Array non typé, donc la comparaison rend un
	# Variant et l'inférence échoue.
	var above_is_floor: bool = y > 0 and generator.grid[y - 1][x] == MapGenerator.FLOOR
	return TilesetBuilder.WALL_EDGE_INDEX if above_is_floor else TilesetBuilder.WALL_INDEX


## Paquet mixte autour du joueur, sur des cases praticables uniquement. Pas en ville :
## il naîtrait dans la zone figée.
func spawn_pack() -> void:
	if in_town:
		return
	var origin := MapGenerator.cell_at(player.global_position)
	var total := PACK_GRUNTS + PACK_CASTERS
	var placed := 0
	var attempts := 0

	while placed < total and attempts < total * 30:
		attempts += 1
		var offset := Vector2i(
			Game.rng.randi_range(-PACK_RADIUS_TILES, PACK_RADIUS_TILES),
			Game.rng.randi_range(-PACK_RADIUS_TILES, PACK_RADIUS_TILES)
		)
		if absi(offset.x) < PACK_MIN_TILES and absi(offset.y) < PACK_MIN_TILES:
			continue   # pas dans les pieds du joueur
		var cell := origin + offset
		if not generator.is_walkable(cell):
			continue

		var scene := CASTER_SCENE if placed >= PACK_GRUNTS else GRUNT_SCENE
		enemy_manager.spawn(scene, MapGenerator.cell_center(cell))
		placed += 1


## Publique : la scène de stress test vide la zone avant d'y verser ses vagues.
func kill_all() -> void:
	enemy_manager.clear()
	for p in projectiles.get_children():
		p.queue_free()
	for z in ground.get_children():
		z.queue_free()
	# Le butin est posé sur le sol de *cette* carte : le garder d'une zone à
	# l'autre laisserait des objets flotter dans les murs de la suivante.
	for l in zone_loot.get_children():
		l.queue_free()


func _on_player_died() -> void:
	# En différé : la mort arrive depuis la boucle de l'EnemyManager, et
	# regénérer la zone viderait sa liste en plein parcours.
	_respawn.call_deferred()


## En ville, on y revient : la repeupler y ferait naître des ennemis.
func _respawn() -> void:
	if in_town:
		enter_town()
		return
	kill_all()
	_place_and_populate()


## Ce que F5 donnera, quand ce n'est pas ce qu'on a sous les pieds. Rien à
## afficher tant que les deux coïncident : une deuxième valeur en permanence se
## lirait comme une contradiction.
func _pending_level() -> String:
	if _area_level() == enemy_manager.level:
		return ""
	return "  (F5 : %d)" % _area_level()


func _overlay_text() -> String:
	return "\n".join([
		# Ni les PV ni les statistiques de combat : les jauges du HUD donnent les
		# premiers au point près, et la fiche (touche C) donne les secondes en
		# entier. Ce bandeau ne garde que ce que lui seul sait.
		"niv %d (%d/%d)    ennemis %d" % [
			player.level, player.xp, player.xp_to_next, enemy_manager.enemies.size()
		],
		"",
		("ville  —  prochaine zone : niveau %d" % Game.zone_level) if in_town else
		"%s %d  —  niveau %d%s  —  %d cases de sol" % [
			AREAS[area], _seed, enemy_manager.level, _pending_level(), generator.floor_cells.size()
		],
		"%d ennemis places en %d paquets" % [_spawned, spawner.pack_count],
		"generation %.0f ms  peinture %.0f ms" % [_gen_ms, _paint_ms],
		"",
		# Lues dans la carte d'entrées : rebindées, elles s'annoncent telles quelles.
		"[%s] carte de la zone" % Keybinds.key_label("zone_map"),
		"[%s] inventaire   [%s] fiche de personnage" % [
			Keybinds.key_label("panel_inventory"), Keybinds.key_label("panel_character")
		],
		"[F5] nouvelle zone   [G] paquet   [K] tout tuer",
		"[PAGE HAUT/BAS] niveau de la prochaine zone  (+MAJ : 10)",
		"[%s] noms au sol   [%s] filtre de butin   [H] masquer cette aide" % [
			Keybinds.key_label("ground_labels"), Keybinds.key_label("loot_filter")
		],
		"[%s] portail vers la ville" % Keybinds.key_label("town_portal"),
		"[F2] arene de reglage   [F3] reglage generation",
		"[F4] forge              [F6] stress test",
		"[B] etabli (reglage)",
		"[ECHAP] menu et sauvegarde",
	])
