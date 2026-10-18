class_name ActorModel
extends Node3D

## Le corps d'un acteur : il reçoit un état (immobile / en marche / en train de frapper) et une
## direction, et choisit l'animation. Les acteurs ne connaissent donc jamais un nom d'animation.
##
## Le modèle de l'archétype, `art/models/<archétype>.glb`, quand il existe ; sa planche sinon
## (`sprite`), le temps que chaque personnage passe en 3D (jalon 54, étape 2). Sans _process :
## l'AnimationPlayer avance seul, et la fin d'un geste arrive par animation_finished.

## Un modèle de `art/models/`, ou un nom connu de SpriteForge.ARCHETYPES.
@export var archetype: String = "grunt"
## -1 : silhouette déduite de la position d'apparition. Un numéro fixe force une
## variante précise, ce dont on se sert pour le joueur. Seules les planches en ont.
@export var variant: int = -1
## Le corps des vues de face (`ActorPortrait`) : `<archétype>_portrait.glb`, le modèle net
## que le jeu ne charge pas en zone, s'il existe (jalon 54). Il n'a que le repos.
@export var portrait := false

const MODELS := "res://art/models/%s.glb"
const PORTRAITS := "res://art/models/%s_portrait.glb"

## L'impact d'un geste qu'aucune planche ni aucun modèle ne décrit : au milieu du coup, un peu avant.
const DEFAULT_IMPACT := 0.4

## Durée du flash blanc encaissé. En secondes réelles : le hit-stop ralentit le
## jeu d'un facteur 50, et un flash étiré d'autant resterait à l'écran presque
## quatre secondes.
const FLASH_TIME := 0.08

## La part de la couleur d'un état dans le corps. À moitié ou presque : assez pour
## lire « embrasé » dans une mêlée, pas assez pour qu'un grunt cesse d'être vert.
const STATE_TINT := 0.45

## Les allures, qui bouclent ; un geste finit et rend le repos.
const REST := &"rest"
const WALK := &"walk"
## Les gestes où l'arme est rangée : la marche, et le lancer des Lames de jet, qui part de la
## main nue (jalon 54). `tools/blender_sheet.py` la lit : l'export n'y tourne pas la main.
const SHEATHED := [&"walk", &"throw"]

static var _overlay: ShaderMaterial

## La planche, quand l'archétype n'a pas de modèle ; null sinon.
var sprite: ActorSprite

## Le geste ou l'allure en cours, sous son nom de planche ou de modèle.
var animation: StringName:
	get:
		return sprite.animation if sprite != null else _playing

var speed_scale: float:
	get:
		return sprite.speed_scale if sprite != null else _player.speed_scale

var _variant := 0
var _weapon := ""
## Tenu le temps du geste en cours à la place de `_weapon`, vide sinon.
var _held := ""
## Le pas que donnent les états (le gel ralentit) : celui des allures. Un geste a le sien,
## calé sur son temps, qu'un état posé pendant le coup n'écrase pas.
var _pace := 1.0
var _attacking := false
var _playing := &""
var _body: Node3D
var _player: AnimationPlayer
## Les métadonnées de l'export (`tools/blender/export_glb.py`) : images d'impact, arme.
var _extras: Dictionary = {}
var _meshes: Array[GeometryInstance3D] = []


func _ready() -> void:
	_variant = variant if variant >= 0 else _pick()
	_rebuild()


static func has_model(name_value: String) -> bool:
	return ResourceLoader.exists(MODELS % name_value)


## Change la silhouette. Elle doit pouvoir s'appliquer **après** le _ready du
## corps : le joueur est déjà dans la scène quand la sauvegarde est chargée.
func set_variant(index: int) -> void:
	var clamped := posmod(index, SpriteForge.VARIANTS)
	if clamped == _variant:
		return
	_variant = clamped
	if sprite != null:
		sprite.set_variant(clamped)


## La silhouette effectivement retenue. Publique parce qu'elle peut avoir été
## déduite de la position d'apparition plutôt que choisie : c'est elle qu'on
## sauvegarde, pas le champ exporté qui vaut -1.
func current_variant() -> int:
	return _variant


