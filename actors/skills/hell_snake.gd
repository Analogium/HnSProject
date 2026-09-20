class_name HellSnake
extends Node2D

## Le serpent de Serpent infernal : lâché au sol, il y rôde, et son corps brûle ce
## qu'il touche — une fois par période pour chaque cible.

## Seize anneaux : c'est la longueur qui dit « serpent ». Court et épais — neuf
## anneaux —, il se lisait comme une larve ; long et fin — douze —, il se perdait
## dans l'écran.
const RINGS := 16
const SPACING := 3.4
const SPEED := 62.0
## Au-delà de la moitié, il tourne vers son point de chute ; à la laisse entière, de
## toutes ses forces. Sans rappel, un cap au hasard l'emmène hors de l'écran en
## quatre secondes.
const LEASH := 44.0
const REMINDER := 3.0
## D'un anneau au centre d'une hurtbox ennemie.
const CONTACT := 11.0
const HEAD_RADIUS := 3.8
const TAIL_RADIUS := 1.4
## Un anneau sur deux plus sombre : ce sont les écailles qui disent « serpent ».
const SCALE_PLATE := 0.22
const SPAWN := 0.2
const DISSIPATION := 0.4
const EYES := Color(0.15, 0.05, 0.02)
const TONGUE := Color(0.9, 0.15, 0.1)

var _cast: SkillStats
var _author: StatusEffects
var _contacts: Targets.Contacts
var _tint := Color.WHITE
var _anchor := Vector2.ZERO
var _head := Vector2.ZERO
var _cap := 0.0
var _age := 0.0
var _seed_of := 0.0
## Les positions passées de la tête, la plus récente à la fin. Le corps s'y pose à
## intervalles de longueur réguliers : il ondule dans les pas de la tête au lieu de
## pivoter d'un bloc.
var _trace: Array[Vector2] = []
## Les anneaux de l'image, tête d'abord, en coordonnées globales.
var _body: Array[Vector2] = []


static func drop(
	parent: Node, point: Vector2, cast: SkillStats, direction: Vector2, author: StatusEffects
) -> HellSnake:
	var s := HellSnake.new()
	s._cast = cast
	s._author = author
	s._contacts = Targets.Contacts.new(cast.period)
	s._tint = DamageType.COLORS[cast.dominant_nature()]
	s._anchor = point
	s._head = point
	s._cap = direction.angle()
	# Déjà étendu derrière la tête : né en un point, il se lirait comme une braise.
	for i in range(RINGS, 0, -1):
		s._trace.append(point - direction.normalized() * SPACING * float(i))
	s._trace.append(point)
	s._body = s._rings()
	parent.add_child(s)
	return s


func _ready() -> void:
	z_index = 1
	_seed_of = float(get_instance_id() % 1000) * 0.01


func _physics_process(delta: float) -> void:
	_age += delta
	_contacts.advance(delta)
	_ramp(delta)
	_body = _rings()
	_bite()
	queue_redraw()
	if _age >= _cast.duration:
		queue_free()


func _ramp(delta: float) -> void:
	var turn := sin(_age * 2.6 + _seed_of) * 2.2 + sin(_age * 1.1 + _seed_of * 3.0) * 1.4
	var toward_anchor := _anchor - _head
	var beyond := toward_anchor.length() - LEASH * 0.5
	if beyond > 0.0:
		var force := minf(beyond / (LEASH * 0.5), 1.0)
		turn += angle_difference(_cap, toward_anchor.angle()) * REMINDER * force
	_cap += turn * delta
	_head += Vector2.from_angle(_cap) * SPEED * delta
	_trace.append(_head)


## Pose les anneaux le long de la trace, et oublie ce qui est derrière la queue.
func _rings() -> Array[Vector2]:
	var current_value := _trace[_trace.size() - 1]
	var out: Array[Vector2] = [current_value]
	var i := _trace.size() - 2
	var rest := SPACING
	while out.size() < RINGS and i >= 0:
		var next_item := _trace[i]
		var d := current_value.distance_to(next_item)
		if d >= rest:
			current_value = current_value.move_toward(next_item, rest)
			out.append(current_value)
			rest = SPACING
		else:
			rest -= d
			current_value = next_item
			i -= 1
	while out.size() < RINGS:
		out.append(out[out.size() - 1])
	if i > 0:
		_trace = _trace.slice(i)
	return out


