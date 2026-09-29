class_name DashTrail
extends Node2D

## Ce qu'une ruée laisse derrière elle : un couloir qui frappe ce qui s'y trouve, une
## fois par période, jusqu'à la fin de sa durée. Il ne fige jamais le jeu, comme tout
## ce qui dure.
##
## Le couloir est une **file de cercles** le long du segment : `Targets.in_circle()` est
## le seul chemin des coups sans collision, et il ne connaît que le cercle.

## L'écart entre deux sondes, en part du rayon. Au-delà de 1, un ennemi peut tenir entre
## deux cercles ; en dessous, on paie des requêtes pour rien.
const STEP := 0.9

## Le sillon « cœur et franges » (jalon 34, choisi sur planche) couvre **la largeur du
## couloir qui frappe**, que l'ancienne file unique réduisait au tiers : un Braises à
## trois points ne se voyait pas. Au cœur, une grande langue tous les onze pixels,
## écartée de l'axe à tour de rôle ; autour, de petites langues semées jusqu'au bord.
const FLAME_STEP := 11.0
const CORE_SWAY := 2.0
## Les franges : au plus une langue par case, **pas un tirage libre**, qui faisait des
## paquets sur la planche ; ni dans le cœur, ni à moins de `FRINGE_MARGIN` du bord.
const FRINGE_CELL := 8.0
const FRINGE_CHANCE := 0.55
const CORE_WIDTH := 5.0
const FRINGE_MARGIN := 4.0
## Le lit de brûlures : un essai tous les 4 × 3 px, d'autant plus rare qu'on s'écarte
## de l'axe — un rectangle plein se lisait en tapis de briques.
const BURN_ALONG := 4.0
const BURN_ACROSS := 3.0
const BURN_DENSITY := 0.5
const SPAWN := 0.12
const FADE := 0.35
## La coupe de la Ruée tranchante : sa demi-largeur, en part du rayon qui mord, et
## les étincelles arrachées de part et d'autre, avec leur vitesse en pixels par
## seconde. Ce sont elles qui bougent, la coupe ne bouge pas.
const CUT_WIDTH := 0.45
const SPARKS := 8
const SPARK_SPEED := 44.0

var _cast: SkillStats
var _author: StatusEffects
var _tint := Color.WHITE
## En repère local : le nœud est posé au départ de la ruée.
var _toward := Vector2.ZERO
var _age := 0.0
var _strikes := 0
## La coupe d'une ruée physique, fabriquée à la naissance à l'angle exact.
var _cut: EffectForge.Piece
## Le sillon de feu, tiré **une fois** à la naissance : il ne bouge pas.
var _burns_at: Array[Vector2] = []
var _tongues: Array[Tongue] = []


class Tongue:
	var foot: Vector2
	var big: bool
	## Le décalage d'animation : deux langues voisines ne battent pas ensemble.
	var phase: float

	func _init(p_foot: Vector2, p_big: bool, p_phase: float) -> void:
		foot = p_foot
		big = p_big
		phase = p_phase


static func leave(
	parent: Node, from_value: Vector2, to: Vector2, cast: SkillStats, author: StatusEffects
) -> DashTrail:
	var trail := DashTrail.new()
	trail._cast = cast
	trail._author = author
	trail._toward = to - from_value
	trail._tint = DamageType.COLORS[cast.nature]
	parent.add_child(trail)
	Settings.veil(trail, Settings.SPELLS)
	trail.global_position = from_value
	return trail


## Le **sol brûlant** (jalon 34) : un sillage sans longueur, posé sur place. Différé,
## parce qu'il naît aussi d'une mort, donc d'un rappel de collision.
static func patch(
	parent: Node, at: Vector2, ground: SkillStats, author: StatusEffects
) -> DashTrail:
	var trail := DashTrail.new()
	trail._cast = ground
	trail._author = author
	trail._tint = DamageType.COLORS[ground.nature]
	Settings.veil(trail, Settings.SPELLS)
	DeferredTree.add_deferred(parent, trail, at)
	return trail


