class_name RatRun
extends Node2D

## Les rats qui passent d'un mort à son héritier (jalon 53) : la Contagion, la Disette — « les rats
## courent » choisi sur planche. Une bouffée là où il tombe, puis ses rats filent au sol jusqu'à
## l'héritier, qu'ils suivent s'il bouge. Un dessin : les rats sont déjà accrochés (`Vermin`).

const SPEED := 220.0
## Ce que dure la bouffée du mort, et l'écart entre deux rats de la file.
const PUFF_TIME := 0.15
const GAP := 12.0
## Au-delà, la file se lit comme un tapis.
const MOST := 3

var _heir: Hurtbox
var _to := Vector2.ZERO
var _count := 1
var _run := 0.0
var _age := 0.0
var _from := Vector2.ZERO


static func send(at: Vector2, heir: Hurtbox, count: int) -> void:
	if not is_instance_valid(heir) or count <= 0:
		return
	var run := RatRun.new()
	run._heir = heir
	run._to = heir.global_position
	run._count = mini(count, MOST)
	DashTrail.layer(heir).add_child(run)
	Settings.veil(run, Settings.SPELLS)
	run.global_position = at
	run._from = at


func _physics_process(delta: float) -> void:
	_age += delta
	if is_instance_valid(_heir):
		_to = _heir.global_position
	var left := global_position.distance_to(_to)
	var step := SPEED * delta
	if left <= step and _age >= PUFF_TIME:
		queue_free()
		return
	global_position = global_position.move_toward(_to, step)
	_run += step
	queue_redraw()


func _draw() -> void:
	Piper.pose_run(self, _count, global_position.direction_to(_to), _run, _from - global_position, _age / PUFF_TIME)
