class_name LightningRod
extends Node3D

## Le Paratonnerre de l'Éclair vif (jalon 43) : la marque posée sur le premier ennemi
## touché, vers laquelle les éclairs suivants s'incurvent. **Une par lanceur** : une autre
## cible ne se marque qu'une fois la marque éteinte ; la retoucher la rallume.

## La foudre appelée (jalon 54, le parti pris de la 2D choisi de nouveau sur planche contre une
## couronne sur la tête, l'étincelle des charges, une cible au sol et le halo) : l'éclair du Nuage
## d'orage tombe sur la tête toutes les `CALL` s et y éclate ; une étincelle y grésille entre deux.
const CALL := 0.5
const BOLT_TALL := 40.0
const SPARK := 4.0
const FLASH := 12.0
const FLASH_LIFE := 0.18
## La tête d'un corps sans modèle 3D, à cette hauteur.
const HEAD := 24.0

## Par lanceur : l'identifiant de ses états → sa marque.
static var _of := {}

var _target: Hurtbox
var _left := SkillStats.ROD_LIFE
var _heir := false
var _storm := false
var _nature := DamageType.Kind.LIGHTNING
var _head := HEAD
var _spark: MeshInstance3D
var _since_call := CALL


## Ce que vise la marque de ce lanceur, ou null.
static func target_of(author: StatusEffects) -> Hurtbox:
	var rod := _rod_of(author)
	return rod._target if rod != null else null


## La même, si l'arbre a pris la Cible de l'orage : ce que ses nuages frappent en plus.
static func storm_target_of(author: StatusEffects) -> Hurtbox:
	var rod := _rod_of(author)
	return rod._target if rod != null and rod._storm else null


## Un éclair vient de toucher `target`. **Depuis un rappel de collision** : la marque
## naît en différé (invariant 4).
static func mark(parent: Node, target: Hurtbox, author: StatusEffects, cast: SkillStats) -> void:
	if author == null or not is_instance_valid(target):
		return
	var rod := _rod_of(author)
	if rod != null:
		if rod._target == target:
			rod._left = SkillStats.ROD_LIFE
		return
	rod = LightningRod.new()
	rod._target = target
	rod._heir = cast.rod_heir > 0.0
	rod._storm = cast.storm_target > 0.0
	rod._nature = cast.nature
	rod._head = _head_of(target)
	_of[author.get_instance_id()] = rod
	Settings.veil(rod, Settings.SPELLS)
	rod._spark = BoltFx.spark(rod, SPARK)
	rod._spark.position = Vector3.UP * (rod._head + SPARK * 0.5)
	DeferredTree.add_deferred(parent, rod, target.global_position)


## Le sommet de la tête de ce que vise la marque : la hauteur de son modèle 3D, ou `HEAD`.
static func _head_of(target: Hurtbox) -> float:
	var body := target.get_parent()
	var model: Variant = body.get(&"model") if body != null else null
	var height := (model as ActorModel).height() if model is ActorModel else 0.0
	return height if height > 0.0 else HEAD


## La marque vivante de ce lanceur. Une marque dont le parent a disparu avant l'appel
## différé est libérée sans entrer dans l'arbre : la validité le dit.
static func _rod_of(author: StatusEffects) -> LightningRod:
	if author == null:
		return null
	var rod = _of.get(author.get_instance_id())
	if rod == null or not is_instance_valid(rod) or rod.is_queued_for_deletion():
		_of.erase(author.get_instance_id())
		return null
	return rod


func _physics_process(delta: float) -> void:
	_left -= delta
	if not is_instance_valid(_target) or _target.is_queued_for_deletion():
		# La Foudre héritée : la marque passe au plus proche, avec le temps qui lui restait.
		_target = Targets.nearest(get_world_3d(), global_position, SkillStats.ROD_REACH) if _heir else null
		if _target != null:
			_head = _head_of(_target)
			_spark.position = Vector3.UP * (_head + SPARK * 0.5)
	if _target == null or _left <= 0.0:
		queue_free()
		return
	global_position = _target.global_position


func _process(delta: float) -> void:
	_since_call += delta
	if _since_call < CALL:
		return
	_since_call = 0.0
	var head := global_position + Vector3.UP * _head
	StormCloudFx.drop(self, head, _nature, BOLT_TALL, self)
	var flash := BoltFx.flash_of(_nature)
	flash.top_level = true
	add_child(flash)
	ElementFx.veil_like(flash, self)
	flash.global_position = head + Vector3.UP
	BoltFx.fade(flash, Vector3.ONE * FLASH, FLASH_LIFE)

