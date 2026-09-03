extends Control

## La planche-contact de la forge : un archétype par page, ses quatre variantes
## en lignes, ses neuf animations en colonnes, le tout en train de jouer.
##
## C'est l'outil qui rend la génération procédurale utilisable. Sans lui on
## règle une silhouette à l'aveugle, en relançant le jeu et en cherchant un
## ennemi du bon type ; ici les quatre variantes sont côte à côte et le moindre
## défaut de proportion saute aux yeux.
##
## [S] écrit toutes les planches en PNG. C'est la porte de sortie du procédural :
## un sprite exporté peut être retouché dans un éditeur d'image et rechargé comme
## un asset ordinaire — la forge ne t'enferme pas dans le code.

const CELL := 64          # 32 px de sprite, agrandis 2 fois
const SCALE := 2
const COLS := 9           # 3 animations x 3 directions
## Dans le projet et non dans user:// : un dossier enfoui sous AppData, on ne
## le retrouve jamais. En jeu exporté res:// n'est pas inscriptible, on
## retombe donc sur user://.
const EXPORT_DIR := "res://art/generated"
const EXPORT_FALLBACK := "user://forge_export"

const ANIMS := ["idle", "walk", "attack"]

@onready var header: Label = $Header
@onready var footer: Label = $Footer
@onready var columns: Label = $Columns
@onready var stage: Node2D = $Stage

var _index := 0
var _status := ""


func _ready() -> void:
	_build()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	# Retenu avant le match : un changement de scène détache ce nœud de l'arbre
	# et get_viewport() renverrait null.
	var vp := get_viewport()

	match (event as InputEventKey).keycode:
		KEY_RIGHT, KEY_SPACE:
			_index = (_index + 1) % SpriteForge.ARCHETYPES.size()
			_build()
		KEY_LEFT:
			_index = (_index - 1 + SpriteForge.ARCHETYPES.size()) % SpriteForge.ARCHETYPES.size()
			_build()
		KEY_S:
			_export()
		# La touche qui a ouvert la forge la referme, comme pour la carte de
		# réglage (F3) — et Échap referme n'importe quel aperçu.
		KEY_F4, KEY_ESCAPE:
			Game.go_back("res://world/zone.tscn")
		_:
			return

	vp.set_input_as_handled()


func _build() -> void:
	for child in stage.get_children():
		child.queue_free()

	var archetype: String = SpriteForge.ARCHETYPES[_index]
	var x0 := (size.x - COLS * CELL) * 0.5
	var y0 := 62.0

	for variant in SpriteForge.VARIANTS:
		var frames := SpriteForge.frames(archetype, variant)
		var col := 0
		for anim in ANIMS:
			for dir in SpriteForge.DIRS:
				var s := AnimatedSprite2D.new()
				s.sprite_frames = frames
				s.scale = Vector2(SCALE, SCALE)
				s.position = Vector2(
					x0 + col * CELL + CELL * 0.5,
					y0 + variant * CELL + CELL * 0.5
				)
				s.play("%s_%s" % [anim, dir])
				# L'attaque ne boucle pas dans le jeu — sur la planche, si :
				# une pose figée ne dit rien du mouvement.
				s.animation_finished.connect(_replay.bind(s))
				stage.add_child(s)
				col += 1

	header.text = "FORGE  —  %s   (variante 0 a %d, de haut en bas)" % [
		archetype.to_upper(), SpriteForge.VARIANTS - 1
	]
	columns.text = "        repos  ^  |  marche  ^  |  attaque  ^"
	footer.text = "\n".join([
		"[<-] [->] archetype     [S] exporter les planches en PNG",
		"[F4] ou [ECHAP] retour",
		_status,
	])


func _replay(s: AnimatedSprite2D) -> void:
	if is_instance_valid(s):
		s.play()


## Compose une planche par variante : une ligne d'images par animation, dans
## l'ordre de SpriteForge. Le fichier obtenu s'ouvre tel quel dans un éditeur
## de pixel art.
func _export() -> void:
	# out_dir et pas dir : la boucle plus bas itère déjà sur les directions.
	# On teste l'existence plutôt que le code de retour, qui vaut aussi erreur
	# quand le dossier est simplement déjà là.
	var out_dir := EXPORT_DIR
	DirAccess.make_dir_recursive_absolute(out_dir)
	if not DirAccess.dir_exists_absolute(out_dir):
		out_dir = EXPORT_FALLBACK
		DirAccess.make_dir_recursive_absolute(out_dir)

	var written := 0
	for archetype in SpriteForge.ARCHETYPES:
		for variant in SpriteForge.VARIANTS:
			var cfg := SpriteForge.config(archetype, variant)
			var rows: Array[Array] = []
			for anim in ANIMS:
				for dir in SpriteForge.DIRS:
					var row: Array = []
					for i in _frame_count(anim):
						row.append(SpriteForge.frame_image(cfg, dir, anim, i))
					rows.append(row)

			var sheet := _compose(rows)
			var path := "%s/%s_v%d.png" % [out_dir, archetype, variant]
			if sheet.save_png(path) == OK:
				written += 1

	_status = "%d planches ecrites dans %s" % [
		written, ProjectSettings.globalize_path(out_dir)
	]
	_build()


func _frame_count(anim: String) -> int:
	match anim:
		"walk": return SpriteForge.WALK_SWING.size()
		"attack": return SpriteForge.ATTACK_FRAMES
		_: return SpriteForge.IDLE_BOB.size()


func _compose(rows: Array[Array]) -> Image:
	var widest := 0
	for row in rows:
		widest = maxi(widest, row.size())

	var f := SpriteForge.FRAME
	var sheet := Image.create_empty(widest * f, rows.size() * f, false, Image.FORMAT_RGBA8)
	var region := Rect2i(0, 0, f, f)

	for y in rows.size():
		var row: Array = rows[y]
		for x in row.size():
			sheet.blit_rect(row[x], region, Vector2i(x * f, y * f))

	return sheet
