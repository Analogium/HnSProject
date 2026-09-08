class_name Projectile
extends Area2D

## Tir générique, partagé par le caster et par le joueur : avancer, s'arrêter au
## mur, blesser la première Hurtbox rencontrée. Ce sont les layers de collision de
## la scène qui décident de qui il peut toucher, pas le script — d'où
## enemy_bolt.tscn et player_bolt.tscn.
##
## Contrairement aux ennemis, il garde son propre _physics_process. Le jour où les
## projectiles se compteront par centaines, c'est le même chemin de migration
## qu'eux : une boucle unique.

@export var speed: float = 140.0
## Zéro par défaut, comme CharacterStats.knockback_force : ce jeu n'a pas de
## recul. Un nouveau projectile ne doit pas en réintroduire sans qu'on le veuille.
@export var knockback: float = 0.0
@export var lifetime: float = 3.0
## Les tirs du joueur figent brièvement le jeu à l'impact, comme le corps à
## corps ; ceux des ennemis non, sinon se faire tirer dessus hacherait le jeu.
@export var hit_stop_on_impact: bool = false
## La nature des dégâts portés. Sur la scène et non passée à spawn() : c'est le
## tir qui est de froid ou de foudre, pas le geste de le lancer — et enemy_bolt
## comme player_bolt le déclarent une fois pour toutes dans l'inspecteur.
@export var damage_type: DamageType.Kind = DamageType.Kind.PHYSICAL

## Distance à laquelle le tir naît devant son lanceur. Trop court, il apparaît
## dans le corps et touche le tireur lui-même ; trop loin, il saute une case.
const MUZZLE := 12.0

var _dir := Vector2.RIGHT
var _damage := 0.0
var _source: Node2D
var _life := 0.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


## Fait partir un tir, avec le piège de l'ordre : add_child d'abord, sinon
## global_position ne veut rien dire.
##
## Ajout immédiat et non différé, contrairement à GroundItem : un tir part toujours
## depuis _physics_process, jamais depuis un callback de collision.
static func spawn(
	parent: Node, scene: PackedScene, from: Vector2, dir: Vector2,
	damage: float, source: Node2D
) -> Projectile:
	if scene == null or parent == null:
		return null
	var bolt: Projectile = scene.instantiate()
	parent.add_child(bolt)
	bolt.global_position = from + dir * MUZZLE
	bolt.setup(dir, damage, source)
	return bolt


## À appeler après add_child, sinon global_position ne veut rien dire.
func setup(dir: Vector2, damage: float, source: Node2D) -> void:
	_dir = dir.normalized()
	_damage = damage
	_source = source
	rotation = _dir.angle()


func _physics_process(delta: float) -> void:
	global_position += _dir * speed * delta
	_life += delta
	if _life >= lifetime:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if not area is Hurtbox:
		return
	var info := DamageInfo.new(
		_damage, global_position, knockback, false, damage_type
	)
	(area as Hurtbox).take_damage(info)
	# Le tir n'est qu'un messager : c'est le lanceur qui porte l'affixe, donc
	# c'est lui qu'on soigne, s'il est encore en vie.
	#
	# La validité se teste **avant** la conversion : convertir un objet déjà libéré
	# est en soi une erreur, et elle interrompt la fonction avant son queue_free().
	# Le tir d'un caster tué pendant que sa bille vole traverse alors le joueur en
	# le blessant à chaque image, jusqu'à expiration.
	if is_instance_valid(_source):
		var caster := _source as Enemy
		if caster != null:
			caster.on_damage_dealt(info.amount)
	if hit_stop_on_impact:
		Game.hit_stop()
	queue_free()


## Le masque ne retient que le décor pour les corps : le tir s'arrête au mur,
## et traverse les autres ennemis sans les toucher.
func _on_body_entered(_body: Node2D) -> void:
	queue_free()
