class_name NuageDOrage
extends Node2D

## Le nuage de Nuage d'orage : posé, il frappe tout ce qui est dessous à chaque
## période, puis se dissipe. Il ne fige jamais le jeu — une impulsion qui gèle
## toutes les demi-secondes hacherait l'image tant qu'il est posé.

## Le nuage flotte au-dessus de sa zone ; c'est le cercle au sol qui dit où elle est.
const HAUTEUR := 22.0
const BOUFFEES := 7
const APPARITION := 0.2
const DISSIPATION := 0.3
const VIE_D_UN_ECLAIR := 0.14
## Le nuage s'éclaire de la couleur de la foudre juste après avoir frappé.
const ECLAT := 0.12
const CORPS := Color(0.20, 0.19, 0.27)
const DESSUS := Color(0.38, 0.36, 0.48)


class Bouffee:
	var centre: Vector2
	var rayon: float
	var phase: float


class Eclair:
	var de: Vector2
	var vers: Vector2
	var age := 0.0


var _geste: StatsDeCompetence
var _teinte := Color.WHITE
var _age := 0.0
var _frappes := 0
var _bouffees: Array[Bouffee] = []
var _eclairs: Array[Eclair] = []
var _scintille := RandomNumberGenerator.new()


static func poser(parent: Node, point: Vector2, geste: StatsDeCompetence) -> NuageDOrage:
	var nuage := NuageDOrage.new()
	nuage._geste = geste
	nuage._teinte = DamageType.COLORS[geste.nature_dominante()]
	parent.add_child(nuage)
	nuage.global_position = point
	return nuage


func _ready() -> void:
	z_index = 4
	_scintille.seed = int(get_instance_id())
	var etendue := _geste.rayon * 0.7
	for i in BOUFFEES:
		var b := Bouffee.new()
		var u := float(i) / float(BOUFFEES - 1)
		b.centre = Vector2(
			lerpf(-etendue, etendue, u) + _scintille.randf_range(-2.0, 2.0),
			-HAUTEUR + _scintille.randf_range(-4.0, 3.0)
		)
		# Plus gros au milieu : un nuage est bombé, une rangée de disques égaux se lit
		# comme une chenille.
		b.rayon = lerpf(5.5, 9.5, 1.0 - absf(u - 0.5) * 2.0)
		b.phase = _scintille.randf_range(0.0, TAU)
		_bouffees.append(b)


## Les frappes se comptent par `frappes_dans_la_duree()`, la fonction même de
## l'estimation : la fiche et le nuage ne peuvent pas annoncer deux nombres.
func _physics_process(delta: float) -> void:
	_age += delta
	var total := _geste.frappes_dans_la_duree()
	while _frappes < total and _age >= float(_frappes) * _geste.periode:
		_frapper()
		_frappes += 1
	for e in _eclairs:
		e.age += delta
	_eclairs = _eclairs.filter(func(e: Eclair) -> bool: return e.age < VIE_D_UN_ECLAIR)
	queue_redraw()
	if _age >= _geste.duree and _frappes >= total:
		queue_free()


## Un tirage par impulsion, qu'elle touche ou non : c'est un geste du nuage.
func _frapper() -> void:
	var parts := _geste.tirer(Game.rng)
	var cibles := Cibles.dans_le_cercle(get_world_2d(), global_position, _geste.rayon)
	for cible in cibles:
		_eclair_vers(to_local(cible.global_position))
		Cibles.frapper(cible, parts, global_position)
	if cibles.is_empty():
		# Un éclair au sol même sans cible : le nuage montre qu'il frappe, et où.
		_eclair_vers(
			Vector2.from_angle(_scintille.randf_range(0.0, TAU))
			* _scintille.randf_range(0.0, _geste.rayon * 0.8)
		)


func _eclair_vers(point: Vector2) -> void:
	var e := Eclair.new()
	var bord := _geste.rayon * 0.6
	e.de = Vector2(clampf(point.x, -bord, bord), -HAUTEUR + 4.0)
	e.vers = point
	_eclairs.append(e)


func _draw() -> void:
	var fondu := minf(_age / APPARITION, 1.0) * clampf((_geste.duree - _age) / DISSIPATION, 0.0, 1.0)
	draw_circle(Vector2.ZERO, _geste.rayon, Color(_teinte, 0.08 * fondu))
	draw_arc(Vector2.ZERO, _geste.rayon, 0.0, TAU, 40, Color(_teinte, 0.35 * fondu), 1.0)

	var depuis := _age - float(maxi(_frappes - 1, 0)) * _geste.periode
	var eclat := clampf(1.0 - depuis / ECLAT, 0.0, 1.0)
	var sombre := Color(CORPS.lerp(_teinte, 0.25 * eclat), 0.9 * fondu)
	var clair := Color(DESSUS.lerp(_teinte, 0.45 * eclat), 0.9 * fondu)
	for b in _bouffees:
		draw_circle(b.centre + Vector2(0.0, sin(_age * 1.8 + b.phase)), b.rayon, sombre)
	# Le dessus plus clair, décalé vers la lumière du jeu — en haut à gauche.
	for b in _bouffees:
		draw_circle(b.centre + Vector2(-1.0, sin(_age * 1.8 + b.phase) - 2.0), b.rayon * 0.6, clair)

	for e in _eclairs:
		var k := 1.0 - e.age / VIE_D_UN_ECLAIR
		var brise := ChaineDEclairs.brisee(e.de, e.vers, _scintille, 3.0)
		draw_polyline(brise, Color(_teinte, 0.5 * k), 3.0)
		draw_polyline(brise, Color(_teinte.lerp(Color.WHITE, 0.6), k), 1.0)
