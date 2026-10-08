class_name LightningRod
extends Node2D

## Le Paratonnerre de l'Éclair vif (jalon 43) : la marque posée sur le premier ennemi
## touché, vers laquelle les éclairs suivants s'incurvent. **Une par lanceur** : une autre
## cible ne se marque qu'une fois la marque éteinte ; la retoucher la rallume.

## Au-dessus de `Hurtbox.overhead()`, le sommet de la tête, où l'éclair tombe : vu à la capture.
const HEAD := 10.0

## Par lanceur : l'identifiant de ses états → sa marque.
static var _of := {}

var _target: Hurtbox
var _left := SkillStats.ROD_LIFE
var _heir := false
var _storm := false
var _age := 0.0


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
	_of[author.get_instance_id()] = rod
	Settings.veil(rod, Settings.SPELLS)
	DeferredTree.add_deferred(parent, rod, target.global_position)


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


func _ready() -> void:
	z_index = 6


func _physics_process(delta: float) -> void:
	_age += delta
	_left -= delta
	if not is_instance_valid(_target) or _target.is_queued_for_deletion():
		# La Foudre héritée : la marque passe au plus proche, avec le temps qui lui restait.
		_target = Targets.nearest(get_world_2d(), global_position, SkillStats.ROD_REACH) if _heir else null
	if _target == null or _left <= 0.0:
		queue_free()
		return
	global_position = _target.overhead() - Vector2(0.0, HEAD)
	queue_redraw()


func _draw() -> void:
	Lightning.rod(
		DamageType.COLORS[DamageType.Kind.LIGHTNING], int(_age * Lightning.ROD_HZ) + int(get_instance_id())
	).put(self, Vector2.ZERO)