func _ready() -> void:
	z_index = 2
	# Le feu et la lame sont dessinés, et une planche cernée ne peut pas être
	# additive. Le reste reste en lumière ajoutée.
	if not _is_painted():
		material = ArtPalette.ADDITIVE
	if _cast.nature == DamageType.Kind.PHYSICAL:
		_cut = Slash.cleave(_tint, _toward, _cast.radius * CUT_WIDTH)
	elif _cast.nature == DamageType.Kind.FIRE:
		_lay_out_the_fire()


## Les impulsions se comptent par `strikes_over_duration()`, la fonction même de
## l'estimation : la fiche et la trace ne peuvent pas annoncer deux nombres.
func _physics_process(delta: float) -> void:
	_age += delta
	var due := _cast.strikes_due(_age)
	while _strikes < due:
		_strike()
		_strikes += 1
	queue_redraw()
	if _age >= _cast.duration and _strikes >= _cast.strikes_over_duration():
		queue_free()


## Un tirage par impulsion et non par cercle : c'est un geste de la trace, pas un coup
## par sonde. Une cible sous deux cercles ne reçoit qu'un coup.
func _strike() -> void:
	var parts := _cast.roll(Game.rng)
	var struck := {}
	for point in _probes():
		for target in Targets.in_circle(get_world_2d(), point, _cast.radius):
			var id := target.get_instance_id()
			if struck.has(id):
				continue
			struck[id] = true
			Targets.strike(target, parts, point, _author, _cast)


## Les centres des sondes, en repère global : les deux bouts au moins.
func _probes() -> Array[Vector2]:
	var out: Array[Vector2] = []
	var span := _toward.length()
	var count := maxi(ceili(span / maxf(_cast.radius * STEP, 1.0)), 1)
	for i in count + 1:
		out.append(global_position + _toward * (float(i) / float(count)))
	return out


func _draw() -> void:
	var fade := minf(_age / SPAWN, 1.0) * clampf((_cast.duration - _age) / FADE, 0.0, 1.0)
	var last := _toward
	var wide := _cast.radius * 0.5
	# Le ruban large dit la portée et rien d'autre : à 0,10 d'un orange, il sortait
	# **brun**, et on voyait un tapis avant de voir le feu (même piège qu'`Explosion`).
	# Les traînées peintes s'en passent, comme de halo : il les délaverait.
	if not _is_painted():
		draw_line(Vector2.ZERO, last, Color(_tint, 0.06 * fade), _cast.radius * 2.0)
		Glow.draw_blob(self, Vector2.ZERO, wide, Color(_tint, 0.30 * fade))
		Glow.draw_blob(self, last, wide, Color(_tint, 0.30 * fade))

	# **Le couloir luit pour tout le monde ; sa matière est par nature.** Le feu
	# lèche, la lame tranche, le reste ne fait que luire : une ruée de glace
	# n'avait aucune raison de laisser des flammes. Aucun de ces dessins ne frappe
	# — la morsure, c'est le couloir.
	match _cast.nature:
		DamageType.Kind.FIRE:
			_burnt_path(fade)
		DamageType.Kind.PHYSICAL:
			_slashed_path(last)
		_:
			# Les natures sans matière propre n'ont que ce trait : le feu s'en passe,
			# il lui barrait ses propres flammes d'une ligne droite.
			draw_line(Vector2.ZERO, last, Color(_tint, 0.30 * fade), 2.0)


## Le sillon : un lit de brûlures et des langues plantées dessus, sur toute la largeur
## du couloir. Des planches posées à plat, jamais tournées : une brûlure pivotée se
## rééchantillonne, et le couloir peut partir dans n'importe quelle direction.
func _burnt_path(fade: float) -> void:
	var burns := EffectForge.burns()
	for i in _burns_at.size():
		EffectForge.put_centered(self, burns[i % burns.size()], _burns_at[i], fade)
	var tall := EffectForge.flames(_tint)
	var short := EffectForge.small_flames(_tint)
	for t in _tongues:
		var sheet: Array = tall if t.big else short
		var tex: Texture2D = sheet[int(_age * EffectForge.FLAME_HZ + t.phase) % sheet.size()]
		_blit(tex, t.foot - Vector2(tex.get_width() * 0.5, tex.get_height() - 2), fade)


