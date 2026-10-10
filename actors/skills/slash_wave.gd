class_name SlashWave
extends Node2D

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
## L'ouverture de l'arc dessiné, en radians. Son rayon de frappe reste un cercle :
## `Targets.in_circle()` est le seul chemin des coups sans collision.
const SPAN := 1.7
## La fin de sa course, où il se dissout en damier au lieu de pâlir.
const FADE := 0.3
## L'épaisseur de la lame qui vole, en son milieu.
const THICKNESS := 5.0

## L'écart entre deux Vagues jumelles, en radians.
const FAN := 0.35

var _cast: SkillStats
var _author: StatusEffects
var _parts: Array[float] = []
var _tint := Color.WHITE
var _toward := Vector2.RIGHT
var _age := 0.0
## Sa période est sa vie entière : un corps traversé de bout en bout n'est frappé
## qu'une fois **par passage**.
var _bitten: Targets.Contacts
## Le Ressac (jalon 39) : celui vers qui elle revient, et d'où part le passage en cours —
## le Sillon d'acier court de là jusqu'au bout du passage.
var _caster: Node2D
var _start := Vector2.ZERO
var _returning := false
## Jalon 46. La Proue : le premier mordu est-il passé. La Lame de fond : ce qu'elle emporte.
## Le Va-et-vient : le cap de l'aller, et le troisième passage en cours.
var _prow_taken := false
## Sans type : un emporté peut mourir en route, et un mort ne passe pas un typage (invariant 4).
var _carried := []
var _heading := Vector2.RIGHT
var _third := false


static func send(
	parent: Node, from_value: Vector2, toward: Vector2, cast: SkillStats, author: StatusEffects,
	caster: Node2D = null
) -> SlashWave:
	var wave := SlashWave.new()
	wave._cast = cast
	wave._author = author
	wave._caster = caster
	wave._parts = cast.roll(Game.rng)
	wave._toward = toward.normalized()
	wave._heading = wave._toward
	wave._tint = DamageType.COLORS[cast.nature]
	wave._bitten = Targets.Contacts.new(cast.duration)
	parent.add_child(wave)
	Settings.veil(wave, Settings.SPELLS)
	# Le nœud ne tourne pas : c'est le dessin qui est fabriqué au cap de sa course,
	# une planche tournée se rééchantillonnant.
	wave.global_position = from_value + wave._toward * START
	wave._start = wave.global_position
	return wave


## Pas de lumière ajoutée : la lame est **dessinée**, et une planche cernée ne peut
## pas être additive — son contour sombre n'y ajoute rien.
func _ready() -> void:
	z_index = 3


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
	for target in Targets.in_circle(get_world_2d(), global_position, _cast.radius * grown):
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
	queue_redraw()
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
		queue_free()
		return
	if _returning:
		# Le Va-et-vient (jalon 46) : revenue, elle repart vers la visée, plus faible.
		if _cast.to_and_fro <= 0.0:
			queue_free()
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


## La Houle (jalon 46) : le rayon et les dégâts grandissent au fil de la course, de un au
## bout. Un seul calcul, que la frappe et le dessin lisent.
func _grown() -> float:
	return 1.0 + _cast.billow * 0.01 * clampf(_age / _cast.duration, 0.0, 1.0)


## La Lame de fond (jalon 46) : ce qu'elle a mordu avance avec elle, murs compris.
func _carry(step: Vector2) -> void:
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


## Un croissant ouvert vers l'avant, le fil blanc devant : l'arc du geste, détaché
## de la lame. Il se dissout en quatre temps sur la fin de sa course — l'aller d'un
## Ressac ne se dissout pas.
func _draw() -> void:
	var fade := clampf((_cast.duration - _age) / (_cast.duration * FADE), 0.0, 1.0)
	if _cast.shape == Skill.Shape.BOOMERANG and not _returning and not _third:
		fade = 1.0
	var gone := floorf((1.0 - fade) * 4.0) / 4.0
	var turn := Slash.turn_of(_toward.angle())
	# Par pas de deux pixels : chaque taille est fabriquée une fois et gardée.
	var radius := floorf(_cast.radius * _grown() * 0.5) * 2.0
	Slash.crescent(
		_tint, radius, THICKNESS, turn, -SPAN * 0.5, SPAN * 0.5, gone, false
	).put(self, -Vector2.from_angle(Slash.angle_of(turn)) * radius * 0.5)
