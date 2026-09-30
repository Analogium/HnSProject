class_name LeapArc
extends Node2D

## Ce que laisse le Bond (jalon 34, « arc et cratère » choisi sur planche) : un arc de
## bouffées du départ à l'arrivée, qui s'éteint **depuis le départ**, et un cratère de
## brûlures à l'arrivée. Il ne frappe pas : la morsure, c'est l'explosion d'arrivée.
## Rien ne pâlit — une bouffée se coupe, le cratère se coupe.

## Le sommet de l'arc au-dessus de la corde, et le nombre de bouffées.
const PEAK := 30.0
const PUFFS := 9
## Ce que met l'arc à s'éteindre ; ce que tient le cratère, dont les langues d'abord.
const ARC_LIFE := 0.35
const CRATER_LIFE := 1.0
const CRATER_FLAMES_LIFE := 0.5
## Le cratère : une couronne de brûlures couchée (un cercle vu d'en haut, aplati).
const CRATER_RADIUS := 12.0
const CRATER_FLATTEN := 0.55

var _tint := Color.WHITE
## En repère local : le nœud est posé au départ.
var _toward := Vector2.ZERO
var _age := 0.0


static func leave(parent: Node, from_value: Vector2, to: Vector2, cast: SkillStats) -> LeapArc:
	var arc := LeapArc.new()
	arc._tint = DamageType.COLORS[cast.nature]
	arc._toward = to - from_value
	parent.add_child(arc)
	Settings.veil(arc, Settings.SPELLS)
	arc.global_position = from_value
	return arc


func _ready() -> void:
	z_index = 2


func _physics_process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _age >= CRATER_LIFE:
		queue_free()


func _draw() -> void:
	var burns := EffectForge.burns()
	var count := maxi(int(CRATER_RADIUS * 1.3), 5)
	for k in count:
		var around := Vector2.RIGHT.rotated(TAU * float(k) / float(count))
		EffectForge.put_centered(
			self, burns[k % burns.size()],
			_toward + around * Vector2(CRATER_RADIUS, CRATER_RADIUS * CRATER_FLATTEN)
		)
	if _age < CRATER_FLAMES_LIFE:
		var short := EffectForge.small_flames(_tint)
		for k in 4:
			var around := Vector2.RIGHT.rotated(TAU * float(k) / 4.0 + 0.4)
			var tex: Texture2D = short[(int(_age * EffectForge.FLAME_HZ) + k) % short.size()]
			var foot := _toward + around * Vector2(CRATER_RADIUS * 0.8, CRATER_RADIUS * 0.45)
			draw_texture_rect(
				tex, Rect2(EffectForge.snap(self, foot - Vector2(tex.get_width() * 0.5, tex.get_height() - 1)),
				Vector2(tex.get_size())), false
			)
	# L'arc s'éteint du départ vers l'arrivée : une bouffée tient tant que l'âge n'a pas
	# rattrapé sa place sur l'arc. La plus vive près de l'arrivée.
	var puffs := EffectForge.puffs(_tint)
	var gone := _age / ARC_LIFE
	for k in PUFFS:
		var t := float(k + 1) / float(PUFFS + 1)
		if t < gone:
			continue
		var at := _toward * t + Vector2(0.0, -PEAK * 4.0 * t * (1.0 - t))
		EffectForge.put_centered(self, puffs[clampi(2 - int(t * 3.0), 0, puffs.size() - 1)], at)
