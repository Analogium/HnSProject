class_name ActorSprite
extends AnimatedSprite3D

## Le sprite d'un acteur : il reçoit un état (immobile / en marche / en train de
## frapper) et une direction, et choisit l'animation. Les acteurs ne connaissent
## donc jamais un nom d'animation.
##
## Volontairement sans _process : avec soixante-dix ennemis à l'écran, un rappel
## par image et par sprite se paierait pour rien. AnimatedSprite3D lit déjà les
## images, et la fin d'une attaque arrive par animation_finished.

## Doit correspondre à un nom connu de SpriteForge.ARCHETYPES.
@export var archetype: String = "grunt"
## -1 : silhouette déduite de la position d'apparition. Un numéro fixe force une
## variante précise, ce dont on se sert pour le joueur.
@export var variant: int = -1

## Marge avant de basculer en vue de profil. Sans elle, une trajectoire proche de
## la diagonale ferait clignoter le sprite entre deux directions à chaque image.
const SIDE_BIAS := 1.15

## Durée du flash blanc encaissé. En secondes réelles : le hit-stop ralentit le
## jeu d'un facteur 50, et un flash étiré d'autant resterait à l'écran presque
## quatre secondes.
const FLASH_TIME := 0.08

## La part de la couleur d'un état dans le corps. À moitié ou presque : assez pour
## lire « embrasé » dans une mêlée, pas assez pour qu'un grunt cesse d'être vert.
const STATE_TINT := 0.45

## L'impact d'un geste qu'aucune planche ne décrit : au milieu du coup, un peu avant.
const DEFAULT_IMPACT := 0.4

var _dir := "down"
var _anim := "idle"
var _attacking := false
## Le pas que donnent les états (le gel ralentit) : celui de la marche et du repos. Un geste a le
## sien, calé sur son temps, qu'un état posé pendant le coup n'écrase plus.
var _pace := 1.0
var _variant := 0
var _weapon := ""
## Tenu le temps du geste en cours à la place de `_weapon`, vide sinon.
var _held := ""


func _ready() -> void:
	# Debout face à la caméra, un pixel de planche pour une unité du monde : le pixel art reste
	# net et à la taille du jeu (jalon 54, jusqu'à `ActorModel`).
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	pixel_size = 1.0
	shaded = false
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	# Une carte debout n'a pas d'ombre qui ait un sens, et elle coûtait : 600 ennemis tombaient
	# à 107 img/s avec, 160 sans (banc, jalon 54). Les modèles de l'étape 2 auront la leur.
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_variant = variant if variant >= 0 else _pick()
	animation_finished.connect(_on_animation_finished)
	_rebuild()


## Change la silhouette. Elle doit pouvoir s'appliquer **après** le _ready du
## sprite : le joueur est déjà dans la scène quand la sauvegarde est chargée.
func set_variant(index: int) -> void:
	var clamped := posmod(index, SpriteForge.VARIANTS)
	if clamped == _variant:
		return
	_variant = clamped
	_rebuild()


## La silhouette effectivement dessinée. Publique parce qu'elle peut avoir été
## déduite de la position d'apparition plutôt que choisie : c'est elle qu'on
## sauvegarde, pas le champ exporté qui vaut -1.
func current_variant() -> int:
	return _variant


## Change de corps : la classe d'un personnage chargé après le _ready du sprite.
func set_archetype(name_value: String) -> void:
	if name_value == archetype:
		return
	archetype = name_value
	_rebuild()


## Change l'arme tenue, vide pour revenir à celle de l'archétype.
##
## Les planches sont refaites, pas retouchées : une arme fait partie du dessin de
## chaque image. Une trentaine d'images à un quart de milliseconde, une seule fois
## par type d'arme grâce au cache de la forge.
func set_weapon(kind: String) -> void:
	if kind == _weapon:
		return
	_weapon = kind
	_rebuild()


## La silhouette se déduit de la case où l'ennemi apparaît, et non d'un tirage :
## avec un tirage, le même ennemi au même endroit change d'aspect à chaque
## lancement, et un jeu dont les visuels bougent tout seuls paraît instable.
func _pick() -> int:
	var body := get_parent() as Node3D
	var at: Vector3 = body.position if body != null else position
	return SpawnSeed.at(at) % SpriteForge.VARIANTS


## Appelée par l'acteur à chaque tick. facing peut être nul : on garde alors la
## direction précédente plutôt que de repartir vers le bas.
##
## Un coup en cours verrouille tout : ni la direction, ni l'animation ne bougent
## jusqu'à la fin. Sans ce verrou, le caster qui tourne autour du joueur repart
## face à sa trajectoire dès l'image suivante — il tire vers le joueur en jouant
## l'animation de côté — et le changement de nom d'animation relance le coup depuis
## sa première image.
func set_state(moving: bool, facing: Vector3) -> void:
	if _attacking:
		return
	_face(facing)
	_anim = "walk" if moving else "idle"
	_apply()


