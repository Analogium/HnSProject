class_name CouronneDeLames
extends Node2D

## Les épées d'Épée spirale, qui tournent autour du joueur. Un seul nœud pour
## toutes : elles partagent un cercle et une rotation, et se répartissent dessus.

const RAYON := 26.0
## Radians par seconde : un tour en un peu moins d'une seconde et demie.
const ROTATION := 4.2
const LONGUEUR := 15.0
## Du centre d'une épée au centre d'une hurtbox ennemie.
const CONTACT := 14.0
## Le temps que met une épée lancée à rejoindre le cercle.
const SORTIE := 0.15
## Sans glissement, les survivantes sautent d'un tiers de tour quand une épée part.
const GLISSEMENT := 8.0
const DISPARITION := 0.5
const ACIER := Color(0.80, 0.84, 0.92)
const FIL := Color(1.0, 1.0, 1.0)
const GARDE := Color(0.86, 0.68, 0.30)
const POIGNEE := Color(0.40, 0.26, 0.16)
## Les images rémanentes : leur retard sur l'épée en radians, et leur opacité.
const REMANENCES := [[0.22, 0.30], [0.44, 0.14]]


class Lame:
	var geste: StatsDeCompetence
	var contacts: Cibles.Contacts
	var age := 0.0
	var place := 0.0


var _lames: Array[Lame] = []
var _rotation := 0.0


func _ready() -> void:
	z_index = 1


func nombre() -> int:
	return _lames.size()


## Zéro : sans limite.
func pleine(maximum: int) -> bool:
	return maximum > 0 and _lames.size() >= maximum


func ajouter(geste: StatsDeCompetence) -> void:
	var lame := Lame.new()
	lame.geste = geste
	lame.contacts = Cibles.Contacts.new(geste.periode)
	# Elle naît à la place qui l'attend : ce sont les autres qui glissent.
	lame.place = TAU * float(_lames.size()) / float(_lames.size() + 1)
	_lames.append(lame)


func vider() -> void:
	_lames.clear()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _lames.is_empty():
		return
	_rotation = fmod(_rotation + ROTATION * delta, TAU)
	var vivantes: Array[Lame] = []
	for lame in _lames:
		lame.age += delta
		lame.contacts.avancer(delta)
		if lame.age < lame.geste.duree:
			vivantes.append(lame)
	_lames = vivantes
	var glisse := 1.0 - exp(-GLISSEMENT * delta)
	for i in _lames.size():
		_lames[i].place = lerp_angle(_lames[i].place, TAU * float(i) / float(_lames.size()), glisse)
	_trancher()
	queue_redraw()


func _trancher() -> void:
	if _lames.is_empty():
		return
	var cibles := Cibles.dans_le_cercle(get_world_2d(), global_position, RAYON + CONTACT)
	for lame in _lames:
		var centre := to_global(_centre(lame, _rotation + lame.place))
		for cible in cibles:
			if centre.distance_to(cible.global_position) <= CONTACT and lame.contacts.accepte(cible):
				Cibles.frapper(cible, lame.geste.tirer(Game.rng), centre)


func _centre(lame: Lame, angle: float) -> Vector2:
	return Vector2.from_angle(angle) * RAYON * smoothstep(0.0, SORTIE, lame.age)


func _draw() -> void:
	for lame in _lames:
		var angle := _rotation + lame.place
		var fondu := clampf((lame.geste.duree - lame.age) / DISPARITION, 0.0, 1.0)
		var teinte: Color = DamageType.COLORS[lame.geste.nature_dominante()]
		for r: Array in REMANENCES:
			var retard := angle - float(r[0])
			_lame(_centre(lame, retard), retard, Color(teinte, float(r[1]) * fondu))
		_epee(_centre(lame, angle), angle, fondu)


## La lame seule, en silhouette : ce que montrent les images rémanentes.
func _lame(centre: Vector2, angle: float, couleur: Color) -> void:
	var le_long := Vector2.from_angle(angle + PI * 0.5)
	var travers := Vector2.from_angle(angle)
	var pointe := centre + le_long * LONGUEUR * 0.55
	var talon := centre - le_long * LONGUEUR * 0.2
	var epaule := pointe - le_long * 3.0
	draw_colored_polygon(PackedVector2Array([
		talon + travers * 1.3, epaule + travers * 1.3, pointe,
		epaule - travers * 1.3, talon - travers * 1.3,
	]), couleur)


## Tangente au cercle, pointe en avant : l'épée file dans le sens où elle tourne.
## Pointée vers l'extérieur, elle se lisait comme une lame de scie.
func _epee(centre: Vector2, angle: float, fondu: float) -> void:
	var le_long := Vector2.from_angle(angle + PI * 0.5)
	var travers := Vector2.from_angle(angle)
	var pointe := centre + le_long * LONGUEUR * 0.55
	var talon := centre - le_long * LONGUEUR * 0.2
	_lame(centre, angle, Color(ACIER, fondu))
	draw_line(talon + travers * 0.5, pointe, Color(FIL, 0.8 * fondu), 1.0)
	draw_line(talon + travers * 3.2, talon - travers * 3.2, Color(GARDE, fondu), 1.6)
	draw_line(talon, talon - le_long * 4.0, Color(POIGNEE, fondu), 1.4)
	draw_circle(talon - le_long * 4.6, 1.0, Color(GARDE, fondu))
