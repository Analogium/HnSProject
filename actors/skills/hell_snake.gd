class_name HellSnake
extends Node3D

## Le serpent de Serpent infernal : lâché au sol, il y rôde, et son corps brûle ce
## qu'il touche — une fois par période pour chaque cible.

## Vingt anneaux serrés : c'est la **finesse** qui dit « serpent ». À seize anneaux
## de 3,6 et cinq de rayon, c'était un tuyau épais qui ondulait ; le même corps
## plus fin et plus découpé se lit d'un coup. L'écart est choisi pour que la
## longueur totale ne bouge pas — 54 pixels —, sinon la morsure s'allongerait avec
## le dessin.
const RINGS := 20
const SPACING := 2.85
## Avant `SkillStats.CRAWL_SPEED`, qui l'accroît.
const SPEED := 62.0
## Au-delà de la moitié, il tourne vers son point de chute ; à la laisse entière, de
## toutes ses forces. Sans rappel, un cap au hasard l'emmène hors de l'écran en
## quatre secondes.
const LEASH := 44.0
const REMINDER := 3.0
## D'un anneau au centre d'une hurtbox ennemie.
const CONTACT := 11.0
## Le fondu de sa fin : effacé par un plus jeune, il n'a plus que ce temps.
const DISSIPATION := 0.4
## Les petits de l'Hydre, à cette échelle : à pleine taille, on ne les distinguait pas de leur
## parent (choisi sur planche, jalon 41).
const HATCHLING_SIZE := 0.6
## L'écart de deux plaques de sol brûlant le long de sa trace : sous le rayon d'une
## plaque, le sillon est continu.
const GROUND_STEP := 12.0
## L'écart de deux serpents d'un même lancer, en radians.
const BROOD_SPREAD := 0.9
## L'Ouroboros : le rayon de son anneau autour du point visé. Le rayon où il serre sa proie
## (Constriction), où la Spirale finit, et la vitesse à laquelle elle rabat ce qu'elle mord.
const OUROBOROS_RING := 40.0
const COIL := 9.0
const SPIRAL_PULL := 60.0

var _cast: SkillStats
var _author: StatusEffects
var _contacts: Targets.Contacts
var _tint := Color.WHITE
var _anchor := Vector3.ZERO
var _head := Vector3.ZERO
var _cap := 0.0
var _age := 0.0
var _seed_of := 0.0
var _since_ground := 0.0
## Les positions passées de la tête, la plus récente à la fin. Le corps s'y pose à
## intervalles de longueur réguliers : il ondule dans les pas de la tête au lieu de
## pivoter d'un bloc.
var _trace: Array[Vector3] = []
## Les anneaux du corps, tête d'abord, en coordonnées globales.
var _body: Array[Vector3] = []
## Son échelle : 1 pour un serpent, moins pour un petit de l'Hydre.
var _size := 1.0
## Ceux de chaque lanceur — le joueur, le corbeau qui rejoue —, du plus ancien au plus jeune :
## `simultaneous` au plus chacun (jalon 41). Les petits de l'Hydre n'en sont pas.
static var _broods := {}
var _owner_id := 0
## Effacé par un plus jeune : il se dissout sans mordre, sans éclat ni petits.
var _vanishing := false
## La Gloutonnerie : ses proies depuis sa dernière mue, et la vie qu'elles lui ont donnée.
var _preys := 0
var _life_bonus := 0.0
## La proie qu'il enlace (Constriction), et les états qu'il tient sous l'Étau.
var _coiled: Hurtbox
var _held: StatusEffects
var _since_spit := 0.0


## `owner` : qui le lâche, et dont il compte dans la limite ; null pour un petit.
static func drop(
	parent: Node, point: Vector3, cast: SkillStats, direction: Vector3, author: StatusEffects,
	owner: Node = null, size := 1.0
) -> HellSnake:
	var s := HellSnake.new()
	s._size = size
	if owner != null:
		s._owner_id = owner.get_instance_id()
		var brood: Array = _broods.get_or_add(s._owner_id, [])
		brood.append(s)
		while cast.max_simultaneous() > 0 and brood.size() > cast.max_simultaneous():
			(brood.pop_front() as HellSnake)._vanish()
	# La Gloutonnerie reconnaît ses proies au lancer qui les tue : à chacun le sien, la
	# couvée partage celui du sort.
	s._cast = cast.echoed(1.0) if cast.gluttony > 0.0 else cast
	s._author = author
	s._contacts = Targets.Contacts.new(cast.period)
	s._tint = DamageType.COLORS[cast.nature]
	s._anchor = point
	# L'Ouroboros naît sur son anneau, lancé le long de lui.
	s._head = point
	if cast.ouroboros > 0.0:
		s._head -= Flat.orthogonal(direction.normalized()) * OUROBOROS_RING
	s._cap = Flat.angle(direction)
	# Déjà étendu derrière la tête : né en un point, il se lirait comme une braise.
	for i in range(RINGS, 0, -1):
		s._trace.append(s._head - direction.normalized() * SPACING * size * float(i))
	s._trace.append(s._head)
	if cast.gluttony > 0.0 and author != null:
		author.slew.connect(s._on_slew)
	s._body = s._rings()
	parent.add_child(s)
	Settings.veil(s, Settings.SPELLS)
	ElementFx.trail(s, DamageType.COLORS[cast.nature])
	return s


