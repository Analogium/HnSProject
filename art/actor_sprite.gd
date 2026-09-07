class_name ActorSprite
extends AnimatedSprite2D

## Le sprite d'un acteur : il reçoit un état (immobile / en marche / en train de
## frapper) et une direction, et choisit l'animation. Les acteurs ne connaissent
## donc jamais un nom d'animation.
##
## Volontairement sans _process : avec soixante-dix ennemis à l'écran, un
## rappel par image et par sprite se paierait pour rien. La lecture des images
## est déjà faite par AnimatedSprite2D en interne, et la fin d'une attaque
## arrive par le signal animation_finished.

## Doit correspondre à un nom connu de SpriteForge.ARCHETYPES.
@export var archetype: String = "grunt"
## -1 : silhouette déduite de la position d'apparition. Un numéro fixe force une
## variante précise, ce dont on se sert pour le joueur.
@export var variant: int = -1

## Marge avant de basculer en vue de profil. Sans elle, une trajectoire proche
## de la diagonale ferait clignoter le sprite entre deux directions à chaque
## image ; le coup d'œil du joueur y est très sensible.
const SIDE_BIAS := 1.15

## Durée du flash blanc encaissé. En secondes réelles : le hit-stop ralentit le
## jeu d'un facteur 50, et un flash étiré d'autant resterait à l'écran presque
## quatre secondes.
const FLASH_TIME := 0.08

var _dir := "down"
var _anim := "idle"
var _attacking := false
var _variant := 0
var _weapon := ""


func _ready() -> void:
	_variant = variant if variant >= 0 else _pick()
	animation_finished.connect(_on_animation_finished)
	_rebuild()


## Change la silhouette. C'est le choix que le joueur fait à la création de son
## personnage, et il doit pouvoir s'appliquer **après** le _ready du sprite : le
## joueur est déjà dans la scène quand la sauvegarde est chargée.
##
## Passe par le même chemin que l'arme — les planches sont refaites, jamais
## retouchées — et le cache de la forge fait que la quatrième silhouette d'un
## personnage déjà vu ne coûte rien.
func set_variant(index: int) -> void:
	var borne := posmod(index, SpriteForge.VARIANTS)
	if borne == _variant:
		return
	_variant = borne
	_rebuild()


## La silhouette effectivement dessinée. Publique parce qu'elle peut avoir été
## déduite de la position d'apparition plutôt que choisie : c'est elle qu'on
## sauvegarde, pas le champ exporté qui vaut -1.
func current_variant() -> int:
	return _variant


## Change l'arme tenue, vide pour revenir à celle de l'archétype.
##
## Les planches sont refaites, pas retouchées : une arme fait partie du dessin
## de chaque image. Une trentaine d'images à un quart de milliseconde, une seule
## fois par type d'arme grâce au cache de la forge — c'est le prix d'un
## changement d'équipement, pas d'une image de jeu.
func set_weapon(kind: String) -> void:
	if kind == _weapon:
		return
	_weapon = kind
	_rebuild()


## La silhouette se déduit de la case où l'ennemi apparaît, et non d'un tirage.
##
## Avec un tirage, le même ennemi au même endroit changeait d'aspect à chaque
## lancement : rien de cassé, mais un jeu dont les visuels bougent tout seuls
## paraît instable. Ici, la position vient du générateur de zone, lui-même issu
## d'une graine — donc une même zone redonne exactement les mêmes ennemis, et
## deux zones différentes gardent des mélanges différents.
func _pick() -> int:
	var body := get_parent() as Node2D
	var at: Vector2 = body.position if body != null else position
	return absi(hash(Vector2i(at.round()))) % SpriteForge.VARIANTS


## Appelée par l'acteur à chaque tick. facing peut être nul : on garde alors la
## direction précédente plutôt que de repartir arbitrairement vers le bas.
##
## Un coup en cours verrouille tout : ni la direction, ni l'animation ne
## bougent jusqu'à la fin. Sans ce verrou, le caster qui tourne autour du
## joueur repartait face à sa trajectoire dès l'image suivante — il tirait donc
## vers le joueur en jouant l'animation de côté — et le changement de nom
## d'animation relançait le coup depuis sa première image. Même chose pour le
## joueur dès qu'on bougeait la souris pendant le swing.
func set_state(moving: bool, facing: Vector2) -> void:
	if _attacking:
		return
	_face(facing)
	_anim = "walk" if moving else "idle"
	_apply()


## play() direct et non _apply() : un nouveau coup doit repartir de sa première
## image même si le précédent jouait encore.
func attack() -> void:
	_attacking = true
	_anim = "attack"
	play("attack_%s" % _dir)


## Le blanchiment encaissé. Il vit ici et non chez chaque acteur : le joueur,
## l'ennemi et le mannequin en écrivaient trois copies identiques, alors qu'ils
## ont tous un ActorSprite et que c'est lui qui porte le matériau.
##
## Le matériau est propre à chaque instance grâce à resource_local_to_scene,
## coché sur le ShaderMaterial des quatre scènes d'acteur — sans quoi tous les
## grunts de l'écran flasheraient ensemble.
func flash() -> void:
	if material == null:
		return
	material.set_shader_parameter("flash_amount", 1.0)
	await get_tree().create_timer(FLASH_TIME, true, false, true).timeout
	if is_instance_valid(self) and material != null:
		material.set_shader_parameter("flash_amount", 0.0)


## Le liseré permanent d'un affixe. Un liseré et non une teinte du corps :
## repeindre le sprite fait perdre la couleur de l'archétype, et un grunt cyan
## ne se lit plus comme un grunt. Ici le corps garde ses teintes et l'affixe
## s'annonce autour.
##
## Sur le shader et non sur une variante de sprite : cinq affixes font trente et
## une combinaisons, et les générer ferait exploser le cache de la forge pour
## une information qui tient dans un vec3.
func set_rim(color: Color, amount: float, width := 1.0) -> void:
	if material == null:
		return
	material.set_shader_parameter("rim_color", Vector3(color.r, color.g, color.b))
	material.set_shader_parameter("rim_amount", amount)
	material.set_shader_parameter("rim_width", width)


## Redemande ses planches à la forge et relance l'animation. Trois endroits le
## faisaient chacun de leur côté — la naissance, le changement de silhouette et
## le changement d'arme — et le jour où la clé de la forge prendra une dimension
## de plus, celui qui l'oublierait garderait un sprite qui ne se met plus à jour.
##
## L'animation en cours reprend à zéro : sprite_frames est remplacé, il n'y a
## plus d'image courante à préserver.
func _rebuild() -> void:
	sprite_frames = SpriteForge.frames(archetype, _variant, _weapon)
	_apply()


func _face(facing: Vector2) -> void:
	if facing.length_squared() < 0.01:
		return
	if absf(facing.x) > absf(facing.y) * SIDE_BIAS:
		_dir = "side"
		flip_h = facing.x < 0.0
	else:
		_dir = "down" if facing.y > 0.0 else "up"
		flip_h = false


## Le test sur le nom est indispensable : play() repart de la première image,
## donc l'appeler à chaque tick figerait la marche sur son premier pas.
##
## next et non name : name est déjà le nom du nœud, hérité de Node, et le
## masquer rendrait le code trompeur à la première relecture.
func _apply() -> void:
	var next := "%s_%s" % [_anim, _dir]
	if animation != next or not is_playing():
		play(next)


func _on_animation_finished() -> void:
	if _attacking:
		_attacking = false
		_anim = "idle"
		_apply()
