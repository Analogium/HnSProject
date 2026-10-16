class_name RatBurst
extends Node2D

## L'éclat des rats de la Danse macabre (jalon 53), « rats qui jaillissent » choisi sur planche.
## Un dessin et rien d'autre : les coups sont portés par `Vermin.burst()`.

const LIFETIME := 0.4
## Au-delà, l'éventail se refermait en boule.
const MOST := 5

var _count := 1
var _age := 0.0


static func pop(parent: Node, at: Vector2, count: int) -> void:
	if not is_instance_valid(parent) or count <= 0:
		return
	var burst := RatBurst.new()
	burst._count = mini(count, MOST)
	parent.add_child(burst)
	Settings.veil(burst, Settings.SPELLS)
	burst.global_position = at


func _ready() -> void:
	z_index = 3


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	Piper.pose_burst(self, _count, _age / LIFETIME)
