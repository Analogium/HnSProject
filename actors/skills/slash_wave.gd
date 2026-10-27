class_name SlashWave
extends Node3D

## Ce qu'un coup de taille envoie devant lui : l'arc du geste, détaché de la lame, qui
## avance en ligne droite et mord **une fois par corps**.
##
## Il naît en avant du bras (`START`) : sur le personnage, il doublerait le coup de la
## hitbox sur tout ce qui est déjà au contact.
##
## Ses parts sont tirées **une fois à la naissance**, comme celles du coup qui l'envoie :
## tout l'arc porte la même valeur.

## Devant le personnage, en pixels : au-delà de l'allonge de la hitbox.
const START := 18.0

## L'écart entre deux Vagues jumelles, en radians.
const FAN := 0.35
## Le croissant d'acier qui vole (`SteelFx.wave`), en part du rayon qui mord.
const ARC_SPAN := 1.3

var _cast: SkillStats
var _author: StatusEffects
var _parts: Array[float] = []
var _toward := Vector3.RIGHT
var _age := 0.0
## Sa période est sa vie entière : un corps traversé de bout en bout n'est frappé
## qu'une fois **par passage**.
var _bitten: Targets.Contacts
## Le Ressac (jalon 39) : celui vers qui elle revient, et d'où part le passage en cours —
## le Sillon d'acier court de là jusqu'au bout du passage.
var _caster: Node3D
var _start := Vector3.ZERO
var _returning := false
## Jalon 46. La Proue : le premier mordu est-il passé. La Lame de fond : ce qu'elle emporte.
## Le Va-et-vient : le cap de l'aller, et le troisième passage en cours.
var _prow_taken := false
## Sans type : un emporté peut mourir en route, et un mort ne passe pas un typage (invariant 4).
var _carried := []
var _heading := Vector3.RIGHT
var _third := false
var _arc: MeshInstance3D


static func send(
	parent: Node, from_value: Vector3, toward: Vector3, cast: SkillStats, author: StatusEffects,
	caster: Node3D = null
) -> SlashWave:
	var wave := SlashWave.new()
	wave._cast = cast
	wave._author = author
	wave._caster = caster
	wave._parts = cast.roll(Game.rng)
	wave._toward = toward.normalized()
	wave._heading = wave._toward
	wave._bitten = Targets.Contacts.new(cast.duration)
	parent.add_child(wave)
	Settings.veil(wave, Settings.SPELLS)
	wave.global_position = from_value + wave._toward * START
	wave._arc = SteelFx.wave(wave, cast.nature, cast.radius * ARC_SPAN)
	wave._arc.rotation.y = -Flat.angle(wave._toward)
	wave._start = wave.global_position
	return wave


func _physics_process(delta: float) -> void:
	_age += delta
	var home := _returning and is_instance_valid(_caster)
	if home:
		_toward = global_position.direction_to(_caster.global_position)
	var step := _toward * _cast.projectile_speed * delta
	position += step
	_bitten.advance(delta)
	_carry(step)
	var grown := _grown()
	_arc.rotation.y = -Flat.angle(_toward)
	_arc.scale = Vector3.ONE * _cast.radius * ARC_SPAN * grown
	for target in Targets.in_circle(get_world_3d(), global_position, _cast.radius * grown):
		if _bitten.accepts(target):
			var factor := grown
			# La Proue (jalon 46) : le premier qu'elle mord prend davantage.
			if _cast.prow > 0.0 and not _prow_taken:
				_prow_taken = true
				factor *= 1.0 + _cast.prow * 0.01
			Targets.strike(target, DamageType.scaled(_parts, factor), global_position, _author, _cast)
			var body := target.get_parent() as Enemy
			if _cast.undertow > 0.0 and body != null and not _carried.has(body):
				_carried.append(body)
	var arrived := home and global_position.distance_to(_caster.global_position) < _cast.radius
	if _age >= _cast.duration or arrived:
		_end_of_run()


## Au bout d'un passage, son Sillon d'acier ; puis, sous le Ressac, le retour — un second
## passage, qui remord ce que l'aller a mordu et pose son propre sillon.
func _end_of_run() -> void:
	if _cast.ground_duration > 0.0:
		DashTrail.leave(get_parent(), _start, global_position, _cast.ground(), _author, true)
	_throw_carried()
	if _cast.shape != Skill.Shape.BOOMERANG or _third:
		_gone()
		return
	if _returning:
		# Le Va-et-vient (jalon 46) : revenue, elle repart vers la visée, plus faible.
		if _cast.to_and_fro <= 0.0:
			_gone()
			return
		_third = true
		_returning = false
		_toward = _heading
		_parts = DamageType.scaled(_parts, SkillStats.TO_AND_FRO_PART)
	else:
		_returning = true
	_age = 0.0
	_start = global_position
	_bitten = Targets.Contacts.new(_cast.duration)


## Son croissant reste où elle s'arrête, le temps de se ronger.
func _gone() -> void:
	SteelFx.release(_arc)
	queue_free()


## La Houle (jalon 46) : le rayon et les dégâts grandissent au fil de la course, de un au
## bout.
func _grown() -> float:
	return 1.0 + _cast.billow * 0.01 * clampf(_age / _cast.duration, 0.0, 1.0)


## La Lame de fond (jalon 46) : ce qu'elle a mordu avance avec elle, murs compris.
func _carry(step: Vector3) -> void:
	if _carried.is_empty():
		return
	_carried = _carried.filter(
		func(e: Variant) -> bool: return is_instance_valid(e) and not (e as Enemy).is_dead
	)
	for body: Variant in _carried:
		(body as Enemy).move_and_collide(step)


## Au bout de la course, les Brisants jettent ce qu'elle emporte : un coup de plus à chacun.
func _throw_carried() -> void:
	if _cast.breakers > 0.0:
		var parts := DamageType.scaled(_parts, _cast.breakers * 0.01)
		for body: Variant in _carried:
			if is_instance_valid(body) and not (body as Enemy).is_dead:
				Targets.strike((body as Enemy).hurtbox, parts, global_position, _author, _cast)
	_carried.clear()