## La Danse du charmeur (jalon 42) : ceux de ce lanceur rôdent désormais autour de ce point.
static func recall(owner: Node, point: Vector3) -> void:
	for snake: HellSnake in _broods.get(owner.get_instance_id(), []):
		snake._anchor = point


## Sa propre errance : deux serpents lâchés ensemble ne serpentent pas d'un même pas.
func _ready() -> void:
	_seed_of = float(get_instance_id() % 1000) * 0.01


func _physics_process(delta: float) -> void:
	_age += delta
	if _coiled != null and not is_instance_valid(_coiled):
		_uncoil()
	# Enlacé, il mord deux fois plus vite : l'horloge de ses contacts court double.
	_contacts.advance(delta * (2.0 if _coiled != null else 1.0))
	_ramp(delta)
	_body = _rings()
	if not _vanishing:
		_bite()
		if _cast.spit > 0.0:
			_spit(delta)
	if _age >= lifetime():
		_die()


## Sa vie, et ce que ses proies y ont ajouté.
func lifetime() -> float:
	return _cast.duration + _life_bonus


## Sa dissolution, tout de suite : le fondu de sa fin, puis rien.
func _vanish() -> void:
	_vanishing = true
	_age = maxf(_age, lifetime() - DISSIPATION)


func _exit_tree() -> void:
	_uncoil()
	var brood: Array = _broods.get(_owner_id, [])
	brood.erase(self)
	if brood.is_empty():
		_broods.erase(_owner_id)


## Ce que sa mort laisse : les petits de l'Hydre (`HATCHLINGS`). Hors d'un rappel de
## collision, ils naissent tout de suite.
func _die() -> void:
	queue_free()
	if _vanishing:
		return
	var brood := int(_cast.hatchlings)
	if brood <= 0:
		return
	var hatchling := _cast.hatchling()
	for i in brood:
		var toward := Flat.from_angle(_cap + TAU * float(i) / float(brood))
		drop(get_parent(), _head, hatchling, toward, _author, null, HATCHLING_SIZE)


## Le **chasseur** (`SkillStats.SEEK`) prend pour point de chute l'ennemi le plus proche
## de sa tête : il rôde autour de lui au lieu de rôder où on l'a lâché.
func _hunt() -> void:
	var prey := Targets.nearest(get_world_3d(), _head, _cast.seek_radius)
	if prey != null:
		_anchor = prey.global_position


## Il rôde ; enlacé, il tourne autour de sa proie ; en Ouroboros, autour du point visé —
## sans chasser.
func _ramp(delta: float) -> void:
	var step := SPEED * (1.0 + _cast.crawl_speed * 0.01) * delta
	if _coiled != null:
		_circle(step, _coiled.global_position, COIL)
	elif _cast.ouroboros > 0.0:
		_circle(step, _anchor, _ring())
	else:
		_prowl(delta, step)
	_trace.append(_head)
	if _cast.ground_duration > 0.0 and not _vanishing:
		_since_ground += step
		if _since_ground >= GROUND_STEP:
			_since_ground = 0.0
			DashTrail.patch(get_parent(), _head, _cast.ground(), _author)


func _prowl(delta: float, step: float) -> void:
	if _cast.seek_radius > 0.0:
		_hunt()
	var turn := sin(_age * 2.6 + _seed_of) * 2.2 + sin(_age * 1.1 + _seed_of * 3.0) * 1.4
	var toward_anchor := _anchor - _head
	var beyond := toward_anchor.length() - LEASH * 0.5
	if beyond > 0.0:
		var force := minf(beyond / (LEASH * 0.5), 1.0)
		turn += angle_difference(_cap, Flat.angle(toward_anchor)) * REMINDER * force
	_cap += turn * delta
	_head += Flat.from_angle(_cap) * step


## Un pas sur ce cercle, dans le sens où il allait.
func _circle(step: float, center: Vector3, ring: float) -> void:
	var from_center := _head - center
	var spin := 1.0 if Flat.cross(from_center, Flat.from_angle(_cap)) >= 0.0 else -1.0
	var phase := Flat.angle(from_center) + spin * step / ring
	_head = center + Flat.from_angle(phase) * ring
	_cap = phase + spin * PI * 0.5