## Dans le repère du couloir — `a` le long, `b` en travers —, puis tourné vers `_toward`.
## Un tirage **local**, semé sur le nœud (invariant 3). Sans longueur — le sol brûlant —,
## la gélule devient un disque et le cœur une seule langue.
func _lay_out_the_fire() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(get_instance_id())
	var r := _cast.radius
	var span := _toward.length()
	var along := _toward / span if span > 0.0 else Vector2.RIGHT
	var across := along.orthogonal()

	var b := -r
	while b <= r:
		var a := -r
		while a <= span + r:
			var d := _off_axis(a, b, span) / r
			if d < 1.0 and rng.randf() < BURN_DENSITY * (1.0 - d * d):
				_burns_at.append(
					along * (a + rng.randf_range(-1.5, 1.5)) + across * (b + rng.randf_range(-1.0, 1.0))
				)
			a += BURN_ALONG
		b += BURN_ACROSS

	var count := maxi(int(span / FLAME_STEP), 1)
	for i in count:
		var sway := CORE_SWAY * (1.0 if i % 2 == 0 else -1.0)
		_tongues.append(Tongue.new(
			along * span * (float(i) + 0.5) / float(count) + across * sway, true, float(i) * 1.7
		))
	b = -r
	while b < r:
		var a := -r
		while a < span + r:
			var p := Vector2(a + rng.randf() * FRINGE_CELL, b + rng.randf() * FRINGE_CELL)
			if absf(p.y) > CORE_WIDTH and _off_axis(p.x, p.y, span) <= r - FRINGE_MARGIN \
					and rng.randf() < FRINGE_CHANCE:
				_tongues.append(Tongue.new(along * p.x + across * p.y, false, rng.randf() * 3.0))
			a += FRINGE_CELL
		b += FRINGE_CELL
	# Le plus bas passe devant : une langue du bord proche ne se cache pas derrière le cœur.
	_tongues.sort_custom(func(t1: Tongue, t2: Tongue) -> bool: return t1.foot.y < t2.foot.y)


## La distance d'un point au segment [0, span] de l'axe, dans le repère du couloir.
static func _off_axis(a: float, b: float, span: float) -> float:
	return Vector2(a - clampf(a, 0.0, span), b).length()


## La Ruée tranchante : **un seul coup d'épée sur toute la traversée**, posé d'une
## pièce, et des étincelles qui s'en arrachent de part et d'autre. La coupe ne pâlit
## pas — une lame à demi transparente sur un sol sombre sort grise — : elle tient
## son quart de seconde, puis elle n'est plus là.
func _slashed_path(last: Vector2) -> void:
	_cut.put(self, Vector2.ZERO)
	var grain := EffectForge.spark(_tint)
	var across := last.orthogonal().normalized()
	for i in SPARKS:
		var side := 1.0 if i % 2 == 0 else -1.0
		var at := last * ((float(i) + 0.5) / float(SPARKS)) + across * side * (3.0 + _age * SPARK_SPEED)
		EffectForge.put_centered(self, grain, at)


## Peinte — fait de planches cernées — ou tracée en lumière ajoutée.
func _is_painted() -> bool:
	return _cast.nature in [DamageType.Kind.FIRE, DamageType.Kind.PHYSICAL]


func _blit(tex: Texture2D, offset: Vector2, fade: float) -> void:
	var corner := EffectForge.snap(self, offset)
	draw_texture_rect(
		tex, Rect2(corner, Vector2(tex.get_width(), tex.get_height())),
		false, Color(1.0, 1.0, 1.0, fade)
	)