## Change de corps : la classe d'un personnage chargé après le _ready, le règne du Roi des Rats.
func set_archetype(name_value: String) -> void:
	if name_value == archetype:
		return
	archetype = name_value
	_rebuild()


## Change l'arme tenue, vide pour revenir à celle de l'archétype.
func set_weapon(kind: String) -> void:
	if kind == _weapon:
		return
	_weapon = kind
	if sprite != null:
		sprite.set_weapon(kind)
	else:
		_show_weapon()


## La silhouette se déduit de la case où l'ennemi apparaît, et non d'un tirage :
## avec un tirage, le même ennemi au même endroit change d'aspect à chaque
## lancement, et un jeu dont les visuels bougent tout seuls paraît instable.
func _pick() -> int:
	var body := get_parent() as Node3D
	var at: Vector3 = body.position if body != null else position
	return SpawnSeed.at(at) % SpriteForge.VARIANTS


## Appelée par l'acteur à chaque tick. facing peut être nul : on garde alors la
## direction précédente.
##
## Un coup en cours verrouille tout : ni la direction, ni l'animation ne bougent
## jusqu'à la fin. Sans ce verrou, le caster qui tourne autour du joueur repart
## face à sa trajectoire dès l'image suivante, et tire vers le joueur de dos.
func set_state(moving: bool, facing: Vector3) -> void:
	if sprite != null:
		sprite.set_state(moving, facing)
		return
	if _attacking:
		return
	if facing.length_squared() >= 0.01:
		rotation.y = atan2(facing.x, facing.z)
	_play(WALK if moving else REST)


## `spell` : un sort joue le lancer, quand le corps en a un. `duration` étire le geste
## sur ce temps (jalon 47) ; zéro, sa cadence propre. `family` : le geste d'une attaque
## (`Skill.GESTURE`), si le corps l'a. `held` : ce que la main tient pour ce geste seul,
## vide pour l'arme ; un sort lancé instrument en main se **joue** (`play`, jalon 53).
func attack(spell := false, duration := 0.0, family := "", held := "") -> void:
	if sprite != null:
		sprite.attack(spell, duration, family, held)
		return
	_attacking = true
	_held = held
	var cast := &"play" if not held.is_empty() and _player.has_animation(&"play") else &"cast"
	var gesture := cast if spell and _player.has_animation(cast) else &"attack"
	if not family.is_empty() and _player.has_animation(family):
		gesture = StringName(family)
	_player.speed_scale = _pace
	if duration > 0.0:
		_player.speed_scale = _player.get_animation(gesture).length / duration
	_playing = gesture
	_show_weapon()
	_player.play(gesture)
	# Sous le même nom, `play()` **continue** le geste en cours : une touche tenue relancerait
	# sur sa fin, qui rendrait aussitôt le repos pour tout le coup (jalon 53).
	_player.seek(0.0, true)


## Où tombe le coup dans ce geste, en part de sa durée : écrit par l'export, sinon
## `DEFAULT_IMPACT`.
func impact_of(family: String) -> float:
	if sprite != null:
		return sprite.impact_of(family)
	return float(_extras.get("impacts", {}).get(family, DEFAULT_IMPACT))


## La hauteur du corps, pieds au sol, en unités du monde : écrite par l'export, nulle pour
## une planche ou un modèle d'avant elle.
func height() -> float:
	return float(_extras.get("height", 0.0)) * Flat.PX_PER_M


## Le blanchiment encaissé. Ici et non chez chaque acteur : c'est le corps qui porte le
## matériau. Une planche n'en a pas en 3D.
func flash() -> void:
	if sprite != null:
		return
	_overlay_set(&"flash_amount", 1.0)
	await get_tree().create_timer(FLASH_TIME, true, false, true).timeout
	if is_instance_valid(self):
		_overlay_set(&"flash_amount", 0.0)


## Le liseré permanent d'un affixe. Un liseré et non une teinte du corps :
## repeindre le corps fait perdre la couleur de l'archétype, et un grunt cyan ne
## se lit plus comme un grunt.
func set_rim(color: Color, amount: float, width := 1.0) -> void:
	_overlay_set(&"rim_color", Vector3(color.r, color.g, color.b))
	_overlay_set(&"rim_amount", amount)
	_overlay_set(&"rim_width", width)