func _bite() -> void:
	var middle := _body[int(RINGS * 0.5)]
	var scope := float(RINGS) * SPACING * 0.5 + CONTACT
	for target in Targets.in_circle(get_world_2d(), middle, scope):
		if _touches(target.global_position) and _contacts.accepts(target):
			Targets.strike(target, _cast.roll(Game.rng), _head, _author, _cast)


func _touches(point: Vector2) -> bool:
	for ring in _body:
		if ring.distance_squared_to(point) <= CONTACT * CONTACT:
			return true
	return false


func _draw() -> void:
	var fade := minf(_age / SPAWN, 1.0) * clampf((_cast.duration - _age) / DISSIPATION, 0.0, 1.0)
	# La tête tire vers le blanc chaud, la queue vers l'ombre : c'est le sens de la
	# bête. **Un quart et pas plus** : à 0,6 le corps sortait beige, et un ver beige
	# n'est pas un serpent de feu. La lumière est dans les langues, pas dans la peau.
	var head := _tint.lerp(Fire.WARM, 0.25)
	var tail := _tint.darkened(0.45)
	# De la queue à la tête, halos d'abord : un halo peint après un anneau voisin le
	# délaverait.
	for i in range(RINGS - 1, -1, -1):
		var k := float(i) / float(RINGS - 1)
		Glow.draw_blob(self, to_local(_body[i]), lerpf(HEAD_RADIUS, TAIL_RADIUS, k) * 2.0, Color(_tint, 0.30 * fade))
	for i in range(RINGS - 1, -1, -1):
		var k := float(i) / float(RINGS - 1)
		var color := head.lerp(tail, k)
		if i % 2 == 1:
			color = color.darkened(SCALE_PLATE)
		draw_circle(to_local(_body[i]), lerpf(HEAD_RADIUS, TAIL_RADIUS, k), Color(color, fade))

	# Un serpent de feu brûle : une langue un anneau sur deux, décroissante vers la
	# queue. Sans elles, c'est un tube lumineux qui ondule. Elles ne mordent pas —
	# la morsure, ce sont les anneaux.
	if _cast.dominant_nature() == DamageType.Kind.FIRE:
		# La queue ne lèche pas : ses langues tomberaient sous le pixel. Et elles sont
		# **plus grandes qu'ailleurs** : le serpent se dessine en mélange normal, où
		# les trois couches ne s'additionnent pas — à la taille du brasier, on ne les
		# voyait pas.
		for i in range(0, RINGS - 4, 2):
			var k := float(i) / float(RINGS - 1)
			Fire.draw_tongue(
				self, to_local(_body[i]), Vector2.UP,
				(11.0 - 5.0 * k) + 2.5 * Fire.breath(_age, i), 3.0 - 1.4 * k,
				_tint, fade, 1.8 * Fire.breath(_age * 0.7, i + 2)
			)

	var before := Vector2.from_angle(_cap)
	var side := before.orthogonal()
	var t := to_local(_body[0])
	for sign_value: float in [-1.0, 1.0]:
		draw_rect(Rect2(t + before * 1.4 + side * 1.5 * sign_value - Vector2(0.5, 0.5), Vector2.ONE), Color(EYES, fade))
	# La langue, par intermittence : toujours sortie, elle se lit comme une tige.
	if fmod(_age + _seed_of, 0.7) < 0.15:
		var root := t + before * HEAD_RADIUS
		var tip_end := root + before * 3.5
		draw_line(root, tip_end, Color(TONGUE, fade), 1.0)
		draw_line(tip_end, tip_end + (before + side).normalized() * 1.5, Color(TONGUE, fade), 1.0)
		draw_line(tip_end, tip_end + (before - side).normalized() * 1.5, Color(TONGUE, fade), 1.0)