## play() direct et non _apply() : un nouveau coup doit repartir de sa première
## image même si le précédent jouait encore.
##
## `spell` : un sort joue le lancer, quand le corps en a un — les grilles n'ont que
## le coup. `duration` étire le geste sur ce temps (jalon 47) ; zéro, sa cadence propre.
## `family` : le geste d'une attaque (`Skill.GESTURE`), s'il est sur la planche.
## `held` : ce que la main tient pour ce geste seul, vide pour l'arme. Un sort lancé instrument
## en main se **joue** (`play`, jalon 53), si la planche a ce geste.
func attack(spell := false, duration := 0.0, family := "", held := "") -> void:
	_attacking = true
	_anim = "attack"
	_hold(held)
	var cast := "cast_%s" % _dir
	if not held.is_empty() and sprite_frames.has_animation("play_%s" % _dir):
		cast = "play_%s" % _dir
	var gesture := cast if spell and sprite_frames.has_animation(cast) else "attack_%s" % _dir
	if not family.is_empty() and sprite_frames.has_animation("%s_%s" % [family, _dir]):
		gesture = "%s_%s" % [family, _dir]
	speed_scale = _pace
	if duration > 0.0:
		speed_scale = sprite_frames.get_frame_count(gesture) \
				/ sprite_frames.get_animation_speed(gesture) / duration
	play(gesture)
	# Sous le même nom, `play()` **continue** le geste en cours : une touche tenue relance sur sa
	# dernière image, qui finissait aussitôt et rendait le repos pour tout le coup (jalon 53).
	set_frame_and_progress(0, 0.0)


## Où tombe le coup dans ce geste : son image d'impact sur la planche, sinon
## `DEFAULT_IMPACT` — les grilles n'ont que le coup.
func impact_of(family: String) -> float:
	var sheet := SpriteForge.sheet_of(archetype)
	var at := sheet.impact(family) if sheet != null else -1.0
	return at if at >= 0.0 else DEFAULT_IMPACT


## Le blanchiment encaissé. Ici et non chez chaque acteur : c'est l'ActorSprite qui
## porte le matériau. Le sprite 3D n'en a pas (jalon 54) : flash, liseré et teinte
## reviennent avec `ActorModel`.
func flash() -> void:
	if material_override == null:
		return
	material_override.set_shader_parameter("flash_amount", 1.0)
	await get_tree().create_timer(FLASH_TIME, true, false, true).timeout
	if is_instance_valid(self) and material_override != null:
		material_override.set_shader_parameter("flash_amount", 0.0)


## Le liseré permanent d'un affixe. Un liseré et non une teinte du corps :
## repeindre le sprite fait perdre la couleur de l'archétype, et un grunt cyan ne
## se lit plus comme un grunt.
##
## Sur le shader et non sur une variante de sprite : cinq affixes font trente et
## une combinaisons, et les générer ferait exploser le cache de la forge pour une
## information qui tient dans un vec3.
func set_rim(color: Color, amount: float, width := 1.0) -> void:
	if material_override == null:
		return
	material_override.set_shader_parameter("rim_color", Vector3(color.r, color.g, color.b))
	material_override.set_shader_parameter("rim_amount", amount)
	material_override.set_shader_parameter("rim_width", width)


## La teinte du plus récent de ses états sur tout le corps, et l'animation ralentie
## par le gel.
##
## **Une teinte, contre la règle du liseré juste au-dessus**, et c'est voulu : un
## affixe est l'identité d'un ennemi et ne doit pas lui voler sa couleur ; un état
## dure quelques secondes et doit se lire d'un coup d'œil dans un paquet.
func show_states(states: StatusEffects) -> void:
	_pace = states.speed_factor
	if not _attacking:
		speed_scale = _pace
	if material_override == null:
		return
	var colors := states.colors()
	var c := Color.WHITE if colors.is_empty() else colors[colors.size() - 1]
	material_override.set_shader_parameter("tint_color", Vector3(c.r, c.g, c.b))
	material_override.set_shader_parameter("tint_strength", 0.0 if colors.is_empty() else STATE_TINT)


## Redemande ses planches à la forge et relance l'animation — le seul chemin, pour
## la naissance comme pour les changements de silhouette et d'arme. L'animation en
## cours reprend à zéro : sprite_frames est remplacé.
func _rebuild() -> void:
	_held = ""
	sprite_frames = SpriteForge.frames(archetype, _variant, _weapon)
	# Les pieds sur l'origine, donc sur le sol : calé comme en 2D, le corps descendait de
	# `CENTER_ABOVE_FEET` sous le plan, et le sol le coupait à la taille. En 3D, le haut est +Y.
	offset = Vector2(0.0, SpriteForge.CENTER_ABOVE_FEET - SpriteForge.offset_of(archetype).y)
	_apply()


func _face(facing: Vector3) -> void:
	if facing.length_squared() < 0.01:
		return
	if absf(facing.x) > absf(facing.z) * SIDE_BIAS:
		_dir = "side"
		flip_h = facing.x < 0.0
	else:
		_dir = "down" if facing.z > 0.0 else "up"
		flip_h = false


## Le test sur le nom est indispensable : play() repart de la première image, donc
## l'appeler à chaque tick figerait la marche sur son premier pas.
##
## `next` et non `name` : celui-ci est déjà le nom du nœud, hérité de Node.
func _apply() -> void:
	var next := "%s_%s" % [_anim, _dir]
	if animation != next or not is_playing():
		play(next)


## Les planches de l'objet tenu : la forge les garde en cache, comme celles de l'arme.
func _hold(kind: String) -> void:
	if kind == _held:
		return
	_held = kind
	sprite_frames = SpriteForge.frames(archetype, _variant, _weapon if kind.is_empty() else kind)


func _on_animation_finished() -> void:
	if _attacking:
		_attacking = false
		_hold("")
		speed_scale = _pace
		_anim = "idle"
		_apply()
