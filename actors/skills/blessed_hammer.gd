class_name BlessedHammer
extends Node3D

## Le marteau du Marteau béni (jalon 48) : il part du point de lancer en spirale qui
## s'élargit jusqu'à son rayon, frappe ce qu'il croise — un même ennemi au plus une fois par
## période — et s'éteint au bout de sa durée. Sous la Gravitation, il tourne autour de son
## lanceur, à rayon fixe.
##
## Comme tout ce qui dure, il ne fige jamais le jeu.

var _cast: SkillStats
var _author: StatusEffects
## Ce qu'il suit sous la Gravitation ; le centre de sa spirale sinon, posé au lancer.
var _caster: Node3D
var _center := Vector3.ZERO
var _start := 0.0
var _age := 0.0
var _bite := SkillStats.HAMMER_BITE
var _tint := Color.WHITE
var _contacts: Targets.Contacts
## Le Martèlement : les coups des marteaux de chaque lanceur sur chaque ennemi, **tous marteaux
## confondus** — un marteau seul ne touche un même ennemi que deux fois sur sa spirale, et le
## Battage n'éclatait jamais —, et l'image du dernier. Par « lanceur:ennemi ».
static var _blows := {}


## `index` : son rang dans le Carillon, qui fait un bourdon sur trois.
static func swing(
	parent: Node, at: Vector3, start: float, cast: SkillStats, author: StatusEffects,
	caster: Node3D, index := 0
) -> BlessedHammer:
	var hammer := BlessedHammer.new()
	if cast.bourdon > 0.0 and index % SkillStats.BOURDON_EVERY == SkillStats.BOURDON_EVERY - 1:
		cast = cast.echoed(SkillStats.BOURDON_FACTOR)
		hammer._bite *= SkillStats.BOURDON_FACTOR
	# Le Tocsin lit ses tués par le lancer : chacun le sien, sinon tous lâcheraient le petit.
	elif cast.tocsin > 0.0:
		cast = cast.echoed(1.0)
	hammer._cast = cast
	hammer._author = author
	hammer._caster = caster
	hammer._center = at
	hammer._start = start
	hammer._tint = DamageType.COLORS[cast.nature]
	hammer._contacts = Targets.Contacts.new(cast.period)
	if cast.tocsin > 0.0 and author != null:
		author.slew.connect(hammer._on_slew)
	parent.add_child(hammer)
	Settings.veil(hammer, Settings.SPELLS)
	hammer.global_position = hammer._at(0.0)
	return hammer


func _physics_process(delta: float) -> void:
	_age += delta
	_contacts.advance(delta)
	if _cast.gravitation > 0.0 and is_instance_valid(_caster):
		_center = _caster.global_position
	global_position = _at(_age)
	for target in Targets.in_circle(get_world_3d(), global_position, _bite):
		if _contacts.accepts(target):
			_blow(target)
	if _age >= _cast.duration:
		queue_free()


## Où il est à cet âge. La spirale s'ouvre de son centre jusqu'au rayon sur toute sa durée :
## la Ferrure, qui l'allonge, donne des tours de plus. La Prestesse le fait tourner plus vite.
func _at(age: float) -> Vector3:
	var turn := _start + SkillStats.HAMMER_SPEED * (1.0 + _cast.hammer_spin * 0.01) * age
	return _center + Flat.from_angle(turn) * _reach(age)


## L'Éclipse élargit l'orbite de la Gravitation.
func _reach(age: float) -> float:
	if _cast.gravitation > 0.0:
		return _cast.radius * SkillStats.GRAVITATION_ORBIT * (1.0 + _cast.eclipse * 0.01 * age)
	return _cast.radius * clampf(age / _cast.duration, 0.0, 1.0) if _cast.duration > 0.0 else 0.0


## Le Martèlement : chaque coup sur un même ennemi frappe plus fort que le précédent. Le
## Battage : tous les cinq, un éclat autour de lui.
func _blow(target: Hurtbox) -> void:
	var count := _count(target)
	var grown := float(mini(count, SkillStats.MARTELLING_MOST) - 1)
	var parts := DamageType.scaled(_cast.roll(Game.rng), 1.0 + _cast.martelling * 0.01 * grown)
	var at := target.global_position
	Targets.strike(target, parts, global_position, _author, _cast)
	if _cast.threshing > 0.0 and count % SkillStats.THRESHING_EVERY == 0:
		Explosion.put(
			get_parent(), at, DamageType.scaled(parts, _cast.threshing * 0.01),
			SkillStats.THRESHING_RADIUS, target, _tint, _author, _cast
		)


## Ce coup est le combientième des marteaux de ce lanceur sur cet ennemi ; compté de nouveau
## après `MARTELLING_FORGET` s sans coup, sur l'horloge de la physique.
func _count(target: Hurtbox) -> int:
	var now := Engine.get_physics_frames()
	var forget := roundi(SkillStats.MARTELLING_FORGET * Engine.physics_ticks_per_second)
	var key := "%d:%d" % [_author.get_instance_id() if _author != null else 0, target.get_instance_id()]
	var last: Array = _blows.get(key, [0, now])
	var count := 1 if now - int(last[1]) > forget else int(last[0]) + 1
	# Les ennemis morts ne reviennent pas : on oublie leurs comptes de temps en temps.
	if _blows.size() > 256:
		for k in _blows.keys():
			if now - int(_blows[k][1]) > forget:
				_blows.erase(k)
	_blows[key] = [count, now]
	return count


## Le Tocsin : un ennemi tué par ce marteau en lâche un petit, qui part en spirale du corps.
## Sous le Branle, le petit en lâche à son tour — une fois. En différé : on est dans le coup.
func _on_slew(cast: SkillStats, at: Vector3, _victim: StatusEffects) -> void:
	if cast != _cast or not is_instance_valid(get_parent()):
		return
	var small := _cast.echoed(_cast.tocsin * 0.01)
	small.radius *= SkillStats.TOCSIN_SIZE
	small.duration *= SkillStats.TOCSIN_SIZE
	small.gravitation = 0.0
	small.hammers = 0.0
	if _cast.peal <= 0.0:
		small.tocsin = 0.0
	small.peal = 0.0
	BlessedHammer.swing.call_deferred(
		get_parent(), at, Flat.angle(at - _center), small, _author, null
	)

