class_name LungeTrail
extends Node2D

## Ce que laisse une frappe vive, choisi sur planche (jalon 28) : un fil d'acier du
## départ à l'arrivée, et une entaille chaude en travers de la cible. Ne frappe rien :
## le coup est parti de `Player._lunge()`.
##
## Les deux traits partent dans n'importe quelle direction : rastérisés **à l'angle
## exact** à la naissance (`Slash.cleave()`), puis dissous en `STEPS` crans fabriqués
## d'avance — une planche ne pâlit pas.

const LIFETIME := 0.25
const STEPS := 4
const PATH_WIDTH := 1.2
const CUT_REACH := 12.0
const CUT_WIDTH := 2.8
## Le fil disparaît avant l'entaille : c'est elle, le coup.
const PATH_PACE := 1.3
const CUT_PACE := 1.1

var _age := 0.0
var _toward := Vector2.ZERO
var _target := Vector2.ZERO
var _path: Array[EffectForge.Piece] = []
var _cut: Array[EffectForge.Piece] = []


static func leave(parent: Node, from_value: Vector2, landing: Vector2, target: Vector2) -> LungeTrail:
	var trail := LungeTrail.new()
	trail._toward = landing - from_value
	trail._target = target - from_value
	parent.add_child(trail)
	Settings.veil(trail, Settings.SPELLS)
	trail.global_position = from_value
	return trail


func _ready() -> void:
	z_index = 2
	_path = EffectForge.dissolving(Slash.cleave(Slash.STEEL, _toward, PATH_WIDTH), STEPS)
	var across := (_target - _toward).orthogonal().normalized() * CUT_REACH
	if across == Vector2.ZERO:
		across = Vector2.UP * CUT_REACH
	_target -= across
	_cut = EffectForge.dissolving(Slash.cleave(SwingArc.STRIKE_COLOR, across * 2.0, CUT_WIDTH), STEPS)


func _physics_process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _age >= LIFETIME:
		queue_free()


func _draw() -> void:
	var k := _age / LIFETIME
	var step := int(k * PATH_PACE * STEPS)
	if step < STEPS:
		_path[step].put(self, Vector2.ZERO)
	step = int(k * CUT_PACE * STEPS)
	if step < STEPS:
		_cut[step].put(self, _target)