## Le rayon de l'anneau : la Spirale le resserre jusqu'au centre sur la vie du serpent.
func _ring() -> float:
	if _cast.spiral <= 0.0:
		return OUROBOROS_RING
	return lerpf(OUROBOROS_RING, COIL, minf(_age / lifetime(), 1.0))


## Pose les anneaux le long de la trace, et oublie ce qui est derrière la queue.
func _rings() -> Array[Vector3]:
	var current_value := _trace[_trace.size() - 1]
	var out: Array[Vector3] = [current_value]
	var i := _trace.size() - 2
	var rest := SPACING * _size
	while out.size() < RINGS and i >= 0:
		var next_item := _trace[i]
		var d := current_value.distance_to(next_item)
		if d >= rest:
			current_value = current_value.move_toward(next_item, rest)
			out.append(current_value)
			rest = SPACING * _size
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
	var scope := float(RINGS) * SPACING * _size * 0.5 + CONTACT
	for target in Targets.in_circle(get_world_3d(), middle, scope):
		if _touches(target.global_position) and _contacts.accepts(target):
			_bite_one(target)


func _bite_one(target: Hurtbox) -> void:
	# Avant le coup : la pourriture que la morsure pose ne se prolonge pas d'elle-même.
	if _cast.rot_hold > 0.0 and target.states != null:
		target.states.extend(StatusEffects.Kind.ROT, _cast.rot_hold)
	# La Spirale mord depuis le centre, et un recul négatif y rabat la proie.
	if _cast.spiral > 0.0:
		Targets.strike(target, _bite_parts(), _anchor, _author, _cast, -SPIRAL_PULL)
	else:
		Targets.strike(target, _bite_parts(), _head, _author, _cast)
	if _cast.constrict > 0.0 and _coiled == null and is_instance_valid(target):
		_coiled = target
		if _cast.vise > 0.0 and target.states != null:
			_held = target.states
			_held.hold(true)


## Le tirage d'une morsure, grossi par ses proies.
func _bite_parts() -> Array[float]:
	return DamageType.scaled(_cast.roll(Game.rng), 1.0 + _cast.gluttony * 0.01 * float(_preys))


func _uncoil() -> void:
	_coiled = null
	if _held != null:
		_held.hold(false)
		_held = null


## Le Crachat : toutes les `SPIT_PERIOD`, des étincelles vers la proie la plus proche, s'il
## y en a une à portée ; sinon il guette.
func _spit(delta: float) -> void:
	_since_spit += delta
	if _since_spit < SkillStats.SPIT_PERIOD:
		return
	var prey := Targets.nearest(get_world_3d(), _head, SkillStats.SPIT_REACH)
	if prey == null:
		return
	_since_spit = 0.0
	var spat := _cast.spark(_cast.spit * 0.01)
	var toward := _head.direction_to(prey.global_position)
	var count := 1 + int(_cast.spit_fan)
	for i in count:
		var heading := Flat.rotated(toward, (float(i) - float(count - 1) * 0.5) * SkillStats.SPIT_SPREAD)
		Fireball.spark(get_parent(), _head, heading, spat, _author)


## Une proie de sa morsure : la Gloutonnerie le grossit, `GLUTTONY_MOST` fois au plus.
## Depuis le coup qui tue — l'explosion de la mue se pose d'elle-même en différé.
func _on_slew(cast: SkillStats, _at: Vector3, _victim: StatusEffects) -> void:
	if cast != _cast or _vanishing or _preys >= SkillStats.GLUTTONY_MOST:
		return
	_preys += 1
	_life_bonus += SkillStats.GLUTTONY_LIFE
	_size = 1.0 + SkillStats.GLUTTONY_GROWTH * float(_preys)
	if _preys == SkillStats.GLUTTONY_MOST and _cast.growth_molt > 0.0:
		_molt()


## La Mue de croissance : une gerbe de la force d'une morsure repue, puis le serpent
## repart de zéro — taille, vie, proies. La gerbe a son propre lancer : ses tués ne le
## nourrissent pas, sinon une mue en déclencherait une autre dans la même meute.
func _molt() -> void:
	Explosion.put(
		get_parent(), _head, _bite_parts(), SkillStats.MOLT_RADIUS, null, _tint, _author,
		_cast.echoed(1.0)
	)
	_preys = 0
	_life_bonus = 0.0
	_size = 1.0
	_age = 0.0


func _touches(point: Vector3) -> bool:
	for ring in _body:
		if ring.distance_squared_to(point) <= CONTACT * CONTACT:
			return true
	return false

