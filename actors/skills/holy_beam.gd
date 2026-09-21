class_name HolyBeam
extends Node2D

## Le trait de Frappe sacrée : il jaillit du lanceur, frappe **une fois** tout ce qui
## est sur sa ligne, puis s'efface. Rien ne reste — le geste entier tient dans son
## premier instant, et ce qu'on voit n'est que la rémanence.
##
## Il frappe à sa première image de physique et non à la pose : le lancer peut venir
## d'un rappel de collision, où l'espace physique refuse les requêtes (invariant 4).

## La rémanence, en secondes : assez pour qu'un trait parti toutes les demi-secondes se
## voie, trop court pour qu'on le prenne pour une présence.
const LIFETIME := 0.16
## La largeur du coup, en pixels : `radius` porte sa longueur, et aucun nœud ne
## vise l'épaisseur.
const WIDTH := 6.0
## Celle du dessin, plus fine que celle du coup : un trait ne doit jamais promettre
## plus que ce qu'il mord.
const DRAWN := 4.0
## Les étincelles qui remontent le trait, et leur vitesse en longueurs par seconde.
## Ce sont elles qui donnent le sens du tir, qu'une barre immobile ne donne pas.
const GLINTS := 5
const GLINT_SPEED := 2.4

var _cast: SkillStats
var _author: StatusEffects
var _tint := Color.WHITE
## Dans le repère du trait, qui ne tourne pas : l'extrémité, en local.
var _tip := Vector2.ZERO
var _age := 0.0
var _has_struck := false
## Rastérisé à la naissance et jamais plus : un trait parti ne change plus de
## forme. Mesuré au banc, 1,16 ms pour le pire cas — la diagonale.
var _lance: EffectForge.Piece


static func fire(
	parent: Node, of: Vector2, direction: Vector2, cast: SkillStats, author: StatusEffects
) -> HolyBeam:
	var beam := HolyBeam.new()
	beam._cast = cast
	beam._author = author
	beam._tint = DamageType.COLORS[cast.dominant_nature()]
	beam._tip = direction.normalized() * cast.radius
	parent.add_child(beam)
	beam.global_position = of
	return beam


## Pas de lumière ajoutée : le trait est **dessiné**, et une planche cernée ne peut
## pas être additive — son contour sombre n'y ajoute rien.
func _ready() -> void:
	z_index = 5
	_lance = Holy.lance(_tip, DRAWN, _tint)


func _physics_process(delta: float) -> void:
	if not _has_struck:
		_has_struck = true
		var parts := _cast.roll(Game.rng)
		for target in Targets.in_capsule(get_world_2d(), global_position, to_global(_tip), WIDTH):
			Targets.strike(target, parts, global_position, _author, _cast)
	_age += delta
	queue_redraw()
	if _age >= LIFETIME:
		queue_free()


## Le trait, **posé d'une pièce**, et les étincelles qui le remontent. Choisi sur
## planche contre quatre autres traits (jalon 24) : le chapelet de marques partait
## dans n'importe quelle direction sans rastérisation, mais ses contours se
## croisaient l'un l'autre et le trait sortait effrangé.
##
## Il ne pâlit pas — une planche à demi-transparente sur un sol sombre sort grise.
## Il tient ses seize centièmes de seconde, puis il n'est plus là : c'est un coup,
## pas une présence.
func _draw() -> void:
	_lance.put(self, Vector2.ZERO)
	# À pleine opacité comme le trait : un grain à demi transparent sur un sol
	# sombre ne s'efface pas, il grisonne.
	for i in GLINTS:
		var along := fmod(_age * GLINT_SPEED + float(i) / float(GLINTS), 1.0)
		var across := Vector2(-_tip.y, _tip.x).normalized() * DRAWN * 1.8
		Holy.spark(
			self, _tip * along + across * (1.0 if i % 2 == 0 else -1.0), _tint, 1.0
		)