## La teinte du plus récent de ses états sur tout le corps, et l'animation ralentie
## par le gel.
##
## **Une teinte, contre la règle du liseré juste au-dessus**, et c'est voulu : un
## affixe est l'identité d'un ennemi et ne doit pas lui voler sa couleur ; un état
## dure quelques secondes et doit se lire d'un coup d'œil dans un paquet.
func show_states(states: StatusEffects) -> void:
	_pace = states.speed_factor
	if sprite != null:
		sprite.set_pace(_pace)
		return
	if not _attacking:
		_player.speed_scale = _pace
	var colors := states.colors()
	var c := Color.WHITE if colors.is_empty() else colors[colors.size() - 1]
	_overlay_set(&"tint_color", Vector3(c.r, c.g, c.b))
	_overlay_set(&"tint_strength", 0.0 if colors.is_empty() else STATE_TINT)


## Le seul chemin, pour la naissance comme pour un changement d'archétype : le corps
## précédent part, modèle ou planche, et le nouveau reprend la silhouette, l'arme et le pas.
func _rebuild() -> void:
	for old: Node in [sprite, _body]:
		if old != null:
			remove_child(old)
			old.queue_free()
	sprite = null
	_body = null
	_held = ""
	_attacking = false
	_playing = &""
	_meshes.clear()
	if not has_model(archetype):
		sprite = ActorSprite.new()
		sprite.archetype = archetype
		sprite.variant = _variant
		add_child(sprite)
		sprite.set_weapon(_weapon)
		sprite.set_pace(_pace)
		return

	var path := MODELS % archetype
	if portrait and ResourceLoader.exists(PORTRAITS % archetype):
		path = PORTRAITS % archetype
	_body = (load(path) as PackedScene).instantiate()
	# Modelé en mètres, posé dans le monde en pixels (jalon 54, §2).
	_body.scale = Vector3.ONE * Flat.PX_PER_M
	add_child(_body)
	_player = _body.find_children("*", "AnimationPlayer", true, false)[0]
	_player.animation_finished.connect(_on_animation_finished)
	# Le glTF n'écrit pas de boucle ; l'animation est partagée, la poser une fois suffit.
	for gait in [REST, WALK]:
		if _player.has_animation(gait):
			_player.get_animation(gait).loop_mode = Animation.LOOP_LINEAR
	_extras = _body.find_child("Armature", true, false).get_meta("extras", {})
	if _overlay == null:
		_overlay = ShaderMaterial.new()
		_overlay.shader = preload("res://art/actor_overlay.gdshader")
	for mesh: GeometryInstance3D in _body.find_children("*", "GeometryInstance3D", true, false):
		mesh.material_overlay = _overlay
		_meshes.append(mesh)
	_play(REST)


## L'allure, relancée seulement si elle change : play() sur l'allure en cours ne fait rien,
## mais repartir de zéro à chaque tick figerait la marche sur son premier pas.
func _play(gait: StringName) -> void:
	if _playing == gait and _player.is_playing():
		return
	_playing = gait
	_show_weapon()
	_player.speed_scale = _pace
	_player.play(gait)


## Une arme par nœud `weapon_<type>`, accrochée à la main par l'export : on montre celle du
## geste, de l'équipement ou de l'archétype, dans cet ordre ; aucune dans `SHEATHED`.
func _show_weapon() -> void:
	var kind := _held if not _held.is_empty() else _weapon
	if kind.is_empty():
		kind = String(_extras.get("weapon", ""))
	var shown := "" if _playing in SHEATHED else "weapon_" + kind
	for weapon: Node3D in _body.find_children("weapon_*", "", true, false):
		weapon.visible = weapon.name == shown


func _overlay_set(parameter: StringName, value: Variant) -> void:
	for mesh in _meshes:
		mesh.set_instance_shader_parameter(parameter, value)


func _on_animation_finished(_name := &"") -> void:
	if _attacking:
		_attacking = false
		_held = ""
		_play(REST)
