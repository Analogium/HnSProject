class_name SerpentInfernal
extends Node2D

## Le serpent de Serpent infernal : lâché au sol, il y rôde, et son corps brûle ce
## qu'il touche — une fois par période pour chaque cible.

## Seize anneaux : c'est la longueur qui dit « serpent ». Court et épais — neuf
## anneaux —, il se lisait comme une larve ; long et fin — douze —, il se perdait
## dans l'écran.
const ANNEAUX := 16
const ESPACEMENT := 3.4
const VITESSE := 62.0
## Au-delà de la moitié, il tourne vers son point de chute ; à la laisse entière, de
## toutes ses forces. Sans rappel, un cap au hasard l'emmène hors de l'écran en
## quatre secondes.
const LAISSE := 44.0
const RAPPEL := 3.0
## D'un anneau au centre d'une hurtbox ennemie.
const CONTACT := 11.0
const RAYON_TETE := 3.8
const RAYON_QUEUE := 1.4
## Un anneau sur deux plus sombre : ce sont les écailles qui disent « serpent ».
const ECAILLE := 0.22
const APPARITION := 0.2
const DISSIPATION := 0.4
const CLAIR := Color(1.0, 0.95, 0.55)
const YEUX := Color(0.15, 0.05, 0.02)
const LANGUE := Color(0.9, 0.15, 0.1)

var _geste: StatsDeCompetence
var _auteur: Etats
var _contacts: Cibles.Contacts
var _teinte := Color.WHITE
var _ancre := Vector2.ZERO
var _tete := Vector2.ZERO
var _cap := 0.0
var _age := 0.0
var _graine := 0.0
## Les positions passées de la tête, la plus récente à la fin. Le corps s'y pose à
## intervalles de longueur réguliers : il ondule dans les pas de la tête au lieu de
## pivoter d'un bloc.
var _trace: Array[Vector2] = []
## Les anneaux de l'image, tête d'abord, en coordonnées globales.
var _corps: Array[Vector2] = []


static func lacher(
	parent: Node, point: Vector2, geste: StatsDeCompetence, direction: Vector2, auteur: Etats
) -> SerpentInfernal:
	var s := SerpentInfernal.new()
	s._geste = geste
	s._auteur = auteur
	s._contacts = Cibles.Contacts.new(geste.periode)
	s._teinte = DamageType.COLORS[geste.nature_dominante()]
	s._ancre = point
	s._tete = point
	s._cap = direction.angle()
	# Déjà étendu derrière la tête : né en un point, il se lirait comme une braise.
	for i in range(ANNEAUX, 0, -1):
		s._trace.append(point - direction.normalized() * ESPACEMENT * float(i))
	s._trace.append(point)
	s._corps = s._anneaux()
	parent.add_child(s)
	return s


func _ready() -> void:
	z_index = 1
	_graine = float(get_instance_id() % 1000) * 0.01


func _physics_process(delta: float) -> void:
	_age += delta
	_contacts.avancer(delta)
	_ramper(delta)
	_corps = _anneaux()
	_mordre()
	queue_redraw()
	if _age >= _geste.duree:
		queue_free()


func _ramper(delta: float) -> void:
	var virage := sin(_age * 2.6 + _graine) * 2.2 + sin(_age * 1.1 + _graine * 3.0) * 1.4
	var vers_l_ancre := _ancre - _tete
	var au_dela := vers_l_ancre.length() - LAISSE * 0.5
	if au_dela > 0.0:
		var force := minf(au_dela / (LAISSE * 0.5), 1.0)
		virage += angle_difference(_cap, vers_l_ancre.angle()) * RAPPEL * force
	_cap += virage * delta
	_tete += Vector2.from_angle(_cap) * VITESSE * delta
	_trace.append(_tete)


## Pose les anneaux le long de la trace, et oublie ce qui est derrière la queue.
func _anneaux() -> Array[Vector2]:
	var courant := _trace[_trace.size() - 1]
	var out: Array[Vector2] = [courant]
	var i := _trace.size() - 2
	var reste := ESPACEMENT
	while out.size() < ANNEAUX and i >= 0:
		var suivant := _trace[i]
		var d := courant.distance_to(suivant)
		if d >= reste:
			courant = courant.move_toward(suivant, reste)
			out.append(courant)
			reste = ESPACEMENT
		else:
			reste -= d
			courant = suivant
			i -= 1
	while out.size() < ANNEAUX:
		out.append(out[out.size() - 1])
	if i > 0:
		_trace = _trace.slice(i)
	return out


func _mordre() -> void:
	var milieu := _corps[int(ANNEAUX * 0.5)]
	var portee := float(ANNEAUX) * ESPACEMENT * 0.5 + CONTACT
	for cible in Cibles.dans_le_cercle(get_world_2d(), milieu, portee):
		if _touche(cible.global_position) and _contacts.accepte(cible):
			Cibles.frapper(cible, _geste.tirer(Game.rng), _tete, _auteur)


func _touche(point: Vector2) -> bool:
	for anneau in _corps:
		if anneau.distance_squared_to(point) <= CONTACT * CONTACT:
			return true
	return false


func _draw() -> void:
	var fondu := minf(_age / APPARITION, 1.0) * clampf((_geste.duree - _age) / DISSIPATION, 0.0, 1.0)
	var tete := _teinte.lerp(CLAIR, 0.6)
	var queue := _teinte.darkened(0.45)
	# De la queue à la tête, halos d'abord : un halo peint après un anneau voisin le
	# délaverait.
	for i in range(ANNEAUX - 1, -1, -1):
		var k := float(i) / float(ANNEAUX - 1)
		draw_circle(to_local(_corps[i]), lerpf(RAYON_TETE, RAYON_QUEUE, k) * 1.7, Color(_teinte, 0.12 * fondu))
	for i in range(ANNEAUX - 1, -1, -1):
		var k := float(i) / float(ANNEAUX - 1)
		var couleur := tete.lerp(queue, k)
		if i % 2 == 1:
			couleur = couleur.darkened(ECAILLE)
		draw_circle(to_local(_corps[i]), lerpf(RAYON_TETE, RAYON_QUEUE, k), Color(couleur, fondu))

	var avant := Vector2.from_angle(_cap)
	var cote := avant.orthogonal()
	var t := to_local(_corps[0])
	for signe: float in [-1.0, 1.0]:
		draw_rect(Rect2(t + avant * 1.4 + cote * 1.5 * signe - Vector2(0.5, 0.5), Vector2.ONE), Color(YEUX, fondu))
	# La langue, par intermittence : toujours sortie, elle se lit comme une tige.
	if fmod(_age + _graine, 0.7) < 0.15:
		var racine := t + avant * RAYON_TETE
		var bout := racine + avant * 3.5
		draw_line(racine, bout, Color(LANGUE, fondu), 1.0)
		draw_line(bout, bout + (avant + cote).normalized() * 1.5, Color(LANGUE, fondu), 1.0)
		draw_line(bout, bout + (avant - cote).normalized() * 1.5, Color(LANGUE, fondu), 1.0)
