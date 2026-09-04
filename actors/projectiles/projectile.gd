class_name Projectile
extends Area2D

## Tir générique, partagé par le caster et par le joueur : la logique est la
## même — avancer, s'arrêter au mur, blesser la première Hurtbox rencontrée.
## Ce sont les layers de collision de la scène qui décident de qui il peut
## toucher, pas le script. D'où enemy_bolt.tscn et player_bolt.tscn.
##
## Le document ne fournit pas ce fichier, il n'en décrit que l'appel :
## setup(direction, dégâts, source).
##
## Contrairement aux ennemis, il garde son propre _physics_process : il n'est
## pas piloté par l'EnemyManager. Le jour où les projectiles se comptent par
## centaines, c'est le même chemin de migration — une boucle unique — mais ça
## ne se justifie pas au jalon 1.

@export var speed: float = 140.0
## Zéro par défaut, comme CharacterStats.knockback_force : ce jeu n'a pas de
## recul. Un nouveau projectile ne doit pas en réintroduire sans qu'on le veuille.
@export var knockback: float = 0.0
@export var lifetime: float = 3.0
## Les tirs du joueur figent brièvement le jeu à l'impact, comme le corps à
## corps ; ceux des ennemis non, sinon se faire tirer dessus hacherait le jeu.
@export var hit_stop_on_impact: bool = false

var _dir := Vector2.RIGHT
var _damage := 0.0
var _source: Node2D
var _life := 0.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


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
	var info := DamageInfo.new(_damage, global_position, knockback)
	(area as Hurtbox).take_damage(info)
	# Le tir n'est qu'un messager : c'est le lanceur qui porte l'affixe, donc
	# c'est lui qu'on soigne, s'il est encore en vie.
	#
	# La validité se teste **avant** la conversion : convertir un objet déjà
	# libéré est en soi une erreur, et elle interrompait la fonction avant son
	# queue_free(). Le tir d'un caster tué pendant que sa bille volait
	# traversait alors le joueur en le blessant à chaque image, jusqu'à
	# expiration. Le cas se présente à chaque caster abattu à distance.
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
