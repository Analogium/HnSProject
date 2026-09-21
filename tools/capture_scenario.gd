extends Node

## Gabarit de scénario pour `tools/capture.sh` : **le recopier dans le dossier de
## travail et n'éditer que les constantes**, puis
## `tools/capture.sh <copie>.gd <sujet>`. Voir le skill /dessiner-un-effet.
##
## Les pièges qu'il contourne, tous payés d'une capture ratée au jalon 24 :
## - **les sorts veulent une baguette** — `cast_slot` rend `false` sans rien dire
##   avec l'épée de départ ; `WAND` l'équipe ;
## - **la réserve** : un sort refusé faute de mana ne dit rien non plus, elle est
##   remplie toutes les quatre images ;
## - **la caméra rattrape le joueur** pendant la première demi-seconde : ne rien
##   lancer avant la frise ci-dessous, qui démarre à l'arrivée en zone ;
## - **ce qui se pose au curseur** tombe à `PLACEMENT_RANGE` devant, dans `FACING` :
##   recadrer là, pas au centre de l'écran ;
## - **un geste entretenu** (cyclone, aura) tourne encore aux captures suivantes.

## Le livre étudié, et les compétences à placer dans la barre, dans l'ordre des cases.
const MANUAL := "manual_weapons"
const SKILLS := ["slicing_dash"]
## Les nœuds de talent à prendre, après les points de compétence.
const NODES: Array[String] = []
const POINTS := 3
const WAND := false
## En biais par défaut : c'est la visée qui éprouve ce qui pivote.
const FACING := Vector2(1.0, -0.55)
## La frise, en images de physique depuis l'arrivée en zone : `["cast", case]`,
## `["shot", "nom"]`, `["pack"]` pour lâcher des ennemis, `["quit"]`.
const TIMELINE := {
	40: ["pack"],
	70: ["cast", 0],
	72: ["shot", "1-debut"],
	78: ["shot", "2-milieu"],
	90: ["shot", "3-fin"],
	110: ["quit"],
}

var _zone: Node
var _player: Player
var _tick := 0
var _armed := false
var _pending: Array[String] = []


func _physics_process(_delta: float) -> void:
	_tick += 1
	if not _armed:
		if _tick == 10:
			Game.character = SaveStore.create("Capture", 0)
			Game.goto_scene("res://world/zone.tscn")
		var scene := get_tree().current_scene
		if _tick > 10 and scene != null and scene.has_node("Entities/Player"):
			_zone = scene
			_player = scene.get_node("Entities/Player")
			_arm()
			_armed = true
			_tick = 0
		return
	if _tick % 4 == 0:
		_player._set_mana(500.0)
	if not TIMELINE.has(_tick):
		return
	var step: Array = TIMELINE[_tick]
	match String(step[0]):
		"pack":
			_zone.spawn_pack()
		"cast":
			print("case %d (%s) : %s" % [step[1], _player.bar.id_of(step[1]), _player.cast_slot(step[1])])
		"shot":
			_pending.append(String(step[1]))
			call_deferred("_save")
		"quit":
			get_tree().quit()


func _arm() -> void:
	if WAND:
		_player.equip(Item.new(ItemCatalog.by_id(ItemCatalog.ID_STARTING_WAND)))
	var book := Item.new(ItemCatalog.by_id(MANUAL))
	book.manual.gain_experience(100000)
	_player.study(book)
	for id: String in SKILLS:
		for n in POINTS:
			_player.invest(0, id)
	for node in NODES:
		print("nœud %s : %s" % [node, _player.invest(0, node)])
	for i in SKILLS.size():
		_player.bar.put(i, SKILLS[i])
	_player._aim_with_mouse = false
	_player.facing = FACING.normalized()
	_player.stats.max_mana = 500.0


func _save() -> void:
	await RenderingServer.frame_post_draw
	var name: String = _pending.pop_front()
	get_viewport().get_texture().get_image().save_png("user://%s.png" % name)
	print("capture : ", name)
