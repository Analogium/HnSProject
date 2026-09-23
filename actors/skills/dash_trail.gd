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

## Une langue tous les onze pixels, quatre au moins. Ce qui faisait la palissade
## n'était pas leur nombre mais leur **régularité** : une grande et une petite en
## alternance, écartées de l'axe à tour de rôle, se lisent comme un chemin qui
## brûle là où douze langues identiques alignées font une clôture.
const FLAME_STEP := 11.0
## De combien une langue sur deux s'écarte de l'axe du couloir.
const FLAME_SWAY := 3.0
const FLAMES_MIN := 4
## L'écart de deux brûlures : sous cinq pixels elles se recouvrent et font un
## sillon continu, ce qui est le but.
const BURN_STEP := 4.0
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


static func leave(
	parent: Node, from_value: Vector2, to: Vector2, cast: SkillStats, author: StatusEffects
) -> DashTrail:
	var trail := DashTrail.new()
	trail._cast = cast
	trail._author = author
	trail._toward = to - from_value
	trail._tint = DamageType.COLORS[cast.dominant_nature()]
	parent.add_child(trail)
	trail.global_position = from_value
	return trail


func _ready() -> void:
	z_index = 2
	# Le feu et la lame sont dessinés, et une planche cernée ne peut pas être
	# additive. Le reste reste en lumière ajoutée.
	if not _is_painted():
		material = ArtPalette.ADDITIVE
	if _cast.dominant_nature() == DamageType.Kind.PHYSICAL:
		_cut = Slash.cleave(_tint, _toward, _cast.radius * CUT_WIDTH)


## Les impulsions se comptent par `strikes_over_duration()`, la fonction même de
## l'estimation : la fiche et la trace ne peuvent pas annoncer deux nombres.
func _physics_process(delta: float) -> void:
	_age += delta
	var total := _cast.strikes_over_duration()
	while _strikes < total and _age >= float(_strikes) * _cast.period:
		_strike()
		_strikes += 1
	queue_redraw()
	if _age >= _cast.duration and _strikes >= total:
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
	match _cast.dominant_nature():
		DamageType.Kind.FIRE:
			_burnt_path(last, fade)
		DamageType.Kind.PHYSICAL:
			_slashed_path(last)
		_:
			# Les natures sans matière propre n'ont que ce trait : le feu s'en passe,
			# il lui barrait ses propres flammes d'une ligne droite.
			draw_line(Vector2.ZERO, last, Color(_tint, 0.30 * fade), 2.0)


## Le sillon : une file de brûlures qui se recouvrent, et des langues plantées
## dessus. Choisi sur planche contre trois autres traînées — c'est le seul dessin
## qui dise qu'on est **passé par là**, et il remplace le ruban brun qui se voyait
## avant le feu.
##
## Des planches posées à plat, jamais tournées : une brûlure pivotée se
## rééchantillonne, et le couloir peut partir dans n'importe quelle direction.
func _burnt_path(last: Vector2, fade: float) -> void:
	var burns := EffectForge.burns()
	var span := last.length()
	var marks := maxi(int(span / BURN_STEP), 2)
	var burn_half := Vector2(EffectForge.BURN_WIDTH, EffectForge.BURN_HEIGHT) * 0.5
	for i in marks + 1:
		var at := last * (float(i) / float(marks))
		_blit(burns[i % burns.size()], at - burn_half, fade)

	var tall := EffectForge.flames(_tint)
	var short := EffectForge.small_flames(_tint)
	var across := last.orthogonal().normalized()
	var count := maxi(int(span / FLAME_STEP), FLAMES_MIN)
	for i in count:
		var big := i % 2 == 0
		var sheet: Array = tall if big else short
		var frame := int(_age * EffectForge.FLAME_HZ + float(i) * 1.7) % sheet.size()
		var tex: Texture2D = sheet[frame]
		var half := Vector2(tex.get_width() * 0.5, tex.get_height() - 2)
		var foot := last * ((float(i) + 0.5) / float(count))
		if not big:
			foot += across * FLAME_SWAY * (1.0 if i % 4 == 1 else -1.0)
		_blit(tex, foot - half, fade)


## La Ruée tranchante : **un seul coup d'épée sur toute la traversée**, posé d'une
## pièce, et des étincelles qui s'en arrachent de part et d'autre. La coupe ne pâlit
## pas — une lame à demi transparente sur un sol sombre sort grise — : elle tient
## son quart de seconde, puis elle n'est plus là.
func _slashed_path(last: Vector2) -> void:
	_cut.put(self, Vector2.ZERO)
	var grain := EffectForge.spark(_tint)
	var half := Vector2(grain.get_width(), grain.get_height()) * 0.5
	var across := last.orthogonal().normalized()
	for i in SPARKS:
		var side := 1.0 if i % 2 == 0 else -1.0
		var at := last * ((float(i) + 0.5) / float(SPARKS)) + across * side * (3.0 + _age * SPARK_SPEED)
		_blit(grain, at - half, 1.0)


## Peinte — fait de planches cernées — ou tracée en lumière ajoutée.
func _is_painted() -> bool:
	return _cast.dominant_nature() in [DamageType.Kind.FIRE, DamageType.Kind.PHYSICAL]


func _blit(tex: Texture2D, offset: Vector2, fade: float) -> void:
	var corner := EffectForge.snap(self, offset)
	draw_texture_rect(
		tex, Rect2(corner, Vector2(tex.get_width(), tex.get_height())),
		false, Color(1.0, 1.0, 1.0, fade)
	)
